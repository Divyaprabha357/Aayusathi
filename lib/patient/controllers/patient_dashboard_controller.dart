import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../models/appointment_request.dart';
import '../../models/patient.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/case_repository.dart';
import '../../repositories/clinical_visit_repository.dart';
import '../../repositories/patient_repository.dart';
import '../localization/patient_strings.dart';
import '../models/patient_app_state.dart';
import '../models/patient_calendar_item.dart';
import '../services/patient_follow_up_service.dart';
import '../services/patient_session_service.dart';

/// Controller managing Patient Dashboard statistics, greeting, and next visit preview.
class PatientDashboardController extends ChangeNotifier {
  final PatientRepository _patientRepo;
  final AppointmentRepository _appointmentRepo;
  final CaseRepository _caseRepo;
  final PatientSessionService _sessionService;
  final PatientFollowUpService _followUpService;
  final String? _explicitPatientId;

  PatientDashboardController({
    PatientRepository? patientRepo,
    AppointmentRepository? appointmentRepo,
    CaseRepository? caseRepo,
    ClinicalVisitRepository? visitRepo,
    PatientSessionService? sessionService,
    PatientFollowUpService? followUpService,
    String? patientId,
  })  : _patientRepo = patientRepo ?? BackendProvider.instance.patientRepository,
        _appointmentRepo = appointmentRepo ?? BackendProvider.instance.appointmentRepository,
        _caseRepo = caseRepo ?? BackendProvider.instance.caseRepository,
        _sessionService = sessionService ?? PatientSessionService.instance,
        _followUpService = followUpService ??
            PatientFollowUpService(
              caseRepo: caseRepo,
              visitRepo: visitRepo,
              appointmentRepo: appointmentRepo,
              sessionService: sessionService,
            ),
        _explicitPatientId = patientId;

  bool _isLoading = false;
  String? _profileError;
  String? _casesError;
  String? _appointmentsError;
  Patient? _patient;
  int _ongoingCasesCount = 0;
  AppointmentRequest? _nextVisit;
  PatientCalendarItem? _nearestUpcomingVisit;

  bool get isLoading => _isLoading;
  bool get hasError => _patient == null && _profileError != null;
  String? get errorMessage => _profileError;

  bool get hasAppointmentsError => _appointmentsError != null;
  String? get appointmentsErrorMessage => _appointmentsError;

  bool get hasCasesError => _casesError != null;
  String? get casesErrorMessage => _casesError;

  Patient? get patient => _patient ?? PatientAppState.instance.currentPatient;
  int get ongoingCasesCount => _ongoingCasesCount;
  AppointmentRequest? get nextVisit => _nextVisit;
  PatientCalendarItem? get nearestUpcomingVisit => _nearestUpcomingVisit;
  bool get hasUpcomingVisit => _nearestUpcomingVisit != null || _nextVisit != null;

  String get activePatientId =>
      _explicitPatientId ??
      _sessionService.authenticatedPatientId ??
      PatientAppState.instance.authenticatedPatientId ??
      '';

  String get patientDisplayName {
    final current = patient;
    if (current != null && current.name.trim().isNotEmpty) {
      return current.name.trim();
    }
    return 'Patient';
  }

  String get patientIdDisplay => activePatientId.isNotEmpty ? activePatientId : '—';
  String get bloodGroupDisplay => _patient?.bloodGroup ?? '—';
  String get ageGenderDisplay {
    final p = _patient;
    if (p == null) return '—';
    final ageStr = p.age > 0 ? '${p.age} yrs' : '';
    final genderStr = p.gender.trim();
    if (ageStr.isNotEmpty && genderStr.isNotEmpty) {
      return '$ageStr • $genderStr';
    } else if (ageStr.isNotEmpty) {
      return ageStr;
    } else if (genderStr.isNotEmpty) {
      return genderStr;
    }
    return '—';
  }

  /// Sourced personalized greeting according to time of day.
  String getGreeting(PatientStrings strings, {DateTime? now}) {
    final currentHour = (now ?? DateTime.now()).hour;
    final name = patientDisplayName;
    if (currentHour >= 4 && currentHour < 12) {
      return strings.greetingMorning(name);
    } else if (currentHour >= 12 && currentHour < 17) {
      return strings.greetingAfternoon(name);
    } else {
      return strings.greetingEvening(name);
    }
  }

  /// Loads real patient-specific data from repositories with isolated component error boundaries.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _profileError = null;
    _casesError = null;
    _appointmentsError = null;
    notifyListeners();

    final id = activePatientId;
    if (id.isEmpty) {
      _patient = null;
      _ongoingCasesCount = 0;
      _nextVisit = null;
      _nearestUpcomingVisit = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 1. Patient Profile (Independent boundary)
    try {
      _patient = await _patientRepo.getPatientById(id);
      if (_patient != null) {
        PatientAppState.instance.setAuthenticatedPatient(_patient!);
      }
    } catch (e) {
      _profileError = 'Unable to load your information.';
    }

    // 2. Ongoing Cases Count (Independent boundary)
    try {
      final cases = await _caseRepo.getCasesForPatient(id);
      _ongoingCasesCount = cases.where((c) => c.isOpen).length;
    } catch (e) {
      _casesError = 'Unable to load your cases.';
      _ongoingCasesCount = 0;
    }

    // 3. Upcoming Appointments & Follow-ups (Independent boundary)
    try {
      await _fetchUpcomingAppointments(id);
    } catch (e) {
      _appointmentsError = 'Unable to load upcoming visits.';
      _nextVisit = null;
      _nearestUpcomingVisit = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUpcomingAppointments(String id) async {
    // 1. Fetch nearest upcoming clinical visit / follow-up
    _nearestUpcomingVisit = await _followUpService.getNearestUpcomingVisit(patientId: id);

    // 2. Also query active kiosk appointments for queue number fallback
    final appointments = await _appointmentRepo.getAppointmentsForPatient(id);
    final activeAppointments = appointments
        .where((a) =>
            a.status == AppointmentStatus.waiting ||
            a.status == AppointmentStatus.accepted ||
            a.status == AppointmentStatus.pending)
        .toList();

    activeAppointments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _nextVisit = activeAppointments.isNotEmpty ? activeAppointments.first : null;
  }

  /// Retries loading upcoming appointments specifically without reloading other components.
  Future<void> retryAppointments() async {
    final id = activePatientId;
    if (id.isEmpty) return;
    _appointmentsError = null;
    notifyListeners();

    try {
      await _fetchUpcomingAppointments(id);
    } catch (e) {
      _appointmentsError = 'Unable to load upcoming visits.';
      _nextVisit = null;
      _nearestUpcomingVisit = null;
    }
    notifyListeners();
  }

  Future<void> refresh() => loadDashboardData();
}
