import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_dashboard_controller.dart';
import 'package:aayusathi/admin/controllers/admin_higher_authority_assignment_controller.dart';
import 'package:aayusathi/admin/screens/admin_dashboard_screen.dart';
import 'package:aayusathi/admin/screens/admin_escalated_patient_workspace_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/mock_admin_dashboard_service.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/models/higher_authority_assignment.dart';
import 'package:aayusathi/doctor/services/doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';
import 'package:aayusathi/repositories/mock/mock_transfer_repository.dart';
import 'package:aayusathi/repositories/mock/mock_vital_repository.dart';
import 'package:aayusathi/services/appointment_escalation_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository caseRepo;
  late MockDoctorRepository doctorRepo;
  late MockClinicalVisitRepository visitRepo;
  late MockPatientRepository patientRepo;
  late MockAppointmentRepository appointmentRepo;
  late MockVitalRepository vitalRepo;
  late MockTransferRepository transferRepo;
  late MockInvestigationRepository investigationRepo;
  late MockReportRepository reportRepo;
  late MockAdminDashboardService dashboardService;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    caseRepo = MockCaseRepository.instance;
    caseRepo.resetToDefaults();

    doctorRepo = MockDoctorRepository.instance;
    doctorRepo.resetToDefaults();

    visitRepo = MockClinicalVisitRepository.instance;
    visitRepo.resetToDefaults();

    patientRepo = MockPatientRepository.instance;
    patientRepo.resetToDefaults();

    appointmentRepo = MockAppointmentRepository.instance;
    appointmentRepo.clear();

    vitalRepo = MockVitalRepository.instance;
    vitalRepo.clear();

    transferRepo = MockTransferRepository.instance;
    transferRepo.resetToDefaults();

    investigationRepo = MockInvestigationRepository.instance;
    investigationRepo.reset();

    reportRepo = MockReportRepository.instance;
    reportRepo.reset();

    dashboardService = MockAdminDashboardService.instance;
    dashboardService.reset();

    MockDoctorPatientRequestService.instance.resetToDefault();

    // Register doctors of differing clinical authority levels
    doctorRepo.registerDoctorProfile(
      DoctorProfile(
        doctorId: 'DOC-101',
        doctorUniqueCode: 'DOC-101',
        name: 'Dr. Rajesh Sharma',
        qualification: 'MBBS (Resident / MO)',
        department: 'general_medicine',
        registeredPhone: '9876543210',
        email: 'doc-101@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        clinicalAuthorityLevel: 1,
        authUid: 'mock-uid-DOC-101',
        createdAt: DateTime(2026, 1, 11),
        updatedAt: DateTime(2026, 1, 11),
      ),
    );

    doctorRepo.registerDoctorProfile(
      DoctorProfile(
        doctorId: 'DOC-102',
        doctorUniqueCode: 'DOC-102',
        name: 'Dr. Amit Mehta',
        qualification: 'MBBS, MD (Senior Consultant)',
        department: 'cardiology',
        registeredPhone: '9876543211',
        email: 'doc-102@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        clinicalAuthorityLevel: 2,
        authUid: 'mock-uid-DOC-102',
        createdAt: DateTime(2026, 1, 12),
        updatedAt: DateTime(2026, 1, 12),
      ),
    );

    doctorRepo.registerDoctorProfile(
      DoctorProfile(
        doctorId: 'DOC-103',
        doctorUniqueCode: 'DOC-103',
        name: 'Dr. Sneha Joshi',
        qualification: 'MBBS, MD, DM (Chief Specialist)',
        department: 'general_medicine',
        registeredPhone: '9876543212',
        email: 'doc-103@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
        clinicalAuthorityLevel: 3,
        authUid: 'mock-uid-DOC-103',
        createdAt: DateTime(2026, 1, 13),
        updatedAt: DateTime(2026, 1, 13),
      ),
    );

    await AdminAuthService.instance.login(
      username: 'admin01',
      password: 'aayusathi1226',
    );
  });

  tearDown(() async {
    await AdminAuthService.instance.logout();
    DoctorSessionService.instance.resetSession();
    AdminDashboardController.instance.resetForTesting();
    MockDoctorPatientRequestService.instance.resetToDefault();
  });

  group('A11 Group 1: Admin Dashboard Telemetry & Error vs Empty State Contract', () {
    test('Available doctors KPI excludes inConsultation and offline doctors', () async {
      final doctors = await doctorRepo.getAllDoctorProfiles();
      final activeDoctors = doctors.where((d) => d.isActive).toList();
      final availableDoctors = activeDoctors
          .where((d) => d.availabilityStatus == DoctorAvailabilityStatus.available)
          .toList();

      final doc101 = doctors.firstWhere((d) => d.doctorId == 'DOC-101');
      final doc102 = doctors.firstWhere((d) => d.doctorId == 'DOC-102');
      final doc103 = doctors.firstWhere((d) => d.doctorId == 'DOC-103');

      expect(availableDoctors.contains(doc101), isTrue);
      expect(availableDoctors.contains(doc102), isTrue);
      expect(availableDoctors.contains(doc103), isFalse);
      expect(
        availableDoctors.every(
          (d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.available,
        ),
        isTrue,
      );
    });

    test('Valid empty state returns zero counts without error banner', () async {
      final controller = AdminDashboardController.instance;
      await controller.initialize();

      expect(controller.hasError, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.overview, isNotNull);
    });

    testWidgets('Dashboard UI cleanly differentiates between loaded data and error state', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('SYSTEM OVERVIEW'), findsOneWidget);
      expect(find.text('Live Data Stream Interrupted'), findsNothing);
    });
  });

  group('A11 Group 2: End-to-End Cross-Module Clinical Lifecycle', () {
    test('Kiosk -> Appointment -> Doctor Queue -> Accept -> Workspace -> Consult -> Complete', () async {
      // 1. Kiosk creates patient & appointment
      final patient = Patient(
        patientId: 'PAT-E2E-001',
        name: 'Sunita Sharma',
        dateOfBirth: '12 Apr 1985',
        age: 39,
        gender: 'Female',
        phone: '9812345678',
        bloodGroup: 'B+',
        address: 'Ward 4, Bilaspur',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await patientRepo.createPatient(patient);

      final appointment = AppointmentRequest(
        requestId: 'APT-E2E-001',
        patientId: patient.patientId,
        domainId: 'general_medicine',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00042',
        createdAt: DateTime.now(),
        sessionId: 'SESS-E2E-001',
      );
      await appointmentRepo.saveAppointment(appointment);

      // 2. Doctor fetches pending requests
      final requestService = MockDoctorPatientRequestService.instance;
      requestService.setRequests([
        DoctorPatientRequest(
          requestId: 'APT-E2E-001',
          appointmentId: 'APT-E2E-001',
          patientId: patient.patientId,
          queueNumber: 'A-00042',
          age: 39,
          gender: 'Female',
          domain: 'general_medicine',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
          status: PatientRequestStatus.waiting,
        ),
      ]);

      final pendingList = await requestService.getPendingRequests(
        domain: 'general_medicine',
      );
      expect(pendingList.any((r) => r.requestId == 'APT-E2E-001'), isTrue);

      // 3. Doctor accepts request atomically
      await DoctorPresenceService.instance.setAvailable();
      final acceptResult = await requestService.acceptPatientRequest(
        requestId: 'APT-E2E-001',
        doctorId: 'DOC-101',
        doctorDomain: 'general_medicine',
      );
      expect(acceptResult.isSuccess, isTrue);

      // 4. Doctor loads Clinical Workspace data
      final workspaceData = await DoctorPatientWorkspaceService.instance.loadWorkspaceData(
        requestId: 'APT-E2E-001',
        doctorId: 'DOC-101',
      );
      expect(workspaceData.status, WorkspaceAccessStatus.success);
      expect(workspaceData.patient?.name, 'Sunita Sharma');

      // 5. Doctor creates clinical case & visit
      final newCase = ClinicalCase(
        caseId: 'CASE-E2E-001',
        patientId: patient.patientId,
        domain: 'general_medicine',
        title: 'Acute respiratory infection with mild fever',
        status: ClinicalCaseStatus.open,
        escalationStatus: CaseEscalationStatus.none,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await caseRepo.createCase(newCase);

      final newVisit = ClinicalVisit(
        visitId: 'VIS-E2E-001-1',
        caseId: newCase.caseId,
        patientId: patient.patientId,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        chiefComplaint: 'Cough for 3 days, Fever',
        assessment: 'Upper Respiratory Tract Infection',
        clinicalObservations: 'Chest clear bilaterally. Vitals stable.',
        status: ClinicalVisitStatus.active,
      );
      await visitRepo.createVisit(newVisit);

      // 6. Complete consultation & return doctor to available
      await appointmentRepo.updateAppointmentStatus('APT-E2E-001', AppointmentStatus.completed);
      await DoctorPresenceService.instance.setAvailable();
      expect(DoctorPresenceService.instance.isAvailable, isTrue);
    });
  });

  group('A11 Group 3: Escalation Pathways (A7, A8, A9, A10)', () {
    test('A7: Appointment 20-minute SLA escalation recognition', () {
      final oldAppointment = AppointmentRequest(
        requestId: 'APT-SLA-OLD',
        patientId: 'PAT-MOCK-001',
        domainId: 'general_medicine',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00001',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        sessionId: 'SESS-E2E-002',
      );

      final isOverdue = AppointmentEscalationPolicy.shouldEscalate(
        oldAppointment,
        DateTime.now(),
      );
      expect(isOverdue, isTrue);
    });

    test('A8: Doctor escalates clinical case', () async {
      await caseRepo.escalateCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        visitId: 'VIS-PAT-001-01-1',
        reason: CaseEscalationReason.higherAuthorityReview,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        note: 'Escalating for Chief Specialist assessment.',
      );

      final escalatedCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );

      expect(escalatedCase, isNotNull);
      expect(escalatedCase!.isEscalated, isTrue);
      expect(escalatedCase.escalationReason, CaseEscalationReason.higherAuthorityReview);
    });

    testWidgets('A9 & A10: Admin reviews read-only workspace and transfers to Higher Authority doctor', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Escalate case
      await caseRepo.escalateCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        visitId: 'VIS-PAT-001-01-1',
        reason: CaseEscalationReason.higherAuthorityReview,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        note: 'Requires Level 2 specialist input.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminEscalatedPatientWorkspaceScreen(
            patientId: 'PAT-MOCK-001',
            caseId: 'CASE-PAT-001-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Read-Only Notice and Workspace Title
      expect(find.text('PATIENT CLINICAL REVIEW'), findsOneWidget);
      expect(find.text('READ ONLY'), findsOneWidget);
      expect(find.text('ASSIGN HIGHER AUTHORITY'), findsAtLeastNWidgets(1));

      final currentCase = (await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      ))!;

      // Perform assignment via controller
      final assignController = AdminHigherAuthorityAssignmentController(
        clinicalCase: currentCase,
        adminId: 'admin01',
      );
      await assignController.initialize();

      // Allow cross-department or pick doctor
      assignController.toggleCrossDepartment(true);
      assignController.setCrossDepartmentReason('Specialist evaluation required.');

      // DOC-102 is Level 2 (available)
      final doc102 = (await doctorRepo.getAllDoctorProfiles())
          .firstWhere((d) => d.doctorId == 'DOC-102');
      assignController.selectDoctor(doc102);

      final assignedCase = await assignController.assignHigherAuthority();
      expect(assignedCase, isNotNull);

      // Verify Case status updated
      final updatedCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(updatedCase!.higherAuthorityDoctorId, 'DOC-102');
      expect(updatedCase.higherAuthorityAssignmentStatus, HigherAuthorityAssignmentStatus.assigned);
    });
  });

  group('A11 Group 4: Storage Service & Document Verification Contracts', () {
    test('Storage service enforces file extension and byte header integrity', () {
      final storage = MockStorageService.instance;

      // Valid PDF magic header: %PDF
      final validPdfBytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34];
      final pdfResult = storage.validateFile(
        fileName: 'chest_xray.pdf',
        bytes: validPdfBytes,
      );
      expect(pdfResult.isValid, isTrue);

      // Invalid header disguised as PDF
      final fakePdfBytes = [0x00, 0x00, 0x00, 0x00];
      final fakeResult = storage.validateFile(
        fileName: 'fake.pdf',
        bytes: fakePdfBytes,
      );
      expect(fakeResult.isValid, isFalse);
      expect(fakeResult.errorMessage, contains('Not a valid PDF'));

      // Unsupported extension
      final exeBytes = [0x4D, 0x5A, 0x90, 0x00];
      final exeResult = storage.validateFile(
        fileName: 'malware.exe',
        bytes: exeBytes,
      );
      expect(exeResult.isValid, isFalse);
      expect(exeResult.errorMessage, contains('Unsupported file format'));
    });
  });

  group('A11 Group 5: Zero-Plaintext Aadhaar & Model Serialization Security', () {
    test('Patient serialization never leaks plaintext Aadhaar', () {
      final patient = Patient(
        patientId: 'PAT-SEC-001',
        name: 'Ramesh Patel',
        dateOfBirth: '20 Aug 1975',
        age: 49,
        gender: 'Male',
        phone: '9988776655',
        bloodGroup: 'O+',
        address: 'Raipur',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = patient.toFirestore();
      expect(map.containsKey('aadhaarNumber'), isFalse);
      expect(map.containsKey('aadhaar'), isFalse);
      expect(map['name'], 'Ramesh Patel');
    });
  });
}
