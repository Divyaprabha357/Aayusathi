import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/clinical_visit.dart';
import '../../doctor/models/investigation_request.dart';
import '../../doctor/models/patient_transfer_request.dart';
import '../../doctor/models/report_document.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../services/admin_auth_service.dart';

/// Reactive state management controller for the Phase A9 Escalated Patient Clinical Workspace.
///
/// Coordinates read-only clinical data retrieval across repositories:
/// - [PatientRepository]: Authorized patient identity records
/// - [CaseRepository]: Authoritative clinical case metadata & escalation state
/// - [ClinicalVisitRepository]: Multi-visit consultation encounter history
/// - [VitalRepository]: Longitudinal telemetry sensor readings
/// - [InvestigationRepository] & [ReportRepository]: Diagnostic orders & verified reports
/// - [TransferRepository]: Inter-department patient referral records
///
/// Strictly enforces read-only governance: Zero clinical editing, zero doctor assignment.
class AdminEscalatedPatientWorkspaceController extends ChangeNotifier {
  final String patientId;
  final String caseId;

  AdminEscalatedPatientWorkspaceController({
    required this.patientId,
    required this.caseId,
  });

  bool _isLoading = true;
  bool _isStartingReview = false;
  String? _errorMessage;

  Patient? _patient;
  ClinicalCase? _clinicalCase;
  List<ClinicalVisit> _visits = [];
  List<VitalReading> _vitals = [];
  Map<String, List<InvestigationRequest>> _investigationsByVisit = {};
  Map<String, List<ReportDocument>> _reportsByVisit = {};
  List<PatientTransferRequest> _transfers = [];

  int _selectedVisitIndex = 0;
  StreamSubscription<List<ClinicalCase>>? _caseEscalationsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  bool get isStartingReview => _isStartingReview;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  Patient? get patient => _patient;
  ClinicalCase? get clinicalCase => _clinicalCase;
  List<ClinicalVisit> get visits => List.unmodifiable(_visits);
  List<VitalReading> get vitals => List.unmodifiable(_vitals);
  List<PatientTransferRequest> get transfers => List.unmodifiable(_transfers);
  int get selectedVisitIndex => _selectedVisitIndex;

  /// Returns the currently active/selected [ClinicalVisit].
  ClinicalVisit? get selectedVisit {
    if (_visits.isEmpty) return null;
    if (_selectedVisitIndex >= 0 && _selectedVisitIndex < _visits.length) {
      return _visits[_selectedVisitIndex];
    }
    return _visits.first;
  }

  /// Returns investigations ordered for the given [visitId].
  List<InvestigationRequest> getInvestigationsForVisit(String visitId) {
    return _investigationsByVisit[visitId] ?? const [];
  }

  /// Returns report documents attached to the given [visitId].
  List<ReportDocument> getReportsForVisit(String visitId) {
    return _reportsByVisit[visitId] ?? const [];
  }

  /// Latest recorded vital telemetry reading.
  VitalReading? get latestVital => _vitals.isNotEmpty ? _vitals.first : null;

  /// Whether an active clinical consultation encounter is currently ongoing.
  bool get isConsultationActive => _visits.any((v) => v.isActive);

  /// Active consultation encounter if one exists.
  ClinicalVisit? get activeConsultationVisit {
    return _visits.cast<ClinicalVisit?>().firstWhere(
          (v) => v?.isActive == true,
          orElse: () => null,
        );
  }

  /// Initializes and loads all clinical data for the workspace.
  Future<void> initialize() async {
    await loadData();
    _subscribeToCaseUpdates();
  }

  /// Subscribes to real-time case updates so review state or clinical changes sync automatically.
  void _subscribeToCaseUpdates() {
    _caseEscalationsSubscription?.cancel();
    try {
      final stream = BackendProvider.instance.caseRepository.watchEscalatedCases();
      _caseEscalationsSubscription = stream.listen((cases) {
        final cleanCaseId = caseId.trim();
        final match = cases.cast<ClinicalCase?>().firstWhere(
              (c) => c?.caseId == cleanCaseId,
              orElse: () => null,
            );
        if (match != null && _clinicalCase != match) {
          _clinicalCase = match;
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('[AdminEscalatedPatientWorkspaceController] Stream error: $err');
      });
    } catch (e) {
      debugPrint('[AdminEscalatedPatientWorkspaceController] Watch stream error: $e');
    }
  }

  /// Loads all longitudinal data concurrently.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final backend = BackendProvider.instance;

      // 1. Fetch Patient & Case metadata
      final patientFuture = backend.patientRepository.getPatientById(patientId);
      final caseFuture = backend.caseRepository.getCaseById(
        patientId: patientId,
        caseId: caseId,
      );
      final visitsFuture = backend.clinicalVisitRepository.getVisitsForCase(
        patientId: patientId,
        caseId: caseId,
      );
      final vitalsFuture = backend.vitalRepository.getVitalsForPatient(patientId);
      final transfersFuture = backend.transferRepository.getTransfersForCase(
        patientId: patientId,
        caseId: caseId,
      );

      final results = await Future.wait([
        patientFuture,
        caseFuture,
        visitsFuture,
        vitalsFuture,
        transfersFuture,
      ]);

      _patient = results[0] as Patient?;
      _clinicalCase = results[1] as ClinicalCase?;
      final loadedVisits = results[2] as List<ClinicalVisit>;
      final loadedVitals = results[3] as List<VitalReading>;
      final loadedTransfers = results[4] as List<PatientTransferRequest>;

      // Sort visits chronologically (Visit 1, Visit 2, ...)
      loadedVisits.sort((a, b) => a.visitNumber.compareTo(b.visitNumber));
      _visits = loadedVisits;

      // Sort vitals newest first
      loadedVitals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _vitals = loadedVitals;

      // Sort transfers chronologically
      loadedTransfers.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      _transfers = loadedTransfers;

      // 2. Fetch Investigations and Reports for all visits
      final Map<String, List<InvestigationRequest>> invMap = {};
      final Map<String, List<ReportDocument>> repMap = {};

      for (final visit in _visits) {
        try {
          final invs = await backend.investigationRepository.getInvestigationRequests(
            patientId: patientId,
            caseId: caseId,
            visitId: visit.visitId,
          );
          invMap[visit.visitId] = invs;
        } catch (e) {
          debugPrint('[AdminEscalatedPatientWorkspaceController] Error fetching investigations for ${visit.visitId}: $e');
          invMap[visit.visitId] = visit.investigationRequests;
        }

        try {
          final reps = await backend.reportRepository.getReportsForVisit(
            patientId: patientId,
            caseId: caseId,
            visitId: visit.visitId,
          );
          repMap[visit.visitId] = reps;
        } catch (e) {
          debugPrint('[AdminEscalatedPatientWorkspaceController] Error fetching reports for ${visit.visitId}: $e');
          repMap[visit.visitId] = const [];
        }
      }

      _investigationsByVisit = invMap;
      _reportsByVisit = repMap;

      // Default selected visit: source visit of escalation if specified, or latest visit
      if (_visits.isNotEmpty) {
        final sourceId = _clinicalCase?.escalationSourceVisitId;
        if (sourceId != null) {
          final idx = _visits.indexWhere((v) => v.visitId == sourceId);
          _selectedVisitIndex = idx != -1 ? idx : _visits.length - 1;
        } else {
          _selectedVisitIndex = _visits.length - 1;
        }
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminEscalatedPatientWorkspaceController] Error loading clinical records: $e');
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Sets the selected active visit index.
  void selectVisitIndex(int index) {
    if (index >= 0 && index < _visits.length) {
      _selectedVisitIndex = index;
      notifyListeners();
    }
  }

  /// Sets the selected active visit by its unique [visitId].
  void selectVisitById(String visitId) {
    final idx = _visits.indexWhere((v) => v.visitId == visitId);
    if (idx != -1) {
      _selectedVisitIndex = idx;
      notifyListeners();
    }
  }

  /// Administrative Action: Starts review on the escalated case (transitions to `underReview`).
  Future<void> startReview() async {
    if (_clinicalCase == null) return;
    if (_clinicalCase!.isUnderReview) return;

    _isStartingReview = true;
    _errorMessage = null;
    notifyListeners();

    final adminId = AdminAuthService.instance.currentSession?.username ?? 'admin01';

    try {
      final updatedCase = await BackendProvider.instance.caseRepository.startAdminCaseReview(
        patientId: patientId,
        caseId: caseId,
        adminId: adminId,
      );

      _clinicalCase = updatedCase;
      _isStartingReview = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminEscalatedPatientWorkspaceController] Error starting review: $e');
      _isStartingReview = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _caseEscalationsSubscription?.cancel();
    super.dispose();
  }
}
