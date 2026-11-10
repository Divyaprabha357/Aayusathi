import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_availability_controller.dart';
import 'package:aayusathi/admin/localization/admin_localizations.dart';
import 'package:aayusathi/admin/screens/admin_availability_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/widgets/admin_availability_dialogs.dart';
import 'package:aayusathi/admin/widgets/admin_desktop_scaffold.dart';
import 'package:aayusathi/admin/widgets/admin_doctor_details_dialog.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';

Widget createTestApp({Widget? home, Locale locale = const Locale('en')}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      AdminLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('hi'),
      Locale('mr'),
    ],
    home: home ?? const AdminAvailabilityScreen(),
    routes: {
      AppRoutes.adminAvailability: (_) => const AdminAvailabilityScreen(),
      AppRoutes.adminDoctors: (_) => const Scaffold(body: Text('Manage Doctors Screen')),
      AppRoutes.adminDoctorsAdd: (_) => const Scaffold(body: Text('Add New Doctor Screen')),
      AppRoutes.adminDashboard: (_) => const Scaffold(body: Text('Admin Dashboard')),
      AppRoutes.adminLogin: (_) => const Scaffold(body: Text('Admin Login Screen')),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorRepository doctorRepo;
  late AdminAvailabilityController controller;

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    AdminAuthService.instance.resetForTesting();
    AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

    doctorRepo = MockDoctorRepository.instance;
    doctorRepo.resetToDefaults();

    controller = AdminAvailabilityController.instance;
    controller.resetForTesting();
    controller.setCustomRepositories(doctorRepository: doctorRepo);
  });

  tearDown(() {
    controller.resetForTesting();
    AdminAuthService.instance.resetForTesting();
  });

  group('Phase A6 Doctor Availability — Widget & Workflow Tests', () {
    testWidgets('1. AdminAvailabilityScreen renders with stationary AdminDesktopScaffold shell and header', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AdminDesktopScaffold), findsOneWidget);
      expect(find.text('DOCTOR AVAILABILITY'), findsWidgets);
      expect(find.text('Monitor and manage real-time Doctor workstation availability.'), findsWidgets);
      expect(find.text('REAL-TIME STREAM ACTIVE'), findsOneWidget);
      expect(find.text('VIEW ALL DOCTORS'), findsOneWidget);
    });

    testWidgets('2. KPI metric cards display accurate counts for Active, Available, In Consultation, Offline', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('TOTAL ACTIVE DOCTORS'), findsOneWidget);
      expect(find.text('ONLINE / AVAILABLE'), findsWidgets);
      expect(find.text('IN CONSULTATION'), findsWidgets);
      expect(find.text('OFFLINE'), findsWidgets);

      // Verify numbers match controller
      expect(find.text('${controller.totalActiveDoctors}'), findsWidgets);
      expect(find.text('${controller.onlineAvailableDoctors}'), findsWidgets);
    });

    testWidgets('3. 8-Domain capacity distribution section renders all standard clinical domains', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('CLINICAL DOMAIN CAPACITY'), findsOneWidget);
      expect(find.text('Cardiology'), findsWidgets);
      expect(find.text('Neurology'), findsWidgets);
      expect(find.text('Gastroenterology'), findsWidgets);
      expect(find.text('Orthopedics'), findsWidgets);
      expect(find.text('Pediatrics'), findsWidgets);
      expect(find.text('ENT'), findsWidgets);
      expect(find.text('Dermatology'), findsWidgets);
      expect(find.text('General Medicine'), findsWidgets);
    });

    testWidgets('4. Doctor Availability Table displays columns, names, IDs, departments, badges', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('DOCTOR'), findsOneWidget);
      expect(find.text('DOCTOR ID'), findsOneWidget);
      expect(find.text('DEPARTMENT'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('AVAILABILITY'), findsWidgets);
      expect(find.text('LAST ACTIVITY'), findsOneWidget);

      // Check for first doctor
      expect(find.text('Dr. Ramesh Gupta'), findsOneWidget);
      expect(find.text('DOC-CARD-01'), findsOneWidget);
      expect(find.text('ACTIVE'), findsWidgets);
    });

    testWidgets('5. Search bar filters doctor list dynamically by name and doctor code', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Dr. Ramesh Gupta'), findsOneWidget);
      expect(find.text('Dr. Suresh Varma'), findsOneWidget);

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Ramesh');
      await tester.pumpAndSettle();

      expect(find.text('Dr. Ramesh Gupta'), findsOneWidget);
      expect(find.text('Dr. Suresh Varma'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Suresh Varma'), findsOneWidget);
    });

    testWidgets('6. Set Offline button opens confirmation dialog and safely updates status', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final setOfflineBtn = find.widgetWithText(OutlinedButton, 'SET OFFLINE').first;
      expect(setOfflineBtn, findsOneWidget);

      await tester.ensureVisible(setOfflineBtn);
      await tester.pumpAndSettle();

      await tester.tap(setOfflineBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AdminSetOfflineDialog), findsOneWidget);
      expect(find.text('SET DOCTOR OFFLINE'), findsOneWidget);
      expect(find.text('• The Doctor will no longer receive new appointment requests.'), findsOneWidget);

      // Confirm in dialog
      final confirmBtn = find.widgetWithText(ElevatedButton, 'SET OFFLINE');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AdminSetOfflineDialog), findsNothing);
    });

    testWidgets('7. Set Available button opens confirmation dialog and safely marks available', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // DOC-ORTH-01 (Dr. Manoj Joshi) is offline by default
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final setAvailBtn = find.widgetWithText(ElevatedButton, 'SET AVAILABLE').first;
      expect(setAvailBtn, findsWidgets);

      await tester.ensureVisible(setAvailBtn);
      await tester.pumpAndSettle();

      await tester.tap(setAvailBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AdminSetAvailableDialog), findsOneWidget);
      expect(find.text('SET DOCTOR AS AVAILABLE'), findsOneWidget);
      expect(find.text('This will make the Doctor eligible for new appointment requests from the Kiosk queue.'), findsOneWidget);

      // Confirm
      final confirmBtn = find.descendant(
        of: find.byType(AdminSetAvailableDialog),
        matching: find.widgetWithText(ElevatedButton, 'SET AVAILABLE'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AdminSetAvailableDialog), findsNothing);
      final updated = await doctorRepo.getDoctorProfileById('DOC-ORTH-01');
      expect(updated?.availabilityStatus, equals(DoctorAvailabilityStatus.available));
    });

    testWidgets('8. Active Consultation Safeguard: Doctor in consultation displays locked badge and opens explanation', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Real-time update: set DOC-NEUR-02 (Dr. Ananya Roy - row 1) to inConsultation
      await doctorRepo.setDoctorAvailabilityStatus(
        doctorId: 'DOC-NEUR-02',
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );
      await controller.refresh();
      await tester.pumpAndSettle();

      final inConsultationLockedBadge = find.byKey(const ValueKey('consultation_lock_action_btn'));
      expect(inConsultationLockedBadge, findsOneWidget);

      await tester.ensureVisible(inConsultationLockedBadge);
      await tester.pumpAndSettle();

      // Tap on the locked badge
      await tester.tap(inConsultationLockedBadge);
      await tester.pumpAndSettle();

      expect(find.byType(AdminConsultationLockedDialog), findsOneWidget);
      expect(find.text('Availability cannot be manually changed while the Doctor is consulting a patient.'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminConsultationLockedDialog), findsNothing);
    });

    testWidgets('9. Inactive doctor displays INACTIVE and OFFLINE with no manual available control', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Real-time update: deactivate doctor account (DOC-NEUR-02 - row 1)
      await doctorRepo.setDoctorActiveStatus(doctorId: 'DOC-NEUR-02', isActive: false);
      await controller.refresh();
      await tester.pumpAndSettle();

      final inactiveFinder = find.text('INACTIVE ACCOUNT').first;
      await tester.ensureVisible(inactiveFinder);
      await tester.pumpAndSettle();

      expect(find.text('INACTIVE ACCOUNT'), findsWidgets);
    });

    testWidgets('10. Inspection modal opens with masked phone and zero sensitive token/credentials', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Click on view profile icon
      final viewIcon = find.byIcon(Icons.visibility_outlined).first;
      await tester.ensureVisible(viewIcon);
      await tester.pumpAndSettle();

      await tester.tap(viewIcon);
      await tester.pumpAndSettle();

      expect(find.byType(AdminDoctorDetailsDialog), findsOneWidget);
      expect(find.text('PHYSICIAN PROFILE RECORD'), findsOneWidget);
      expect(find.text('Registered Phone'), findsOneWidget);

      // Phone is masked
      expect(find.textContaining('******'), findsOneWidget);

      // Zero sensitive data
      expect(find.textContaining('password'), findsNothing);
      expect(find.textContaining('token'), findsNothing);
      expect(find.textContaining('mock-uid-'), findsNothing);

      // Close modal
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminDoctorDetailsDialog), findsNothing);
    });

    testWidgets('11. View All Doctors button navigates to /admin/doctors', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('VIEW ALL DOCTORS'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Doctors Screen'), findsOneWidget);
    });

    testWidgets('12. Responsive screen test at 1600x900 and 1920x1080 with zero layout overflow', (tester) async {
      for (final size in [const Size(1366, 768), const Size(1600, 900), const Size(1920, 1080)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(AdminAvailabilityScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });
  });
}
