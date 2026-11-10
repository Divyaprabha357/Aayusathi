import 'package:flutter/foundation.dart';
import '../models/doctor_profile.dart';
import 'mock_doctor_presence_service.dart';

/// Contract for physician availability and presence management on the workstation.
///
/// In Phase D4, this is powered by [MockDoctorPresenceService] for UI and flow development.
/// In subsequent phases, this will be swapped for [FirebaseDoctorPresenceService]
/// without altering Doctor UI widgets.
abstract class DoctorPresenceService extends ChangeNotifier {
  /// Global presence service singleton.
  static DoctorPresenceService instance = MockDoctorPresenceService();

  /// Current presence and clinical availability status.
  DoctorAvailabilityStatus get status;

  /// Whether the workstation is connected/authenticated.
  bool get isOnline;

  /// Whether the physician is actively ready to accept incoming OPD patients.
  bool get isAvailable;

  /// Whether the physician is currently occupied with a patient consultation.
  bool get isInConsultation;

  /// Whether the physician is offline / workstation is disconnected.
  bool get isOffline;

  /// Sets workstation connection status to online (not yet ready for patients).
  Future<void> goOnline();

  /// Sets workstation to offline.
  Future<void> goOffline();

  /// Sets physician availability to AVAILABLE (ready for patients).
  Future<void> setAvailable();

  /// Sets physician status to IN CONSULTATION (system-controlled during active consult).
  Future<void> setInConsultation();

  /// Resets presence state upon logout or session clearance.
  Future<void> resetPresence();
}
