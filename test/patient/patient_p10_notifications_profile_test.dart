import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/controllers/patient_profile_controller.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_calendar_item.dart';
import 'package:aayusathi/patient/models/patient_navigation_tab.dart';
import 'package:aayusathi/patient/models/patient_notification_config.dart';
import 'package:aayusathi/patient/models/patient_notification_item.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/screens/patient_dashboard_screen.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_notification_center_screen.dart';
import 'package:aayusathi/patient/screens/patient_profile_screen.dart';
import 'package:aayusathi/patient/services/patient_notification_service.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/widgets/patient_bottom_navigation.dart';
import 'package:aayusathi/patient/widgets/patient_notification_permission_banner.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    onGenerateRoute: PatientRoutes.onGenerateRoute,
    home: PatientLocalizations.provider(
      strings: PatientLocalizations.forLocaleCode(locale.languageCode),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPatientRepository mockPatientRepo;
  late DefaultPatientNotificationService notificationService;

  const testPatientId = 'PAT-P10-001';

  setUp(() async {
    mockPatientRepo = MockPatientRepository.instance;
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockPatientRepository.instance.resetToDefaults();
    MockAppointmentRepository.instance.clear();

    notificationService = DefaultPatientNotificationService();
    notificationService.resetForTesting();
    PatientNotificationService.instance = notificationService;

    final p1 = Patient(
      patientId: testPatientId,
      name: 'Aarav Sharma',
      dateOfBirth: '1981-05-10',
      age: 45,
      gender: 'Male',
      phone: '9876543210',
      bloodGroup: 'O+',
      address: 'Pune, Maharashtra',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockPatientRepo.savePatient(p1);

    PatientAppState.instance.resetSession();
    PatientAppState.instance.setAuthenticatedPatient(p1);
    PatientSessionService.instance.startSession(testPatientId);
  });

  group('Phase P10: Notification Service & Configuration Tests (1-15)', () {
    test('1. Notification service initialization completes safely', () async {
      await notificationService.initialize();
      expect(true, isTrue);
    });

    test('2. Permission request executes without crashing', () async {
      final granted = await notificationService.requestNotificationPermission();
      expect(granted, isTrue);
    });

    test('3. areRemindersEnabled reports correct state', () async {
      // Prior to grant (simulated)
      final initial = await notificationService.areRemindersEnabled();
      expect(initial, isFalse);
      // Request permission
      await notificationService.requestNotificationPermission();
      final after = await notificationService.areRemindersEnabled();
      expect(after, isTrue);
    });

    test('4. Permission granted state updates listeners', () async {
      bool notified = false;
      notificationService.addListener(() => notified = true);
      await notificationService.requestNotificationPermission();
      expect(notified, isTrue);
    });

    test('5. Follow-up reminder scheduling creates correct item in inbox', () async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      await notificationService.scheduleFollowUpReminder(
        eventId: 'VISIT-101',
        visitDate: futureDate,
        title: PatientNotificationConfig.followUpTitle,
        department: 'Cardiology',
        patientId: testPatientId,
      );

      final notifications = notificationService.getNotifications(testPatientId);
      expect(notifications.length, equals(1));
      expect(notifications.first.eventId, equals('VISIT-101'));
      expect(notifications.first.body, contains('Cardiology'));
      expect(notifications.first.isRead, isFalse);
    });

    test('6. 24-hour reminder policy calculates trigger time 24 hours prior', () {
      expect(PatientNotificationConfig.defaultReminderBefore, equals(const Duration(hours: 24)));
      final visit = DateTime(2026, 10, 15, 10, 0);
      final trigger = visit.subtract(PatientNotificationConfig.defaultReminderBefore);
      expect(trigger, equals(DateTime(2026, 10, 14, 10, 0)));
    });

    test('7. Past follow-up is NOT scheduled', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      await notificationService.scheduleFollowUpReminder(
        eventId: 'VISIT-PAST',
        visitDate: pastDate,
        title: 'Past Visit',
        department: 'Neurology',
        patientId: testPatientId,
      );

      final notifications = notificationService.getNotifications(testPatientId);
      expect(notifications, isEmpty);
    });

    test('8. Invalid or cancelled follow-up not scheduled', () async {
      // Empty follow-ups list during sync
      await notificationService.syncFollowUpReminders(
        patientId: testPatientId,
        followUps: [],
      );

      final notifications = notificationService.getNotifications(testPatientId);
      expect(notifications, isEmpty);
    });

    test('9. Duplicate prevention: scheduling same visit repeatedly creates only ONE reminder', () async {
      final futureDate = DateTime.now().add(const Duration(days: 4));
      final items = [
        PatientCalendarItem(
          id: 'VISIT-DUP',
          date: futureDate,
          title: 'Doctor Follow-up',
          doctorName: 'Dr. Mehta',
          caseId: 'CASE-01',
        ),
      ];

      await notificationService.syncFollowUpReminders(patientId: testPatientId, followUps: items);
      await notificationService.syncFollowUpReminders(patientId: testPatientId, followUps: items);
      await notificationService.syncFollowUpReminders(patientId: testPatientId, followUps: items);

      final notifications = notificationService.getNotifications(testPatientId);
      expect(notifications.length, equals(1));
    });

    test('10. Rescheduling cancels old reminder and schedules new one', () async {
      final oldDate = DateTime.now().add(const Duration(days: 3));
      final newDate = DateTime.now().add(const Duration(days: 7));

      await notificationService.syncFollowUpReminders(
        patientId: testPatientId,
        followUps: [
          PatientCalendarItem(
            id: 'VISIT-RESCHED',
            date: oldDate,
            title: 'Cardiology Visit',
            doctorName: 'Dr. Shah',
          ),
        ],
      );
      expect(notificationService.getNotifications(testPatientId).length, equals(1));
      expect(notificationService.getNotifications(testPatientId).first.visitDate, equals(oldDate));

      // Reschedule to new date
      await notificationService.syncFollowUpReminders(
        patientId: testPatientId,
        followUps: [
          PatientCalendarItem(
            id: 'VISIT-RESCHED',
            date: newDate,
            title: 'Cardiology Visit',
            doctorName: 'Dr. Shah',
          ),
        ],
      );

      final updated = notificationService.getNotifications(testPatientId);
      expect(updated.length, equals(1));
      expect(updated.first.visitDate, equals(newDate));
    });

    test('11. Cancellation removes pending reminder', () async {
      final futureDate = DateTime.now().add(const Duration(days: 2));
      await notificationService.scheduleFollowUpReminder(
        eventId: 'VISIT-CANCEL',
        visitDate: futureDate,
        title: 'Checkup',
        department: 'General',
        patientId: testPatientId,
      );

      await notificationService.cancelReminder('VISIT-CANCEL');
      // After sync with empty list, reminder is pruned
      await notificationService.syncFollowUpReminders(patientId: testPatientId, followUps: []);
      final count = notificationService.getNotifications(testPatientId)
          .where((n) => n.eventId == 'VISIT-CANCEL')
          .length;
      expect(count, equals(0));
    });

    test('12. Multiple upcoming visits scheduled correctly', () async {
      final date1 = DateTime.now().add(const Duration(days: 2));
      final date2 = DateTime.now().add(const Duration(days: 6));

      await notificationService.syncFollowUpReminders(
        patientId: testPatientId,
        followUps: [
          PatientCalendarItem(id: 'V1', date: date1, title: 'Visit 1', doctorName: 'Cardiology'),
          PatientCalendarItem(id: 'V2', date: date2, title: 'Visit 2', doctorName: 'Orthopedics'),
        ],
      );

      final notifications = notificationService.getNotifications(testPatientId);
      expect(notifications.length, equals(2));
    });

    testWidgets('13. Notification tap navigation marks read and deep-links to Calendar', (tester) async {
      final futureDate = DateTime(2026, 11, 20);
      notificationService.injectNotificationForTesting(
        testPatientId,
        PatientNotificationItem(
          id: 'TEST-REM-1',
          patientId: testPatientId,
          eventId: 'V-TEST',
          title: 'AAYUSATHI Follow-up Reminder',
          body: 'Your Cardiology follow-up is scheduled for tomorrow.',
          scheduledDate: futureDate.subtract(const Duration(days: 1)),
          visitDate: futureDate,
          createdAt: DateTime.now(),
          department: 'Cardiology',
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        PatientNotificationCenterScreen(service: notificationService),
      ));
      await tester.pumpAndSettle();

      expect(find.text('AAYUSATHI Follow-up Reminder'), findsOneWidget);
      expect(notificationService.getUnreadCount(testPatientId), equals(1));

      // Tap the notification card
      await tester.tap(find.text('AAYUSATHI Follow-up Reminder'));
      await tester.pumpAndSettle();

      // 14. Calendar date selection from notification
      expect(notificationService.getUnreadCount(testPatientId), equals(0));
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.calendar));
      expect(PatientAppState.instance.targetCalendarDate, equals(futureDate));
    });

    test('15. Notification privacy: payload contains NO Aadhaar, phone, UID, or clinical notes', () {
      final body = PatientNotificationConfig.formatFollowUpBody(department: 'Cardiology');
      expect(body.contains('Aadhaar'), isFalse);
      expect(body.contains('9876543210'), isFalse);
      expect(body.contains('UID'), isFalse);
      expect(body.contains('diagnosis'), isFalse);
      expect(body, equals('Your Cardiology follow-up is scheduled for tomorrow.'));
    });
  });

  group('Phase P10: Notification Center & UI Tests (16-19)', () {
    testWidgets('16. Notification center renders title and notification items', (tester) async {
      notificationService.injectNotificationForTesting(
        testPatientId,
        PatientNotificationItem(
          id: 'TEST-1',
          patientId: testPatientId,
          eventId: 'E1',
          title: 'Follow-up Tomorrow',
          body: 'Your Orthopedics follow-up is scheduled for tomorrow.',
          scheduledDate: DateTime.now(),
          visitDate: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        PatientNotificationCenterScreen(service: notificationService),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Follow-up Tomorrow'), findsOneWidget);
    });

    testWidgets('17. Read notification visual distinction (NEW badge absent)', (tester) async {
      notificationService.injectNotificationForTesting(
        testPatientId,
        PatientNotificationItem(
          id: 'TEST-READ',
          patientId: testPatientId,
          eventId: 'E2',
          title: 'Read Notice',
          body: 'This is an already read notification.',
          scheduledDate: DateTime.now(),
          visitDate: DateTime.now().add(const Duration(days: 2)),
          isRead: true,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        PatientNotificationCenterScreen(service: notificationService),
      ));
      await tester.pumpAndSettle();

      expect(find.text('NEW'), findsNothing);
    });

    testWidgets('18. Unread notification shows NEW badge indicator', (tester) async {
      notificationService.injectNotificationForTesting(
        testPatientId,
        PatientNotificationItem(
          id: 'TEST-UNREAD',
          patientId: testPatientId,
          eventId: 'E3',
          title: 'Unread Notice',
          body: 'This notification is unread.',
          scheduledDate: DateTime.now(),
          visitDate: DateTime.now().add(const Duration(days: 2)),
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        PatientNotificationCenterScreen(service: notificationService),
      ));
      await tester.pumpAndSettle();

      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('19. Empty notification state renders when inbox is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PatientNotificationCenterScreen(service: notificationService),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Notifications'), findsOneWidget);
      expect(find.text("You're all caught up."), findsOneWidget);
    });
  });

  group('Phase P10: Patient Profile & Privacy Tests (20-27)', () {
    testWidgets('20. Patient profile screen renders patient information', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Patient Profile'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('AAYUSATHI Patient'), findsOneWidget);
    });

    testWidgets('21. Patient ID display and copy action', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text(testPatientId), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      // Tap copy icon
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('22. Aadhaar completely absent from Profile screen & card', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('aadhar'), findsNothing);
      expect(find.textContaining('UIDAI'), findsNothing);
    });

    testWidgets('23. Phone number is masked (last 4 digits only)', (tester) async {
      final controller = PatientProfileController();
      await controller.loadProfile();

      expect(controller.registeredMobile, equals('******3210'));
      expect(controller.registeredMobile.contains('987654'), isFalse);

      await tester.pumpWidget(_buildTestApp(
        PatientProfileScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.text('******3210'), findsOneWidget);
      expect(find.text('9876543210'), findsNothing);
    });

    testWidgets('24. Profile is strictly read-only (zero edit controls)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.textContaining('Identity information is managed by hospital administration.'), findsOneWidget);
    });

    testWidgets('25. Logout button presence & styling', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('26. Logout confirmation dialog opens and cancels safely', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Log Out'));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog closed, patient session still active
      expect(find.text('Are you sure you want to log out?'), findsNothing);
      expect(PatientAppState.instance.isAuthenticated, isTrue);
    });

    testWidgets('27. Patient session clearing on confirmed logout', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Log Out'));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Confirm logout
      final confirmLogoutButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(ElevatedButton),
      );
      await tester.tap(confirmLogoutButton);
      await tester.pumpAndSettle();

      expect(PatientAppState.instance.isAuthenticated, isFalse);
      expect(PatientAppState.instance.authenticatedPatientId, isNull);
      expect(PatientSessionService.instance.isAuthenticated, isFalse);
    });
  });

  group('Phase P10: Regressions & UI Polish Tests (28-33)', () {
    testWidgets('28. Four-tab bottom navigation remains stationary', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientMainShellScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PatientBottomNavigation), findsOneWidget);
      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Dashboard')), findsOneWidget);
      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Cases')), findsOneWidget);
      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Reports')), findsOneWidget);
      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Calendar')), findsOneWidget);
      // No fifth tab
      final items = tester.widgetList(find.byType(InkResponse)).toList();
      expect(items.length, lessThanOrEqualTo(5)); // Top bar + 4 tabs
    });

    testWidgets('29. P8 report upload regression: Reports screen renders tabs & CTA', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientMainShellScreen(initialTab: PatientNavigationTab.reports),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.text('YET TO SUBMIT'), findsOneWidget);
    });

    testWidgets('30. P9 Calendar regression: month header and calendar grid render', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientMainShellScreen(initialTab: PatientNavigationTab.calendar),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsWidgets);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('31. Dashboard Next Visit card integrates cleanly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const PatientDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Visits'), findsOneWidget);
      expect(find.text('No Ongoing Cases'), findsOneWidget);
    });

    testWidgets('32. Responsive mobile layout (360dp width) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(
        const PatientProfileScreen(),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('33. Educational notification permission banner renders and dismisses cleanly', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(_buildTestApp(
        PatientNotificationPermissionBanner(
          onDismiss: () => dismissed = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Follow-up Reminder'), findsOneWidget);
      expect(find.text('Get reminders for your upcoming follow-up visits.'), findsOneWidget);
      expect(find.text('Allow Notifications'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });
  });
}
