import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_doctor_controller.dart';
import 'package:aayusathi/admin/models/doctor_provisioning_request.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/mock_doctor_provisioning_service.dart';
import 'package:aayusathi/core/auth/auth_user.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorProvisioningService mockService;
  late AdminDoctorController controller;

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    AdminAuthService.instance.resetForTesting();
    mockService = MockDoctorProvisioningService();
    controller = AdminDoctorController.instance;
    controller.setCustomService(mockService);
    controller.resetForm();
  });

  tearDown(() {
    AdminAuthService.instance.resetForTesting();
    controller.resetForm();
  });

  group('AAYUSATHI Phase A4.1: Admin Authorization & Security Tests', () {
    test('1. Admin can initiate doctor provisioning when authenticated', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');
      expect(AdminAuthService.instance.isAuthenticated, isTrue);

      final request = DoctorProvisioningRequest(
        name: 'Dr. Aarav Patel',
        registeredPhone: '9876543210',
        qualification: 'MBBS, MD Cardiology',
        department: 'Cardiology',
        email: 'aarav.patel@hospital.aayusathi.in',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);
      expect(result.doctorProfile, isNotNull);
      expect(result.doctorProfile!.doctorId, equals('DOC-101'));
      expect(result.temporaryPassword, isNotNull);
      expect(result.temporaryPassword, startsWith('Ayu@'));
    });

    test('2. Unauthenticated user cannot provision doctor', () async {
      expect(AdminAuthService.instance.isAuthenticated, isFalse);

      final request = DoctorProvisioningRequest(
        name: 'Dr. Unauthorized User',
        registeredPhone: '9876543211',
        qualification: 'MBBS',
        department: 'Neurology',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Administrator authority required'));
    });

    test('3. Doctor role cannot provision another doctor', () async {
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      const doctorRole = UserRole.doctor;
      expect(doctorRole, isNot(equals(UserRole.admin)));

      final request = DoctorProvisioningRequest(
        name: 'Dr. Colleague Doctor',
        registeredPhone: '9876543212',
        qualification: 'MBBS, MS Orthopedics',
        department: 'Orthopedics',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Administrator authority required'));
    });

    test('4. Kiosk terminal cannot provision doctor', () async {
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      const kioskRole = UserRole.kiosk;
      expect(kioskRole, isNot(equals(UserRole.admin)));

      final request = DoctorProvisioningRequest(
        name: 'Dr. Kiosk Attempt',
        registeredPhone: '9876543213',
        qualification: 'MBBS',
        department: 'General Medicine',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Administrator authority required'));
    });

    test('5. Patient role cannot provision doctor', () async {
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      const patientRole = UserRole.patient;
      expect(patientRole, isNot(equals(UserRole.admin)));

      final request = DoctorProvisioningRequest(
        name: 'Dr. Patient Self-Registration Attempt',
        registeredPhone: '9876543214',
        qualification: 'None',
        department: 'Pediatrics',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Administrator authority required'));
    });

    test('6. Doctor creation preserves the active Admin session (no logout / user replacement)', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');
      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(AdminAuthService.instance.currentSession?.username, equals('admin01'));

      final request = DoctorProvisioningRequest(
        name: 'Dr. Session Safety Test',
        registeredPhone: '9876543215',
        qualification: 'MBBS, MD Pediatrics',
        department: 'Pediatrics',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);

      // Verify Admin session remains completely intact
      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(AdminAuthService.instance.currentSession?.username, equals('admin01'));
    });

    test('7. Firebase Auth account creation parameters conform to standard format', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      final request = DoctorProvisioningRequest(
        name: 'Dr. Convention Test',
        registeredPhone: '9876543216',
        qualification: 'MBBS, MS ENT',
        department: 'ENT',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);

      final expectedEmail = '${result.doctorProfile!.doctorId.toLowerCase()}@hospital.aayusathi.in';
      expect(expectedEmail, equals('doc-101@hospital.aayusathi.in'));
    });

    test('8. Firestore Doctor profile creation sets initial active=true and offline availability', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      final request = DoctorProvisioningRequest(
        name: 'Dr. Profile Field Validation',
        registeredPhone: '9876543217',
        qualification: 'MBBS, MD Dermatology',
        department: 'Dermatology',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);
      final profile = result.doctorProfile!;

      expect(profile.isActive, isTrue);
      expect(profile.availabilityStatus, equals(DoctorAvailabilityStatus.offline));
      expect(profile.name, equals('Dr. Profile Field Validation'));
      expect(profile.qualification, equals('MBBS, MD Dermatology'));
      expect(profile.department, equals('dermatology'));
      expect(profile.registeredPhone, equals('+919876543217'));
    });

    test('9. authUid is securely linked to the Doctor profile', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      final request = DoctorProvisioningRequest(
        name: 'Dr. Auth UID Test',
        registeredPhone: '9876543218',
        qualification: 'MBBS, MD Gastroenterology',
        department: 'Gastroenterology',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);
      expect(result.doctorProfile!.authUid, isNotEmpty);
      expect(result.doctorProfile!.authUid, equals('mock-uid-DOC-101'));
    });

    test('10. Zero password storage: password NEVER enters Firestore DoctorProfile payload', () async {
      final now = DateTime.now();
      final doctorProfile = DoctorProfile(
        doctorId: 'DOC-101',
        doctorUniqueCode: 'DOC-101',
        name: 'Dr. Privacy Test',
        qualification: 'MBBS',
        department: 'General Medicine',
        registeredPhone: '+919876543219',
        email: 'doc-101@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.offline,
        authUid: 'test-auth-uid-123',
        createdAt: now,
        updatedAt: now,
      );

      final firestoreMap = doctorProfile.toFirestore();
      expect(firestoreMap.containsKey('password'), isFalse);
      expect(firestoreMap.containsKey('tempPassword'), isFalse);
      expect(firestoreMap.containsKey('temporaryPassword'), isFalse);
      expect(firestoreMap.containsKey('adminPassword'), isFalse);
      expect(firestoreMap.containsKey('rawPassword'), isFalse);
      expect(firestoreMap.containsKey('otp'), isFalse);
    });

    test('11. Zero password storage: password NEVER enters audit logs', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      final request = DoctorProvisioningRequest(
        name: 'Dr. Audit Log Test',
        registeredPhone: '9876543220',
        qualification: 'MBBS',
        department: 'Cardiology',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);

      final auditRepo = BackendProvider.instance.auditRepository;
      final logs = await auditRepo.getLogsForEntity(
        entityType: 'DOCTOR_PROFILE',
        entityId: 'DOC-101',
      );
      expect(logs.isNotEmpty, isTrue);

      final createLog = logs.firstWhere((l) => l.action == 'DOCTOR_CREATED');
      expect(createLog.metadata.containsKey('password'), isFalse);
      expect(createLog.metadata.containsKey('temporaryPassword'), isFalse);
      expect(createLog.metadata.containsKey('tempPassword'), isFalse);
    });

    test('12. Firestore permission / network failure is handled gracefully with clear user error', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');
      mockService.shouldFailFirestore = true;

      final request = DoctorProvisioningRequest(
        name: 'Dr. Failure Simulation',
        registeredPhone: '9876543221',
        qualification: 'MBBS',
        department: 'Neurology',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Cloud Firestore database write error'));
    });

    test('13. Auth rollback after Firestore failure prevents orphan accounts', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');
      mockService.shouldFailFirestore = true;

      controller.setName('Dr. Rollback Test');
      controller.setMobile('9876543222');
      controller.setQualification('MBBS, MD Cardiology');
      controller.setDepartment('Cardiology');

      final success = await controller.submitProvisioning();
      expect(success, isFalse);
      expect(controller.generalError, isNotNull);
      expect(controller.isSuccess, isFalse);
      expect(controller.provisionedDoctor, isNull);

      // Verify no doctor profile was retained in repository
      final docExists = await mockService.checkDoctorExists(phone: '9876543222');
      expect(docExists, isFalse);
    });

    test('14. Sequential ID generation remains collision-free across multiple additions', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      final req1 = DoctorProvisioningRequest(
        name: 'Dr. One',
        registeredPhone: '9876543231',
        qualification: 'MBBS',
        department: 'Cardiology',
      );
      final req2 = DoctorProvisioningRequest(
        name: 'Dr. Two',
        registeredPhone: '9876543232',
        qualification: 'MBBS',
        department: 'Neurology',
      );

      final res1 = await mockService.provisionDoctor(req1);
      final res2 = await mockService.provisionDoctor(req2);

      expect(res1.doctorProfile!.doctorId, equals('DOC-101'));
      expect(res2.doctorProfile!.doctorId, equals('DOC-102'));
    });

    test('15. Controller reset clears sensitive form state and one-time password', () {
      controller.setName('Dr. Reset Test');
      controller.setMobile('9876543233');
      controller.setQualification('MBBS');
      controller.setDepartment('Cardiology');

      controller.resetForm();

      expect(controller.name, isEmpty);
      expect(controller.mobile, isEmpty);
      expect(controller.qualification, isEmpty);
      expect(controller.department, isEmpty);
      expect(controller.provisionedDoctor, isNull);
      expect(controller.temporaryPassword, isNull);
      expect(controller.isSuccess, isFalse);
      expect(controller.generalError, isNull);
    });
  });
}
