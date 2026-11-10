import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../models/patient.dart';
import '../../repositories/patient_repository.dart';
import '../models/patient_app_state.dart';

/// Read-only controller for patient demographic data.
/// Strictly non-editable by patient; strictly zero Aadhaar exposure.
class PatientProfileController extends ChangeNotifier {
  final PatientRepository _patientRepo;

  PatientProfileController({PatientRepository? patientRepo})
      : _patientRepo = patientRepo ?? BackendProvider.instance.patientRepository;

  Patient? _patient;
  bool _isLoading = false;
  String? _errorMessage;

  Patient? get patient => _patient ?? PatientAppState.instance.currentPatient;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  String get fullName => patient?.name ?? 'Patient';
  String get patientId => patient?.patientId ?? (PatientAppState.instance.authenticatedPatientId ?? 'N/A');
  String get age => patient != null ? '${patient!.age} yrs' : 'N/A';
  String get gender => patient?.gender ?? 'N/A';
  String get bloodGroup => patient?.bloodGroup ?? 'N/A';
  String get registeredMobile {
    final p = patient;
    if (p == null || p.phone.isEmpty) return 'N/A';
    if (p.phone.length >= 4) {
      final last4 = p.phone.substring(p.phone.length - 4);
      return '******$last4';
    }
    return '******';
  }

  Future<void> loadProfile({bool force = false}) async {
    if (_patient != null && !force) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = PatientAppState.instance.authenticatedPatientId;
      if (id != null && id.isNotEmpty) {
        _patient = await _patientRepo.getPatientById(id);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load patient profile.';
      notifyListeners();
    }
  }
}
