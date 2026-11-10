import '../../core/backend/backend_mode.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/audit_log.dart';
import '../../repositories/audit_repository.dart';
import '../../repositories/mock/mock_doctor_repository.dart';
import '../models/doctor_provisioning_request.dart';
import '../models/doctor_provisioning_result.dart';
import 'admin_auth_service.dart';
import 'doctor_id_generator.dart';
import 'doctor_password_generator.dart';
import 'doctor_provisioning_service.dart';

/// In-memory mock implementation of [DoctorProvisioningService] for automated testing and offline mode.
class MockDoctorProvisioningService implements DoctorProvisioningService {
  final Map<String, DoctorProfile> _doctors = {};
  final AuditRepository? _customAuditRepository;

  bool shouldFailAuth = false;
  bool shouldFailFirestore = false;
  bool shouldSimulateDuplicate = false;

  MockDoctorProvisioningService({
    AuditRepository? auditRepository,
  }) : _customAuditRepository = auditRepository;

  AuditRepository get _auditRepo =>
      _customAuditRepository ?? BackendProvider.instance.auditRepository;

  List<DoctorProfile> get provisionedDoctors => _doctors.values.toList();

  void addExistingDoctor(DoctorProfile profile) {
    _doctors[profile.doctorId] = profile;
  }

  void clear() {
    _doctors.clear();
    shouldFailAuth = false;
    shouldFailFirestore = false;
    shouldSimulateDuplicate = false;
  }

  @override
  Future<bool> checkDoctorExists({
    required String phone,
    String? email,
    String? doctorUniqueCode,
  }) async {
    if (shouldSimulateDuplicate) return true;

    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    final last10Phone = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    if (doctorUniqueCode != null && doctorUniqueCode.isNotEmpty) {
      if (_doctors.containsKey(DoctorProfile.normalizeCode(doctorUniqueCode))) {
        return true;
      }
    }

    for (final doc in _doctors.values) {
      final regClean = doc.registeredPhone.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
      if (last10Phone.isNotEmpty && regClean.endsWith(last10Phone)) {
        return true;
      }
      if (email != null && email.isNotEmpty && doc.email.toLowerCase() == email.toLowerCase().trim()) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<DoctorProvisioningResult> provisionDoctor(DoctorProvisioningRequest request) async {
    // 1. Admin Authorization check
    if (!AdminAuthService.instance.isAuthenticated) {
      return DoctorProvisioningResult.failure('Administrator authority required.');
    }

    // 2. Duplicate Doctor Protection
    final exists = await checkDoctorExists(
      phone: request.registeredPhone,
      email: request.email,
    );
    if (exists) {
      return DoctorProvisioningResult.failure('Doctor account already exists with this phone or email.');
    }

    // 3. Simulated Auth Failure
    if (shouldFailAuth) {
      return DoctorProvisioningResult.failure('Firebase Authentication service error.');
    }

    // 4. Generate Unique Collision-Safe ID
    final doctorId = DoctorIdGenerator.generateNextId(_doctors.keys);

    // 5. Generate Password
    final temporaryPassword = DoctorPasswordGenerator.generateTemporaryPassword();

    // 6. Simulated Firestore Failure (with Auth rollback)
    if (shouldFailFirestore) {
      return DoctorProvisioningResult.failure('Cloud Firestore database write error.');
    }

    // 7. Create Profile
    final now = DateTime.now();
    final profile = DoctorProfile(
      doctorId: doctorId,
      doctorUniqueCode: doctorId,
      name: request.name.trim(),
      qualification: request.qualification.trim(),
      department: request.canonicalDepartment,
      registeredPhone: request.standardizedPhone,
      email: request.email?.trim() ?? '',
      isActive: true,
      availabilityStatus: DoctorAvailabilityStatus.offline,
      authUid: 'mock-uid-$doctorId',
      createdAt: now,
      updatedAt: now,
    );

    _doctors[doctorId] = profile;
    MockDoctorRepository.instance.saveDoctorProfile(profile);

    // 8. Audit Log
    try {
      final audit = AuditLog(
        auditId: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
        actorType: AuditActorType.admin.value,
        actorId: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        action: 'DOCTOR_CREATED',
        entityType: 'DOCTOR_PROFILE',
        entityId: doctorId,
        timestamp: DateTime.now(),
        metadata: {
          'doctorId': doctorId,
          'department': profile.department,
          'qualification': profile.qualification,
        },
      );
      await _auditRepo.logEvent(audit);
    } catch (_) {}

    return DoctorProvisioningResult.success(
      doctorProfile: profile,
      temporaryPassword: temporaryPassword,
    );
  }
}
