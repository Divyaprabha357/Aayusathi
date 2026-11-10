import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../models/doctor_profile.dart';
import 'doctor_presence_service.dart';
import 'doctor_profile_service.dart';
import 'doctor_session_service.dart';
import 'mock_doctor_presence_service.dart';
import 'mock_doctor_session_service.dart';

/// Development-Only Controller to access Doctor Workspace without real Firebase accounts.
///
/// Strictly isolated behind compile-time/runtime configuration.
/// Set compile-time flag: `--dart-define=DOCTOR_DEV_MODE=true`
///
/// SAFETY INVARIANTS:
/// - NEVER calls Firebase Authentication
/// - NEVER writes to Cloud Firestore
/// - NEVER creates fake production audit logs
/// - NEVER exposed when DOCTOR_DEV_MODE is absent or false
class DoctorDevWorkspaceController {
  DoctorDevWorkspaceController._();

  /// Compile-time configuration flag.
  /// Defaults to false in production builds.
  static const bool isDevModeCompileTime =
      bool.fromEnvironment('DOCTOR_DEV_MODE', defaultValue: false);

  /// Test-only runtime override flag.
  /// When non-null, overrides [isDevModeCompileTime].
  static bool? devModeOverride;

  /// Whether the development workspace entry point is enabled.
  static bool get isDevModeEnabled => devModeOverride ?? isDevModeCompileTime;

  /// Safely enters the development mock Doctor Workspace.
  ///
  /// Bypasses Firebase Auth, assigns Dr. Rajesh Sharma (DOC-101, Cardiology, AVAILABLE),
  /// and transitions to the Clinical Dashboard.
  static Future<void> enterDemoWorkspace(BuildContext context) async {
    if (!isDevModeEnabled) {
      throw StateError(
        'Cannot enter demo workspace when DOCTOR_DEV_MODE is disabled.',
      );
    }

    // 1. Ensure mock profile service is active
    if (DoctorProfileService.instance is! MockDoctorProfileService) {
      DoctorProfileService.instance = MockDoctorProfileService();
    }

    // 2. Ensure mock presence service is active
    if (DoctorPresenceService.instance is! MockDoctorPresenceService) {
      DoctorPresenceService.instance = MockDoctorPresenceService(
        initialStatus: DoctorAvailabilityStatus.available,
      );
    }

    // 3. Ensure mock session service is active
    if (DoctorSessionService.instance is! MockDoctorSessionService) {
      DoctorSessionService.instance = MockDoctorSessionService();
    }

    // 4. Create local mock session and set state to authenticated
    await DoctorSessionService.instance.enterDevelopmentWorkspace(
      profile: MockDoctorProfileService.demoDoctor,
    );

    // 5. Navigate to Doctor Dashboard
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
  }
}
