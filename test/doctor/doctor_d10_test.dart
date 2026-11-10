import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/models/documentation_input.dart';
import 'package:aayusathi/doctor/models/documentation_summary_result.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/firebase_gemini_documentation_service.dart';
import 'package:aayusathi/doctor/services/gemini_documentation_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_gemini_documentation_service.dart';
import 'package:aayusathi/doctor/services/mock_speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/speech_to_text_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_gemini_widgets.dart';
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
  late MockGeminiDocumentationService mockGeminiService;

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

    mockGeminiService = MockGeminiDocumentationService.instance;
    mockGeminiService.resetToDefaults();
    GeminiDocumentationService.instance = mockGeminiService;
  });

  tearDown(() {
    mockGeminiService.resetToDefaults();
    GeminiDocumentationService.instance = null;
  });

  // =========================================================================
  // GROUP 1: Models Unit Tests (DocumentationInput & SummaryResult)
  // =========================================================================
  group('AAYUSATHI Phase D10 — Models Unit Tests', () {
    test('1.1 DocumentationInput.empty() validates incomplete status and lists all 8 missing fields', () {
      final input = DocumentationInput.empty();
      expect(input.isComplete, isFalse);
      expect(input.missingFields.length, equals(8));
      expect(input.missingFields, contains('Chief Complaint'));
      expect(input.missingFields, contains('Onset / Duration'));
      expect(input.missingFields, contains('Associated Symptoms'));
      expect(input.missingFields, contains('Medical History'));
      expect(input.missingFields, contains('Current Medication'));
      expect(input.missingFields, contains('Clinical Observations'));
      expect(input.missingFields, contains('Assessment'));
      expect(input.missingFields, contains('Plan'));
    });

    test('1.2 DocumentationInput detects partial completeness and missing specific fields', () {
      final input = DocumentationInput(
        chiefComplaint: 'Chest tightness',
        onsetDuration: '2 days',
        associatedSymptoms: 'Mild dyspnea',
        medicalHistory: 'Hypertension',
        currentMedication: 'Amlodipine 5mg',
        clinicalObservations: '',
        assessment: 'Angina pectoris',
        plan: '',
      );

      expect(input.isComplete, isFalse);
      expect(input.missingFields.length, equals(2));
      expect(input.missingFields, contains('Clinical Observations'));
      expect(input.missingFields, contains('Plan'));
    });

    test('1.3 DocumentationInput with all 8 mandatory fields has isComplete == true', () {
      final input = DocumentationInput(
        chiefComplaint: 'Fever and chills',
        onsetDuration: '3 days',
        associatedSymptoms: 'Headache, body ache',
        medicalHistory: 'None',
        currentMedication: 'Paracetamol PRN',
        clinicalObservations: 'Temp 101.4F, Pharyngeal erythema',
        assessment: 'Acute viral pharyngitis',
        plan: 'Rest, hydration, antipyretics',
        followUp: '3 days if fever persists',
        patientInstructions: 'Drink warm water and rest well',
      );

      expect(input.isComplete, isTrue);
      expect(input.missingFields, isEmpty);
    });

    test('1.4 DocumentationInput toMap() and fromMap() roundtrip preserves all fields', () {
      final original = DocumentationInput(
        chiefComplaint: 'Knee pain',
        onsetDuration: '1 month',
        associatedSymptoms: 'Morning stiffness',
        medicalHistory: 'Osteoarthritis',
        currentMedication: 'Glucosamine',
        clinicalObservations: 'Mild effusion right knee',
        assessment: 'Osteoarthritis right knee flare',
        plan: 'NSAID topical gel, physiotherapy',
        previousRelevantHistory: 'Right knee arthroscopy 2021',
        followUp: '2 weeks',
        patientInstructions: 'Avoid squatting and climbing stairs',
      );

      final map = original.toMap();
      final restored = DocumentationInput.fromMap(map);

      expect(restored.chiefComplaint, equals(original.chiefComplaint));
      expect(restored.onsetDuration, equals(original.onsetDuration));
      expect(restored.associatedSymptoms, equals(original.associatedSymptoms));
      expect(restored.medicalHistory, equals(original.medicalHistory));
      expect(restored.currentMedication, equals(original.currentMedication));
      expect(restored.clinicalObservations, equals(original.clinicalObservations));
      expect(restored.assessment, equals(original.assessment));
      expect(restored.plan, equals(original.plan));
      expect(restored.previousRelevantHistory, equals(original.previousRelevantHistory));
      expect(restored.followUp, equals(original.followUp));
      expect(restored.patientInstructions, equals(original.patientInstructions));
      expect(restored.isComplete, isTrue);
    });

    test('1.5 DocumentationSummaryResult success and failure factory constructors', () {
      final successResult = DocumentationSummaryResult.success(
        summary: 'Synthesized clinical summary text.',
        keyDocumentedFindings: ['Finding 1', 'Finding 2'],
        documentedAssessment: 'Documented assessment',
        documentedPlan: 'Documented plan',
      );

      expect(successResult.isSuccess, isTrue);
      expect(successResult.summary, equals('Synthesized clinical summary text.'));
      expect(successResult.keyDocumentedFindings.length, equals(2));
      expect(successResult.errorMessage, isNull);

      final failureResult = DocumentationSummaryResult.failure(
        errorMessage: 'Network timeout',
        errorCode: 'TIMEOUT',
      );

      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.summary, isEmpty);
      expect(failureResult.errorMessage, equals('Network timeout'));
      expect(failureResult.errorCode, equals('TIMEOUT'));
    });

    test('1.6 DocumentationSummaryResult toMap() and fromMap() roundtrip', () {
      final original = DocumentationSummaryResult.success(
        summary: 'Complete patient summary draft.',
        keyDocumentedFindings: ['CC: Cough', 'Obs: Clear lungs'],
        documentedAssessment: 'URTI',
        documentedPlan: 'Symptomatic care',
      );

      final map = original.toMap();
      final restored = DocumentationSummaryResult.fromMap(map);

      expect(restored.isSuccess, isTrue);
      expect(restored.summary, equals(original.summary));
      expect(restored.keyDocumentedFindings, equals(original.keyDocumentedFindings));
      expect(restored.documentedAssessment, equals(original.documentedAssessment));
      expect(restored.documentedPlan, equals(original.documentedPlan));
    });
  });

  // =========================================================================
  // GROUP 2: MockGeminiDocumentationService Unit Tests
  // =========================================================================
  group('AAYUSATHI Phase D10 — MockGeminiDocumentationService Unit Tests', () {
    final completeInput = DocumentationInput(
      chiefComplaint: 'Dry cough and sore throat',
      onsetDuration: '4 days',
      associatedSymptoms: 'Low grade fever',
      medicalHistory: 'Seasonal allergies',
      currentMedication: 'Cetirizine 10mg',
      clinicalObservations: 'Posterior pharyngeal wall congestion',
      assessment: 'Viral Upper Respiratory Tract Infection',
      plan: 'Steam inhalation, warm saline gargles, hydration',
      followUp: '5 days',
      patientInstructions: 'Rest voice, stay hydrated',
    );

    test('2.1 Deterministic English summary synthesis contains all input elements accurately', () async {
      final result = await mockGeminiService.generateDocumentationSummary(
        completeInput,
        locale: KioskLocale.english,
      );

      expect(result.isSuccess, isTrue);
      expect(result.summary, contains('Dry cough and sore throat'));
      expect(result.summary, contains('4 days'));
      expect(result.summary, contains('Low grade fever'));
      expect(result.summary, contains('Seasonal allergies'));
      expect(result.summary, contains('Cetirizine 10mg'));
      expect(result.summary, contains('Posterior pharyngeal wall congestion'));
      expect(result.summary, contains('Viral Upper Respiratory Tract Infection'));
      expect(result.summary, contains('Steam inhalation'));
      expect(result.summary, contains('Follow-up: 5 days'));
      expect(result.summary, contains('Patient Instructions: Rest voice, stay hydrated'));
      expect(result.keyDocumentedFindings.length, equals(5));
    });

    test('2.2 Deterministic Hindi summary synthesis produces localized text', () async {
      final result = await mockGeminiService.generateDocumentationSummary(
        completeInput,
        locale: KioskLocale.hindi,
      );

      expect(result.isSuccess, isTrue);
      expect(result.summary, contains('मरीज़'));
      expect(result.summary, contains('की शिकायत के साथ आया'));
      expect(result.summary, contains('संबंधित लक्षण:'));
      expect(result.summary, contains('उपचार योजना:'));
    });

    test('2.3 Deterministic Marathi summary synthesis produces localized text', () async {
      final result = await mockGeminiService.generateDocumentationSummary(
        completeInput,
        locale: KioskLocale.marathi,
      );

      expect(result.isSuccess, isTrue);
      expect(result.summary, contains('रुग्ण'));
      expect(result.summary, contains('च्या तक्रारीसह आला'));
      expect(result.summary, contains('संबंधित लक्षणे:'));
      expect(result.summary, contains('उपचार योजना:'));
    });

    test('2.4 Incomplete input fails with MISSING_MANDATORY_FIELDS error', () async {
      final incompleteInput = DocumentationInput(
        chiefComplaint: 'Back pain',
        onsetDuration: '',
        associatedSymptoms: '',
        medicalHistory: '',
        currentMedication: '',
        clinicalObservations: '',
        assessment: '',
        plan: '',
      );

      final result = await mockGeminiService.generateDocumentationSummary(incompleteInput);
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('MISSING_MANDATORY_FIELDS'));
      expect(result.errorMessage, contains('Missing required consultation fields'));
    });

    test('2.5 Error simulation flags: Network, Timeout, RateLimit, ServiceUnavailable, SafetyRefusal, Malformed, Empty', () async {
      // 1. Network Error
      mockGeminiService.simulateNetworkError = true;
      var res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('NETWORK_ERROR'));
      mockGeminiService.simulateNetworkError = false;

      // 2. Timeout
      mockGeminiService.simulateTimeout = true;
      res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('TIMEOUT'));
      mockGeminiService.simulateTimeout = false;

      // 3. Rate Limit
      mockGeminiService.simulateRateLimit = true;
      res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('RATE_LIMITED'));
      mockGeminiService.simulateRateLimit = false;

      // 4. Service Unavailable
      mockGeminiService.simulateServiceUnavailable = true;
      res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('SERVICE_UNAVAILABLE'));
      mockGeminiService.simulateServiceUnavailable = false;

      // 5. Safety Refusal
      mockGeminiService.simulateSafetyRefusal = true;
      res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('SAFETY_REFUSAL'));
      mockGeminiService.simulateSafetyRefusal = false;

      // 6. Malformed Response
      mockGeminiService.simulateMalformedResponse = true;
      res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('MALFORMED_RESPONSE'));
      mockGeminiService.simulateMalformedResponse = false;

      // 7. Empty Response
      mockGeminiService.simulateEmptyResponse = true;
      res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('EMPTY_RESPONSE'));
      mockGeminiService.simulateEmptyResponse = false;
    });

    test('2.6 Custom summary override works as expected', () async {
      mockGeminiService.customSummaryOverride = 'Custom Doctor Note Summary Test';
      final res = await mockGeminiService.generateDocumentationSummary(completeInput);
      expect(res.isSuccess, isTrue);
      expect(res.summary, equals('Custom Doctor Note Summary Test'));
    });
  });

  // =========================================================================
  // GROUP 3: Service Resolution & Dev Mode Priority Unit Tests
  // =========================================================================
  group('AAYUSATHI Phase D10 — Service Resolution Unit Tests', () {
    test('3.1 Development Mode prioritizes MockGeminiDocumentationService', () {
      GeminiDocumentationService.instance = null; // Clear override
      expect(DoctorSessionService.instance.isDevelopmentMode, isTrue);
      final resolved = GeminiDocumentationService.instance;
      expect(resolved, isA<MockGeminiDocumentationService>());
    });

    test('3.2 FirebaseGeminiDocumentationService gracefully falls back when uninitialized', () async {
      final service = FirebaseGeminiDocumentationService.instance;
      final completeInput = DocumentationInput(
        chiefComplaint: 'Headache',
        onsetDuration: '1 day',
        associatedSymptoms: 'Nausea',
        medicalHistory: 'None',
        currentMedication: 'None',
        clinicalObservations: 'Normal vitals, no meningism',
        assessment: 'Tension headache',
        plan: 'Rest and hydration',
      );

      final result = await service.generateDocumentationSummary(completeInput);
      expect(result.isSuccess, isTrue);
      expect(result.summary, contains('Headache'));
    });
  });

  // =========================================================================
  // GROUP 4: DoctorGeminiDocumentationCard & Dialog Widget Unit Tests
  // =========================================================================
  group('AAYUSATHI Phase D10 — Widget Unit Tests', () {
    testWidgets('4.1 DoctorGeminiDocumentationCard displays incomplete notice when isComplete is false', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorGeminiDocumentationCard(
            isGenerating: false,
            isComplete: false,
            missingFields: const ['Chief Complaint', 'Assessment'],
            onGenerate: () {},
            onRegenerate: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gemini_documentation_card')), findsOneWidget);
      expect(find.byKey(const Key('gemini_incomplete_notice')), findsOneWidget);
      expect(find.textContaining('Missing: Chief Complaint, Assessment'), findsOneWidget);
      expect(find.byKey(const Key('generate_draft_summary_button')), findsNothing);
    });

    testWidgets('4.2 DoctorGeminiDocumentationCard displays [ GENERATE DRAFT SUMMARY ] button when isComplete is true and hasDraft is false', (tester) async {
      setDesktopViewport(tester);
      var generateCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorGeminiDocumentationCard(
            isGenerating: false,
            isComplete: true,
            hasDraft: false,
            onGenerate: () {
              generateCalled = true;
            },
            onRegenerate: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gemini_incomplete_notice')), findsNothing);
      expect(find.byKey(const Key('generate_draft_summary_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('generate_draft_summary_button')));
      await tester.pumpAndSettle();

      expect(generateCalled, isTrue);
    });

    testWidgets('4.3 DoctorGeminiDocumentationCard displays [ REGENERATE DRAFT ] button when hasDraft is true', (tester) async {
      setDesktopViewport(tester);
      var regenerateCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorGeminiDocumentationCard(
            isGenerating: false,
            isComplete: true,
            hasDraft: true,
            onGenerate: () {},
            onRegenerate: () {
              regenerateCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('generate_draft_summary_button')), findsNothing);
      expect(find.byKey(const Key('regenerate_draft_summary_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('regenerate_draft_summary_button')));
      await tester.pumpAndSettle();

      expect(regenerateCalled, isTrue);
    });

    testWidgets('4.4 DoctorGeminiDocumentationCard displays generating spinner during isGenerating == true', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorGeminiDocumentationCard(
            isGenerating: true,
            isComplete: true,
            onGenerate: () {},
            onRegenerate: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('gemini_generating_indicator')), findsOneWidget);
      expect(find.text('AI is preparing documentation draft...'), findsOneWidget);
    });

    testWidgets('4.5 DoctorGeminiDocumentationCard displays error banner with dismiss action', (tester) async {
      setDesktopViewport(tester);
      var dismissCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorGeminiDocumentationCard(
            isGenerating: false,
            isComplete: true,
            errorMessage: 'Network connection failed.',
            onGenerate: () {},
            onRegenerate: () {},
            onDismissError: () {
              dismissCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gemini_error_banner')), findsOneWidget);
      expect(find.text('Network connection failed.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(dismissCalled, isTrue);
    });

    testWidgets('4.6 DoctorRegenerateWarningDialog allows Cancel and Confirm', (tester) async {
      setDesktopViewport(tester);

      bool? dialogResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_dialog_button'),
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: ctx,
                    builder: (dCtx) => const DoctorRegenerateWarningDialog(),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog and test Cancel
      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gemini_regenerate_warning_dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('gemini_dialog_cancel')));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);

      // Open dialog and test Confirm
      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('gemini_dialog_confirm')));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });
  });

  // =========================================================================
  // GROUP 5: Workspace Integration Tests (Phase D10 Gemini Documentation Flow)
  // =========================================================================
  group('AAYUSATHI Phase D10 — Doctor Patient Workspace Integration Tests', () {
    testWidgets('5.1 Workspace loads and displays Gemini Documentation card in incomplete state initially', (tester) async {
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

      // Verify Gemini Documentation card exists
      expect(find.byKey(const Key('gemini_documentation_card')), findsOneWidget);
      expect(find.text('AI ASSISTED'), findsOneWidget);
      expect(find.text('DEV MODE'), findsOneWidget);
    });

    testWidgets('5.2 Filling all 8 mandatory consultation fields enables [ GENERATE DRAFT SUMMARY ] button', (tester) async {
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

      // Populate 8 mandatory fields
      await tester.enterText(find.byKey(const Key('field_chiefComplaint')), 'Persistent productive cough');
      await tester.enterText(find.byKey(const Key('field_onsetDuration')), '5 days');
      await tester.enterText(find.byKey(const Key('field_associatedSymptoms')), 'Low grade fever, chest congestion');
      await tester.enterText(find.byKey(const Key('field_medicalHistory')), 'No chronic illnesses');
      await tester.enterText(find.byKey(const Key('field_currentMedication')), 'None');
      await tester.enterText(find.byKey(const Key('field_clinicalObservations')), 'Bilateral coarse crackles, SpO2 97%');
      await tester.enterText(find.byKey(const Key('field_assessment')), 'Acute Bronchitis');
      await tester.enterText(find.byKey(const Key('field_plan')), 'Expectorant syrup, hydration, warm fluids');
      await tester.pumpAndSettle();

      // Verify [ GENERATE DRAFT SUMMARY ] button is now rendered
      expect(find.byKey(const Key('generate_draft_summary_button')), findsOneWidget);
    });

    testWidgets('5.3 Generating draft populates summary field, sets REVIEW REQUIRED, and creates audit log', (tester) async {
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

      // Populate 8 mandatory fields
      await tester.enterText(find.byKey(const Key('field_chiefComplaint')), 'Throat pain and difficulty swallowing');
      await tester.enterText(find.byKey(const Key('field_onsetDuration')), '2 days');
      await tester.enterText(find.byKey(const Key('field_associatedSymptoms')), 'Mild fever');
      await tester.enterText(find.byKey(const Key('field_medicalHistory')), 'None');
      await tester.enterText(find.byKey(const Key('field_currentMedication')), 'None');
      await tester.enterText(find.byKey(const Key('field_clinicalObservations')), 'Erythematous tonsils');
      await tester.enterText(find.byKey(const Key('field_assessment')), 'Acute Tonsillitis');
      await tester.enterText(find.byKey(const Key('field_plan')), 'Analgesics, warm saline gargles');
      await tester.pumpAndSettle();

      // Click [ GENERATE DRAFT SUMMARY ]
      await tester.tap(find.byKey(const Key('generate_draft_summary_button')));
      await tester.pump(); // Start async generation
      await tester.pump(const Duration(milliseconds: 300)); // Complete async delay
      await tester.pumpAndSettle();

      // Verify Summary Text is populated
      final summaryField = tester.widget<TextField>(find.byKey(const Key('field_visit_summary')));
      expect(summaryField.controller?.text, contains('Throat pain and difficulty swallowing'));
      expect(summaryField.controller?.text, contains('Acute Tonsillitis'));

      // Verify Summary status badge shows REVIEW REQUIRED (not auto-approved)
      expect(find.text('REVIEW REQUIRED'), findsOneWidget);

      // Verify Audit Log
      final genLogs = mockAuditRepo.logs.where((l) => l.action == 'AI_DOCUMENTATION_GENERATED').toList();
      expect(genLogs, isNotEmpty);
      expect(genLogs.first.entityType, equals('CLINICAL_VISIT'));
    });

    testWidgets('5.4 Generated summary is strictly draft; doctor edits summary and approves it manually', (tester) async {
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

      // Fill 8 fields and generate
      await tester.enterText(find.byKey(const Key('field_chiefComplaint')), 'Epigastric burning');
      await tester.enterText(find.byKey(const Key('field_onsetDuration')), '1 week');
      await tester.enterText(find.byKey(const Key('field_associatedSymptoms')), 'Bloating after meals');
      await tester.enterText(find.byKey(const Key('field_medicalHistory')), 'GERD');
      await tester.enterText(find.byKey(const Key('field_currentMedication')), 'Antacids OTC');
      await tester.enterText(find.byKey(const Key('field_clinicalObservations')), 'Epigastric tenderness');
      await tester.enterText(find.byKey(const Key('field_assessment')), 'Gastritis with GERD');
      await tester.enterText(find.byKey(const Key('field_plan')), 'PPI therapy, dietary modifications');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('generate_draft_summary_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Edit summary text manually
      await tester.enterText(find.byKey(const Key('field_visit_summary')), 'Edited by Doctor: Verified Gastritis with GERD.');
      await tester.pumpAndSettle();

      // Verify AI_DOCUMENTATION_REVIEWED audit log
      final reviewLogs = mockAuditRepo.logs.where((l) => l.action == 'AI_DOCUMENTATION_REVIEWED').toList();
      expect(reviewLogs, isNotEmpty);

      // Now approve the summary
      await tester.tap(find.byKey(const Key('btn_approve_summary')));
      await tester.pumpAndSettle();

      // Verify status badge changed to APPROVED BY DOCTOR
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);

      // Verify SUMMARY_APPROVED audit log
      final approveLogs = mockAuditRepo.logs.where((l) => l.action == 'SUMMARY_APPROVED').toList();
      expect(approveLogs, isNotEmpty);
    });

    testWidgets('5.5 Regenerate warning dialog triggers on [ REGENERATE DRAFT ] and resets approval status on confirm', (tester) async {
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

      // Fill 8 fields and generate
      await tester.enterText(find.byKey(const Key('field_chiefComplaint')), 'Headache');
      await tester.enterText(find.byKey(const Key('field_onsetDuration')), '2 days');
      await tester.enterText(find.byKey(const Key('field_associatedSymptoms')), 'Photophobia');
      await tester.enterText(find.byKey(const Key('field_medicalHistory')), 'Migraine');
      await tester.enterText(find.byKey(const Key('field_currentMedication')), 'None');
      await tester.enterText(find.byKey(const Key('field_clinicalObservations')), 'Normal neurological exam');
      await tester.enterText(find.byKey(const Key('field_assessment')), 'Acute Migraine without aura');
      await tester.enterText(find.byKey(const Key('field_plan')), 'NSAID, rest in dark room');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('generate_draft_summary_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Approve summary first
      await tester.tap(find.byKey(const Key('btn_approve_summary')));
      await tester.pumpAndSettle();
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);

      // Now click [ REGENERATE DRAFT ]
      await tester.tap(find.byKey(const Key('regenerate_draft_summary_button')));
      await tester.pumpAndSettle();

      // Verify warning dialog opened
      expect(find.byKey(const Key('gemini_regenerate_warning_dialog')), findsOneWidget);

      // Cancel dialog first
      await tester.tap(find.byKey(const Key('gemini_dialog_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget); // Status unchanged

      // Re-trigger and confirm
      await tester.tap(find.byKey(const Key('regenerate_draft_summary_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gemini_dialog_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Status reset to REVIEW REQUIRED
      expect(find.text('REVIEW REQUIRED'), findsOneWidget);

      // Verify AI_DOCUMENTATION_REGENERATED audit log
      final regenLogs = mockAuditRepo.logs.where((l) => l.action == 'AI_DOCUMENTATION_REGENERATED').toList();
      expect(regenLogs, isNotEmpty);
    });

    testWidgets('5.6 Prescriptions and investigation requests remain completely untouched during Gemini draft generation', (tester) async {
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

      // 1. Add Prescription row
      await tester.tap(find.byKey(const Key('prescription_count_decrement')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create_prescription_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('prescription_medicine_0')), 'Amoxicillin 500mg');
      await tester.enterText(find.byKey(const Key('prescription_duration_0')), '5 days');
      await tester.enterText(find.byKey(const Key('prescription_times_0')), '3 times a day');
      await tester.enterText(find.byKey(const Key('prescription_remarks_0')), 'After food');
      await tester.pumpAndSettle();

      // 2. Fill consultation fields & generate summary
      await tester.enterText(find.byKey(const Key('field_chiefComplaint')), 'Ear pain');
      await tester.enterText(find.byKey(const Key('field_onsetDuration')), '3 days');
      await tester.enterText(find.byKey(const Key('field_associatedSymptoms')), 'Hearing fullness');
      await tester.enterText(find.byKey(const Key('field_medicalHistory')), 'None');
      await tester.enterText(find.byKey(const Key('field_currentMedication')), 'None');
      await tester.enterText(find.byKey(const Key('field_clinicalObservations')), 'Bulging tympanic membrane');
      await tester.enterText(find.byKey(const Key('field_assessment')), 'Acute Otitis Media');
      await tester.enterText(find.byKey(const Key('field_plan')), 'Oral antibiotics and analgesics');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('generate_draft_summary_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify Prescription item remains intact and untouched
      final medField = tester.widget<TextField>(find.byKey(const Key('prescription_medicine_0')));
      expect(medField.controller?.text, equals('Amoxicillin 500mg'));
    });
  });
}
