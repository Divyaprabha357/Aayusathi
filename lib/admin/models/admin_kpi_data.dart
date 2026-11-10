import 'package:flutter/foundation.dart';

/// Lightweight presentation model for System Overview metrics.
/// Cleanly isolated from backend data sources in Phase A1.
@immutable
class AdminKpiData {
  final int totalDoctors;
  final int availableDoctors;
  final int pendingAppointments;
  final int activeEscalations;

  const AdminKpiData({
    this.totalDoctors = 24,
    this.availableDoctors = 18,
    this.pendingAppointments = 5,
    this.activeEscalations = 0,
  });
}
