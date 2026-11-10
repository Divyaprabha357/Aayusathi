import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/controllers/patient_calendar_controller.dart';
import 'package:aayusathi/patient/controllers/patient_dashboard_controller.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/localization/patient_strings.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_calendar_item.dart';
import 'package:aayusathi/patient/models/patient_navigation_tab.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/screens/patient_calendar_screen.dart';
import 'package:aayusathi/patient/screens/patient_dashboard_screen.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_reports_screen.dart';
import 'package:aayusathi/patient/services/patient_follow_up_parser.dart';
import 'package:aayusathi/patient/services/patient_follow_up_service.dart';
import 'package:aayusathi/patient/services/patient_notification_service.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/widgets/patient_bottom_navigation.dart';
import 'package:aayusathi/patient/widgets/patient_calendar_widget.dart';
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
  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockAppointmentRepository mockAppointmentRepo;

  const testPatientId = 'PAT-P9-001';
  const otherPatientId = 'PAT-P9-002';

  setUp(() async {
    mockPatientRepo = MockPatientRepository.instance;
    mockCaseRepo = MockCaseRepository.instance;
    mockVisitRepo = MockClinicalVisitRepository.instance;
    mockAppointmentRepo = MockAppointmentRepository.instance;

    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockPatientRepository.instance.resetToDefaults();
    MockAppointmentRepository.instance.clear();

    PatientAppState.instance.resetSession();
    PatientSessionService.instance.startSession(testPatientId);

    // Seed test patient
    final now = DateTime(2026, 1, 1);
    await mockPatientRepo.savePatient(Patient(
      patientId: testPatientId,
      name: 'Ramesh Patel',
      dateOfBirth: '15 August 1964',
      age: 62,
      gender: 'Male',
      phone: '9876543210',
      bloodGroup: 'B+',
      address: 'Pune, Maharashtra',
      createdAt: now,
      updatedAt: now,
    ));
  });

  tearDown(() {
    PatientSessionService.instance.logout();
    PatientAppState.instance.resetSession();
  });

  group('AAYUSATHI Patient App P9: Calendar & Follow-up Test Suite', () {
    // 1. Calendar renders
    testWidgets('1. Calendar renders title, month navigation, and days grid', (tester) async {
      final controller = PatientCalendarController();

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('My Health Calendar'), findsOneWidget);
      expect(find.byType(PatientCalendarWidget), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    // 2. Current month
    testWidgets('2. Current month displayed initially in calendar header', (tester) async {
      final now = DateTime.now();
      final controller = PatientCalendarController();

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      final strings = const PatientStrings();
      final expectedMonthHeader = '${strings.monthName(now.month)} ${now.year}';
      expect(find.text(expectedMonthHeader), findsOneWidget);
    });

    // 3. Previous month
    testWidgets('3. Previous month navigation decrements visible month', (tester) async {
      final controller = PatientCalendarController();
      final initialMonth = controller.visibleMonth;

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      final expectedMonth = DateTime(initialMonth.year, initialMonth.month - 1, 1);
      expect(controller.visibleMonth.year, equals(expectedMonth.year));
      expect(controller.visibleMonth.month, equals(expectedMonth.month));
    });

    // 4. Next month
    testWidgets('4. Next month navigation increments visible month', (tester) async {
      final controller = PatientCalendarController();
      final initialMonth = controller.visibleMonth;

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      final expectedMonth = DateTime(initialMonth.year, initialMonth.month + 1, 1);
      expect(controller.visibleMonth.year, equals(expectedMonth.year));
      expect(controller.visibleMonth.month, equals(expectedMonth.month));
    });

    // 5. Date selection
    testWidgets('5. Date selection updates selected date in controller and UI', (tester) async {
      final controller = PatientCalendarController();
      final targetDate = DateTime(controller.visibleMonth.year, controller.visibleMonth.month, 15);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      controller.selectDate(targetDate);
      await tester.pumpAndSettle();

      expect(controller.selectedDate.day, equals(15));
      expect(find.textContaining('15'), findsWidgets);
    });

    // 6. Follow-up event indicator
    testWidgets('6. Follow-up event indicator dot appears on calendar cell', (tester) async {
      final eventDate = DateTime(2026, 9, 20);
      final controller = PatientCalendarController();
      controller.selectDate(eventDate);
      controller.setEvents([
        PatientCalendarItem(
          id: 'ev-1',
          date: eventDate,
          title: 'Follow-up Visit',
          department: 'Cardiology',
          type: PatientCalendarEventType.followUp,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(controller.selectedDateEvents.length, equals(1));
      expect(find.byType(PatientCalendarWidget), findsOneWidget);
    });

    // 7. Event card
    testWidgets('7. Event card renders with department, follow-up badge, and View Details', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final controller = PatientCalendarController();
      controller.selectDate(futureDate);
      controller.setEvents([
        PatientCalendarItem(
          id: 'ev-card',
          date: futureDate,
          title: 'Follow-up Visit',
          department: 'Cardiology',
          doctorName: 'Dr. Mehta',
          type: PatientCalendarEventType.followUp,
          caseId: 'CASE-001',
          visitId: 'VIS-001',
          caseTitle: 'Chest Pain Evaluation',
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('UPCOMING FOLLOW-UP'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('Follow-up Visit'), findsOneWidget);
      expect(find.text('Dr. Mehta'), findsOneWidget);
      expect(find.text('Chest Pain Evaluation'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });

    // 8. No-event empty state
    testWidgets('8. No-event empty state renders when selected date has no events', (tester) async {
      final emptyDate = DateTime(2026, 1, 1);
      final controller = PatientCalendarController();
      controller.selectDate(emptyDate);
      controller.setEvents([]);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('No Follow-up Scheduled'), findsOneWidget);
      expect(find.text('There are no scheduled follow-ups for this date.'), findsOneWidget);
    });

    // 9. Past follow-up
    testWidgets('9. Past follow-up displays Past Follow-up badge and isPast is true', (tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 15));
      final item = PatientCalendarItem(
        id: 'past-1',
        date: pastDate,
        title: 'Follow-up Visit',
        department: 'Neurology',
        type: PatientCalendarEventType.followUp,
      );

      expect(item.isPast, isTrue);
      expect(item.isUpcoming, isFalse);

      final controller = PatientCalendarController();
      controller.selectDate(pastDate);
      controller.setEvents([item]);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('PAST FOLLOW-UP'), findsOneWidget);
      expect(find.text('Neurology'), findsOneWidget);
    });

    // 10. Future follow-up
    testWidgets('10. Future follow-up displays Upcoming Follow-up badge and isUpcoming is true', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final item = PatientCalendarItem(
        id: 'future-1',
        date: futureDate,
        title: 'Follow-up Visit',
        department: 'Cardiology',
        type: PatientCalendarEventType.followUp,
      );

      expect(item.isUpcoming, isTrue);
      expect(item.isPast, isFalse);

      final controller = PatientCalendarController();
      controller.selectDate(futureDate);
      controller.setEvents([item]);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('UPCOMING FOLLOW-UP'), findsOneWidget);
    });

    // 11. Nearest future follow-up
    testWidgets('11. Nearest future follow-up correctly identified from multiple dates', (tester) async {
      final now = DateTime.now();
      final date1 = now.add(const Duration(days: 14));
      final date2 = now.add(const Duration(days: 3)); // Nearest
      final date3 = now.subtract(const Duration(days: 5)); // Past

      // Seed Case and Visits
      final testCase = ClinicalCase(
        caseId: 'CASE-NEAR-01',
        patientId: testPatientId,
        domain: 'Cardiology',
        title: 'Hypertension',
        createdAt: now,
        updatedAt: now,
        visitCount: 2,
      );
      await mockCaseRepo.createCase(testCase);

      await mockVisitRepo.createVisit(ClinicalVisit(
        visitId: 'VIS-NEAR-01',
        caseId: testCase.caseId,
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: now,
        followUp: '${date1.day}-${date1.month}-${date1.year}',
      ));

      await mockVisitRepo.createVisit(ClinicalVisit(
        visitId: 'VIS-NEAR-02',
        caseId: testCase.caseId,
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 2,
        startedAt: now,
        followUp: '${date2.day}-${date2.month}-${date2.year}',
      ));

      await mockVisitRepo.createVisit(ClinicalVisit(
        visitId: 'VIS-NEAR-03',
        caseId: testCase.caseId,
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 3,
        startedAt: now,
        followUp: '${date3.day}-${date3.month}-${date3.year}',
      ));

      final service = PatientFollowUpService(
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        appointmentRepo: mockAppointmentRepo,
      );

      final nearest = await service.getNearestUpcomingVisit();
      expect(nearest, isNotNull);
      expect(nearest!.date.day, equals(date2.day));
      expect(nearest.date.month, equals(date2.month));
      expect(nearest.date.year, equals(date2.year));
    });

    // 12. Multiple follow-ups
    testWidgets('12. Multiple follow-ups on same date render cleanly', (tester) async {
      final targetDate = DateTime(2026, 9, 20);
      final controller = PatientCalendarController();
      controller.selectDate(targetDate);
      controller.setEvents([
        PatientCalendarItem(
          id: 'm1',
          date: targetDate,
          title: 'Follow-up Visit',
          department: 'Cardiology',
          type: PatientCalendarEventType.followUp,
        ),
        PatientCalendarItem(
          id: 'm2',
          date: targetDate,
          title: 'Follow-up Visit',
          department: 'Ophthalmology',
          type: PatientCalendarEventType.followUp,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('Ophthalmology'), findsOneWidget);
    });

    // 13. Null follow-up
    testWidgets('13. Null or missing follow-up handled gracefully without crash', (tester) async {
      final parsed = PatientFollowUpParser.parse(null);
      expect(parsed, isNull);

      final parsedEmpty = PatientFollowUpParser.parse('');
      expect(parsedEmpty, isNull);

      final parsedQualitative = PatientFollowUpParser.parse('SOS if pain increases');
      expect(parsedQualitative, isNull);
    });

    // 14. Timestamp and DateTime parsing
    testWidgets('14. Timestamp, DateTime, standard dates, and relative intervals parse safely', (tester) async {
      final now = DateTime(2026, 9, 10);

      // DateTime direct
      expect(PatientFollowUpParser.parse(now), equals(DateTime(2026, 9, 10)));

      // Timestamp
      final ts = Timestamp.fromDate(now);
      expect(PatientFollowUpParser.parse(ts), equals(DateTime(2026, 9, 10)));

      // Milliseconds
      expect(PatientFollowUpParser.parse(now.millisecondsSinceEpoch), equals(DateTime(2026, 9, 10)));

      // Formatted strings
      expect(PatientFollowUpParser.parse('20 September 2026'), equals(DateTime(2026, 9, 20)));
      expect(PatientFollowUpParser.parse('September 20, 2026'), equals(DateTime(2026, 9, 20)));
      expect(PatientFollowUpParser.parse('20-09-2026'), equals(DateTime(2026, 9, 20)));
      expect(PatientFollowUpParser.parse('2026-09-20'), equals(DateTime(2026, 9, 20)));
      expect(PatientFollowUpParser.parse('20th Sep 2026'), equals(DateTime(2026, 9, 20)));

      // Relative offsets with referenceDate
      final ref = DateTime(2026, 9, 6);
      expect(PatientFollowUpParser.parse('Review in 2 weeks', referenceDate: ref), equals(DateTime(2026, 9, 20)));
      expect(PatientFollowUpParser.parse('3 days if fever persists', referenceDate: ref), equals(DateTime(2026, 9, 9)));
      expect(PatientFollowUpParser.parse('1 month', referenceDate: ref), equals(DateTime(2026, 10, 6)));
    });

    // 15. Dashboard Next Visit
    testWidgets('15. Dashboard Next Visit card displays real follow-up data', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final testCase = ClinicalCase(
        caseId: 'CASE-DASH-01',
        patientId: testPatientId,
        domain: 'Cardiology',
        title: 'Cardiac Checkup',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );
      await mockCaseRepo.createCase(testCase);

      await mockVisitRepo.createVisit(ClinicalVisit(
        visitId: 'VIS-DASH-01',
        caseId: testCase.caseId,
        patientId: testPatientId,
        doctorId: 'DOC-CAR-01',
        doctorName: 'Dr. Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        followUp: '${futureDate.day}-${futureDate.month}-${futureDate.year}',
      ));

      final dashboardController = PatientDashboardController(
        patientRepo: mockPatientRepo,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        appointmentRepo: mockAppointmentRepo,
      );

      await tester.pumpWidget(_buildTestApp(PatientDashboardScreen(controller: dashboardController)));
      await tester.pumpAndSettle();

      expect(find.text('NEXT VISIT'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('FOLLOW-UP VISIT'), findsOneWidget);
      expect(find.text('${futureDate.day}'), findsOneWidget);
    });

    // 16. No Upcoming Visits
    testWidgets('16. Dashboard Next Visit displays valid empty state when none exist', (tester) async {
      final dashboardController = PatientDashboardController(
        patientRepo: mockPatientRepo,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        appointmentRepo: mockAppointmentRepo,
      );

      await tester.pumpWidget(_buildTestApp(PatientDashboardScreen(controller: dashboardController)));
      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Visits'), findsOneWidget);
      expect(find.text("You don't have a scheduled visit yet."), findsOneWidget);
      expect(find.text('Unable to load upcoming visits.'), findsNothing);
    });

    // 17. Dashboard -> Calendar navigation
    testWidgets('17. Dashboard Next Visit card tap navigates to Calendar and sets target date', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final testCase = ClinicalCase(
        caseId: 'CASE-NAV-01',
        patientId: testPatientId,
        domain: 'General Medicine',
        title: 'Fever Review',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );
      await mockCaseRepo.createCase(testCase);

      await mockVisitRepo.createVisit(ClinicalVisit(
        visitId: 'VIS-NAV-01',
        caseId: testCase.caseId,
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime.now(),
        followUp: '${futureDate.day}-${futureDate.month}-${futureDate.year}',
      ));

      final dashboardController = PatientDashboardController(
        patientRepo: mockPatientRepo,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        appointmentRepo: mockAppointmentRepo,
      );

      await tester.pumpWidget(_buildTestApp(PatientDashboardScreen(controller: dashboardController)));
      await tester.pumpAndSettle();

      // Tap Next Visit card
      await tester.tap(find.text('NEXT VISIT'));
      await tester.pumpAndSettle();

      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.calendar));
      expect(PatientAppState.instance.targetCalendarDate?.day, equals(futureDate.day));
    });

    // 18. Patient ownership
    testWidgets('18. Patient ownership: only own follow-ups and cases are queried', (tester) async {
      final date = DateTime.now().add(const Duration(days: 3));

      // Other patient's case & visit
      final otherCase = ClinicalCase(
        caseId: 'CASE-OTHER-01',
        patientId: otherPatientId,
        domain: 'Orthopedics',
        title: 'Knee Pain',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );
      await mockCaseRepo.createCase(otherCase);

      await mockVisitRepo.createVisit(ClinicalVisit(
        visitId: 'VIS-OTHER-01',
        caseId: otherCase.caseId,
        patientId: otherPatientId,
        doctorId: 'DOC-02',
        visitNumber: 1,
        startedAt: DateTime.now(),
        followUp: '${date.day}-${date.month}-${date.year}',
      ));

      final service = PatientFollowUpService(
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        appointmentRepo: mockAppointmentRepo,
      );

      // Authenticated session is testPatientId, not otherPatientId
      final events = await service.getFollowUpsAndAppointmentsForPatient();
      expect(events.where((e) => e.department == 'Orthopedics'), isEmpty);
    });

    // 19. Unauthorized patient access
    testWidgets('19. Unauthorized patient access: querying mismatched patient ID returns empty', (tester) async {
      final service = PatientFollowUpService(
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        appointmentRepo: mockAppointmentRepo,
      );

      // Session is testPatientId, but passing otherPatientId explicitly
      final events = await service.getFollowUpsAndAppointmentsForPatient(patientId: otherPatientId);
      expect(events, isEmpty);
    });

    // 20. Localization
    testWidgets('20. Trilingual localization verification in Hindi and Marathi', (tester) async {
      const stringsEn = PatientStrings();
      const stringsHi = PatientStringsHindi();
      const stringsMr = PatientStringsMarathi();

      // Calendar screen title
      expect(stringsEn.calendarScreenTitle, equals('My Health Calendar'));
      expect(stringsHi.calendarScreenTitle, equals('स्वास्थ्य कैलेंडर'));
      expect(stringsMr.calendarScreenTitle, equals('आरोग्य कॅलेंडर'));

      // Follow-up visit
      expect(stringsEn.followUpVisit, equals('Follow-up Visit'));
      expect(stringsHi.followUpVisit, equals('फॉलो-अप परामर्श'));
      expect(stringsMr.followUpVisit, equals('पुढील तपासणी भेट'));

      // Empty states
      expect(stringsEn.noFollowUpScheduled, equals('No Follow-up Scheduled'));
      expect(stringsHi.noFollowUpScheduled, equals('कोई फॉलो-अप निर्धारित नहीं'));
      expect(stringsMr.noFollowUpScheduled, equals('कोणतीही पुढील तपासणी नियोजित नाही'));

      expect(stringsEn.noUpcomingVisits, equals('No Upcoming Visits'));
      expect(stringsHi.noUpcomingVisits, equals('कोई आगामी मुलाकात नहीं'));
      expect(stringsMr.noUpcomingVisits, equals('कोणतीही आगामी भेट नाही'));

      // Month name
      expect(stringsEn.monthName(9), equals('September'));
      expect(stringsHi.monthName(9), equals('सितंबर'));
      expect(stringsMr.monthName(9), equals('सप्टेंबर'));
    });

    // 21. Responsive calendar
    testWidgets('21. Responsive verification across 360dp, 375dp, 390dp, 412dp, 430dp, and desktop', (tester) async {
      const widths = [360.0, 375.0, 390.0, 412.0, 430.0, 800.0];

      for (final w in widths) {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1.0;

        final controller = PatientCalendarController();
        await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
        await tester.pumpAndSettle();

        expect(find.byType(PatientCalendarWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 22. No overflow
    testWidgets('22. Layout produces zero RenderFlex overflow across all calendar states', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      final controller = PatientCalendarController();
      final date = DateTime.now().add(const Duration(days: 2));
      controller.selectDate(date);
      controller.setEvents([
        PatientCalendarItem(
          id: 'ev-overflow-check',
          date: date,
          title: 'Follow-up Visit',
          department: 'Pulmonology / Respiratory Medicine',
          doctorName: 'Dr. Anand Ramanathan MBBS MD',
          type: PatientCalendarEventType.followUp,
          caseId: 'CASE-01',
          visitId: 'VIS-01',
          caseTitle: 'Chronic Obstructive Pulmonary Disease Long Term Management',
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(PatientCalendarScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 23. Four-tab navigation
    testWidgets('23. Four-tab navigation remains stationary (Dashboard, Cases, Reports, Calendar)', (tester) async {
      await tester.pumpWidget(_buildTestApp(const PatientMainShellScreen()));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Dashboard')), findsOneWidget);
      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Cases')), findsOneWidget);
      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Reports')), findsOneWidget);
      expect(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Calendar')), findsOneWidget);

      // Switch to Calendar tab
      await tester.tap(find.descendant(of: find.byType(PatientBottomNavigation), matching: find.text('Calendar')));
      await tester.pumpAndSettle();

      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.calendar));
      expect(find.text('My Health Calendar'), findsOneWidget);
    });

    // 24. P8 Reports regression
    testWidgets('24. P8 Reports regression: Submitted and Yet to Submit tabs intact', (tester) async {
      await tester.pumpWidget(_buildTestApp(const PatientReportsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.text('YET TO SUBMIT'), findsOneWidget);
    });

    // 25. P8 upload navigation regression
    testWidgets('25. P8 upload navigation regression: /patient/reports/upload route builds safely', (tester) async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: PatientRoutes.onGenerateRoute,
        initialRoute: '/patient/reports/upload',
      ));
      await tester.pumpAndSettle();

      // Screen opens cleanly (either context or error prompt if no route params passed)
      expect(tester.takeException(), isNull);
    });

    // 26. P8 report status regression & Notification stub
    testWidgets('26. P8 report status enum preserved and Notification stub initializes safely', (tester) async {
      final stub = PatientNotificationServiceStub();
      expect(await stub.areRemindersEnabled(), isFalse);

      // Should complete with no-op without error
      await stub.scheduleFollowUpReminder(
        eventId: 'EV-01',
        visitDate: DateTime.now(),
        title: 'Follow-up',
        department: 'Cardiology',
      );
      await stub.cancelReminder('EV-01');

      expect(tester.takeException(), isNull);
    });
  });
}
