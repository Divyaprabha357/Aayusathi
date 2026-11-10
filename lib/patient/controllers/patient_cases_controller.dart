import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../repositories/case_repository.dart';
import '../models/patient_app_state.dart';
import '../services/patient_session_service.dart';

enum PatientCasesTab {
  active,
  completed,
}

/// Controller managing Patient Cases list, Active / Completed tab switching,
/// pull-to-refresh, and patient-specific case retrieval.
class PatientCasesController extends ChangeNotifier {
  final CaseRepository _caseRepo;
  final PatientSessionService _sessionService;

  PatientCasesController({
    CaseRepository? caseRepo,
    PatientSessionService? sessionService,
  })  : _caseRepo = caseRepo ?? BackendProvider.instance.caseRepository,
        _sessionService = sessionService ?? PatientSessionService.instance;

  PatientCasesTab _selectedTab = PatientCasesTab.active;
  bool _isLoading = false;
  String? _errorMessage;
  List<ClinicalCase> _allCases = [];

  PatientCasesTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  List<ClinicalCase> get allCases => List.unmodifiable(_allCases);

  List<ClinicalCase> get activeCases {
    final list = _allCases.where((c) => c.isOpen).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<ClinicalCase> get completedCases {
    final list = _allCases.where((c) => c.isClosed).toList();
    list.sort((a, b) => (b.closedAt ?? b.updatedAt).compareTo(a.closedAt ?? a.updatedAt));
    return list;
  }

  List<ClinicalCase> get displayedCases =>
      _selectedTab == PatientCasesTab.active ? activeCases : completedCases;

  void selectTab(PatientCasesTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  Future<void> loadCases({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final patientId = _sessionService.currentSession.patientId ??
          PatientAppState.instance.authenticatedPatientId;

      if (kDebugMode) {
        debugPrint('[PatientCasesController] Patient session authenticated: ${_sessionService.isAuthenticated}');
        debugPrint('[PatientCasesController] Patient ID available: ${patientId != null && patientId.isNotEmpty}');
      }

      if (patientId != null && patientId.isNotEmpty) {
        _allCases = await _caseRepo.getCasesForPatient(patientId);
        if (kDebugMode) {
          debugPrint('[PatientCasesController] Successfully loaded ${_allCases.length} case(s).');
        }
      } else {
        _allCases = [];
      }
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientCasesController] Diagnostic: Case retrieval failed ($e)');
      }
      _isLoading = false;
      _errorMessage = 'Unable to load your cases. Please try again.';
      notifyListeners();
    }
  }

  Future<void> refresh() => loadCases(isRefresh: true);
}
