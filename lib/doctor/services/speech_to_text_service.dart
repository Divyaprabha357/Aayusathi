import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/localization/kiosk_locale.dart';
import 'mock_speech_to_text_service.dart';
import 'python_speech_to_text_service_stub.dart'
    if (dart.library.io) 'python_speech_to_text_service.dart';
import 'windows_speech_to_text_service_stub.dart'
    if (dart.library.io) 'windows_speech_to_text_service.dart';

/// Clinical lifecycle states of the Doctor Speech-to-Text assistant.
enum SpeechRecognitionState {
  /// Engine is inactive and ready to start a recording session.
  idle,

  /// Initializing microphone hardware and recognition models.
  initializing,

  /// Actively capturing doctor speech telemetry.
  listening,

  /// Processing and finalizing transcription payload.
  processing,

  /// Final transcript is ready for insertion into the target field.
  ready,

  /// An error occurred during capture or transcription.
  error,

  /// Platform or hardware does not support speech recognition.
  unsupported,
}

/// System microphone permission state.
enum MicrophonePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

/// Abstract contract for Doctor Speech-to-Text transcription.
///
/// Features:
/// - Isolated behind service abstraction (swappable engine).
/// - Field-targeted transcription (records into specified clinical fields).
/// - Real-time duration & state tracking.
/// - Never summarizes or interprets clinical meaning (transcription only).
abstract class SpeechToTextService {
  static SpeechToTextService? _customInstance;

  /// Sets custom service override for testing.
  static set instance(SpeechToTextService? service) {
    _customInstance = service;
  }

  /// Resolves the active speech-to-text service.
  ///
  /// Uses [PythonSpeechToTextService.instance] (Python + Whisper local service)
  /// as the primary high-accuracy transcription engine.
  /// Automated tests override this by assigning [SpeechToTextService.instance = MockSpeechToTextService()].
  static SpeechToTextService get instance {
    if (_customInstance != null) return _customInstance!;
    if (kIsWeb) return MockSpeechToTextService.instance;
    return PythonSpeechToTextService.instance;
  }

  /// Legacy Windows System.Speech implementation for reference or test compatibility.
  static WindowsSpeechToTextService get legacyWindowsInstance =>
      WindowsSpeechToTextService.instance;

  /// Current recognition engine state.
  SpeechRecognitionState get state;

  /// Whether the service is actively recording speech.
  bool get isListening => state == SpeechRecognitionState.listening;

  /// Whether the service is processing final audio transcription.
  bool get isProcessing => state == SpeechRecognitionState.processing;

  /// Current clinical field targeted by active speech capture (e.g. 'chiefComplaint').
  String? get currentListeningField;

  /// Human-readable error message if [state] is [SpeechRecognitionState.error].
  String? get lastError;

  /// Elapsed duration of active recording session.
  Duration get recordingDuration;

  /// Stream of state changes.
  Stream<SpeechRecognitionState> get stateStream;

  /// Stream of elapsed recording duration updates.
  Stream<Duration> get durationStream;

  /// Stream of live/partial transcription tokens.
  Stream<String> get partialResultStream;

  /// Initializes the speech engine with preferred language locale.
  Future<bool> initialize({KioskLocale locale = KioskLocale.english});

  /// Checks current microphone hardware permission status.
  Future<MicrophonePermissionStatus> checkPermission();

  /// Prompts doctor for microphone permission access.
  Future<MicrophonePermissionStatus> requestPermission();

  /// Begins capturing doctor speech for the target clinical [fieldId].
  Future<void> startListening({
    required String fieldId,
    KioskLocale locale = KioskLocale.english,
    void Function(String partialText)? onPartialResult,
  });

  /// Stops recording, finalizes transcription, and returns the converted text.
  Future<String?> stopListening();

  /// Aborts active recording session and discards buffered audio.
  Future<void> cancelListening();

  /// Releases speech hardware and controller subscriptions.
  void dispose();
}
