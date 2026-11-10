import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_config.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../models/patient_identity.dart';
import 'mock_patient_repository.dart';

/// Result status for an Aadhaar identity lookup.
class AadhaarLookupResult {
  final bool isSuccess;
  final PatientIdentity? patient;
  final String? errorCode;
  final bool isAlreadyRegistered;

  const AadhaarLookupResult.success(
    this.patient, {
    this.isAlreadyRegistered = false,
  })  : isSuccess = true,
        errorCode = null;

  const AadhaarLookupResult.alreadyRegistered([this.patient])
      : isSuccess = true,
        isAlreadyRegistered = true,
        errorCode = 'ALREADY_REGISTERED';

  const AadhaarLookupResult.failure(this.errorCode)
      : isSuccess = false,
        isAlreadyRegistered = false,
        patient = null;

  bool get aadhaarVerified => isSuccess && !isAlreadyRegistered;
  String? get fullName => patient?.fullName;
  String? get dob => patient?.dob;
  int? get age => patient?.age;
  String? get gender => patient?.gender;
  String? get address => patient?.address;
  String? get bloodGroup => patient?.bloodGroup;
  String? get aadhaarNumber => patient?.aadhaarNumber;
}

/// Result status for initiating an Aadhaar OTP verification step.
/// Validates Aadhaar existence and provides linked phone without exposing demographic identity data.
class AadhaarOtpResult {
  final bool isSuccess;
  final String? phone;
  final String? maskedPhone;
  final String? errorCode;

  const AadhaarOtpResult.success({
    required this.phone,
    required this.maskedPhone,
  })  : isSuccess = true,
        errorCode = null;

  const AadhaarOtpResult.failure(this.errorCode)
      : isSuccess = false,
        phone = null,
        maskedPhone = null;
}

/// Abstract contract for Aadhaar identity lookup.
/// Decouples UI from mock vs production implementation.
abstract class AadhaarService {
  Future<AadhaarLookupResult> verifyAadhaar(String aadhaarNumber, {bool simulateDelay = true});
  Future<AadhaarOtpResult> initiateOtp(String aadhaarNumber, {bool simulateDelay = true});
  Future<bool> isAadhaarRegistered(String aadhaarNumber, {bool simulateDelay = true});
}

/// Mock implementation querying the controlled fictional dataset.
class MockAadhaarService implements AadhaarService {
  final MockPatientRepository _repository;
  bool simulateDelay;

  MockAadhaarService({MockPatientRepository? repository, this.simulateDelay = true})
      : _repository = repository ?? MockPatientRepository.instance;

  @override
  Future<bool> isAadhaarRegistered(
    String aadhaarNumber, {
    bool? simulateDelay,
  }) async {
    final cleanDigits = aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleanDigits.length != 12 || !RegExp(r'^\d{12}$').hasMatch(cleanDigits)) {
      return false;
    }
    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _repository.isAadhaarRegistered(cleanDigits);
  }

  @override
  Future<AadhaarOtpResult> initiateOtp(
    String aadhaarNumber, {
    bool? simulateDelay,
  }) async {
    final cleanDigits = aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();

    // 1. Validation: exactly 12 numeric digits
    if (cleanDigits.length != 12 || !RegExp(r'^\d{12}$').hasMatch(cleanDigits)) {
      return const AadhaarOtpResult.failure('INVALID_FORMAT');
    }

    // 2. Simulated network latency
    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 350));
    }

    // 3. Query controlled mock repository for existence and linked phone only
    final patient = _repository.findByAadhaar(cleanDigits);
    if (patient != null) {
      return AadhaarOtpResult.success(
        phone: patient.phone,
        maskedPhone: patient.maskedPhone,
      );
    } else {
      return const AadhaarOtpResult.failure('NOT_FOUND');
    }
  }

  @override
  Future<AadhaarLookupResult> verifyAadhaar(
    String aadhaarNumber, {
    bool? simulateDelay,
  }) async {
    final cleanDigits = aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();

    // 1. Validation: exactly 12 numeric digits
    if (cleanDigits.length != 12 || !RegExp(r'^\d{12}$').hasMatch(cleanDigits)) {
      return const AadhaarLookupResult.failure('INVALID_FORMAT');
    }

    // Explicit test failure trigger (e.g. 999988887777 or 000000000000)
    if (cleanDigits == '999988887777' || cleanDigits == '000000000000') {
      return const AadhaarLookupResult.failure('NOT_FOUND');
    }

    // 2. Simulated network latency for realistic Kiosk feel
    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 350));
    }

    // 3. Query controlled mock repository
    final existing = _repository.findByAadhaar(cleanDigits);
    if (existing != null) {
      final isRegistered = existing.patientId.trim().isNotEmpty;
      // CRITICAL: Phone number must NOT come from Aadhaar lookup
      final sanitized = existing.copyWith(
        phone: '',
        patientId: isRegistered ? existing.patientId : '',
        isNewRegistration: !isRegistered,
      );
      if (isRegistered) {
        return AadhaarLookupResult.alreadyRegistered(sanitized);
      } else {
        return AadhaarLookupResult.success(sanitized);
      }
    }

    // 4. For new fake 12-digit Aadhaar entries in manual/automated test scenarios:
    // Generate deterministic mock demographic data (strictly zero phone, zero patientId).
    final mockPatient = _generateMockDemographics(cleanDigits);
    return AadhaarLookupResult.success(mockPatient);
  }

  PatientIdentity _generateMockDemographics(String cleanDigits) {
    // Deterministic selection based on digits
    final seed = int.tryParse(cleanDigits.substring(cleanDigits.length - 2)) ?? 42;
    final isFemale = seed % 2 == 1;
    final names = isFemale
        ? ['Ananya Joshi', 'Meera Kulkarni', 'Kavita Shinde', 'Pooja Patil']
        : ['Suresh More', 'Vikram Deshmukh', 'Amit Gaikwad', 'Ramesh Kumar'];
    final bloodGroups = ['O+', 'B+', 'A+', 'AB+', 'O-'];

    return PatientIdentity(
      aadhaarNumber: cleanDigits,
      patientId: '', // Brand new, no patientId
      fullName: names[seed % names.length],
      dob: '15 Aug ${1980 + (seed % 25)}',
      age: 46 - (seed % 25),
      gender: isFemale ? 'Female' : 'Male',
      phone: '', // STRICTLY ZERO PHONE FROM AADHAAR
      address: 'Flat ${(seed * 7) % 500 + 101}, Shanti Vihar, Pune, Maharashtra 411001',
      bloodGroup: bloodGroups[seed % bloodGroups.length],
      isNewRegistration: true,
    );
  }
}

/// Production repository-backed Aadhaar service.
/// Dynamically queries Cloud Firestore `/demo_aadhaar/{aadharNumber}` when in Firebase mode,
/// and falls back smoothly to [MockAadhaarService] when in Mock mode or offline.
class RepositoryAadhaarService extends MockAadhaarService {
  final FirebaseFirestore? _customFirestore;

  RepositoryAadhaarService({
    super.repository,
    super.simulateDelay = true,
    FirebaseFirestore? firestore,
  }) : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  bool get _isFirebaseActive =>
      FirebaseInitializer.isInitialized && BackendProvider.instance.isFirebaseMode;

  @override
  Future<bool> isAadhaarRegistered(
    String aadhaarNumber, {
    bool? simulateDelay,
  }) async {
    final cleanDigits = aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleanDigits.length != 12 || !RegExp(r'^\d{12}$').hasMatch(cleanDigits)) {
      return false;
    }

    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_isFirebaseActive) {
      try {
        final doc = await _firestore
            .collection(FirebaseConfig.demoAadhaarCollection)
            .doc(cleanDigits)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final isReg = data['isRegistered'] == true ||
              (data['patientId'] is String && (data['patientId'] as String).trim().isNotEmpty);
          if (isReg) return true;
        }
      } catch (e) {
        debugPrint('[RepositoryAadhaarService] isAadhaarRegistered error: $e');
      }
    }

    return super.isAadhaarRegistered(cleanDigits, simulateDelay: false);
  }

  @override
  Future<AadhaarLookupResult> verifyAadhaar(
    String aadhaarNumber, {
    bool? simulateDelay,
  }) async {
    final cleanDigits = aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();

    // 1. Validation: exactly 12 numeric digits
    if (cleanDigits.length != 12 || !RegExp(r'^\d{12}$').hasMatch(cleanDigits)) {
      return const AadhaarLookupResult.failure('INVALID_FORMAT');
    }

    // Explicit test failure triggers (e.g. 999988887777 or 000000000000)
    if (cleanDigits == '999988887777' || cleanDigits == '000000000000') {
      return const AadhaarLookupResult.failure('NOT_FOUND');
    }

    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 350));
    }

    // 2. Query Cloud Firestore if Firebase mode is active
    if (_isFirebaseActive) {
      try {
        final doc = await _firestore
            .collection(FirebaseConfig.demoAadhaarCollection)
            .doc(cleanDigits)
            .get();

        if (!doc.exists || doc.data() == null) {
          return const AadhaarLookupResult.failure('NOT_FOUND');
        }

        final data = doc.data()!;
        final name = (data['name'] as String?) ?? '';
        final bloodGroup = (data['bloodGroup'] as String?) ?? 'O+';
        final rawAge = data['age'];
        final int age = rawAge is int ? rawAge : (int.tryParse(rawAge?.toString() ?? '') ?? 30);
        final gender = (data['gender'] as String?) ?? 'Male';
        final address = (data['address'] as String?) ?? '';
        final rawPatientId = (data['patientId'] as String?) ?? '';
        final bool isAlreadyRegistered = data['isRegistered'] == true || rawPatientId.trim().isNotEmpty;

        final patientIdentity = PatientIdentity(
          aadhaarNumber: cleanDigits,
          patientId: isAlreadyRegistered ? rawPatientId : '',
          fullName: name,
          dob: (data['dob'] as String?) ?? '01 Jan ${DateTime.now().year - age}',
          age: age,
          gender: gender,
          phone: '', // STRICTLY ZERO PHONE FROM AADHAAR
          address: address,
          bloodGroup: bloodGroup,
          isNewRegistration: !isAlreadyRegistered,
        );

        if (isAlreadyRegistered) {
          return AadhaarLookupResult.alreadyRegistered(patientIdentity);
        } else {
          return AadhaarLookupResult.success(patientIdentity);
        }
      } on FirebaseException catch (e) {
        debugPrint('[RepositoryAadhaarService] FirebaseException on verifyAadhaar: ${e.code} - ${e.message}');
        return const AadhaarLookupResult.failure('UNAVAILABLE');
      } catch (e) {
        debugPrint('[RepositoryAadhaarService] Unexpected error on verifyAadhaar: $e');
        return const AadhaarLookupResult.failure('UNAVAILABLE');
      }
    }

    // 3. Fallback to Mock dataset (for local unit tests or offline dev)
    return super.verifyAadhaar(cleanDigits, simulateDelay: false);
  }
}
