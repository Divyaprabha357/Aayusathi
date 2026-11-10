import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/audit_log.dart';
import '../../repositories/audit_repository.dart';
import '../../repositories/doctor_repository.dart';
import '../services/admin_auth_service.dart';

/// Sorting criteria for doctor registry table.
enum DoctorSortOption {
  newest,
  nameAsc,
  department,
  status,
}

/// State management controller for the Admin Manage Doctors dashboard screen.
///
/// Features:
/// - Real-time stream of all provisioned physician profiles
/// - In-memory instant multi-parameter search (ID, name, phone, department)
/// - Department and active-status filtering
/// - Sorting by newest, name, department, status
/// - Active consultation safeguard enforcement
/// - Deactivation / Activation toggles with audit logging
/// - Profile updating with department transfer audit tracking
class AdminManageDoctorsController extends ChangeNotifier {
  static final AdminManageDoctorsController instance = AdminManageDoctorsController._();
  AdminManageDoctorsController._();
  factory AdminManageDoctorsController() => instance;

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
    _selectedStatus = null;
    _sortOption = DoctorSortOption.newest;
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
  String? _selectedDepartment; // null = all
  String? _selectedStatus; // null = all, 'active', 'inactive'
  DoctorSortOption _sortOption = DoctorSortOption.newest;

  // Processing state for async operations
  bool _isProcessingAction = false;
  String? _actionError;

  // Getters
  List<DoctorProfile> get allDoctors => List.unmodifiable(_doctors);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedDepartment => _selectedDepartment;
  String? get selectedStatus => _selectedStatus;
  DoctorSortOption get sortOption => _sortOption;
  bool get isProcessingAction => _isProcessingAction;
  String? get actionError => _actionError;

  int get totalCount => _doctors.length;
  int get activeCount => _doctors.where((d) => d.isActive).length;
  int get inactiveCount => _doctors.where((d) => !d.isActive).length;

  /// Returns the current filtered and sorted view of doctors.
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

    // 2. Active Status Filter
    if (_selectedStatus != null &&
        _selectedStatus!.isNotEmpty &&
        _selectedStatus != 'all') {
      final requireActive = _selectedStatus == 'active';
      result = result.where((d) => d.isActive == requireActive).toList();
    }

    // 3. Search Query Filter
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((d) {
        final matchCode = d.doctorUniqueCode.toLowerCase().contains(query);
        final matchId = d.doctorId.toLowerCase().contains(query);
        final matchName = d.name.toLowerCase().contains(query);
        final matchPhone = d.registeredPhone.toLowerCase().contains(query);
        final matchDept = d.department.toLowerCase().contains(query);
        final matchEmail = d.email.toLowerCase().contains(query);
        return matchCode || matchId || matchName || matchPhone || matchDept || matchEmail;
      }).toList();
    }

    // 4. Sorting
    switch (_sortOption) {
      case DoctorSortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DoctorSortOption.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case DoctorSortOption.department:
        result.sort((a, b) => a.department.toLowerCase().compareTo(b.department.toLowerCase()));
        break;
      case DoctorSortOption.status:
        result.sort((a, b) {
          if (a.isActive == b.isActive) {
            return b.createdAt.compareTo(a.createdAt);
          }
          return a.isActive ? -1 : 1; // Active first
        });
        break;
    }

    return result;
  }

  /// Initializes real-time listener for doctor profiles.
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
          debugPrint('[AdminManageDoctorsController] Stream error: $error');
          _isLoading = false;
          _errorMessage = 'Failed to load doctors: ${error.toString()}';
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to initialize doctors stream: $e';
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

  void setSelectedStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSortOption(DoctorSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedDepartment = null;
    _selectedStatus = null;
    _sortOption = DoctorSortOption.newest;
    notifyListeners();
  }

  /// Refreshes the doctor list.
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
      _errorMessage = 'Error refreshing doctors: $e';
      notifyListeners();
    }
  }

  /// Checks if a doctor can be deactivated or edited.
  /// Returns null if allowed, or error message string if blocked.
  String? checkActionSafeguard(DoctorProfile doctor) {
    if (doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation) {
      return 'Doctor is currently IN CONSULTATION. Cannot change status or department during active clinical care.';
    }
    return null;
  }

  /// Toggles doctor active/inactive status with active consultation protection and audit logging.
  Future<bool> setDoctorActiveStatus({
    required DoctorProfile doctor,
    required bool newActiveStatus,
  }) async {
    // 1. Safeguard check
    if (!newActiveStatus && doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation) {
      _actionError = 'Cannot deactivate a doctor who is currently in consultation.';
      notifyListeners();
      return false;
    }

    _isProcessingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      await _doctorRepo.setDoctorActiveStatus(
        doctorId: doctor.doctorId,
        isActive: newActiveStatus,
      );

      final idx = _doctors.indexWhere((d) => d.doctorId == doctor.doctorId);
      if (idx != -1) {
        _doctors[idx] = _doctors[idx].copyWith(
          isActive: newActiveStatus,
          availabilityStatus: !newActiveStatus ? DoctorAvailabilityStatus.offline : _doctors[idx].availabilityStatus,
          updatedAt: DateTime.now(),
        );
      }

      // Audit Log Event
      try {
        final currentAdmin = AdminAuthService.instance.currentSession?.username ?? 'admin01';
        final audit = AuditLog(
          auditId: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
          actorType: AuditActorType.admin.value,
          actorId: currentAdmin,
          action: newActiveStatus ? 'DOCTOR_ACTIVATED' : 'DOCTOR_DEACTIVATED',
          entityType: 'DOCTOR_PROFILE',
          entityId: doctor.doctorId,
          timestamp: DateTime.now(),
          metadata: {
            'doctorId': doctor.doctorId,
            'doctorUniqueCode': doctor.doctorUniqueCode,
            'previousStatus': doctor.isActive,
            'newStatus': newActiveStatus,
            'department': doctor.department,
          },
        );
        await _auditRepo.logEvent(audit);
      } catch (e) {
        debugPrint('[AdminManageDoctorsController] Audit log error: $e');
      }

      _isProcessingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessingAction = false;
      _actionError = 'Failed to update doctor status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Updates editable profile fields with active consultation protection and audit logging.
  Future<bool> updateDoctorProfile({
    required DoctorProfile doctor,
    required String name,
    required String qualification,
    required String department,
    required String registeredPhone,
    String? email,
  }) async {
    final isDepartmentChanged = doctor.department.toLowerCase() != department.trim().toLowerCase();

    // 1. Safeguard: block department change if in consultation
    if (isDepartmentChanged && doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation) {
      _actionError = 'Cannot change department while doctor is currently in consultation.';
      notifyListeners();
      return false;
    }

    _isProcessingAction = true;
    _actionError = null;
    notifyListeners();

    try {
      await _doctorRepo.updateDoctorProfile(
        doctorId: doctor.doctorId,
        name: name.trim(),
        qualification: qualification.trim(),
        department: department.trim(),
        registeredPhone: registeredPhone.trim(),
        email: email?.trim(),
      );

      final idx = _doctors.indexWhere((d) => d.doctorId == doctor.doctorId);
      if (idx != -1) {
        _doctors[idx] = _doctors[idx].copyWith(
          name: name.trim(),
          qualification: qualification.trim(),
          department: department.trim(),
          registeredPhone: registeredPhone.trim(),
          email: email?.trim(),
          updatedAt: DateTime.now(),
        );
      }

      // Audit Log Event
      try {
        final currentAdmin = AdminAuthService.instance.currentSession?.username ?? 'admin01';
        final audit = AuditLog(
          auditId: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
          actorType: AuditActorType.admin.value,
          actorId: currentAdmin,
          action: isDepartmentChanged ? 'DOCTOR_DEPARTMENT_CHANGED' : 'DOCTOR_PROFILE_UPDATED',
          entityType: 'DOCTOR_PROFILE',
          entityId: doctor.doctorId,
          timestamp: DateTime.now(),
          metadata: {
            'doctorId': doctor.doctorId,
            'doctorUniqueCode': doctor.doctorUniqueCode,
            'oldDepartment': doctor.department,
            'newDepartment': department.trim(),
            'name': name.trim(),
            'qualification': qualification.trim(),
          },
        );
        await _auditRepo.logEvent(audit);
      } catch (e) {
        debugPrint('[AdminManageDoctorsController] Audit log error: $e');
      }

      _isProcessingAction = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessingAction = false;
      _actionError = 'Failed to update doctor profile: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
