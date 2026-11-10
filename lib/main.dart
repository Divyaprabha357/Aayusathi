import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'core/backend/backend_mode.dart';
import 'core/constants/app_constants.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/routes/app_routes.dart';
import 'core/supabase/supabase_initializer.dart';
import 'core/theme/app_theme.dart';
import 'doctor/services/doctor_dashboard_metrics_service.dart';
import 'doctor/services/doctor_patient_request_service.dart';
import 'doctor/services/doctor_session_service.dart';
import 'doctor/services/firebase_doctor_dashboard_metrics_service.dart';
import 'doctor/services/firebase_doctor_patient_request_service.dart';
import 'doctor/services/firebase_doctor_session_service.dart';
import 'doctor/services/mock_doctor_patient_request_service.dart';
import 'doctor/services/mock_doctor_session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt non-crashing Supabase initialization with 3s timeout
  try {
    final supabaseResult = await SupabaseInitializer.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () => const SupabaseInitResult(
        isInitialized: false,
        errorMessage: 'Initialization timed out',
      ),
    );
    if (supabaseResult.isInitialized) {
      debugPrint('[AAYUSATHI] Supabase Storage initialized successfully.');
    } else {
      debugPrint('[AAYUSATHI] Supabase Storage unavailable (${supabaseResult.errorMessage}).');
    }
  } catch (e) {
    debugPrint('[AAYUSATHI] Supabase init note: $e');
  }

  const backendModeEnv = String.fromEnvironment('BACKEND_MODE', defaultValue: 'firebase');
  if (backendModeEnv.toLowerCase() == 'mock') {
    debugPrint('[AAYUSATHI] Explicit Mock backend requested via BACKEND_MODE=mock.');
    BackendProvider.instance.setMode(BackendMode.mock);
    DoctorSessionService.instance = MockDoctorSessionService();
    DoctorDashboardMetricsService.instance = MockDoctorDashboardMetricsService();
    DoctorPatientRequestService.instance = MockDoctorPatientRequestService.instance;
  } else {
    // Attempt non-crashing Firebase initialization with 4s timeout
    try {
      final initResult = await FirebaseInitializer.initialize().timeout(
        const Duration(seconds: 4),
        onTimeout: () => const FirebaseInitResult.failure('Initialization timed out'),
      );
      if (initResult.isInitialized) {
        debugPrint('[AAYUSATHI] Firebase initialized successfully.');
        BackendProvider.instance.setMode(BackendMode.firebase);

        DoctorSessionService.instance = FirebaseDoctorSessionService();
        DoctorDashboardMetricsService.instance = FirebaseDoctorDashboardMetricsService();
        DoctorPatientRequestService.instance = FirebaseDoctorPatientRequestService();

        // Authenticate in background so the UI renders immediately without spinning
        Future(() async {
          try {
            if (FirebaseAuth.instance.currentUser != null) {
              try {
                await FirebaseAuth.instance.currentUser?.getIdToken(true).timeout(const Duration(seconds: 3));
              } catch (_) {
                await FirebaseAuth.instance.signOut();
              }
            }
            if (FirebaseAuth.instance.currentUser == null) {
              final authUser = await BackendProvider.instance.authService.signInAnonymously().timeout(const Duration(seconds: 4));
              if (authUser != null) {
                debugPrint('[AAYUSATHI] AUTHENTICATION SUCCESS: uid=${authUser.uid}');
              }
            }
          } catch (e) {
            debugPrint('[AAYUSATHI] Background auth note: $e');
          }
        });
      } else {
        debugPrint('[AAYUSATHI] Firebase unavailable (${initResult.errorMessage}). Defaulting to Mock backend.');
        BackendProvider.instance.setMode(BackendMode.mock);
        DoctorSessionService.instance = MockDoctorSessionService();
        DoctorDashboardMetricsService.instance = MockDoctorDashboardMetricsService();
        DoctorPatientRequestService.instance = MockDoctorPatientRequestService.instance;
      }
    } catch (e) {
      debugPrint('[AAYUSATHI] Firebase init fallback: $e');
      BackendProvider.instance.setMode(BackendMode.mock);
      DoctorSessionService.instance = MockDoctorSessionService();
      DoctorDashboardMetricsService.instance = MockDoctorDashboardMetricsService();
      DoctorPatientRequestService.instance = MockDoctorPatientRequestService.instance;
    }
  }

  const initialRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: '/',
  );
  runApp(const AayusathiApp(initialRoute: initialRoute));
}

/// Root widget for AAYUSATHI.
class AayusathiApp extends StatelessWidget {
  final String initialRoute;

  const AayusathiApp({
    super.key,
    this.initialRoute = AppRoutes.initial,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (initialRouteName) {
        return [
          AppRoutes.onGenerateRoute(RouteSettings(name: initialRouteName)),
        ];
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

