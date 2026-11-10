import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/investigation_request.dart';
import '../../repositories/case_repository.dart';
import '../../repositories/clinical_visit_repository.dart';
import '../../repositories/investigation_repository.dart';
import '../models/patient_app_state.dart';
import '../services/patient_session_service.dart';

enum PatientReportsTab {
  submitted,
  yetToSubmit,
}

/// Controller managing Patient Reports list and Submitted / Yet to Submit segmented switching.
class PatientReportsController extends ChangeNotifier {
  final InvestigationRepository _investigationRepo;
  final CaseRepository _caseRepo;
  final ClinicalVisitRepository _visitRepo;
  final PatientSessionService _sessionService;
  final String? _explicitPatientId;

  PatientReportsController({
    InvestigationRepository? investigationRepo,
    CaseRepository? caseRepo,
    ClinicalVisitRepository? visitRepo,
    PatientSessionService? sessionService,
    String? patientId,
  })  : _investigationRepo = investigationRepo ?? BackendProvider.instance.investigationRepository,
        _caseRepo = caseRepo ?? BackendProvider.instance.caseRepository,
        _visitRepo = visitRepo ?? BackendProvider.instance.clinicalVisitRepository,
        _sessionService = sessionService ?? PatientSessionService.instance,
        _explicitPatientId = patientId;

  PatientReportsTab _selectedTab = PatientReportsTab.submitted;
  bool _isLoading = false;
  String? _errorMessage;
  String? _highlightedInvestigationId;
  List<InvestigationRequest> _submittedReports = [];
  List<InvestigationRequest> _pendingReports = [];
  final Map<String, String> _caseTitles = {};
  final Map<String, DateTime> _visitDates = {};

  PatientReportsTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String? get highlightedInvestigationId => _highlightedInvestigationId;

  List<InvestigationRequest> get submittedReports => _submittedReports;
  List<InvestigationRequest> get yetToSubmitReports => _pendingReports;

  List<InvestigationRequest> get displayedReports =>
      _selectedTab == PatientReportsTab.submitted ? _submittedReports : _pendingReports;

  String get activePatientId =>
      _explicitPatientId ??
      _sessionService.authenticatedPatientId ??
      PatientAppState.instance.authenticatedPatientId ??
      '';

  String getCaseTitle(String? caseId) {
    if (caseId == null || caseId.isEmpty) return 'General Consultation';
    return _caseTitles[caseId] ?? 'Case #$caseId';
  }

  DateTime? getVisitDate(String? visitId) {
    if (visitId == null || visitId.isEmpty) return null;
    return _visitDates[visitId];
  }

  void selectTab(PatientReportsTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  void focusInvestigation(String? investigationId) {
    _highlightedInvestigationId = investigationId;
    if (investigationId != null && investigationId.isNotEmpty) {
      _selectedTab = PatientReportsTab.yetToSubmit;
    }
    notifyListeners();
  }

  Future<void> loadReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetId = PatientAppState.instance.targetInvestigationId;
      if (targetId != null && targetId.isNotEmpty) {
        _highlightedInvestigationId = targetId;
        _selectedTab = PatientReportsTab.yetToSubmit;
      }

      final patientId = activePatientId;
      if (patientId.isNotEmpty) {
        final cases = await _caseRepo.getCasesForPatient(patientId);
        final List<InvestigationRequest> allInvestigations = [];
        _caseTitles.clear();
        _visitDates.clear();

        for (final c in cases) {
          final title = c.title.trim().isNotEmpty
              ? c.title.trim()
              : (c.domain.trim().isNotEmpty ? c.domain.trim() : 'Case #${c.caseId}');
          _caseTitles[c.caseId] = title;

          final visits = await _visitRepo.getVisitsForCase(
            patientId: patientId,
            caseId: c.caseId,
          );

          for (final v in visits) {
            _visitDates[v.visitId] = v.startedAt;

            final requests = await _investigationRepo.getInvestigationRequests(
              patientId: patientId,
              caseId: c.caseId,
              visitId: v.visitId,
            );

            // Enrich request with parent context if not already populated
            for (final req in requests) {
              allInvestigations.add(req.copyWith(
                patientId: req.patientId ?? patientId,
                caseId: req.caseId ?? c.caseId,
                visitId: req.visitId ?? v.visitId,
                department: req.department ?? c.domain,
              ));
            }
          }
        }

        // Categorize into submitted (uploaded / reviewed) and yet to submit (pendingUpload)
        _submittedReports = allInvestigations
            .where((r) =>
                r.status == InvestigationStatus.uploaded ||
                r.status == InvestigationStatus.reviewed)
            .toList();

        // Sort submitted chronologically descending (most recent first)
        _submittedReports.sort((a, b) {
          final dateA = a.uploadedAt ?? a.requestedAt;
          final dateB = b.uploadedAt ?? b.requestedAt;
          return dateB.compareTo(dateA);
        });

        _pendingReports = allInvestigations
            .where((r) => r.status == InvestigationStatus.pendingUpload)
            .toList();

        // Sort pending: required tests first, then by requestedAt descending
        _pendingReports.sort((a, b) {
          if (a.isRequired != b.isRequired) {
            return a.isRequired ? -1 : 1;
          }
          return b.requestedAt.compareTo(a.requestedAt);
        });
      } else {
        _submittedReports = [];
        _pendingReports = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load medical reports.';
      notifyListeners();
    }
  }

  Future<void> refresh() => loadReports();
}
