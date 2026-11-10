import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/audit_log.dart';
import '../../repositories/audit_repository.dart';
import '../../repositories/doctor_repository.dart';
import '../models/admin_domain_availability.dart';
import '../services/admin_auth_service.dart';

/// Deterministic sorting options for the Doctor Availability table.
enum DoctorAvailabilitySortOption {
  nameAsc,
  department,
  availability,
  lastActivity,
}

/// Domain capacity representation for Phase A6 domain view.
class DomainAvailabilitySummary {
  final String domainId;
  final String domainName;
  final int totalActive;
  final int available;
  final int inConsultation;
  final int offline;

  const DomainAvailabilitySummary({
    required this.domainId,
    required this.domainName,
    required this.totalActive,
    required this.available,
    required this.inConsultation,
    required this.offline,
  });
}

/// State management controller for the Admin Doctor Availability screen (Phase A6).
///
/// Mandates:
/// - Real-time stream subscription via [DoctorRepository.watchDoctorProfiles]
/// - Accurate active counting rule: only [DoctorProfile.isActive] == true counts as active
/// - Inactive doctors are operationally offline and excluded from active capacity
/// - 8-domain availability matrix breakdown
/// - Instant combinable filtering (department, account status, availability)
/// - Multi-parameter search without credential/PII/token exposure
/// - Hard-blocked mutations during [DoctorAvailabilityStatus.inConsultation]
/// - Pre-mutation concurrency validation
/// - Audit logging of [DOCTOR_AVAILABILITY_CHANGED]
class AdminAvailabilityController extends ChangeNotifier {
  static final AdminAvailabilityController instance = AdminAvailabilityController._();
  AdminAvailabilityController._();
  factory AdminAvailabilityController() => instance;

  DoctorRepository? _customDoctorRepository;
  AuditRepository? _customAuditRepository;

  void setCustomRepositories({
    DoctorRepository? doctorRepository,
    AuditRepository? auditRepository,
  }) {
    _customDoctorRepository = doctorRepository;
    _customAuditRepository = auditRepository;
    _restartSubscription();
  }

  void resetForTesting() {
    _subscription?.cancel();
    _subscription = null;
    _doctors = [];
    _isLoading = true;
    _errorMessage = null;
    _searchQuery = '';
    _selectedDepartment = null;
    _selectedAccountStatus = null;
    _selectedAvailabilityStatus = null;
    _sortOption = DoctorAvailabilitySortOption.nameAsc;
    _isProcessingAction = false;
    _actionError = null;
  }

  DoctorRepository get _doctorRepo =>
      _customDoctorRepository ?? BackendProvider.instance.doctorRepository;

  AuditRepository get _auditRepo =>
      _customAuditRepository ?? BackendProvider.instance.auditRepository;

  StreamSubscription<List<DoctorProfile>>? _subscription;

  List<DoctorProfile> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search, Filter & Sort State
  String _searchQuery = '';
  String? _selectedDepartment; // null or 'all' for all departments
  String? _selectedAccountStatus; // null or 'all', 'active', 'inactive'
  String? _selectedAvailabilityStatus; // null or 'all', 'offline', 'available', 'inConsultation'
  DoctorAvailabilitySortOption _sortOption = DoctorAvailabilitySortOption.nameAsc;

  // Processing state for async operations
  bool _isProcessingAction = false;
  String? _actionError;

  // Getters
  List<DoctorProfile> get allDoctors => List.unmodifiable(_doctors);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedDepartment => _selectedDepartment;
  String? get selectedAccountStatus => _selectedAccountStatus;
  String? get selectedAvailabilityStatus => _selectedAvailabilityStatus;
  DoctorAvailabilitySortOption get sortOption => _sortOption;
  bool get isProcessingAction => _isProcessingAction;
  String? get actionError => _actionError;

  // Real-time KPI summary counts (Counting Rule: Only isActive == true counts as active)
  int get totalActiveDoctors => _doctors.where((d) => d.isActive).length;
  int get onlineAvailableDoctors => _doctors.where((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.available).length;
  int get inConsultationDoctors => _doctors.where((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.inConsultation).length;
  int get offlineDoctors => _doctors.where((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.offline).length;
  int get totalDoctorsCount => _doctors.length;
  int get inactiveDoctorsCount => _doctors.where((d) => !d.isActive).length;

  /// Aggregated 8-domain capacity summary.
  List<DomainAvailabilitySummary> get domainSummaries {
    final list = <DomainAvailabilitySummary>[];
    for (final domain in AdminDomainAvailability.standardDomains) {
      final domainId = domain['id']!.toLowerCase();
      final domainName = domain['name']!;

      final activeInDomain = _doctors.where(
        (d) => d.isActive && d.department.toLowerCase() == domainId,
      ).toList();

      final availableCount = activeInDomain
          .where((d) => d.availabilityStatus == DoctorAvailabilityStatus.available)
          .length;
      final inConsultationCount = activeInDomain
          .where((d) => d.availabilityStatus == DoctorAvailabilityStatus.inConsultation)
          .length;
      final offlineCount = activeInDomain
          .where((d) => d.availabilityStatus == DoctorAvailabilityStatus.offline)
          .length;

      list.add(DomainAvailabilitySummary(
        domainId: domainId,
        domainName: domainName,
        totalActive: activeInDomain.length,
        available: availableCount,
        inConsultation: inConsultationCount,
        offline: offlineCount,
      ));
    }
    return list;
  }

  /// Returns the filtered and sorted list of doctors.
  List<DoctorProfile> get filteredDoctors {
    var result = List<DoctorProfile>.from(_doctors);

    // 1. Department Filter
    if (_selectedDepartment != null &&
        _selectedDepartment!.isNotEmpty &&
        _selectedDepartment != 'all') {
      result = result
          .where((d) => d.department.toLowerCase() == _selectedDepartment!.toLowerCase())
          .toList();
    }

    // 2. Account Status Filter
    if (_selectedAccountStatus != null &&
        _selectedAccountStatus!.isNotEmpty &&
        _selectedAccountStatus != 'all') {
      final requireActive = _selectedAccountStatus == 'active';
      result = result.where((d) => d.isActive == requireActive).toList();
    }

    // 3. Availability Filter
    if (_selectedAvailabilityStatus != null &&
        _selectedAvailabilityStatus!.isNotEmpty &&
        _selectedAvailabilityStatus != 'all') {
      final target = _selectedAvailabilityStatus!.toLowerCase();
      result = result.where((d) {
        // Inactive doctors are operationally offline
        if (!d.isActive) {
          return target == 'offline';
        }
        return d.availabilityStatus.value.toLowerCase() == target;
      }).toList();
    }

    // 4. Search Query Filter (Name, Doctor ID, Department - NO PII / passwords)
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((d) {
        final matchCode = d.doctorUniqueCode.toLowerCase().contains(query);
        final matchId = d.doctorId.toLowerCase().contains(query);
        final matchName = d.name.toLowerCase().contains(query);
        final matchDept = d.department.toLowerCase().contains(query);
        final matchQual = d.qualification.toLowerCase().contains(query);
        return matchCode || matchId || matchName || matchDept || matchQual;
      }).toList();
    }

    // 5. Sorting
    switch (_sortOption) {
      case DoctorAvailabilitySortOption.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case DoctorAvailabilitySortOption.department:
        result.sort((a, b) => a.department.toLowerCase().compareTo(b.department.toLowerCase()));
        break;
      case DoctorAvailabilitySortOption.availability:
        result.sort((a, b) {
          // Priority: available (0), inConsultation (1), offline (2)
          int priority(DoctorProfile doc) {
            if (!doc.isActive) return 3;
            switch (doc.availabilityStatus) {
              case DoctorAvailabilityStatus.available:
                return 0;
              case DoctorAvailabilityStatus.inConsultation:
                return 1;
              case DoctorAvailabilityStatus.online:
                return 0;
              case DoctorAvailabilityStatus.offline:
                return 2;
            }
          }
          final pA = priority(a);
          final pB = priority(b);
          if (pA != pB) return pA.compareTo(pB);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case DoctorAvailabilitySortOption.lastActivity:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    return result;
  }

  /// Initializes real-time stream listener.
  void init() {
    if (_subscription != null) return;
    _restartSubscription();
  }

  void _restartSubscription() {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = _doctorRepo.watchDoctorProfiles().listen(
        (data) {
          _doctors = data;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[AdminAvailabilityController] Stream error: $error');
          _isLoading = false;
          _errorMessage = 'Failed to load doctor availability: ${error.toString()}';
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to initialize availability stream: $e';
      notifyListeners();
    }
  }

  // Filter & Search Mutations
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedDepartment(String? department) {
    _selectedDepartment = department;
    notifyListeners();
  }

  void setSelectedAccountStatus(String? status) {
    _selectedAccountStatus = status;
    notifyListeners();
  }

  void setSelectedAvailabilityStatus(String? status) {
    _selectedAvailabilityStatus = status;
    notifyListeners();
  }

  void setSortOption(DoctorAvailabilitySortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedDepartment = null;
    _selectedAccountStatus = null;
    _selectedAvailabilityStatus = null;
    _sortOption = DoctorAvailabilitySortOption.nameAsc;
    notifyListeners();
  }

  /// Refreshes the doctor list manually.
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _doctorRepo.getAllDoctorProfiles();
      _doctors = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error refreshing availability: $e';
      notifyListeners();
    }
  }

  /// Validates permitted availability transition before opening confirmation or executing update.
  /// Returns null if allowed, or an explanatory error message if blocked.
  String? checkAvailabilityChangeSafeguard({
    required DoctorProfile doctor,
    required DoctorAvailabilityStatus targetStatus,
  }) {
    if (!doctor.isActive) {
      return 'Doctor account is inactive. Inactive doctors cannot be set to Available.';
    }

    if (doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation) {
      return 'Doctor is currently IN CONSULTATION. Availability cannot be manually changed while the Doctor is consulting a patient.';
    }

    if (targetStatus == DoctorAvailabilityStatus.inConsultation) {
      return 'Admin cannot manually assign a Doctor into consultation state.';
    }

    return null;
  }

  /// Toggles doctor availability between AVAILABLE and OFFLINE with strict safeguards,
  /// concurrency check, and audit logging.
  Future<bool> setDoctorAvailability({
    required DoctorProfile doctor,
    required DoctorAvailabilityStatus targetStatus,
  }) async {
    // 1. Initial Safeguard Check
    final safeguardError = checkAvailabilityChangeSafeguard(
      doctor: doctor,
      targetStatus: targetStatus,
    );
    if (safeguardError != null) {
      _actionError = safeguardError;
      notifyListeners();
      return false;
    }

    _isProcessingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      // 2. Concurrency Safety: Fetch fresh profile to verify state hasn't transitioned to inConsultation
      final freshProfile = await _doctorRepo.getDoctorProfileById(doctor.doctorId);
      if (freshProfile != null) {
        if (!freshProfile.isActive) {
          _isProcessingAction = false;
          _actionError = 'Doctor account has been deactivated.';
          notifyListeners();
          return false;
        }
        if (freshProfile.availabilityStatus == DoctorAvailabilityStatus.inConsultation) {
          _isProcessingAction = false;
          _actionError = 'Doctor has started an active consultation. Availability update blocked.';
          notifyListeners();
          return false;
        }
      }

      // 3. Apply Field-Level Firestore Update
      await _doctorRepo.setDoctorAvailabilityStatus(
        doctorId: doctor.doctorId,
        availabilityStatus: targetStatus,
      );

      // Optimistic / Local Update
      final idx = _doctors.indexWhere((d) => d.doctorId == doctor.doctorId);
      if (idx != -1) {
        _doctors[idx] = _doctors[idx].copyWith(
          availabilityStatus: targetStatus,
          updatedAt: DateTime.now(),
        );
      }

      // 4. Record Governance Audit Log
      try {
        final currentAdmin = AdminAuthService.instance.currentSession?.username ?? 'admin01';
        final audit = AuditLog(
          auditId: 'AUD-AVAIL-${DateTime.now().microsecondsSinceEpoch}',
          actorType: AuditActorType.admin.value,
          actorId: currentAdmin,
          action: 'DOCTOR_AVAILABILITY_CHANGED',
          entityType: 'DOCTOR_PROFILE',
          entityId: doctor.doctorId,
          timestamp: DateTime.now(),
          metadata: {
            'doctorId': doctor.doctorId,
            'doctorUniqueCode': doctor.doctorUniqueCode,
            'previousAvailability': doctor.availabilityStatus.value,
            'newAvailability': targetStatus.value,
            'department': doctor.department,
          },
        );
        await _auditRepo.logEvent(audit);
      } catch (auditError) {
        debugPrint('[AdminAvailabilityController] Audit log error: $auditError');
      }

      _isProcessingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessingAction = false;
      _actionError = 'Failed to update doctor availability: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
