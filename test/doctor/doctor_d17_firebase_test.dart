import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/firebase/firebase_config.dart';
import 'package:aayusathi/doctor/models/doctor_assignment_result.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/models/visit_report_pdf_result.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_pdf_output_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/doctor/services/visit_report_pdf_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_pdf_success_dialog.dart';
import 'package:aayusathi/firebase_options.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockStorageService.instance.reset();
    MockReportRepository.instance.reset();
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    DoctorPresenceService.instance = MockDoctorPresenceService();
    await DoctorPresenceService.instance.setAvailable();
  });

  group('Phase D17: Firebase Project Configuration & Region Tests', () {
    test('1. FirebaseConfig matches authoritative project aayusathi-a1199 in asia-south1', () {
      expect(FirebaseConfig.projectId, equals('aayusathi-a1199'));
      expect(FirebaseConfig.projectNumber, equals('919886761374'));
      expect(FirebaseConfig.region, equals('asia-south1'));
      expect(FirebaseConfig.storageBucket, equals('aayusathi-a1199.firebasestorage.app'));
    });

    test('2. DefaultFirebaseOptions windows configuration matches project aayusathi-a1199', () {
      final options = DefaultFirebaseOptions.windows;
      expect(options.projectId, equals('aayusathi-a1199'));
      expect(options.messagingSenderId, equals('919886761374'));
      expect(options.storageBucket, equals('aayusathi-a1199.firebasestorage.app'));
    });
  });

  group('Phase D17: Storage Magic-Header Binary Validation Tests', () {
    final storage = MockStorageService.instance;

    test('3. Valid PDF magic bytes (%PDF) passes validation', () {
      final pdfBytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34];
      final res = storage.validateFile(
        fileName: 'report.pdf',
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, equals('application/pdf'));
    });

    test('4. Valid JPEG magic bytes (FF D8 FF) passes validation', () {
      final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];
      final res = storage.validateFile(
        fileName: 'xray.jpg',
        bytes: jpegBytes,
        mimeType: 'image/jpeg',
      );
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, equals('image/jpeg'));
    });

    test('5. Valid PNG magic bytes (89 50 4E 47) passes validation', () {
      final pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final res = storage.validateFile(
        fileName: 'scan.png',
        bytes: pngBytes,
        mimeType: 'image/png',
      );
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, equals('image/png'));
    });

    test('6. Corrupted / mismatched header bytes are rejected', () {
      final badBytes = [0x00, 0x00, 0x00, 0x00];
      final res = storage.validateFile(
        fileName: 'spoofed.pdf',
        bytes: badBytes,
        mimeType: 'application/pdf',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('File header mismatch'));
    });

    test('7. Files larger than 15 MB are rejected', () {
      final dummyLargeBytes = Uint8List(16 * 1024 * 1024); // 16MB
      final res = storage.validateFile(
        fileName: 'huge.pdf',
        bytes: dummyLargeBytes,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('15 MB limit'));
    });

    test('8. Disallowed file extensions are rejected', () {
      final res = storage.validateFile(
        fileName: 'malicious.exe',
        bytes: [0x4D, 0x5A, 0x90, 0x00],
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Unsupported file format'));
    });
  });

  group('Phase D17: Official Doctor PDF Dual-Path (Local + Cloud) Tests', () {
    final pdfService = VisitReportPdfService.instance;
    final mockOutput = MockPdfOutputService();

    final testReportData = VisitReportData(
      patientId: 'PAT-001',
      patientName: 'Aarav Sharma',
      age: 42,
      gender: 'Male',
      bloodGroup: 'O+',
      patientType: 'Outpatient',
      caseId: 'CASE-001',
      caseTitle: 'Hypertension Clinical Review',
      caseType: 'Chronic',
      caseStatus: 'OPEN',
      department: 'Cardiology',
      visitNumber: 1,
      visitStatus: 'ACTIVE',
      dateTime: DateTime.now(),
      doctorName: 'Dr. Ramesh Kumar',
      doctorQualification: 'MD, DM (Cardiology)',
      chiefComplaint: 'Chest tightness on exertion',
      onsetDuration: '3 days',
      associatedSymptoms: 'Mild fatigue',
      medicalHistory: 'Hypertension (2 years)',
      currentMedication: 'Amlodipine 5mg OD',
      clinicalObservations: 'Normal heart sounds, BP 138/88 mmHg',
      assessment: 'Essential Hypertension Stage 1',
      plan: 'Continue Amlodipine, schedule ECG',
      prescriptions: const [],
      investigations: const [],
      summary: 'Patient exhibits stable blood pressure under current medication.',
      summaryStatus: 'APPROVED BY DOCTOR',
      approvedDoctorId: 'DOC-101',
      approvedAt: DateTime.now(),
      isSummaryApproved: true,
      completionVisitNumber: '1',
      completionCaseId: 'CASE-001',
      consultingDoctor: 'Dr. Ramesh Kumar',
      consultingDoctorQualification: 'MD, DM (Cardiology)',
      summaryApprovalNotice: 'Approved for official record',
    );

    test('9. generateAndSaveVisitPdf succeeds and creates local file', () async {
      final localRes = await pdfService.generateAndSaveVisitPdf(
        testReportData,
        outputService: mockOutput,
      );

      expect(localRes.isSuccess, isTrue);
      expect(localRes.filePath, isNotNull);
      expect(localRes.fileName, contains('AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf'));
      expect(localRes.pdfBytes, isNotNull);
      expect(localRes.pdfBytes!.isNotEmpty, isTrue);
    });

    test('10. uploadVisitReportPdfToCloud uploads bytes to Cloud Storage and saves ReportDocument metadata', () async {
      final localRes = await pdfService.generateAndSaveVisitPdf(
        testReportData,
        outputService: mockOutput,
      );
      expect(localRes.isSuccess, isTrue);

      final cloudRes = await pdfService.uploadVisitReportPdfToCloud(
        localResult: localRes,
        data: testReportData,
        storageService: MockStorageService.instance,
        reportRepository: MockReportRepository.instance,
      );

      expect(cloudRes.isCloudUploaded, isTrue);
      expect(cloudRes.cloudStoragePath, contains('patients/PAT-001/cases/CASE-001/visits/VIS-CASE-001-1/reports/'));
      expect(cloudRes.cloudUploadError, isNull);

      // Verify ReportDocument saved in repository
      final reports = await MockReportRepository.instance.getReportsForVisit(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
      );
      expect(reports.any((r) => r.investigationId == 'OFFICIAL_VISIT_REPORT'), isTrue);
    });

    test('11. Cloud upload failure preserves local PDF with valid filePath and non-empty bytes', () async {
      final localRes = await pdfService.generateAndSaveVisitPdf(
        testReportData,
        outputService: mockOutput,
      );
      expect(localRes.isSuccess, isTrue);

      MockStorageService.instance.simulateUploadFailure = true;
      MockStorageService.instance.failureErrorMessage = 'Simulated network timeout';

      final cloudRes = await pdfService.uploadVisitReportPdfToCloud(
        localResult: localRes,
        data: testReportData,
        storageService: MockStorageService.instance,
        reportRepository: MockReportRepository.instance,
      );

      // Local PDF remains completely intact
      expect(cloudRes.isSuccess, isTrue);
      expect(cloudRes.filePath, isNotNull);
      expect(cloudRes.pdfBytes, isNotNull);
      // Cloud status reflects warning
      expect(cloudRes.isCloudUploaded, isFalse);
      expect(cloudRes.cloudUploadError, contains('Simulated network timeout'));
    });
  });

  group('Phase D17: First-Doctor-Wins & Presence Lifecycle Tests', () {
    test('12. Doctor presence transitions accurately across workflow', () async {
      final presence = DoctorPresenceService.instance;
      expect(presence.isAvailable, isTrue);

      await presence.setInConsultation();
      expect(presence.isInConsultation, isTrue);
      expect(presence.isAvailable, isFalse);

      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);
    });

    test('13. First-Doctor-Wins assignment result models duplicate protection', () {
      final successResult = DoctorAssignmentResult.success(
        requestId: 'REQ-001',
        appointmentId: 'APT-001',
        queueNumber: 'A-00001',
        assignedDoctorId: 'DOC-101',
        message: 'Successfully assigned',
      );
      expect(successResult.isSuccess, isTrue);

      final conflictResult = DoctorAssignmentResult.alreadyAssigned(
        requestId: 'REQ-001',
        queueNumber: 'A-00001',
        message: 'Patient request has already been assigned to another doctor.',
      );
      expect(conflictResult.isSuccess, isFalse);
      expect(conflictResult.isAlreadyAssigned, isTrue);
    });
  });

  group('Phase D17: Sequential Visits & Doctor Scoping Tests', () {
    final caseRepo = MockCaseRepository.instance;
    final visitRepo = MockClinicalVisitRepository.instance;

    test('14. Explicit new visit sequential numbering increments atomically without auto-creation', () async {
      final initialVisits = await visitRepo.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      final initialCount = initialVisits.length;

      // Creating next visit
      final newVisit = await visitRepo.createNextVisit(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Ramesh Kumar',
        chiefComplaint: 'Follow-up consultation',
      );

      expect(newVisit.visitNumber, equals(initialCount + 1));
      expect(newVisit.isActive, isTrue);

      // Attempting to create duplicate active visit throws
      expect(
        () => visitRepo.createNextVisit(
          patientId: 'PAT-MOCK-001',
          caseId: 'CASE-PAT-001-01',
          doctorId: 'DOC-101',
          doctorName: 'Dr. Ramesh Kumar',
        ),
        throwsStateError,
      );

      // Complete the visit
      final completed = await visitRepo.completeVisit(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        visitId: newVisit.visitId,
        doctorId: 'DOC-101',
      );
      expect(completed.isCompleted, isTrue);

      // Parent case remains OPEN
      final parentCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(parentCase?.isOpen, isTrue);
    });

    test('15. Backend getCasesForDoctor strictly scopes cases to doctor involvement', () async {
      final doc101Cases = await caseRepo.getCasesForDoctor('DOC-101');
      expect(doc101Cases.any((c) => c.caseId == 'CASE-PAT-001-01'), isTrue);
      expect(doc101Cases.any((c) => c.caseId == 'CASE-102938-01'), isTrue);
      expect(doc101Cases.any((c) => c.domain.toLowerCase() == 'orthopedics'), isFalse);
      expect(doc101Cases.any((c) => c.domain.toLowerCase() == 'dermatology'), isFalse);
    });

    test('16. Explicit closeCase marks case CLOSED with doctor note and declaration', () async {
      final closed = await caseRepo.closeCase(
        patientId: 'AAYU-102938',
        caseId: 'CASE-102938-01',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Ramesh Kumar',
        closureNote: 'Patient hypertension fully resolved and stabilized.',
      );

      expect(closed.isClosed, isTrue);
      expect(closed.closedByDoctorId, equals('DOC-101'));
      expect(closed.closureNote, contains('fully resolved'));

      // Attempting to close already closed case fails
      expect(
        () => caseRepo.closeCase(
          patientId: 'AAYU-102938',
          caseId: 'CASE-102938-01',
          doctorId: 'DOC-101',
          closureNote: 'Duplicate closure attempt',
        ),
        throwsException,
      );
    });
  });

  group('Phase D17: Audit Trail Sanitization Tests', () {
    test('17. Audit logs contain zero passwords, OTPs, or raw Aadhaar numbers', () {
      final log = AuditLog(
        auditId: 'AUD-100',
        actorType: 'DOCTOR',
        actorId: 'DOC-101',
        action: 'VISIT_REPORT_PDF_GENERATED',
        entityType: 'CLINICAL_VISIT',
        entityId: 'CASE-001',
        timestamp: DateTime.now(),
        metadata: {
          'patientId': 'PAT-001',
          'caseId': 'CASE-001',
          'visitNumber': 1,
          'fileName': 'AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf',
        },
      );

      final map = log.toMap();
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('otp'), isFalse);
      expect(map.containsKey('aadhaar'), isFalse);
      expect(map.containsKey('aadhaarNumber'), isFalse);
    });
  });

  group('Phase D17: DoctorPdfSuccessDialog Widget Integration Tests', () {
    testWidgets('18. Dialog displays local file details, Open PDF button, and Cloud Sync indicator', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final result = VisitReportPdfResult.success(
        filePath: r'C:\Users\Doctor\Desktop\AAYUSATHI_Visit_Report.pdf',
        fileName: 'AAYUSATHI_Visit_Report.pdf',
        fileSizeBytes: 45000,
        pdfBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        cloudStoragePath: 'patients/PAT-001/cases/CASE-001/visits/VIS-1/reports/AAYUSATHI_Visit_Report.pdf',
        isCloudUploaded: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPdfSuccessDialog(result: result),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AAYUSATHI_Visit_Report.pdf'), findsOneWidget);
      expect(find.text('OPEN PDF'), findsOneWidget);
      expect(find.textContaining('SAVE AS'), findsOneWidget);
      expect(find.text('Cloud Copy Synchronized'), findsOneWidget);
    });

    testWidgets('19. Dialog displays cloud upload pending notice if cloud copy encounters error, while keeping OPEN PDF active', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final result = VisitReportPdfResult.success(
        filePath: r'C:\Users\Doctor\Desktop\AAYUSATHI_Visit_Report.pdf',
        fileName: 'AAYUSATHI_Visit_Report.pdf',
        fileSizeBytes: 45000,
        pdfBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        isCloudUploaded: false,
        cloudUploadError: 'Network unavailable',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPdfSuccessDialog(result: result),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPEN PDF'), findsOneWidget);
      expect(find.text('Cloud upload pending / offline (Local PDF ready)'), findsOneWidget);
    });
  });
}
