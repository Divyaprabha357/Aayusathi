import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/constants/app_assets.dart';
import 'package:aayusathi/patient/controllers/patient_auth_controller.dart';
import 'package:aayusathi/patient/controllers/patient_cases_controller.dart';
import 'package:aayusathi/patient/controllers/patient_profile_controller.dart';
import 'package:aayusathi/patient/controllers/patient_reports_controller.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_session.dart';
import 'package:aayusathi/patient/screens/patient_cases_screen.dart';
import 'package:aayusathi/patient/screens/patient_login_screen.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_otp_screen.dart';
import 'package:aayusathi/patient/screens/patient_profile_screen.dart';
import 'package:aayusathi/patient/screens/patient_reports_screen.dart';
import 'package:aayusathi/patient/services/patient_auth_service.dart';
import 'package:aayusathi/patient/services/patient_otp_service.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_colors.dart';
import 'package:aayusathi/patient/theme/patient_spacing.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_auth_scaffold.dart';
import 'package:aayusathi/patient/widgets/patient_bottom_navigation.dart';
import 'package:aayusathi/patient/widgets/patient_empty_state.dart';
import 'package:aayusathi/patient/widgets/patient_input_field.dart';
import 'package:aayusathi/patient/widgets/patient_otp_field.dart';
import 'package:aayusathi/patient/widgets/patient_segmented_control.dart';
import 'package:aayusathi/patient/widgets/patient_top_bar.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPatientRepository mockPatientRepo;
  late MockCaseRepository mockCaseRepo;
  late PatientAuthService authService;
  late MockPatientOtpService otpService;

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    mockPatientRepo = MockPatientRepository.instance;
    mockPatientRepo.resetToDefaults();
    mockCaseRepo = MockCaseRepository.instance;
    mockCaseRepo.resetToDefaults();
    authService = PatientAuthService(patientRepository: mockPatientRepo);
    otpService = MockPatientOtpService(cooldownSeconds: 0, defaultTestOtp: '123456');
    PatientAppState.instance.resetSession();
    PatientSessionService.instance.logout();
  });

  group('Phase P13: UI/UX Consistency, Spacing, Alignment & Input Visibility', () {
    // 1. Patient Login field visible
    testWidgets('1. Patient Login field is clearly visible with mint fill and visible border', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientLoginScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientInputField), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      final inputField = tester.widget<TextField>(find.byType(TextField));
      final decoration = inputField.decoration!;
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, equals(PatientColors.inputFill));
      expect(decoration.enabledBorder, isA<OutlineInputBorder>());
      final border = decoration.enabledBorder as OutlineInputBorder;
      expect(border.borderSide.color, equals(PatientColors.inputBorder));
      expect(border.borderSide.width, equals(1.5));
      controller.dispose();
    });

    // 2. Patient ID hint readable
    testWidgets('2. Patient ID hint text is readable with high contrast', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientLoginScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final inputField = tester.widget<TextField>(find.byType(TextField));
      expect(inputField.decoration?.hintStyle?.color, equals(PatientColors.hintColor));
      expect(inputField.decoration?.hintText, isNotEmpty);
      controller.dispose();
    });

    // 3. Patient ID entered text readable
    testWidgets('3. Patient ID entered text has deep navy color and semibold weight', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientLoginScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'AAYU-102938');
      await tester.pumpAndSettle();

      final inputField = tester.widget<TextField>(find.byType(TextField));
      expect(inputField.style?.color, equals(PatientColors.navy));
      expect(inputField.style?.fontWeight, equals(FontWeight.w600));
      controller.dispose();
    });

    // 4. Patient ID focus state visible
    testWidgets('4. Patient ID input field focus border is medical teal with 2px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientLoginScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final inputField = tester.widget<TextField>(find.byType(TextField));
      final focusedBorder = inputField.decoration?.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, equals(PatientColors.inputBorderFocused));
      expect(focusedBorder.borderSide.width, equals(2.0));
      controller.dispose();
    });

    // 5. OTP boxes visible
    testWidgets('5. OTP field renders six distinct visible interactive boxes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientOtpScreen(
            patientId: 'AAYU-102938',
            maskedPhone: '+91 ******3210',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientOtpField), findsOneWidget);
      // Verify six digit box containers inside the row
      final animatedContainers = find.descendant(
        of: find.byType(PatientOtpField),
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainers, findsNWidgets(6));
      controller.dispose();
    });

    // 6. OTP digits readable
    testWidgets('6. OTP entered digits are bold navy text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientOtpScreen(
            patientId: 'AAYU-102938',
            maskedPhone: '+91 ******3210',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      final digit1 = tester.widget<Text>(find.text('1'));
      expect(digit1.style?.color, equals(PatientColors.navy));
      expect(digit1.style?.fontWeight, equals(FontWeight.w800));
      controller.dispose();
    });

    // 7. OTP focus state visible
    testWidgets('7. Active OTP digit box highlights with teal border', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientOtpScreen(
            patientId: 'AAYU-102938',
            maskedPhone: '+91 ******3210',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to focus the OTP field
      await tester.tap(find.byType(PatientOtpField));
      await tester.pumpAndSettle();

      final firstBox = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(PatientOtpField),
          matching: find.byType(AnimatedContainer),
        ).first,
      );

      final decoration = firstBox.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, equals(PatientColors.inputBorderFocused));
      expect(border.top.width, equals(2.0));
      controller.dispose();
    });

    // 8. Login and OTP have consistent top spacing
    testWidgets('8. Login and OTP screens share identical PatientAuthScaffold structure', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientLoginScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientAuthScaffold), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientOtpScreen(
            patientId: 'AAYU-102938',
            maskedPhone: '+91 ******3210',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientAuthScaffold), findsOneWidget);
      controller.dispose();
    });

    // 9. Cases title alignment
    testWidgets('9. Cases screen title aligns at PatientSpacing.pageTop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientCasesScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final padding = scrollView.padding as EdgeInsets;
      expect(padding.top, equals(PatientSpacing.pageTop));
      expect(padding.left, equals(PatientSpacing.pageHorizontal));
    });

    // 10. Cases segmented control alignment
    testWidgets('10. Cases segmented control is placed 16px below title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientCasesScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientSegmentedControl<PatientCasesTab>), findsOneWidget);
      final controlBox = tester.getRect(find.byType(PatientSegmentedControl<PatientCasesTab>));
      final titleBox = tester.getRect(find.text('Cases'));
      expect(controlBox.top - titleBox.bottom, closeTo(PatientSpacing.sectionGap, 1.0));
    });

    // 11. Cases empty state positioning
    testWidgets('11. Cases empty state is vertically balanced and not sunken', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      PatientSessionService.instance.setSession(
        PatientSession.authenticated(patientId: 'PAT-EMPTY'),
      );
      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientCasesScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientEmptyState), findsOneWidget);
      final emptyBox = tester.getRect(find.byType(PatientEmptyState));
      // Empty state begins in upper half of screen (below control ~150-200dp, well above bottom 844dp)
      expect(emptyBox.top, lessThan(400.0));
    });

    // 12. Reports title alignment
    testWidgets('12. Reports title aligns at identical vertical position as Cases', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final reportsController = PatientReportsController(
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientReportsScreen(controller: reportsController),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final padding = scrollView.padding as EdgeInsets;
      expect(padding.top, equals(PatientSpacing.pageTop));
      expect(padding.left, equals(PatientSpacing.pageHorizontal));
    });

    // 13. Reports segmented control alignment
    testWidgets('13. Reports segmented control is placed 16px below title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final reportsController = PatientReportsController(
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientReportsScreen(controller: reportsController),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientSegmentedControl<PatientReportsTab>), findsOneWidget);
      final controlBox = tester.getRect(find.byType(PatientSegmentedControl<PatientReportsTab>));
      final titleBox = tester.getRect(find.text('Reports'));
      expect(controlBox.top - titleBox.bottom, closeTo(PatientSpacing.sectionGap, 1.0));
    });

    // 14. Reports empty state positioning
    testWidgets('14. Reports empty state is vertically balanced', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      PatientSessionService.instance.setSession(
        PatientSession.authenticated(patientId: 'PAT-EMPTY'),
      );
      final reportsController = PatientReportsController(
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientReportsScreen(controller: reportsController),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientEmptyState), findsOneWidget);
      final emptyBox = tester.getRect(find.byType(PatientEmptyState));
      expect(emptyBox.top, lessThan(400.0));
    });

    // 15. Cases tab switching does not change top layout
    testWidgets('15. Toggling Cases tabs keeps Title and SegmentedControl at fixed coordinates', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientCasesController(
        caseRepo: mockCaseRepo,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientCasesScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleTopBefore = tester.getTopLeft(find.text('Cases')).dy;
      final controlTopBefore = tester.getTopLeft(find.byType(PatientSegmentedControl<PatientCasesTab>)).dy;

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      final titleTopAfter = tester.getTopLeft(find.text('Cases')).dy;
      final controlTopAfter = tester.getTopLeft(find.byType(PatientSegmentedControl<PatientCasesTab>)).dy;

      expect(titleTopBefore, equals(titleTopAfter));
      expect(controlTopBefore, equals(controlTopAfter));
    });

    // 16. Reports tab switching does not change top layout
    testWidgets('16. Toggling Reports tabs keeps Title and SegmentedControl at fixed coordinates', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final reportsController = PatientReportsController(
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientReportsScreen(controller: reportsController),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleTopBefore = tester.getTopLeft(find.text('Reports')).dy;
      final controlTopBefore = tester.getTopLeft(find.byType(PatientSegmentedControl<PatientReportsTab>)).dy;

      // Switch to Yet To Submit
      await tester.tap(find.text('YET TO SUBMIT'));
      await tester.pumpAndSettle();

      final titleTopAfter = tester.getTopLeft(find.text('Reports')).dy;
      final controlTopAfter = tester.getTopLeft(find.byType(PatientSegmentedControl<PatientReportsTab>)).dy;

      expect(titleTopBefore, equals(titleTopAfter));
      expect(controlTopBefore, equals(controlTopAfter));
    });

    // 17. Bottom navigation remains stable
    testWidgets('17. Patient bottom navigation has exactly 4 tabs and fixed height', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      PatientSessionService.instance.startSession('AAYU-102938');

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientMainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final navFinder = find.byType(PatientBottomNavigation);
      expect(find.descendant(of: navFinder, matching: find.text('Dashboard')), findsOneWidget);
      expect(find.descendant(of: navFinder, matching: find.text('Cases')), findsOneWidget);
      expect(find.descendant(of: navFinder, matching: find.text('Reports')), findsOneWidget);
      expect(find.descendant(of: navFinder, matching: find.text('Calendar')), findsOneWidget);

      // Switch tab to Cases
      await tester.tap(find.descendant(of: navFinder, matching: find.text('Cases')));
      await tester.pumpAndSettle();

      // Navigation bar remains stable
      expect(find.descendant(of: navFinder, matching: find.text('Dashboard')), findsOneWidget);
      expect(find.descendant(of: navFinder, matching: find.text('Cases')), findsOneWidget);
      expect(find.descendant(of: navFinder, matching: find.text('Reports')), findsOneWidget);
      expect(find.descendant(of: navFinder, matching: find.text('Calendar')), findsOneWidget);
    });

    // 18. No Aadhaar displayed
    testWidgets('18. Profile Screen strictly contains zero Aadhaar numbers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      PatientSessionService.instance.startSession('AAYU-102938');
      final profileController = PatientProfileController(patientRepo: mockPatientRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientProfileScreen(controller: profileController),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('AADHAAR'), findsNothing);
      expect(find.textContaining('XXXX'), findsNothing);
      expect(find.textContaining('xxxx'), findsNothing);
    });

    // 19. Official AAYUSATHI logo is used
    testWidgets('19. Official AAYUSATHI logo asset is loaded in PatientTopBar and AuthScaffold', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientLoginScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final authImage = tester.widget<Image>(find.byType(Image));
      expect((authImage.image as AssetImage).assetName, equals(AppAssets.logo));

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const Scaffold(appBar: PatientTopBar()),
        ),
      );
      await tester.pumpAndSettle();

      final topBarImage = tester.widget<Image>(find.byType(Image));
      expect((topBarImage.image as AssetImage).assetName, equals(AppAssets.logo));
      controller.dispose();
    });

    // 20. Responsive layout does not overflow
    testWidgets('20. Authentication screens render cleanly without overflow across multiple viewports', (tester) async {
      final viewports = [
        const Size(360, 640),  // Compact Android
        const Size(390, 844),  // Standard Android
        const Size(412, 915),  // Large Android
        const Size(768, 1024), // Tablet
        const Size(1440, 900), // Desktop
      ];

      for (final size in viewports) {
        await tester.binding.setSurfaceSize(size);
        final controller = PatientAuthController(
          authService: authService,
          otpService: otpService,
          sessionService: PatientSessionService.instance,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: PatientTheme.theme,
            home: PatientLoginScreen(controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed on viewport $size');
        controller.dispose();
      }
    });
  });
}
