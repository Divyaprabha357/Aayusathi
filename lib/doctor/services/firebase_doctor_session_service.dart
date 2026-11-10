import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../../core/auth/auth_user.dart';
import '../../core/backend/backend_mode.dart';
import '../../models/audit_log.dart';
import '../../repositories/audit_repository.dart';
import '../models/doctor_auth_state.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_ui_status.dart';
import 'doctor_otp_service.dart';
import 'doctor_presence_service.dart';
import 'doctor_session_service.dart';

/// Production Firebase-backed implementation of [DoctorSessionService].
///
/// Flow:
/// 1. Targeted lookup by normalized `doctorUniqueCode` in `/doctors/{doctorId}`.
/// 2. Verification that `isActive == true` (inactive accounts rejected).
/// 3. Credential verification via `FirebaseAuth.instance.signInWithEmailAndPassword()`.
/// 4. Identity linkage verification (`request.auth.uid == profile.authUid`).
/// 5. Phone verification / OTP dispatch via [DoctorOtpService].
/// 6. OTP verification -> transition to [DoctorAuthState.authenticated] with [UserRole.doctor].
/// 7. Logout -> `FirebaseAuth.instance.signOut()`, clean state clearance, audit record.
///
/// CRITICAL SECURITY MANDATES:
/// - Never store passwords in Firestore.
/// - Never expose raw technical Firebase errors or tokens to the doctor.
/// - Maintain strict separation between UI and Firebase calls.
/// - Zero impact on Kiosk sessions or patient records.
class FirebaseDoctorSessionService extends ChangeNotifier
    implements DoctorSessionService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final DoctorOtpService _otpService;
  final AuditRepository? _customAuditRepository;

  DoctorAuthState _authState = DoctorAuthState.loggedOut;
  String? _pendingDoctorCode;
  String? _maskedPhoneNumber;
  String? _activeDoctorId;
  String? _activeDoctorName;
  String? _activeDepartment;
  DoctorProfile? _activeProfile;
  DoctorProfile? _pendingProfile;
  UserRole _role = UserRole.kiosk;
  final DoctorOnlineStatus _onlineStatus = DoctorOnlineStatus.online;
  DoctorWorkStatus _workStatus = DoctorWorkStatus.available;

  FirebaseDoctorSessionService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DoctorOtpService? otpService,
    AuditRepository? auditRepository,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _otpService = otpService ?? WindowsDoctorOtpService(),
        _customAuditRepository = auditRepository;

  AuditRepository get _auditRepo =>
      _customAuditRepository ?? BackendProvider.instance.auditRepository;

  @override
  DoctorAuthState get authState => _authState;

  @override
  bool get isAuthenticated => _authState == DoctorAuthState.authenticated;

  @override
  String? get pendingDoctorCode => _pendingDoctorCode;

  @override
  String? get maskedPhoneNumber => _maskedPhoneNumber;

  @override
  String? get activeDoctorId => _activeDoctorId;

  @override
  String? get activeDoctorName => _activeDoctorName;

  @override
  String? get activeDepartment => _activeDepartment;

  @override
  DoctorProfile? get activeProfile => _activeProfile;

  @override
  DoctorProfile? get pendingProfile => _pendingProfile;

  @override
  UserRole get role => _role;

  @override
  DoctorOnlineStatus get onlineStatus => _onlineStatus;

  @override
  DoctorWorkStatus get workStatus => _workStatus;

  @override
  Future<DoctorAuthResult> validateCredentials({
    required String doctorCode,
    required String password,
  }) async {
    final trimmedCode = doctorCode.trim();

    if (trimmedCode.isEmpty) {
      return const DoctorAuthResult.failure(
        'Please enter your Doctor Unique Code.',
        state: DoctorAuthState.loggedOut,
      );
    }

    if (password.isEmpty) {
      return const DoctorAuthResult.failure(
        'Please enter your password.',
        state: DoctorAuthState.loggedOut,
      );
    }

    final normalizedCode = DoctorProfile.normalizeCode(trimmedCode);

    try {
      // 1. Targeted Firestore query for Admin-provisioned Doctor Profile
      final snapshot = await _firestore
          .collection('doctors')
          .where('doctorUniqueCode', isEqualTo: normalizedCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        await _recordAudit(
          action: 'DOCTOR_AUTH_FAILURE',
          actorId: normalizedCode,
          metadata: {'reason': 'doctor_code_not_found'},
        );
        return const DoctorAuthResult.failure(
          'Invalid login details.',
          state: DoctorAuthState.loggedOut,
        );
      }

      final doc = snapshot.docs.first;
      final profile = DoctorProfile.fromFirestore(doc.data(), doc.id);

      // 2. Administrative active/inactive enforcement
      if (!profile.isActive) {
        await _recordAudit(
          action: 'DOCTOR_AUTH_FAILURE',
          actorId: profile.doctorId,
          metadata: {'reason': 'doctor_account_inactive'},
        );
        return const DoctorAuthResult.failure(
          'Your doctor account is currently inactive. Please contact Hospital Administration.',
          state: DoctorAuthState.loggedOut,
        );
      }

      // 3. Firebase Authentication with physician email credentials
      final email = profile.email.isNotEmpty
          ? profile.email
          : '${profile.doctorUniqueCode.toLowerCase()}@hospital.aayusathi.in';

      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user;
        if (user == null || (profile.authUid.isNotEmpty && user.uid != profile.authUid)) {
          await _auth.signOut();
          await _recordAudit(
            action: 'DOCTOR_AUTH_FAILURE',
            actorId: profile.doctorId,
            metadata: {'reason': 'auth_uid_mismatch'},
          );
          return const DoctorAuthResult.failure(
            'Authentication could not be completed. Please try again.',
            state: DoctorAuthState.loggedOut,
          );
        }
      } on fb.FirebaseAuthException catch (e) {
        await _recordAudit(
          action: 'DOCTOR_AUTH_FAILURE',
          actorId: profile.doctorId,
          metadata: {'code': e.code},
        );
        return DoctorAuthResult.failure(
          _mapFirebaseAuthError(e.code),
          state: DoctorAuthState.loggedOut,
        );
      }

      // 4. Dispatch verification code to registered phone
      final otpSent = await _otpService.sendOtp(
        registeredPhone: profile.registeredPhone,
        doctorId: profile.doctorId,
      );

      if (!otpSent) {
        return const DoctorAuthResult.failure(
          'Unable to send verification code. Please try again.',
          state: DoctorAuthState.loggedOut,
        );
      }

      _authState = DoctorAuthState.otpPending;
      _pendingProfile = profile;
      _pendingDoctorCode = profile.doctorUniqueCode;
      _maskedPhoneNumber = profile.maskedPhone;

      await _recordAudit(
        action: 'DOCTOR_LOGIN_ATTEMPT',
        actorId: profile.doctorId,
        metadata: {'department': profile.department},
      );

      notifyListeners();

      return const DoctorAuthResult.success(
        state: DoctorAuthState.otpPending,
      );
    } catch (e) {
      debugPrint('[FirebaseDoctorSessionService] Exception during validation: $e');
      await _recordAudit(
        action: 'DOCTOR_AUTH_FAILURE',
        actorId: normalizedCode,
        metadata: {'error': 'unexpected_server_error'},
      );
      return const DoctorAuthResult.failure(
        'Unable to connect to the clinical server. Please check your connection and try again.',
        state: DoctorAuthState.loggedOut,
      );
    }
  }

  @override
  Future<DoctorAuthResult> verifyOtp(String otp) async {
    final cleanOtp = otp.trim();

    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      return const DoctorAuthResult.failure(
        'Please enter the 6-digit OTP.',
        state: DoctorAuthState.otpPending,
      );
    }

    if (_pendingProfile == null) {
      return const DoctorAuthResult.failure(
        'Authentication session expired. Please log in again.',
        state: DoctorAuthState.loggedOut,
      );
    }

    final verified = await _otpService.verifyOtp(
      otp: cleanOtp,
      doctorId: _pendingProfile!.doctorId,
    );

    if (!verified) {
      return const DoctorAuthResult.failure(
        'Invalid OTP. Please try again.',
        state: DoctorAuthState.otpPending,
      );
    }

    // OTP Verified -> Establish authenticated doctor session
    _authState = DoctorAuthState.authenticated;
    _role = UserRole.doctor;
    _activeProfile = _pendingProfile;
    _activeDoctorId = _activeProfile!.doctorId;
    _activeDoctorName = _activeProfile!.name;
    _activeDepartment = _activeProfile!.department;
    _pendingProfile = null;

    await _recordAudit(
      action: 'DOCTOR_AUTH_SUCCESS',
      actorId: _activeDoctorId!,
      metadata: {
        'doctorUniqueCode': _activeProfile!.doctorUniqueCode,
        'department': _activeDepartment,
      },
    );

    notifyListeners();

    return const DoctorAuthResult.success(
      state: DoctorAuthState.authenticated,
    );
  }

  @override
  Future<bool> resendOtp() async {
    if (_authState != DoctorAuthState.otpPending || _pendingProfile == null) {
      return false;
    }
    return _otpService.resendOtp(
      registeredPhone: _pendingProfile!.registeredPhone,
      doctorId: _pendingProfile!.doctorId,
    );
  }

  @override
  Future<void> setWorkStatus(DoctorWorkStatus status) async {
    _workStatus = status;
    notifyListeners();
  }

  @override
  void resetSession() {
    _authState = DoctorAuthState.loggedOut;
    _pendingDoctorCode = null;
    _maskedPhoneNumber = null;
    _activeDoctorId = null;
    _activeDoctorName = null;
    _activeDepartment = null;
    _activeProfile = null;
    _pendingProfile = null;
    _role = UserRole.kiosk;
    _workStatus = DoctorWorkStatus.available;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    final docId = _activeDoctorId ?? 'DOCTOR';
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[FirebaseDoctorSessionService] Error signing out from Firebase: $e');
    }

    await _recordAudit(
      action: 'DOCTOR_LOGOUT',
      actorId: docId,
      metadata: {'event': 'doctor_signed_out'},
    );

    await DoctorPresenceService.instance.resetPresence();
    resetSession();
  }

  @override
  bool get isDevelopmentMode => false;

  @override
  Future<void> enterDevelopmentWorkspace({DoctorProfile? profile}) {
    throw UnsupportedError(
      'Development workspace cannot be entered in production Firebase session service.',
    );
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Invalid login details.';
      case 'user-disabled':
        return 'Your doctor account is currently inactive. Please contact Hospital Administration.';
      case 'network-request-failed':
        return 'Unable to connect to the clinical server. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Authentication could not be completed. Please try again.';
    }
  }

  Future<void> _recordAudit({
    required String action,
    required String actorId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final audit = AuditLog(
        auditId: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
        actorType: AuditActorType.doctor.value,
        actorId: actorId,
        action: action,
        entityType: 'DOCTOR_SESSION',
        entityId: actorId,
        timestamp: DateTime.now(),
        metadata: metadata,
      );
      await _auditRepo.logEvent(audit);
    } catch (e) {
      debugPrint('[FirebaseDoctorSessionService] Failed to record audit log: $e');
    }
  }
}
