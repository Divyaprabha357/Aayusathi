import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/prescription_item.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/models/visit_report_pdf_result.dart';
import 'package:aayusathi/doctor/services/mock_pdf_output_service.dart';
import 'package:aayusathi/doctor/services/visit_report_pdf_service.dart';
import 'package:aayusathi/doctor/services/windows_pdf_output_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_pdf_success_dialog.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/models/vital_reading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockPatient = Patient(
    patientId: 'AAYU-102938',
    name: 'Aarav Sharma',
    dateOfBirth: '1990-05-12',
    age: 36,
    gender: 'Male',
    phone: '+919876543210',
    bloodGroup: 'B+',
    address: 'Mumbai, India',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockCase = ClinicalCase(
    caseId: 'CASE-001',
    patientId: 'AAYU-102938',
    domain: 'Cardiology',
    title: 'Atypical Chest Pain',
    status: ClinicalCaseStatus.open,
    relevantHistory: 'Hypertension on Telmisartan.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final completeVisit = ClinicalVisit(
    visitId: 'VIS-001',
    caseId: 'CASE-001',
    patientId: 'AAYU-102938',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD (Cardiology)',
    visitNumber: 1,
    startedAt: DateTime.now(),
    status: ClinicalVisitStatus.active,
    chiefComplaint: 'Chest tightness for 3 days',
    onsetDuration: '3 days, insidious onset',
    associatedSymptoms: 'Mild breathlessness',
    medicalHistory: 'Known hypertensive',
    currentMedication: 'Telmisartan 40mg OD',
    clinicalObservations: 'S1 S2 normal, chest clear',
    assessment: 'Likely non-cardiac chest discomfort',
    plan: '12-lead ECG, blood work, reassurance',
    summary: 'Patient evaluated for atypical chest discomfort. Normal vitals.',
    summaryText: 'Patient evaluated for atypical chest discomfort. Normal vitals.',
    summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
    approvedByDoctorId: 'DOC-101',
    approvedAt: DateTime.now(),
    followUp: 'Review in 2 weeks',
    patientInstructions: 'Take medications on time.',
    prescriptions: const [
      PrescriptionItem(
        medicineName: 'Paracetamol 650mg',
        duration: '5 days',
        timesPerDay: '1-0-1',
        remarks: 'After food',
      ),
    ],
  );

  final completeReportData = VisitReportData.fromComponents(
    patient: mockPatient,
    clinicalCase: mockCase,
    visit: completeVisit,
    vitals: VitalReading(
      vitalId: 'VIT-1',
      patientId: 'AAYU-102938',
      heartRate: 72,
      spo2: 98,
      temperature: 36.8,
      timestamp: DateTime.now(),
    ),
  );

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockPdfOutputService.instance.reset();
  });

  group('Phase D11.1 — Safe Filename Generation Tests', () {
    test('1. Generates expected standard filename format', () {
      final fileName = VisitReportPdfService.instance.generateSafeFileName(
        patientId: 'AAYU-102938',
        visitNumber: 1,
      );
      expect(fileName, 'AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf');
    });

    test('2. Sanitizes illegal characters and path traversal attempts', () {
      final fileName = VisitReportPdfService.instance.generateSafeFileName(
        patientId: '../../etc/passwd:bad*name?|<test>',
        visitNumber: 2,
      );
      expect(fileName.contains('..'), isFalse);
      expect(fileName.contains('/'), isFalse);
      expect(fileName.contains('\\'), isFalse);
      expect(fileName.contains(':'), isFalse);
      expect(fileName.contains('*'), isFalse);
      expect(fileName.contains('?'), isFalse);
      expect(fileName.contains('<'), isFalse);
      expect(fileName.contains('>'), isFalse);
      expect(fileName.contains('|'), isFalse);
      expect(fileName.endsWith('.pdf'), isTrue);
    });

    test('3. Handles whitespace and empty patient ID gracefully', () {
      final fileName = VisitReportPdfService.instance.generateSafeFileName(
        patientId: '   ',
        visitNumber: 5,
      );
      expect(fileName, 'AAYUSATHI_Visit_Report_Patient_Visit_5.pdf');
    });
  });

  group('Phase D11.1 — PDF Generation & File Output Tests', () {
    test('4. Generates PDF bytes and saves to MockPdfOutputService', () async {
      final mockOutput = MockPdfOutputService.instance;
      final result = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        completeReportData,
        outputService: mockOutput,
      );

      expect(result.isSuccess, isTrue);
      expect(result.filePath, isNotNull);
      expect(result.fileName, 'AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf');
      expect(result.fileSizeBytes, greaterThan(0));
      expect(result.pdfBytes, isNotNull);
      expect(result.pdfBytes![0], 0x25); // %
      expect(result.pdfBytes![1], 0x50); // P
      expect(result.pdfBytes![2], 0x44); // D
      expect(result.pdfBytes![3], 0x46); // F
      expect(mockOutput.savedFiles.containsKey(result.filePath), isTrue);
    });

    test('5. Fails gracefully when consultation gating requirements are not met', () async {
      final incompleteData = VisitReportData.fromComponents(
        patient: mockPatient,
        clinicalCase: mockCase,
        visit: completeVisit.copyWith(chiefComplaint: ''),
      );

      final result = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        incompleteData,
        outputService: MockPdfOutputService.instance,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'GATING_REQUIREMENTS_NOT_MET');
      expect(result.errorMessage, contains('Chief Complaint'));
      expect(MockPdfOutputService.instance.savedFiles.isEmpty, isTrue);
    });

    test('6. Handles file write failure gracefully', () async {
      final mockOutput = MockPdfOutputService.instance;
      mockOutput.simulateWriteFailure = true;
      mockOutput.writeErrorMessage = 'Disk full on drive C:';

      final result = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        completeReportData,
        outputService: mockOutput,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'FILE_WRITE_FAILED');
      expect(result.errorMessage, contains('Disk full on drive C:'));
    });
  });

  group('Phase D11.1 — PdfOutputService Open & Save-As Operations', () {
    test('7. MockPdfOutputService records openPdf calls', () async {
      final mockOutput = MockPdfOutputService.instance;
      final saveResult = await mockOutput.saveGeneratedPdf(
        fileName: 'test.pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x00]),
      );

      expect(saveResult.isSuccess, isTrue);
      final openResult = await mockOutput.openPdf(saveResult.savedPath!);
      expect(openResult.isSuccess, isTrue);
      expect(mockOutput.openedFiles, contains(saveResult.savedPath));
    });

    test('8. MockPdfOutputService returns failure on non-existent file open', () async {
      final mockOutput = MockPdfOutputService.instance;
      final openResult = await mockOutput.openPdf('C:\\non_existent.pdf');
      expect(openResult.isSuccess, isFalse);
      expect(openResult.errorMessage, contains('does not exist'));
    });

    test('9. MockPdfOutputService simulates open failure', () async {
      final mockOutput = MockPdfOutputService.instance;
      mockOutput.simulateOpenFailure = true;
      mockOutput.openErrorMessage = 'Windows could not find a default PDF application.';

      final openResult = await mockOutput.openPdf('any_path.pdf');
      expect(openResult.isSuccess, isFalse);
      expect(openResult.errorMessage, contains('could not find a default PDF application'));
    });

    test('10. MockPdfOutputService handles Save-As operation', () async {
      final mockOutput = MockPdfOutputService.instance;
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x00]);

      final saveAsResult = await mockOutput.savePdfAs(
        defaultFileName: 'AAYUSATHI_Visit_Report_1.pdf',
        bytes: bytes,
      );

      expect(saveAsResult.isSuccess, isTrue);
      expect(saveAsResult.savedPath, contains('Desktop'));
      expect(mockOutput.savedAsFiles.length, 1);
    });

    test('11. MockPdfOutputService handles Save-As cancellation safely without error', () async {
      final mockOutput = MockPdfOutputService.instance;
      mockOutput.simulateSaveAsCancelled = true;

      final saveAsResult = await mockOutput.savePdfAs(
        defaultFileName: 'AAYUSATHI_Visit_Report_1.pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x00]),
      );

      expect(saveAsResult.isSuccess, isFalse);
      expect(saveAsResult.isCancelled, isTrue);
      expect(saveAsResult.errorMessage, isNull);
    });

    test('12. WindowsPdfOutputService rejects empty or invalid bytes', () async {
      final winOutput = WindowsPdfOutputService.instance;

      final emptyResult = await winOutput.saveGeneratedPdf(
        fileName: 'empty.pdf',
        bytes: Uint8List(0),
      );
      expect(emptyResult.isSuccess, isFalse);
      expect(emptyResult.errorMessage, contains('empty'));

      final invalidResult = await winOutput.saveGeneratedPdf(
        fileName: 'invalid.pdf',
        bytes: Uint8List.fromList([0x00, 0x01, 0x02, 0x03]),
      );
      expect(invalidResult.isSuccess, isFalse);
      expect(invalidResult.errorMessage, contains('valid PDF headers'));
    });
  });

  group('Phase D11.1 — UI Dialog & Localization Tests', () {
    testWidgets('13. DoctorPdfSuccessDialog renders metadata and triggers OPEN PDF',
        (tester) async {
      final mockOutput = MockPdfOutputService.instance;
      final pdfResult = VisitReportPdfResult.success(
        filePath: 'C:\\Users\\MockUser\\Documents\\AAYUSATHI\\VisitReports\\AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
        fileName: 'AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
        fileSizeBytes: 125952,
        pdfBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x00]),
      );

      // Pre-populate mock output so open succeeds
      mockOutput.savedFiles[pdfResult.filePath!] = pdfResult.pdfBytes!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPdfSuccessDialog(
              result: pdfResult,
              pdfOutputService: mockOutput,
            ),
          ),
        ),
      );

      expect(find.text('Visit Report PDF Created'), findsOneWidget);
      expect(find.text('AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf'), findsOneWidget);
      expect(find.text('123 KB'), findsOneWidget);
      expect(find.text('OPEN PDF'), findsOneWidget);
      expect(find.text('SAVE AS'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      // Tap OPEN PDF
      await tester.tap(find.text('OPEN PDF'));
      await tester.pumpAndSettle();

      expect(mockOutput.openedFiles, contains(pdfResult.filePath));
    });

    testWidgets('14. DoctorPdfSuccessDialog triggers SAVE AS and shows success status',
        (tester) async {
      final mockOutput = MockPdfOutputService.instance;
      final pdfResult = VisitReportPdfResult.success(
        filePath: 'C:\\Users\\MockUser\\Documents\\AAYUSATHI\\VisitReports\\AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
        fileName: 'AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
        fileSizeBytes: 125952,
        pdfBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x00]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPdfSuccessDialog(
              result: pdfResult,
              pdfOutputService: mockOutput,
            ),
          ),
        ),
      );

      // Tap SAVE AS
      await tester.tap(find.text('SAVE AS'));
      await tester.pumpAndSettle();

      expect(mockOutput.savedAsFiles.isNotEmpty, isTrue);
      expect(find.textContaining('PDF report copy saved successfully'), findsOneWidget);
    });

    testWidgets('15. DoctorPdfSuccessDialog displays error banner if open fails',
        (tester) async {
      final mockOutput = MockPdfOutputService.instance;
      mockOutput.simulateOpenFailure = true;
      mockOutput.openErrorMessage = 'PDF was created, but Windows could not open the file.';

      final pdfResult = VisitReportPdfResult.success(
        filePath: 'C:\\Users\\MockUser\\Documents\\report.pdf',
        fileName: 'report.pdf',
        fileSizeBytes: 50000,
        pdfBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x00]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPdfSuccessDialog(
              result: pdfResult,
              pdfOutputService: mockOutput,
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN PDF'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('PDF was created, but Windows could not open the file.'),
        findsOneWidget,
      );
    });

    test('16. Localized strings for Phase D11.1 across English, Hindi, Marathi', () {
      final en = DoctorLocalizations.forLocale(KioskLocale.english);
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      // Dialog Title
      expect(en.pdfCreatedSuccessTitle, 'Visit Report PDF Created');
      expect(hi.pdfCreatedSuccessTitle, 'विज़िट रिपोर्ट PDF तैयार');
      expect(mr.pdfCreatedSuccessTitle, 'भेट अहवाल PDF तयार झाला');

      // Buttons
      expect(en.openPdfButton, 'OPEN PDF');
      expect(hi.openPdfButton, 'PDF खोलें');
      expect(mr.openPdfButton, 'PDF उघडा');

      expect(en.saveAsButton, 'SAVE AS');
      expect(hi.saveAsButton, 'इस रूप में सहेजें');
      expect(mr.saveAsButton, 'या नावाने जतन करा');

      // Error and Save As notices
      expect(en.pdfOpenError, contains('Windows could not open'));
      expect(hi.pdfOpenError, contains('विंडोज़ फ़ाइल नहीं खोल सका'));
      expect(mr.pdfOpenError, contains('विंडोज फाइल उघडू शकले नाही'));

      expect(en.pdfSaveAsSuccess, contains('saved successfully'));
      expect(hi.pdfSaveAsSuccess, contains('सफलतापूर्वक सहेजी गई'));
      expect(mr.pdfSaveAsSuccess, contains('यशस्वीरित्या जतन केली'));
    });
  });
}
