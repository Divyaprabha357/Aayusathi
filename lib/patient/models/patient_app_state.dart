import 'package:flutter/foundation.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../models/patient.dart';
import 'patient_navigation_tab.dart';

/// Central observable state for the Patient App session.
class PatientAppState extends ChangeNotifier {
  static final PatientAppState instance = PatientAppState._internal();
  PatientAppState._internal();

  PatientNavigationTab _currentTab = PatientNavigationTab.dashboard;
  Patient? _currentPatient;
  String? _authenticatedPatientId;
  KioskLocale _selectedLocale = KioskLocale.english;
  bool _isAuthenticated = false;

  String? _targetInvestigationId;
  DateTime? _targetCalendarDate;
  bool _notificationPromptDismissed = false;

  PatientNavigationTab get currentTab => _currentTab;
  Patient? get currentPatient => _currentPatient;
  String? get authenticatedPatientId => _authenticatedPatientId;
  KioskLocale get selectedLocale => _selectedLocale;
  bool get isAuthenticated => _isAuthenticated;
  String? get targetInvestigationId => _targetInvestigationId;
  DateTime? get targetCalendarDate => _targetCalendarDate;
  bool get notificationPromptDismissed => _notificationPromptDismissed;

  void dismissNotificationPrompt() {
    _notificationPromptDismissed = true;
    notifyListeners();
  }

  void setTab(PatientNavigationTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void navigateToReportsWithInvestigation(String? investigationId) {
    _targetInvestigationId = investigationId;
    _currentTab = PatientNavigationTab.reports;
    notifyListeners();
  }

  void clearTargetInvestigation() {
    if (_targetInvestigationId != null) {
      _targetInvestigationId = null;
      notifyListeners();
    }
  }

  void navigateToCalendarWithDate(DateTime? date) {
    _targetCalendarDate = date;
    _currentTab = PatientNavigationTab.calendar;
    notifyListeners();
  }

  void clearTargetCalendarDate() {
    if (_targetCalendarDate != null) {
      _targetCalendarDate = null;
      notifyListeners();
    }
  }

  void setAuthenticatedPatient(Patient patient) {
    _currentPatient = patient;
    _authenticatedPatientId = patient.patientId;
    _isAuthenticated = true;
    notifyListeners();
  }

  void setPatientId(String patientId) {
    _authenticatedPatientId = patientId;
    _isAuthenticated = true;
    notifyListeners();
  }

  void setLocale(KioskLocale locale) {
    if (_selectedLocale != locale) {
      _selectedLocale = locale;
      notifyListeners();
    }
  }

  void resetSession() {
    _currentTab = PatientNavigationTab.dashboard;
    _currentPatient = null;
    _authenticatedPatientId = null;
    _targetInvestigationId = null;
    _targetCalendarDate = null;
    _notificationPromptDismissed = false;
    _isAuthenticated = false;
    _selectedLocale = KioskLocale.english;
    notifyListeners();
  }
}
