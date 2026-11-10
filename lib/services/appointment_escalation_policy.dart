import '../models/appointment_request.dart';

/// Centralized clinical policy for appointment response SLAs and escalation thresholds.
///
/// Business Rule (Phase A7):
/// An appointment/consultation request is escalated when it remains in the `WAITING` or `PENDING`
/// status for **20 minutes** or more without being accepted/assigned to an attending physician.
///
/// Calculation MUST strictly be evaluated from the appointment's server-persisted creation timestamp
/// (`createdAt` / `requestedAt`).
class AppointmentEscalationPolicy {
  AppointmentEscalationPolicy._();

  /// The exact waiting threshold after which an unassigned appointment enters ESCALATED status.
  static const Duration waitingThreshold = Duration(minutes: 20);

  /// Calculates the elapsed waiting duration from [createdAt] relative to [now].
  static Duration calculateWaitDuration(DateTime createdAt, [DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(createdAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Evaluates whether an appointment has crossed the 20-minute escalation threshold.
  ///
  /// Criteria:
  /// 1. Appointment status must be `waiting` or `pending`.
  /// 2. `assignedDoctorId` must be null or empty.
  /// 3. Elapsed duration from `createdAt` must be greater than or equal to [waitingThreshold].
  static bool shouldEscalate(AppointmentRequest appointment, [DateTime? now]) {
    // Already assigned, completed, or cancelled requests never escalate
    if (appointment.status != AppointmentStatus.waiting &&
        appointment.status != AppointmentStatus.pending) {
      return false;
    }

    if (appointment.assignedDoctorId != null &&
        appointment.assignedDoctorId!.isNotEmpty) {
      return false;
    }

    final duration = calculateWaitDuration(appointment.createdAt, now);
    return duration >= waitingThreshold;
  }

  /// Formats duration into human-readable representation:
  /// - Under 60 min: "04 min", "18 min", "20 min"
  /// - Over 60 min: "1 hr 04 min", "2 hr 15 min"
  static String formatWaitDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes < 60) {
      return '${totalMinutes.toString().padLeft(2, '0')} min';
    }
    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    return '$hours hr ${remainingMinutes.toString().padLeft(2, '0')} min';
  }
}
