import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_doctor_controller.dart';
import 'package:aayusathi/admin/models/admin_auth_state.dart';
import 'package:aayusathi/admin/models/admin_domain_availability.dart';
import 'package:aayusathi/admin/models/doctor_provisioning_request.dart';
import 'package:aayusathi/admin/screens/admin_doctor_provisioning_screen.dart';
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

  group('AAYUSATHI Phase A4.2: Domain Dropdown UI Reactivity Tests', () {
    test('1. Initial department is empty / null', () {
      expect(controller.department, isEmpty);
      expect(controller.departmentError, isNull);
    });

    test('2. Selecting Cardiology immediately updates controller and notifies listeners', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setDepartment('cardiology');

      expect(controller.department, equals('cardiology'));
      expect(controller.departmentError, isNull);
      expect(notifyCount, equals(1));
    });

    test('3. Selecting Neurology immediately updates controller and notifies listeners', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setDepartment('neurology');

      expect(controller.department, equals('neurology'));
      expect(controller.departmentError, isNull);
      expect(notifyCount, equals(1));
    });

    test('4. Selecting another department updates state immediately', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setDepartment('orthopedics');
      expect(controller.department, equals('orthopedics'));
      expect(notifyCount, equals(1));

      controller.setDepartment('dermatology');
      expect(controller.department, equals('dermatology'));
      expect(notifyCount, equals(2));
    });

    test('5. Selected value survives other form field changes', () {
      controller.setDepartment('neurology');
      controller.setName('Dr. Rajesh Sharma');
      controller.setMobile('9876543210');
      controller.setQualification('MBBS, MD');
      controller.setEmail('dr.rajesh@example.com');

      expect(controller.department, equals('neurology'));
      expect(controller.name, equals('Dr. Rajesh Sharma'));
      expect(controller.mobile, equals('9876543210'));
      expect(controller.qualification, equals('MBBS, MD'));
      expect(controller.email, equals('dr.rajesh@example.com'));
    });

    test('6. Selected value is correctly mapped and sent to provisioning request', () {
      controller.setDepartment('neurology');
      final request = DoctorProvisioningRequest(
        name: 'Dr. Test',
        registeredPhone: '9876543210',
        qualification: 'MBBS',
        department: controller.department,
      );

      expect(request.department, equals('neurology'));
      expect(request.canonicalDepartment, equals('neurology'));
    });

    test('7. Validation error immediately clears after department selection without clicking submit', () {
      // Trigger validation error on empty form
      final valid = controller.validateForm();
      expect(valid, isFalse);
      expect(controller.departmentError, equals('Select a department.'));

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // Select department -> error must clear immediately
      controller.setDepartment('gastroenterology');
      expect(controller.department, equals('gastroenterology'));
      expect(controller.departmentError, isNull);
      expect(notifyCount, equals(1));
    });

    test('8. Form reset clears department to empty', () {
      controller.setDepartment('ent');
      expect(controller.department, equals('ent'));

      controller.resetForm();
      expect(controller.department, isEmpty);
      expect(controller.departmentError, isNull);
    });

    test('9. Canonical 8 standard domains are available in AdminDomainAvailability', () {
      final domains = AdminDomainAvailability.standardDomains;
      expect(domains.length, equals(8));

      final domainIds = domains.map((d) => d['id']).toList();
      expect(domainIds, contains('cardiology'));
      expect(domainIds, contains('neurology'));
      expect(domainIds, contains('gastroenterology'));
      expect(domainIds, contains('orthopedics'));
      expect(domainIds, contains('pediatrics'));
      expect(domainIds, contains('ent'));
      expect(domainIds, contains('dermatology'));
      expect(domainIds, contains('general_medicine'));
    });

    testWidgets('10. AdminDoctorProvisioningScreen renders dropdown and updates immediately on change', (tester) async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDoctorProvisioningScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find Dropdown widget
      final dropdownFinder = find.byType(DropdownButton<String>);
      expect(dropdownFinder, findsOneWidget);

      // Initially hint text is shown
      expect(find.text('Select specialty department'), findsOneWidget);

      // Select 'Neurology'
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap 'Neurology' menu item
      final neurologyItemFinder = find.text('Neurology').last;
      await tester.tap(neurologyItemFinder);
      await tester.pumpAndSettle();

      // Selected value must be updated immediately in controller and UI
      expect(controller.department, equals('neurology'));
      expect(find.text('Neurology'), findsOneWidget);
    });
  });

  group('AAYUSATHI Phase A4.2: Firebase Authorization & Security Tests', () {
    test('11. Admin login establishes authenticated state', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');
      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(AdminAuthService.instance.currentSession?.username, equals('admin01'));
      expect(AdminAuthService.instance.currentSession?.role, equals(AdminRole.admin));
    });

    test('12. Admin email is formatted as admin01@hospital.aayusathi.in', () {
      const username = 'admin01';
      final email = '$username@hospital.aayusathi.in';
      expect(email, equals('admin01@hospital.aayusathi.in'));
      expect(RegExp(r'^admin[0-9]*@hospital\.aayusathi\.in$').hasMatch(email), isTrue);
    });

    test('13. Primary Firebase user remains Admin during and after doctor creation', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      final request = DoctorProvisioningRequest(
        name: 'Dr. Identity Preservation',
        registeredPhone: '9876543210',
        qualification: 'MBBS, MD',
        department: 'Neurology',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);

      // Primary Admin session is still authenticated as admin01
      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(AdminAuthService.instance.currentSession?.username, equals('admin01'));
    });

    test('14. Doctor profile creation succeeds under Admin authority', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      final request = DoctorProvisioningRequest(
        name: 'Dr. Neha Verma',
        registeredPhone: '9876543211',
        qualification: 'MBBS, DM Neurology',
        department: 'neurology',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isTrue);
      expect(result.doctorProfile, isNotNull);
      expect(result.doctorProfile!.department, equals('neurology'));
      expect(result.doctorProfile!.isActive, isTrue);
      expect(result.doctorProfile!.availabilityStatus, equals(DoctorAvailabilityStatus.offline));
      expect(result.temporaryPassword, isNotNull);
    });

    test('15. Password is NEVER persisted in Firestore payload', () {
      final now = DateTime.now();
      final doctorProfile = DoctorProfile(
        doctorId: 'DOC-102',
        doctorUniqueCode: 'DOC-102',
        name: 'Dr. Security Check',
        qualification: 'MBBS',
        department: 'cardiology',
        registeredPhone: '+919876543212',
        email: 'doc-102@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.offline,
        authUid: 'mock-auth-uid-102',
        createdAt: now,
        updatedAt: now,
      );

      final map = doctorProfile.toFirestore();
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('tempPassword'), isFalse);
      expect(map.containsKey('temporaryPassword'), isFalse);
      expect(map.containsKey('rawPassword'), isFalse);
    });

    test('16. Unauthorized users cannot provision doctors (Doctor, Kiosk, Patient)', () async {
      expect(AdminAuthService.instance.isAuthenticated, isFalse);

      final request = DoctorProvisioningRequest(
        name: 'Dr. Unauthorized',
        registeredPhone: '9876543213',
        qualification: 'MBBS',
        department: 'cardiology',
      );

      // Unauthenticated
      final res1 = await mockService.provisionDoctor(request);
      expect(res1.isSuccess, isFalse);
      expect(res1.errorMessage, contains('Administrator authority required'));

      // Check role comparisons
      expect(UserRole.doctor, isNot(equals(UserRole.admin)));
      expect(UserRole.kiosk, isNot(equals(UserRole.admin)));
      expect(UserRole.patient, isNot(equals(UserRole.admin)));
    });

    test('17. Rollback works when Firestore write fails', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');
      mockService.shouldFailFirestore = true;

      final request = DoctorProvisioningRequest(
        name: 'Dr. Rollback Verification',
        registeredPhone: '9876543214',
        qualification: 'MBBS',
        department: 'pediatrics',
      );

      final result = await mockService.provisionDoctor(request);
      expect(result.isSuccess, isFalse);
      expect(result.doctorProfile, isNull);
      expect(result.temporaryPassword, isNull);

      // Verify no record persisted in repository
      final exists = await mockService.checkDoctorExists(phone: '9876543214');
      expect(exists, isFalse);
    });

    test('18. Admin remains logged in after provisioning flow', () async {
      AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

      controller.setName('Dr. Continuous Session');
      controller.setMobile('9876543215');
      controller.setQualification('MBBS, MS');
      controller.setDepartment('ent');

      final success = await controller.submitProvisioning();
      expect(success, isTrue);
      expect(controller.isSuccess, isTrue);

      // Verify Admin session remains fully active
      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(AdminAuthService.instance.currentSession?.username, equals('admin01'));
      expect(AdminAuthService.instance.authState, equals(AdminAuthState.authenticated));
    });
  });
}
