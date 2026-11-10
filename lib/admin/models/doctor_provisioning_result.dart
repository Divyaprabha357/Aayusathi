import '../../doctor/models/doctor_profile.dart';

/// Result envelope returned upon attempting Doctor account provisioning.
class DoctorProvisioningResult {
  final bool isSuccess;
  final DoctorProfile? doctorProfile;
  final String? temporaryPassword;
  final String? errorMessage;

  const DoctorProvisioningResult._({
    required this.isSuccess,
    this.doctorProfile,
    this.temporaryPassword,
    this.errorMessage,
  });

  factory DoctorProvisioningResult.success({
    required DoctorProfile doctorProfile,
    required String temporaryPassword,
  }) {
    return DoctorProvisioningResult._(
      isSuccess: true,
      doctorProfile: doctorProfile,
      temporaryPassword: temporaryPassword,
    );
  }

  factory DoctorProvisioningResult.failure(String errorMessage) {
    return DoctorProvisioningResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
