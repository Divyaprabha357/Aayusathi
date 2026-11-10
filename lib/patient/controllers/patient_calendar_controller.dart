import 'package:flutter/foundation.dart';
import '../models/patient_calendar_item.dart';
import '../services/patient_follow_up_service.dart';
import '../services/patient_session_service.dart';

/// Controller managing month navigation, selected day, and live calendar items for the authenticated patient.
class PatientCalendarController extends ChangeNotifier {
  final PatientFollowUpService _followUpService;
  final PatientSessionService _sessionService;

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  List<PatientCalendarItem> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  PatientCalendarController({
    PatientFollowUpService? followUpService,
    PatientSessionService? sessionService,
  })  : _followUpService = followUpService ?? PatientFollowUpService(),
        _sessionService = sessionService ?? PatientSessionService.instance;

  DateTime get visibleMonth => _visibleMonth;
  DateTime get selectedDate => _selectedDate;
  List<PatientCalendarItem> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<PatientCalendarItem> get selectedDateEvents =>
      _events.where((e) => e.isSameDay(_selectedDate)).toList();

  void nextMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    notifyListeners();
  }

  void previousMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    if (_visibleMonth.month != date.month || _visibleMonth.year != date.year) {
      _visibleMonth = DateTime(date.year, date.month, 1);
    }
    notifyListeners();
  }

  void setEvents(List<PatientCalendarItem> items) {
    _events = items;
    notifyListeners();
  }

  /// Loads real follow-up dates and scheduled appointments from Firebase.
  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final patientId = _sessionService.authenticatedPatientId;
      if (patientId == null || patientId.isEmpty) {
        _events = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _events = await _followUpService.getFollowUpsAndAppointmentsForPatient(patientId: patientId);
    } catch (e) {
      _errorMessage = 'Unable to load calendar events.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadEvents();
}
