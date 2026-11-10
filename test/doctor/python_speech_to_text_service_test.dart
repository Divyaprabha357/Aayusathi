import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/services/python_speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/speech_to_text_service.dart';
import 'package:aayusathi/doctor/services/windows_speech_to_text_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_speech_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PythonSpeechToTextService service;

  setUp(() {
    service = PythonSpeechToTextService.instance;
    service.resetForTesting();
    SpeechToTextService.instance = null; // Reset to default
  });

  tearDown(() {
    service.resetForTesting();
  });

  group('PythonSpeechToTextService - Architecture & Singletons', () {
    test('1. SpeechToTextService.instance defaults to PythonSpeechToTextService', () {
      expect(SpeechToTextService.instance, isA<PythonSpeechToTextService>());
      expect(identical(SpeechToTextService.instance, PythonSpeechToTextService.instance), isTrue);
    });

    test('2. SpeechToTextService.legacyWindowsInstance provides Windows fallback', () {
      expect(SpeechToTextService.legacyWindowsInstance, isA<WindowsSpeechToTextService>());
      expect(identical(SpeechToTextService.legacyWindowsInstance, WindowsSpeechToTextService.instance), isTrue);
    });

    test('3. Default localhost binding is 127.0.0.1:8765 with 120s transcription timeout', () {
      expect(service.host, equals('127.0.0.1'));
      expect(service.port, equals(8765));
      expect(service.requestTimeout, equals(const Duration(seconds: 10)));
      expect(service.transcriptionTimeout, equals(const Duration(seconds: 120)));
    });
  });

  group('PythonSpeechToTextService - Language Mapping', () {
    test('4. Correctly maps KioskLocale to Whisper language codes', () {
      expect(PythonSpeechToTextService.mapLocaleToWhisper(KioskLocale.english), equals('en'));
      expect(PythonSpeechToTextService.mapLocaleToWhisper(KioskLocale.hindi), equals('hi'));
      expect(PythonSpeechToTextService.mapLocaleToWhisper(KioskLocale.marathi), equals('mr'));
    });
  });

  group('PythonSpeechToTextService - Health Check & Permissions', () {
    test('5. Successful initialize when local Python server is healthy', () async {
      service.customTransport = (method, path, body) async {
        if (method == 'GET' && path == '/health') {
          return {
            'status': 'ok',
            'model': 'base',
            'microphone_available': true,
          };
        }
        throw Exception('Unexpected route: $method $path');
      };

      final initialized = await service.initialize();
      expect(initialized, isTrue);
      expect(service.state, equals(SpeechRecognitionState.idle));
      expect(service.lastError, isNull);

      final perm = await service.checkPermission();
      expect(perm, equals(MicrophonePermissionStatus.granted));
    });

    test('6. Offline Python server returns false and sets informative doctor error', () async {
      service.customTransport = (method, path, body) async {
        throw Exception('Connection refused to 127.0.0.1:8765');
      };

      final initialized = await service.initialize();
      expect(initialized, isFalse);
      expect(service.lastError, contains('Python Speech Service is offline'));
      expect(service.lastError, contains('127.0.0.1:8765'));

      final perm = await service.checkPermission();
      expect(perm, equals(MicrophonePermissionStatus.unavailable));
    });
  });

  group('PythonSpeechToTextService - Explicit Recording Lifecycle', () {
    test('7. Explicit start -> ticking duration -> explicit stop returns transcript', () async {
      final List<String> requests = [];
      Map<String, dynamic>? capturedStartBody;
      Map<String, dynamic>? capturedStopBody;

      service.customTransport = (method, path, body) async {
        requests.add('$method $path');
        if (method == 'POST' && path == '/start') {
          capturedStartBody = body;
          return {
            'status': 'recording',
            'field_id': body?['field_id'],
            'language': body?['language'],
          };
        }
        if (method == 'POST' && path == '/stop') {
          capturedStopBody = body;
          return {
            'status': 'completed',
            'field_id': body?['field_id'],
            'transcript': 'Patient reports moderate headache for 2 days.',
            'duration_seconds': 3.2,
          };
        }
        throw Exception('Unexpected: $method $path');
      };

      final states = <SpeechRecognitionState>[];
      final sub = service.stateStream.listen(states.add);

      expect(service.isListening, isFalse);

      // Explicit Doctor trigger: Start
      await service.startListening(
        fieldId: 'chiefComplaint',
        locale: KioskLocale.english,
      );

      expect(service.isListening, isTrue);
      expect(service.currentListeningField, equals('chiefComplaint'));
      expect(capturedStartBody?['field_id'], equals('chiefComplaint'));
      expect(capturedStartBody?['language'], equals('en'));

      // Wait a short duration for ticker
      await Future.delayed(const Duration(milliseconds: 250));
      expect(service.recordingDuration.inMilliseconds, greaterThan(0));

      // Explicit Doctor trigger: Stop
      final transcript = await service.stopListening();
      await Future.delayed(Duration.zero);

      expect(transcript, equals('Patient reports moderate headache for 2 days.'));
      expect(capturedStopBody?['field_id'], equals('chiefComplaint'));
      expect(service.isListening, isFalse);
      expect(service.currentListeningField, isNull);

      expect(states, contains(SpeechRecognitionState.listening));
      expect(states, contains(SpeechRecognitionState.processing));
      expect(states, contains(SpeechRecognitionState.ready));
      expect(states, contains(SpeechRecognitionState.idle));

      await sub.cancel();
    });

    test('8. Duplicate startListening calls while already listening are safely ignored', () async {
      int startCallCount = 0;
      service.customTransport = (method, path, body) async {
        if (method == 'POST' && path == '/start') {
          startCallCount++;
          return {'status': 'recording', 'field_id': 'chiefComplaint'};
        }
        return {};
      };

      await service.startListening(fieldId: 'chiefComplaint');
      expect(startCallCount, equals(1));

      // Attempt second call without stopping
      await service.startListening(fieldId: 'chiefComplaint');
      expect(startCallCount, equals(1), reason: 'Duplicate start call must be ignored while active');
    });

    test('9. Cancel listening dispatches /cancel and resets service state to idle', () async {
      bool cancelDispatched = false;
      service.customTransport = (method, path, body) async {
        if (method == 'POST' && path == '/start') {
          return {'status': 'recording', 'field_id': 'diagnosis'};
        }
        if (method == 'POST' && path == '/cancel') {
          cancelDispatched = true;
          return {'status': 'cancelled'};
        }
        return {};
      };

      await service.startListening(fieldId: 'diagnosis');
      expect(service.isListening, isTrue);

      await service.cancelListening();

      expect(cancelDispatched, isTrue);
      expect(service.isListening, isFalse);
      expect(service.state, equals(SpeechRecognitionState.idle));
      expect(service.currentListeningField, isNull);
      expect(service.recordingDuration, equals(Duration.zero));
    });

    test('10. Empty or silent transcript returns null without corrupting target field', () async {
      service.customTransport = (method, path, body) async {
        if (method == 'POST' && path == '/start') {
          return {'status': 'recording', 'field_id': 'plan'};
        }
        if (method == 'POST' && path == '/stop') {
          return {'status': 'completed', 'transcript': '   ', 'duration_seconds': 1.0};
        }
        return {};
      };

      await service.startListening(fieldId: 'plan');
      final transcript = await service.stopListening();

      expect(transcript, isNull, reason: 'Empty transcription must return null');
    });
  });

  group('PythonSpeechToTextService - Field Isolation & Safety', () {
    test('11. Transcription captures speech into target field strictly', () async {
      String? sentField;
      service.customTransport = (method, path, body) async {
        if (path == '/start') {
          sentField = body?['field_id'];
          return {'status': 'recording'};
        }
        if (path == '/stop') {
          return {'status': 'completed', 'transcript': 'Regular diet, avoid excess salt.'};
        }
        return {};
      };

      await service.startListening(fieldId: 'patientInstructions');
      expect(sentField, equals('patientInstructions'));

      final text = await service.stopListening();
      expect(text, equals('Regular diet, avoid excess salt.'));
    });

    test('12. STT functions strictly as documentation assistant without clinical auto-diagnosis', () async {
      // The transcript returned is strictly what was dictated by the doctor
      const spokenWords = 'Patient has throat irritation and fever for 24 hours';
      service.customTransport = (method, path, body) async {
        if (path == '/start') return {'status': 'recording'};
        if (path == '/stop') return {'status': 'completed', 'transcript': spokenWords};
        return {};
      };

      await service.startListening(fieldId: 'symptoms');
      final result = await service.stopListening();

      expect(result, equals(spokenWords));
      expect(result, isNot(contains('Auto-diagnosed: Pharyngitis')));
      expect(result, isNot(contains('Prescription generated: Azithromycin')));
    });
  });

  group('DoctorSpeechAppendReplaceDialog - Doctor Review and Control', () {
    testWidgets('13. Append dialog presents doctor with explicit Replace, Append, and Cancel options', (tester) async {
      const existingText = 'Initial complaint: headache.';
      const newDictatedText = 'Also reports mild nausea in the morning.';

      String? chosenAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  chosenAction = await showDialog<String>(
                    context: context,
                    builder: (_) => const DoctorSpeechAppendReplaceDialog(
                      fieldLabel: 'Chief Complaint',
                      existingText: existingText,
                      newTranscript: newDictatedText,
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check dialog elements
      expect(find.textContaining('CURRENT TEXT IN Chief Complaint:'), findsOneWidget);
      expect(find.text(existingText), findsOneWidget);
      expect(find.text('NEW SPEECH TRANSCRIPT:'), findsOneWidget);
      expect(find.text(newDictatedText), findsOneWidget);

      expect(find.byKey(const Key('speech_append_button')), findsOneWidget);
      expect(find.byKey(const Key('speech_replace_button')), findsOneWidget);
      expect(find.byKey(const Key('speech_append_replace_cancel')), findsOneWidget);

      // Tap Append
      await tester.tap(find.byKey(const Key('speech_append_button')));
      await tester.pumpAndSettle();

      expect(chosenAction, equals('append'));
    });
  });

  group('PythonSpeechToTextService - Timeout and Concurrency Guards', () {
    test('14. Duplicate startListening and stopListening calls while processing are blocked', () async {
      final completer = Completer<Map<String, dynamic>>();
      service.customTransport = (method, path, body) async {
        if (method == 'POST' && path == '/start') {
          return {'status': 'recording', 'field_id': 'chiefComplaint'};
        }
        if (method == 'POST' && path == '/stop') {
          return completer.future;
        }
        return {};
      };

      await service.startListening(fieldId: 'chiefComplaint');
      expect(service.isListening, isTrue);

      // Trigger stop, which sets state to processing while waiting for completion
      final stopFuture = service.stopListening();
      expect(service.isProcessing, isTrue);

      // Attempt duplicate startListening while processing
      await service.startListening(fieldId: 'chiefComplaint');
      expect(service.isProcessing, isTrue, reason: 'Must remain in processing state');

      // Attempt duplicate stopListening while processing
      final duplicateStopResult = await service.stopListening();
      expect(duplicateStopResult, isNull);

      // Complete transcription
      completer.complete({
        'status': 'completed',
        'transcript': 'Completed transcript',
      });
      final result = await stopFuture;
      expect(result, equals('Completed transcript'));
      expect(service.state, equals(SpeechRecognitionState.idle));
    });

    test('15. TimeoutException in stopListening transitions to error state with clear message', () async {
      service.customTransport = (method, path, body) async {
        if (method == 'POST' && path == '/start') {
          return {'status': 'recording', 'field_id': 'plan'};
        }
        if (method == 'POST' && path == '/stop') {
          throw TimeoutException('Future not completed', service.transcriptionTimeout);
        }
        return {};
      };

      await service.startListening(fieldId: 'plan');
      expect(service.isListening, isTrue);

      final result = await service.stopListening();
      expect(result, isNull);
      expect(service.state, equals(SpeechRecognitionState.error));
      expect(service.lastError, contains('Transcription timed out'));
      expect(service.lastError, contains('120'));
      expect(service.currentListeningField, isNull);
    });

    testWidgets('16. DoctorSpeechFieldButton shows processing indicator and disables tap during processing', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorSpeechFieldButton(
              fieldId: 'chiefComplaint',
              fieldLabel: 'Chief Complaint',
              activeListeningField: 'chiefComplaint',
              isListening: false,
              isProcessing: true,
              onTrigger: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('PROCESSING'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tapping while processing should not trigger callback
      await tester.tap(find.byKey(const Key('speech_mic_button_chiefComplaint')));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });
}
