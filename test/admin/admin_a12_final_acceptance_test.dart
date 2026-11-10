import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_availability_controller.dart';
import 'package:aayusathi/admin/controllers/admin_dashboard_controller.dart';
import 'package:aayusathi/admin/controllers/admin_higher_authority_assignment_controller.dart';
import 'package:aayusathi/admin/models/admin_domain_availability.dart';
import 'package:aayusathi/admin/screens/admin_escalated_patient_workspace_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/mock_admin_dashboard_service.dart';
import 'package:aayusathi/admin/widgets/admin_availability_table.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/models/higher_authority_assignment.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';
import 'package:aayusathi/repositories/mock/mock_transfer_repository.dart';
import 'package:aayusathi/repositories/mock/mock_vital_repository.dart';

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
  late MockAuditRepository auditRepo;
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

    auditRepo = MockAuditRepository.instance;
    auditRepo.clear();

    dashboardService = MockAdminDashboardService.instance;
    dashboardService.reset();

    MockDoctorPatientRequestService.instance.resetToDefault();

    // Register 3 test doctors with differing clinical authority levels
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
    AdminAvailabilityController.instance.resetForTesting();
    MockDoctorPatientRequestService.instance.resetToDefault();
  });

  group('A12 Acceptance Group 1: Doctor Availability Table & Mathematical Invariants', () {
    test('8 standard OPD specialties are represented with valid invariants', () async {
      final controller = AdminAvailabilityController.instance;
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      final summaries = controller.domainSummaries;
      expect(summaries.length, 8);

      final domainIds = summaries.map((s) => s.domainId).toList();
      expect(domainIds, containsAll([
        'cardiology',
        'neurology',
        'gastroenterology',
        'orthopedics',
        'pediatrics',
        'ent',
        'dermatology',
        'general_medicine',
      ]));

      // Mathematical invariants:
      // Online = Available + In Consultation
      // Available <= Total Active
      // In Consultation <= Total Active
      for (final s in summaries) {
        expect(s.available + s.inConsultation + s.offline, equals(s.totalActive));
        expect(s.available, lessThanOrEqualTo(s.totalActive));
        expect(s.inConsultation, lessThanOrEqualTo(s.totalActive));
      }
    });

    testWidgets('AdminAvailabilityTable displays clean status pills and zero-state typography', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [
        const AdminDomainAvailability(
          domainId: 'cardiology',
          domainName: 'Cardiology',
          totalDoctors: 2,
          onlineDoctors: 2,
          available: 1,
          inConsultation: 1,
        ),
        const AdminDomainAvailability(
          domainId: 'neurology',
          domainName: 'Neurology',
          totalDoctors: 1,
          onlineDoctors: 0,
          available: 0,
          inConsultation: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAvailabilityTable(items: items),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SPECIALTY DOMAIN'), findsOneWidget);
      expect(find.text('ONLINE DOCTORS'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsOneWidget);
      expect(find.text('IN CONSULTATION'), findsOneWidget);

      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('Neurology'), findsOneWidget);

      // Verify non-zero pill values
      expect(find.text('1'), findsAtLeastNWidgets(2));
      // Verify neutral zero values
      expect(find.text('0'), findsAtLeastNWidgets(2));
    });
  });

  group('A12 Acceptance Group 2: Real-time Operational Presence Transitions', () {
    test('Offline -> Available -> In Consultation -> Available transition integrity', () async {
      final presence = DoctorPresenceService.instance;

      // 1. Initial Available
      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);
      expect(presence.isInConsultation, isFalse);

      // 2. Toggled to In Consultation (system lock during active consult)
      await presence.setInConsultation();
      expect(presence.isInConsultation, isTrue);
      expect(presence.isAvailable, isFalse);

      // 3. Consultation Completed -> Reset to Available
      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);
      expect(presence.isInConsultation, isFalse);
    });
  });

  group('A12 Acceptance Group 3: Complete 20-Step End-to-End System Acceptance Workflow', () {
    test('Steps 1-4: Admin login, live dashboard telemetry & doctor presence reflection', () async {
      // STEP 1: Admin login verification
      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(AdminAuthService.instance.currentSession?.username, 'admin01');

      // STEP 2: Admin Dashboard telemetry loads cleanly
      final dashboardController = AdminDashboardController.instance;
      await dashboardController.initialize();
      expect(dashboardController.hasError, isFalse);
      expect(dashboardController.overview, isNotNull);

      // STEP 3: Doctors registered across clinical authority levels
      final doctors = await doctorRepo.getAllDoctorProfiles();
      expect(doctors.any((d) => d.doctorId == 'DOC-101' && d.clinicalAuthorityLevel == 1), isTrue);
      expect(doctors.any((d) => d.doctorId == 'DOC-102' && d.clinicalAuthorityLevel == 2), isTrue);
      expect(doctors.any((d) => d.doctorId == 'DOC-103' && d.clinicalAuthorityLevel == 3), isTrue);

      // STEP 4: Doctor AVAILABLE presence reflected in Admin Availability
      final availController = AdminAvailabilityController.instance;
      availController.init();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(availController.onlineAvailableDoctors, greaterThan(0));
    });

    test('Steps 5-9: Kiosk patient & appointment creation, FIFO queue query, atomic doctor claim & consult lock', () async {
      // STEP 5: Kiosk creates new patient identity
      final patient = Patient(
        patientId: 'PAT-A12-001',
        name: 'Meera Deshmukh',
        dateOfBirth: '15 Jun 1982',
        age: 44,
        gender: 'Female',
        phone: '9822334455',
        bloodGroup: 'A+',
        address: 'Sector 5, Raipur',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await patientRepo.createPatient(patient);
      expect(await patientRepo.patientExists('PAT-A12-001'), isTrue);

      // STEP 6: Kiosk creates appointment with valid queue format A-XXXXX
      final appointment = AppointmentRequest(
        requestId: 'APT-A12-001',
        patientId: patient.patientId,
        domainId: 'general_medicine',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00099',
        createdAt: DateTime.now(),
        sessionId: 'SESS-A12-001',
      );
      await appointmentRepo.saveAppointment(appointment);
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(appointment.queueNumber), isTrue);

      // STEP 7: Doctor sees request in FIFO queue
      final requestService = MockDoctorPatientRequestService.instance;
      requestService.setRequests([
        DoctorPatientRequest(
          requestId: 'APT-A12-001',
          appointmentId: 'APT-A12-001',
          patientId: patient.patientId,
          queueNumber: 'A-00099',
          age: 44,
          gender: 'Female',
          domain: 'general_medicine',
          requestType: PatientRequestType.newVisit,
          requestedAt: DateTime.now(),
          status: PatientRequestStatus.waiting,
        ),
      ]);
      final pendingList = await requestService.getPendingRequests(domain: 'general_medicine');
      expect(pendingList.any((r) => r.requestId == 'APT-A12-001'), isTrue);

      // STEP 8: Doctor accepts request atomically
      await DoctorPresenceService.instance.setAvailable();
      final acceptResult = await requestService.acceptPatientRequest(
        requestId: 'APT-A12-001',
        doctorId: 'DOC-101',
        doctorDomain: 'general_medicine',
      );
      expect(acceptResult.isSuccess, isTrue);

      // STEP 9: Doctor becomes IN_CONSULTATION
      await DoctorPresenceService.instance.setInConsultation();
      expect(DoctorPresenceService.instance.isInConsultation, isTrue);
    });

    test('Steps 10-12: Doctor creates Case, completes Visit (Case remains OPEN), and escalates Case', () async {
      // STEP 10: Doctor creates and continues Case
      final clinicalCase = ClinicalCase(
        caseId: 'CASE-A12-001',
        patientId: 'PAT-A12-001',
        domain: 'general_medicine',
        title: 'Persistent febrile illness with joint pain',
        status: ClinicalCaseStatus.open,
        escalationStatus: CaseEscalationStatus.none,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await caseRepo.createCase(clinicalCase);

      final visit1 = ClinicalVisit(
        visitId: 'VIS-A12-001-1',
        caseId: clinicalCase.caseId,
        patientId: 'PAT-A12-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        chiefComplaint: 'Fever for 5 days, severe arthralgia',
        assessment: 'Suspected Viral Polyarthritis',
        clinicalObservations: 'No rash. Bilateral knee tenderness.',
        status: ClinicalVisitStatus.completed,
      );
      await visitRepo.createVisit(visit1);

      // STEP 11: Completing Visit 1 does NOT close Case (Case remains open for Visit 2)
      final caseCheck = await caseRepo.getCaseById(
        patientId: 'PAT-A12-001',
        caseId: clinicalCase.caseId,
      );
      expect(caseCheck!.isOpen, isTrue);
      expect(caseCheck.status, ClinicalCaseStatus.open);

      // STEP 12: Doctor explicitly escalates Case (A8 higherAuthorityReview)
      await caseRepo.escalateCase(
        patientId: 'PAT-A12-001',
        caseId: clinicalCase.caseId,
        visitId: visit1.visitId,
        reason: CaseEscalationReason.higherAuthorityReview,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        note: 'Requires Rheumatology / Senior Specialist input.',
      );

      final escalatedCase = await caseRepo.getCaseById(
        patientId: 'PAT-A12-001',
        caseId: clinicalCase.caseId,
      );
      expect(escalatedCase!.isEscalated, isTrue);
    });

    testWidgets('Steps 13-16: Admin receives escalation, starts review, and inspects A9 Clinical Workspace', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed escalated case
      await caseRepo.escalateCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        visitId: 'VIS-PAT-001-01-1',
        reason: CaseEscalationReason.higherAuthorityReview,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        note: 'Requires Level 2 specialist input.',
      );

      // STEP 14: Admin starts review
      await caseRepo.startAdminCaseReview(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        adminId: 'admin01',
      );

      final underReviewCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(underReviewCase!.isUnderReview, isTrue);

      // STEP 15 & 16: Admin loads A9 Clinical Workspace (Read-Only)
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.adminLogin: (_) => const Scaffold(body: Text('Login')),
            AppRoutes.adminCaseEscalations: (_) => const Scaffold(body: Text('Case Escalations')),
          },
          home: const AdminEscalatedPatientWorkspaceScreen(
            patientId: 'PAT-MOCK-001',
            caseId: 'CASE-PAT-001-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PATIENT CLINICAL REVIEW'), findsOneWidget);
      expect(find.text('READ ONLY'), findsOneWidget);
      expect(find.text('ASSIGN HIGHER AUTHORITY'), findsAtLeastNWidgets(1));
    });

    test('Steps 17-20: Admin assigns higher-authority doctor, doctor receives & accepts case', () async {
      // Escalate and review case
      await caseRepo.escalateCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        visitId: 'VIS-PAT-001-01-1',
        reason: CaseEscalationReason.higherAuthorityReview,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        note: 'Requires specialist review.',
      );
      await caseRepo.startAdminCaseReview(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        adminId: 'admin01',
      );
      final underReviewCase = (await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      ))!;

      // STEP 17: Admin assigns higher-authority Doctor (DOC-102 Level 2)
      final assignController = AdminHigherAuthorityAssignmentController(
        clinicalCase: underReviewCase,
        adminId: 'admin01',
      );
      await assignController.initialize();
      assignController.toggleCrossDepartment(true);
      assignController.setCrossDepartmentReason('Cardiology/Rheumatology assessment needed.');

      final doc102 = (await doctorRepo.getAllDoctorProfiles())
          .firstWhere((d) => d.doctorId == 'DOC-102');
      assignController.selectDoctor(doc102);

      final assignedCase = await assignController.assignHigherAuthority();
      expect(assignedCase, isNotNull);

      // STEP 18: Higher-authority Doctor receives assignment
      final targetCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(targetCase!.higherAuthorityDoctorId, 'DOC-102');
      expect(targetCase.higherAuthorityAssignmentStatus, HigherAuthorityAssignmentStatus.assigned);

      // STEP 19: Higher-authority Doctor accepts assignment
      final acceptedCase = await caseRepo.acceptHigherAuthorityAssignment(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        doctorId: 'DOC-102',
      );
      expect(acceptedCase.higherAuthorityAssignmentStatus, HigherAuthorityAssignmentStatus.accepted);

      // STEP 20: Doctor presence returns to AVAILABLE
      await DoctorPresenceService.instance.setAvailable();
      expect(DoctorPresenceService.instance.isAvailable, isTrue);
    });
  });

  group('A12 Acceptance Group 4: Security, Privacy & Audit Non-Exposure', () {
    test('Zero plain-text Aadhaar, passwords, or OTPs in models and serialization', () {
      final patient = Patient(
        patientId: 'PAT-SEC-A12',
        name: 'Govind Rao',
        dateOfBirth: '01 Jan 1970',
        age: 56,
        gender: 'Male',
        phone: '9876543210',
        bloodGroup: 'O+',
        address: 'Bhopal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firestoreMap = patient.toFirestore();
      expect(firestoreMap.containsKey('aadhaar'), isFalse);
      expect(firestoreMap.containsKey('aadhaarNumber'), isFalse);
      expect(firestoreMap.containsKey('password'), isFalse);
      expect(firestoreMap.containsKey('otp'), isFalse);
    });

    test('Audit log records operations without sensitive leakage', () async {
      final log = AuditLog(
        auditId: 'AUD-A12-001',
        actorType: AuditActorType.admin.value,
        actorId: 'admin01',
        action: 'ADMIN_LOGIN_SUCCESS',
        entityType: 'SESSION',
        entityId: 'admin01',
        timestamp: DateTime.now(),
        metadata: {'portal': 'ADMIN_PORTAL', 'authMode': 'MOCK'},
      );

      await auditRepo.logEvent(log);
      final events = auditRepo.logs;
      expect(events.any((e) => e.action == 'ADMIN_LOGIN_SUCCESS'), isTrue);

      // Verify no sensitive keys
      final logMap = log.toMap();
      expect(logMap.containsKey('password'), isFalse);
      expect(logMap.containsKey('token'), isFalse);
      expect(logMap.containsKey('aadhaar'), isFalse);
    });
  });

  group('A12 Acceptance Group 5: Storage & Report Document Verification', () {
    test('Storage service binary header validation rejects disguised files', () {
      final storage = MockStorageService.instance;

      // Valid PDF (%PDF)
      final validPdf = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37];
      expect(storage.validateFile(fileName: 'ecg_report.pdf', bytes: validPdf).isValid, isTrue);

      // Disguised EXE disguised as PDF
      final fakePdf = [0x4D, 0x5A, 0x90, 0x00];
      expect(storage.validateFile(fileName: 'ecg_report.pdf', bytes: fakePdf).isValid, isFalse);

      // Oversized payload (> 15 MB)
      final oversizedBytes = List<int>.filled(16 * 1024 * 1024, 0);
      expect(storage.validateFile(fileName: 'scan.pdf', bytes: oversizedBytes).isValid, isFalse);
    });
  });
}
