import 'dart:async';
import '../models/doctor_profile.dart';

/// Contract for fetching and observing physician profile information.
///
/// In Phase D4, this is implemented by [MockDoctorProfileService] for development.
/// In later phases, this will bridge to Firebase Doctor Profile repositories.
abstract class DoctorProfileService {
  /// Global profile service singleton.
  static DoctorProfileService instance = MockDoctorProfileService();

  /// Retrieves the active doctor profile.
  Future<DoctorProfile> getDoctorProfile({String? doctorId});

  /// Streams real-time doctor profile updates.
  Stream<DoctorProfile> watchDoctorProfile({String? doctorId});
}

/// Development-only mock implementation of [DoctorProfileService] for Phase D4.
///
/// Strictly isolated from Cloud Firestore and Firebase Auth.
class MockDoctorProfileService implements DoctorProfileService {
  static final DoctorProfile demoDoctor = DoctorProfile(
    doctorId: 'DOC-101',
    doctorUniqueCode: 'DOC-101',
    name: 'Dr. Rajesh Sharma',
    qualification: 'MBBS, MD (Cardiology)',
    department: 'Cardiology',
    registeredPhone: '+91******3210',
    email: 'doc-101@hospital.aayusathi.in',
    isActive: true,
    availabilityStatus: DoctorAvailabilityStatus.available,
    authUid: 'mock-dev-uid-doc-101',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  DoctorProfile _profile = demoDoctor;
  final StreamController<DoctorProfile> _controller =
      StreamController<DoctorProfile>.broadcast();

  MockDoctorProfileService({DoctorProfile? initialProfile}) {
    if (initialProfile != null) {
      _profile = initialProfile;
    }
  }

  @override
  Future<DoctorProfile> getDoctorProfile({String? doctorId}) async {
    return _profile;
  }

  @override
  Stream<DoctorProfile> watchDoctorProfile({String? doctorId}) {
    return _controller.stream;
  }

  /// Helper to simulate administrative updates during tests.
  void updateMockProfile(DoctorProfile updated) {
    _profile = updated;
    _controller.add(updated);
  }
}
