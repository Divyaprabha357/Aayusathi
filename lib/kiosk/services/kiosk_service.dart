import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../models/appointment_request.dart';
import '../../models/audit_log.dart';
import '../../models/opd_domain.dart';
import '../../models/patient.dart';
import '../../models/previous_visit_record.dart';
import '../../models/vital_reading.dart';
import '../../services/appointment_service.dart';
import '../../services/arduino/arduino_service.dart';
import '../../services/arduino/demo_reading_provider.dart';
import '../../services/doctor_availability_service.dart';
import '../../services/previous_visit_service.dart';
import '../../services/vital_validation_service.dart';
import '../models/kiosk_session.dart';
import '../models/patient_identity.dart';
import 'aadhaar_service.dart';
import 'otp_service.dart';
import 'patient_id_service.dart';
import 'patient_lookup_service.dart';

/// Central state manager responsible for Kiosk hardware, active language,
/// patient identification workflow, OTP verification, vital telemetry,
/// OPD domain routing, appointment requests, and strict privacy resets.
class KioskService extends ChangeNotifier {
  static final KioskService instance = KioskService._();
  KioskService._();
  factory KioskService() => instance;

  final AadhaarService aadhaarService = RepositoryAadhaarService();
  final PatientIdService patientIdService = StandardPatientIdService();
  final PatientLookupService patientLookupService = RepositoryPatientLookupService();
  final OtpService otpService = MockOtpService();
  ArduinoService arduinoService = ArduinoService();

  @visibleForTesting
  void setArduinoServiceForTesting(ArduinoService service) {
    arduinoService = service;
  }
  final VitalValidationService vitalValidationService = const VitalValidationService();
  final DoctorAvailabilityService doctorAvailabilityService = MockDoctorAvailabilityService();
  final PreviousVisitService previousVisitService = RepositoryPreviousVisitService();
  late final AppointmentService appointmentService = MockAppointmentService(
    doctorAvailabilityService: doctorAvailabilityService,
  );

  KioskLocale _activeLocale = KioskLocale.english;
  KioskSession? _currentSession;
  UserType? _userType;
  PatientIdentity? _identifiedPatient;
  String _activeAadhaarInput = '';
  String _activePatientIdInput = '';
  String _activeMobileInput = '';
  PatientIdentity? _temporaryAadhaarData;
  String? _activeAadhaarPhone;
  String? _activeAadhaarMaskedPhone;
  bool _isOtpVerified = false;

  VitalReading? _currentVitalReading;
  VitalValidationResult? _vitalValidationResult;

  OpdDomain? _selectedDomain;
  PreviousVisitRecord? _currentPreviousVisitRecord;
  AppointmentRequest? _currentAppointmentRequest;

  KioskLocale get activeLocale => _activeLocale;
  KioskSession? get currentSession => _currentSession;
  UserType? get userType => _userType;
  PatientIdentity? get identifiedPatient => _identifiedPatient;
  String get activeAadhaarInput => _activeAadhaarInput;
  String get activePatientIdInput => _activePatientIdInput;
  String get activeMobileInput => _activeMobileInput;
  PatientIdentity? get temporaryAadhaarData => _temporaryAadhaarData;
  String? get activeAadhaarPhone => _activeAadhaarPhone;
  String? get activeAadhaarMaskedPhone => _activeAadhaarMaskedPhone;
  bool get isOtpVerified => _isOtpVerified;
  VitalReading? get currentVitalReading => _currentVitalReading;
  VitalValidationResult? get vitalValidationResult => _vitalValidationResult;

  OpdDomain? get selectedDomain => _selectedDomain;
  PreviousVisitRecord? get currentPreviousVisitRecord => _currentPreviousVisitRecord;
  AppointmentRequest? get currentAppointmentRequest => _currentAppointmentRequest;

  bool get hasActiveSession =>
      _currentSession != null && _currentSession!.status != KioskSessionStatus.idle;

  /// Sets the temporary language for the current kiosk session.
  void setLocale(KioskLocale locale) {
    if (_activeLocale != locale) {
      _activeLocale = locale;
      notifyListeners();
    }
  }

  /// Sets whether the patient is a first-time registered user or an existing hospital patient.
  void setUserType(UserType type) {
    _userType = type;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(userType: type);
    }
    notifyListeners();
  }

  /// Starts a fresh kiosk session.
  void startNewSession() {
    _currentSession = KioskSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      status: KioskSessionStatus.idle,
      startedAt: DateTime.now(),
    );
    _userType = null;
    _identifiedPatient = null;
    _activeAadhaarInput = '';
    _activePatientIdInput = '';
    _activeMobileInput = '';
    _temporaryAadhaarData = null;
    _activeAadhaarPhone = null;
    _activeAadhaarMaskedPhone = null;
    _isOtpVerified = false;
    _currentVitalReading = null;
    _vitalValidationResult = null;
    _selectedDomain = null;
    _currentPreviousVisitRecord = null;
    _currentAppointmentRequest = null;
    otpService.reset();
    arduinoService.stopReading();
    arduinoService.disconnect();
    arduinoService.reset();
    DemoReadingProvider.instance.reset();
    notifyListeners();

  }

  /// Updates temporary Aadhaar input during active New User session.
  void setAadhaarInput(String value) {
    _activeAadhaarInput = value;
    notifyListeners();
  }

  /// Sets temporary demographic identity data fetched from Aadhaar lookup.
  void setTemporaryAadhaarData(PatientIdentity? data) {
    _temporaryAadhaarData = data;
    notifyListeners();
  }

  /// Sets manual mobile number entered by New User for registration.
  void setActiveMobileInput(String value) {
    _activeMobileInput = value;
    notifyListeners();
  }

  /// Sets temporary phone metadata linked to Aadhaar input for OTP dispatch.
  void setActiveAadhaarOtpData({required String phone, required String maskedPhone}) {
    _activeAadhaarPhone = phone;
    _activeAadhaarMaskedPhone = maskedPhone;
    notifyListeners();
  }

  /// Updates temporary Patient ID input during active Existing Patient session.
  void setPatientIdInput(String value) {
    _activePatientIdInput = value;
    notifyListeners();
  }

  /// Sets the patient identity once authenticated/identified at the kiosk.
  void setIdentifiedPatient(PatientIdentity patient) {
    _identifiedPatient = patient;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        patientId: patient.patientId,
        status: KioskSessionStatus.patientIdentified,
      );
    }
    // Async save to repository (enforcing duplicate check for new registrations)
    final patientRecord = Patient.fromPatientIdentity(patient);
    if (patient.isNewRegistration) {
      BackendProvider.instance.patientRepository.createPatient(patientRecord).catchError((e) {
        debugPrint('[KioskService] Failed to create new patient record: $e');
      });
    } else {
      BackendProvider.instance.patientRepository.savePatient(patientRecord).catchError((e) {
        debugPrint('[KioskService] Failed to persist patient record: $e');
      });
    }
    BackendProvider.instance.auditRepository.logEvent(
      AuditLog(
        auditId: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        actorType: 'KIOSK',
        actorId: 'KIOSK-01',
        action: patient.isNewRegistration ? 'PATIENT_REGISTERED' : 'PATIENT_VERIFIED',
        entityType: 'PATIENT',
        entityId: patient.patientId,
        timestamp: DateTime.now(),
      ),
    ).catchError((e) {
      debugPrint('[KioskService] Failed to log audit event: $e');
    });
    notifyListeners();
  }

  /// Sets whether the patient's phone number OTP is successfully verified.
  void setOtpVerified(bool value) {
    _isOtpVerified = value;
    notifyListeners();
  }

  /// Sets temporary vital reading captured during session.
  void setVitalReading(VitalReading reading) {
    _currentVitalReading = reading;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        status: KioskSessionStatus.vitalsMeasuring,
      );
    }
    if (_identifiedPatient != null) {
      BackendProvider.instance.vitalRepository.saveVitalReading(
        patientId: _identifiedPatient!.patientId,
        reading: reading,
        appointmentId: _currentAppointmentRequest?.requestId,
      ).catchError((e) {
        debugPrint('[KioskService] Failed to persist vitals: $e');
      });
    }
    notifyListeners();
  }

  /// Sets clinical validation result for the patient's vitals.
  void setVitalValidationResult(VitalValidationResult result) {
    _vitalValidationResult = result;
    notifyListeners();
  }

  /// Sets selected OPD clinical domain for the active patient consultation.
  void setSelectedDomain(OpdDomain domain) {
    _selectedDomain = domain;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        domainId: domain.id,
      );
    }
    notifyListeners();
  }

  /// Sets previous visit record if verified for the active department.
  void setPreviousVisitRecord(PreviousVisitRecord? record) {
    _currentPreviousVisitRecord = record;
    notifyListeners();
  }

  /// Sets created appointment request with sequential queue ticket.
  void setAppointmentRequest(AppointmentRequest request) {
    _currentAppointmentRequest = request;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        queueNumber: request.queueNumber,
        status: KioskSessionStatus.consultationPending,
      );
    }
    BackendProvider.instance.appointmentRepository.saveAppointment(request).catchError((e) {
      debugPrint('[KioskService] Failed to persist appointment: $e');
    });
    BackendProvider.instance.auditRepository.logEvent(
      AuditLog(
        auditId: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        actorType: 'KIOSK',
        actorId: 'KIOSK-01',
        action: 'APPOINTMENT_CREATED',
        entityType: 'APPOINTMENT',
        entityId: request.requestId,
        timestamp: DateTime.now(),
        metadata: {
          'queueNumber': request.queueNumber,
          'domainId': request.domainId,
          'status': request.status.name,
        },
      ),
    ).catchError((e) {
      debugPrint('[KioskService] Failed to log appointment audit: $e');
    });
    notifyListeners();
  }

  /// Atomically books, allocates sequential queue number, and persists appointment and visit history.
  /// Also logs governance audit trails. Throws [BackendException] if persistence or queue fails.
  Future<AppointmentRequest> bookAndPersistAppointment({
    required String patientId,
    required String domainId,
    String? previousDoctorId,
    required PreferredDoctorMode preferredDoctorMode,
  }) async {
    final sessionId = _currentSession?.sessionId ?? 'SESS-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Create and atomically persist appointment with sequential queue number and captured vitals
    final savedAppointment = await appointmentService.createAndPersistAppointmentRequest(
      patientId: patientId,
      domainId: domainId,
      sessionId: sessionId,
      previousDoctorId: previousDoctorId,
      preferredDoctorMode: preferredDoctorMode,
      vitals: _currentVitalReading,
    );

    // 2. Update session state
    _currentAppointmentRequest = savedAppointment;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        queueNumber: savedAppointment.queueNumber,
        status: KioskSessionStatus.consultationPending,
      );
    }

    // 2b. Link captured vitals with the allocated appointment ID in the vitals repository
    if (_currentVitalReading != null) {
      BackendProvider.instance.vitalRepository.saveVitalReading(
        patientId: patientId,
        reading: _currentVitalReading!,
        appointmentId: savedAppointment.requestId,
      ).catchError((e) {
        debugPrint('[KioskService] Failed to link vitals to appointment: $e');
      });
    }

    // 3. Persist visit record in visits/ collection with status 'queued' or 'requested'
    final visitId = 'VIS-${DateTime.now().millisecondsSinceEpoch}-$patientId';
    final visitRecord = PreviousVisitRecord(
      visitId: visitId,
      patientId: patientId,
      domainId: domainId,
      previousDoctorId: previousDoctorId ?? '',
      lastVisitDate: DateTime.now(),
      appointmentId: savedAppointment.requestId,
      status: savedAppointment.status == AppointmentStatus.waiting ? 'queued' : 'requested',
    );

    BackendProvider.instance.visitRepository.saveVisit(visitRecord).catchError((e) {
      debugPrint('[KioskService] Failed to record visit record: $e');
    });

    // 4. Log audit trails
    BackendProvider.instance.auditRepository.logEvent(
      AuditLog(
        auditId: 'AUD-${DateTime.now().millisecondsSinceEpoch}-APPT',
        actorType: 'KIOSK',
        actorId: 'KIOSK-01',
        action: 'APPOINTMENT_CREATED',
        entityType: 'APPOINTMENT',
        entityId: savedAppointment.requestId,
        timestamp: DateTime.now(),
        metadata: {
          'queueNumber': savedAppointment.queueNumber,
          'domainId': savedAppointment.domainId,
          'status': savedAppointment.status.name,
          'patientId': patientId,
        },
      ),
    ).catchError((e) {
      debugPrint('[KioskService] Failed to log appointment audit: $e');
    });

    BackendProvider.instance.auditRepository.logEvent(
      AuditLog(
        auditId: 'AUD-${DateTime.now().millisecondsSinceEpoch}-QUEUE',
        actorType: 'KIOSK',
        actorId: 'KIOSK-01',
        action: 'QUEUE_GENERATED',
        entityType: 'QUEUE',
        entityId: savedAppointment.queueNumber,
        timestamp: DateTime.now(),
        metadata: {
          'appointmentId': savedAppointment.requestId,
          'domainId': savedAppointment.domainId,
          'patientId': patientId,
        },
      ),
    ).catchError((e) {
      debugPrint('[KioskService] Failed to log queue audit: $e');
    });

    notifyListeners();
    return savedAppointment;
  }

  /// Sets the patient ID once authenticated/identified at the kiosk.
  void setPatient(String patientId) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        patientId: patientId,
        status: KioskSessionStatus.patientIdentified,
      );
      notifyListeners();
    }
  }

  /// STRICT PRIVACY: Resets the kiosk back to Standby, completely wiping
  /// all entered Aadhaar digits, Patient IDs, OTP state, identified patient details,
  /// temporary vitals, selected domain, previous visit, appointment requests,
  /// session tokens, and restoring language to default English.
  void resetSession() {
    _currentSession = null;
    _userType = null;
    _identifiedPatient = null;
    _activeAadhaarInput = '';
    _activePatientIdInput = '';
    _activeMobileInput = '';
    _temporaryAadhaarData = null;
    _activeAadhaarPhone = null;
    _activeAadhaarMaskedPhone = null;
    _isOtpVerified = false;
    _currentVitalReading = null;
    _vitalValidationResult = null;
    _selectedDomain = null;
    _currentPreviousVisitRecord = null;
    _currentAppointmentRequest = null;
    otpService.reset();
    arduinoService.stopReading();
    arduinoService.disconnect();
    arduinoService.reset();
    DemoReadingProvider.instance.reset();
    _activeLocale = KioskLocale.english; // Language strictly resets for the next patient

    notifyListeners();
  }
}
