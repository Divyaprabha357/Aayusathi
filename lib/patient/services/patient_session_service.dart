import 'package:flutter/foundation.dart';
import '../models/patient_app_state.dart';
import '../models/patient_session.dart';
import 'patient_notification_service.dart';

/// Central service managing the active Patient App authenticated session.
/// 
/// Privacy & Security Guardrails:
/// - Session lifecycle is completely isolated from Doctor, Admin, and Kiosk modules.
/// - Logging out clears all patient identity and cached patient app state.
class PatientSessionService extends ChangeNotifier {
  static final PatientSessionService instance = PatientSessionService._internal();
  PatientSessionService._internal();

  PatientSession _currentSession = PatientSession.loggedOut();

  PatientSession get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession.isAuthenticated;
  String? get authenticatedPatientId => _currentSession.patientId;

  /// Creates and activates an authenticated patient session.
  void startSession(String patientId, {String? authUid}) {
    _currentSession = PatientSession.authenticated(
      patientId: patientId,
      authUid: authUid,
      authenticatedAt: DateTime.now(),
    );

    // Sync with UI-level PatientAppState
    PatientAppState.instance.setPatientId(patientId);

    notifyListeners();
  }

  /// Sets the session to an intermediate state (e.g. ID entered, OTP pending).
  void setSession(PatientSession session) {
    _currentSession = session;
    notifyListeners();
  }

  /// Clears the patient session, resets the patient app state, and notifies listeners.
  /// 
  /// NOTE: This does NOT affect Doctor, Admin, or Kiosk auth sessions.
  void logout() {
    final pid = _currentSession.patientId;
    if (pid != null && pid.isNotEmpty) {
      PatientNotificationService.instance.clearPatientSession(pid);
    }
    _currentSession = PatientSession.loggedOut();
    PatientAppState.instance.resetSession();
    notifyListeners();
  }
}
