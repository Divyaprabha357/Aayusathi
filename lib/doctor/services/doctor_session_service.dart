import 'package:flutter/foundation.dart';
import '../../core/auth/auth_user.dart';
import '../models/doctor_auth_state.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_ui_status.dart';
import 'mock_doctor_session_service.dart';

/// Contract for Doctor session and authentication management.
///
/// In Phase D2, this was driven by a local/mock foundation.
/// In Phase D3, this is backed by [FirebaseDoctorSessionService] for production,
/// and [MockDoctorSessionService] for automated tests and offline preview.
abstract class DoctorSessionService extends ChangeNotifier {
  /// Global active session service instance.
  static DoctorSessionService instance = DefaultDoctorSessionService();

  /// Current authentication state in the workstation session lifecycle.
  DoctorAuthState get authState;

  /// Whether a doctor is actively authenticated.
  bool get isAuthenticated => authState == DoctorAuthState.authenticated;

  /// Doctor Unique Code currently in progress of verification.
  String? get pendingDoctorCode;

  /// Masked mobile number for OTP destination display (e.g. '******4321').
  String? get maskedPhoneNumber;

  /// Authenticated doctor profile fields (empty when logged out).
  String? get activeDoctorId;
  String? get activeDoctorName;
  String? get activeDepartment;

  /// Complete authenticated doctor profile in session.
  DoctorProfile? get activeProfile;

  /// In-progress doctor profile pending OTP verification.
  DoctorProfile? get pendingProfile;

  /// Active ecosystem role associated with this workstation identity.
  UserRole get role;

  DoctorOnlineStatus get onlineStatus;
  DoctorWorkStatus get workStatus;

  /// Validates Doctor Unique Code and password.
  Future<DoctorAuthResult> validateCredentials({
    required String doctorCode,
    required String password,
  });

  /// Verifies the 6-digit numeric OTP.
  Future<DoctorAuthResult> verifyOtp(String otp);

  /// Requests a fresh OTP dispatch to the registered mobile number.
  Future<bool> resendOtp();

  /// Updates clinical work status.
  Future<void> setWorkStatus(DoctorWorkStatus status);

  /// Resets temporary login state and returns to logged-out state.
  void resetSession();

  /// Terminates active session and resets state.
  Future<void> logout();

  /// Whether the workstation session is currently running in development/demo mode.
  bool get isDevelopmentMode => false;

  /// Activates an isolated development/demo doctor session without calling Firebase.
  Future<void> enterDevelopmentWorkspace({DoctorProfile? profile});
}

/// Default implementation providing backward compatibility for D1/D2 tests and mocks.
class DefaultDoctorSessionService extends MockDoctorSessionService {}

/// Backward compatibility stub for Phase D1 references.
class StubDoctorSessionService extends DefaultDoctorSessionService {}
