import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/doctor_profile.dart';

/// Orchestration controller for Phase A10 Higher-Authority Doctor Assignment workflow.
///
/// Responsibilities:
/// 1. Inspects case metadata to determine source doctor identity & baseline authority level.
/// 2. Streams real-time doctor profiles and dynamically filters eligible higher-authority physicians.
/// 3. Validates cross-department routing rationale and selection constraints.
/// 4. Executes atomic transactional assignment via [CaseRepository].
class AdminHigherAuthorityAssignmentController extends ChangeNotifier {
  final ClinicalCase clinicalCase;
  final String adminId;

  AdminHigherAuthorityAssignmentController({
    required this.clinicalCase,
    required this.adminId,
  });

  bool _isLoading = true;
  bool _isAssigning = false;
  bool _isSuccess = false;
  String? _errorMessage;

  DoctorProfile? _sourceDoctor;
  int _sourceAuthorityLevel = 1;

  List<DoctorProfile> _allDoctors = [];
  DoctorProfile? _selectedDoctor;
  bool _isCrossDepartment = false;
  String _crossDepartmentReason = '';

  StreamSubscription<List<DoctorProfile>>? _doctorSubscription;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAssigning => _isAssigning;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;

  DoctorProfile? get sourceDoctor => _sourceDoctor;
  int get sourceAuthorityLevel => _sourceAuthorityLevel;

  DoctorProfile? get selectedDoctor => _selectedDoctor;
  bool get isCrossDepartment => _isCrossDepartment;
  String get crossDepartmentReason => _crossDepartmentReason;

  /// Returns list of doctors strictly satisfying all 11 eligibility rules:
  /// 1. Active account (`isActive == true`)
  /// 2. Available presence (`availabilityStatus == available`)
  /// 3. Authority level > source doctor authority level
  /// 4. Department matching (or cross-department enabled)
  /// 5. Not the source doctor
  List<DoctorProfile> get eligibleDoctors {
    String normalize(String s) => s.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    final caseDomain = normalize(clinicalCase.domain);
    final sourceId = clinicalCase.escalatedByDoctorId?.trim().toUpperCase();

    return _allDoctors.where((d) {
      if (!d.isActive) return false;
      if (d.availabilityStatus != DoctorAvailabilityStatus.available) return false;
      if (d.clinicalAuthorityLevel <= _sourceAuthorityLevel) return false;
      if (sourceId != null && d.doctorId.trim().toUpperCase() == sourceId) return false;

      if (!_isCrossDepartment) {
        final docDept = normalize(d.department);
        if (docDept != caseDomain) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // Sort highest authority first, then alphabetical by name
        final authComp = b.clinicalAuthorityLevel.compareTo(a.clinicalAuthorityLevel);
        if (authComp != 0) return authComp;
        return a.name.compareTo(b.name);
      });
  }

  /// Initializes controller, loads source doctor authority, and streams doctors.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doctorRepo = BackendProvider.instance.doctorRepository;

      // 1. Resolve source doctor profile & authority level
      final sourceDocId = clinicalCase.escalatedByDoctorId;
      if (sourceDocId != null && sourceDocId.isNotEmpty) {
        _sourceDoctor = await doctorRepo.getDoctorProfileById(sourceDocId);
        if (_sourceDoctor != null) {
          _sourceAuthorityLevel = _sourceDoctor!.clinicalAuthorityLevel;
        }
      }

      // 2. Stream all doctor profiles
      _doctorSubscription?.cancel();
      _doctorSubscription = doctorRepo.watchDoctorProfiles().listen(
        (doctors) {
          _allDoctors = doctors;
          // If previously selected doctor is no longer eligible or available, clear selection
          if (_selectedDoctor != null) {
            final isStillEligible = eligibleDoctors.any((d) => d.doctorId == _selectedDoctor!.doctorId);
            if (!isStillEligible) {
              _selectedDoctor = null;
            }
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (err) {
          _errorMessage = 'Failed to load doctors: $err';
          _isLoading = false;
          notifyListeners();
        },
      );

      // Fallback initial one-shot load
      _allDoctors = await doctorRepo.getAllDoctorProfiles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize assignment workspace: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDoctor(DoctorProfile? doctor) {
    _selectedDoctor = doctor;
    _errorMessage = null;
    notifyListeners();
  }

  void toggleCrossDepartment(bool value) {
    _isCrossDepartment = value;
    if (!_isCrossDepartment) {
      _crossDepartmentReason = '';
      // If selected doctor was from another department, reset selection
      if (_selectedDoctor != null &&
          _selectedDoctor!.department.trim().toLowerCase() !=
              clinicalCase.domain.trim().toLowerCase()) {
        _selectedDoctor = null;
      }
    }
    notifyListeners();
  }

  void setCrossDepartmentReason(String reason) {
    _crossDepartmentReason = reason;
    notifyListeners();
  }

  /// Executes atomic transactional assignment to the selected higher-authority physician.
  Future<ClinicalCase?> assignHigherAuthority() async {
    if (_selectedDoctor == null) {
      _errorMessage = 'Please select an eligible higher-authority doctor.';
      notifyListeners();
      return null;
    }

    if (_isCrossDepartment && _crossDepartmentReason.trim().isEmpty) {
      _errorMessage = 'Please provide a clinical rationale for cross-department transfer.';
      notifyListeners();
      return null;
    }

    _isAssigning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final caseRepo = BackendProvider.instance.caseRepository;
      final updatedCase = await caseRepo.assignHigherAuthorityDoctor(
        patientId: clinicalCase.patientId,
        caseId: clinicalCase.caseId,
        targetDoctorId: _selectedDoctor!.doctorId,
        targetDoctorName: _selectedDoctor!.name,
        targetDepartment: _selectedDoctor!.department,
        assignedByAdminId: adminId,
        crossDepartmentReason: _isCrossDepartment ? _crossDepartmentReason.trim() : null,
      );

      _isAssigning = false;
      _isSuccess = true;
      notifyListeners();
      return updatedCase;
    } on BackendException catch (e) {
      _errorMessage = e.message;
      _isAssigning = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during assignment: $e';
      _isAssigning = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _doctorSubscription?.cancel();
    super.dispose();
  }
}
