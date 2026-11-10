import '../models/doctor_provisioning_request.dart';
import '../models/doctor_provisioning_result.dart';

/// Abstract service contract for Admin-initiated Doctor account provisioning.
abstract class DoctorProvisioningService {
  /// Provisions a new Doctor account by generating unique ID, password, Auth user, and Firestore profile.
  Future<DoctorProvisioningResult> provisionDoctor(DoctorProvisioningRequest request);

  /// Checks if a doctor already exists with the given phone, email, or unique code.
  Future<bool> checkDoctorExists({
    required String phone,
    String? email,
    String? doctorUniqueCode,
  });
}
