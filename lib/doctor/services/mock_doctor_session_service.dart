import 'package:flutter/foundation.dart';
import '../../core/auth/auth_user.dart';
import '../../models/audit_log.dart';
import '../../repositories/audit_repository.dart';
import '../models/doctor_auth_state.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_ui_status.dart';
import 'doctor_otp_service.dart';
import 'doctor_presence_service.dart';
import 'doctor_profile_service.dart';
import 'doctor_session_service.dart';

/// In-memory mock implementation of [DoctorSessionService] for automated testing
/// and offline development.
///
/// Features:
/// - Provides deterministic doctor profile fixtures (active, inactive).
/// - Enforces normalized Doctor Unique Code lookup.
/// - Simulates the OTP verification lifecycle.
/// - Verifies that inactive doctors are rejected with appropriate clinical messaging.
/// - Enforces [UserRole.doctor] upon successful authentication.
/// - Never persists passwords.
class MockDoctorSessionService extends ChangeNotifier
    implements DoctorSessionService {
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
  bool _isDevelopmentMode = false;

  final DoctorOtpService _otpService;
  final AuditRepository? _customAuditRepository;

  final Map<String, DoctorProfile> _doctorStore = {};

  MockDoctorSessionService({
    DoctorOtpService? otpService,
    AuditRepository? auditRepository,
  })  : _otpService = otpService ?? MockDoctorOtpService(),
        _customAuditRepository = auditRepository {
    _initializeFixtures();
  }

  void _initializeFixtures() {
    registerProfile(
      DoctorProfile(
        doctorId: 'DOC-101',
        doctorUniqueCode: 'DOC-101',
        name: 'Dr. Physician',
        qualification: 'MBBS, MD (Cardiology)',
        department: 'cardiology',
        registeredPhone: '+919876543210',
        email: 'dr.physician@aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        authUid: 'mock-auth-uid-doc-001',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    );

    registerProfile(
      DoctorProfile(
        doctorId: 'DOC-INACTIVE',
        doctorUniqueCode: 'DOC-INACTIVE',
        name: 'Dr. Inactive Physician',
        qualification: 'MBBS',
        department: 'neurology',
        registeredPhone: '+919876543211',
        email: 'dr.inactive@aayusathi.in',
        isActive: false,
        availabilityStatus: DoctorAvailabilityStatus.offline,
        authUid: 'mock-auth-uid-inactive',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    );
  }

  /// Registers or overrides a doctor profile fixture in memory.
  void registerProfile(DoctorProfile profile) {
    _doctorStore[DoctorProfile.normalizeCode(profile.doctorUniqueCode)] = profile;
  }

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

    final normalized = DoctorProfile.normalizeCode(trimmedCode);

    // Explicit test fixture rejection patterns
    if (normalized == 'INVALID' || password == 'WRONG') {
      await _recordAudit(
        action: 'DOCTOR_AUTH_FAILURE',
        actorId: normalized,
        metadata: {'reason': 'invalid_credentials'},
      );
      return const DoctorAuthResult.failure(
        'Invalid login details.',
        state: DoctorAuthState.loggedOut,
      );
    }

    // Lookup profile fixture
    final profile = _doctorStore[normalized];

    // Inactive doctor rejection rule
    if (profile != null && !profile.isActive) {
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

    _authState = DoctorAuthState.otpPending;
    _pendingDoctorCode = trimmedCode;
    _pendingProfile = profile;
    _maskedPhoneNumber = profile?.maskedPhone ?? '******4321';

    await _otpService.sendOtp(
      registeredPhone: profile?.registeredPhone ?? '+919876543210',
      doctorId: profile?.doctorId ?? trimmedCode,
    );

    await _recordAudit(
      action: 'DOCTOR_LOGIN_ATTEMPT',
      actorId: profile?.doctorId ?? trimmedCode,
      metadata: {'doctorUniqueCode': normalized},
    );

    notifyListeners();

    return const DoctorAuthResult.success(
      state: DoctorAuthState.otpPending,
    );
  }

  @override
  Future<DoctorAuthResult> verifyOtp(String otp) async {
    final trimmedOtp = otp.trim();

    if (trimmedOtp.length != 6 || int.tryParse(trimmedOtp) == null) {
      return const DoctorAuthResult.failure(
        'Please enter the 6-digit OTP.',
        state: DoctorAuthState.otpPending,
      );
    }

    final verified = await _otpService.verifyOtp(
      otp: trimmedOtp,
      doctorId: _pendingProfile?.doctorId ?? _pendingDoctorCode ?? 'DOC-UNKNOWN',
    );

    if (!verified) {
      return const DoctorAuthResult.failure(
        'Invalid OTP. Please try again.',
        state: DoctorAuthState.otpPending,
      );
    }

    // Successful authentication
    _authState = DoctorAuthState.authenticated;
    _role = UserRole.doctor;
    _activeProfile = _pendingProfile;
    _activeDoctorId = _pendingProfile?.doctorId ?? _pendingDoctorCode ?? 'DOC-OFFICIAL';
    _activeDoctorName = _pendingProfile?.name ?? 'Dr. Physician';
    _activeDepartment = _pendingProfile?.department ?? 'General OPD';
    _pendingProfile = null;

    await _recordAudit(
      action: 'DOCTOR_AUTH_SUCCESS',
      actorId: _activeDoctorId ?? 'DOC-OFFICIAL',
      metadata: {'department': _activeDepartment},
    );

    notifyListeners();

    return const DoctorAuthResult.success(
      state: DoctorAuthState.authenticated,
    );
  }

  @override
  Future<bool> resendOtp() async {
    if (_authState != DoctorAuthState.otpPending) return false;
    return _otpService.resendOtp(
      registeredPhone: _pendingProfile?.registeredPhone ?? '+919876543210',
      doctorId: _pendingProfile?.doctorId ?? _pendingDoctorCode ?? 'DOC-OFFICIAL',
    );
  }

  @override
  Future<void> setWorkStatus(DoctorWorkStatus status) async {
    _workStatus = status;
    notifyListeners();
  }

  @override
  bool get isDevelopmentMode => _isDevelopmentMode;

  @override
  Future<void> enterDevelopmentWorkspace({DoctorProfile? profile}) async {
    final devProfile = profile ?? MockDoctorProfileService.demoDoctor;
    _isDevelopmentMode = true;
    _authState = DoctorAuthState.authenticated;
    _role = UserRole.doctor;
    _activeProfile = devProfile;
    _activeDoctorId = devProfile.doctorId;
    _activeDoctorName = devProfile.name;
    _activeDepartment = devProfile.department;
    _workStatus = DoctorWorkStatus.available;
    _pendingProfile = null;
    _pendingDoctorCode = null;

    await DoctorPresenceService.instance.setAvailable();
    notifyListeners();
  }

  @override
  void resetSession() {
    _isDevelopmentMode = false;
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
    final wasDev = _isDevelopmentMode;
    final docId = _activeDoctorId ?? 'DOC-OFFICIAL';
    if (!wasDev) {
      await _recordAudit(
        action: 'DOCTOR_LOGOUT',
        actorId: docId,
        metadata: {'event': 'doctor_signed_out'},
      );
    }
    await DoctorPresenceService.instance.resetPresence();
    resetSession();
  }

  Future<void> _recordAudit({
    required String action,
    required String actorId,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (_customAuditRepository == null) return;
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
      await _customAuditRepository.logEvent(audit);
    } catch (e) {
      debugPrint('[MockDoctorSessionService] Audit log exception: $e');
    }
  }
}
