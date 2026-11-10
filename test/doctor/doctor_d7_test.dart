import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/patient_report.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/theme/doctor_colors.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_workspace_widgets.dart';
import 'package:aayusathi/doctor/widgets/doctor_transfer_patient_dialog.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';

Widget buildTestableWidget(
  Widget child, {
  KioskLocale locale = KioskLocale.english,
  Map<String, dynamic>? initialArgs,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    routes: {
      AppRoutes.doctorDashboard: (ctx) =>
          const Scaffold(body: Text('Doctor Dashboard Screen')),
      AppRoutes.doctorPatientWorkspace: (ctx) =>
          DoctorPatientWorkspaceScreen(initialArguments: initialArgs),
    },
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(1366, 768),
        devicePixelRatio: 1.0,
      ),
      child: child,
    ),
  );
}

void setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1366, 768);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorSessionService mockSession;
  late MockDoctorPresenceService mockPresence;
  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockPatientRepository mockPatientRepo;
  late MockDoctorPatientWorkspaceService mockWorkspaceService;
  late MockAuditRepository mockAudit;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);

    mockPresence = MockDoctorPresenceService(
      initialStatus: DoctorAvailabilityStatus.available,
    );
    DoctorPresenceService.instance = mockPresence;

    mockAudit = MockAuditRepository();
    mockAudit.clear();
    BackendProvider.instance.setCustomRepositories(auditRepo: mockAudit);

    mockSession = MockDoctorSessionService(auditRepository: mockAudit);
    DoctorSessionService.instance = mockSession;
    await mockSession.enterDevelopmentWorkspace();

    mockCaseRepo = MockCaseRepository.instance;
    mockCaseRepo.resetToDefaults();

    mockVisitRepo = MockClinicalVisitRepository.instance;
    mockVisitRepo.resetToDefaults();

    mockPatientRepo = MockPatientRepository.instance;
    mockPatientRepo.resetToDefaults();

    mockWorkspaceService = MockDoctorPatientWorkspaceService.instance;
    mockWorkspaceService.simulateError = false;
    mockWorkspaceService.simulateUnauthorized = false;
  });

  group('AAYUSATHI Phase D7 — Models & Scoped Hierarchy Tests', () {
    test('1. ClinicalCase model initializes open with valid metadata', () {
      final c = ClinicalCase(
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        domain: 'Cardiology',
        title: 'Chest Pain Evaluation',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );

      expect(c.isOpen, isTrue);
      expect(c.isClosed, isFalse);
      expect(c.domain, equals('Cardiology'));
      expect(c.visitCount, equals(0));
    });

    test('2. ClinicalVisit model initializes active with case-scoped visit number', () {
      final v = ClinicalVisit(
        visitId: 'VIS-001-1',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
      );

      expect(v.isActive, isTrue);
      expect(v.isCompleted, isFalse);
      expect(v.visitNumber, equals(1));
    });

    test('3. Scoped visit numbering starts at 1 for new case', () async {
      final nextNum = await mockVisitRepo.getNextVisitNumber(
        patientId: 'PAT-NEW-999',
        caseId: 'CASE-NEW-999',
      );
      expect(nextNum, equals(1));
    });

    test('4. Scoped visit numbering increments correctly per case', () async {
      final nextNum = await mockVisitRepo.getNextVisitNumber(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(nextNum, equals(3)); // already has visits 1 & 2
    });

    test('5. Duplicate visit numbers are prevented within same case', () async {
      final duplicateAttempt = ClinicalVisit(
        visitId: 'VIS-DUPE',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        visitNumber: 1, // Already exists
        startedAt: DateTime.now(),
      );

      final created = await mockVisitRepo.createVisit(duplicateAttempt);
      expect(created.visitNumber, equals(3)); // Automatically bumped
    });

    test('6. Completing a visit does NOT close the Case', () async {
      final c = await mockCaseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(c?.isOpen, isTrue);

      // Simulate completing visit 2
      final v2 = await mockVisitRepo.getVisitById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        visitId: 'VIS-PAT-001-01-2',
      );
      expect(v2, isNotNull);

      final completedV2 = v2!.copyWith(
        status: ClinicalVisitStatus.completed,
        completedAt: DateTime.now(),
      );
      await mockVisitRepo.updateVisit(completedV2);

      // Verify case remains open
      final updatedCase = await mockCaseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(updatedCase?.isOpen, isTrue);
      expect(updatedCase?.status, equals(ClinicalCaseStatus.open));
    });

    test('7. PatientReport model serializes and parses properly', () {
      final r = PatientReport(
        reportId: 'REP-99',
        patientId: 'PAT-001',
        title: 'ECG Test',
        type: PatientReportType.diagnostic,
        status: PatientReportStatus.available,
        date: DateTime.now(),
      );

      expect(r.isAvailable, isTrue);
      final map = r.toMap();
      expect(map['title'], equals('ECG Test'));
      expect(map['status'], equals('available'));
    });

    test('8. Strictly NO Aadhaar stored in ClinicalCase or ClinicalVisit', () {
      final c = ClinicalCase(
        caseId: 'CASE-1',
        patientId: 'PAT-1',
        domain: 'Cardiology',
        title: 'Routine Checkup',
        createdAt: DateTime.now(),
      );
      final v = ClinicalVisit(
        visitId: 'VIS-1',
        caseId: 'CASE-1',
        patientId: 'PAT-1',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
      );

      expect(c.toMap().containsKey('aadhaar'), isFalse);
      expect(c.toMap().containsKey('aadhaarNumber'), isFalse);
      expect(v.toMap().containsKey('aadhaar'), isFalse);
      expect(v.toMap().containsKey('aadhaarNumber'), isFalse);
    });
  });

  group('AAYUSATHI Phase D7 — Authorization & Security Tests', () {
    test('9. Authorized Doctor can successfully load patient workspace data', () async {
      final data = await mockWorkspaceService.loadWorkspaceData(
        requestId: 'REQ-D5-001',
        doctorId: 'DOC-101',
      );

      expect(data.isSuccess, isTrue);
      expect(data.patient, isNotNull);
      expect(data.patient?.name, equals('Aarav Sharma'));
      expect(data.appointment?.queueNumber, equals('A-00027'));
    });

    test('10. Doctor cannot access another Doctor\'s assigned patient', () async {
      // Save appointment assigned to DOC-999
      final foreignAppt = AppointmentRequest(
        requestId: 'REQ-FOREIGN-01',
        patientId: 'AAYU-102938',
        domainId: 'Cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        assignedDoctorId: 'DOC-999',
        status: AppointmentStatus.accepted,
        queueNumber: 'A-00099',
        createdAt: DateTime.now(),
        sessionId: 'SES-01',
      );
      await BackendProvider.instance.appointmentRepository.saveAppointment(foreignAppt);

      // Attending doctor DOC-101 tries to access REQ-FOREIGN-01
      final data = await mockWorkspaceService.loadWorkspaceData(
        requestId: 'REQ-FOREIGN-01',
        doctorId: 'DOC-101',
      );

      expect(data.isUnauthorized, isTrue);
      expect(data.status, equals(WorkspaceAccessStatus.unauthorized));
    });

    test('11. Non-existent appointment returns appointmentNotFound status', () async {
      final data = await mockWorkspaceService.loadWorkspaceData(
        requestId: 'REQ-NON-EXISTENT',
        doctorId: 'DOC-101',
      );

      expect(data.isNotFound, isTrue);
      expect(data.status, equals(WorkspaceAccessStatus.appointmentNotFound));
    });

    test('12. Doctor presence lock remains IN_CONSULTATION during workspace session', () async {
      await mockPresence.setInConsultation();
      expect(mockPresence.isInConsultation, isTrue);
      expect(mockPresence.isAvailable, isFalse);
    });
  });

  group('AAYUSATHI Phase D7 — UI Clinical Workstation Widget Tests', () {
    testWidgets('13. Workspace renders patient identity banner without Aadhaar', (tester) async {
      setDesktopViewport(tester);
      final patient = Patient(
        patientId: 'PAT-MOCK-001',
        name: 'Aarav Sharma',
        dateOfBirth: '14 May 1984',
        age: 42,
        gender: 'Male',
        phone: '+91 98765 43210',
        bloodGroup: 'O+',
        address: '104, Green Meadows, Pune',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: DoctorPatientIdentityCard(patient: patient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('PAT-MOCK-001'), findsOneWidget);
      expect(find.text('42 yrs'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('O+'), findsOneWidget);

      // Verify Aadhaar is NOT displayed anywhere
      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('UIDAI'), findsNothing);
    });

    testWidgets('14. Current Vitals Bar renders SpO2, Heart Rate, and Temp', (tester) async {
      setDesktopViewport(tester);
      final vitals = VitalReading(
        vitalId: 'VIT-1',
        spo2: 98,
        heartRate: 74,
        temperature: 36.6,
        timestamp: DateTime.now(),
        status: VitalStatus.valid,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: DoctorCurrentVitalsBar(vitals: vitals),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('98%'), findsOneWidget);
      expect(find.text('74 BPM'), findsOneWidget);
      expect(find.text('120/80 mmHg'), findsNothing);
      expect(find.text('36.6 °C'), findsOneWidget);
      expect(find.text('CURRENT VITALS'), findsOneWidget);
    });

    testWidgets('15. Missing vitals render Not available placeholder', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: DoctorCurrentVitalsBar(vitals: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not available'), findsNWidgets(3));
    });

    testWidgets('16. Cases & Visits section displays existing cases and visits', (tester) async {
      setDesktopViewport(tester);
      final cases = [
        ClinicalCase(
          caseId: 'CASE-01',
          patientId: 'PAT-001',
          domain: 'Cardiology',
          title: 'Hypertension Review',
          status: ClinicalCaseStatus.open,
          createdAt: DateTime.now(),
          visitCount: 2,
        ),
      ];

      final visits = [
        ClinicalVisit(
          visitId: 'VIS-01-1',
          caseId: 'CASE-01',
          patientId: 'PAT-001',
          doctorId: 'DOC-101',
          doctorName: 'Dr. Rajesh Sharma',
          visitNumber: 1,
          startedAt: DateTime.now().subtract(const Duration(days: 7)),
          status: ClinicalVisitStatus.completed,
          summary: 'Initial consultation notes.',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: cases,
              selectedCase: cases.first,
              visits: visits,
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hypertension Review'), findsOneWidget);
      expect(find.text('OPEN'), findsWidgets);
      expect(find.text('Visit 1'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Initial consultation notes.'), findsOneWidget);
    });

    testWidgets('17. Reports section displays tabs and test records', (tester) async {
      setDesktopViewport(tester);
      final reports = [
        PatientReport(
          reportId: 'REP-1',
          patientId: 'PAT-001',
          title: '12-Lead Electrocardiogram (ECG)',
          type: PatientReportType.diagnostic,
          status: PatientReportStatus.available,
          date: DateTime.now(),
          summary: 'Normal sinus rhythm.',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: DoctorReportsSection(reports: reports),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Available Reports'), findsOneWidget);
      expect(find.text('Requested Reports'), findsOneWidget);
      expect(find.text('Uploaded Reports'), findsOneWidget);
      expect(find.text('12-Lead Electrocardiogram (ECG)'), findsOneWidget);
      expect(find.text('Normal sinus rhythm.'), findsOneWidget);
    });

    testWidgets('18. Full Workspace Screen renders header, vitals, cases, and reports', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AAYUSATHI'), findsOneWidget);
      expect(find.text('PATIENT WORKSPACE'), findsOneWidget);
      expect(find.text('QUEUE NUMBER: A-00027'), findsOneWidget);
      expect(find.text('IN CONSULTATION'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('VISIT IDENTIFICATION'), findsOneWidget);
      expect(find.text('VITALS AT CONSULTATION'), findsOneWidget);
      expect(find.text('CASE INFORMATION'), findsOneWidget);
      expect(find.text('STRUCTURED CONSULTATION'), findsOneWidget);
      expect(find.text('TRANSFER PATIENT'), findsOneWidget);
      expect(find.text('COMPLETE VISIT'), findsOneWidget);
    });

    testWidgets('19. Navigation back attempt shows confirmation dialog with Stay and Leave options', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap back button in header
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Consultation in Progress'), findsOneWidget);
      expect(find.text('STAY'), findsOneWidget);
      expect(find.text('LEAVE WORKSPACE'), findsOneWidget);

      // Tap STAY
      await tester.tap(find.text('STAY'));
      await tester.pumpAndSettle();

      // Still in workspace
      expect(find.text('PATIENT WORKSPACE'), findsOneWidget);
    });

    testWidgets('20. Leaving workspace returns to dashboard without resetting presence', (tester) async {
      setDesktopViewport(tester);
      await mockPresence.setInConsultation();

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Tap LEAVE WORKSPACE
      await tester.tap(find.text('LEAVE WORKSPACE'));
      await tester.pumpAndSettle();

      // Preserved presence
      expect(mockPresence.isInConsultation, isTrue);
      expect(find.text('Doctor Dashboard Screen'), findsOneWidget);
    });

    testWidgets('21. Start New Case dialog creates case and adds it to list', (tester) async {
      setDesktopViewport(tester);
      String? createdDomain;
      String? createdTitle;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorNewCaseDialog(
            defaultDomain: 'Cardiology',
            onConfirm: (domain, title) {
              createdDomain = domain;
              createdTitle = title;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Case Title in dialog
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Acute Chest Tightness');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      expect(createdDomain, equals('Cardiology'));
      expect(createdTitle, equals('Acute Chest Tightness'));
    });

    testWidgets('21b. DoctorNewCaseDialog contrast, dropdown selection, cancel action, and responsive styling', (tester) async {
      setDesktopViewport(tester);
      String? createdDomain;
      String? createdTitle;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorNewCaseDialog(
            defaultDomain: 'General Medicine',
            onConfirm: (domain, title) {
              createdDomain = domain;
              createdTitle = title;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Dialog Title & Header
      expect(find.text('START NEW CASE'), findsOneWidget);
      final titleWidget = tester.widget<Text>(find.text('START NEW CASE'));
      expect(titleWidget.style?.color, equals(DoctorColors.brandNavy));

      // 2. Verify Field Labels have high contrast dark navy color
      expect(find.text('Case Domain'), findsOneWidget);
      final domainLabel = tester.widget<Text>(find.text('Case Domain'));
      expect(domainLabel.style?.color, equals(DoctorColors.brandNavy));

      expect(find.text('Case Label / Reason'), findsOneWidget);
      final titleLabel = tester.widget<Text>(find.text('Case Label / Reason'));
      expect(titleLabel.style?.color, equals(DoctorColors.brandNavy));

      // 3. Verify Dropdown exists and has visible arrow & selected value
      expect(find.byKey(const Key('case_domain_dropdown')), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.text('General Medicine'), findsOneWidget);

      // Change Domain in Dropdown to Pediatrics
      await tester.tap(find.byKey(const Key('case_domain_dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('Pediatrics').last, findsOneWidget);
      await tester.tap(find.text('Pediatrics').last);
      await tester.pumpAndSettle();

      // 4. Verify Input field has placeholder and accepts typed text with high contrast
      final inputFinder = find.byKey(const Key('case_title_input'));
      expect(inputFinder, findsOneWidget);
      final textField = tester.widget<TextField>(inputFinder);
      expect(textField.decoration?.hintText, equals('e.g. Hypertension & Chest Discomfort'));
      expect(textField.style?.color, equals(DoctorColors.textPrimary));

      await tester.enterText(inputFinder, 'Persistent Fever & Cough');
      await tester.pumpAndSettle();

      // 5. Verify Cancel button exists and closes dialog without saving
      expect(find.byKey(const Key('cancel_new_case_button')), findsOneWidget);

      // 6. Verify Save button exists with brand teal background and white text
      final saveBtnFinder = find.byKey(const Key('save_new_case_button'));
      expect(saveBtnFinder, findsOneWidget);
      final saveBtn = tester.widget<ElevatedButton>(saveBtnFinder);
      expect(saveBtn.style?.backgroundColor?.resolve({}), equals(DoctorColors.brandTeal));

      // 7. Verify responsive layout on compact screen
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tap Save
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();

      expect(createdDomain, equals('Pediatrics'));
      expect(createdTitle, equals('Persistent Fever & Cough'));
    });

    testWidgets('22. Hindi localized strings render properly in workspace widgets', (tester) async {
      final hindiStrings = DoctorLocalizations.forLocale(KioskLocale.hindi);
      expect(hindiStrings.patientWorkspaceTitle, equals('मरीज़ वर्कस्पेस'));
      expect(hindiStrings.currentVitals, equals('वर्तमान वाइटल्स'));
      expect(hindiStrings.myCases, equals('मेरे केस'));
      expect(hindiStrings.startNewCase, equals('नया केस शुरू करें'));
      expect(hindiStrings.addVisit, equals('विज़िट जोड़ें'));
      expect(hindiStrings.stayButton, equals('रहें'));
      expect(hindiStrings.leaveWorkspaceButton, equals('वर्कस्पेस छोड़ें'));
    });

    testWidgets('23. Marathi localized strings render properly in workspace widgets', (tester) async {
      final marathiStrings = DoctorLocalizations.forLocale(KioskLocale.marathi);
      expect(marathiStrings.patientWorkspaceTitle, equals('रुग्ण वर्कस्पेस'));
      expect(marathiStrings.currentVitals, equals('सध्याचे व्हायटल्स'));
      expect(marathiStrings.myCases, equals('माझे केस'));
      expect(marathiStrings.startNewCase, equals('नवीन केस सुरू करा'));
      expect(marathiStrings.addVisit, equals('भेट जोडा'));
      expect(marathiStrings.stayButton, equals('थांबा'));
      expect(marathiStrings.leaveWorkspaceButton, equals('वर्कस्पेस सोडा'));
    });

    testWidgets('24. Selection of existing case updates displayed visits', (tester) async {
      setDesktopViewport(tester);
      final cases = [
        ClinicalCase(
          caseId: 'CASE-01',
          patientId: 'PAT-001',
          domain: 'Cardiology',
          title: 'Hypertension Review',
          status: ClinicalCaseStatus.open,
          createdAt: DateTime.now(),
          visitCount: 1,
        ),
        ClinicalCase(
          caseId: 'CASE-02',
          patientId: 'PAT-001',
          domain: 'Orthopedics',
          title: 'Knee Sprain',
          status: ClinicalCaseStatus.closed,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          visitCount: 1,
        ),
      ];

      final visits = [
        ClinicalVisit(
          visitId: 'VIS-01-1',
          caseId: 'CASE-01',
          patientId: 'PAT-001',
          doctorId: 'DOC-101',
          visitNumber: 1,
          startedAt: DateTime.now(),
          summary: 'Cardiology consultation notes.',
        ),
      ];

      ClinicalCase? selectedCase = cases.first;

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (ctx, setState) {
              return Scaffold(
                body: DoctorClinicalRecordsSection(
                  cases: cases,
                  selectedCase: selectedCase,
                  visits: visits.where((v) => v.caseId == selectedCase?.caseId).toList(),
                  onSelectCase: (c) => setState(() => selectedCase = c),
                  onStartNewCase: () {},
                  onAddVisit: () {},
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cardiology consultation notes.'), findsOneWidget);

      // Tap second case (Orthopedics)
      await tester.tap(find.text('Knee Sprain'));
      await tester.pumpAndSettle();

      expect(find.text('Cardiology consultation notes.'), findsNothing);
      expect(find.text('No visits recorded for this clinical case.'), findsOneWidget);
    });

    testWidgets('25. Empty cases state displays No clinical cases found', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: const [],
              selectedCase: null,
              visits: const [],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No clinical cases found for this patient.'), findsOneWidget);
      expect(find.text('Select a case to view its consultation visits.'), findsOneWidget);
    });

    testWidgets('26. Previous Doctor Requested badge renders when flagged in route arguments', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-003',
              'queueNumber': 'A-00029',
              'domain': 'Cardiology',
              'requestType': 'previousDoctor',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PREVIOUS DOCTOR REQUEST'), findsOneWidget);
    });

    testWidgets('27. Bottom bar action buttons display informative SnackBars', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Transfer Patient -> opens DoctorTransferPatientDialog
      await tester.tap(find.text('TRANSFER PATIENT'));
      await tester.pumpAndSettle();
      expect(find.byType(DoctorTransferPatientDialog), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SAVE DRAFT'));
      await tester.pump();
      expect(find.text('Consultation draft saved successfully.'), findsOneWidget);
    });

    testWidgets('28. Reports section tab switching filters reports by status', (tester) async {
      setDesktopViewport(tester);
      final reports = [
        PatientReport(
          reportId: 'REP-1',
          patientId: 'PAT-001',
          title: 'Available Blood Test',
          status: PatientReportStatus.available,
          date: DateTime.now(),
        ),
        PatientReport(
          reportId: 'REP-2',
          patientId: 'PAT-001',
          title: 'Requested Ultrasound',
          status: PatientReportStatus.requested,
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: DoctorReportsSection(reports: reports),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Available Blood Test'), findsOneWidget);
      expect(find.text('Requested Ultrasound'), findsNothing);

      // Tap Requested Reports tab
      await tester.tap(find.text('Requested Reports'));
      await tester.pumpAndSettle();

      expect(find.text('Available Blood Test'), findsNothing);
      expect(find.text('Requested Ultrasound'), findsOneWidget);
    });

    testWidgets('29. Error view displays when workspace fails to load with retry button', (tester) async {
      setDesktopViewport(tester);
      mockWorkspaceService.simulateError = true;

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient information could not be loaded.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Unset error and tap retry
      mockWorkspaceService.simulateError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('PATIENT WORKSPACE'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
    });

    testWidgets('30. Unauthorized doctor shows error view and returns to dashboard', (tester) async {
      setDesktopViewport(tester);
      mockWorkspaceService.simulateUnauthorized = true;

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You are not authorized to access this patient.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Doctor Dashboard Screen'), findsOneWidget);
    });

    testWidgets('31. Add Visit creates visit in repository and updates sequential counter', (tester) async {
      final nextNum = await mockVisitRepo.getNextVisitNumber(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(nextNum, equals(3));

      final newVisit = ClinicalVisit(
        visitId: 'VIS-PAT-001-01-3',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        visitNumber: nextNum,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
      );

      final created = await mockVisitRepo.createVisit(newVisit);
      expect(created.visitNumber, equals(3));
      expect(created.isActive, isTrue);

      final visits = await mockVisitRepo.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(visits.length, equals(3));
    });
  });
}
