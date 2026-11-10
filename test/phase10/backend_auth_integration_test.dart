import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/auth/auth_user.dart';
import 'package:aayusathi/core/auth/mock_auth_service.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/kiosk/models/patient_identity.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/models/opd_domain.dart';
import 'package:aayusathi/models/vital_reading.dart';

void main() {
  group('Phase 10: BackendProvider Auth Integration & Session Boundaries', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
      mockAuth.reset();
      BackendProvider.instance.resetOverrides();
      BackendProvider.instance.setMode(BackendMode.mock);
    });

    tearDown(() {
      BackendProvider.instance.resetOverrides();
      mockAuth.reset();
    });

    test('BackendProvider.instance.authService defaults to MockAuthService in mock mode', () {
      expect(BackendProvider.instance.authService, isA<MockAuthService>());
    });

    test('BackendProvider custom auth override functions in any mode', () {
      final customAuth = MockAuthService();
      BackendProvider.instance.setCustomRepositories(authService: customAuth);

      expect(BackendProvider.instance.authService, same(customAuth));

      BackendProvider.instance.setMode(BackendMode.firebase);
      expect(BackendProvider.instance.authService, same(customAuth));
    });

    test('Kiosk session reset preserves authenticated terminal identity', () async {
      // 1. Setup mock terminal identity
      final terminalAuth = MockAuthService();
      BackendProvider.instance.setCustomRepositories(authService: terminalAuth);
      await terminalAuth.signInAnonymously(role: UserRole.kiosk);

      expect(BackendProvider.instance.authService.isAuthenticated, isTrue);
      final terminalUid = BackendProvider.instance.authService.currentUser?.uid;
      expect(terminalUid, isNotNull);

      // 2. Initialize KioskService and populate patient transient session
      final kiosk = KioskService.instance;
      kiosk.startNewSession();

      kiosk.setPatientIdInput('PAT-PUNE-9876');
      kiosk.setIdentifiedPatient(
        const PatientIdentity(
          aadhaarNumber: '123456789012',
          patientId: 'PAT-PUNE-9876',
          fullName: 'Suresh Patil',
          dob: '1981-01-01',
          age: 45,
          gender: 'Male',
          phone: '9876543210',
          address: 'Pune, Maharashtra',
          bloodGroup: 'B+',
          isNewRegistration: false,
        ),
      );
      kiosk.setVitalReading(
        VitalReading(
          heartRate: 75,
          spo2: 98,
          temperature: 37.0,
          source: VitalSource.arduino,
          timestamp: DateTime.now(),
        ),
      );
      kiosk.setSelectedDomain(
        const OpdDomain(
          id: 'cardiology',
          icon: Icons.favorite_rounded,
        ),
      );

      expect(kiosk.activePatientIdInput, 'PAT-PUNE-9876');
      expect(kiosk.identifiedPatient?.patientId, 'PAT-PUNE-9876');
      expect(kiosk.selectedDomain?.id, 'cardiology');
      expect(kiosk.currentVitalReading?.heartRate, 75);

      // 3. Reset patient session at end of flow
      kiosk.resetSession();

      // 4. Verify patient session data is wiped clean
      expect(kiosk.hasActiveSession, isFalse);
      expect(kiosk.currentSession, isNull);
      expect(kiosk.identifiedPatient, isNull);
      expect(kiosk.activePatientIdInput, isEmpty);
      expect(kiosk.selectedDomain, isNull);
      expect(kiosk.currentVitalReading, isNull);

      // 5. CRITICAL ARCHITECTURAL BOUNDARY:
      // Terminal auth identity MUST remain active and unchanged.
      expect(BackendProvider.instance.authService.isAuthenticated, isTrue);
      expect(BackendProvider.instance.authService.currentUser?.uid, terminalUid);
      expect(BackendProvider.instance.authService.currentUser?.isKiosk, isTrue);
    });
  });
}
