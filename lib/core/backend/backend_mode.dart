import 'package:flutter/foundation.dart';
import '../../doctor/services/doctor_session_service.dart';
import '../../doctor/services/firebase_storage_service.dart';
import '../../doctor/services/mock_storage_service.dart';
import '../../doctor/services/storage_service.dart';
import '../../doctor/services/supabase_storage_service.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/audit_repository.dart';
import '../../repositories/case_repository.dart';
import '../../repositories/clinical_visit_repository.dart';
import '../../repositories/doctor_repository.dart';
import '../../repositories/firebase/firebase_appointment_repository.dart';
import '../../repositories/firebase/firebase_audit_repository.dart';
import '../../repositories/firebase/firebase_case_repository.dart';
import '../../repositories/firebase/firebase_clinical_visit_repository.dart';
import '../../repositories/firebase/firebase_doctor_repository.dart';
import '../../repositories/firebase/firebase_investigation_repository.dart';
import '../../repositories/firebase/firebase_patient_repository.dart';
import '../../repositories/firebase/firebase_report_repository.dart';
import '../../repositories/firebase/firebase_transfer_repository.dart';
import '../../repositories/firebase/firebase_visit_repository.dart';
import '../../repositories/firebase/firebase_vital_repository.dart';
import '../../repositories/investigation_repository.dart';
import '../../repositories/mock/mock_appointment_repository.dart';
import '../../repositories/mock/mock_audit_repository.dart';
import '../../repositories/mock/mock_case_repository.dart';
import '../../repositories/mock/mock_clinical_visit_repository.dart';
import '../../repositories/mock/mock_doctor_repository.dart';
import '../../repositories/mock/mock_investigation_repository.dart';
import '../../repositories/mock/mock_patient_repository.dart';
import '../../repositories/mock/mock_report_repository.dart';
import '../../repositories/mock/mock_transfer_repository.dart';
import '../../repositories/mock/mock_visit_repository.dart';
import '../../repositories/mock/mock_vital_repository.dart';
import '../../repositories/patient_repository.dart';
import '../../repositories/report_repository.dart';
import '../../repositories/transfer_repository.dart';
import '../../repositories/visit_repository.dart';
import '../../repositories/vital_repository.dart';
import '../auth/auth_service.dart';
import '../auth/firebase_auth_service.dart';
import '../auth/mock_auth_service.dart';
import '../firebase/firebase_initializer.dart';

/// Available backend persistence modes for the AAYUSATHI ecosystem.
enum BackendMode {
  /// Pure deterministic in-memory mock repositories (ideal for local testing, CI, and offline dev).
  mock,

  /// Live Google Cloud Firestore integration.
  firebase,
}

/// Central dependency provider orchestrating backend repositories and authentication
/// without scattering conditional checks inside UI widgets or screens.
class BackendProvider extends ChangeNotifier {
  static final BackendProvider instance = BackendProvider._();
  BackendProvider._();
  factory BackendProvider() => instance;

  BackendMode _mode = BackendMode.mock;

  // Mock repository & auth singletons
  final PatientRepository _mockPatientRepository = MockPatientRepository.instance;
  final AppointmentRepository _mockAppointmentRepository = MockAppointmentRepository.instance;
  final VitalRepository _mockVitalRepository = MockVitalRepository.instance;
  final VisitRepository _mockVisitRepository = MockVisitRepository.instance;
  final CaseRepository _mockCaseRepository = MockCaseRepository.instance;
  final ClinicalVisitRepository _mockClinicalVisitRepository = MockClinicalVisitRepository.instance;
  final DoctorRepository _mockDoctorRepository = MockDoctorRepository.instance;
  final AuditRepository _mockAuditRepository = MockAuditRepository.instance;
  final InvestigationRepository _mockInvestigationRepository = MockInvestigationRepository.instance;
  final ReportRepository _mockReportRepository = MockReportRepository.instance;
  final TransferRepository _mockTransferRepository = MockTransferRepository.instance;
  final StorageService _mockStorageService = MockStorageService.instance;
  final AuthService _mockAuthService = MockAuthService.instance;

  // Firebase repository & auth instances
  late final PatientRepository _firebasePatientRepository = FirebasePatientRepository();
  late final AppointmentRepository _firebaseAppointmentRepository = FirebaseAppointmentRepository();
  late final VitalRepository _firebaseVitalRepository = FirebaseVitalRepository();
  late final VisitRepository _firebaseVisitRepository = FirebaseVisitRepository();
  late final CaseRepository _firebaseCaseRepository = FirebaseCaseRepository();
  late final ClinicalVisitRepository _firebaseClinicalVisitRepository = FirebaseClinicalVisitRepository();
  late final DoctorRepository _firebaseDoctorRepository = FirebaseDoctorRepository();
  late final AuditRepository _firebaseAuditRepository = FirebaseAuditRepository();
  late final InvestigationRepository _firebaseInvestigationRepository = FirebaseInvestigationRepository();
  late final ReportRepository _firebaseReportRepository = FirebaseReportRepository();
  late final TransferRepository _firebaseTransferRepository = FirebaseTransferRepository();
  late final StorageService _supabaseStorageService = SupabaseStorageService();
  late final StorageService _firebaseStorageService = FirebaseStorageService();
  late final AuthService _firebaseAuthService = FirebaseAuthService();

  // Test overrides
  PatientRepository? _customPatientRepository;
  AppointmentRepository? _customAppointmentRepository;
  VitalRepository? _customVitalRepository;
  VisitRepository? _customVisitRepository;
  CaseRepository? _customCaseRepository;
  ClinicalVisitRepository? _customClinicalVisitRepository;
  DoctorRepository? _customDoctorRepository;
  AuditRepository? _customAuditRepository;
  InvestigationRepository? _customInvestigationRepository;
  ReportRepository? _customReportRepository;
  TransferRepository? _customTransferRepository;
  StorageService? _customStorageService;
  AuthService? _customAuthService;

  BackendMode get mode => _mode;
  bool get isFirebaseMode => _mode == BackendMode.firebase;

  /// Sets the active backend persistence mode.
  void setMode(BackendMode mode) {
    _mode = mode;
    debugPrint('[AAYUSATHI] Backend mode: ${mode.name.toUpperCase()}');
    debugPrint('[AAYUSATHI] PatientRepository: ${patientRepository.runtimeType}');
    debugPrint('[AAYUSATHI] AppointmentRepository: ${appointmentRepository.runtimeType}');
    debugPrint('[AAYUSATHI] VisitRepository: ${visitRepository.runtimeType}');
    notifyListeners();
  }

  /// Outputs full backend diagnostic log summary.
  void logDiagnostics() {
    debugPrint('[AAYUSATHI] Backend mode: ${_mode.name.toUpperCase()}');
    debugPrint('[AAYUSATHI] PatientRepository: ${patientRepository.runtimeType}');
    debugPrint('[AAYUSATHI] AppointmentRepository: ${appointmentRepository.runtimeType}');
    debugPrint('[AAYUSATHI] VitalRepository: ${vitalRepository.runtimeType}');
    debugPrint('[AAYUSATHI] VisitRepository: ${visitRepository.runtimeType}');
    debugPrint('[AAYUSATHI] DoctorRepository: ${doctorRepository.runtimeType}');
    debugPrint('[AAYUSATHI] AuditRepository: ${auditRepository.runtimeType}');
    debugPrint('[AAYUSATHI] InvestigationRepository: ${investigationRepository.runtimeType}');
    debugPrint('[AAYUSATHI] ReportRepository: ${reportRepository.runtimeType}');
    debugPrint('[AAYUSATHI] StorageService: ${storageService.runtimeType}');
    debugPrint('[AAYUSATHI] AuthService: ${authService.runtimeType}');
  }

  /// Active [PatientRepository] implementation.
  PatientRepository get patientRepository {
    if (_customPatientRepository != null) return _customPatientRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockPatientRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebasePatientRepository;
    }
    return _mockPatientRepository;
  }

  /// Active [AppointmentRepository] implementation.
  AppointmentRepository get appointmentRepository {
    if (_customAppointmentRepository != null) return _customAppointmentRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockAppointmentRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseAppointmentRepository;
    }
    return _mockAppointmentRepository;
  }

  /// Active [VitalRepository] implementation.
  VitalRepository get vitalRepository {
    if (_customVitalRepository != null) return _customVitalRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockVitalRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseVitalRepository;
    }
    return _mockVitalRepository;
  }

  /// Active [VisitRepository] implementation.
  VisitRepository get visitRepository {
    if (_customVisitRepository != null) return _customVisitRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockVisitRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseVisitRepository;
    }
    return _mockVisitRepository;
  }

  /// Active [CaseRepository] implementation.
  CaseRepository get caseRepository {
    if (_customCaseRepository != null) return _customCaseRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockCaseRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseCaseRepository;
    }
    return _mockCaseRepository;
  }

  /// Active [ClinicalVisitRepository] implementation.
  ClinicalVisitRepository get clinicalVisitRepository {
    if (_customClinicalVisitRepository != null) return _customClinicalVisitRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockClinicalVisitRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseClinicalVisitRepository;
    }
    return _mockClinicalVisitRepository;
  }

  /// Active [DoctorRepository] implementation.
  DoctorRepository get doctorRepository {
    if (_customDoctorRepository != null) return _customDoctorRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockDoctorRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseDoctorRepository;
    }
    return _mockDoctorRepository;
  }

  /// Active [AuditRepository] implementation.
  AuditRepository get auditRepository {
    if (_customAuditRepository != null) return _customAuditRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockAuditRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseAuditRepository;
    }
    return _mockAuditRepository;
  }

  /// Active [InvestigationRepository] implementation.
  InvestigationRepository get investigationRepository {
    if (_customInvestigationRepository != null) return _customInvestigationRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockInvestigationRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseInvestigationRepository;
    }
    return _mockInvestigationRepository;
  }

  /// Active [ReportRepository] implementation.
  ReportRepository get reportRepository {
    if (_customReportRepository != null) return _customReportRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockReportRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseReportRepository;
    }
    return _mockReportRepository;
  }

  /// Active [TransferRepository] implementation.
  TransferRepository get transferRepository {
    if (_customTransferRepository != null) return _customTransferRepository!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockTransferRepository;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseTransferRepository;
    }
    return _mockTransferRepository;
  }

  /// Active [StorageService] implementation.
  StorageService get storageService {
    if (_customStorageService != null) return _customStorageService!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockStorageService;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _supabaseStorageService;
    }
    return _mockStorageService;
  }

  /// Direct handle to the live Supabase Storage service.
  StorageService get supabaseStorageService => _supabaseStorageService;

  /// Direct handle to the legacy/fallback Firebase Storage service.
  StorageService get firebaseStorageService => _firebaseStorageService;

  /// Active [AuthService] implementation.
  AuthService get authService {
    if (_customAuthService != null) return _customAuthService!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return _mockAuthService;
    }
    if (isFirebaseMode && FirebaseInitializer.isInitialized) {
      return _firebaseAuthService;
    }
    return _mockAuthService;
  }

  /// Sets custom repository and auth overrides (for mock/unit testing).
  void setCustomRepositories({
    PatientRepository? patientRepo,
    AppointmentRepository? appointmentRepo,
    VitalRepository? vitalRepo,
    VisitRepository? visitRepo,
    CaseRepository? caseRepo,
    ClinicalVisitRepository? clinicalVisitRepo,
    DoctorRepository? doctorRepo,
    AuditRepository? auditRepo,
    InvestigationRepository? investigationRepo,
    ReportRepository? reportRepo,
    TransferRepository? transferRepo,
    StorageService? storageService,
    AuthService? authService,
  }) {
    _customPatientRepository = patientRepo;
    _customAppointmentRepository = appointmentRepo;
    _customVitalRepository = vitalRepo;
    _customVisitRepository = visitRepo;
    _customCaseRepository = caseRepo;
    _customClinicalVisitRepository = clinicalVisitRepo;
    _customDoctorRepository = doctorRepo;
    _customAuditRepository = auditRepo;
    _customInvestigationRepository = investigationRepo;
    _customReportRepository = reportRepo;
    _customTransferRepository = transferRepo;
    _customStorageService = storageService;
    _customAuthService = authService;
    notifyListeners();
  }

  /// Clears all custom test overrides and resets to default mode.
  void resetOverrides() {
    _customPatientRepository = null;
    _customAppointmentRepository = null;
    _customVitalRepository = null;
    _customVisitRepository = null;
    _customCaseRepository = null;
    _customClinicalVisitRepository = null;
    _customDoctorRepository = null;
    _customAuditRepository = null;
    _customInvestigationRepository = null;
    _customReportRepository = null;
    _customTransferRepository = null;
    _customStorageService = null;
    _customAuthService = null;
    notifyListeners();
  }
}
