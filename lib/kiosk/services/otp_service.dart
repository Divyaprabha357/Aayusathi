/// Status code for OTP verification actions.
enum OtpStatus {
  success,
  invalid,
  tooManyAttempts,
  expired,
  inProgress,
  error,
}

/// Discrete lifecycle states of the OTP verification workflow.
enum OtpFlowState {
  initial,
  sending,
  sent,
  verifying,
  verified,
  incorrect,
  cooldown,
  lockedOut,
  error,
}

/// Structured response object from OtpService.
class OtpResult {
  final OtpStatus status;
  final String? message;
  final int attemptsRemaining;
  final OtpFlowState flowState;

  const OtpResult({
    required this.status,
    this.message,
    this.attemptsRemaining = 3,
    this.flowState = OtpFlowState.initial,
  });

  bool get isSuccess => status == OtpStatus.success;
  bool get isInvalid => status == OtpStatus.invalid;
  bool get isLockedOut => status == OtpStatus.tooManyAttempts;

  const OtpResult.success([this.message])
      : status = OtpStatus.success,
        attemptsRemaining = 3,
        flowState = OtpFlowState.verified;

  const OtpResult.invalid({required this.attemptsRemaining, this.message})
      : status = OtpStatus.invalid,
        flowState = OtpFlowState.incorrect;

  const OtpResult.tooManyAttempts([this.message])
      : status = OtpStatus.tooManyAttempts,
        attemptsRemaining = 0,
        flowState = OtpFlowState.lockedOut;

  const OtpResult.inProgress([this.message])
      : status = OtpStatus.inProgress,
        attemptsRemaining = 3,
        flowState = OtpFlowState.verifying;

  const OtpResult.error([this.message])
      : status = OtpStatus.error,
        attemptsRemaining = 3,
        flowState = OtpFlowState.error;
}

/// Abstract contract for OTP operations at the AAYUSATHI Kiosk.
/// Keeps UI decoupled from Mock vs future Firebase/SMS providers.
abstract class OtpService {
  Future<OtpResult> sendOtp(String phoneNumber, {bool? simulateDelay});
  Future<OtpResult> verifyOtp(String otp, {String? phoneNumber, bool? simulateDelay});
  Future<OtpResult> resendOtp(String phoneNumber, {bool? simulateDelay});
  OtpFlowState get state;
  int get failedAttempts;
  int get attemptsRemaining;
  int get cooldownRemainingSeconds;
  bool get canResend;
  bool get isLockedOut;
  void reset();
}

/// Controlled Mock OTP service for Phase 6.5.
/// Uses deterministic test OTP ('123456'), enforces attempt limit (max 3),
/// guards against duplicate concurrent taps, validates patient context, and tracks state.
class MockOtpService implements OtpService {
  static const String defaultTestOtp = '123456';
  static const int maxAttempts = 3;

  int _failedAttempts = 0;
  DateTime? _lastSentTime;
  OtpFlowState _state = OtpFlowState.initial;
  bool simulateDelay;
  int cooldownSeconds;
  String testOtp;

  MockOtpService({
    this.simulateDelay = true,
    this.cooldownSeconds = 30,
    this.testOtp = defaultTestOtp,
  });

  @override
  OtpFlowState get state => _state;

  @override
  int get failedAttempts => _failedAttempts;

  @override
  int get attemptsRemaining => (maxAttempts - _failedAttempts).clamp(0, maxAttempts);

  @override
  bool get isLockedOut => _failedAttempts >= maxAttempts || _state == OtpFlowState.lockedOut;

  @override
  int get cooldownRemainingSeconds {
    if (_lastSentTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentTime!).inSeconds;
    final remaining = cooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  @override
  bool get canResend => cooldownRemainingSeconds <= 0 && !isLockedOut && _state != OtpFlowState.sending;

  @override
  Future<OtpResult> sendOtp(String phoneNumber, {bool? simulateDelay}) async {
    if (phoneNumber.trim().isEmpty) {
      return const OtpResult.error('Phone number is required to send OTP.');
    }

    if (_state == OtpFlowState.sending) {
      return const OtpResult.inProgress('OTP request already in progress.');
    }

    _state = OtpFlowState.sending;

    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _failedAttempts = 0;
    _lastSentTime = DateTime.now();
    _state = OtpFlowState.sent;
    return const OtpResult(
      status: OtpStatus.success,
      flowState: OtpFlowState.sent,
      message: 'OTP sent.',
    );
  }

  @override
  Future<OtpResult> verifyOtp(String otp, {String? phoneNumber, bool? simulateDelay}) async {
    // 1. Lockout Guard
    if (isLockedOut) {
      _state = OtpFlowState.lockedOut;
      return const OtpResult.tooManyAttempts();
    }

    // 2. Identity / Phone Context Guard
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      _state = OtpFlowState.error;
      return const OtpResult.error('Cannot verify OTP without a valid patient phone number.');
    }

    // 3. Duplicate Operation Guard
    if (_state == OtpFlowState.verifying) {
      return const OtpResult.inProgress('Verification in progress. Duplicate tap ignored.');
    }

    _state = OtpFlowState.verifying;

    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 350));
    }

    final cleanOtp = otp.replaceAll(RegExp(r'\s+'), '').trim();

    if (cleanOtp == testOtp) {
      _failedAttempts = 0;
      _state = OtpFlowState.verified;
      return const OtpResult.success();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= maxAttempts) {
        _state = OtpFlowState.lockedOut;
        return const OtpResult.tooManyAttempts();
      } else {
        _state = OtpFlowState.incorrect;
        return OtpResult.invalid(
          attemptsRemaining: attemptsRemaining,
        );
      }
    }
  }

  @override
  Future<OtpResult> resendOtp(String phoneNumber, {bool? simulateDelay}) async {
    if (isLockedOut) {
      return const OtpResult.tooManyAttempts();
    }

    if (!canResend) {
      return OtpResult.error('Resend on cooldown. Please wait $cooldownRemainingSeconds seconds.');
    }

    _state = OtpFlowState.sending;

    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _lastSentTime = DateTime.now();
    _state = OtpFlowState.cooldown;
    return const OtpResult.success('New OTP sent.');
  }

  @override
  void reset() {
    _failedAttempts = 0;
    _lastSentTime = null;
    _state = OtpFlowState.initial;
  }
}
