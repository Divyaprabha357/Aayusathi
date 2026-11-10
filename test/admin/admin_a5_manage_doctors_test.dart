import 'package:aayusathi/admin/controllers/admin_manage_doctors_controller.dart';
import 'package:aayusathi/admin/localization/admin_localizations.dart';
import 'package:aayusathi/admin/screens/admin_doctors_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/widgets/admin_buttons.dart';
import 'package:aayusathi/admin/widgets/admin_doctor_details_dialog.dart';
import 'package:aayusathi/admin/widgets/admin_doctor_status_dialogs.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorRepository mockDoctorRepo;
  late MockAuditRepository mockAuditRepo;
  late AdminManageDoctorsController controller;

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    AdminAuthService.instance.resetForTesting();
    AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

    mockDoctorRepo = MockDoctorRepository.instance;
    mockDoctorRepo.resetToDefaults();

    mockAuditRepo = MockAuditRepository.instance;
    mockAuditRepo.clear();

    controller = AdminManageDoctorsController.instance;
    controller.resetForTesting();
    controller.setCustomRepositories(
      doctorRepository: mockDoctorRepo,
      auditRepository: mockAuditRepo,
    );
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
  // GROUP 1: CONTROLLER UNIT TESTS
  // =========================================================================
  group('1. AdminManageDoctorsController Unit Tests', () {
    test('1.1 Loads default doctors from repository and calculates counts', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.totalCount, equals(10));
      expect(controller.activeCount, equals(10));
      expect(controller.inactiveCount, equals(0));
      expect(controller.filteredDoctors.length, equals(10));
    });

    test('1.2 Search query filters doctors by ID, name, department, phone, email', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      // By Doctor ID
      controller.setSearchQuery('DOC-CARD-01');
      expect(controller.filteredDoctors.length, equals(1));
      expect(controller.filteredDoctors.first.doctorId, equals('DOC-CARD-01'));

      // By Name substring
      controller.setSearchQuery('Ramesh');
      expect(controller.filteredDoctors.length, equals(1));
      expect(controller.filteredDoctors.first.name, contains('Ramesh'));

      // By Department
      controller.setSearchQuery('neurology');
      expect(controller.filteredDoctors.length, equals(2));

      // By Phone substring
      controller.setSearchQuery('3200');
      expect(controller.filteredDoctors.length, equals(1));

      // Reset
      controller.setSearchQuery('');
      expect(controller.filteredDoctors.length, equals(10));
    });

    test('1.3 Department filter restricts results to specific domain', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      controller.setSelectedDepartment('cardiology');
      expect(controller.filteredDoctors.length, equals(2));
      expect(controller.filteredDoctors.every((d) => d.department == 'cardiology'), isTrue);

      controller.setSelectedDepartment('orthopedics');
      expect(controller.filteredDoctors.length, equals(1));

      controller.setSelectedDepartment(null);
      expect(controller.filteredDoctors.length, equals(10));
    });

    test('1.4 Status filter and Sorting options work deterministically', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      // Deactivate one doctor
      final target = controller.allDoctors.first;
      await controller.setDoctorActiveStatus(doctor: target, newActiveStatus: false);

      expect(controller.activeCount, equals(9));
      expect(controller.inactiveCount, equals(1));

      // Filter active only
      controller.setSelectedStatus('active');
      expect(controller.filteredDoctors.length, equals(9));

      // Filter inactive only
      controller.setSelectedStatus('inactive');
      expect(controller.filteredDoctors.length, equals(1));
      expect(controller.filteredDoctors.first.doctorId, equals(target.doctorId));

      // Reset status and test sorting
      controller.setSelectedStatus(null);
      controller.setSortOption(DoctorSortOption.nameAsc);
      final sortedNames = controller.filteredDoctors.map((d) => d.name).toList();
      final expectedNames = List<String>.from(sortedNames)..sort();
      expect(sortedNames, equals(expectedNames));
    });

    test('1.5 Safeguard: Cannot deactivate a doctor who is currently IN_CONSULTATION', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      // Mark doctor as IN_CONSULTATION
      mockDoctorRepo.setDoctorAvailabilityStatus(
        doctorId: 'DOC-CARD-01',
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-CARD-01');
      expect(doc.availabilityStatus, equals(DoctorAvailabilityStatus.inConsultation));

      final canDeactivate = await controller.setDoctorActiveStatus(
        doctor: doc,
        newActiveStatus: false,
      );

      expect(canDeactivate, isFalse);
      expect(controller.actionError, contains('in consultation'));
      expect(mockAuditRepo.logs.any((l) => l.action == 'DOCTOR_DEACTIVATED'), isFalse);
    });

    test('1.6 Deactivating an available doctor updates status and logs DOCTOR_DEACTIVATED audit', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-CARD-02');
      final success = await controller.setDoctorActiveStatus(
        doctor: doc,
        newActiveStatus: false,
      );

      expect(success, isTrue);
      await Future.delayed(const Duration(milliseconds: 50));

      final updated = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-CARD-02');
      expect(updated.isActive, isFalse);

      // Audit log verification
      final audit = mockAuditRepo.logs.lastWhere((l) => l.entityId == 'DOC-CARD-02');
      expect(audit.action, equals('DOCTOR_DEACTIVATED'));
      expect(audit.actorType, equals('ADMIN'));
      expect(audit.actorId, equals('admin01'));
    });

    test('1.7 Activating an inactive doctor updates status and logs DOCTOR_ACTIVATED audit', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      // First deactivate
      final doc = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-ORTH-01');
      await controller.setDoctorActiveStatus(doctor: doc, newActiveStatus: false);
      await Future.delayed(const Duration(milliseconds: 50));

      // Reactivate
      final inactiveDoc = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-ORTH-01');
      final success = await controller.setDoctorActiveStatus(
        doctor: inactiveDoc,
        newActiveStatus: true,
      );

      expect(success, isTrue);
      await Future.delayed(const Duration(milliseconds: 50));

      final updated = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-ORTH-01');
      expect(updated.isActive, isTrue);

      final audit = mockAuditRepo.logs.lastWhere((l) => l.entityId == 'DOC-ORTH-01');
      expect(audit.action, equals('DOCTOR_ACTIVATED'));
    });

    test('1.8 Safeguard: Cannot change department while doctor is IN_CONSULTATION', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      mockDoctorRepo.setDoctorAvailabilityStatus(
        doctorId: 'DOC-CARD-01',
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-CARD-01');
      final success = await controller.updateDoctorProfile(
        doctor: doc,
        name: doc.name,
        qualification: doc.qualification,
        department: 'neurology',
        registeredPhone: doc.registeredPhone,
      );

      expect(success, isFalse);
      expect(controller.actionError, contains('in consultation'));
    });

    test('1.9 Updating profile fields and department records DOCTOR_DEPARTMENT_CHANGED audit', () async {
      controller.init();
      await Future.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-GEN-01');
      final success = await controller.updateDoctorProfile(
        doctor: doc,
        name: 'Dr. Arvind Deshmukh MD',
        qualification: 'MBBS, MD, DNB',
        department: 'cardiology',
        registeredPhone: '9876543299',
        email: 'dr.arvind@hospital.aayusathi.in',
      );

      expect(success, isTrue);
      await Future.delayed(const Duration(milliseconds: 50));

      final updated = controller.allDoctors.firstWhere((d) => d.doctorId == 'DOC-GEN-01');
      expect(updated.name, equals('Dr. Arvind Deshmukh MD'));
      expect(updated.qualification, equals('MBBS, MD, DNB'));
      expect(updated.department, equals('cardiology'));
      expect(updated.registeredPhone, equals('9876543299'));

      final audit = mockAuditRepo.logs.lastWhere((l) => l.entityId == 'DOC-GEN-01');
      expect(audit.action, equals('DOCTOR_DEPARTMENT_CHANGED'));
      expect(audit.metadata['oldDepartment'], equals('general_medicine'));
      expect(audit.metadata['newDepartment'], equals('cardiology'));
    });
  });

  // =========================================================================
  // GROUP 2: WIDGET UI & SCREEN INTERACTION TESTS
  // =========================================================================
  group('2. AdminDoctorsScreen Widget Tests', () {
    testWidgets('2.1 Screen renders stationary Header, persistent Sidebar, Metrics, and Doctors Table', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorsScreen()));
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('MANAGE DOCTORS'), findsAtLeastNWidgets(1));
      expect(find.text('admin01'), findsOneWidget);

      // Metrics strip verification
      expect(find.text('Total Provisioned'), findsOneWidget);
      expect(find.text('Active Doctors'), findsOneWidget);
      expect(find.text('Deactivated Doctors'), findsOneWidget);

      // Table Column Headers
      expect(find.text('DOCTOR ID'), findsOneWidget);
      expect(find.text('DOCTOR NAME'), findsOneWidget);
      expect(find.text('DEPARTMENT'), findsOneWidget);
      expect(find.text('MOBILE'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);

      // Doctors rendered in table rows
      expect(find.text('Dr. Ramesh Gupta'), findsOneWidget);
      expect(find.text('DOC-CARD-01'), findsOneWidget);
      expect(find.text('Dr. Sunita Rao'), findsOneWidget);
      expect(find.text('ADD NEW DOCTOR'), findsOneWidget);
    });

    testWidgets('2.2 Search input filters table rows dynamically in UI', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorsScreen()));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(
        find.widgetWithText(TextField, 'Search by Doctor ID, name, or phone...'),
        'Priya',
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Priya Kulkarni'), findsOneWidget);
      expect(find.text('Dr. Ramesh Gupta'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Ramesh Gupta'), findsOneWidget);
    });

    testWidgets('2.3 Clicking Inspection button opens Doctor Details modal with privacy-masked phone', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorsScreen()));
      await tester.pumpAndSettle();

      // Click first inspect icon
      final inspectButton = find.byIcon(Icons.visibility_outlined).first;
      await tester.ensureVisible(inspectButton);
      await tester.tap(inspectButton);
      await tester.pumpAndSettle();

      // Details Modal verification
      expect(find.byType(AdminDoctorDetailsDialog), findsOneWidget);
      expect(find.text('PHYSICIAN PROFILE RECORD'), findsOneWidget);
      expect(find.text('ACTIVE ACCOUNT'), findsOneWidget);
      expect(find.text('Historical consultation, diagnostic, and prescription records remain permanently associated with this physician identity.'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDoctorDetailsDialog), findsNothing);
    });

    testWidgets('2.4 Deactivation button shows confirmation dialog and deactivates doctor', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorsScreen()));
      await tester.pumpAndSettle();

      // Tap first toggle button
      final toggleButton = find.byIcon(Icons.toggle_on_rounded).first;
      await tester.ensureVisible(toggleButton);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminDeactivateDoctorDialog), findsOneWidget);
      expect(find.text('DEACTIVATE DOCTOR ACCOUNT'), findsOneWidget);
      expect(find.text('CONFIRM DEACTIVATION'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('CONFIRM DEACTIVATION'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDeactivateDoctorDialog), findsNothing);
      expect(find.text('Doctor account deactivated successfully.'), findsOneWidget);
    });

    testWidgets('2.5 Active Consultation Safeguard prevents deactivation in UI', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Put first doctor in consultation before screen initializes
      final doc = mockDoctorRepo.getAllDoctorProfilesSync().first;
      mockDoctorRepo.setDoctorAvailabilityStatus(
        doctorId: doc.doctorId,
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );
      controller.resetForTesting();
      controller.setCustomRepositories(
        doctorRepository: mockDoctorRepo,
        auditRepository: mockAuditRepo,
      );

      await tester.pumpWidget(createTestWidget(const AdminDoctorsScreen()));
      await tester.pumpAndSettle();

      // Click toggle on the doctor in consultation
      final toggleButton = find.byIcon(Icons.toggle_on_rounded).first;
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Dialog shows active consultation safeguard
      expect(find.text('CANNOT DEACTIVATE DOCTOR'), findsOneWidget);
      expect(find.textContaining('This physician is currently IN CONSULTATION with a patient'), findsOneWidget);
      expect(find.text('CONFIRM DEACTIVATION'), findsNothing); // No confirm button rendered

      // Close safeguard modal
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDeactivateDoctorDialog), findsNothing);
    });

    testWidgets('2.6 Edit Doctor Dialog updates profile and warns on department transfer', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorsScreen()));
      await tester.pumpAndSettle();

      // Tap Edit button
      final editButton = find.byIcon(Icons.edit_outlined).first;
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminEditDoctorDialog), findsOneWidget);
      expect(find.text('EDIT DOCTOR PROFILE'), findsOneWidget);

      // Change name
      final nameField = find.descendant(
        of: find.byType(AdminEditDoctorDialog),
        matching: find.byType(TextField),
      ).first;
      await tester.enterText(nameField, 'Dr. Updated Senior Physician');
      await tester.pumpAndSettle();

      // Save
      final saveButton = find.descendant(
        of: find.byType(AdminEditDoctorDialog),
        matching: find.byType(AdminPrimaryButton),
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminEditDoctorDialog), findsNothing);
      expect(find.text('Doctor profile updated successfully.'), findsOneWidget);
      expect(find.text('Dr. Updated Senior Physician'), findsOneWidget);
    });




    testWidgets('2.7 Responsive layout maintains stability on 1366x768 and 1920x1080 viewports', (tester) async {
      // 1. Laptop Viewport: 1366x768
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const AdminDoctorsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MANAGE DOCTORS'), findsAtLeastNWidgets(1));
      expect(find.byType(DataTable), findsOneWidget);

      // 2. Full HD Viewport: 1920x1080
      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpAndSettle();

      expect(find.text('MANAGE DOCTORS'), findsAtLeastNWidgets(1));
      expect(find.byType(DataTable), findsOneWidget);
    });
  });
}
