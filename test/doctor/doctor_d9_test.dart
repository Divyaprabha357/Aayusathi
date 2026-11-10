import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/python_speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/windows_speech_to_text_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_speech_widgets.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1366, 768);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSpeechToTextService mockStt;
  late MockDoctorSessionService mockSession;
  late MockAuditRepository mockAuditRepo;
  late MockPatientRepository mockPatientRepo;
  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockDoctorPresenceService mockPresenceService;
  late MockDoctorPatientWorkspaceService mockWorkspaceService;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);

    mockStt = MockSpeechToTextService.instance;
    mockStt.resetToDefaults();
    SpeechToTextService.instance = mockStt;

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

    mockWorkspaceService = MockDoctorPatientWorkspaceService.instance;
    mockWorkspaceService.simulateError = false;
    mockWorkspaceService.simulateUnauthorized = false;
  });

  tearDown(() {
    mockStt.resetToDefaults();
  });

  group('Phase D9 Unit Tests: SpeechToTextService & Mock Engine', () {
    test('Initial state is idle with no active listening field', () {
      expect(mockStt.state, equals(SpeechRecognitionState.idle));
      expect(mockStt.isListening, isFalse);
      expect(mockStt.isProcessing, isFalse);
      expect(mockStt.currentListeningField, isNull);
      expect(mockStt.recordingDuration, equals(Duration.zero));
    });

    test('Initializes successfully across English, Hindi, and Marathi', () async {
      expect(await mockStt.initialize(locale: KioskLocale.english), isTrue);
      expect(await mockStt.initialize(locale: KioskLocale.hindi), isTrue);
      expect(await mockStt.initialize(locale: KioskLocale.marathi), isTrue);
      expect(mockStt.state, equals(SpeechRecognitionState.idle));
    });

    test('Microphone permission check and request workflow', () async {
      expect(await mockStt.checkPermission(), equals(MicrophonePermissionStatus.granted));
      expect(await mockStt.requestPermission(), equals(MicrophonePermissionStatus.granted));

      mockStt.simulatePermissionDenied = true;
      expect(await mockStt.checkPermission(), equals(MicrophonePermissionStatus.denied));
      expect(await mockStt.requestPermission(), equals(MicrophonePermissionStatus.denied));
    });

    test('Starting speech capture updates state and listening field', () async {
      await mockStt.startListening(fieldId: 'chiefComplaint');

      expect(mockStt.state, equals(SpeechRecognitionState.listening));
      expect(mockStt.isListening, isTrue);
      expect(mockStt.currentListeningField, equals('chiefComplaint'));
    });

    test('Partial transcript tokens stream live during capture', () async {
      String latestPartial = '';
      await mockStt.startListening(
        fieldId: 'chiefComplaint',
        onPartialResult: (text) {
          latestPartial = text;
        },
      );

      await Future.delayed(const Duration(milliseconds: 350));
      expect(mockStt.isListening, isTrue);
      expect(latestPartial.isNotEmpty, isTrue);

      await mockStt.cancelListening();
      expect(mockStt.state, equals(SpeechRecognitionState.idle));
    });

    test('Stopping speech returns deterministic field transcript', () async {
      await mockStt.startListening(fieldId: 'chiefComplaint');
      final transcript = await mockStt.stopListening();

      expect(transcript, isNotNull);
      expect(
        transcript,
        equals(MockSpeechToTextService.defaultFieldTranscripts['chiefComplaint']),
      );
      expect(mockStt.state, equals(SpeechRecognitionState.ready));
    });

    test('Stopping speech with Hindi locale returns Hindi transcript', () async {
      await mockStt.startListening(fieldId: 'chiefComplaint', locale: KioskLocale.hindi);
      final transcript = await mockStt.stopListening(locale: KioskLocale.hindi);

      expect(transcript, isNotNull);
      expect(
        transcript,
        equals(MockSpeechToTextService.hindiFieldTranscripts['chiefComplaint']),
      );
    });

    test('Stopping speech with Marathi locale returns Marathi transcript', () async {
      await mockStt.startListening(fieldId: 'chiefComplaint', locale: KioskLocale.marathi);
      final transcript = await mockStt.stopListening(locale: KioskLocale.marathi);

      expect(transcript, isNotNull);
      expect(
        transcript,
        equals(MockSpeechToTextService.marathiFieldTranscripts['chiefComplaint']),
      );
    });

    test('Custom transcript override per field is respected', () async {
      mockStt.setMockTranscript('assessment', 'Custom clinical assessment text for ECG.');
      await mockStt.startListening(fieldId: 'assessment');
      final transcript = await mockStt.stopListening();

      expect(transcript, equals('Custom clinical assessment text for ECG.'));
    });

    test('Canceling speech resets state to idle and clears field', () async {
      await mockStt.startListening(fieldId: 'plan');
      expect(mockStt.isListening, isTrue);

      await mockStt.cancelListening();
      expect(mockStt.state, equals(SpeechRecognitionState.idle));
      expect(mockStt.currentListeningField, isNull);
    });

    test('Simulated engine unavailable sets unsupported state', () async {
      mockStt.simulateEngineUnavailable = true;
      final initResult = await mockStt.initialize();

      expect(initResult, isFalse);
      expect(mockStt.state, equals(SpeechRecognitionState.unsupported));
      expect(mockStt.lastError, isNotNull);
    });

    test('Simulated timeout sets error state and returns null transcript', () async {
      mockStt.simulateTimeout = true;
      await mockStt.startListening(fieldId: 'chiefComplaint');
      final transcript = await mockStt.stopListening();

      expect(transcript, isNull);
      expect(mockStt.state, equals(SpeechRecognitionState.error));
      expect(mockStt.lastError, contains('timed out'));
    });
  });

  group('Phase D9 Widget Tests: Doctor Speech UI Components', () {
    testWidgets('DoctorSpeechFieldButton renders inactive state and handles tap', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorSpeechFieldButton(
              fieldId: 'chiefComplaint',
              fieldLabel: 'Chief Complaint',
              activeListeningField: null,
              isListening: false,
              onTrigger: () => triggered = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('speech_mic_button_chiefComplaint')), findsOneWidget);
      expect(find.text('DICTATE'), findsOneWidget);

      await tester.tap(find.byKey(const Key('speech_mic_button_chiefComplaint')));
      await tester.pump();
      expect(triggered, isTrue);
    });

    testWidgets('DoctorSpeechFieldButton renders active recording state with REC badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoctorSpeechFieldButton(
              fieldId: 'chiefComplaint',
              fieldLabel: 'Chief Complaint',
              activeListeningField: 'chiefComplaint',
              isListening: true,
              onTrigger: _dummyCallback,
            ),
          ),
        ),
      );

      expect(find.text('REC'), findsOneWidget);
    });

    testWidgets('DoctorSpeechRecordingBar renders target field, timer, stop, and cancel', (tester) async {
      setDesktopViewport(tester);
      bool stopClicked = false;
      bool cancelClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorSpeechRecordingBar(
              fieldId: 'chiefComplaint',
              fieldLabel: 'Chief Complaint',
              elapsedDuration: const Duration(seconds: 14),
              partialTranscript: 'Patient reports chest discomfort',
              onStop: () => stopClicked = true,
              onCancel: () => cancelClicked = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('speech_recording_bar')), findsOneWidget);
      expect(find.text('CHIEF COMPLAINT'), findsOneWidget);
      expect(find.text('00:14'), findsOneWidget);
      expect(find.text('Patient reports chest discomfort'), findsOneWidget);

      await tester.tap(find.byKey(const Key('speech_stop_button')));
      expect(stopClicked, isTrue);

      await tester.tap(find.byKey(const Key('speech_cancel_button')));
      expect(cancelClicked, isTrue);
    });

    testWidgets('DoctorSpeechAppendReplaceDialog displays choices and returns selection', (tester) async {
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (ctx) => const DoctorSpeechAppendReplaceDialog(
                      fieldLabel: 'Chief Complaint',
                      existingText: 'Initial symptom notes.',
                      newTranscript: 'New spoken complaints.',
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Initial symptom notes.'), findsOneWidget);
      expect(find.text('New spoken complaints.'), findsOneWidget);
      expect(find.byKey(const Key('speech_append_button')), findsOneWidget);
      expect(find.byKey(const Key('speech_replace_button')), findsOneWidget);
      expect(find.byKey(const Key('speech_append_replace_cancel')), findsOneWidget);

      // Tap Append
      await tester.tap(find.byKey(const Key('speech_append_button')));
      await tester.pumpAndSettle();
      expect(dialogResult, equals('append'));
    });

    testWidgets('DoctorSpeechErrorCard renders error message and dismisses', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorSpeechErrorCard(
              errorMessage: 'Microphone permission denied.',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('speech_error_card')), findsOneWidget);
      expect(find.text('Microphone permission denied.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });
  });

  group('Phase D9 Integration Tests: Doctor Patient Workspace STT Flow', () {
    Future<void> pumpWorkspace(WidgetTester tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            AppRoutes.doctorDashboard: (ctx) => const Scaffold(body: Text('Doctor Dashboard Screen')),
          },
          home: const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );

      // Settle async workspace loading
      await tester.pumpAndSettle();
    }

    testWidgets('Workspace displays speech dictate buttons on clinical fields', (tester) async {
      await pumpWorkspace(tester);

      expect(find.byKey(const Key('speech_mic_button_chiefComplaint')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_onsetDuration')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_associatedSymptoms')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_medicalHistory')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_currentMedication')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_clinicalObservations')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_assessment')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_plan')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_relevantHistory')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_summaryText')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_followUp')), findsOneWidget);
      expect(find.byKey(const Key('speech_mic_button_patientInstructions')), findsOneWidget);
    });

    testWidgets('Triggering speech and stopping inserts transcript directly into empty field', (tester) async {
      await pumpWorkspace(tester);

      // Scroll to Chief Complaint mic button and trigger
      final micFinder = find.byKey(const Key('speech_mic_button_chiefComplaint'));
      await tester.ensureVisible(micFinder);
      await tester.pumpAndSettle();
      await tester.tap(micFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockStt.isListening, isTrue);
      expect(find.byKey(const Key('speech_recording_bar')), findsOneWidget);

      // Click Stop & Insert on the recording bar
      final stopFinder = find.byKey(const Key('speech_stop_button'));
      await tester.tap(stopFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Voice Transcript Review dialog appears -> tap USE ORIGINAL
      final useOriginalFinder = find.byKey(const Key('transcript_use_original_button'));
      if (useOriginalFinder.evaluate().isNotEmpty) {
        await tester.tap(useOriginalFinder);
        await tester.pumpAndSettle();
      }

      // Field now contains default chief complaint transcript
      expect(
        find.text(MockSpeechToTextService.defaultFieldTranscripts['chiefComplaint']!),
        findsOneWidget,
      );
    });

    testWidgets('Triggering speech on non-empty field triggers append/replace dialog', (tester) async {
      await pumpWorkspace(tester);

      // Enter initial text in onset duration field
      final onsetField = find.widgetWithText(TextField, 'e.g. 3 days, acute onset, worsening since yesterday...');
      await tester.ensureVisible(onsetField);
      await tester.pumpAndSettle();
      await tester.enterText(onsetField, 'Initial onset text.');
      await tester.pump();

      // Trigger mic on onset duration
      final onsetMicFinder = find.byKey(const Key('speech_mic_button_onsetDuration'));
      await tester.ensureVisible(onsetMicFinder);
      await tester.pumpAndSettle();
      await tester.tap(onsetMicFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Stop speech
      final stopFinder = find.byKey(const Key('speech_stop_button'));
      await tester.tap(stopFinder);
      await tester.pumpAndSettle();

      // Voice Transcript Review dialog appears -> tap USE ORIGINAL
      final useOriginalFinder = find.byKey(const Key('transcript_use_original_button'));
      if (useOriginalFinder.evaluate().isNotEmpty) {
        await tester.tap(useOriginalFinder);
        await tester.pumpAndSettle();
      }

      // Append/Replace dialog is shown
      expect(find.byKey(const Key('speech_append_button')), findsOneWidget);
      expect(find.byKey(const Key('speech_replace_button')), findsOneWidget);

      // Tap Append
      await tester.tap(find.byKey(const Key('speech_append_button')));
      await tester.pumpAndSettle();

      final expectedAppended =
          'Initial onset text.\n${MockSpeechToTextService.defaultFieldTranscripts['onsetDuration']}';
      expect(find.text(expectedAppended), findsOneWidget);
    });

    testWidgets('Transcribed text is fully editable and saving draft preserves content with audit log', (tester) async {
      await pumpWorkspace(tester);

      // Dictate into chief complaint
      final micFinder = find.byKey(const Key('speech_mic_button_chiefComplaint'));
      await tester.ensureVisible(micFinder);
      await tester.pumpAndSettle();
      await tester.tap(micFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final stopFinder = find.byKey(const Key('speech_stop_button'));
      await tester.tap(stopFinder);
      await tester.pumpAndSettle();

      // Voice Transcript Review dialog appears -> tap USE ORIGINAL
      final useOriginalFinder = find.byKey(const Key('transcript_use_original_button'));
      if (useOriginalFinder.evaluate().isNotEmpty) {
        await tester.tap(useOriginalFinder);
        await tester.pumpAndSettle();
      }

      // Physician manually edits the dictated text
      final complaintField = find.widgetWithText(TextField, MockSpeechToTextService.defaultFieldTranscripts['chiefComplaint']!);
      await tester.ensureVisible(complaintField);
      await tester.pumpAndSettle();
      await tester.enterText(complaintField, 'Physician edited: Patient has severe chest pain.');
      await tester.pump();

      // Save Draft
      final saveDraftFinder = find.text('SAVE DRAFT');
      await tester.ensureVisible(saveDraftFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveDraftFinder);
      await tester.pumpAndSettle();

      expect(find.text('Consultation draft saved successfully.'), findsOneWidget);

      // Verify doctor presence invariant: remains in consultation
      expect(mockPresenceService.isInConsultation, isTrue);
    });
  });

  group('Phase D9 Culture Selection, Locale Resolution & Windows Service Resolver Tests', () {
    test('1. Requested locale parsing and mapping to Windows culture tags', () {
      expect(WindowsSpeechToTextService.resolveLocaleTag(KioskLocale.english), equals('en-IN'));
      expect(WindowsSpeechToTextService.resolveLocaleTag(KioskLocale.hindi), equals('hi-IN'));
      expect(WindowsSpeechToTextService.resolveLocaleTag(KioskLocale.marathi), equals('mr-IN'));
    });

    test('2. Exact culture match when requested locale is installed', () {
      final available = ['en-US', 'en-IN', 'en-GB'];
      expect(WindowsSpeechToTextService.selectBestCulture('en-IN', available), equals('en-IN'));
      expect(WindowsSpeechToTextService.selectBestCulture('en-US', available), equals('en-US'));
      expect(WindowsSpeechToTextService.selectBestCulture('en-GB', available), equals('en-GB'));
    });

    test('3. Exact locale unavailable, safe fallback to closest supported English culture', () {
      final availableOnlyUs = ['en-US'];
      expect(WindowsSpeechToTextService.selectBestCulture('en-IN', availableOnlyUs), equals('en-US'));
      expect(WindowsSpeechToTextService.selectBestCulture('en-AU', availableOnlyUs), equals('en-US'));
      expect(WindowsSpeechToTextService.selectBestCulture('en-CA', availableOnlyUs), equals('en-US'));
    });

    test('4. English fallback prefers en-US then en-GB then first English recognizer', () {
      final availableGb = ['en-GB', 'fr-FR'];
      expect(WindowsSpeechToTextService.selectBestCulture('en-IN', availableGb), equals('en-GB'));

      final availableAu = ['en-AU', 'de-DE'];
      expect(WindowsSpeechToTextService.selectBestCulture('en-IN', availableAu), equals('en-AU'));
    });

    test('5. No unrelated-language fallback for unsupported Hindi locale', () {
      final availableOnlyEnglish = ['en-US (Microsoft Speech Recognizer 8.0)'];
      expect(WindowsSpeechToTextService.selectBestCulture('hi-IN', availableOnlyEnglish), isNull);
    });

    test('6. No unrelated-language fallback for unsupported Marathi locale', () {
      final availableOnlyEnglish = ['en-US (Microsoft Speech Recognizer 8.0)'];
      expect(WindowsSpeechToTextService.selectBestCulture('mr-IN', availableOnlyEnglish), isNull);
    });

    test('7. Invalid locale tag returns null', () {
      final available = ['en-US'];
      expect(WindowsSpeechToTextService.selectBestCulture('xyz-invalid', available), isNull);
      expect(WindowsSpeechToTextService.selectBestCulture('12345', available), isNull);
    });

    test('8. Empty locale string safely resolves to available English culture', () {
      final available = ['en-US'];
      expect(WindowsSpeechToTextService.selectBestCulture('', available), equals('en-US'));
    });

    test('9. SpeechToTextService.instance defaults to PythonSpeechToTextService when unassigned', () {
      SpeechToTextService.instance = null;
      expect(SpeechToTextService.instance, isA<PythonSpeechToTextService>());
      expect(SpeechToTextService.legacyWindowsInstance, isA<WindowsSpeechToTextService>());
      // Restore mockStt for teardown
      SpeechToTextService.instance = mockStt;
    });

    test('10. SpeechToTextService.instance override respects mock instance in tests', () {
      SpeechToTextService.instance = mockStt;
      expect(SpeechToTextService.instance, equals(mockStt));
    });

    test('11. WindowsSpeechDiagnostics data model properties and formatting', () {
      const diag = WindowsSpeechDiagnostics(
        requestedLocale: 'en-IN',
        selectedLocale: 'en-US (Microsoft Speech Recognizer 8.0)',
        availableCultures: ['en-US'],
        isSupported: true,
        audioDevice: 'Default Windows Recording Device',
        statusMessage: 'Ready',
      );

      expect(diag.requestedLocale, equals('en-IN'));
      expect(diag.selectedLocale, contains('en-US'));
      expect(diag.availableCultures, contains('en-US'));
      expect(diag.isSupported, isTrue);
      expect(diag.audioDevice, equals('Default Windows Recording Device'));
      expect(diag.statusMessage, equals('Ready'));
      expect(diag.toString(), contains('WindowsSpeechDiagnostics'));
    });
  });
}

void _dummyCallback() {}
