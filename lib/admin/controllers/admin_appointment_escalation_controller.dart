import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/doctor_assignment_result.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/appointment_request.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/doctor_repository.dart';
import '../../services/appointment_escalation_policy.dart';
import '../services/admin_auth_service.dart';

/// State controller managing real-time monitoring, 20-minute SLA evaluation,
/// combinable filtering, and atomic manual doctor assignment for escalated appointments (Phase A7).
class AdminAppointmentEscalationController extends ChangeNotifier {
  static final AdminAppointmentEscalationController instance =
      AdminAppointmentEscalationController._();
  AdminAppointmentEscalationController._();
  factory AdminAppointmentEscalationController() => instance;

  AppointmentRepository? _customAppointmentRepository;
  DoctorRepository? _customDoctorRepository;

  AppointmentRepository get _appointmentRepo =>
      _customAppointmentRepository ?? BackendProvider.instance.appointmentRepository;
  DoctorRepository get _doctorRepo =>
      _customDoctorRepository ?? BackendProvider.instance.doctorRepository;

  List<AppointmentRequest> _allAppointments = [];
  List<DoctorProfile> _allDoctors = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedDepartment = 'all';
  String _selectedStatus = 'all'; // 'all', 'escalated', 'waiting', 'resolved'
  String _selectedSort = 'oldestWaiting'; // 'oldestWaiting', 'newest', 'department', 'escalationTime'

  StreamSubscription<List<AppointmentRequest>>? _appointmentSubscription;
  StreamSubscription<List<DoctorProfile>>? _doctorSubscription;

  /// Clock provider for deterministic time evaluation in testing and runtime
  DateTime Function() nowProvider = DateTime.now;

  // Getters
  List<AppointmentRequest> get allAppointments => _allAppointments;
  List<DoctorProfile> get allDoctors => _allDoctors;
  bool get isLoading => _isLoading;
  bool get isAssigning => _isAssigning;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  String get selectedStatus => _selectedStatus;
  String get selectedSort => _selectedSort;

  /// Real-time metric: Total Escalated Appointments (>20 min waiting without doctor)
  int get escalatedCount {
    final now = nowProvider();
    return _allAppointments.where((a) {
      final isWaiting = a.status == AppointmentStatus.waiting || a.status == AppointmentStatus.pending;
      final isUnassigned = a.assignedDoctorId == null || a.assignedDoctorId!.isEmpty;
      return isWaiting && isUnassigned && (a.isEscalated || AppointmentEscalationPolicy.shouldEscalate(a, now));
    }).length;
  }

  /// Real-time metric: Total Waiting Appointments
  int get waitingCount {
    return _allAppointments.where((a) {
      final isWaiting = a.status == AppointmentStatus.waiting || a.status == AppointmentStatus.pending;
      final isUnassigned = a.assignedDoctorId == null || a.assignedDoctorId!.isEmpty;
      return isWaiting && isUnassigned;
    }).length;
  }

  /// Real-time metric: Resolved Today (Escalated appointments successfully assigned)
  int get resolvedTodayCount {
    final now = nowProvider();
    return _allAppointments.where((a) {
      if (a.escalationStatus != AppointmentEscalationStatus.resolved &&
          a.status != AppointmentStatus.accepted &&
          a.status != AppointmentStatus.completed) {
        return false;
      }
      final dateToCheck = a.resolvedAt ?? a.assignedAt ?? a.updatedAt;
      return dateToCheck.year == now.year &&
          dateToCheck.month == now.month &&
          dateToCheck.day == now.day;
    }).length;
  }

  /// Initializes the controller and registers real-time subscriptions.
  Future<void> initialize({
    AppointmentRepository? appointmentRepository,
    DoctorRepository? doctorRepository,
  }) async {
    if (appointmentRepository != null) _customAppointmentRepository = appointmentRepository;
    if (doctorRepository != null) _customDoctorRepository = doctorRepository;

    if (_appointmentSubscription != null &&
        appointmentRepository == null &&
        doctorRepository == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _appointmentSubscription?.cancel();
    await _doctorSubscription?.cancel();

    try {
      // Initial fetch
      final appointments = await _appointmentRepo.getAllAppointments();
      final doctors = await _doctorRepo.getAllDoctorProfiles();

      _allAppointments = appointments;
      _allDoctors = doctors;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      // Trigger automatic escalation state mutation for any appointments that crossed 20 min
      _evaluateAndCommitEscalations();

      // Subscribe to live appointment stream
      _appointmentSubscription = _appointmentRepo.watchAllAppointments().listen(
        (updatedAppointments) {
          _allAppointments = updatedAppointments;
          _evaluateAndCommitEscalations();
          notifyListeners();
        },
        onError: (err) {
          debugPrint('[AdminAppointmentEscalationController] Appointment stream error: $err');
          _errorMessage = 'Live appointment stream interrupted.';
          notifyListeners();
        },
      );

      // Subscribe to live doctor presence stream
      _doctorSubscription = _doctorRepo.watchDoctorProfiles().listen(
        (updatedDoctors) {
          _allDoctors = updatedDoctors;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('[AdminAppointmentEscalationController] Doctor stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('[AdminAppointmentEscalationController] Initialization error: $e');
      _isLoading = false;
      _errorMessage = 'Unable to load appointment escalations.';
      notifyListeners();
    }
  }

  /// Internal: Safely checks for unassigned appointments crossing the 20-min threshold
  /// and marks them in the repository without generating duplicate events.
  void _evaluateAndCommitEscalations() {
    final now = nowProvider();
    for (final apt in _allAppointments) {
      if (apt.escalationStatus == AppointmentEscalationStatus.none &&
          AppointmentEscalationPolicy.shouldEscalate(apt, now)) {
        // Fire atomic escalation mutation
        _appointmentRepo.markAppointmentEscalated(apt.requestId).catchError((err) {
          debugPrint('[AdminAppointmentEscalationController] Escalation mark error: $err');
          return false;
        });
      }
    }
  }

  /// Refreshes state and re-evaluates escalations.
  Future<void> refresh() async {
    try {
      final appointments = await _appointmentRepo.getAllAppointments();
      final doctors = await _doctorRepo.getAllDoctorProfiles();
      _allAppointments = appointments;
      _allDoctors = doctors;
      _evaluateAndCommitEscalations();
      _errorMessage = null;
    } catch (e) {
      debugPrint('[AdminAppointmentEscalationController] Refresh error: $e');
      _errorMessage = 'Unable to reload appointment escalations.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter & Search Modifiers
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setDepartment(String department) {
    _selectedDepartment = department;
    notifyListeners();
  }

  void setStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSort(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedDepartment != 'all' ||
      _selectedStatus != 'all';

  void resetFilters() {
    _searchQuery = '';
    _selectedDepartment = 'all';
    _selectedStatus = 'all';
    _selectedSort = 'oldestWaiting';
    notifyListeners();
  }

  /// Returns filtered and deterministically sorted list of appointments.
  List<AppointmentRequest> get filteredAppointments {
    final now = nowProvider();
    var list = List<AppointmentRequest>.from(_allAppointments);

    // 1. Search filter: Queue Number or Appointment Request ID
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        return a.queueNumber.toLowerCase().contains(q) ||
            a.requestId.toLowerCase().contains(q) ||
            a.domainId.toLowerCase().contains(q);
      }).toList();
    }

    // 2. Department filter
    if (_selectedDepartment != 'all') {
      final targetDep = _normalizeDomainId(_selectedDepartment);
      list = list.where((a) => _normalizeDomainId(a.domainId) == targetDep).toList();
    }

    // 3. Status filter
    if (_selectedStatus != 'all') {
      list = list.where((a) {
        final isWaiting = a.status == AppointmentStatus.waiting || a.status == AppointmentStatus.pending;
        final isUnassigned = a.assignedDoctorId == null || a.assignedDoctorId!.isEmpty;
        final isEscalated = isWaiting && isUnassigned &&
            (a.isEscalated || AppointmentEscalationPolicy.shouldEscalate(a, now));

        switch (_selectedStatus) {
          case 'escalated':
            return isEscalated;
          case 'waiting':
            return isWaiting && isUnassigned && !isEscalated;
          case 'resolved':
            return a.isEscalationResolved ||
                a.status == AppointmentStatus.accepted ||
                a.status == AppointmentStatus.completed;
          default:
            return true;
        }
      }).toList();
    }

    // 4. Deterministic Sorting
    list.sort((a, b) {
      switch (_selectedSort) {
        case 'oldestWaiting':
          // FIFO: oldest createdAt first
          return a.createdAt.compareTo(b.createdAt);
        case 'newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'department':
          final cmp = a.domainId.toLowerCase().compareTo(b.domainId.toLowerCase());
          if (cmp != 0) return cmp;
          return a.createdAt.compareTo(b.createdAt);
        case 'escalationTime':
          final aTime = a.escalatedAt ?? a.createdAt;
          final bTime = b.escalatedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        default:
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    return list;
  }

  /// Computes the list of ONLY eligible doctors for manual assignment:
  /// 1. Doctor account is active (`isActive == true`).
  /// 2. Availability is `AVAILABLE` or `ONLINE` (not `OFFLINE`, not `IN_CONSULTATION`).
  /// 3. Doctor specialty department matches appointment domain.
  /// 4. If appointment is locked to a previous doctor (`PreferredDoctorMode.sameDoctor`), matches previous doctor ID.
  List<DoctorProfile> getEligibleDoctorsForAppointment(AppointmentRequest appointment) {
    final apptDomain = _normalizeDomainId(appointment.domainId);
    final prevDocId = appointment.previousDoctorId;
    final isSameDoctorLocked = appointment.preferredDoctorMode == PreferredDoctorMode.sameDoctor &&
        prevDocId != null &&
        prevDocId.isNotEmpty;

    return _allDoctors.where((doc) {
      // 1. Must be active
      if (!doc.isActive) return false;

      // 2. Must be Available (cannot assign Offline or In Consultation)
      if (doc.availabilityStatus != DoctorAvailabilityStatus.available &&
          doc.availabilityStatus != DoctorAvailabilityStatus.online) {
        return false;
      }

      // 3. Department matching
      final docDep = _normalizeDomainId(doc.department);
      if (apptDomain.isNotEmpty && docDep != apptDomain) {
        return false;
      }

      // 4. Previous doctor restriction
      if (isSameDoctorLocked && doc.doctorId != prevDocId) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Manually assigns an eligible physician to an escalated appointment.
  Future<DoctorAssignmentResult> assignDoctor({
    required String requestId,
    required String doctorId,
  }) async {
    _isAssigning = true;
    notifyListeners();

    try {
      final appt = _allAppointments.firstWhere(
        (a) => a.requestId == requestId,
        orElse: () => throw Exception('Appointment $requestId not found.'),
      );

      final adminId = AdminAuthService.instance.currentSession?.username ?? 'admin01';

      final result = await _appointmentRepo.adminAssignDoctor(
        requestId: requestId,
        doctorId: doctorId,
        doctorDomain: appt.domainId,
        adminId: adminId,
      );

      if (result.isSuccess) {
        await refresh();
      }

      return result;
    } catch (e) {
      debugPrint('[AdminAppointmentEscalationController] Assignment error: $e');
      return DoctorAssignmentResult.error(
        requestId: requestId,
        message: 'Unable to assign doctor: $e',
      );
    } finally {
      _isAssigning = false;
      notifyListeners();
    }
  }

  String _normalizeDomainId(String raw) {
    final lower = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '_');
    if (lower.contains('cardio')) return 'cardiology';
    if (lower.contains('neuro')) return 'neurology';
    if (lower.contains('gastro')) return 'gastroenterology';
    if (lower.contains('ortho')) return 'orthopedics';
    if (lower.contains('pediatric') || lower.contains('paediatric')) return 'pediatrics';
    if (lower.contains('ent')) return 'ent';
    if (lower.contains('derma')) return 'dermatology';
    if (lower.contains('general') || lower.contains('medicine')) return 'general_medicine';
    return lower;
  }

  @visibleForTesting
  void resetForTesting() {
    _appointmentSubscription?.cancel();
    _doctorSubscription?.cancel();
    _appointmentSubscription = null;
    _doctorSubscription = null;
    _allAppointments = [];
    _allDoctors = [];
    _isLoading = true;
    _isAssigning = false;
    _errorMessage = null;
    _searchQuery = '';
    _selectedDepartment = 'all';
    _selectedStatus = 'all';
    _selectedSort = 'oldestWaiting';
    nowProvider = DateTime.now;
    notifyListeners();
  }

  @override
  void dispose() {
    _appointmentSubscription?.cancel();
    _doctorSubscription?.cancel();
    super.dispose();
  }
}
