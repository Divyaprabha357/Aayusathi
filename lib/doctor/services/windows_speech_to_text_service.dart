import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/localization/kiosk_locale.dart';
import 'speech_to_text_service.dart';

/// Diagnostic summary of the Windows Speech Recognition subsystem configuration.
class WindowsSpeechDiagnostics {
  final String requestedLocale;
  final String? selectedLocale;
  final List<String> availableCultures;
  final bool isSupported;
  final String audioDevice;
  final String statusMessage;

  const WindowsSpeechDiagnostics({
    required this.requestedLocale,
    this.selectedLocale,
    this.availableCultures = const [],
    required this.isSupported,
    this.audioDevice = 'Default Windows Recording Device',
    required this.statusMessage,
  });

  @override
  String toString() =>
      'WindowsSpeechDiagnostics(requested: $requestedLocale, selected: $selectedLocale, '
      'available: $availableCultures, supported: $isSupported, device: $audioDevice, status: $statusMessage)';
}

/// Real Windows desktop implementation of [SpeechToTextService] using the
/// native Windows Speech Recognition subsystem (`System.Speech.Recognition`).
///
/// Architecture & Pipeline:
/// 1. Spawns a background worker process executing a compiled C# SpeechRecognitionEngine.
/// 2. Discovers installed Windows recognition cultures and matches requested locale.
/// 3. Falls back safely to the closest installed English recognition engine (e.g. en-US)
///    when exact regional English (e.g. en-IN) is not present in SAPI recognizers.
/// 4. Explicitly synchronizes thread culture for proper acoustic phoneme normalization.
/// 5. Binds directly to the default Windows recording device (laptop/USB microphone).
/// 6. Configures continuous dictation grammar with optimized silence timeouts.
/// 7. Native C# delegates emit `PARTIAL:<text>` and `FINAL:<text>` over stdout in real-time.
/// 8. Dart streams partial hypotheses to the floating recording HUD for live doctor feedback.
/// 9. When the doctor clicks "Stop & Insert", stdin signals the engine to finalize and return text.
/// 10. Zero raw audio data is stored in Firebase or transmitted to Gemini.
/// 11. 100% editable result with Append/Replace dialog support.
class WindowsSpeechToTextService implements SpeechToTextService {
  static final WindowsSpeechToTextService instance =
      WindowsSpeechToTextService._();
  WindowsSpeechToTextService._();
  factory WindowsSpeechToTextService() => instance;

  SpeechRecognitionState _state = SpeechRecognitionState.idle;
  String? _currentListeningField;
  String? _lastError;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  Process? _speechProcess;
  StreamSubscription<String>? _stdoutSubscription;
  final StringBuffer _transcriptBuffer = StringBuffer();
  String _latestPartial = '';

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

  /// Maps [KioskLocale] to Windows speech recognition culture tag.
  static String resolveLocaleTag(KioskLocale locale) {
    switch (locale) {
      case KioskLocale.english:
        return 'en-IN';
      case KioskLocale.hindi:
        return 'hi-IN';
      case KioskLocale.marathi:
        return 'mr-IN';
    }
  }

  /// Selects the best matching installed culture.
  ///
  /// Strategy:
  /// 1. Try exact match with requested locale tag (case-insensitive).
  /// 2. If requested is English (or starts with 'en' / empty), fallback to 'en-US',
  ///    'en-GB', or the first available English culture.
  /// 3. If requested is non-English and not installed, returns null to avoid
  ///    silently misrecognizing foreign speech.
  static String? selectBestCulture(
    String requestedLocale,
    List<String> installedCultures,
  ) {
    if (installedCultures.isEmpty) return null;

    final trimmedReq = requestedLocale.trim();

    // 1. Exact match
    for (final culture in installedCultures) {
      final code = culture.split(' ').first.trim();
      if (code.toLowerCase() == trimmedReq.toLowerCase()) {
        return code;
      }
    }

    // 2. English fallback
    if (trimmedReq.isEmpty || trimmedReq.toLowerCase().startsWith('en')) {
      for (final culture in installedCultures) {
        final code = culture.split(' ').first.trim();
        if (code.toLowerCase() == 'en-us') {
          return code;
        }
      }
      for (final culture in installedCultures) {
        final code = culture.split(' ').first.trim();
        if (code.toLowerCase() == 'en-gb') {
          return code;
        }
      }
      for (final culture in installedCultures) {
        final code = culture.split(' ').first.trim();
        if (code.toLowerCase().startsWith('en')) {
          return code;
        }
      }
    }

    return null;
  }

  @override
  Future<bool> initialize({KioskLocale locale = KioskLocale.english}) async {
    try {
      final tag = resolveLocaleTag(locale);
      debugPrint('[WindowsSpeechToText] Initializing Windows Speech engine for locale: ${locale.name} ($tag)');
      _setState(SpeechRecognitionState.idle);
      _lastError = null;
      if (Platform.isWindows) {
        unawaited(_getOrCompileExecutable());
      }
      return true;
    } catch (e) {
      debugPrint('[WindowsSpeechToText] Initialization exception: $e');
      _setState(SpeechRecognitionState.unsupported);
      _lastError = 'Windows speech recognition service is not available.';
      return false;
    }
  }

  @override
  Future<MicrophonePermissionStatus> checkPermission() async {
    try {
      if (!Platform.isWindows) return MicrophonePermissionStatus.granted;
      return MicrophonePermissionStatus.granted;
    } catch (e) {
      debugPrint('[WindowsSpeechToText] Permission check exception: $e');
      return MicrophonePermissionStatus.unavailable;
    }
  }

  @override
  Future<MicrophonePermissionStatus> requestPermission() async {
    try {
      if (!Platform.isWindows) return MicrophonePermissionStatus.granted;
      return MicrophonePermissionStatus.granted;
    } catch (e) {
      debugPrint('[WindowsSpeechToText] Permission request exception: $e');
      return MicrophonePermissionStatus.denied;
    }
  }

  static String? _cachedExecutablePath;

  static const String _csharpSourceCode = r'''
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Speech.Recognition;
using System.Threading;

public class Program
{
    public static void Main(string[] args)
    {
        string requestedLocale = args.Length > 0 ? args[0] : "en-IN";
        bool checkOnly = false;
        for (int i = 1; i < args.Length; i++)
        {
            if (string.Equals(args[i], "-CheckOnly", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(args[i], "--check-only", StringComparison.OrdinalIgnoreCase))
            {
                checkOnly = true;
            }
        }
        var runner = new AayusathiSpeechRunner();
        runner.Run(requestedLocale, checkOnly);
    }
}

public class AayusathiSpeechRunner
{
    private SpeechRecognitionEngine _engine;
    private ManualResetEvent _stopEvent = new ManualResetEvent(false);

    public void Run(string requestedLocale, bool checkOnly)
    {
        try
        {
            Console.WriteLine("DIAG:REQUESTED_LOCALE:" + requestedLocale);

            var recognizers = SpeechRecognitionEngine.InstalledRecognizers();
            List<string> avail = new List<string>();
            foreach (var r in recognizers)
            {
                avail.Add(r.Culture.Name + " (" + r.Description + ")");
            }
            Console.WriteLine("DIAG:AVAILABLE_CULTURES:" + string.Join("; ", avail));

            RecognizerInfo selected = null;

            // 1. Try exact match
            foreach (var r in recognizers)
            {
                if (string.Equals(r.Culture.Name, requestedLocale, StringComparison.OrdinalIgnoreCase))
                {
                    selected = r;
                    break;
                }
            }

            // 2. Fallback to English recognizer if requested is English variant or empty
            if (selected == null && (string.IsNullOrEmpty(requestedLocale) || requestedLocale.StartsWith("en", StringComparison.OrdinalIgnoreCase)))
            {
                foreach (var r in recognizers)
                {
                    if (string.Equals(r.Culture.Name, "en-US", StringComparison.OrdinalIgnoreCase))
                    {
                        selected = r;
                        break;
                    }
                }
                if (selected == null)
                {
                    foreach (var r in recognizers)
                    {
                        if (string.Equals(r.Culture.Name, "en-GB", StringComparison.OrdinalIgnoreCase))
                        {
                            selected = r;
                            break;
                        }
                    }
                }
                if (selected == null)
                {
                    foreach (var r in recognizers)
                    {
                        if (r.Culture.Name.StartsWith("en", StringComparison.OrdinalIgnoreCase))
                        {
                            selected = r;
                            break;
                        }
                    }
                }
            }

            if (selected == null)
            {
                string langName = requestedLocale;
                if (string.Equals(requestedLocale, "hi-IN", StringComparison.OrdinalIgnoreCase)) langName = "Hindi";
                else if (string.Equals(requestedLocale, "mr-IN", StringComparison.OrdinalIgnoreCase)) langName = "Marathi";
                else if (string.Equals(requestedLocale, "en-IN", StringComparison.OrdinalIgnoreCase)) langName = "English (India)";
                Console.WriteLine("ERROR:Speech recognition for " + langName + " is not available on this Windows installation. Please use manual entry or switch to English.");
                return;
            }

            Console.WriteLine("DIAG:SELECTED_CULTURE:" + selected.Culture.Name + " (" + selected.Description + ")");
            Console.WriteLine("DIAG:AUDIO_DEVICE:Default Windows Recording Device");

            if (checkOnly)
            {
                Console.WriteLine("DIAG:STATUS:OK");
                return;
            }

            // Explicitly synchronize thread culture for accurate acoustic phoneme normalization
            Thread.CurrentThread.CurrentCulture = selected.Culture;
            Thread.CurrentThread.CurrentUICulture = selected.Culture;

            _engine = new SpeechRecognitionEngine(selected);
            _engine.SetInputToDefaultAudioDevice();

            var grammar = new DictationGrammar("grammar:dictation");
            grammar.Name = "medical_dictation";
            grammar.Weight = 1.0f;
            grammar.Priority = 0;
            _engine.LoadGrammar(grammar);

            _engine.InitialSilenceTimeout = TimeSpan.FromSeconds(6);
            _engine.EndSilenceTimeout = TimeSpan.FromMilliseconds(500);
            _engine.EndSilenceTimeoutAmbiguous = TimeSpan.FromMilliseconds(500);

            _engine.SpeechHypothesized += (s, e) =>
            {
                if (e != null && e.Result != null && !string.IsNullOrWhiteSpace(e.Result.Text))
                {
                    Console.WriteLine("PARTIAL:" + e.Result.Text);
                }
            };

            _engine.SpeechRecognized += (s, e) =>
            {
                if (e != null && e.Result != null && !string.IsNullOrWhiteSpace(e.Result.Text))
                {
                    Console.WriteLine("FINAL:" + e.Result.Text);
                }
            };

            _engine.SpeechRecognitionRejected += (s, e) =>
            {
                if (e != null && e.Result != null)
                {
                    Console.WriteLine("DIAG:REJECTED:Low confidence speech detected");
                }
            };

            _engine.RecognizeAsync(RecognizeMode.Multiple);
            Console.WriteLine("READY");

            Thread stdinThread = new Thread(() =>
            {
                try
                {
                    string line = Console.ReadLine();
                }
                catch {}
                _stopEvent.Set();
            });
            stdinThread.IsBackground = true;
            stdinThread.Start();

            _stopEvent.WaitOne();
        }
        catch (Exception ex)
        {
            Console.WriteLine("ERROR:" + ex.Message);
        }
        finally
        {
            if (_engine != null)
            {
                try
                {
                    _engine.RecognizeAsyncStop();
                    _engine.Dispose();
                }
                catch {}
            }
            Console.WriteLine("STOPPED");
        }
    }
}
''';

  Future<String?> _getOrCompileExecutable() async {
    if (!Platform.isWindows) return null;
    if (_cachedExecutablePath != null && File(_cachedExecutablePath!).existsSync()) {
      return _cachedExecutablePath;
    }

    final tempDir = Directory.systemTemp;
    final exeFile = File('${tempDir.path}${Platform.pathSeparator}aayusathi_speech_engine_v1.exe');
    if (exeFile.existsSync()) {
      _cachedExecutablePath = exeFile.path;
      return exeFile.path;
    }

    final cscCandidates = [
      r'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe',
      r'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe',
    ];
    String? cscPath;
    for (final candidate in cscCandidates) {
      if (File(candidate).existsSync()) {
        cscPath = candidate;
        break;
      }
    }
    if (cscPath == null) return null;

    final speechCandidates = [
      r'C:\WINDOWS\Microsoft.Net\assembly\GAC_MSIL\System.Speech\v4.0_4.0.0.0__31bf3856ad364e35\System.Speech.dll',
      r'C:\Windows\Microsoft.Net\assembly\GAC_MSIL\System.Speech\v4.0_4.0.0.0__31bf3856ad364e35\System.Speech.dll',
      r'C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.0\System.Speech.dll',
    ];
    String? speechDllPath;
    for (final candidate in speechCandidates) {
      if (File(candidate).existsSync()) {
        speechDllPath = candidate;
        break;
      }
    }
    if (speechDllPath == null) return null;

    try {
      final csFile = File('${tempDir.path}${Platform.pathSeparator}aayusathi_speech_engine.cs');
      await csFile.writeAsString(_csharpSourceCode, flush: true);

      final result = await Process.run(
        cscPath,
        [
          '/target:exe',
          '/optimize+',
          '/platform:anycpu',
          '/reference:$speechDllPath',
          '/out:${exeFile.path}',
          csFile.path,
        ],
      );

      if (result.exitCode == 0 && exeFile.existsSync()) {
        debugPrint('[WindowsSpeechToText] Native speech binary pre-compiled successfully at: ${exeFile.path}');
        _cachedExecutablePath = exeFile.path;
        return exeFile.path;
      } else {
        debugPrint('[WindowsSpeechToText] csc compilation note: ${result.stderr} / ${result.stdout}');
      }
    } catch (e) {
      debugPrint('[WindowsSpeechToText] Error during native binary compilation: $e');
    }
    return null;
  }

  /// Safe diagnostic query to inspect Windows Speech Recognition engine status without recording audio.
  Future<WindowsSpeechDiagnostics> checkConfiguration({
    KioskLocale locale = KioskLocale.english,
  }) async {
    final reqTag = resolveLocaleTag(locale);
    if (!Platform.isWindows) {
      return WindowsSpeechDiagnostics(
        requestedLocale: reqTag,
        selectedLocale: 'Mock / Non-Windows Host',
        availableCultures: const ['en-US', 'en-IN'],
        isSupported: true,
        statusMessage: 'Ready (Non-Windows platform)',
      );
    }

    try {
      final exePath = await _getOrCompileExecutable();
      ProcessResult result;
      if (exePath != null) {
        result = await Process.run(exePath, [reqTag, '--check-only']);
      } else {
        final scriptFile = await _ensureScriptFile();
        result = await Process.run(
          'powershell.exe',
          [
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            scriptFile.path,
            '-RequestedLocale',
            reqTag,
            '-CheckOnly',
          ],
        );
      }

      final lines = (result.stdout as String).split(RegExp(r'\r?\n'));
      String? selected;
      final List<String> available = [];
      String? errorMsg;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('DIAG:AVAILABLE_CULTURES:')) {
          final listStr = trimmed.substring(24);
          available.addAll(listStr.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty));
        } else if (trimmed.startsWith('DIAG:SELECTED_CULTURE:')) {
          selected = trimmed.substring(22).trim();
        } else if (trimmed.startsWith('ERROR:')) {
          errorMsg = trimmed.substring(6).trim();
        }
      }

      final isSupported = errorMsg == null && selected != null;
      return WindowsSpeechDiagnostics(
        requestedLocale: reqTag,
        selectedLocale: selected,
        availableCultures: available,
        isSupported: isSupported,
        statusMessage: errorMsg ?? 'Speech recognition engine is ready.',
      );
    } catch (e) {
      return WindowsSpeechDiagnostics(
        requestedLocale: reqTag,
        isSupported: false,
        statusMessage: 'Failed to query Windows Speech configuration: $e',
      );
    }
  }

  Future<File> _ensureScriptFile() async {
    final tempDir = Directory.systemTemp;
    final scriptFile = File('${tempDir.path}${Platform.pathSeparator}aayusathi_speech_engine.ps1');

    final psCode = '''
param(
    [string]\$RequestedLocale = "en-IN",
    [switch]\$CheckOnly
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

\$source = @"
$_csharpSourceCode
"@

Add-Type -TypeDefinition \$source -ReferencedAssemblies "System.Speech"

\$runner = New-Object AayusathiSpeechRunner
\$runner.Run(\$RequestedLocale, \$CheckOnly.IsPresent)
''';

    await scriptFile.writeAsString(psCode, flush: true);
    return scriptFile;
  }

  @override
  Future<void> startListening({
    required String fieldId,
    KioskLocale locale = KioskLocale.english,
    void Function(String partialText)? onPartialResult,
  }) async {
    await _terminateProcess();
    _durationTimer?.cancel();
    _lastError = null;
    _recordingDuration = Duration.zero;
    _currentListeningField = fieldId;
    _transcriptBuffer.clear();
    _latestPartial = '';

    final localeTag = resolveLocaleTag(locale);
    _setState(SpeechRecognitionState.initializing);
    debugPrint('[WindowsSpeechToText] Starting real microphone capture for field: $fieldId (locale: $localeTag)');

    if (!Platform.isWindows) {
      _setState(SpeechRecognitionState.listening);
      _startDurationTimer();
      return;
    }

    try {
      final exePath = await _getOrCompileExecutable();
      if (exePath != null) {
        _speechProcess = await Process.start(exePath, [localeTag]);
      } else {
        final scriptFile = await _ensureScriptFile();
        _speechProcess = await Process.start(
          'powershell.exe',
          [
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            scriptFile.path,
            '-RequestedLocale',
            localeTag,
          ],
        );
      }

      _stdoutSubscription = _speechProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('DIAG:REQUESTED_LOCALE:')) {
          debugPrint('[WindowsSpeechToText] Requested locale: ${trimmed.substring(22)}');
        } else if (trimmed.startsWith('DIAG:AVAILABLE_CULTURES:')) {
          debugPrint('[WindowsSpeechToText] Available recognition cultures: ${trimmed.substring(24)}');
        } else if (trimmed.startsWith('DIAG:SELECTED_CULTURE:')) {
          debugPrint('[WindowsSpeechToText] Selected recognition culture: ${trimmed.substring(22)}');
        } else if (trimmed.startsWith('DIAG:AUDIO_DEVICE:')) {
          debugPrint('[WindowsSpeechToText] Audio device: ${trimmed.substring(18)}');
        } else if (trimmed.startsWith('DIAG:REJECTED:')) {
          debugPrint('[WindowsSpeechToText] Speech rejection event: ${trimmed.substring(14)}');
        } else if (trimmed == 'READY') {
          debugPrint('[WindowsSpeechToText] Microphone engine READY and listening');
          _setState(SpeechRecognitionState.listening);
          _startDurationTimer();
        } else if (trimmed.startsWith('PARTIAL:')) {
          final partialText = trimmed.substring(8).trim();
          _latestPartial = partialText;
          if (!_partialResultController.isClosed) {
            _partialResultController.add(partialText);
          }
          onPartialResult?.call(partialText);
        } else if (trimmed.startsWith('FINAL:')) {
          final finalText = trimmed.substring(6).trim();
          if (finalText.isNotEmpty) {
            if (_transcriptBuffer.isNotEmpty) {
              _transcriptBuffer.write(' ');
            }
            _transcriptBuffer.write(finalText);
            _latestPartial = '';
            final fullText = _transcriptBuffer.toString();
            debugPrint('[WindowsSpeechToText] Recognized phrase: $finalText');
            if (!_partialResultController.isClosed) {
              _partialResultController.add(fullText);
            }
            onPartialResult?.call(fullText);
          }
        } else if (trimmed.startsWith('ERROR:')) {
          _lastError = trimmed.substring(6).trim();
          debugPrint('[WindowsSpeechToText] Engine Error: $_lastError');
          _setState(SpeechRecognitionState.error);
        }
      }, onError: (e) {
        debugPrint('[WindowsSpeechToText] Process stdout error: $e');
      });

      _speechProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((err) {
        if (err.trim().isNotEmpty) {
          debugPrint('[WindowsSpeechToText] Process stderr: $err');
        }
      });

      _speechProcess!.exitCode.then((exitCode) {
        debugPrint('[WindowsSpeechToText] Speech process exited with code $exitCode');
      });
    } catch (e) {
      debugPrint('[WindowsSpeechToText] Failed to start speech process: $e');
      _lastError = 'Unable to access microphone: $e';
      _setState(SpeechRecognitionState.error);
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      if (!_durationController.isClosed) {
        _durationController.add(_recordingDuration);
      }
    });
  }

  @override
  Future<String?> stopListening() async {
    if (_state != SpeechRecognitionState.listening &&
        _state != SpeechRecognitionState.initializing) {
      return null;
    }

    _durationTimer?.cancel();
    _durationTimer = null;
    _setState(SpeechRecognitionState.processing);
    debugPrint('[WindowsSpeechToText] Stopping microphone capture and finalizing transcript...');

    if (_speechProcess != null) {
      try {
        _speechProcess!.stdin.writeln('STOP');
        await _speechProcess!.stdin.flush();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));
      await _terminateProcess();
    }

    _setState(SpeechRecognitionState.ready);

    final finalTranscript = _transcriptBuffer.toString().trim();
    if (finalTranscript.isNotEmpty) {
      debugPrint('[WindowsSpeechToText] Returning final accumulated transcript (length: ${finalTranscript.length})');
      return finalTranscript;
    }
    if (_latestPartial.trim().isNotEmpty) {
      debugPrint('[WindowsSpeechToText] Returning latest partial transcript: $_latestPartial');
      return _latestPartial.trim();
    }
    debugPrint('[WindowsSpeechToText] No speech detected in recording session');
    return null;
  }

  @override
  Future<void> cancelListening() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _currentListeningField = null;
    _recordingDuration = Duration.zero;
    _lastError = null;
    _transcriptBuffer.clear();
    _latestPartial = '';
    debugPrint('[WindowsSpeechToText] Cancelling active recording session');
    await _terminateProcess();
    _setState(SpeechRecognitionState.idle);
  }

  Future<void> _terminateProcess() async {
    await _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    if (_speechProcess != null) {
      try {
        _speechProcess!.kill();
      } catch (_) {}
      _speechProcess = null;
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _terminateProcess();
    _stateController.close();
    _durationController.close();
    _partialResultController.close();
  }
}
