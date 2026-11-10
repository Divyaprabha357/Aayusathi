import 'dart:async';
import '../../core/localization/kiosk_locale.dart';
import 'speech_to_text_service.dart';

/// In-memory mock implementation of [SpeechToTextService] for development and testing.
///
/// Features:
/// - Provides realistic, deterministic clinical medical transcripts.
/// - Simulates live partial transcription token streams.
/// - Simulates timer ticking for recording duration.
/// - Simulates microphone permission workflows and edge-case errors.
/// - Never writes fake speech data to production Cloud Firestore or Firebase Storage.
class MockSpeechToTextService implements SpeechToTextService {
  static final MockSpeechToTextService instance = MockSpeechToTextService();

  SpeechRecognitionState _state = SpeechRecognitionState.idle;
  String? _currentListeningField;
  KioskLocale? _currentListeningLocale;
  String? _lastError;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _partialTokenTimer;

  final StreamController<SpeechRecognitionState> _stateController =
      StreamController<SpeechRecognitionState>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<String> _partialResultController =
      StreamController<String>.broadcast();

  // Error simulation flags
  bool simulatePermissionDenied = false;
  bool simulateEngineUnavailable = false;
  bool simulateTimeout = false;
  bool simulateError = false;
  bool simulateEmptyTranscript = false;
  String simulatedErrorMessage = 'Mock speech recognition failure.';

  // Custom transcript overrides
  final Map<String, String> _customFieldTranscripts = {};
  String? _customDefaultTranscript;

  /// Default clinical transcripts mapped per consultation field.
  static final Map<String, String> defaultFieldTranscripts = {
    'chiefComplaint':
        'Patient reports moderate chest discomfort and shortness of breath for 3 days.',
    'onsetDuration':
        'Symptoms started gradually 3 days ago, worsening with moderate physical exertion.',
    'associatedSymptoms':
        'Mild palpitations and occasional lightheadedness. No syncope or radiating arm pain.',
    'medicalHistory':
        'Known hypertension for 4 years on regular antihypertensive therapy. Non-diabetic.',
    'currentMedication':
        'Telmisartan 40mg once daily morning after breakfast.',
    'clinicalObservations':
        'BP 138/88 mmHg, heart rate 78 bpm regular rhythm, chest clear bilaterally, S1 S2 heard.',
    'assessment':
        'Stage 1 Essential Hypertension with exertional dyspnea, hemodynamically stable.',
    'plan':
        'Advise 12-lead ECG and 2D Echocardiogram. Continue current medication with sodium restriction.',
    'followUp':
        'Review in OPD after 1 week with ECG and basic blood work.',
    'patientInstructions':
        'Maintain low salt diet, monitor blood pressure daily, avoid heavy physical exertion.',
    'relevantHistory':
        'Previous episode of mild chest discomfort evaluated 6 months ago, normotensive at that time.',
    'summaryText':
        'Patient presented with 3-day history of exertional chest discomfort and dyspnea. Vital signs stable, diagnostic tests ordered.',
    'prescription':
        'Paracetamol 500 mg for 5 days, 2 times a day, after food. Pantoprazole 40 mg for 5 days, 1 time a day, before breakfast.',
  };

  /// Localized mock transcripts for Hindi.
  static final Map<String, String> hindiFieldTranscripts = {
    'chiefComplaint': 'मरीज़ को 3 दिनों से सीने में हल्का दर्द और सांस फूलने की शिकायत है।',
    'onsetDuration': 'लक्षण 3 दिन पहले धीरे-धीरे शुरू हुए, चलने पर बढ़ते हैं।',
    'associatedSymptoms': 'हल्की घबराहट और कभी-कभी चक्कर आना।',
    'medicalHistory': 'पिछले 4 वर्षों से उच्च रक्तचाप का इतिहास है।',
    'currentMedication': 'टेल्मिसार्टन 40 मिलीग्राम दिन में एक बार सुबह नाश्ते के बाद।',
    'clinicalObservations': 'रक्तचाप 138/88 mmHg, हृदय गति 78 प्रति मिनट।',
    'assessment': 'चरण 1 आवश्यक उच्च रक्तचाप, स्थिर स्थिति।',
    'plan': 'ईसीजी और ईको की सलाह दी गई। नमक कम करने का निर्देश।',
    'followUp': '1 सप्ताह बाद ईसीजी रिपोर्ट के साथ पुनः दिखाएं।',
    'patientInstructions': 'कम नमक का आहार लें, प्रतिदिन रक्तचाप मापें।',
    'prescription':
        'पैरासिटामोल 500 मिलीग्राम 5 दिनों के लिए, दिन में 2 बार, भोजन के बाद। पैंटोप्राजोल 40 मिलीग्राम 5 दिनों के लिए, दिन में 1 बार, नाश्ते से पहले।',
  };

  /// Localized mock transcripts for Marathi.
  static final Map<String, String> marathiFieldTranscripts = {
    'chiefComplaint': 'रुग्णाला ३ दिवसांपासून छातीत दुखणे आणि धाप लागण्याचा त्रास होत आहे.',
    'onsetDuration': 'लक्षणे ३ दिवसांपूर्वी सुरू झाली, चालताना वाढतात.',
    'associatedSymptoms': 'किरकोळ धडधड आणि चक्कर येणे.',
    'medicalHistory': 'मागील ४ वर्षांपासून उच्च रक्तदाबाचा त्रास आहे.',
    'currentMedication': 'टेल्मिसार्टन ४० मिग्रॅ दररोज सकाळी जेवणानंतर.',
    'clinicalObservations': 'रक्तदाब १३८/८८ mmHg, नाडीचे ठोके ७८ प्रति मिनिट.',
    'assessment': 'टप्पा १ उच्च रक्तदाब, स्थिर स्थिती.',
    'plan': 'ईसीजी आणि इको तपासणीचा सल्ला दिला. मिठाचे प्रमाण कमी करा.',
    'followUp': '१ आठवड्यानंतर ईसीजी अहवालासह पुन्हा यावे.',
    'patientInstructions': 'कमी मिठाचा आहार घ्या, दररोज रक्तदाब तपासा.',
    'prescription':
        'पॅरासिटामॉल 500 मिग्रॅ 5 दिवसांसाठी, दिवसातून 2 वेळा, जेवणानंतर. पॅन्टोप्राझोल 40 मिग्रॅ 5 दिवसांसाठी, दिवसातून 1 वेळ, नाश्त्यापूर्वी.',
  };

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

  void setMockTranscript(String fieldId, String transcript) {
    _customFieldTranscripts[fieldId] = transcript;
  }

  void setDefaultTranscript(String transcript) {
    _customDefaultTranscript = transcript;
  }

  void resetToDefaults() {
    _customFieldTranscripts.clear();
    _customDefaultTranscript = null;
    simulatePermissionDenied = false;
    simulateEngineUnavailable = false;
    simulateTimeout = false;
    simulateError = false;
    simulateEmptyTranscript = false;
    simulatedErrorMessage = 'Mock speech recognition failure.';
    _state = SpeechRecognitionState.idle;
    _currentListeningField = null;
    _currentListeningLocale = null;
    _lastError = null;
    _recordingDuration = Duration.zero;
    _stopTimers();
  }

  void _setState(SpeechRecognitionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  @override
  Future<bool> initialize({KioskLocale locale = KioskLocale.english}) async {
    if (simulateEngineUnavailable) {
      _setState(SpeechRecognitionState.unsupported);
      _lastError = 'Speech recognition engine is unavailable on this system.';
      return false;
    }
    _setState(SpeechRecognitionState.idle);
    _lastError = null;
    return true;
  }

  @override
  Future<MicrophonePermissionStatus> checkPermission() async {
    if (simulatePermissionDenied) {
      return MicrophonePermissionStatus.denied;
    }
    return MicrophonePermissionStatus.granted;
  }

  @override
  Future<MicrophonePermissionStatus> requestPermission() async {
    if (simulatePermissionDenied) {
      _setState(SpeechRecognitionState.error);
      _lastError = 'Microphone permission was denied by user.';
      return MicrophonePermissionStatus.denied;
    }
    return MicrophonePermissionStatus.granted;
  }

  @override
  Future<void> startListening({
    required String fieldId,
    KioskLocale locale = KioskLocale.english,
    void Function(String partialText)? onPartialResult,
  }) async {
    _stopTimers();
    _lastError = null;
    _recordingDuration = Duration.zero;
    _currentListeningField = fieldId;
    _currentListeningLocale = locale;

    // Check engine support
    if (simulateEngineUnavailable) {
      _setState(SpeechRecognitionState.unsupported);
      _lastError = 'Speech recognition engine is unavailable.';
      return;
    }

    // Check permission
    if (simulatePermissionDenied) {
      _setState(SpeechRecognitionState.error);
      _lastError = 'Microphone permission denied.';
      return;
    }

    if (simulateError) {
      _setState(SpeechRecognitionState.error);
      _lastError = simulatedErrorMessage;
      return;
    }

    _setState(SpeechRecognitionState.initializing);
    await Future.delayed(const Duration(milliseconds: 50));

    _setState(SpeechRecognitionState.listening);

    // Start timer ticking for duration
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      if (!_durationController.isClosed) {
        _durationController.add(_recordingDuration);
      }
    });

    // Determine target full transcript for live token simulation
    final fullText = _resolveTranscript(fieldId, locale);
    final words = fullText.split(' ');
    int tokenIndex = 0;

    _partialTokenTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_state != SpeechRecognitionState.listening) {
        timer.cancel();
        return;
      }
      if (tokenIndex < words.length) {
        tokenIndex++;
        final partial = words.take(tokenIndex).join(' ');
        if (!_partialResultController.isClosed) {
          _partialResultController.add(partial);
        }
        onPartialResult?.call(partial);
      }
    });
  }

  String _resolveTranscript(String fieldId, KioskLocale locale) {
    if (simulateEmptyTranscript) return '';
    if (_customFieldTranscripts.containsKey(fieldId)) {
      return _customFieldTranscripts[fieldId]!;
    }
    if (_customDefaultTranscript != null) {
      return _customDefaultTranscript!;
    }

    if (locale == KioskLocale.hindi && hindiFieldTranscripts.containsKey(fieldId)) {
      return hindiFieldTranscripts[fieldId]!;
    }
    if (locale == KioskLocale.marathi && marathiFieldTranscripts.containsKey(fieldId)) {
      return marathiFieldTranscripts[fieldId]!;
    }

    return defaultFieldTranscripts[fieldId] ??
        'Clinical consultation notes recorded for $fieldId.';
  }

  @override
  Future<String?> stopListening({KioskLocale? locale}) async {
    if (_state != SpeechRecognitionState.listening &&
        _state != SpeechRecognitionState.initializing) {
      return null;
    }

    _stopTimers();
    _setState(SpeechRecognitionState.processing);
    await Future.delayed(const Duration(milliseconds: 100));

    if (simulateTimeout) {
      _setState(SpeechRecognitionState.error);
      _lastError = 'Speech recognition timed out.';
      return null;
    }

    if (simulateError) {
      _setState(SpeechRecognitionState.error);
      _lastError = simulatedErrorMessage;
      return null;
    }

    final targetField = _currentListeningField ?? 'chiefComplaint';
    final targetLocale = locale ?? _currentListeningLocale ?? KioskLocale.english;
    final transcript = _resolveTranscript(targetField, targetLocale);

    _setState(SpeechRecognitionState.ready);
    return transcript.isNotEmpty ? transcript : null;
  }

  @override
  Future<void> cancelListening() async {
    _stopTimers();
    _currentListeningField = null;
    _recordingDuration = Duration.zero;
    _lastError = null;
    _setState(SpeechRecognitionState.idle);
  }

  void _stopTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _partialTokenTimer?.cancel();
    _partialTokenTimer = null;
  }

  @override
  void dispose() {
    _stopTimers();
    _stateController.close();
    _durationController.close();
    _partialResultController.close();
  }
}
