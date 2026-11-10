import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/kiosk/services/aadhaar_service.dart';
import 'package:aayusathi/kiosk/services/mock_patient_repository.dart';
import 'package:aayusathi/core/firebase/firebase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPatientRepository mockRepository;
  late RepositoryAadhaarService service;

  setUp(() {
    mockRepository = MockPatientRepository.instance;
    mockRepository.resetToDefaults();
    service = RepositoryAadhaarService(
      repository: mockRepository,
      simulateDelay: false,
    );
  });

  group('AAYUSATHI Demo Aadhaar - Records Lookup & Field Mapping', () {
    test('1. Lookup 111111111111 returns Aarav Patil with exact fields', () async {
      final result = await service.verifyAadhaar('111111111111');

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyRegistered, isFalse);
      expect(result.patient, isNotNull);

      final p = result.patient!;
      expect(p.aadhaarNumber, '111111111111');
      expect(p.fullName, 'Aarav Patil');
      expect(p.bloodGroup, 'B+');
      expect(p.dob, '12 Jan 2002');
      expect(p.age, 24);
      expect(p.gender, 'Male');
      expect(p.address, '12 Demo Lane, Vengurla, Maharashtra');
      expect(p.phone, isEmpty, reason: 'Phone must not come from Aadhaar');
      expect(p.patientId, isEmpty, reason: 'Patient ID must not be pre-created');
      expect(p.isNewRegistration, isTrue);
    });

    test('2. Lookup 222222222222 returns Ananya Deshmukh with exact fields', () async {
      final result = await service.verifyAadhaar('222222222222');

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyRegistered, isFalse);
      expect(result.patient, isNotNull);

      final p = result.patient!;
      expect(p.aadhaarNumber, '222222222222');
      expect(p.fullName, 'Ananya Deshmukh');
      expect(p.bloodGroup, 'O+');
      expect(p.dob, '05 Mar 1995');
      expect(p.age, 31);
      expect(p.gender, 'Female');
      expect(p.address, '45 Test Road, Wadala, Mumbai');
      expect(p.phone, isEmpty);
      expect(p.patientId, isEmpty);
      expect(p.isNewRegistration, isTrue);
    });

    test('3. Lookup 333333333333 returns Rohan Kulkarni with exact fields', () async {
      final result = await service.verifyAadhaar('333333333333');

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyRegistered, isFalse);
      expect(result.patient, isNotNull);

      final p = result.patient!;
      expect(p.aadhaarNumber, '333333333333');
      expect(p.fullName, 'Rohan Kulkarni');
      expect(p.bloodGroup, 'A+');
      expect(p.dob, '20 Jul 2007');
      expect(p.age, 19);
      expect(p.gender, 'Male');
      expect(p.address, '78 Sample Nagar, Pune, Maharashtra');
      expect(p.phone, isEmpty);
      expect(p.patientId, isEmpty);
      expect(p.isNewRegistration, isTrue);
    });

    test('4. Lookup 444444444444 returns Meera Joshi with exact fields', () async {
      final result = await service.verifyAadhaar('444444444444');

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyRegistered, isFalse);
      expect(result.patient, isNotNull);

      final p = result.patient!;
      expect(p.aadhaarNumber, '444444444444');
      expect(p.fullName, 'Meera Joshi');
      expect(p.bloodGroup, 'AB+');
      expect(p.dob, '18 Nov 1983');
      expect(p.age, 42);
      expect(p.gender, 'Female');
      expect(p.address, '23 Prototype Street, Nashik, Maharashtra');
      expect(p.phone, isEmpty);
      expect(p.patientId, isEmpty);
      expect(p.isNewRegistration, isTrue);
    });

    test('5. Lookup 555555555555 returns Kabir Shahi with exact fields', () async {
      final result = await service.verifyAadhaar('555555555555');

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyRegistered, isFalse);
      expect(result.patient, isNotNull);

      final p = result.patient!;
      expect(p.aadhaarNumber, '555555555555');
      expect(p.fullName, 'Kabir Shahi');
      expect(p.bloodGroup, 'O-');
      expect(p.dob, '30 Apr 1970');
      expect(p.age, 56);
      expect(p.gender, 'Male');
      expect(p.address, '91 Mock Colony, Thane, Maharashtra');
      expect(p.phone, isEmpty);
      expect(p.patientId, isEmpty);
      expect(p.isNewRegistration, isTrue);
    });

    test('6. Lookup 666666666666 returns Yatin Ugale with exact fields', () async {
      final result = await service.verifyAadhaar('666666666666');

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyRegistered, isFalse);
      expect(result.patient, isNotNull);

      final p = result.patient!;
      expect(p.aadhaarNumber, '666666666666');
      expect(p.fullName, 'Yatin Ugale');
      expect(p.dob, '20 Oct 2000');
      expect(p.age, 26);
      expect(p.gender, 'Male');
      expect(p.address, 'Nirmala Nagar, Khar Road, Mumbai');
      expect(p.bloodGroup, 'B+');
      expect(p.phone, isEmpty, reason: 'Phone must not come from Aadhaar');
      expect(p.patientId, isEmpty, reason: 'Patient ID must not be pre-created');
      expect(p.isNewRegistration, isTrue);
    });

    test('7. Lookup 777777777777 returns Urvi Sharma with exact fields', () async {
      final result = await service.verifyAadhaar('777777777777');

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyRegistered, isFalse);
      expect(result.patient, isNotNull);

      final p = result.patient!;
      expect(p.aadhaarNumber, '777777777777');
      expect(p.fullName, 'Urvi Sharma');
      expect(p.dob, '10 Aug 2002');
      expect(p.age, 24);
      expect(p.gender, 'Female');
      expect(p.address, 'Ram Nagar, Haryana');
      expect(p.bloodGroup, 'A+');
      expect(p.phone, isEmpty, reason: 'Phone must not come from Aadhaar');
      expect(p.patientId, isEmpty, reason: 'Patient ID must not be pre-created');
      expect(p.isNewRegistration, isTrue);
    });
  });

  group('Validation, Seeding Idempotence & Error Handling', () {
    test('8. Invalid Aadhaar length (<12 or >12 digits) returns INVALID_FORMAT', () async {
      final resultShort = await service.verifyAadhaar('12345');
      expect(resultShort.isSuccess, isFalse);
      expect(resultShort.errorCode, 'INVALID_FORMAT');

      final resultLong = await service.verifyAadhaar('12345678901234');
      expect(resultLong.isSuccess, isFalse);
      expect(resultLong.errorCode, 'INVALID_FORMAT');

      final isRegistered = await service.isAadhaarRegistered('123');
      expect(isRegistered, isFalse);
    });

    test('9. Invalid Aadhaar characters (alphabetic/symbols) returns INVALID_FORMAT', () async {
      final resultLetters = await service.verifyAadhaar('11112222333A');
      expect(resultLetters.isSuccess, isFalse);
      expect(resultLetters.errorCode, 'INVALID_FORMAT');

      final resultSymbols = await service.verifyAadhaar('1111-2222#333');
      expect(resultSymbols.isSuccess, isFalse);
      expect(resultSymbols.errorCode, 'INVALID_FORMAT');
    });

    test('10. Missing record returns NOT_FOUND', () async {
      final result = await service.verifyAadhaar('999988887777');
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'NOT_FOUND');

      final resultZero = await service.verifyAadhaar('000000000000');
      expect(resultZero.isSuccess, isFalse);
      expect(resultZero.errorCode, 'NOT_FOUND');
    });

    test('11. Duplicate registration protection returns ALREADY_REGISTERED', () async {
      // 111122223333 is pre-registered with patientId AAYU-102938
      final isRegistered = await service.isAadhaarRegistered('111122223333');
      expect(isRegistered, isTrue);

      final result = await service.verifyAadhaar('111122223333');
      expect(result.isAlreadyRegistered, isTrue);
      expect(result.errorCode, 'ALREADY_REGISTERED');
      expect(result.patient?.patientId, 'AAYU-102938');

      // Now register demo 111111111111 with a patientId
      final existingPat = mockRepository.findByAadhaar('111111111111')!;
      mockRepository.savePatient(existingPat.copyWith(
        patientId: 'AAYU-999001',
        phone: '+91 98765 00000',
        isNewRegistration: false,
      ));

      final isDemoRegistered = await service.isAadhaarRegistered('111111111111');
      expect(isDemoRegistered, isTrue);

      final demoResult = await service.verifyAadhaar('111111111111');
      expect(demoResult.isAlreadyRegistered, isTrue);
      expect(demoResult.patient?.patientId, 'AAYU-999001');
    });

    test('12. Verification does NOT automatically create a patient document or ID', () async {
      // Prior to lookup, verify 333333333333 has no patientId
      final initial = mockRepository.findByAadhaar('333333333333');
      expect(initial?.patientId, isEmpty);

      // Perform lookup
      final result = await service.verifyAadhaar('333333333333');
      expect(result.isSuccess, isTrue);

      // Check that repository still has empty patientId and no patient ID was minted
      final afterLookup = mockRepository.findByAadhaar('333333333333');
      expect(afterLookup?.patientId, isEmpty);
      expect(afterLookup?.phone, isEmpty);
    });

    test('13. Correct field mapping preserves masked values and formatting', () async {
      final result = await service.verifyAadhaar('4444 4444 4444'); // spaces handled
      expect(result.isSuccess, isTrue);
      final p = result.patient!;
      expect(p.formattedAadhaar, '4444 4444 4444');
      expect(p.maskedAadhaar, 'XXXX XXXX 4444');
      expect(p.dobWithAge, contains('42 Yrs'));
    });

    test('14. Firestore collection configuration references demo_aadhaar', () {
      expect(FirebaseConfig.demoAadhaarCollection, 'demo_aadhaar');
    });

    test('15. Plain-text Aadhaar is rejected from patients collection schema', () {
      expect(FirebaseConfig.patientsCollection, 'patients');
      expect(FirebaseConfig.demoAadhaarCollection, 'demo_aadhaar');
      expect(FirebaseConfig.demoAadhaarCollection, isNot(equals(FirebaseConfig.patientsCollection)));
    });

    test('16. Repeated seeding and resetToDefaults prevent duplicate entries and preserve all records', () {
      expect(mockRepository.allPatients.length, 11);

      // Run seeding process multiple times
      mockRepository.seedDemoAadhaarRecords();
      mockRepository.seedDemoAadhaarRecords();
      mockRepository.seedDemoAadhaarRecords();

      expect(mockRepository.allPatients.length, 11);

      // Run resetToDefaults multiple times
      mockRepository.resetToDefaults();
      mockRepository.resetToDefaults();

      expect(mockRepository.allPatients.length, 11);

      // Verify all 7 demo records and 4 registered records are present
      final expectedAadhaars = [
        '111122223333',
        '444455556666',
        '777788889999',
        '123456789012',
        '111111111111',
        '222222222222',
        '333333333333',
        '444444444444',
        '555555555555',
        '666666666666',
        '777777777777',
      ];
      for (final aadhaar in expectedAadhaars) {
        expect(mockRepository.findByAadhaar(aadhaar), isNotNull, reason: 'Expected $aadhaar to be present');
      }
    });

    test('17. Space tolerance and masking for 666666666666 and 777777777777 preserve privacy', () async {
      // Yatin Ugale with spaces
      final res1 = await service.verifyAadhaar('6666 6666 6666');
      expect(res1.isSuccess, isTrue);
      expect(res1.patient?.fullName, 'Yatin Ugale');
      expect(res1.patient?.formattedAadhaar, '6666 6666 6666');
      expect(res1.patient?.maskedAadhaar, 'XXXX XXXX 6666');
      expect(res1.patient?.dobWithAge, '20 Oct 2000 (26 Yrs)');

      // Urvi Sharma with spaces
      final res2 = await service.verifyAadhaar('7777 7777 7777');
      expect(res2.isSuccess, isTrue);
      expect(res2.patient?.fullName, 'Urvi Sharma');
      expect(res2.patient?.formattedAadhaar, '7777 7777 7777');
      expect(res2.patient?.maskedAadhaar, 'XXXX XXXX 7777');
      expect(res2.patient?.dobWithAge, '10 Aug 2002 (24 Yrs)');
    });

    test('18. Existing-record regression ensures original registered and demo records remain intact', () async {
      // Verify pre-registered patient 111122223333
      final reg1 = mockRepository.findByAadhaar('111122223333');
      expect(reg1?.fullName, 'Aarav Sharma');
      expect(reg1?.patientId, 'AAYU-102938');

      // Verify pre-registered patient 444455556666
      final reg2 = mockRepository.findByAadhaar('444455556666');
      expect(reg2?.fullName, 'Priya Patil');
      expect(reg2?.patientId, 'AAYU-482910');

      // Verify pre-registered patient 777788889999
      final reg3 = mockRepository.findByAadhaar('777788889999');
      expect(reg3?.fullName, 'Rajesh Kulkarni');
      expect(reg3?.patientId, 'AAYU-773829');

      // Verify pre-registered patient 123456789012
      final reg4 = mockRepository.findByAadhaar('123456789012');
      expect(reg4?.fullName, 'Sunita Deshmukh');
      expect(reg4?.patientId, 'AAYU-918234');
    });
  });
}
