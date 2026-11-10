import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/portal_gateway_screen.dart';
import '../theme/app_theme.dart';
import '../../doctor/theme/doctor_colors.dart';
import '../../admin/screens/admin_appointment_escalations_screen.dart';
import '../../admin/screens/admin_availability_screen.dart';
import '../../admin/screens/admin_case_escalations_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../admin/screens/admin_doctor_provisioning_screen.dart';
import '../../admin/screens/admin_doctors_screen.dart';
import '../../admin/screens/admin_escalated_patient_workspace_screen.dart';
import '../../admin/screens/admin_login_screen.dart';
import '../../admin/screens/admin_standby_screen.dart';
import '../../admin/services/admin_auth_service.dart';
import '../../doctor/screens/doctor_case_screen.dart';
import '../../doctor/screens/doctor_consultation_screen.dart';
import '../../doctor/screens/doctor_dashboard_screen.dart';
import '../../doctor/screens/doctor_login_screen.dart';
import '../../doctor/screens/doctor_otp_screen.dart';
import '../../doctor/screens/doctor_patient_request_screen.dart';
import '../../doctor/screens/doctor_patient_workspace_screen.dart';
import '../../doctor/screens/doctor_profile_screen.dart';
import '../../doctor/screens/doctor_reports_screen.dart';
import '../../doctor/screens/doctor_standby_screen.dart';
import '../../kiosk/models/patient_identity.dart';
import '../../kiosk/screens/aadhaar_input_screen.dart';
import '../../kiosk/screens/doctor_preference_screen.dart';
import '../../kiosk/screens/domain_selection_screen.dart';
import '../../kiosk/screens/existing_patient_confirmation_screen.dart';
import '../../kiosk/screens/ipd_referral_screen.dart';
import '../../kiosk/screens/language_selection_screen.dart';
import '../../kiosk/screens/mobile_number_input_screen.dart';
import '../../kiosk/screens/otp_success_screen.dart';
import '../../kiosk/screens/otp_verification_screen.dart';
import '../../kiosk/screens/patient_details_confirmation_screen.dart';
import '../../kiosk/screens/patient_id_input_screen.dart';
import '../../kiosk/screens/phase5_complete_screen.dart';
import '../../kiosk/screens/phase6_complete_screen.dart';
import '../../kiosk/screens/queue_confirmation_screen.dart';
import '../../kiosk/screens/registration_success_screen.dart';
import '../../kiosk/screens/sensor_instructions_screen.dart';
import '../../kiosk/screens/standby_screen.dart';
import '../../kiosk/screens/thank_you_screen.dart';
import '../../kiosk/screens/user_type_screen.dart';
import '../../kiosk/screens/vitals_screen.dart';
import '../../models/appointment_request.dart';
import '../../models/opd_domain.dart';
import '../../models/previous_visit_record.dart';
import '../../patient/patient_routes.dart';

/// Central route management for AAYUSATHI (Kiosk, Doctor, Admin, Patient).
class AppRoutes {
  AppRoutes._();

  // Route Names - Patient Portal
  static const String patient = PatientRoutes.patient;
  static const String patientLogin = PatientRoutes.patientLogin;
  static const String patientOtp = PatientRoutes.patientOtp;
  static const String patientDashboard = PatientRoutes.patientDashboard;
  static const String patientCases = PatientRoutes.patientCases;
  static const String patientReports = PatientRoutes.patientReports;
  static const String patientCalendar = PatientRoutes.patientCalendar;
  static const String patientProfile = PatientRoutes.patientProfile;

  // Route Names - Gateway Hub & Kiosk
  static const String initial = '/';
  static const String hub = '/hub';
  static const String kiosk = '/kiosk';
  static const String standby = '/standby';
  static const String kioskHome = '/kiosk';
  static const String language = '/language';
  static const String userType = '/user-type';
  static const String newUser = '/new-user';
  static const String aadhaarInput = '/new-user';
  static const String patientDetailsConfirmation = '/patient-details-confirmation';
  static const String mobileInput = '/mobile-input';
  static const String registrationSuccess = '/registration-success';
  static const String existingPatient = '/existing-patient';
  static const String patientIdInput = '/existing-patient';
  static const String existingPatientConfirmation = '/existing-patient-confirmation';
  static const String otpVerification = '/otp-verification';
  static const String otpSuccess = '/otp-success';
  static const String phase5Complete = '/phase5-complete';
  static const String phase6Complete = '/phase6-complete';
  static const String sensorInstructions = '/sensor-instructions';
  static const String vitals = '/vitals';
  static const String ipdReferral = '/ipd-referral';
  static const String domainSelection = '/domain-selection';
  static const String doctorPreference = '/doctor-preference';
  static const String queueConfirmation = '/queue-confirmation';
  static const String thankYou = '/thank-you';
  static const String patientHome = '/patient';

  // Route Names - Doctor Portal
  static const String doctorHome = '/doctor';
  static const String doctorStandby = '/doctor/standby';
  static const String doctorLogin = '/doctor/login';
  static const String doctorOtp = '/doctor/otp';
  static const String doctorDashboard = '/doctor/dashboard';
  static const String doctorPatientRequest = '/doctor/patient-request';
  static const String doctorPatientWorkspace = '/doctor/patient-workspace';
  static const String doctorConsultation = '/doctor/consultation';
  static const String doctorCase = '/doctor/case';
  static const String doctorReports = '/doctor/reports';
  static const String doctorProfile = '/doctor/profile';

  // Route Names - Admin Portal
  static const String admin = '/admin';
  static const String adminHome = '/admin';
  static const String adminStandby = '/admin/standby';
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminDoctors = '/admin/doctors';
  static const String adminDoctorsAdd = '/admin/doctors/add';
  static const String adminDoctorsManage = '/admin/doctors/manage';
  static const String adminAvailability = '/admin/availability';
  static const String adminAppointmentEscalations = '/admin/appointment-escalations';
  static const String adminCaseEscalations = '/admin/case-escalations';
  static const String adminEscalatedPatient = '/admin/escalated-patient';

  /// Route generator for dynamic navigation
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Check Patient module routes first
    final patientRoute = PatientRoutes.onGenerateRoute(settings);
    if (patientRoute != null) {
      return patientRoute;
    }

    PageRouteBuilder buildSlideTransition(Widget page) {
      return PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => page,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final tween = Tween<Offset>(
            begin: const Offset(0.05, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        settings: settings,
      );
    }

    PageRouteBuilder buildDoctorRoute(Widget page) {
      return PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => Theme(
          data: AppTheme.lightTheme.copyWith(
            scaffoldBackgroundColor: DoctorColors.background,
          ),
          child: page,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        settings: settings,
      );
    }

    PageRouteBuilder buildAdminRoute(Widget page) {
      return PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        settings: settings,
      );
    }

    PageRouteBuilder buildProtectedAdminRoute(Widget page) {
      if (!AdminAuthService.instance.isAuthenticated) {
        return buildAdminRoute(const AdminLoginScreen());
      }
      return buildAdminRoute(page);
    }

    switch (settings.name) {
      case hub:
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => const PortalGatewayScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          settings: settings,
        );

      case initial:
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) =>
              kIsWeb ? const PortalGatewayScreen() : const StandbyScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          settings: settings,
        );

      case kiosk:
      case standby:
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => const StandbyScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          settings: settings,
        );

      case language:
        return buildSlideTransition(const LanguageSelectionScreen());

      case userType:
        return buildSlideTransition(const UserTypeScreen());

      case newUser:
        return buildSlideTransition(const AadhaarInputScreen());

      case patientDetailsConfirmation:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(PatientDetailsConfirmationScreen(patient: patient));

      case mobileInput:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(MobileNumberInputScreen(patient: patient));

      case registrationSuccess:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(RegistrationSuccessScreen(patient: patient));

      case existingPatient:
        return buildSlideTransition(const PatientIdInputScreen());

      case existingPatientConfirmation:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(ExistingPatientConfirmationScreen(patient: patient));

      case otpVerification:
        if (settings.arguments is PatientIdentity) {
          final patient = settings.arguments as PatientIdentity;
          return buildSlideTransition(OtpVerificationScreen(patient: patient));
        } else if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return buildSlideTransition(
            OtpVerificationScreen(
              patient: args['patient'] as PatientIdentity?,
              phoneNumber: args['phoneNumber'] as String?,
              maskedPhone: args['maskedPhone'] as String?,
              aadhaarNumber: args['aadhaarNumber'] as String?,
            ),
          );
        } else {
          return buildSlideTransition(const OtpVerificationScreen());
        }

      case otpSuccess:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(OtpSuccessScreen(patient: patient));

      case sensorInstructions:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(SensorInstructionsScreen(patient: patient));

      case vitals:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(VitalsScreen(patient: patient));

      case ipdReferral:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(IpdReferralScreen(patient: patient));

      case domainSelection:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(DomainSelectionScreen(patient: patient));

      case doctorPreference:
        final args = settings.arguments as Map<String, dynamic>;
        return buildSlideTransition(
          DoctorPreferenceScreen(
            patient: args['patient'] as PatientIdentity,
            domain: args['domain'] as OpdDomain,
            previousVisit: args['previousVisit'] as PreviousVisitRecord?,
          ),
        );

      case queueConfirmation:
        final appointment = settings.arguments as AppointmentRequest;
        return buildSlideTransition(QueueConfirmationScreen(appointment: appointment));

      case thankYou:
        return buildSlideTransition(const ThankYouScreen());

      case phase5Complete:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(Phase5CompleteScreen(patient: patient));

      case phase6Complete:
        final patient = settings.arguments as PatientIdentity;
        return buildSlideTransition(Phase6CompleteScreen(patient: patient));

      // Doctor Portal Routes
      case doctorHome:
      case doctorStandby:
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => const DoctorStandbyScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          settings: settings,
        );

      case doctorLogin:
        return buildDoctorRoute(const DoctorLoginScreen());

      case doctorOtp:
        return buildDoctorRoute(const DoctorOtpScreen());

      case doctorDashboard:
        return buildDoctorRoute(const DoctorDashboardScreen());

      case doctorPatientRequest:
        return buildDoctorRoute(const DoctorPatientRequestScreen());

      case doctorPatientWorkspace:
        return buildDoctorRoute(const DoctorPatientWorkspaceScreen());

      case doctorConsultation:
        return buildDoctorRoute(const DoctorConsultationScreen());

      case doctorCase:
        return buildDoctorRoute(const DoctorCaseScreen());

      case doctorReports:
        return buildDoctorRoute(const DoctorReportsScreen());

      case doctorProfile:
        return buildDoctorRoute(const DoctorProfileScreen());

      // Admin Portal Routes
      case admin:
      case adminStandby:
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => const AdminStandbyScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          settings: settings,
        );

      case adminLogin:
        return buildAdminRoute(const AdminLoginScreen());

      case adminDashboard:
        return buildProtectedAdminRoute(const AdminDashboardScreen());

      case adminDoctors:
      case adminDoctorsManage:
        return buildProtectedAdminRoute(const AdminDoctorsScreen());

      case adminDoctorsAdd:
        return buildProtectedAdminRoute(const AdminDoctorProvisioningScreen());


      case adminAvailability:
        return buildProtectedAdminRoute(const AdminAvailabilityScreen());

      case adminAppointmentEscalations:
        return buildProtectedAdminRoute(const AdminAppointmentEscalationsScreen());

      case adminCaseEscalations:
        return buildProtectedAdminRoute(const AdminCaseEscalationsScreen());

      case adminEscalatedPatient:
        String? pId;
        String? cId;
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          pId = args['patientId'] as String?;
          cId = args['caseId'] as String?;
        }
        return buildProtectedAdminRoute(AdminEscalatedPatientWorkspaceScreen(
          patientId: pId,
          caseId: cId,
        ));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
