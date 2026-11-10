import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/prescription_item.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/speech_to_text_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_prescription_widgets.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

Widget buildTestableWidget(
  Widget child, {
  KioskLocale locale = KioskLocale.english,
  Map<String, dynamic>? initialArgs,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    routes: {
      AppRoutes.doctorDashboard: (ctx) =>
          const Scaffold(body: Text('Doctor Dashboard Screen')),
      AppRoutes.doctorPatientWorkspace: (ctx) =>
          DoctorPatientWorkspaceScreen(initialArguments: initialArgs),
    },
    home: Material(child: child),
  );
}

void setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1920, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late MockDoctorSessionService mockSession;
  late MockAuditRepository mockAuditRepo;
  late MockPatientRepository mockPatientRepo;
  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockDoctorPresenceService mockPresenceService;
  late MockDoctorPatientWorkspaceService mockWorkspaceService;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);

    mockAuditRepo = MockAuditRepository.instance;
    mockAuditRepo.clear();
    BackendProvider.instance.setCustomRepositories(auditRepo: mockAuditRepo);

    mockPresenceService = MockDoctorPresenceService();
    mockPresenceService.resetPresence();
    mockPresenceService.goOnline();
    mockPresenceService.setInConsultation();
    DoctorPresenceService.instance = mockPresenceService;

    mockSession = MockDoctorSessionService(auditRepository: mockAuditRepo);
    DoctorSessionService.instance = mockSession;
    await mockSession.enterDevelopmentWorkspace();
    mockPresenceService.setInConsultation();

    mockPatientRepo = MockPatientRepository.instance;
    mockPatientRepo.resetToDefaults();

    mockCaseRepo = MockCaseRepository.instance;
    mockCaseRepo.resetToDefaults();

    mockVisitRepo = MockClinicalVisitRepository.instance;
    mockVisitRepo.resetToDefaults();

    mockWorkspaceService = MockDoctorPatientWorkspaceService();
    DoctorPatientWorkspaceService.instance = mockWorkspaceService;
    SpeechToTextService.instance = MockSpeechToTextService();
  });

  group('AAYUSATHI Phase D9.1 — PrescriptionItem Model Unit Tests', () {
    test('1. PrescriptionItem default constructor initializes empty fields & detects incomplete state', () {
      final item = PrescriptionItem.empty();
      expect(item.medicineName, isEmpty);
      expect(item.duration, isEmpty);
      expect(item.timesPerDay, isEmpty);
      expect(item.remarks, isEmpty);
      expect(item.isComplete, isFalse);
      expect(item.isPartiallyFilled, isFalse);
      expect(item.missingFields, contains('Name of Medicine'));
      expect(item.missingFields, contains('Duration'));
      expect(item.missingFields, contains('Times a Day'));
      expect(item.missingFields, contains('Remarks'));
    });

    test('2. PrescriptionItem with complete mandatory fields validates as complete', () {
      const item = PrescriptionItem(
        medicineName: 'Tab Amlodipine 5mg',
        duration: '30 Days',
        timesPerDay: 'Once daily after breakfast',
        remarks: 'Monitor blood pressure',
      );
      expect(item.isComplete, isTrue);
      expect(item.missingFields, isEmpty);
    });

    test('3. PrescriptionItem detects partially filled rows', () {
      const item = PrescriptionItem(
        medicineName: 'Tab Paracetamol 500mg',
        duration: '',
        timesPerDay: 'SOS',
        remarks: '',
      );
      expect(item.isComplete, isFalse);
      expect(item.isPartiallyFilled, isTrue);
      expect(item.missingFields, contains('Duration'));
      expect(item.missingFields, contains('Remarks'));
    });

    test('4. PrescriptionItem serializes and deserializes accurately', () {
      const original = PrescriptionItem(
        medicineName: 'Tab Metformin 500mg',
        duration: '15 Days',
        timesPerDay: 'Twice daily',
        remarks: 'After food',
      );
      final map = original.toMap();
      final reconstructed = PrescriptionItem.fromMap(map);

      expect(reconstructed.medicineName, 'Tab Metformin 500mg');
      expect(reconstructed.duration, '15 Days');
      expect(reconstructed.timesPerDay, 'Twice daily');
      expect(reconstructed.remarks, 'After food');
      expect(reconstructed.isComplete, isTrue);
    });
  });

  group('AAYUSATHI Phase D9.1 — ClinicalVisit Prescriptions Integration Unit Tests', () {
    test('5. ClinicalVisit arePrescriptionsValid is true when no prescriptions exist', () {
      final visit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        doctorQualification: 'MBBS, MD',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        chiefComplaint: 'Chest pain',
        onsetDuration: '2 days',
        associatedSymptoms: 'Sweating',
        medicalHistory: 'None',
        currentMedication: 'None',
        clinicalObservations: 'Normal',
        assessment: 'Angina',
        plan: 'Rest',
        summaryText: 'Stable',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-101',
        approvedAt: DateTime.now(),
        prescriptions: const [],
      );

      expect(visit.arePrescriptionsValid, isTrue);
      expect(visit.canCompleteVisit, isTrue);
    });

    test('6. ClinicalVisit with incomplete prescription row blocks canCompleteVisit', () {
      final visit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        doctorQualification: 'MBBS, MD',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        chiefComplaint: 'Chest pain',
        onsetDuration: '2 days',
        associatedSymptoms: 'Sweating',
        medicalHistory: 'None',
        currentMedication: 'None',
        clinicalObservations: 'Normal',
        assessment: 'Angina',
        plan: 'Rest',
        summaryText: 'Stable',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-101',
        approvedAt: DateTime.now(),
        prescriptions: const [
          PrescriptionItem(
            medicineName: 'Tab Atorvastatin 20mg',
            duration: '', // Missing duration
            timesPerDay: 'Night',
            remarks: 'After dinner',
          ),
        ],
      );

      expect(visit.arePrescriptionsValid, isFalse);
      expect(visit.canCompleteVisit, isFalse);
      expect(
        visit.missingRequirements.any((r) => r.contains('Medicine 1')),
        isTrue,
      );
    });

    test('7. ClinicalVisit with fully complete prescriptions validates and serializes correctly', () {
      final visit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        doctorQualification: 'MBBS, MD',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        chiefComplaint: 'Chest pain',
        onsetDuration: '2 days',
        associatedSymptoms: 'Sweating',
        medicalHistory: 'None',
        currentMedication: 'None',
        clinicalObservations: 'Normal',
        assessment: 'Angina',
        plan: 'Rest',
        summaryText: 'Stable',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-101',
        approvedAt: DateTime.now(),
        prescriptions: const [
          PrescriptionItem(
            medicineName: 'Tab Amlodipine 5mg',
            duration: '30 Days',
            timesPerDay: 'OD',
            remarks: 'Morning',
          ),
          PrescriptionItem(
            medicineName: 'Tab Aspirin 75mg',
            duration: '30 Days',
            timesPerDay: 'OD',
            remarks: 'After food',
          ),
        ],
      );

      expect(visit.arePrescriptionsValid, isTrue);
      expect(visit.canCompleteVisit, isTrue);

      final map = visit.toMap();
      final reconstructed = ClinicalVisit.fromMap(map);
      expect(reconstructed.prescriptions.length, 2);
      expect(reconstructed.prescriptions[0].medicineName, 'Tab Amlodipine 5mg');
      expect(reconstructed.prescriptions[1].medicineName, 'Tab Aspirin 75mg');
    });
  });

  group('AAYUSATHI Phase D9.1 — Localization Strings Unit Tests', () {
    test('8. DoctorStrings English contains all prescription keys', () {
      final strings = DoctorLocalizations.forLocale(KioskLocale.english);
      expect(strings.prescription, 'PRESCRIPTION');
      expect(strings.numberOfMedicines, 'Number of Medicines');
      expect(strings.createPrescription, 'CREATE PRESCRIPTION');
      expect(strings.addMedicine, '+ ADD MEDICINE');
      expect(strings.srNo, 'Sr. No.');
      expect(strings.medicineName, 'Name of Medicine');
      expect(strings.duration, 'Duration');
      expect(strings.timesADay, 'Times a Day');
      expect(strings.remarks, 'Remarks');
      expect(strings.dictatePrescription, 'DICTATE PRESCRIPTION');
      expect(strings.useInPrescription, 'USE IN PRESCRIPTION');
      expect(strings.addToExistingPrescription, 'ADD TO EXISTING PRESCRIPTION');
      expect(strings.replacePrescription, 'REPLACE PRESCRIPTION');
    });

    test('9. DoctorStrings Hindi and Marathi contain localized prescription strings', () {
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      expect(hi.prescription, 'प्रिस्क्रिप्शन / औषधोपचार');
      expect(mr.prescription, 'औषधोपचार / प्रिस्क्रिप्शन');
      expect(hi.addMedicine, '+ दवाई जोड़ें');
      expect(mr.addMedicine, '+ औषध जोडा');
    });
  });

  group('AAYUSATHI Phase D9.1 — MockSpeechToTextService Prescription Unit Tests', () {
    test('10. MockSpeechToTextService returns deterministic prescription transcripts across locales', () async {
      final service = MockSpeechToTextService();

      // English
      await service.startListening(fieldId: 'prescription', locale: KioskLocale.english);
      final enResult = await service.stopListening();
      expect(enResult, contains('Paracetamol 500 mg'));
      expect(enResult, contains('Pantoprazole 40 mg'));

      // Hindi
      await service.startListening(fieldId: 'prescription', locale: KioskLocale.hindi);
      final hiResult = await service.stopListening();
      expect(hiResult, contains('पैरासिटामोल 500 मिलीग्राम'));

      // Marathi
      await service.startListening(fieldId: 'prescription', locale: KioskLocale.marathi);
      final mrResult = await service.stopListening();
      expect(mrResult, contains('पॅरासिटामॉल 500 मिग्रॅ'));
    });
  });

  group('AAYUSATHI Phase D9.1 — DoctorPrescriptionCard & Dialog Widget Tests', () {
    testWidgets('11. Initial state renders number of medicines prompt and CREATE PRESCRIPTION button', (tester) async {
      setDesktopViewport(tester);

      final rows = <PrescriptionRowControllers>[];
      int createdCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPrescriptionCard(
              rows: rows,
              onAddMedicine: () {},
              onRemoveMedicine: (idx) {},
              onCreateWithCount: (count) {
                createdCount = count;
              },
              onDictate: () {},
              onUseTranscript: () {},
              onDiscardTranscript: () {},
            ),
          ),
        ),
      );

      expect(find.text('PRESCRIPTION'), findsOneWidget);
      expect(find.byKey(const Key('prescription_generator_box')), findsOneWidget);
      expect(find.byKey(const Key('prescription_count_text')), findsOneWidget);
      expect(find.byKey(const Key('create_prescription_button')), findsOneWidget);

      // Increment count
      await tester.tap(find.byKey(const Key('prescription_count_increment')));
      await tester.pumpAndSettle();

      // Click create prescription
      await tester.tap(find.byKey(const Key('create_prescription_button')));
      await tester.pumpAndSettle();

      expect(createdCount, 4);
    });

    testWidgets('11b. Medicine counter stepper: visibility, limits, tooltips, and screen sizes', (tester) async {
      setDesktopViewport(tester);

      int createdCount = 0;
      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPrescriptionCard(
            rows: const [],
            onAddMedicine: () {},
            onRemoveMedicine: (_) {},
            onCreateWithCount: (count) {
              createdCount = count;
            },
            onDictate: () {},
            onUseTranscript: () {},
            onDiscardTranscript: () {},
          ),
        ),
      );

      final decFinder = find.byKey(const Key('prescription_count_decrement'));
      final incFinder = find.byKey(const Key('prescription_count_increment'));
      final textFinder = find.byKey(const Key('prescription_count_text'));

      expect(decFinder, findsOneWidget);
      expect(incFinder, findsOneWidget);
      expect(textFinder, findsOneWidget);

      // Verify tooltips for accessibility
      final decBtn = tester.widget<IconButton>(decFinder);
      final incBtn = tester.widget<IconButton>(incFinder);
      expect(decBtn.tooltip, 'Decrease number of medicines');
      expect(incBtn.tooltip, 'Increase number of medicines');

      // Verify initial count is 3
      expect(find.text('3'), findsOneWidget);

      // Decrement from 3 to 2
      await tester.tap(decFinder);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // Decrement from 2 to 1 (minimum limit)
      await tester.tap(decFinder);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // At minimum 1: decrement button must be disabled
      final disabledDecBtn = tester.widget<IconButton>(decFinder);
      expect(disabledDecBtn.onPressed, isNull);

      // Attempt to tap disabled decrement: count must remain 1
      await tester.tap(decFinder);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Increment from 1 to 20 (maximum limit)
      for (int i = 1; i < 20; i++) {
        await tester.tap(incFinder);
        await tester.pumpAndSettle();
      }
      expect(find.text('20'), findsOneWidget);

      // At maximum 20: increment button must be disabled
      final disabledIncBtn = tester.widget<IconButton>(incFinder);
      expect(disabledIncBtn.onPressed, isNull);

      // Attempt to tap disabled increment: count must remain 20
      await tester.tap(incFinder);
      await tester.pumpAndSettle();
      expect(find.text('20'), findsOneWidget);

      // CREATE PRESCRIPTION works with count 20
      await tester.tap(find.byKey(const Key('create_prescription_button')));
      await tester.pumpAndSettle();
      expect(createdCount, 20);

      // Test responsive behavior on compact viewport
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Renders prescription table with exact 5 columns and sequential Sr. No.', (tester) async {
      setDesktopViewport(tester);

      final rows = [
        PrescriptionRowControllers(
          medicineName: 'Tab Amlodipine 5mg',
          duration: '30 Days',
          timesPerDay: 'OD',
          remarks: 'Morning',
        ),
        PrescriptionRowControllers(
          medicineName: 'Tab Aspirin 75mg',
          duration: '30 Days',
          timesPerDay: 'OD',
          remarks: 'After food',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPrescriptionCard(
              rows: rows,
              onAddMedicine: () {},
              onRemoveMedicine: (idx) {},
              onCreateWithCount: (_) {},
              onDictate: () {},
              onUseTranscript: () {},
              onDiscardTranscript: () {},
            ),
          ),
        ),
      );

      // Verify Column headers
      expect(find.text('SR. NO.'), findsOneWidget);
      expect(find.text('NAME OF MEDICINE'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('TIMES A DAY'), findsOneWidget);
      expect(find.text('REMARKS'), findsOneWidget);

      // Verify Row 1 and Row 2 Sr. No. labels
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify populated text
      expect(find.text('Tab Amlodipine 5mg'), findsOneWidget);
      expect(find.text('Tab Aspirin 75mg'), findsOneWidget);

      // Verify single header dictate button and NO cell-level mic buttons
      expect(find.byKey(const Key('speech_mic_button_prescription')), findsOneWidget);
      expect(find.byKey(const Key('remove_medicine_button_0')), findsOneWidget);
      expect(find.byKey(const Key('remove_medicine_button_1')), findsOneWidget);
    });

    testWidgets('13. Add Medicine button and row deletion trigger callbacks', (tester) async {
      setDesktopViewport(tester);

      final rows = [
        PrescriptionRowControllers(medicineName: 'Med 1', duration: '5 Days', timesPerDay: 'OD', remarks: ''),
        PrescriptionRowControllers(medicineName: 'Med 2', duration: '10 Days', timesPerDay: 'BD', remarks: ''),
      ];
      bool addCalled = false;
      int removedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPrescriptionCard(
              rows: rows,
              onAddMedicine: () {
                addCalled = true;
              },
              onRemoveMedicine: (idx) {
                removedIndex = idx;
              },
              onCreateWithCount: (_) {},
              onDictate: () {},
              onUseTranscript: () {},
              onDiscardTranscript: () {},
            ),
          ),
        ),
      );

      // Tap + ADD MEDICINE
      await tester.tap(find.byKey(const Key('add_medicine_button')));
      await tester.pumpAndSettle();
      expect(addCalled, isTrue);

      // Tap Remove on row 0
      await tester.tap(find.byKey(const Key('remove_medicine_button_0')));
      await tester.pumpAndSettle();
      expect(removedIndex, 0);
    });

    testWidgets('14. Transcript review area renders with USE IN PRESCRIPTION and DISCARD buttons', (tester) async {
      setDesktopViewport(tester);

      final rows = <PrescriptionRowControllers>[];
      bool useTranscriptCalled = false;
      bool discardTranscriptCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPrescriptionCard(
              rows: rows,
              prescriptionTranscript: 'Tab Amlodipine 5mg 30 Days OD Morning',
              onAddMedicine: () {},
              onRemoveMedicine: (_) {},
              onCreateWithCount: (_) {},
              onDictate: () {},
              onUseTranscript: () {
                useTranscriptCalled = true;
              },
              onDiscardTranscript: () {
                discardTranscriptCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('prescription_transcript_box')), findsOneWidget);
      expect(find.text('Tab Amlodipine 5mg 30 Days OD Morning'), findsOneWidget);

      await tester.tap(find.byKey(const Key('use_in_prescription_button')));
      await tester.pumpAndSettle();
      expect(useTranscriptCalled, isTrue);

      await tester.tap(find.byKey(const Key('prescription_transcript_cancel_btn')));
      await tester.pumpAndSettle();
      expect(discardTranscriptCalled, isTrue);
    });

    testWidgets('15. DoctorPrescriptionAppendReplaceDialog renders options and returns selection', (tester) async {
      setDesktopViewport(tester);

      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (_) => const DoctorPrescriptionAppendReplaceDialog(existingCount: 2),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('prescription_append_replace_dialog')), findsOneWidget);
      expect(find.byKey(const Key('prescription_dialog_append')), findsOneWidget);
      expect(find.byKey(const Key('prescription_dialog_replace')), findsOneWidget);
      expect(find.byKey(const Key('prescription_dialog_cancel')), findsOneWidget);

      // Tap Append
      await tester.tap(find.byKey(const Key('prescription_dialog_append')));
      await tester.pumpAndSettle();
      expect(dialogResult, 'append');
    });
  });

  group('AAYUSATHI Phase D9.1 — Full Patient Workspace Prescription Integration Tests', () {
    testWidgets('16. Workspace creates prescription rows, saves draft, and preserves prescription data', (tester) async {
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

      // Verify Prescription Card is visible
      expect(find.text('PRESCRIPTION'), findsOneWidget);
      expect(find.byKey(const Key('create_prescription_button')), findsOneWidget);

      // Create 2 prescription rows
      await tester.tap(find.byKey(const Key('prescription_count_decrement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create_prescription_button')));
      await tester.pumpAndSettle();

      // Enter medicine details in row 1
      await tester.enterText(find.byKey(const Key('prescription_medicine_0')), 'Tab Telmisartan 40mg');
      await tester.enterText(find.byKey(const Key('prescription_duration_0')), '30 Days');
      await tester.enterText(find.byKey(const Key('prescription_times_0')), 'Once daily (OD)');
      await tester.enterText(find.byKey(const Key('prescription_remarks_0')), 'Morning after breakfast');
      await tester.pumpAndSettle();

      // Enter medicine details in row 2
      await tester.enterText(find.byKey(const Key('prescription_medicine_1')), 'Tab Hydrochlorothiazide 12.5mg');
      await tester.enterText(find.byKey(const Key('prescription_duration_1')), '30 Days');
      await tester.enterText(find.byKey(const Key('prescription_times_1')), 'Once daily (OD)');
      await tester.enterText(find.byKey(const Key('prescription_remarks_1')), 'Morning');
      await tester.pumpAndSettle();

      // Tap SAVE DRAFT in bottom bar
      await tester.tap(find.text('SAVE DRAFT'));
      await tester.pumpAndSettle();

      // Verify draft saved notice
      expect(find.text('Consultation draft saved successfully.'), findsOneWidget);

      // Verify repository updated with 2 complete prescription items
      final updatedVisits = await mockVisitRepo.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(updatedVisits.last.prescriptions.length, 2);
      expect(updatedVisits.last.prescriptions[0].medicineName, 'Tab Telmisartan 40mg');
      expect(updatedVisits.last.prescriptions[1].medicineName, 'Tab Hydrochlorothiazide 12.5mg');
    });

    testWidgets('17. Voice dictation into prescription populates transcript review and inserts parsed rows', (tester) async {
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

      // Trigger prescription speech dictation via header mic
      await tester.tap(find.byKey(const Key('speech_mic_button_prescription')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Floating recording bar should appear
      expect(find.byKey(const Key('speech_recording_bar')), findsOneWidget);

      // Stop speech recording
      await tester.tap(find.byKey(const Key('speech_stop_button')));
      await tester.pumpAndSettle();

      // Transcript review box should appear with transcribed text
      expect(find.byKey(const Key('prescription_transcript_box')), findsOneWidget);

      // Click USE IN PRESCRIPTION
      await tester.tap(find.byKey(const Key('use_in_prescription_button')));
      await tester.pumpAndSettle();

      // Table should now be populated with rows parsed from transcript
      expect(find.byKey(const Key('prescription_table_container')), findsOneWidget);
      expect(find.text('Paracetamol 500 mg'), findsOneWidget);
      expect(find.text('Pantoprazole 40 mg'), findsOneWidget);

      // Verify audit log for transcription used
      final auditLogs = mockAuditRepo.logs.where((l) => l.action == 'CONSULTATION_TRANSCRIPTION_USED');
      expect(auditLogs, isNotEmpty);
    });

    testWidgets('18. Multi-visit isolation: Adding a new visit creates distinct prescription workspace', (tester) async {
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

      // Create 1 medicine for Visit 1
      await tester.tap(find.byKey(const Key('prescription_count_decrement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prescription_count_decrement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create_prescription_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('prescription_medicine_0')), 'Tab Aspirin 75mg');
      await tester.enterText(find.byKey(const Key('prescription_duration_0')), '30 Days');
      await tester.enterText(find.byKey(const Key('prescription_times_0')), 'OD');
      await tester.enterText(find.byKey(const Key('prescription_remarks_0')), 'After food');
      await tester.pumpAndSettle();

      // Save Draft for Visit 1
      await tester.tap(find.text('SAVE DRAFT'));
      await tester.pumpAndSettle();
      expect(find.text('Consultation draft saved successfully.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Complete active visit so continuation can proceed
      final activeVisit = await mockVisitRepo.getActiveVisitForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      if (activeVisit != null) {
        await mockVisitRepo.completeVisit(
          patientId: 'PAT-MOCK-001',
          caseId: 'CASE-PAT-001-01',
          visitId: activeVisit.visitId,
          doctorId: 'DOC-101',
        );
      }

      // Add Visit 2 via + NEW VISIT button and confirmation dialog
      await tester.tap(find.text('+ NEW VISIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START NEW VISIT').last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Visit 2 has fresh generator prompt
      expect(find.byKey(const Key('prescription_generator_box')), findsOneWidget);

      // Create 1 medicine for Visit 2
      await tester.tap(find.byKey(const Key('prescription_count_decrement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prescription_count_decrement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create_prescription_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('prescription_medicine_0')), 'Tab Clopidogrel 75mg');
      await tester.enterText(find.byKey(const Key('prescription_duration_0')), '60 Days');
      await tester.enterText(find.byKey(const Key('prescription_times_0')), 'OD');
      await tester.enterText(find.byKey(const Key('prescription_remarks_0')), 'Morning');
      await tester.pumpAndSettle();

      // Save Draft for Visit 2
      await tester.tap(find.text('SAVE DRAFT'));
      await tester.pumpAndSettle();
      expect(find.text('Consultation draft saved successfully.'), findsOneWidget);

      // Verify repository has visits with distinct prescriptions
      final visits = await mockVisitRepo.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      final visitsWithPrescriptions = visits.where((v) => v.prescriptions.isNotEmpty).toList();
      expect(visitsWithPrescriptions.length, 2);
      expect(visitsWithPrescriptions[0].prescriptions.first.medicineName, 'Tab Aspirin 75mg');
      expect(visitsWithPrescriptions[1].prescriptions.first.medicineName, 'Tab Clopidogrel 75mg');
    });
  });
}
