import '../doctor/models/doctor_profile.dart';
import '../models/doctor.dart';

/// Abstract contract for doctor availability, physician management, and clinical department allocation.
abstract class DoctorRepository {
  /// Retrieves a doctor record by [doctorId].
  Future<Doctor?> getDoctorById(String doctorId);

  /// Retrieves all doctors belonging to a clinical domain.
  Future<List<Doctor>> getDoctorsForDomain(String domainId);

  /// Checks if a doctor is currently available for consultation.
  Future<bool> isDoctorAvailable(String doctorId);

  /// Finds an available alternative doctor for the specified domain.
  Future<String?> findAlternativeDoctor({
    required String domainId,
    String? excludeDoctorId,
  });

  /// Checks if all doctors in the domain are currently busy.
  Future<bool> areAllDoctorsBusy(String domainId);

  /// Persists or updates doctor record.
  Future<void> saveDoctor(Doctor doctor);

  /// Real-time stream of all registered physician profiles.
  Stream<List<DoctorProfile>> watchDoctorProfiles();

  /// Retrieves all doctor profiles ordered by creation date.
  Future<List<DoctorProfile>> getAllDoctorProfiles();

  /// Retrieves full doctor profile by [doctorId].
  Future<DoctorProfile?> getDoctorProfileById(String doctorId);

  /// Updates editable doctor profile attributes.
  Future<void> updateDoctorProfile({
    required String doctorId,
    String? name,
    String? qualification,
    String? department,
    String? registeredPhone,
    String? email,
  });

  /// Updates active status of a doctor (active/inactive).
  Future<void> setDoctorActiveStatus({
    required String doctorId,
    required bool isActive,
  });

  /// Updates clinical availability status of a doctor (offline, available, inConsultation).
  Future<void> setDoctorAvailabilityStatus({
    required String doctorId,
    required DoctorAvailabilityStatus availabilityStatus,
  });
}

