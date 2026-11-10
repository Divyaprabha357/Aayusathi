import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/doctor.dart';
import '../doctor_repository.dart';

/// Cloud Firestore implementation of [DoctorRepository].
///
/// Manages doctor registry, physician profiles, and availability querying under the `doctors` collection.
class FirebaseDoctorRepository implements DoctorRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseDoctorRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirebaseConfig.doctorsCollection);

  @override
  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      final doc = await _collection.doc(doctorId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Doctor.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on getDoctorById: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not fetch doctor details from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Doctor>> getDoctorsForDomain(String domainId) async {
    try {
      final query = await _collection
          .where('domains', arrayContains: domainId.toLowerCase())
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => Doctor.fromFirestore(doc.data(), doc.id)).toList();
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on query: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not query domain doctors.',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isDoctorAvailable(String doctorId) async {
    final doc = await getDoctorById(doctorId);
    return doc?.isAvailable ?? false;
  }

  @override
  Future<String?> findAlternativeDoctor({
    required String domainId,
    String? excludeDoctorId,
  }) async {
    try {
      final doctors = await getDoctorsForDomain(domainId);
      for (final doc in doctors) {
        if (doc.doctorId != excludeDoctorId && doc.isAvailable) {
          return doc.doctorId;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[FirebaseDoctorRepository] Error finding alternative doctor: $e');
      return null;
    }
  }

  @override
  Future<bool> areAllDoctorsBusy(String domainId) async {
    try {
      final doctors = await getDoctorsForDomain(domainId);
      if (doctors.isEmpty) return false;
      return doctors.every((d) => !d.isAvailable);
    } catch (e) {
      debugPrint('[FirebaseDoctorRepository] Error checking doctor busy status: $e');
      return false;
    }
  }

  @override
  Future<void> saveDoctor(Doctor doctor) async {
    try {
      await _collection.doc(doctor.doctorId).set(
            doctor.toFirestore(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on saveDoctor: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not save doctor to Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<DoctorProfile>> watchDoctorProfiles() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorProfile.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<DoctorProfile>> getAllDoctorProfiles() async {
    try {
      final snapshot = await _collection.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => DoctorProfile.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on getAllDoctorProfiles: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not fetch doctor profiles from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<DoctorProfile?> getDoctorProfileById(String doctorId) async {
    try {
      final doc = await _collection.doc(doctorId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return DoctorProfile.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on getDoctorProfileById: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not fetch doctor profile.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateDoctorProfile({
    required String doctorId,
    String? name,
    String? qualification,
    String? department,
    String? registeredPhone,
    String? email,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };
      if (name != null) updateData['name'] = name.trim();
      if (qualification != null) updateData['qualification'] = qualification.trim();
      if (department != null) {
        updateData['department'] = department.trim();
        updateData['domains'] = [department.trim().toLowerCase()];
        updateData['specialization'] = department.trim();
      }
      if (registeredPhone != null) updateData['registeredPhone'] = registeredPhone.trim();
      if (email != null) updateData['email'] = email.trim();

      await _collection.doc(doctorId).update(updateData);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on updateDoctorProfile: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not update doctor profile in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setDoctorActiveStatus({
    required String doctorId,
    required bool isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      };
      if (!isActive) {
        updateData['availabilityStatus'] = DoctorAvailabilityStatus.offline.value;
        updateData['isAvailable'] = false;
      }
      await _collection.doc(doctorId).update(updateData);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on setDoctorActiveStatus: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not update doctor active status in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setDoctorAvailabilityStatus({
    required String doctorId,
    required DoctorAvailabilityStatus availabilityStatus,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'availabilityStatus': availabilityStatus.value,
        'isAvailable': availabilityStatus == DoctorAvailabilityStatus.available,
        'updatedAt': Timestamp.now(),
      };
      await _collection.doc(doctorId).update(updateData);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseDoctorRepository] FirebaseException on setDoctorAvailabilityStatus: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not update doctor availability status in Firestore.',
        originalError: e,
      );
    }
  }
}

