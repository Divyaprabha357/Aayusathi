import 'admin_domain_availability.dart';
import 'admin_waiting_appointment_summary.dart';

/// Aggregated, real-time system overview model for the AAYUSATHI Admin Dashboard.
///
/// Encapsulates all clinical telemetry across:
/// 1. Registered Doctor Profiles (active only)
/// 2. Online/Available Clinicians (presence-backed)
/// 3. Waiting OPD Appointments (FIFO queue-backed)
/// 4. Escalated Appointments (waiting > 20 min without doctor)
/// 5. Escalated Clinical Cases (doctor-escalated & under review)
/// 6. Active Clinical Cases (open episodes of care)
/// 7. 8-Domain Availability Distribution
/// 8. Waiting Appointment Summaries (privacy-safe)
/// 9. Case Distribution by Clinical Domain
class AdminDashboardOverview {
  final int registeredDoctors;
  final int onlineDoctors;
  final int waitingAppointments;
  final int escalatedAppointments;
  final int escalatedCases;
  final int activeCases;
  final List<AdminDomainAvailability> domainAvailability;
  final List<AdminWaitingAppointmentSummary> waitingAppointmentsList;
  final Map<String, int> activeCasesByDomain;
  final DateTime lastUpdated;

  const AdminDashboardOverview({
    required this.registeredDoctors,
    required this.onlineDoctors,
    required this.waitingAppointments,
    this.escalatedAppointments = 0,
    this.escalatedCases = 0,
    required this.activeCases,
    required this.domainAvailability,
    required this.waitingAppointmentsList,
    required this.activeCasesByDomain,
    required this.lastUpdated,
  });

  /// Factory creating an empty (zero-valued) overview.
  factory AdminDashboardOverview.empty() {
    return AdminDashboardOverview(
      registeredDoctors: 0,
      onlineDoctors: 0,
      waitingAppointments: 0,
      escalatedAppointments: 0,
      escalatedCases: 0,
      activeCases: 0,
      domainAvailability: AdminDomainAvailability.defaultEmptyList(),
      waitingAppointmentsList: const [],
      activeCasesByDomain: const {},
      lastUpdated: DateTime.now(),
    );
  }

  AdminDashboardOverview copyWith({
    int? registeredDoctors,
    int? onlineDoctors,
    int? waitingAppointments,
    int? escalatedAppointments,
    int? escalatedCases,
    int? activeCases,
    List<AdminDomainAvailability>? domainAvailability,
    List<AdminWaitingAppointmentSummary>? waitingAppointmentsList,
    Map<String, int>? activeCasesByDomain,
    DateTime? lastUpdated,
  }) {
    return AdminDashboardOverview(
      registeredDoctors: registeredDoctors ?? this.registeredDoctors,
      onlineDoctors: onlineDoctors ?? this.onlineDoctors,
      waitingAppointments: waitingAppointments ?? this.waitingAppointments,
      escalatedAppointments: escalatedAppointments ?? this.escalatedAppointments,
      escalatedCases: escalatedCases ?? this.escalatedCases,
      activeCases: activeCases ?? this.activeCases,
      domainAvailability: domainAvailability ?? this.domainAvailability,
      waitingAppointmentsList:
          waitingAppointmentsList ?? this.waitingAppointmentsList,
      activeCasesByDomain: activeCasesByDomain ?? this.activeCasesByDomain,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'AdminDashboardOverview(doctors: $registeredDoctors, online: $onlineDoctors, waiting: $waitingAppointments, escalatedAppts: $escalatedAppointments, escalatedCases: $escalatedCases, cases: $activeCases)';
  }
}
