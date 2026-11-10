import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../services/admin_auth_service.dart';

/// 5-way deterministic sorting options for the Case Escalations table.
enum AdminCaseSortOption {
  oldestEscalation,
  newestEscalation,
  department,
  visitCount,
  reason,
}

/// Reactive state management controller for the Phase A8 Case Escalations module (`/admin/case-escalations`).
///
/// Encapsulates:
/// 1. Real-time Firestore stream subscriptions on `watchEscalatedCases()`.
/// 2. KPI overview metric aggregations (Total, Pending, Under Review, Repeated Visits).
/// 3. Multi-dimensional filtering (Search, Department, Reason, Review Status).
/// 4. 5-way deterministic sorting.
/// 5. Transactional administrative "Start Review" workflow.
class AdminCaseEscalationController extends ChangeNotifier {
  static final AdminCaseEscalationController instance =
      AdminCaseEscalationController._();

  AdminCaseEscalationController._();
  factory AdminCaseEscalationController() => instance;

  StreamSubscription<List<ClinicalCase>>? _casesSubscription;

  List<ClinicalCase> _allEscalations = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter State
  String _searchQuery = '';
  String _selectedDepartment = 'ALL';
  CaseEscalationReason? _selectedReason;
  CaseEscalationStatus? _selectedReviewStatus;
  AdminCaseSortOption _sortOption = AdminCaseSortOption.oldestEscalation;

  // Getters
  List<ClinicalCase> get allEscalations => List.unmodifiable(_allEscalations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  CaseEscalationReason? get selectedReason => _selectedReason;
  CaseEscalationStatus? get selectedReviewStatus => _selectedReviewStatus;
  AdminCaseSortOption get sortOption => _sortOption;

  // KPI Metrics
  int get totalEscalatedCases =>
      _allEscalations.where((c) => c.isEscalated).length;

  int get pendingReviewCount => _allEscalations
      .where((c) => c.escalationStatus == CaseEscalationStatus.escalated)
      .length;

  int get underReviewCount => _allEscalations
      .where((c) => c.escalationStatus == CaseEscalationStatus.underReview)
      .length;

  int get repeatedVisitsCount => _allEscalations
      .where((c) =>
          c.escalationReason ==
          CaseEscalationReason.repeatedVisitsNoResolution)
      .length;

  /// Initializes the real-time stream subscription.
  void initialize() {
    _subscribeToCases();
  }

  void _subscribeToCases() {
    _casesSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stream = BackendProvider.instance.caseRepository.watchEscalatedCases();
      _casesSubscription = stream.listen(
        (cases) {
          _allEscalations = List.from(cases);
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('[AdminCaseEscalationController] Stream error: $err');
          _isLoading = false;
          _errorMessage = err.toString().replaceFirst('Exception: ', '');
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Sets live search query (filters by Case ID, Patient ID, Doctor ID/Name).
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  /// Filters by Clinical Department / Domain.
  void setSelectedDepartment(String department) {
    _selectedDepartment = department.trim().toUpperCase();
    notifyListeners();
  }

  /// Filters by Escalation Reason.
  void setSelectedReason(CaseEscalationReason? reason) {
    _selectedReason = reason;
    notifyListeners();
  }

  /// Filters by Review Status (`escalated` or `underReview`).
  void setSelectedReviewStatus(CaseEscalationStatus? status) {
    _selectedReviewStatus = status;
    notifyListeners();
  }

  /// Sets sorting order.
  void setSortOption(AdminCaseSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  /// Resets all filter controls.
  void resetFilters() {
    _searchQuery = '';
    _selectedDepartment = 'ALL';
    _selectedReason = null;
    _selectedReviewStatus = null;
    _sortOption = AdminCaseSortOption.oldestEscalation;
    notifyListeners();
  }

  /// Returns the filtered and sorted list of clinical case escalations.
  List<ClinicalCase> get filteredEscalations {
    return _allEscalations.where((c) {
      // 1. Must be actively escalated or under review
      if (!c.isEscalated) return false;

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCaseId = c.caseId.toLowerCase().contains(q);
        final matchPatientId = c.patientId.toLowerCase().contains(q);
        final matchDocId =
            (c.escalatedByDoctorId ?? '').toLowerCase().contains(q);
        final matchDocName =
            (c.escalatedByDoctorName ?? '').toLowerCase().contains(q);
        final matchTitle = c.title.toLowerCase().contains(q);

        if (!matchCaseId &&
            !matchPatientId &&
            !matchDocId &&
            !matchDocName &&
            !matchTitle) {
          return false;
        }
      }

      // 3. Department filter
      if (_selectedDepartment != 'ALL') {
        final cleanDept = _selectedDepartment.replaceAll(RegExp(r'[\s\-_]+'), '');
        final caseDept = c.domain.replaceAll(RegExp(r'[\s\-_]+'), '').toUpperCase();
        if (!caseDept.contains(cleanDept)) {
          return false;
        }
      }

      // 4. Reason filter
      if (_selectedReason != null && c.escalationReason != _selectedReason) {
        return false;
      }

      // 5. Review Status filter
      if (_selectedReviewStatus != null &&
          c.escalationStatus != _selectedReviewStatus) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_sortOption) {
          case AdminCaseSortOption.oldestEscalation:
            final aTime = a.escalatedAt ?? a.updatedAt;
            final bTime = b.escalatedAt ?? b.updatedAt;
            return aTime.compareTo(bTime);

          case AdminCaseSortOption.newestEscalation:
            final aTime = a.escalatedAt ?? a.updatedAt;
            final bTime = b.escalatedAt ?? b.updatedAt;
            return bTime.compareTo(aTime);

          case AdminCaseSortOption.department:
            return a.domain.toLowerCase().compareTo(b.domain.toLowerCase());

          case AdminCaseSortOption.visitCount:
            return b.visitCount.compareTo(a.visitCount);

          case AdminCaseSortOption.reason:
            final aReason = a.escalationReason?.name ?? '';
            final bReason = b.escalationReason?.name ?? '';
            return aReason.compareTo(bReason);
        }
      });
  }

  /// Administrative Action: Starts review on a pending escalated case.
  Future<void> startReview({
    required String patientId,
    required String caseId,
  }) async {
    final adminId =
        AdminAuthService.instance.currentSession?.username ?? 'admin01';

    try {
      final updatedCase = await BackendProvider.instance.caseRepository
          .startAdminCaseReview(
        patientId: patientId,
        caseId: caseId,
        adminId: adminId,
      );

      final idx = _allEscalations.indexWhere((c) => c.caseId == caseId);
      if (idx != -1) {
        _allEscalations[idx] = updatedCase;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AdminCaseEscalationController] Error starting review: $e');
      rethrow;
    }
  }

  /// Manually triggers a reload.
  Future<void> refresh() async {
    _subscribeToCases();
  }

  /// Resets controller state for unit and widget testing.
  @visibleForTesting
  void resetForTesting() {
    _casesSubscription?.cancel();
    _casesSubscription = null;
    _allEscalations = [];
    _isLoading = false;
    _errorMessage = null;
    resetFilters();
  }

  /// Sets error state for unit and widget testing.
  @visibleForTesting
  void setErrorForTesting(String message) {
    _casesSubscription?.cancel();
    _casesSubscription = null;
    _allEscalations = [];
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _casesSubscription?.cancel();
    super.dispose();
  }
}
