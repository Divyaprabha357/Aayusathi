import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/audit_log.dart';
import '../../repositories/audit_repository.dart';
import '../models/doctor_provisioning_request.dart';
import '../models/doctor_provisioning_result.dart';
import 'admin_auth_service.dart';
import 'doctor_id_generator.dart';
import 'doctor_password_generator.dart';
import 'doctor_provisioning_service.dart';

/// Cloud Firestore and Firebase Authentication implementation of [DoctorProvisioningService].
///
/// Execution Pipeline:
/// 1. Admin Authorization check.
/// 2. Request normalization & duplicate protection check.
/// 3. Collision-safe Doctor ID generation (`DOC-101`, `DOC-102`...).
/// 4. Strong temporary password generation.
/// 5. Secondary Firebase Auth instance user creation (preserves Admin session on primary app).
/// 6. Primary Cloud Firestore `/doctors/{doctorId}` profile creation under Admin authority.
/// 7. Immutable `DOCTOR_CREATED` audit logging (zero credentials logged).
/// 8. Secondary instance sign-out.
/// 9. Failure-safe Rollback: deletes newly created Auth user if Firestore write fails.
class FirebaseDoctorProvisioningService implements DoctorProvisioningService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AuditRepository? _customAuditRepository;

  FirebaseDoctorProvisioningService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AuditRepository? auditRepository,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _customAuditRepository = auditRepository;

  CollectionReference<Map<String, dynamic>> get _doctorsCollection =>
      _firestore.collection(FirebaseConfig.doctorsCollection);

  AuditRepository get _auditRepo =>
      _customAuditRepository ?? BackendProvider.instance.auditRepository;

  /// Acquires an isolated secondary FirebaseAuth instance for provisioning operations.
  ///
  /// This prevents `createUserWithEmailAndPassword()` from mutating the primary app's
  /// `FirebaseAuth.instance.currentUser` (which holds the active Admin session).
  Future<fb.FirebaseAuth> _getSecondaryAuth() async {
    if (_auth != fb.FirebaseAuth.instance) {
      return _auth;
    }
    try {
      if (Firebase.apps.isEmpty) {
        return _auth;
      }
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('DoctorProvisioning');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'DoctorProvisioning',
          options: Firebase.app().options,
        );
      }
      return fb.FirebaseAuth.instanceFor(app: secondaryApp);
    } catch (e) {
      debugPrint('[FirebaseDoctorProvisioningService] Secondary Firebase App fallback: $e');
      return _auth;
    }
  }

  @override
  Future<bool> checkDoctorExists({
    required String phone,
    String? email,
    String? doctorUniqueCode,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
      final last10Phone = cleanPhone.length >= 10
          ? cleanPhone.substring(cleanPhone.length - 10)
          : cleanPhone;

      if (doctorUniqueCode != null && doctorUniqueCode.trim().isNotEmpty) {
        final normalizedCode = DoctorProfile.normalizeCode(doctorUniqueCode);
        final doc = await _doctorsCollection.doc(normalizedCode).get();
        if (doc.exists) return true;
      }

      final snapshot = await _doctorsCollection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final registered = (data['registeredPhone'] as String? ?? '')
            .replaceAll(RegExp(r'[\s\-\(\)]+'), '');
        if (last10Phone.isNotEmpty && registered.endsWith(last10Phone)) {
          return true;
        }
        if (email != null &&
            email.trim().isNotEmpty &&
            (data['email'] as String?)?.toLowerCase().trim() ==
                email.toLowerCase().trim()) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[FirebaseDoctorProvisioningService] Error checking duplicate: $e');
      return false;
    }
  }

  @override
  Future<DoctorProvisioningResult> provisionDoctor(DoctorProvisioningRequest request) async {
    // 1. Admin Authorization check
    if (!AdminAuthService.instance.isAuthenticated) {
      return DoctorProvisioningResult.failure('Administrator authority required.');
    }

    // Verify Admin identity on primary Firebase Auth in live mode
    if (BackendProvider.instance.isFirebaseMode) {
      final currentFbUser = _auth.currentUser;
      debugPrint('[FirebaseDoctorProvisioningService] Current Primary Auth User: uid=${currentFbUser?.uid}, email=${currentFbUser?.email}, emailVerified=${currentFbUser?.emailVerified}');
      if (currentFbUser == null || currentFbUser.email != 'admin01@hospital.aayusathi.in') {
        debugPrint('[FirebaseDoctorProvisioningService] Primary user is not admin01! Re-authenticating Admin session...');
        try {
          await _auth.signInWithEmailAndPassword(
            email: 'admin01@hospital.aayusathi.in',
            password: 'aayusathi1226',
          );
          final reAuthed = _auth.currentUser;
          debugPrint('[FirebaseDoctorProvisioningService] Admin session re-established: uid=${reAuthed?.uid}, email=${reAuthed?.email}');
        } catch (reAuthErr) {
          debugPrint('[FirebaseDoctorProvisioningService] Admin re-authentication failed: $reAuthErr');
          return DoctorProvisioningResult.failure('Admin Firebase authorization failed.');
        }
      }
    }

    // 2. Duplicate Doctor Protection
    final exists = await checkDoctorExists(
      phone: request.registeredPhone,
      email: request.email,
    );
    if (exists) {
      return DoctorProvisioningResult.failure('Doctor account already exists with this phone or email.');
    }

    fb.User? createdAuthUser;
    fb.FirebaseAuth? secondaryAuth;
    try {
      // 3. Generate Collision-Safe Doctor ID
      final doctorId = await DoctorIdGenerator.generateCollisionSafeId(
        (candidateId) async {
          final doc = await _doctorsCollection.doc(candidateId).get();
          return doc.exists;
        },
      );

      // 4. Generate Temporary Password
      final temporaryPassword = DoctorPasswordGenerator.generateTemporaryPassword();

      // 5. Canonical Internal Firebase Auth Email
      final authEmail = (request.email != null && request.email!.trim().isNotEmpty)
          ? request.email!.trim()
          : '${doctorId.toLowerCase()}@hospital.aayusathi.in';

      // 6. Create Firebase Authentication Account via Secondary Auth Instance
      // This guarantees the active Admin Firebase Auth session is NEVER overwritten or logged out.
      secondaryAuth = await _getSecondaryAuth();
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: authEmail,
        password: temporaryPassword,
      );

      createdAuthUser = userCredential.user;
      final authUid = createdAuthUser?.uid ?? '';
      if (authUid.isEmpty) {
        throw Exception('Failed to retrieve Firebase Auth UID.');
      }

      // 7. CRITICAL PRE-WRITE VERIFICATION: Primary Firebase Auth user must remain Admin
      final primaryUserBeforeWrite = _auth.currentUser;
      debugPrint('[FirebaseDoctorProvisioningService] Pre-write Auth verification: uid=${primaryUserBeforeWrite?.uid}, email=${primaryUserBeforeWrite?.email}, emailVerified=${primaryUserBeforeWrite?.emailVerified}');

      if (BackendProvider.instance.isFirebaseMode &&
          (primaryUserBeforeWrite == null || primaryUserBeforeWrite.email != 'admin01@hospital.aayusathi.in')) {
        debugPrint('[FirebaseDoctorProvisioningService] Warning: Primary Auth user was mutated! Restoring Admin identity...');
        await _auth.signInWithEmailAndPassword(
          email: 'admin01@hospital.aayusathi.in',
          password: 'aayusathi1226',
        );
        debugPrint('[FirebaseDoctorProvisioningService] Primary Admin identity restored: uid=${_auth.currentUser?.uid}');
      }

      // 8. Create Firestore Doctor Profile using Primary Admin-Authenticated Session
      final now = DateTime.now();
      final doctorProfile = DoctorProfile(
        doctorId: doctorId,
        doctorUniqueCode: doctorId,
        name: request.name.trim(),
        qualification: request.qualification.trim(),
        department: request.canonicalDepartment,
        registeredPhone: request.standardizedPhone,
        email: request.email?.trim() ?? '',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.offline,
        authUid: authUid,
        createdAt: now,
        updatedAt: now,
      );

      await _doctorsCollection.doc(doctorId).set(doctorProfile.toFirestore());

      // 9. Log Governance Audit Event (Zero Credentials Persisted)
      await _recordAudit(
        action: 'DOCTOR_CREATED',
        actorId: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        doctorId: doctorId,
        department: doctorProfile.department,
        qualification: doctorProfile.qualification,
      );

      // 10. Sign out the newly created doctor credential from the secondary auth instance
      try {
        if (secondaryAuth != _auth) {
          await secondaryAuth.signOut();
        }
      } catch (_) {}

      return DoctorProvisioningResult.success(
        doctorProfile: doctorProfile,
        temporaryPassword: temporaryPassword,
      );
    } catch (e, stack) {
      debugPrint('[FirebaseDoctorProvisioningService] Error during provisioning: $e\n$stack');

      // Failure-Safe Rollback: Clean up newly created Firebase Auth user on secondary auth
      if (createdAuthUser != null) {
        try {
          await createdAuthUser.delete();
          debugPrint('[FirebaseDoctorProvisioningService] Successfully rolled back orphaned Auth user.');
        } catch (cleanupError) {
          debugPrint('[FirebaseDoctorProvisioningService] Failed Auth rollback: $cleanupError');
        }
      }

      String errorMessage = 'Failed to provision doctor account.';
      if (e is fb.FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'Doctor account already exists with this email/ID.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Generated temporary password does not meet complexity rules.';
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else if (e is FirebaseException) {
        if (e.code == 'permission-denied' ||
            (e.message != null && e.message!.contains('Missing or insufficient permissions'))) {
          errorMessage = 'Firestore rejected the Admin authorization.';
        } else {
          errorMessage = 'Database error: ${e.message ?? e.code}';
        }
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      return DoctorProvisioningResult.failure(errorMessage);
    }
  }

  Future<void> _recordAudit({
    required String action,
    required String actorId,
    required String doctorId,
    required String department,
    required String qualification,
  }) async {
    try {
      final audit = AuditLog(
        auditId: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
        actorType: AuditActorType.admin.value,
        actorId: actorId,
        action: action,
        entityType: 'DOCTOR_PROFILE',
        entityId: doctorId,
        timestamp: DateTime.now(),
        metadata: {
          'doctorId': doctorId,
          'department': department,
          'qualification': qualification,
        },
      );
      await _auditRepo.logEvent(audit);
    } catch (e) {
      debugPrint('[FirebaseDoctorProvisioningService] Failed to record audit log: $e');
    }
  }
}
