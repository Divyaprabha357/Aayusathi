import 'package:flutter/foundation.dart';

/// Extension point contract for patient consultation notifications.
///
/// In future phases, this service connects to Firebase Cloud Messaging (FCM)
/// to notify the patient's mobile device that a physician has accepted their OPD request.
abstract class PatientNotificationService {
  static PatientNotificationService instance = MockPatientNotificationService();

  /// Dispatches a notification to the patient that their consultation has been accepted.
  Future<void> notifyPatientConsultationAccepted({
    required String appointmentId,
    required String patientId,
    required String queueNumber,
    required String doctorId,
  });
}

/// In-memory development fixture for [PatientNotificationService].
class MockPatientNotificationService implements PatientNotificationService {
  final List<Map<String, String>> dispatchedNotifications = [];

  @override
  Future<void> notifyPatientConsultationAccepted({
    required String appointmentId,
    required String patientId,
    required String queueNumber,
    required String doctorId,
  }) async {
    dispatchedNotifications.add({
      'appointmentId': appointmentId,
      'patientId': patientId,
      'queueNumber': queueNumber,
      'doctorId': doctorId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint('[PatientNotificationService] Consultation accepted for queue $queueNumber by doctor $doctorId');
  }

  void clear() {
    dispatchedNotifications.clear();
  }
}
