import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/theme/doctor_colors.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_close_case_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_transfer_patient_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_visit_report_preview_dialog.dart';
import 'package:aayusathi/models/patient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
  });

  final mockPatient = Patient(
    patientId: 'PAT-9001',
    name: 'Rohan Sharma',
    dateOfBirth: '1985-06-15',
    age: 41,
    gender: 'Male',
    phone: '+919876543210',
    bloodGroup: 'O+',
    address: 'Kathmandu, Nepal',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockCase = ClinicalCase(
    caseId: 'CASE-8001',
    patientId: 'PAT-9001',
    domain: 'Cardiology',
    title: 'Severe Angina Pectoris',
    status: ClinicalCaseStatus.open,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockActiveVisit = ClinicalVisit(
    visitId: 'VIS-7001',
    caseId: 'CASE-8001',
    patientId: 'PAT-9001',
    doctorId: 'DOC-501',
    visitNumber: 1,
    startedAt: DateTime.now(),
    status: ClinicalVisitStatus.active,
    chiefComplaint: 'Substernal chest pain radiating to left arm',
    onsetDuration: '2 hours',
    associatedSymptoms: 'Diaphoresis, nausea',
    medicalHistory: 'Hypertension (5 years)',
    currentMedication: 'Amlodipine 5mg OD',
    clinicalObservations: 'BP 150/95, HR 88 regular, S1 S2 heard',
    assessment: 'Unstable Angina — Rule out NSTEMI',
    plan: 'ECG, Trop-I stat, Aspirin 300mg, Atorvastatin 80mg',
    summary: 'Emergency evaluation underway. Monitoring vitals.',
    summaryApprovalStatus: SummaryApprovalStatus.reviewRequired,
  );

  group('AAYUSATHI Doctor Dialogs Visibility & Theme Tests', () {
    testWidgets('1. DoctorVisitReportPreviewDialog: Header, branding, warning & contrast in Light & Dark modes',
        (tester) async {
      final reportData = VisitReportData.fromComponents(
        patient: mockPatient,
        clinicalCase: mockCase,
        visit: mockActiveVisit,
      );

      bool pdfTriggered = false;

      for (final themeData in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: themeData,
            home: Scaffold(
              body: DoctorVisitReportPreviewDialog(
                data: reportData,
                onGeneratePdf: () {
                  pdfTriggered = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Dialog background is pure white (#FFFFFF)
        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);
        final dialogWidget = tester.widget<Dialog>(dialogFinder);
        expect(dialogWidget.backgroundColor, equals(DoctorColors.dialogBg));

        // 2. Verify branding wordmark and tagline
        expect(find.text('AAYUSATHI'), findsOneWidget);
        expect(find.text('LIVE BETTER, TOGETHER'), findsOneWidget);
        expect(find.text('CASE & VISIT DOCUMENTATION — DRAFT PREVIEW'), findsOneWidget);

        final wordmarkText = tester.widget<Text>(find.text('AAYUSATHI'));
        expect(wordmarkText.style?.color, equals(DoctorColors.dialogDarkTeal));

        final taglineText = tester.widget<Text>(find.text('LIVE BETTER, TOGETHER'));
        expect(taglineText.style?.color, equals(DoctorColors.dialogPrimaryText));

        // 3. Verify Warning banner has light red background and dark red text
        expect(
          find.textContaining('Complete all required consultation fields and approve the visit summary'),
          findsOneWidget,
        );
        expect(find.textContaining('Missing requirements:'), findsOneWidget);
        final warningIcon = find.byIcon(Icons.warning_amber_rounded);
        expect(warningIcon, findsOneWidget);
        final iconWidget = tester.widget<Icon>(warningIcon);
        expect(iconWidget.color, equals(DoctorColors.dialogWarningText));

        // 4. Verify report sections are visible with high-contrast text
        expect(find.text('SECTION 1 — VISIT IDENTIFICATION'), findsOneWidget);
        expect(find.text('SECTION 2 — PATIENT INFORMATION'), findsOneWidget);
        expect(find.text('SECTION 3 — VITALS AT CONSULTATION'), findsOneWidget);
        expect(find.text('SECTION 4 — CASE INFORMATION'), findsOneWidget);
        expect(find.text('SECTION 5 — STRUCTURED CONSULTATION'), findsOneWidget);
        expect(find.text('SECTION 6 — DOCTOR-APPROVED VISIT SUMMARY'), findsOneWidget);

        // 5. Verify Close button and disabled Generate PDF button
        final closeBtn = find.text('CLOSE');
        expect(closeBtn, findsOneWidget);

        final generateBtn = find.text('GENERATE VISIT PDF');
        expect(generateBtn, findsOneWidget);

        // Attempting to tap Generate Visit PDF when requirements are incomplete should NOT trigger PDF
        await tester.tap(generateBtn);
        await tester.pumpAndSettle();
        expect(pdfTriggered, isFalse);
      }
    });

    testWidgets('2. DoctorTransferPatientDialog: White dropdown, visible departments & transfer flow',
        (tester) async {
      String? transferredDept;
      String? transferReason;

      for (final themeData in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: themeData,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (_) => DoctorTransferPatientDialog(
                        patientName: 'Rohan Sharma',
                        patientAge: 41,
                        patientGender: 'Male',
                        currentDepartment: 'Cardiology',
                        onTransferConfirmed: (dept, reason) {
                          transferredDept = dept;
                          transferReason = reason;
                        },
                      ),
                    );
                  },
                  child: const Text('OPEN_TRANSFER'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('OPEN_TRANSFER'));
        await tester.pumpAndSettle();

        // 1. Verify Dialog background is pure white
        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);
        final dialogWidget = tester.widget<Dialog>(dialogFinder);
        expect(dialogWidget.backgroundColor, equals(DoctorColors.dialogBg));

        // 2. Verify title and current patient info
        expect(find.text('TRANSFER PATIENT'), findsOneWidget);
        expect(find.textContaining('Rohan Sharma'), findsOneWidget);
        expect(find.textContaining('Cardiology'), findsWidgets);

        // 3. Verify dropdown styling
        final formFieldFinder = find.byType(DropdownButtonFormField<String>);
        expect(formFieldFinder, findsOneWidget);
        final dropdownButtonFinder = find.descendant(
          of: formFieldFinder,
          matching: find.byType(DropdownButton<String>),
        );
        expect(dropdownButtonFinder, findsOneWidget);
        final dropdownWidget = tester.widget<DropdownButton<String>>(dropdownButtonFinder);
        expect(dropdownWidget.dropdownColor, equals(DoctorColors.dialogBg));

        // 4. Tap dropdown to open menu items
        await tester.tap(formFieldFinder);
        await tester.pumpAndSettle();

        // Check standard healthcare domains are present in dropdown
        expect(find.text('Neurology'), findsWidgets);
        expect(find.text('Gastroenterology'), findsWidgets);
        expect(find.text('Orthopedics'), findsWidgets);
        expect(find.text('Pediatrics'), findsWidgets);
        expect(find.text('ENT'), findsWidgets);
        expect(find.text('Dermatology'), findsWidgets);
        expect(find.text('General Medicine'), findsWidgets);

        // Select Neurology
        await tester.tap(find.text('Neurology').last);
        await tester.pumpAndSettle();

        // 5. Verify validation: trying to proceed without minimum reason fails
        await tester.tap(find.text('REVIEW TRANSFER'));
        await tester.pumpAndSettle();
        expect(
          find.text('Please provide a reason for transferring this patient (minimum 5 characters).'),
          findsOneWidget,
        );

        // 6. Enter valid reason
        await tester.enterText(
          find.byType(TextFormField),
          'Patient requires immediate neurological assessment and cranial CT review.',
        );
        await tester.pumpAndSettle();

        // Proceed to Step 2 Review
        await tester.tap(find.text('REVIEW TRANSFER'));
        await tester.pumpAndSettle();

        // Verify Step 2 confirmation review
        expect(find.text('CONFIRM TRANSFER'), findsOneWidget);
        expect(find.text('BACK'), findsOneWidget);

        // Confirm transfer
        await tester.tap(find.text('CONFIRM TRANSFER'));
        await tester.pumpAndSettle();

        expect(transferredDept, equals('Neurology'));
        expect(transferReason, contains('neurological assessment'));

        // Reset for next theme iteration
        transferredDept = null;
        transferReason = null;
      }
    });

    testWidgets('3. Active Visit Exists Warning Dialog: White background, warning icon, dark navy text & close dismiss',
        (tester) async {
      for (final themeData in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        bool dismissed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: themeData,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    final strings = DoctorLocalizations.forLocale(KioskLocale.english);
                    await showDialog(
                      context: ctx,
                      builder: (dialogCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: DoctorColors.dialogBorder, width: 1.0),
                        ),
                        backgroundColor: DoctorColors.dialogBg,
                        surfaceTintColor: Colors.transparent,
                        elevation: 8,
                        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: DoctorColors.dialogWarningBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: DoctorColors.dialogWarningBorder),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: DoctorColors.dialogWarningText,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                strings.activeVisitExistsTitle,
                                style: const TextStyle(
                                  color: DoctorColors.dialogPrimaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          strings.activeVisitBlocksClosureError,
                          style: const TextStyle(
                            color: DoctorColors.dialogSecondaryText,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DoctorColors.dialogPrimaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              elevation: 0,
                            ),
                            onPressed: () {
                              dismissed = true;
                              Navigator.of(dialogCtx).pop();
                            },
                            child: Text(
                              strings.close,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('TRIGGER_WARNING'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('TRIGGER_WARNING'));
        await tester.pumpAndSettle();

        // 1. Verify AlertDialog background is pure white
        final alertFinder = find.byType(AlertDialog);
        expect(alertFinder, findsOneWidget);
        final alertWidget = tester.widget<AlertDialog>(alertFinder);
        expect(alertWidget.backgroundColor, equals(DoctorColors.dialogBg));

        // 2. Verify title "Active Visit Exists" is readable dark navy
        final titleText = tester.widget<Text>(find.text('Active Visit Exists'));
        expect(titleText.style?.color, equals(DoctorColors.dialogPrimaryText));

        // 3. Verify message is readable dark secondary text
        final msgFinder = find.textContaining('Complete or transfer the active Visit');
        expect(msgFinder, findsOneWidget);
        final msgText = tester.widget<Text>(msgFinder);
        expect(msgText.style?.color, equals(DoctorColors.dialogSecondaryText));

        // 4. Verify Close button is primary teal with white text
        final closeBtnFinder = find.widgetWithText(ElevatedButton, 'CLOSE');
        expect(closeBtnFinder, findsOneWidget);
        final closeBtn = tester.widget<ElevatedButton>(closeBtnFinder);
        expect(closeBtn.style?.backgroundColor?.resolve({}), equals(DoctorColors.dialogPrimaryTeal));
        expect(closeBtn.style?.foregroundColor?.resolve({}), equals(Colors.white));

        // 5. Verify Close button dismisses dialog without side effects
        await tester.tap(closeBtnFinder);
        await tester.pumpAndSettle();
        expect(dismissed, isTrue);
        expect(find.byType(AlertDialog), findsNothing);
      }
    });

    testWidgets('4. DoctorCloseCaseDialog: Contrast, declaration confirmation & closure note validation',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? confirmedClosureNote;

      for (final themeData in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: themeData,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    final note = await showDialog<String>(
                      context: ctx,
                      builder: (_) => DoctorCloseCaseDialog(
                        clinicalCase: mockCase,
                      ),
                    );
                    confirmedClosureNote = note;
                  },
                  child: const Text('OPEN_CLOSE_CASE'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('OPEN_CLOSE_CASE'));
        await tester.pumpAndSettle();

        // 1. Verify Dialog background
        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);
        final dialogWidget = tester.widget<Dialog>(dialogFinder);
        expect(dialogWidget.backgroundColor, equals(DoctorColors.dialogBg));

        // 2. Verify titles and labels (Header title and action button both use CLOSE CASE)
        expect(find.text('CLOSE CASE'), findsNWidgets(2));
        expect(find.textContaining('Cardiology • Severe Angina Pectoris'), findsOneWidget);

        // 3. Checkbox toggling and note entry
        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'Treatment completed successfully. Patient advised on lifestyle and medication adherence.',
        );
        await tester.pumpAndSettle();

        // 4. Close case
        final closeCaseBtn = find.widgetWithText(DoctorPrimaryButton, 'CLOSE CASE');
        await tester.ensureVisible(closeCaseBtn);
        await tester.pumpAndSettle();
        await tester.tap(closeCaseBtn);
        await tester.pumpAndSettle();

        expect(confirmedClosureNote, contains('Treatment completed successfully'));
        expect(find.byType(Dialog), findsNothing);

        // Reset
        confirmedClosureNote = null;
      }
    });
  });
}
