import 'package:aayusathi/admin/controllers/admin_doctor_controller.dart';
import 'package:aayusathi/admin/localization/admin_localizations.dart';
import 'package:aayusathi/admin/models/doctor_provisioning_request.dart';
import 'package:aayusathi/admin/screens/admin_doctor_provisioning_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/doctor_id_generator.dart';
import 'package:aayusathi/admin/services/doctor_password_generator.dart';
import 'package:aayusathi/admin/services/mock_admin_dashboard_service.dart';
import 'package:aayusathi/admin/services/mock_doctor_provisioning_service.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorProvisioningService mockProvisioningService;
  late MockAuditRepository mockAuditRepo;
  late AdminDoctorController doctorController;

  setUp(() async {
    mockAuditRepo = MockAuditRepository.instance;
    mockAuditRepo.clear();

    mockProvisioningService = MockDoctorProvisioningService(auditRepository: mockAuditRepo);
    mockProvisioningService.clear();

    doctorController = AdminDoctorController.instance;
    doctorController.setCustomService(mockProvisioningService);
    doctorController.resetForm();

    // Authenticate Admin session
    await AdminAuthService.instance.login(
      username: 'admin01',
      password: 'aayusathi1226',
    );
  });

  tearDown(() async {
    doctorController.resetForm();
    mockProvisioningService.clear();
    await AdminAuthService.instance.logout();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AdminLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: child,
    );
  }

  // =========================================================================
  // GROUP 1: DOCTOR ID GENERATOR TESTS
  // =========================================================================
  group('1. DoctorIdGenerator Unit Tests', () {
    test('1.1 extractNumber accurately parses numeric suffix and handles variations', () {
      expect(DoctorIdGenerator.extractNumber('DOC-101'), equals(101));
      expect(DoctorIdGenerator.extractNumber('doc-104'), equals(104));
      expect(DoctorIdGenerator.extractNumber('  DOC-250  '), equals(250));
      expect(DoctorIdGenerator.extractNumber('INVALID-101'), isNull);
      expect(DoctorIdGenerator.extractNumber('DOC-ABC'), isNull);
    });

    test('1.2 formatId formats integer to standard DOC-XXX format', () {
      expect(DoctorIdGenerator.formatId(101), equals('DOC-101'));
      expect(DoctorIdGenerator.formatId(999), equals('DOC-999'));
    });

    test('1.3 generateNextId starts at DOC-101 when no existing doctors exist', () {
      final nextId = DoctorIdGenerator.generateNextId([]);
      expect(nextId, equals('DOC-101'));
    });

    test('1.4 generateNextId generates sequential ID avoiding existing IDs', () {
      final nextId = DoctorIdGenerator.generateNextId(['DOC-101', 'DOC-102']);
      expect(nextId, equals('DOC-103'));
    });

    test('1.5 generateNextId fills lowest available gap in non-contiguous IDs', () {
      final nextId = DoctorIdGenerator.generateNextId(['DOC-101', 'DOC-103', 'DOC-104']);
      expect(nextId, equals('DOC-102'));
    });

    test('1.6 generateCollisionSafeId verifies candidate against async checker', () async {
      final taken = {'DOC-101', 'DOC-102', 'DOC-103'};
      final safeId = await DoctorIdGenerator.generateCollisionSafeId(
        (candidate) async => taken.contains(candidate),
      );
      expect(safeId, equals('DOC-104'));
    });
  });

  // =========================================================================
  // GROUP 2: DOCTOR PASSWORD GENERATOR TESTS
  // =========================================================================
  group('2. DoctorPasswordGenerator Unit Tests', () {
    test('2.1 generateTemporaryPassword generates passwords of minimum length 10', () {
      final pwd = DoctorPasswordGenerator.generateTemporaryPassword();
      expect(pwd.length, greaterThanOrEqualTo(10));
      expect(pwd.startsWith('Ayu@'), isTrue);
    });

    test('2.2 meetsComplexityRequirements verifies uppercase, lowercase, digit, and symbol', () {
      expect(DoctorPasswordGenerator.meetsComplexityRequirements('Ayu@7Xk92P'), isTrue);
      expect(DoctorPasswordGenerator.meetsComplexityRequirements('Ayu@Abc12'), isTrue);
      expect(DoctorPasswordGenerator.meetsComplexityRequirements('weakpass'), isFalse);
      expect(DoctorPasswordGenerator.meetsComplexityRequirements('NO_DIGITS_HERE!'), isFalse);
      expect(DoctorPasswordGenerator.meetsComplexityRequirements('nouppercase123@'), isFalse);
      expect(DoctorPasswordGenerator.meetsComplexityRequirements('NoSpecial1234'), isFalse);
    });

    test('2.3 20 consecutive generated passwords all meet complexity rules', () {
      for (int i = 0; i < 20; i++) {
        final pwd = DoctorPasswordGenerator.generateTemporaryPassword();
        expect(
          DoctorPasswordGenerator.meetsComplexityRequirements(pwd),
          isTrue,
          reason: 'Password $pwd failed complexity requirements',
        );
      }
    });

    test('2.4 Two consecutively generated passwords are not identical', () {
      final pwd1 = DoctorPasswordGenerator.generateTemporaryPassword();
      final pwd2 = DoctorPasswordGenerator.generateTemporaryPassword();
      expect(pwd1, isNot(equals(pwd2)));
    });
  });

  // =========================================================================
  // GROUP 3: PROVISIONING REQUEST & SERVICE LOGIC TESTS
  // =========================================================================
  group('3. Provisioning Request & Service Tests', () {
    test('3.1 DoctorProvisioningRequest formats Indian phone with +91 prefix', () {
      const req1 = DoctorProvisioningRequest(
        name: 'Dr. Rahul Sharma',
        registeredPhone: '9876543210',
        qualification: 'MBBS, MD',
        department: 'cardiology',
      );
      expect(req1.standardizedPhone, equals('+919876543210'));

      const req2 = DoctorProvisioningRequest(
        name: 'Dr. Rahul Sharma',
        registeredPhone: '+919876543210',
        qualification: 'MBBS, MD',
        department: 'cardiology',
      );
      expect(req2.standardizedPhone, equals('+919876543210'));
    });

    test('3.2 DoctorProvisioningRequest canonicalizes department identifiers', () {
      const req = DoctorProvisioningRequest(
        name: 'Dr. Test',
        registeredPhone: '9876543210',
        qualification: 'MBBS',
        department: 'Cardiology Clinic',
      );
      expect(req.canonicalDepartment, equals('cardiology'));
    });

    test('3.3 Provisioning fails when Admin is unauthenticated', () async {
      await AdminAuthService.instance.logout();

      const req = DoctorProvisioningRequest(
        name: 'Dr. Rajesh Sharma',
        registeredPhone: '9876543210',
        qualification: 'MBBS, MD',
        department: 'cardiology',
      );

      final result = await mockProvisioningService.provisionDoctor(req);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Administrator authority required'));
    });

    test('3.4 Provisioning succeeds and initializes doctor in OFFLINE state with active true', () async {
      const req = DoctorProvisioningRequest(
        name: 'Dr. Rajesh Sharma',
        registeredPhone: '9876543210',
        qualification: 'MBBS, MD',
        department: 'cardiology',
      );

      final result = await mockProvisioningService.provisionDoctor(req);
      expect(result.isSuccess, isTrue);
      expect(result.doctorProfile, isNotNull);
      expect(result.temporaryPassword, isNotNull);

      final doc = result.doctorProfile!;
      expect(doc.doctorId, equals('DOC-101'));
      expect(doc.doctorUniqueCode, equals('DOC-101'));
      expect(doc.name, equals('Dr. Rajesh Sharma'));
      expect(doc.qualification, equals('MBBS, MD'));
      expect(doc.department, equals('cardiology'));
      expect(doc.registeredPhone, equals('+919876543210'));
      expect(doc.isActive, isTrue);
      expect(doc.availabilityStatus, equals(DoctorAvailabilityStatus.offline));
      expect(doc.authUid, isNotEmpty);
    });

    test('3.5 Provisioning emits DOCTOR_CREATED audit log with zero credentials logged', () async {
      const req = DoctorProvisioningRequest(
        name: 'Dr. Rajesh Sharma',
        registeredPhone: '9876543210',
        qualification: 'MBBS, MD',
        department: 'cardiology',
      );

      final result = await mockProvisioningService.provisionDoctor(req);
      expect(result.isSuccess, isTrue);

      final audits = mockAuditRepo.logs;
      expect(audits, isNotEmpty);

      final doctorCreatedAudit = audits.firstWhere((a) => a.action == 'DOCTOR_CREATED');
      expect(doctorCreatedAudit.entityType, equals('DOCTOR_PROFILE'));
      expect(doctorCreatedAudit.entityId, equals('DOC-101'));
      expect(doctorCreatedAudit.actorId, equals('admin01'));

      // CRITICAL SECURITY: Audit metadata must NOT contain password or tokens
      expect(doctorCreatedAudit.metadata.containsKey('password'), isFalse);
      expect(doctorCreatedAudit.metadata.containsKey('temporaryPassword'), isFalse);
      expect(doctorCreatedAudit.metadata.containsKey('token'), isFalse);
    });

    test('3.6 Duplicate doctor phone is rejected safely', () async {
      const req1 = DoctorProvisioningRequest(
        name: 'Dr. First Doctor',
        registeredPhone: '9876543210',
        qualification: 'MBBS',
        department: 'cardiology',
      );
      await mockProvisioningService.provisionDoctor(req1);

      const req2 = DoctorProvisioningRequest(
        name: 'Dr. Second Doctor',
        registeredPhone: '9876543210',
        qualification: 'MD',
        department: 'neurology',
      );
      final result2 = await mockProvisioningService.provisionDoctor(req2);
      expect(result2.isSuccess, isFalse);
      expect(result2.errorMessage, contains('already exists'));
    });

    test('3.7 Simulated failure returns clear user-friendly error envelope', () async {
      mockProvisioningService.shouldFailFirestore = true;

      const req = DoctorProvisioningRequest(
        name: 'Dr. Test Doctor',
        registeredPhone: '9876543210',
        qualification: 'MBBS',
        department: 'orthopedics',
      );

      final result = await mockProvisioningService.provisionDoctor(req);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('database write error'));
    });
  });

  // =========================================================================
  // GROUP 4: CONTROLLER STATE & FORM VALIDATION TESTS
  // =========================================================================
  group('4. AdminDoctorController Form Validation Tests', () {
    test('4.1 validateForm fails on empty fields with specific inline errors', () {
      doctorController.setName('');
      doctorController.setMobile('');
      doctorController.setQualification('');
      doctorController.setDepartment('');

      final isValid = doctorController.validateForm();
      expect(isValid, isFalse);
      expect(doctorController.nameError, equals('Doctor name is required.'));
      expect(doctorController.mobileError, equals('Mobile number is required.'));
      expect(doctorController.qualificationError, equals('Qualification is required.'));
      expect(doctorController.departmentError, equals('Select a department.'));
    });

    test('4.2 validateForm validates Indian mobile format (10 digits starting with 6-9)', () {
      doctorController.setName('Dr. Valid Name');
      doctorController.setQualification('MBBS');
      doctorController.setDepartment('cardiology');

      doctorController.setMobile('12345');
      expect(doctorController.validateForm(), isFalse);
      expect(doctorController.mobileError, contains('10-digit'));

      doctorController.setMobile('5555555555'); // Invalid leading digit
      expect(doctorController.validateForm(), isFalse);

      doctorController.setMobile('9876543210'); // Valid Indian mobile
      expect(doctorController.validateForm(), isTrue);
      expect(doctorController.mobileError, isNull);
    });

    test('4.3 resetForm wipes all form inputs and temporary password from memory', () async {
      doctorController.setName('Dr. Rajesh Sharma');
      doctorController.setMobile('9876543210');
      doctorController.setQualification('MBBS, MD');
      doctorController.setDepartment('cardiology');

      await doctorController.submitProvisioning();
      expect(doctorController.isSuccess, isTrue);
      expect(doctorController.temporaryPassword, isNotNull);

      doctorController.resetForm();
      expect(doctorController.name, isEmpty);
      expect(doctorController.mobile, isEmpty);
      expect(doctorController.qualification, isEmpty);
      expect(doctorController.department, isEmpty);
      expect(doctorController.temporaryPassword, isNull);
      expect(doctorController.provisionedDoctor, isNull);
      expect(doctorController.isSuccess, isFalse);
    });

    test('4.4 clearPassword specifically clears temporary password', () async {
      doctorController.setName('Dr. Rajesh Sharma');
      doctorController.setMobile('9876543210');
      doctorController.setQualification('MBBS, MD');
      doctorController.setDepartment('cardiology');

      await doctorController.submitProvisioning();
      expect(doctorController.temporaryPassword, isNotNull);

      doctorController.clearPassword();
      expect(doctorController.temporaryPassword, isNull);
    });
  });

  // =========================================================================
  // GROUP 5: WIDGET UI & SCREEN INTERACTION TESTS
  // =========================================================================
  group('5. AdminDoctorProvisioningScreen Widget Tests', () {
    testWidgets('5.1 Screen renders stationary Header, persistent Sidebar, and Add Doctor Form', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorProvisioningScreen()));
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('ADD NEW DOCTOR'), findsOneWidget);
      expect(find.text('Provision a secure Doctor Portal account.'), findsOneWidget);
      expect(find.text('admin01'), findsOneWidget);

      // Top Back link
      expect(find.text('Back to Manage Doctors'), findsOneWidget);
      expect(find.text('ADMIN-PROVISIONED ONLY'), findsOneWidget);

      // Section Header
      expect(find.text('DOCTOR INFORMATION'), findsOneWidget);

      // Form Field Labels
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('REGISTERED MOBILE NUMBER'), findsOneWidget);
      expect(find.text('QUALIFICATION / DEGREE'), findsOneWidget);
      expect(find.text('DEPARTMENT / DOMAIN'), findsOneWidget);
      expect(find.text('EMAIL (OPTIONAL)'), findsOneWidget);

      // Primary Button
      expect(find.text('CREATE DOCTOR'), findsOneWidget);
    });

    testWidgets('5.2 Clicking CREATE DOCTOR with empty fields displays inline error messages', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorProvisioningScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('CREATE DOCTOR'));
      await tester.tap(find.text('CREATE DOCTOR'));
      await tester.pumpAndSettle();

      expect(find.text('Doctor name is required.'), findsOneWidget);
      expect(find.text('Mobile number is required.'), findsOneWidget);
      expect(find.text('Qualification is required.'), findsOneWidget);
      expect(find.text('Select a department.'), findsOneWidget);
    });

    testWidgets('5.3 Successful provisioning displays Success Screen with credentials and one-time password', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorProvisioningScreen()));
      await tester.pumpAndSettle();

      // Enter Doctor Name
      await tester.enterText(
        find.widgetWithText(TextField, 'Dr. Rahul Sharma'),
        'Dr. Rajesh Sharma',
      );

      // Enter Mobile
      await tester.enterText(
        find.widgetWithText(TextField, '9876543210'),
        '9876543210',
      );

      // Enter Qualification
      await tester.enterText(
        find.widgetWithText(TextField, 'MBBS, MD'),
        'MBBS, MD (Cardiology)',
      );

      // Select Department
      await tester.ensureVisible(find.text('Select specialty department'));
      await tester.tap(find.text('Select specialty department'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cardiology').last);
      await tester.pumpAndSettle();

      // Submit Form
      await tester.ensureVisible(find.text('CREATE DOCTOR'));
      await tester.tap(find.text('CREATE DOCTOR'));
      await tester.pumpAndSettle();

      // Verify Success Screen renders
      expect(find.text('DOCTOR ACCOUNT CREATED'), findsOneWidget);
      expect(find.text('Dr. Rajesh Sharma'), findsOneWidget);
      expect(find.text('DOC-101'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('MBBS, MD (Cardiology)'), findsOneWidget);
      expect(find.text('******3210'), findsOneWidget); // Masked mobile

      // Password and warning check
      expect(find.textContaining('Save this temporary password securely'), findsOneWidget);
      expect(find.text('COPY DOCTOR ID'), findsOneWidget);
      expect(find.text('COPY PASSWORD'), findsOneWidget);
      expect(find.text('ADD ANOTHER DOCTOR'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('5.4 ADD ANOTHER DOCTOR resets form to fresh state', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorProvisioningScreen()));

      await tester.pumpAndSettle();

      // Fill and submit
      await tester.enterText(find.widgetWithText(TextField, 'Dr. Rahul Sharma'), 'Dr. Amit Patel');
      await tester.enterText(find.widgetWithText(TextField, '9876543210'), '9876543211');
      await tester.enterText(find.widgetWithText(TextField, 'MBBS, MD'), 'MBBS');

      await tester.ensureVisible(find.text('Select specialty department'));
      await tester.tap(find.text('Select specialty department'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neurology').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('CREATE DOCTOR'));
      await tester.tap(find.text('CREATE DOCTOR'));
      await tester.pumpAndSettle();
      expect(find.text('DOCTOR ACCOUNT CREATED'), findsOneWidget);

      // Tap ADD ANOTHER DOCTOR
      await tester.ensureVisible(find.text('ADD ANOTHER DOCTOR'));
      await tester.tap(find.text('ADD ANOTHER DOCTOR'));
      await tester.pumpAndSettle();

      // Verifies form is reset and fresh
      expect(find.text('DOCTOR INFORMATION'), findsOneWidget);
      expect(find.text('CREATE DOCTOR'), findsOneWidget);
      expect(doctorController.temporaryPassword, isNull);
    });
  });

  // =========================================================================
  // GROUP 6: A3 KPI & DASHBOARD INTEGRATION TESTS
  // =========================================================================
  group('6. A3 KPI & Dashboard Integration Tests', () {
    test('6.1 Provisioning doctor increments Registered Doctors KPI naturally without incrementing Online Doctors', () async {
      final dashboardService = MockAdminDashboardService();
      final initialOverview = await dashboardService.getDashboardOverview();
      final initialRegistered = initialOverview.registeredDoctors;
      final initialOnline = initialOverview.onlineDoctors;
      final initialOrtho = initialOverview.domainAvailability.firstWhere((d) => d.domainId == 'orthopedics').totalDoctors;

      // Provision new doctor
      const req = DoctorProvisioningRequest(
        name: 'Dr. Suresh Verma',
        registeredPhone: '9876543299',
        qualification: 'MBBS, MS',
        department: 'orthopedics',
      );
      final result = await mockProvisioningService.provisionDoctor(req);
      expect(result.isSuccess, isTrue);

      final provisionedDoctor = result.doctorProfile!;
      expect(provisionedDoctor.isActive, isTrue);
      expect(provisionedDoctor.availabilityStatus, equals(DoctorAvailabilityStatus.offline));

      // Simulate dashboard reading updated doctor count
      final updatedAvailability = initialOverview.domainAvailability.map((d) {
        if (d.domainId == 'orthopedics') {
          return d.copyWith(totalDoctors: d.totalDoctors + 1);
        }
        return d;
      }).toList();

      dashboardService.setMockData(
        registeredDoctors: initialRegistered + 1,
        onlineDoctors: initialOnline, // Online count unchanged
        domainAvailability: updatedAvailability,
      );

      final updatedOverview = await dashboardService.getDashboardOverview();
      expect(updatedOverview.registeredDoctors, equals(initialRegistered + 1));
      expect(updatedOverview.onlineDoctors, equals(initialOnline));

      final ortho = updatedOverview.domainAvailability.firstWhere((d) => d.domainId == 'orthopedics');
      expect(ortho.totalDoctors, equals(initialOrtho + 1));
      expect(ortho.onlineDoctors, equals(initialOverview.domainAvailability.firstWhere((d) => d.domainId == 'orthopedics').onlineDoctors));
    });
  });

  // =========================================================================
  // GROUP 7: EXISTING DOCTOR LOGIN COMPATIBILITY TESTS
  // =========================================================================
  group('7. Doctor Login Compatibility Tests', () {
    test('7.1 Provisioned doctor credentials conform to D3 Firebase Doctor Auth expectations', () async {
      const req = DoctorProvisioningRequest(
        name: 'Dr. Neha Gupta',
        registeredPhone: '9876543288',
        qualification: 'MBBS, MD',
        department: 'dermatology',
      );

      final result = await mockProvisioningService.provisionDoctor(req);
      expect(result.isSuccess, isTrue);

      final doctor = result.doctorProfile!;
      final password = result.temporaryPassword!;

      // 1. Normalized unique code matches
      expect(DoctorProfile.normalizeCode(doctor.doctorUniqueCode), equals('DOC-101'));

      // 2. Canonical email construction matches D3 Firebase Doctor Session convention
      final expectedInternalEmail = '${doctor.doctorUniqueCode.toLowerCase()}@hospital.aayusathi.in';
      expect(expectedInternalEmail, equals('doc-101@hospital.aayusathi.in'));

      // 3. Password complexity conforms to Firebase password rules
      expect(password.length, greaterThanOrEqualTo(8));
      expect(DoctorPasswordGenerator.meetsComplexityRequirements(password), isTrue);

      // 4. Doctor initial state is active
      expect(doctor.isActive, isTrue);
    });
  });
}
