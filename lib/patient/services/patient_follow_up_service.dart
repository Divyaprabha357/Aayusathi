import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../models/appointment_request.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/case_repository.dart';
import '../../repositories/clinical_visit_repository.dart';
import '../models/patient_calendar_item.dart';
import 'patient_session_service.dart';

/// Central domain service aggregating doctor-recorded clinical follow-up dates
/// and active consultation appointments for the authenticated patient.
///
/// Principles:
/// - Strictly relies on canonical Firestore models ([ClinicalVisit], [ClinicalCase], [AppointmentRequest]).
/// - Enforces authenticated patient ownership: Patient A can never access Patient B's follow-up dates.
/// - Parses qualitative & structured doctor follow-ups safely without crashing.
class PatientFollowUpService {
  final CaseRepository _caseRepo;
  final ClinicalVisitRepository _visitRepo;
  final AppointmentRepository _appointmentRepo;
  final PatientSessionService _sessionService;

  PatientFollowUpService({
    CaseRepository? caseRepo,
    ClinicalVisitRepository? visitRepo,
    AppointmentRepository? appointmentRepo,
    PatientSessionService? sessionService,
  })  : _caseRepo = caseRepo ?? BackendProvider.instance.caseRepository,
        _visitRepo = visitRepo ?? BackendProvider.instance.clinicalVisitRepository,
        _appointmentRepo = appointmentRepo ?? BackendProvider.instance.appointmentRepository,
        _sessionService = sessionService ?? PatientSessionService.instance;

  /// Retrieves all scheduled follow-ups and active appointments for the patient.
  ///
  /// Strictly verifies that [patientId] matches the active authenticated session.
  Future<List<PatientCalendarItem>> getFollowUpsAndAppointmentsForPatient({
    String? patientId,
  }) async {
    final authenticatedId = _sessionService.authenticatedPatientId;
    if (authenticatedId == null || authenticatedId.isEmpty) {
      debugPrint('[PatientFollowUpService] Rejected: No active authenticated patient session.');
      return [];
    }

    final targetId = patientId ?? authenticatedId;
    if (targetId != authenticatedId) {
      debugPrint('[PatientFollowUpService] Security violation: Attempted to query follow-ups for $targetId under session $authenticatedId.');
      return [];
    }

    final List<PatientCalendarItem> results = [];
    final Set<String> linkedAppointmentIds = {};

    // 1. Query Patient's Clinical Cases
    try {
      final cases = await _caseRepo.getCasesForPatient(targetId);

      // 2. Query Visits under each Case
      for (final clinicalCase in cases) {
        try {
          final visits = await _visitRepo.getVisitsForCase(
            patientId: targetId,
            caseId: clinicalCase.caseId,
          );

          for (final visit in visits) {
            if (visit.appointmentId != null) {
              linkedAppointmentIds.add(visit.appointmentId!);
            }

            final parsedDate = visit.followUpDate;
            if (parsedDate != null) {
              results.add(PatientCalendarItem(
                id: 'followup_${clinicalCase.caseId}_${visit.visitId}',
                date: parsedDate,
                title: 'Follow-up Visit',
                department: clinicalCase.domain,
                doctorName: visit.doctorName,
                type: PatientCalendarEventType.followUp,
                caseId: clinicalCase.caseId,
                visitId: visit.visitId,
                visitNumber: visit.visitNumber,
                caseTitle: clinicalCase.title,
                rawFollowUpText: visit.followUp,
              ));
            }
          }
        } catch (e) {
          debugPrint('[PatientFollowUpService] Warning: Could not fetch visits for case ${clinicalCase.caseId}: $e');
        }
      }
    } catch (e) {
      debugPrint('[PatientFollowUpService] Warning: Could not fetch cases for patient $targetId: $e');
    }

    // 3. Query Active Appointments (Kiosk / Doctor Queue)
    try {
      final appointments = await _appointmentRepo.getAppointmentsForPatient(targetId);
      final activeAppointments = appointments.where((a) =>
          a.status == AppointmentStatus.waiting ||
          a.status == AppointmentStatus.accepted ||
          a.status == AppointmentStatus.pending);

      for (final apt in activeAppointments) {
        // Prevent duplicate cards if an appointment is already linked to a recorded visit follow-up
        if (linkedAppointmentIds.contains(apt.requestId)) {
          continue;
        }

        final aptDate = DateTime(apt.createdAt.year, apt.createdAt.month, apt.createdAt.day);

        // Check if there's already a follow-up for the same day and department
        final alreadyHasSameEvent = results.any((item) =>
            item.isSameDay(aptDate) &&
            item.department?.toLowerCase() == apt.domainId.toLowerCase());

        if (!alreadyHasSameEvent) {
          results.add(PatientCalendarItem(
            id: 'appointment_${apt.requestId}',
            date: aptDate,
            title: 'OPD Consultation',
            department: apt.domainId,
            type: PatientCalendarEventType.visit,
          ));
        }
      }
    } catch (e) {
      debugPrint('[PatientFollowUpService] Warning: Could not fetch appointments for patient $targetId: $e');
    }

    // Sort all events chronologically
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  /// Identifies the nearest upcoming scheduled visit or follow-up.
  ///
  /// Returns `null` if no future follow-ups or appointments exist.
  Future<PatientCalendarItem?> getNearestUpcomingVisit({String? patientId}) async {
    final allEvents = await getFollowUpsAndAppointmentsForPatient(patientId: patientId);
    final upcomingEvents = allEvents.where((e) => e.isUpcoming).toList();

    if (upcomingEvents.isEmpty) return null;

    upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
    return upcomingEvents.first;
  }
}
