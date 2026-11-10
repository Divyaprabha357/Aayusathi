import 'dart:async';

/// Abstract contract for Patient OTP delivery and verification.
/// 
/// Privacy & Security Guardrails:
/// - OTP values are NEVER logged in production.
/// - Full phone numbers are NEVER stored or passed without masking.
abstract class PatientOtpService {
  /// Initiates OTP dispatch to the patient's registered phone.
  Future<bool> sendOtp({
    required String patientId,
    required String maskedPhone,
  });

  /// Verifies the provided 6-digit OTP code.
  Future<bool> verifyOtp({
    required String patientId,
    required String otp,
  });

  /// The enforced cooldown duration in seconds between consecutive OTP requests.
  int get resendCooldownSeconds;

  /// Timestamp of the most recent OTP transmission.
  DateTime? get lastSentTime;

  /// Whether a resend is currently permitted based on cooldown.
  bool get canResend;

  /// Remaining seconds before resend is allowed.
  int get remainingCooldownSeconds;
}

/// Controlled mock implementation for development and testing.
/// 
/// Uses deterministic verification rules and strictly isolated test logic.
class MockPatientOtpService implements PatientOtpService {
  final int cooldownSeconds;
  final String defaultTestOtp;
  final Duration simulatedDelay;
  DateTime? _lastSentTime;

  MockPatientOtpService({
    this.cooldownSeconds = 30,
    this.defaultTestOtp = '123456',
    this.simulatedDelay = Duration.zero,
  });

  @override
  int get resendCooldownSeconds => cooldownSeconds;

  @override
  DateTime? get lastSentTime => _lastSentTime;

  @override
  bool get canResend {
    if (_lastSentTime == null) return true;
    final diff = DateTime.now().difference(_lastSentTime!).inSeconds;
    return diff >= cooldownSeconds;
  }

  @override
  int get remainingCooldownSeconds {
    if (_lastSentTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentTime!).inSeconds;
    final remaining = cooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Future<bool> sendOtp({
    required String patientId,
    required String maskedPhone,
  }) async {
    // Check cooldown
    if (!canResend) {
      return false;
    }
    _lastSentTime = DateTime.now();
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    return true;
  }

  @override
  Future<bool> verifyOtp({
    required String patientId,
    required String otp,
  }) async {
    // Validate length and format
    final cleanOtp = otp.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      return false;
    }

    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    // Deterministic mock verification: matches default test OTP or any valid 6-digit in dev
    // For strict testing, matches the configured test OTP or '123456'
    return cleanOtp == defaultTestOtp || cleanOtp == '123456';
  }

  /// Resets cooldown state (useful in test setups).
  void resetCooldown() {
    _lastSentTime = null;
  }
}
