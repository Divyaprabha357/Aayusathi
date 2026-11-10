import 'dart:async';
import '../../doctor/models/doctor_profile.dart';
import '../../models/doctor.dart';
import '../doctor_repository.dart';

/// In-memory mock implementation of [DoctorRepository] managing doctors, profiles, and clinical domains.
class MockDoctorRepository implements DoctorRepository {
  static final MockDoctorRepository instance = MockDoctorRepository._();
  MockDoctorRepository._() {
    resetToDefaults();
  }
  factory MockDoctorRepository() => instance;

  final Map<String, Doctor> _doctors = {};
  final Map<String, DoctorProfile> _profiles = {};
  final Set<String> _domainsAllBusy = {'orthopedics'};
  StreamController<List<DoctorProfile>>? _profilesStreamController;

  StreamController<List<DoctorProfile>> get _streamController {
    if (_profilesStreamController == null || _profilesStreamController!.isClosed) {
      _profilesStreamController = StreamController<List<DoctorProfile>>.broadcast();
    }
    return _profilesStreamController!;
  }

  void _notifyProfilesChanged() {
    if (_streamController.hasListener) {
      _streamController.add(getAllDoctorProfilesSync());
    }
  }

  List<DoctorProfile> getAllDoctorProfilesSync() {
    final list = _profiles.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void resetToDefaults() {
    _doctors.clear();
    _profiles.clear();
    _domainsAllBusy
      ..clear()
      ..add('orthopedics');

    final list = [
      Doctor(
        doctorId: 'DOC-CARD-01',
        name: 'Dr. Ramesh Gupta',
        specialization: 'Cardiology',
        domains: const ['cardiology'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      Doctor(
        doctorId: 'DOC-CARD-02',
        name: 'Dr. Sunita Rao',
        specialization: 'Cardiology',
        domains: const ['cardiology'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      ),
      Doctor(
        doctorId: 'DOC-NEUR-01',
        name: 'Dr. Vikram Seth',
        specialization: 'Neurology',
        domains: const ['neurology'],
        isAvailable: false, // Specifically unavailable for Phase 8 test cases
        createdAt: DateTime(2026, 1, 3),
        updatedAt: DateTime(2026, 1, 3),
      ),
      Doctor(
        doctorId: 'DOC-NEUR-02',
        name: 'Dr. Ananya Roy',
        specialization: 'Neurology',
        domains: const ['neurology'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 4),
        updatedAt: DateTime(2026, 1, 4),
      ),
      Doctor(
        doctorId: 'DOC-ORTH-01',
        name: 'Dr. Manoj Joshi',
        specialization: 'Orthopedics',
        domains: const ['orthopedics'],
        isAvailable: false,
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 1, 5),
      ),
      Doctor(
        doctorId: 'DOC-PED-01',
        name: 'Dr. Meera Iyer',
        specialization: 'Pediatrics',
        domains: const ['pediatrics'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 6),
        updatedAt: DateTime(2026, 1, 6),
      ),
      Doctor(
        doctorId: 'DOC-ENT-01',
        name: 'Dr. Suresh Varma',
        specialization: 'ENT',
        domains: const ['ent'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 7),
        updatedAt: DateTime(2026, 1, 7),
      ),
      Doctor(
        doctorId: 'DOC-DERM-01',
        name: 'Dr. Kavita Nair',
        specialization: 'Dermatology',
        domains: const ['dermatology'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 8),
        updatedAt: DateTime(2026, 1, 8),
      ),
      Doctor(
        doctorId: 'DOC-GEN-01',
        name: 'Dr. Arvind Deshmukh',
        specialization: 'General Medicine',
        domains: const ['general_medicine'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 9),
        updatedAt: DateTime(2026, 1, 9),
      ),
      Doctor(
        doctorId: 'DOC-GAST-01',
        name: 'Dr. Priya Kulkarni',
        specialization: 'Gastroenterology',
        domains: const ['gastroenterology'],
        isAvailable: true,
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      ),
    ];

    for (int i = 0; i < list.length; i++) {
      final doc = list[i];
      _doctors[doc.doctorId] = doc;
      int authLevel = 1;
      if (doc.doctorId == 'DOC-CARD-02' || doc.doctorId == 'DOC-NEUR-02') {
        authLevel = 3;
      } else if (doc.doctorId == 'DOC-NEUR-01' ||
          doc.doctorId == 'DOC-ORTH-01' ||
          doc.doctorId == 'DOC-PED-01') {
        authLevel = 2;
      }

      _profiles[doc.doctorId] = DoctorProfile(
        doctorId: doc.doctorId,
        doctorUniqueCode: doc.doctorId,
        name: doc.name,
        qualification: authLevel >= 3
            ? 'MBBS, MD, DM (Chief Specialist)'
            : authLevel == 2
                ? 'MBBS, MD (Senior Consultant)'
                : 'MBBS (Resident / MO)',
        department: doc.domains.first,
        registeredPhone: '98765432${i.toString().padLeft(2, '0')}',
        email: '${doc.doctorId.toLowerCase()}@hospital.aayusathi.in',
        isActive: doc.isActive,
        availabilityStatus: doc.isAvailable
            ? DoctorAvailabilityStatus.available
            : DoctorAvailabilityStatus.offline,
        clinicalAuthorityLevel: authLevel,
        authUid: 'mock-uid-${doc.doctorId}',
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      );
    }
    _notifyProfilesChanged();
  }

  /// Registers or updates a test doctor profile
  void registerDoctorProfile(DoctorProfile profile) {
    _profiles[profile.doctorId] = profile;
    _doctors[profile.doctorId] = Doctor(
      doctorId: profile.doctorId,
      name: profile.name,
      specialization: profile.department,
      domains: [profile.department],
      isAvailable: profile.availabilityStatus == DoctorAvailabilityStatus.available,
      isActive: profile.isActive,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
    _notifyProfilesChanged();
  }

  @override
  Future<Doctor?> getDoctorById(String doctorId) async {
    return _doctors[doctorId];
  }

  @override
  Future<List<Doctor>> getDoctorsForDomain(String domainId) async {
    return _doctors.values
        .where((d) => d.domains.any((dom) => dom.toLowerCase() == domainId.toLowerCase()))
        .toList();
  }

  @override
  Future<bool> isDoctorAvailable(String doctorId) async {
    final doc = _doctors[doctorId];
    return doc?.isAvailable ?? false;
  }

  @override
  Future<String?> findAlternativeDoctor({
    required String domainId,
    String? excludeDoctorId,
  }) async {
    if (_domainsAllBusy.contains(domainId.toLowerCase())) {
      return null;
    }
    final doctors = await getDoctorsForDomain(domainId);
    for (final doc in doctors) {
      if (doc.doctorId != excludeDoctorId && doc.isAvailable) {
        return doc.doctorId;
      }
    }
    return null;
  }

  @override
  Future<bool> areAllDoctorsBusy(String domainId) async {
    if (_domainsAllBusy.contains(domainId.toLowerCase())) {
      return true;
    }
    final doctors = await getDoctorsForDomain(domainId);
    if (doctors.isEmpty) return false;
    return doctors.every((d) => !d.isAvailable);
  }

  @override
  Future<void> saveDoctor(Doctor doctor) async {
    _doctors[doctor.doctorId] = doctor;
    if (_profiles.containsKey(doctor.doctorId)) {
      final existing = _profiles[doctor.doctorId]!;
      _profiles[doctor.doctorId] = existing.copyWith(
        name: doctor.name,
        department: doctor.domains.isNotEmpty ? doctor.domains.first : existing.department,
        isActive: doctor.isActive,
        availabilityStatus: doctor.isAvailable
            ? DoctorAvailabilityStatus.available
            : DoctorAvailabilityStatus.offline,
        updatedAt: doctor.updatedAt,
      );
    }
    _notifyProfilesChanged();
  }

  void saveDoctorProfile(DoctorProfile profile) {
    _profiles[profile.doctorId] = profile;
    _doctors[profile.doctorId] = Doctor(
      doctorId: profile.doctorId,
      name: profile.name,
      specialization: profile.department,
      domains: [profile.department.toLowerCase()],
      isActive: profile.isActive,
      isAvailable: profile.availabilityStatus == DoctorAvailabilityStatus.available,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
    _notifyProfilesChanged();
  }

  @override
  Stream<List<DoctorProfile>> watchDoctorProfiles() {
    return Stream.multi((controller) {
      controller.add(getAllDoctorProfilesSync());
      final subscription = _streamController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  @override
  Future<List<DoctorProfile>> getAllDoctorProfiles() async {
    return getAllDoctorProfilesSync();
  }

  @override
  Future<DoctorProfile?> getDoctorProfileById(String doctorId) async {
    return _profiles[doctorId];
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
    final existing = _profiles[doctorId];
    if (existing == null) return;

    final updated = existing.copyWith(
      name: name?.trim() ?? existing.name,
      qualification: qualification?.trim() ?? existing.qualification,
      department: department?.trim() ?? existing.department,
      registeredPhone: registeredPhone?.trim() ?? existing.registeredPhone,
      email: email?.trim() ?? existing.email,
      updatedAt: DateTime.now(),
    );
    _profiles[doctorId] = updated;

    if (_doctors.containsKey(doctorId)) {
      final doc = _doctors[doctorId]!;
      _doctors[doctorId] = doc.copyWith(
        name: updated.name,
        specialization: updated.department,
        domains: [updated.department.toLowerCase()],
        updatedAt: updated.updatedAt,
      );
    }
    _notifyProfilesChanged();
  }

  @override
  Future<void> setDoctorActiveStatus({
    required String doctorId,
    required bool isActive,
  }) async {
    final existing = _profiles[doctorId];
    if (existing == null) return;

    final updated = existing.copyWith(
      isActive: isActive,
      availabilityStatus: !isActive ? DoctorAvailabilityStatus.offline : existing.availabilityStatus,
      updatedAt: DateTime.now(),
    );
    _profiles[doctorId] = updated;

    if (_doctors.containsKey(doctorId)) {
      final doc = _doctors[doctorId]!;
      _doctors[doctorId] = doc.copyWith(
        isActive: isActive,
        isAvailable: isActive ? doc.isAvailable : false,
        updatedAt: updated.updatedAt,
      );
    }
    _notifyProfilesChanged();
  }

  void setDoctorAvailability(String doctorId, bool isAvailable) {
    final doc = _doctors[doctorId];
    if (doc != null) {
      _doctors[doctorId] = doc.copyWith(isAvailable: isAvailable);
    }
    final prof = _profiles[doctorId];
    if (prof != null) {
      _profiles[doctorId] = prof.copyWith(
        availabilityStatus: isAvailable ? DoctorAvailabilityStatus.available : DoctorAvailabilityStatus.offline,
      );
    }
    _notifyProfilesChanged();
  }

  @override
  Future<void> setDoctorAvailabilityStatus({
    required String doctorId,
    required DoctorAvailabilityStatus availabilityStatus,
  }) async {
    final prof = _profiles[doctorId];
    if (prof != null) {
      _profiles[doctorId] = prof.copyWith(
        availabilityStatus: availabilityStatus,
        updatedAt: DateTime.now(),
      );
    }
    final doc = _doctors[doctorId];
    if (doc != null) {
      _doctors[doctorId] = doc.copyWith(
        isAvailable: availabilityStatus == DoctorAvailabilityStatus.available,
        updatedAt: DateTime.now(),
      );
    }
    _notifyProfilesChanged();
  }

  /// Synchronous helper for test setup
  void setDoctorAvailabilityStatusSync(String doctorId, DoctorAvailabilityStatus status) {
    setDoctorAvailabilityStatus(
      doctorId: doctorId,
      availabilityStatus: status,
    );
  }

  void setDomainAllBusy(String domainId, bool isBusy) {
    if (isBusy) {
      _domainsAllBusy.add(domainId.toLowerCase());
    } else {
      _domainsAllBusy.remove(domainId.toLowerCase());
    }
  }
}

