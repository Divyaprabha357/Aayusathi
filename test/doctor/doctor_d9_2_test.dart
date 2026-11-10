import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/documentation_input.dart';
import 'package:aayusathi/doctor/models/transcript_cleanup_input.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/firebase_gemini_transcript_cleanup_service.dart';
import 'package:aayusathi/doctor/services/gemini_documentation_service.dart';
import 'package:aayusathi/doctor/services/gemini_transcript_cleanup_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_gemini_documentation_service.dart';
import 'package:aayusathi/doctor/services/mock_gemini_transcript_cleanup_service.dart';
import 'package:aayusathi/doctor/services/mock_speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/speech_to_text_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_transcript_cleanup_dialog.dart';
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
  late MockGeminiTranscriptCleanupService mockCleanup;
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

    mockCleanup = MockGeminiTranscriptCleanupService.instance;
    mockCleanup.resetToDefaults();
    GeminiTranscriptCleanupService.instance = mockCleanup;

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
    mockCleanup.resetToDefaults();
    GeminiTranscriptCleanupService.instance = null;
    SpeechToTextService.instance = null;
  });

  // =========================================================================
  // GROUP 1: DTOs & Validation (Tests 1 - 3, 27 - 31)
  // =========================================================================
  group('Phase D9.2: DTOs, Security & Privacy Validation', () {
    test('1. TranscriptCleanupInput creation & serialization', () {
      const input = TranscriptCleanupInput(
        transcript: 'patient has headache for three days',
        locale: KioskLocale.english,
      );

      expect(input.transcript, equals('patient has headache for three days'));
      expect(input.locale, equals(KioskLocale.english));
      expect(input.characterCount, equals(35));
      expect(input.isValid, isTrue);

      final map = input.toMap();
      expect(map['transcript'], equals('patient has headache for three days'));
      expect(map['locale'], equals('english'));

      final restored = TranscriptCleanupInput.fromMap(map);
      expect(restored.transcript, equals(input.transcript));
      expect(restored.locale, equals(input.locale));
    });

    test('2. Empty transcript validation', () {
      const emptyInput = TranscriptCleanupInput(transcript: '   ');
      expect(emptyInput.isEmpty, isTrue);
      expect(emptyInput.isValid, isFalse);
    });

    test('3. Maximum transcript length enforcement (4000 characters)', () {
      final longText = 'A' * 4001;
      final longInput = TranscriptCleanupInput(transcript: longText);
      expect(longInput.isTooLong, isTrue);
      expect(longInput.isValid, isFalse);

      final validLongText = 'B' * 4000;
      final validLongInput = TranscriptCleanupInput(transcript: validLongText);
      expect(validLongInput.isTooLong, isFalse);
      expect(validLongInput.isValid, isTrue);
    });

    test('27-31. Privacy verification: DTO contains only transcript and locale', () {
      const input = TranscriptCleanupInput(
        transcript: 'patient reports mild fever and dry cough',
        locale: KioskLocale.hindi,
      );

      final map = input.toMap();
      // No PII, Aadhaar, OTP, password, auth tokens, or audio buffers in map
      expect(map.keys, containsAll(['transcript', 'locale']));
      expect(map.keys.length, equals(2));
      expect(map.containsKey('aadhaar'), isFalse);
      expect(map.containsKey('otp'), isFalse);
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('audio'), isFalse);
      expect(map.containsKey('authToken'), isFalse);
    });
  });

  // =========================================================================
  // GROUP 2: Service Architecture & Resolver (Tests 4 - 7)
  // =========================================================================
  group('Phase D9.2: Service Architecture & Development Mode Resolution', () {
    test('4. MockGeminiTranscriptCleanupService performs deterministic cleanup', () async {
      const input = TranscriptCleanupInput(
        transcript: 'patient has had ake headache from three days',
        locale: KioskLocale.english,
      );

      final result = await mockCleanup.cleanupTranscript(input);
      expect(result.isSuccess, isTrue);
      expect(result.rawTranscript, equals('patient has had ake headache from three days'));
      expect(result.cleanedTranscript, equals('Patient has had a headache for three days.'));
      expect(result.isDevelopmentMock, isTrue);
    });

    test('5. Development Mode resolves to MockGeminiTranscriptCleanupService and Real/Mock STT', () {
      GeminiTranscriptCleanupService.instance = null;
      expect(DoctorSessionService.instance.isDevelopmentMode, isTrue);
      expect(GeminiTranscriptCleanupService.instance, isA<MockGeminiTranscriptCleanupService>());
    });

    test('6. Production service abstraction (FirebaseGeminiTranscriptCleanupService)', () async {
      final firebaseService = FirebaseGeminiTranscriptCleanupService.instance;
      expect(firebaseService, isA<GeminiTranscriptCleanupService>());

      // Empty input validation on Firebase service
      final emptyResult = await firebaseService.cleanupTranscript(
        const TranscriptCleanupInput(transcript: ''),
      );
      expect(emptyResult.isSuccess, isFalse);
      expect(emptyResult.errorCode, equals('EMPTY_INPUT'));
    });

    test('7. D10 Gemini Documentation service remains strictly separate', () {
      expect(GeminiDocumentationService.instance, isA<MockGeminiDocumentationService>());
      expect(GeminiTranscriptCleanupService.instance, isA<MockGeminiTranscriptCleanupService>());
      expect(
        GeminiDocumentationService.instance.runtimeType !=
            GeminiTranscriptCleanupService.instance.runtimeType,
        isTrue,
      );
    });
  });

  // =========================================================================
  // GROUP 3: Clinical Safety & Zero Hallucination Tests (Tests 21 - 26)
  // =========================================================================
  group('Phase D9.2: Clinical Safety & Zero Hallucination Invariants', () {
    test('21-22. No diagnosis generation: headache is NEVER changed to migraine', () async {
      const input = TranscriptCleanupInput(
        transcript: 'patient has headache',
        locale: KioskLocale.english,
      );

      final result = await mockCleanup.cleanupTranscript(input);
      expect(result.cleanedTranscript, equals('Patient has a headache.'));
      expect(result.cleanedTranscript.toLowerCase().contains('migraine'), isFalse);
    });

    test('23-24. No medication or dosage invention: paracetamol does NOT gain 500mg TDS', () async {
      const input = TranscriptCleanupInput(
        transcript: 'patient taking paracetamol',
        locale: KioskLocale.english,
      );

      final result = await mockCleanup.cleanupTranscript(input);
      expect(result.cleanedTranscript, equals('Patient is taking paracetamol.'));
      expect(result.cleanedTranscript.contains('500 mg'), isFalse);
      expect(result.cleanedTranscript.contains('three times'), isFalse);
    });

    test('25-26. Preservation of numbers & measurements without adding treatment/investigations', () async {
      const input = TranscriptCleanupInput(
        transcript: 'blood pressure one twenty over eighty',
        locale: KioskLocale.english,
      );

      final result = await mockCleanup.cleanupTranscript(input);
      expect(result.cleanedTranscript, equals('Blood pressure 120/80 mmHg.'));
      expect(result.cleanedTranscript.contains('120/80'), isTrue);
    });

    test('Strict preservation of clinical negations (patient denies fever)', () async {
      const input = TranscriptCleanupInput(
        transcript: 'patient denies fever',
        locale: KioskLocale.english,
      );

      final result = await mockCleanup.cleanupTranscript(input);
      expect(result.cleanedTranscript, equals('Patient denies fever.'));
      expect(result.cleanedTranscript.toLowerCase().contains('denies'), isTrue);
    });
  });

  // =========================================================================
  // GROUP 4: Failure & Ambiguity Scenarios (Tests 16 - 20)
  // =========================================================================
  group('Phase D9.2: Error Simulation & Ambiguity Handling', () {
    test('16. Network error simulation preserves raw transcript', () async {
      mockCleanup.simulateNetworkError = true;
      final result = await mockCleanup.cleanupTranscript(
        const TranscriptCleanupInput(transcript: 'patient has fever'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('NETWORK_ERROR'));
      expect(result.rawTranscript, equals('patient has fever'));
      expect(result.cleanedTranscript, equals('patient has fever'));
    });

    test('17. Malformed AI response handling', () async {
      mockCleanup.simulateMalformedResponse = true;
      final result = await mockCleanup.cleanupTranscript(
        const TranscriptCleanupInput(transcript: 'patient has cough'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('MALFORMED_RESPONSE'));
    });

    test('18. Empty AI response handling', () async {
      mockCleanup.simulateEmptyResponse = true;
      final result = await mockCleanup.cleanupTranscript(
        const TranscriptCleanupInput(transcript: 'patient has pain'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('EMPTY_RESPONSE'));
    });

    test('19. Safety refusal handling', () async {
      mockCleanup.simulateSafetyRefusal = true;
      final result = await mockCleanup.cleanupTranscript(
        const TranscriptCleanupInput(transcript: 'patient has rash'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('SAFETY_REFUSAL'));
    });

    test('20. Ambiguous / truncated words flagged in uncertainSegments', () async {
      final result = await mockCleanup.cleanupTranscript(
        const TranscriptCleanupInput(transcript: 'patient has dizzi...'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.hasUncertainties, isTrue);
      expect(result.uncertainSegments, contains('dizzi...'));
    });
  });

  // =========================================================================
  // GROUP 5: Review Modal UI & Acceptance Actions (Tests 8 - 15)
  // =========================================================================
  group('Phase D9.2: Doctor Voice Transcript Review Modal Widget Tests', () {
    testWidgets('8-9. Modal displays original STT transcript and AI cleaned draft', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  await showDialog<DoctorTranscriptReviewResult>(
                    context: ctx,
                    builder: (dialogCtx) => const DoctorVoiceTranscriptReviewDialog(
                      fieldId: 'chiefComplaint',
                      fieldLabel: 'Chief Complaint',
                      originalTranscript: 'patient has had ake headache from three days',
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      expect(find.text('VOICE TRANSCRIPT REVIEW'), findsOneWidget);
      expect(find.byKey(const Key('transcript_original_container')), findsOneWidget);
      expect(find.byKey(const Key('transcript_cleaned_container')), findsOneWidget);
      expect(find.text('patient has had ake headache from three days'), findsOneWidget);
      expect(find.text('Patient has had a headache for three days.'), findsOneWidget);
      expect(find.byKey(const Key('transcript_use_cleaned_button')), findsOneWidget);
      expect(find.byKey(const Key('transcript_use_original_button')), findsOneWidget);
      expect(find.byKey(const Key('transcript_edit_button')), findsOneWidget);
      expect(find.byKey(const Key('transcript_clean_again_button')), findsOneWidget);
    });

    testWidgets('10. USE CLEANED VERSION returns cleaned text with CLEANED choice', (tester) async {
      setDesktopViewport(tester);

      DoctorTranscriptReviewResult? reviewResult;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  reviewResult = await showDialog<DoctorTranscriptReviewResult>(
                    context: ctx,
                    builder: (dialogCtx) => const DoctorVoiceTranscriptReviewDialog(
                      fieldId: 'chiefComplaint',
                      fieldLabel: 'Chief Complaint',
                      originalTranscript: 'patient has had ake headache from three days',
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transcript_use_cleaned_button')));
      await tester.pumpAndSettle();

      expect(reviewResult, isNotNull);
      expect(reviewResult!.acceptedText, equals('Patient has had a headache for three days.'));
      expect(reviewResult!.choiceType, equals(TranscriptChoiceType.cleaned));
    });

    testWidgets('11. USE ORIGINAL returns raw STT text with ORIGINAL choice', (tester) async {
      setDesktopViewport(tester);

      DoctorTranscriptReviewResult? reviewResult;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  reviewResult = await showDialog<DoctorTranscriptReviewResult>(
                    context: ctx,
                    builder: (dialogCtx) => const DoctorVoiceTranscriptReviewDialog(
                      fieldId: 'chiefComplaint',
                      fieldLabel: 'Chief Complaint',
                      originalTranscript: 'patient has had ake headache from three days',
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transcript_use_original_button')));
      await tester.pumpAndSettle();

      expect(reviewResult, isNotNull);
      expect(reviewResult!.acceptedText, equals('patient has had ake headache from three days'));
      expect(reviewResult!.choiceType, equals(TranscriptChoiceType.original));
    });

    testWidgets('12. Manual EDIT workflow allows modifying text before acceptance', (tester) async {
      setDesktopViewport(tester);

      DoctorTranscriptReviewResult? reviewResult;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  reviewResult = await showDialog<DoctorTranscriptReviewResult>(
                    context: ctx,
                    builder: (dialogCtx) => const DoctorVoiceTranscriptReviewDialog(
                      fieldId: 'chiefComplaint',
                      fieldLabel: 'Chief Complaint',
                      originalTranscript: 'patient has headache',
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Tap EDIT
      await tester.tap(find.byKey(const Key('transcript_edit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transcript_edit_textfield')), findsOneWidget);

      // Enter custom doctor text
      await tester.enterText(
        find.byKey(const Key('transcript_edit_textfield')),
        'Patient reports persistent frontal headache for 4 days.',
      );
      await tester.pump();

      // Tap Use Cleaned / Accepted
      await tester.tap(find.byKey(const Key('transcript_use_cleaned_button')));
      await tester.pumpAndSettle();

      expect(reviewResult, isNotNull);
      expect(
        reviewResult!.acceptedText,
        equals('Patient reports persistent frontal headache for 4 days.'),
      );
      expect(reviewResult!.choiceType, equals(TranscriptChoiceType.edited));
    });

    testWidgets('13. CANCEL dismisses modal and returns null', (tester) async {
      setDesktopViewport(tester);

      DoctorTranscriptReviewResult? reviewResult;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  reviewResult = await showDialog<DoctorTranscriptReviewResult>(
                    context: ctx,
                    builder: (dialogCtx) => const DoctorVoiceTranscriptReviewDialog(
                      fieldId: 'chiefComplaint',
                      fieldLabel: 'Chief Complaint',
                      originalTranscript: 'patient has headache',
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transcript_review_cancel_button')));
      await tester.pumpAndSettle();

      expect(reviewResult, isNull);
    });

    testWidgets('14-15. CLEAN AGAIN shows confirmation dialog and uses ORIGINAL STT source', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (dialogCtx) => const DoctorVoiceTranscriptReviewDialog(
                    fieldId: 'chiefComplaint',
                    fieldLabel: 'Chief Complaint',
                    originalTranscript: 'patient has had ake headache from three days',
                  ),
                ),
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Tap Clean Again
      await tester.tap(find.byKey(const Key('transcript_clean_again_button')));
      await tester.pumpAndSettle();

      // Confirmation dialog is displayed
      expect(find.text('Regenerate Cleaned Draft?'), findsOneWidget);
      expect(find.byKey(const Key('clean_again_confirm_button')), findsOneWidget);
      expect(find.byKey(const Key('clean_again_cancel_button')), findsOneWidget);

      // Confirm clean again
      await tester.tap(find.byKey(const Key('clean_again_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('Patient has had a headache for three days.'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 6: Multilingual Localization (Tests 32 - 34)
  // =========================================================================
  group('Phase D9.2: Localization Across English, Hindi, and Marathi', () {
    test('32. English localization strings', () {
      final s = DoctorLocalizations.forLocale(KioskLocale.english);
      expect(s.voiceTranscriptReviewTitle, equals('VOICE TRANSCRIPT REVIEW'));
      expect(s.useCleanedVersion, equals('USE CLEANED VERSION'));
      expect(s.useOriginal, equals('USE ORIGINAL'));
      expect(s.editManually, equals('EDIT'));
      expect(s.cleanAgain, equals('CLEAN AGAIN'));
    });

    test('33. Hindi localization strings', () {
      final s = DoctorLocalizations.forLocale(KioskLocale.hindi);
      expect(s.voiceTranscriptReviewTitle, equals('वॉयस ट्रांसक्रिप्ट समीक्षा'));
      expect(s.useCleanedVersion, equals('संशोधित संस्करण उपयोग करें'));
      expect(s.useOriginal, equals('मूल ट्रांसक्रिप्ट उपयोग करें'));
      expect(s.editManually, equals('संपादित करें'));
      expect(s.cleanAgain, equals('पुनः संशोधित करें'));
    });

    test('34. Marathi localization strings', () {
      final s = DoctorLocalizations.forLocale(KioskLocale.marathi);
      expect(s.voiceTranscriptReviewTitle, equals('व्हॉइस ट्रान्सक्रिप्ट पुनरावलोकन'));
      expect(s.useCleanedVersion, equals('सुधारित आवृत्ती वापरा'));
      expect(s.useOriginal, equals('मूळ आवृत्ती वापरा'));
      expect(s.editManually, equals('संपादित करा'));
      expect(s.cleanAgain, equals('पुन्हा सुधारित करा'));
    });
  });

  // =========================================================================
  // GROUP 7: Full Workspace Regression & Integration (Tests 35 - 39)
  // =========================================================================
  group('Phase D9.2: Workspace Dictation & Regressions', () {
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

      await tester.pumpAndSettle();
    }

    testWidgets('35. D9.1 Prescription dictation remains isolated and unaffected by Gemini cleanup', (tester) async {
      await pumpWorkspace(tester);

      // Trigger prescription dictation
      final dictFinder = find.byKey(const Key('speech_mic_button_prescription'));
      await tester.ensureVisible(dictFinder);
      await tester.pumpAndSettle();
      await tester.tap(dictFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockStt.isListening, isTrue);

      // Stop speech
      final stopFinder = find.byKey(const Key('speech_stop_button'));
      await tester.tap(stopFinder);
      await tester.pumpAndSettle();

      // D9.1 transcript review box appears directly without Gemini cleanup dialog
      expect(find.byKey(const Key('prescription_transcript_box')), findsOneWidget);
      expect(find.byKey(const Key('use_in_prescription_button')), findsOneWidget);
    });

    testWidgets('36-37. Dictating into consultation field presents cleanup review and populates field with cleaned draft', (tester) async {
      await pumpWorkspace(tester);

      // Dictate into chief complaint
      final micFinder = find.byKey(const Key('speech_mic_button_chiefComplaint'));
      await tester.ensureVisible(micFinder);
      await tester.pumpAndSettle();
      await tester.tap(micFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockStt.isListening, isTrue);

      // Stop dictation
      final stopFinder = find.byKey(const Key('speech_stop_button'));
      await tester.tap(stopFinder);
      await tester.pumpAndSettle();

      // Review dialog appears
      expect(find.byKey(const Key('transcript_use_cleaned_button')), findsOneWidget);
      expect(find.byKey(const Key('transcript_use_original_button')), findsOneWidget);

      // Doctor accepts cleaned version
      await tester.tap(find.byKey(const Key('transcript_use_cleaned_button')));
      await tester.pumpAndSettle();

      // Target field is now populated
      expect(
        find.text(
          MockSpeechToTextService.defaultFieldTranscripts['chiefComplaint']!,
        ),
        findsOneWidget,
      );

      // Verify audit trail logged AI_TRANSCRIPT_CLEANUP_REQUESTED and AI_TRANSCRIPT_CLEANUP_ACCEPTED
      final auditActions = mockAuditRepo.logs.map((l) => l.action).toList();
      expect(auditActions, contains('AI_TRANSCRIPT_CLEANUP_REQUESTED'));
      expect(auditActions, contains('AI_TRANSCRIPT_CLEANUP_ACCEPTED'));
    });

    testWidgets('38. D10 Gemini Documentation Assistant generates summary independently', (tester) async {
      await pumpWorkspace(tester);

      // Documentation card is present and indicates validation state
      expect(find.byKey(const Key('gemini_documentation_card')), findsOneWidget);
      expect(find.byKey(const Key('gemini_incomplete_notice')), findsOneWidget);
    });

    test('39. D10 summary generation model remains functional', () async {
      final docService = MockGeminiDocumentationService.instance;
      const input = DocumentationInput(
        chiefComplaint: 'Chest Pain',
        onsetDuration: '3 days',
        associatedSymptoms: 'Shortness of breath',
        medicalHistory: 'Hypertension',
        currentMedication: 'Amlodipine 5mg',
        clinicalObservations: 'BP 140/90 mmHg, clear lungs',
        assessment: 'Angina Pectoris',
        plan: 'ECG and Cardiology consult',
      );

      final result = await docService.generateDocumentationSummary(input);
      expect(result.isSuccess, isTrue);
      expect(result.summary.contains('Patient presented with Chest Pain'), isTrue);
    });
  });
}
