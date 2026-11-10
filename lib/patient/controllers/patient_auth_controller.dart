import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/patient_lookup_result.dart';
import '../models/patient_session.dart';
import '../services/patient_auth_service.dart';
import '../services/patient_otp_service.dart';
import '../services/patient_session_service.dart';

enum PatientAuthStatus {
  idle,
  validatingId,
  idVerified,
  sendingOtp,
  otpSent,
  verifyingOtp,
  authenticated,
  error,
}

/// Controller managing Patient ID lookup, OTP delivery, and authenticated session creation.
/// 
/// Privacy & Security Guardrails:
/// - Strictly NEVER logs or exposes plaintext OTP codes or Aadhaar.
/// - Stores and displays phone numbers only in masked format (`+91 ******4321`).
class PatientAuthController extends ChangeNotifier {
  final PatientAuthService _authService;
  final PatientOtpService _otpService;
  final PatientSessionService _sessionService;

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  PatientAuthController({
    PatientAuthService? authService,
    PatientOtpService? otpService,
    PatientSessionService? sessionService,
  })  : _authService = authService ?? PatientAuthService(),
        _otpService = otpService ?? MockPatientOtpService(),
        _sessionService = sessionService ?? PatientSessionService.instance;

  PatientAuthStatus _status = PatientAuthStatus.idle;
  String? _errorMessage;
  String? _pendingPatientId;
  String _maskedPhone = '+91 ******4321';

  PatientAuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get pendingPatientId => _pendingPatientId;
  String get maskedPhone => _maskedPhone;
  int get cooldownRemaining => _cooldownRemaining;
  bool get canResendOtp => _cooldownRemaining <= 0 && _otpService.canResend;
  bool get isLoading =>
      _status == PatientAuthStatus.validatingId ||
      _status == PatientAuthStatus.sendingOtp ||
      _status == PatientAuthStatus.verifyingOtp;

  /// Sets pending patient ID and masked phone when arriving at OTP screen directly.
  void setPendingPatient(String patientId, {String? maskedPhone}) {
    _pendingPatientId = patientId.trim().toUpperCase();
    if (maskedPhone != null && maskedPhone.isNotEmpty) {
      _maskedPhone = maskedPhone;
    }
    _status = PatientAuthStatus.otpSent;
    notifyListeners();
  }

  /// Looks up the patient ID in Firestore and initiates OTP dispatch.
  Future<bool> submitPatientId(String rawInput) async {
    final cleanId = rawInput.trim().toUpperCase();
    if (cleanId.isEmpty) {
      _errorMessage = 'Please enter your Patient ID.';
      _status = PatientAuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = PatientAuthStatus.validatingId;
    _errorMessage = null;
    notifyListeners();

    try {
      final PatientLookupResult result = await _authService.lookupPatientById(cleanId);

      if (!result.isSuccessful) {
        _errorMessage = result.errorMessage ?? 'Unable to verify Patient ID.';
        _status = PatientAuthStatus.error;
        notifyListeners();
        return false;
      }

      _pendingPatientId = result.patientId;
      _maskedPhone = result.maskedPhone ?? '+91 ******4321';

      // Send initial OTP via OTP abstraction
      _status = PatientAuthStatus.sendingOtp;
      notifyListeners();

      final otpSent = await _otpService.sendOtp(
        patientId: _pendingPatientId!,
        maskedPhone: _maskedPhone,
      );

      if (!otpSent) {
        _errorMessage = 'Unable to send OTP. Please try again in a moment.';
        _status = PatientAuthStatus.error;
        notifyListeners();
        return false;
      }

      // Update session intermediate state
      _sessionService.setSession(PatientSession.otpPending(_pendingPatientId!));

      // Start resend cooldown timer (30 seconds)
      _startCooldownTimer(_otpService.resendCooldownSeconds);

      _status = PatientAuthStatus.idVerified;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _status = PatientAuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Verifies the entered 6-digit OTP code.
  Future<bool> verifyOtp(String otpCode) async {
    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      _errorMessage = 'Please enter a valid 6-digit code.';
      _status = PatientAuthStatus.error;
      notifyListeners();
      return false;
    }

    if (_pendingPatientId == null) {
      _errorMessage = 'Session expired. Please enter your Patient ID again.';
      _status = PatientAuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = PatientAuthStatus.verifyingOtp;
    _errorMessage = null;
    notifyListeners();

    try {
      final isVerified = await _otpService.verifyOtp(
        patientId: _pendingPatientId!,
        otp: cleanOtp,
      );

      if (!isVerified) {
        _errorMessage = 'Invalid OTP. Please check the code and try again.';
        _status = PatientAuthStatus.error;
        notifyListeners();
        return false;
      }

      // Create authenticated patient session
      _cooldownTimer?.cancel();
      _cooldownTimer = null;
      _cooldownRemaining = 0;
      _sessionService.startSession(_pendingPatientId!);

      _status = PatientAuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Verification failed. Please try again.';
      _status = PatientAuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Triggers a resend of the OTP code if cooldown has expired.
  Future<bool> resendOtp() async {
    if (!canResendOtp || _pendingPatientId == null) {
      _errorMessage = 'Please wait before requesting a new OTP.';
      notifyListeners();
      return false;
    }

    _status = PatientAuthStatus.sendingOtp;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _otpService.sendOtp(
        patientId: _pendingPatientId!,
        maskedPhone: _maskedPhone,
      );

      if (success) {
        _startCooldownTimer(_otpService.resendCooldownSeconds);
        _status = PatientAuthStatus.otpSent;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Unable to resend OTP at this time.';
        _status = PatientAuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to resend OTP. Please try again.';
      _status = PatientAuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void _startCooldownTimer(int seconds) {
    _cooldownTimer?.cancel();
    if (seconds <= 0) {
      _cooldownRemaining = 0;
      _cooldownTimer = null;
      notifyListeners();
      return;
    }
    _cooldownRemaining = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining > 1) {
        _cooldownRemaining--;
        notifyListeners();
      } else {
        _cooldownRemaining = 0;
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
        notifyListeners();
      }
    });
  }

  /// Resets controller state back to clean initial state.
  void reset() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownRemaining = 0;
    _status = PatientAuthStatus.idle;
    _errorMessage = null;
    _pendingPatientId = null;
    _maskedPhone = '+91 ******4321';
    notifyListeners();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
