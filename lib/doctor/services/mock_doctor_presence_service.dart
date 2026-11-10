import 'package:flutter/foundation.dart';
import '../models/doctor_profile.dart';
import 'doctor_presence_service.dart';

/// Local mock implementation of [DoctorPresenceService] for Phase D4 development and testing.
///
/// Ensures strict state machine transitions:
/// - OFFLINE -> ONLINE -> AVAILABLE
/// - AVAILABLE <-> IN CONSULTATION
/// - AVAILABLE / ONLINE -> OFFLINE
/// - OFFLINE -> IN CONSULTATION is rejected with [StateError]
class MockDoctorPresenceService extends ChangeNotifier
    implements DoctorPresenceService {
  DoctorAvailabilityStatus _status;

  MockDoctorPresenceService({
    DoctorAvailabilityStatus initialStatus = DoctorAvailabilityStatus.available,
  }) : _status = initialStatus;

  @override
  DoctorAvailabilityStatus get status => _status;

  @override
  bool get isOnline => _status != DoctorAvailabilityStatus.offline;

  @override
  bool get isAvailable => _status == DoctorAvailabilityStatus.available;

  @override
  bool get isInConsultation => _status == DoctorAvailabilityStatus.inConsultation;

  @override
  bool get isOffline => _status == DoctorAvailabilityStatus.offline;

  @override
  Future<void> goOnline() async {
    if (_status == DoctorAvailabilityStatus.online) return;
    _status = DoctorAvailabilityStatus.online;
    notifyListeners();
  }

  @override
  Future<void> goOffline() async {
    if (_status == DoctorAvailabilityStatus.offline) return;
    _status = DoctorAvailabilityStatus.offline;
    notifyListeners();
  }

  @override
  Future<void> setAvailable() async {
    if (_status == DoctorAvailabilityStatus.available) return;
    _status = DoctorAvailabilityStatus.available;
    notifyListeners();
  }

  @override
  Future<void> setInConsultation() async {
    if (_status == DoctorAvailabilityStatus.offline) {
      throw StateError(
        'Cannot transition to inConsultation from offline. Workstation must be online or available first.',
      );
    }
    if (_status == DoctorAvailabilityStatus.inConsultation) return;
    _status = DoctorAvailabilityStatus.inConsultation;
    notifyListeners();
  }

  @override
  Future<void> resetPresence() async {
    _status = DoctorAvailabilityStatus.offline;
    notifyListeners();
  }
}
