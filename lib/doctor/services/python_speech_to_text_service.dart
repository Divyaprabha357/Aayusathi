import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/localization/kiosk_locale.dart';
import 'speech_to_text_service.dart';

/// Production implementation of [SpeechToTextService] communicating with the
/// local Python + Whisper Speech-to-Text service running on 127.0.0.1:8765.
///
/// Features:
/// - Connects strictly to localhost (127.0.0.1).
/// - Captures audio strictly upon explicit doctor trigger.
/// - Zero raw audio storage on disk, Firebase, or Supabase.
/// - Isolates dictation to the active consultation field.
/// - Gracefully falls back to clear doctor alerts and manual typing if service is offline.
/// - Provides mock transport override for deterministic unit and widget testing.
class PythonSpeechToTextService implements SpeechToTextService {
  static final PythonSpeechToTextService instance = PythonSpeechToTextService._();
  PythonSpeechToTextService._();
  factory PythonSpeechToTextService() => instance;

  String host = '127.0.0.1';
  int port = 8765;
  Duration requestTimeout = const Duration(seconds: 10);
  Duration transcriptionTimeout = const Duration(seconds: 120);

  SpeechRecognitionState _state = SpeechRecognitionState.idle;
  String? _currentListeningField;
  String? _lastError;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  // Custom HTTP transport hook for unit testing without live network daemon
  Future<Map<String, dynamic>> Function(String method, String path, Map<String, dynamic>? body)?
      customTransport;

  @visibleForTesting
  void resetForTesting() {
    _durationTimer?.cancel();
    _durationTimer = null;
    customTransport = null;
    _state = SpeechRecognitionState.idle;
    _currentListeningField = null;
    _lastError = null;
    _recordingDuration = Duration.zero;
    requestTimeout = const Duration(seconds: 10);
    transcriptionTimeout = const Duration(seconds: 120);
  }

  final StreamController<SpeechRecognitionState> _stateController =
      StreamController<SpeechRecognitionState>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<String> _partialResultController =
      StreamController<String>.broadcast();

  @override
  SpeechRecognitionState get state => _state;

  @override
  bool get isListening => _state == SpeechRecognitionState.listening;

  @override
  bool get isProcessing => _state == SpeechRecognitionState.processing;

  @override
  String? get currentListeningField => _currentListeningField;

  @override
  String? get lastError => _lastError;

  @override
  Duration get recordingDuration => _recordingDuration;

  @override
  Stream<SpeechRecognitionState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<String> get partialResultStream => _partialResultController.stream;

  void _setState(SpeechRecognitionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Maps [KioskLocale] to Whisper language code.
  static String mapLocaleToWhisper(KioskLocale locale) {
    switch (locale) {
      case KioskLocale.english:
        return 'en';
      case KioskLocale.hindi:
        return 'hi';
      case KioskLocale.marathi:
        return 'mr';
    }
  }

  /// Sends an HTTP request to the local Python STT service using native [dart:io] [HttpClient].
  Future<Map<String, dynamic>> _sendRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    if (customTransport != null) {
      return customTransport!(method, path, body);
    }

    final effectiveTimeout = timeout ?? requestTimeout;
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 2500);

    try {
      final uri = Uri.http('$host:$port', path);
      HttpClientRequest request;

      if (method == 'GET') {
        request = await client.getUrl(uri).timeout(requestTimeout);
      } else if (method == 'POST') {
        request = await client.postUrl(uri).timeout(requestTimeout);
        request.headers.contentType = ContentType.json;
        if (body != null) {
          final jsonBody = utf8.encode(jsonEncode(body));
          request.add(jsonBody);
        }
      } else {
        throw UnsupportedError('Unsupported HTTP method: $method');
      }

      final response = await request.close().timeout(effectiveTimeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(effectiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.trim().isEmpty) return {};
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        String detail = 'HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(responseBody) as Map<String, dynamic>;
          if (errJson['detail'] != null) {
            detail = errJson['detail'].toString();
          }
        } catch (_) {}
        throw HttpException(detail, uri: uri);
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<bool> initialize({KioskLocale locale = KioskLocale.english}) async {
    debugPrint('[PythonSpeechToText] Probing local STT service at http://$host:$port/health...');
    _lastError = null;

    try {
      final res = await _sendRequest('GET', '/health');
      final isOk = res['status'] == 'ok';
      if (isOk) {
        debugPrint('[PythonSpeechToText] Connected to Python Whisper STT (model: ${res['model']})');
        _setState(SpeechRecognitionState.idle);
        return true;
      } else {
        _lastError = 'Python speech service returned unexpected status: ${res['status']}';
        _setState(SpeechRecognitionState.error);
        return false;
      }
    } catch (e) {
      debugPrint('[PythonSpeechToText] Offline or unreachable: $e');
      _lastError = 'Python Speech Service is offline at 127.0.0.1:$port. Please start python_stt/server.py or enter notes manually.';
      _setState(SpeechRecognitionState.idle);
      return false;
    }
  }

  @override
  Future<MicrophonePermissionStatus> checkPermission() async {
    try {
      final res = await _sendRequest('GET', '/health');
      if (res['microphone_available'] == true) {
        return MicrophonePermissionStatus.granted;
      } else if (res['microphone_available'] == false) {
        return MicrophonePermissionStatus.unavailable;
      }
      return MicrophonePermissionStatus.granted;
    } catch (_) {
      // If service is offline, mic permission status is unavailable
      return MicrophonePermissionStatus.unavailable;
    }
  }

  @override
  Future<MicrophonePermissionStatus> requestPermission() async {
    return checkPermission();
  }

  @override
  Future<void> startListening({
    required String fieldId,
    KioskLocale locale = KioskLocale.english,
    void Function(String partialText)? onPartialResult,
  }) async {
    if (_state == SpeechRecognitionState.listening ||
        _state == SpeechRecognitionState.processing ||
        _state == SpeechRecognitionState.initializing) {
      debugPrint('[PythonSpeechToText] Already active ($_state). Ignoring duplicate trigger on $fieldId');
      return;
    }

    _lastError = null;
    _currentListeningField = fieldId;
    _recordingDuration = Duration.zero;

    final langCode = mapLocaleToWhisper(locale);
    debugPrint('[PythonSpeechToText] Starting recording for field: $fieldId (lang: $langCode)');

    try {
      _setState(SpeechRecognitionState.initializing);

      final res = await _sendRequest('POST', '/start', body: {
        'field_id': fieldId,
        'language': langCode,
      });

      if (res['status'] == 'recording' || res['status'] == 'already_recording') {
        _setState(SpeechRecognitionState.listening);

        // Start elapsed duration ticker
        _durationTimer?.cancel();
        _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          _recordingDuration += const Duration(milliseconds: 100);
          if (!_durationController.isClosed) {
            _durationController.add(_recordingDuration);
          }
        });
      } else {
        throw StateError(res['message'] ?? 'Failed to start recording');
      }
    } catch (e) {
      _durationTimer?.cancel();
      _currentListeningField = null;
      _lastError = 'Speech service offline. Please start python_stt/server.py or type manually.';
      _setState(SpeechRecognitionState.error);
      debugPrint('[PythonSpeechToText] startListening failed: $e');
      throw Exception(_lastError);
    }
  }

  @override
  Future<String?> stopListening() async {
    if (_state == SpeechRecognitionState.processing) {
      debugPrint('[PythonSpeechToText] stopListening called while already processing. Ignoring duplicate call.');
      return null;
    }

    if (_state != SpeechRecognitionState.listening && _state != SpeechRecognitionState.initializing) {
      debugPrint('[PythonSpeechToText] stopListening called while not listening (state: $_state)');
      return null;
    }

    final targetField = _currentListeningField;
    _durationTimer?.cancel();
    _setState(SpeechRecognitionState.processing);

    debugPrint(
        '[PythonSpeechToText] Stopping recording and finalizing transcript for $targetField (timeout: ${transcriptionTimeout.inSeconds}s)...');

    try {
      final res = await _sendRequest(
        'POST',
        '/stop',
        body: {'field_id': targetField},
        timeout: transcriptionTimeout,
      );

      final rawTranscript = res['transcript'] as String?;
      final clean = rawTranscript?.trim() ?? '';

      _setState(SpeechRecognitionState.ready);
      _currentListeningField = null;
      _setState(SpeechRecognitionState.idle);

      if (clean.isEmpty) {
        debugPrint('[PythonSpeechToText] No speech detected for $targetField');
        return null;
      }

      debugPrint('[PythonSpeechToText] Transcription received for $targetField: "$clean"');
      return clean;
    } on TimeoutException catch (e) {
      _currentListeningField = null;
      _lastError =
          'Transcription timed out (exceeded ${transcriptionTimeout.inSeconds}s). Please speak briefly or enter text manually.';
      _setState(SpeechRecognitionState.error);
      debugPrint('[PythonSpeechToText] stopListening timed out after ${transcriptionTimeout.inSeconds}s: $e');
      return null;
    } catch (e) {
      _currentListeningField = null;
      _lastError = 'Transcription error: $e';
      _setState(SpeechRecognitionState.error);
      debugPrint('[PythonSpeechToText] stopListening failed: $e');
      return null;
    }
  }

  @override
  Future<void> cancelListening() async {
    _durationTimer?.cancel();
    _recordingDuration = Duration.zero;
    _currentListeningField = null;

    try {
      await _sendRequest('POST', '/cancel');
    } catch (e) {
      debugPrint('[PythonSpeechToText] cancelListening error: $e');
    } finally {
      _setState(SpeechRecognitionState.idle);
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    if (!_stateController.isClosed) _stateController.close();
    if (!_durationController.isClosed) _durationController.close();
    if (!_partialResultController.isClosed) _partialResultController.close();
  }
}
