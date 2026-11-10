import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/doctor_profile.dart';
import '../models/doctor_provisioning_request.dart';
import '../services/doctor_provisioning_service.dart';
import '../services/firebase_doctor_provisioning_service.dart';
import '../services/mock_doctor_provisioning_service.dart';

/// State management controller for the Admin Doctor Provisioning form.
class AdminDoctorController extends ChangeNotifier {
  static final AdminDoctorController instance = AdminDoctorController._();
  AdminDoctorController._();
  factory AdminDoctorController() => instance;

  DoctorProvisioningService? _customService;

  void setCustomService(DoctorProvisioningService? service) {
    _customService = service;
  }

  DoctorProvisioningService get _service {
    if (_customService != null) return _customService!;
    if (BackendProvider.instance.isFirebaseMode) {
      return FirebaseDoctorProvisioningService();
    }
    return MockDoctorProvisioningService();
  }

  // Form Field Values
  String _name = '';
  String _mobile = '';
  String _qualification = '';
  String _department = '';
  String _email = '';

  // Field Errors
  String? _nameError;
  String? _mobileError;
  String? _qualificationError;
  String? _departmentError;
  String? _generalError;

  // Processing & Result State
  bool _isProvisioning = false;
  DoctorProfile? _provisionedDoctor;
  String? _temporaryPassword;

  // Getters
  String get name => _name;
  String get mobile => _mobile;
  String get qualification => _qualification;
  String get department => _department;
  String get email => _email;

  String? get nameError => _nameError;
  String? get mobileError => _mobileError;
  String? get qualificationError => _qualificationError;
  String? get departmentError => _departmentError;
  String? get generalError => _generalError;

  bool get isProvisioning => _isProvisioning;
  DoctorProfile? get provisionedDoctor => _provisionedDoctor;
  String? get temporaryPassword => _temporaryPassword;
  bool get isSuccess => _provisionedDoctor != null && _temporaryPassword != null;

  // Setters
  void setName(String value) {
    _name = value;
    if (_nameError != null) {
      _nameError = null;
      notifyListeners();
    }
  }

  void setMobile(String value) {
    _mobile = value;
    if (_mobileError != null) {
      _mobileError = null;
      notifyListeners();
    }
  }

  void setQualification(String value) {
    _qualification = value;
    if (_qualificationError != null) {
      _qualificationError = null;
      notifyListeners();
    }
  }

  void setDepartment(String value) {
    _department = value;
    _departmentError = null;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
  }

  /// Validates all input fields according to AAYUSATHI validation rules.
  bool validateForm() {
    bool isValid = true;
    _nameError = null;
    _mobileError = null;
    _qualificationError = null;
    _departmentError = null;
    _generalError = null;

    // 1. Name Validation
    final trimmedName = _name.trim();
    if (trimmedName.isEmpty) {
      _nameError = 'Doctor name is required.';
      isValid = false;
    } else if (trimmedName.length < 3) {
      _nameError = 'Doctor name must be at least 3 characters.';
      isValid = false;
    } else if (RegExp(r'^[0-9\W]+$').hasMatch(trimmedName)) {
      _nameError = 'Enter a valid doctor name.';
      isValid = false;
    }

    // 2. Mobile Validation (Indian 10-digit mobile)
    final cleanPhone = _mobile.replaceAll(RegExp(r'[\s\-\(\)\+]+'), '');
    final last10 = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
    if (cleanPhone.isEmpty) {
      _mobileError = 'Mobile number is required.';
      isValid = false;
    } else if (last10.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(last10)) {
      _mobileError = 'Enter a valid 10-digit mobile number.';
      isValid = false;
    }

    // 3. Qualification Validation
    final trimmedQual = _qualification.trim();
    if (trimmedQual.isEmpty) {
      _qualificationError = 'Qualification is required.';
      isValid = false;
    } else if (trimmedQual.length < 2) {
      _qualificationError = 'Enter a valid qualification / degree.';
      isValid = false;
    }

    // 4. Department Validation
    if (_department.trim().isEmpty) {
      _departmentError = 'Select a department.';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  /// Submits the provisioning request.
  Future<bool> submitProvisioning() async {
    if (_isProvisioning) return false; // Duplicate click prevention

    if (!validateForm()) {
      return false;
    }

    _isProvisioning = true;
    _generalError = null;
    notifyListeners();

    try {
      final request = DoctorProvisioningRequest(
        name: _name.trim(),
        registeredPhone: _mobile.trim(),
        qualification: _qualification.trim(),
        department: _department.trim(),
        email: _email.trim().isNotEmpty ? _email.trim() : null,
      );

      final result = await _service.provisionDoctor(request);

      if (result.isSuccess && result.doctorProfile != null && result.temporaryPassword != null) {
        _provisionedDoctor = result.doctorProfile;
        _temporaryPassword = result.temporaryPassword;
        _isProvisioning = false;
        notifyListeners();
        return true;
      } else {
        _generalError = result.errorMessage ?? 'Failed to provision doctor account.';
        _isProvisioning = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _generalError = 'An unexpected error occurred during doctor provisioning.';
      _isProvisioning = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears form inputs and sensitive ephemeral password state.
  void resetForm() {
    _name = '';
    _mobile = '';
    _qualification = '';
    _department = '';
    _email = '';
    _nameError = null;
    _mobileError = null;
    _qualificationError = null;
    _departmentError = null;
    _generalError = null;
    _isProvisioning = false;
    _provisionedDoctor = null;
    _temporaryPassword = null;
    notifyListeners();
  }

  /// Clears the single-use temporary password from memory.
  void clearPassword() {
    _temporaryPassword = null;
    notifyListeners();
  }
}
