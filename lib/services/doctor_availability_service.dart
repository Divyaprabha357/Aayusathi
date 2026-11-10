/// Abstract service contract managing doctor availability and allocation logic.
abstract class DoctorAvailabilityService {
  /// Checks whether a specific doctor is currently available for consultations.
  Future<bool> isDoctorAvailable(String doctorId);

  /// Finds an alternative eligible doctor for a given medical domain.
  Future<String?> findAlternativeDoctor({
    required String domainId,
    String? excludeDoctorId,
  });

  /// Checks whether all eligible doctors for a given medical domain are currently busy.
  Future<bool> areAllDoctorsBusy(String domainId);
}

/// Deterministic mock implementation of [DoctorAvailabilityService] for development and testing.
class MockDoctorAvailabilityService implements DoctorAvailabilityService {
  // Mapping of doctorId -> isAvailable
  final Map<String, bool> _doctorAvailability = {
    'DOC-CARD-01': true,
    'DOC-CARD-02': true,
    'DOC-NEUR-01': false, // Specifically unavailable for testing Part 7
    'DOC-NEUR-02': true,
    'DOC-ORTH-01': false,
    'DOC-PED-01': true,
    'DOC-ENT-01': true,
    'DOC-DERM-01': true,
    'DOC-GEN-01': true,
  };

  // Mapping of domainId -> list of doctor IDs
  final Map<String, List<String>> _domainDoctors = {
    'cardiology': ['DOC-CARD-01', 'DOC-CARD-02'],
    'neurology': ['DOC-NEUR-01', 'DOC-NEUR-02'],
    'orthopedics': ['DOC-ORTH-01'],
    'pediatrics': ['DOC-PED-01'],
    'ent': ['DOC-ENT-01'],
    'dermatology': ['DOC-DERM-01'],
    'general_medicine': ['DOC-GEN-01'],
    'gastroenterology': ['DOC-GAST-01'],
  };

  // Explicit override to simulate all doctors busy in a domain (Part 9)
  final Set<String> _domainsAllBusy = {'orthopedics'};

  @override
  Future<bool> isDoctorAvailable(String doctorId) async {
    return _doctorAvailability[doctorId] ?? true;
  }

  @override
  Future<String?> findAlternativeDoctor({
    required String domainId,
    String? excludeDoctorId,
  }) async {
    if (_domainsAllBusy.contains(domainId)) {
      return null;
    }

    final doctors = _domainDoctors[domainId] ?? ['DOC-${domainId.toUpperCase()}-ALT'];
    for (final doc in doctors) {
      if (doc != excludeDoctorId && (_doctorAvailability[doc] ?? true)) {
        return doc;
      }
    }
    return null;
  }

  @override
  Future<bool> areAllDoctorsBusy(String domainId) async {
    if (_domainsAllBusy.contains(domainId)) {
      return true;
    }
    final doctors = _domainDoctors[domainId] ?? [];
    if (doctors.isEmpty) return false;
    return doctors.every((doc) => _doctorAvailability[doc] == false);
  }

  // --- Test Helpers ---

  /// Overrides availability of a specific doctor.
  void setDoctorAvailability(String doctorId, bool isAvailable) {
    _doctorAvailability[doctorId] = isAvailable;
  }

  /// Sets all doctors busy status for a domain.
  void setDomainAllBusy(String domainId, bool isBusy) {
    if (isBusy) {
      _domainsAllBusy.add(domainId);
    } else {
      _domainsAllBusy.remove(domainId);
    }
  }

  /// Resets test overrides back to initial defaults.
  void reset() {
    _doctorAvailability
      ..clear()
      ..addAll({
        'DOC-CARD-01': true,
        'DOC-CARD-02': true,
        'DOC-NEUR-01': false,
        'DOC-NEUR-02': true,
        'DOC-ORTH-01': false,
        'DOC-PED-01': true,
        'DOC-ENT-01': true,
        'DOC-DERM-01': true,
        'DOC-GEN-01': true,
      });
    _domainsAllBusy
      ..clear()
      ..add('orthopedics');
  }
}
