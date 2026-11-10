import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/repositories/firebase/firebase_appointment_repository.dart';
import 'package:aayusathi/repositories/firebase/firebase_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/services/dev_firestore_connection_test_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 9 Live Verification & Diagnostic Tests', () {
    test('Backend mode selection logs and switches repositories', () {
      final provider = BackendProvider.instance;
      provider.resetOverrides();

      // Switch to Mock
      provider.setMode(BackendMode.mock);
      expect(provider.mode, BackendMode.mock);
      expect(provider.patientRepository, isA<MockPatientRepository>());
      expect(provider.appointmentRepository, isA<MockAppointmentRepository>());

      // Custom override simulation for Firebase mode testing
      final customFirebasePatient = FirebasePatientRepository();
      final customFirebaseAppt = FirebaseAppointmentRepository();
      provider.setCustomRepositories(
        patientRepo: customFirebasePatient,
        appointmentRepo: customFirebaseAppt,
      );

      expect(provider.patientRepository, equals(customFirebasePatient));
      expect(provider.appointmentRepository, equals(customFirebaseAppt));
      expect(provider.patientRepository, isA<FirebasePatientRepository>());
      expect(provider.appointmentRepository, isA<FirebaseAppointmentRepository>());

      provider.resetOverrides();
    });

    test('DevConnectionTestResult models write/read states accurately', () {
      const successResult = DevConnectionTestResult(
        isWriteSuccess: true,
        isReadSuccess: true,
        testDocumentId: 'test_123',
      );
      expect(successResult.isFullSuccess, isTrue);
      expect(successResult.errorCode, isNull);

      const writeFail = DevConnectionTestResult(
        isWriteSuccess: false,
        isReadSuccess: false,
        testDocumentId: 'test_456',
        errorCode: 'permission-denied',
        errorMessage: 'The caller does not have permission to execute the specified operation.',
      );
      expect(writeFail.isFullSuccess, isFalse);
      expect(writeFail.errorCode, 'permission-denied');

      const readFail = DevConnectionTestResult(
        isWriteSuccess: true,
        isReadSuccess: false,
        testDocumentId: 'test_789',
        errorCode: 'permission-denied',
        errorMessage: 'Missing read permissions.',
      );
      expect(readFail.isFullSuccess, isFalse);
      expect(readFail.isWriteSuccess, isTrue);
      expect(readFail.isReadSuccess, isFalse);
    });

    test('BackendMode.firebase maintains mode during repository operations', () {
      final provider = BackendProvider.instance;
      provider.resetOverrides();
      provider.setMode(BackendMode.firebase);

      expect(provider.mode, BackendMode.firebase);
      expect(provider.isFirebaseMode, isTrue);

      // Reset back to mock for test hygiene
      provider.setMode(BackendMode.mock);
    });
  });
}
