import 'package:flutter/material.dart';
import '../doctor/models/clinical_case.dart';
import '../doctor/models/clinical_visit.dart';
import '../doctor/models/investigation_request.dart';
import 'models/patient_app_state.dart';
import 'models/patient_navigation_tab.dart';
import 'screens/patient_case_detail_screen.dart';
import 'screens/patient_login_screen.dart';
import 'screens/patient_main_shell_screen.dart';
import 'screens/patient_notification_center_screen.dart';
import 'screens/patient_otp_screen.dart';
import 'screens/patient_profile_screen.dart';
import 'screens/patient_report_detail_screen.dart';
import 'screens/patient_report_upload_screen.dart';
import 'screens/patient_visit_detail_screen.dart';
import 'services/patient_session_service.dart';

/// Central Route definitions and Generator for the AAYUSATHI Patient App.
class PatientRoutes {
  PatientRoutes._();

  static const String patient = '/patient';
  static const String patientLogin = '/patient/login';
  static const String patientOtp = '/patient/otp';
  static const String patientDashboard = '/patient/dashboard';
  static const String patientCases = '/patient/cases';
  static const String patientCaseDetailPrefix = '/patient/cases/';
  static const String patientReports = '/patient/reports';
  static const String patientReportDetailPrefix = '/patient/reports/';
  static const String patientCalendar = '/patient/calendar';
  static const String patientProfile = '/patient/profile';
  static const String patientNotifications = '/patient/notifications';

  /// Generates routes specifically for the Patient App module.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final pathSegments = uri.pathSegments;

    // Must be under /patient
    if (pathSegments.isEmpty || pathSegments.first != 'patient') {
      return null;
    }

    PageRouteBuilder buildPatientRoute(Widget page) {
      return PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => page,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        settings: settings,
      );
    }

    PageRouteBuilder buildProtectedPatientRoute(Widget page) {
      if (!PatientSessionService.instance.isAuthenticated) {
        return buildPatientRoute(const PatientLoginScreen());
      }
      return buildPatientRoute(page);
    }

    // 1. /patient
    if (pathSegments.length == 1) {
      if (!PatientSessionService.instance.isAuthenticated) {
        return buildPatientRoute(const PatientLoginScreen());
      }
      return buildPatientRoute(
        const PatientMainShellScreen(initialTab: PatientNavigationTab.dashboard),
      );
    }

    // 2. /patient/login
    if (pathSegments.length == 2 && pathSegments[1] == 'login') {
      return buildPatientRoute(const PatientLoginScreen());
    }

    // 3. /patient/otp
    if (pathSegments.length == 2 && pathSegments[1] == 'otp') {
      String? patientId;
      String? maskedPhone;
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        patientId = args['patientId'] as String?;
        maskedPhone = args['maskedPhone'] as String?;
      }
      return buildPatientRoute(PatientOtpScreen(
        patientId: patientId,
        maskedPhone: maskedPhone,
      ));
    }

    // 4. /patient/dashboard
    if (pathSegments.length == 2 && pathSegments[1] == 'dashboard') {
      return buildProtectedPatientRoute(
        const PatientMainShellScreen(initialTab: PatientNavigationTab.dashboard),
      );
    }

    // 5. /patient/cases
    if (pathSegments.length == 2 && pathSegments[1] == 'cases') {
      return buildProtectedPatientRoute(
        const PatientMainShellScreen(initialTab: PatientNavigationTab.cases),
      );
    }

    // 6. /patient/cases/:caseId/visits/:visitId
    if (pathSegments.length == 5 && pathSegments[1] == 'cases' && pathSegments[3] == 'visits') {
      final caseId = pathSegments[2];
      final visitId = pathSegments[4];
      ClinicalVisit? visit;
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        visit = args['visit'] as ClinicalVisit?;
      }
      return buildProtectedPatientRoute(PatientVisitDetailScreen(
        caseId: caseId,
        visitId: visitId,
        preloadedVisit: visit,
      ));
    }

    // 7. /patient/cases/:caseId
    if (pathSegments.length == 3 && pathSegments[1] == 'cases') {
      final caseId = pathSegments[2];
      ClinicalCase? clinicalCase;
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        clinicalCase = args['clinicalCase'] as ClinicalCase?;
      }
      return buildProtectedPatientRoute(PatientCaseDetailScreen(
        caseId: caseId,
        preloadedCase: clinicalCase,
      ));
    }

    // 8. /patient/reports
    if (pathSegments.length == 2 && pathSegments[1] == 'reports') {
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        final targetId = args['investigationId'] as String? ?? args['reportId'] as String?;
        if (targetId != null && targetId.isNotEmpty) {
          PatientAppState.instance.navigateToReportsWithInvestigation(targetId);
        }
      }
      return buildProtectedPatientRoute(
        const PatientMainShellScreen(initialTab: PatientNavigationTab.reports),
      );
    }

    // 9. /patient/reports/:reportId/upload
    if (pathSegments.length == 4 &&
        pathSegments[1] == 'reports' &&
        pathSegments[3] == 'upload') {
      final reportId = pathSegments[2];
      InvestigationRequest? investigation;
      String? caseTitle;
      DateTime? visitDate;
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        investigation = args['investigation'] as InvestigationRequest? ??
            args['report'] as InvestigationRequest?;
        caseTitle = args['caseTitle'] as String?;
        visitDate = args['visitDate'] as DateTime?;
      }
      investigation ??= InvestigationRequest(
        requestId: reportId,
        name: 'Diagnostic Investigation',
        requestedAt: visitDate ?? DateTime.now(),
      );
      return buildProtectedPatientRoute(PatientReportUploadScreen(
        investigation: investigation,
        caseTitle: caseTitle,
        visitDate: visitDate,
      ));
    }

    // 10. /patient/reports/:reportId
    if (pathSegments.length == 3 && pathSegments[1] == 'reports') {
      final reportId = pathSegments[2];
      InvestigationRequest? report;
      String? caseTitle;
      DateTime? visitDate;
      if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        report = args['report'] as InvestigationRequest?;
        caseTitle = args['caseTitle'] as String?;
        visitDate = args['visitDate'] as DateTime?;
      }
      return buildProtectedPatientRoute(PatientReportDetailScreen(
        reportId: reportId,
        preloadedReport: report,
        caseTitle: caseTitle,
        visitDate: visitDate,
      ));
    }

    // 10. /patient/calendar
    if (pathSegments.length == 2 && pathSegments[1] == 'calendar') {
      DateTime? selectedDate;
      if (settings.arguments is DateTime) {
        selectedDate = settings.arguments as DateTime;
      } else if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        selectedDate = args['selectedDate'] as DateTime?;
      }
      if (selectedDate != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          PatientAppState.instance.navigateToCalendarWithDate(selectedDate);
        });
      }
      return buildProtectedPatientRoute(
        const PatientMainShellScreen(initialTab: PatientNavigationTab.calendar),
      );
    }

    // 11. /patient/profile
    if (pathSegments.length == 2 && pathSegments[1] == 'profile') {
      return buildProtectedPatientRoute(const PatientProfileScreen());
    }

    // 12. /patient/notifications
    if (pathSegments.length == 2 && pathSegments[1] == 'notifications') {
      return buildProtectedPatientRoute(const PatientNotificationCenterScreen());
    }

    return null;
  }
}
