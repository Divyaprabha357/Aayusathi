import 'dart:async';
import '../../core/localization/kiosk_locale.dart';
import 'mock_speech_to_text_service.dart';
import 'speech_to_text_service.dart';

/// Web/Non-IO stub of [WindowsSpeechToTextService].
class WindowsSpeechToTextService implements SpeechToTextService {
  static final WindowsSpeechToTextService instance = WindowsSpeechToTextService._();
  WindowsSpeechToTextService._();
  factory WindowsSpeechToTextService() => instance;

  final MockSpeechToTextService _mock = MockSpeechToTextService.instance;

  @override
  SpeechRecognitionState get state => _mock.state;

  @override
  bool get isListening => _mock.isListening;

  @override
  bool get isProcessing => _mock.isProcessing;

  @override
  String? get currentListeningField => _mock.currentListeningField;

  @override
  String? get lastError => _mock.lastError;

  @override
  Duration get recordingDuration => _mock.recordingDuration;

  @override
  Stream<SpeechRecognitionState> get stateStream => _mock.stateStream;

  @override
  Stream<Duration> get durationStream => _mock.durationStream;

  @override
  Stream<String> get partialResultStream => _mock.partialResultStream;

  @override
  Future<bool> initialize({KioskLocale locale = KioskLocale.english}) =>
      _mock.initialize(locale: locale);

  @override
  Future<MicrophonePermissionStatus> checkPermission() => _mock.checkPermission();

  @override
  Future<MicrophonePermissionStatus> requestPermission() => _mock.requestPermission();

  @override
  Future<void> startListening({
    required String fieldId,
    KioskLocale locale = KioskLocale.english,
    void Function(String partialText)? onPartialResult,
  }) => _mock.startListening(
        fieldId: fieldId,
        locale: locale,
        onPartialResult: onPartialResult,
      );

  @override
  Future<String?> stopListening() => _mock.stopListening();

  @override
  Future<void> cancelListening() => _mock.cancelListening();

  @override
  void dispose() => _mock.dispose();
}
