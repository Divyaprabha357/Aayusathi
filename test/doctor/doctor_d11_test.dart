import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/models/prescription_item.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/doctor/services/visit_report_pdf_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_reports_review_widget.dart';
import 'package:aayusathi/doctor/widgets/doctor_request_investigation_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_visit_report_preview_dialog.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/patient/services/patient_investigation_service.dart';
import 'package:aayusathi/patient/widgets/patient_reports_card.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    BackendProvider.instance.resetOverrides();
    MockInvestigationRepository.instance.reset();
    MockReportRepository.instance.reset();
    MockStorageService.instance.reset();
  });

  group('Phase D11 — Data Models & Serialization Tests', () {
    test('1. InvestigationRequest serializes and deserializes correctly', () {
      final req = InvestigationRequest(
        requestId: 'INV-101',
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-001',
        requestedByDoctorId: 'DOC-101',
        department: 'Cardiology',
        name: 'Serum Electrolytes',
        category: InvestigationCategory.lab,
        priority: InvestigationPriority.required,
        status: InvestigationStatus.pendingUpload,
        requestedAt: DateTime(2026, 9, 6, 12, 0),
        notes: 'Fasting preferred',
      );

      final map = req.toMap();
      expect(map['requestId'], 'INV-101');
      expect(map['investigationId'], 'INV-101');
      expect(map['category'], 'lab');
      expect(map['priority'], 'required');
      expect(map['status'], 'pendingUpload');

      final fromMap = InvestigationRequest.fromMap(map);
      expect(fromMap.name, 'Serum Electrolytes');
      expect(fromMap.category, InvestigationCategory.lab);
      expect(fromMap.priority, InvestigationPriority.required);
      expect(fromMap.isRequired, isTrue);
      expect(fromMap.isPendingUpload, isTrue);
    });

    test('2. InvestigationCategory and Priority helper mappings', () {
      expect(InvestigationCategory.fromString('laboratory'), InvestigationCategory.lab);
      expect(InvestigationCategory.fromString('imaging'), InvestigationCategory.radiology);
      expect(InvestigationCategory.fromString('diagnostic'), InvestigationCategory.diagnostic);
      expect(InvestigationCategory.fromString('unknown_category'), InvestigationCategory.other);

      expect(InvestigationPriority.fromString('as_advised'), InvestigationPriority.asAdvised);
      expect(InvestigationPriority.fromString('required'), InvestigationPriority.required);

      expect(InvestigationStatus.fromString('uploaded'), InvestigationStatus.uploaded);
      expect(InvestigationStatus.fromString('reviewed'), InvestigationStatus.reviewed);
      expect(InvestigationStatus.fromString('cancelled'), InvestigationStatus.cancelled);
    });

    test('3. ReportDocument model serializes and detects MIME types correctly', () {
      final rep = ReportDocument(
        reportId: 'REP-001',
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-001',
        investigationId: 'INV-101',
        fileName: 'Blood_Test_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 204800,
        storagePath: 'patients/PAT-001/cases/CASE-001/visits/VIS-001/reports/INV-101/Blood_Test_Report.pdf',
        uploadedAt: DateTime(2026, 9, 6, 12, 30),
        uploadedByPatientId: 'PAT-001',
        reviewStatus: ReportReviewStatus.uploaded,
      );

      expect(rep.isPdf, isTrue);
      expect(rep.isImage, isFalse);
      expect(rep.isUploaded, isTrue);
      expect(rep.isReviewed, isFalse);

      final map = rep.toMap();
      final fromMap = ReportDocument.fromMap(map);
      expect(fromMap.reportId, 'REP-001');
      expect(fromMap.fileName, 'Blood_Test_Report.pdf');
      expect(fromMap.fileSizeBytes, 204800);
      expect(fromMap.reviewStatus, ReportReviewStatus.uploaded);
    });
  });

  group('Phase D11 — Storage Service & File Validation Tests', () {
    test('4. StorageService rejects empty files', () {
      final storage = MockStorageService.instance;
      final res = storage.validateFile(fileName: 'test.pdf', bytes: []);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('File is empty'));
    });

    test('5. StorageService rejects oversized files (> 15 MB)', () {
      final storage = MockStorageService.instance;
      final oversizedBytes = Uint8List(16 * 1024 * 1024);
      final res = storage.validateFile(fileName: 'large.pdf', bytes: oversizedBytes);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('exceeds the 15 MB limit'));
    });

    test('6. StorageService rejects unsupported file extensions', () {
      final storage = MockStorageService.instance;
      final bytes = [1, 2, 3, 4];
      final res = storage.validateFile(fileName: 'malicious.exe', bytes: bytes);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Unsupported file format'));
    });

    test('7. StorageService validates valid PDF bytes and magic header', () {
      final storage = MockStorageService.instance;
      // %PDF header
      final pdfBytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34];
      final res = storage.validateFile(fileName: 'ecg_report.pdf', bytes: pdfBytes);
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'application/pdf');
    });

    test('8. StorageService validates PNG image bytes', () {
      final storage = MockStorageService.instance;
      // \x89PNG header
      final pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final res = storage.validateFile(fileName: 'xray.png', bytes: pngBytes);
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'image/png');
    });
  });

  group('Phase D11 — Repositories & Investigation Lifecycle Tests', () {
    test('9. MockInvestigationRepository creates, retrieves, and updates investigation requests', () async {
      final repo = MockInvestigationRepository.instance;
      repo.clearAll();

      final created = await repo.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-NEW-1',
          patientId: 'PAT-999',
          caseId: 'CASE-999',
          visitId: 'VIS-999',
          name: 'Chest X-Ray (PA View)',
          category: InvestigationCategory.radiology,
          priority: InvestigationPriority.required,
          requestedAt: DateTime.now(),
        ),
      );

      expect(created.requestId, 'INV-NEW-1');
      expect(created.status, InvestigationStatus.pendingUpload);

      final list = await repo.getInvestigationRequests(
        patientId: 'PAT-999',
        caseId: 'CASE-999',
        visitId: 'VIS-999',
      );
      expect(list.length, 1);
      expect(list.first.name, 'Chest X-Ray (PA View)');

      // Transition: Uploaded
      await repo.markUploaded(
        patientId: 'PAT-999',
        caseId: 'CASE-999',
        visitId: 'VIS-999',
        investigationId: 'INV-NEW-1',
        reportId: 'REP-NEW-1',
      );

      final uploaded = await repo.getInvestigationById(
        patientId: 'PAT-999',
        caseId: 'CASE-999',
        visitId: 'VIS-999',
        investigationId: 'INV-NEW-1',
      );
      expect(uploaded?.status, InvestigationStatus.uploaded);
      expect(uploaded?.uploadedReportId, 'REP-NEW-1');

      // Transition: Reviewed
      await repo.markReviewed(
        patientId: 'PAT-999',
        caseId: 'CASE-999',
        visitId: 'VIS-999',
        investigationId: 'INV-NEW-1',
        doctorId: 'DOC-101',
      );

      final reviewed = await repo.getInvestigationById(
        patientId: 'PAT-999',
        caseId: 'CASE-999',
        visitId: 'VIS-999',
        investigationId: 'INV-NEW-1',
      );
      expect(reviewed?.status, InvestigationStatus.reviewed);
      expect(reviewed?.reviewedByDoctorId, 'DOC-101');
    });

    test('10. MockReportRepository saves and updates report review status', () async {
      final repo = MockReportRepository.instance;
      repo.clearAll();

      final report = ReportDocument(
        reportId: 'REP-TEST-1',
        patientId: 'PAT-888',
        caseId: 'CASE-888',
        visitId: 'VIS-888',
        investigationId: 'INV-888',
        fileName: 'lipid_profile.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 54321,
        storagePath: 'patients/PAT-888/cases/CASE-888/visits/VIS-888/reports/INV-888/lipid_profile.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: 'PAT-888',
        reviewStatus: ReportReviewStatus.uploaded,
      );

      final saved = await repo.saveReportDocument(report);
      expect(saved.reportId, 'REP-TEST-1');

      final list = await repo.getReportsForVisit(
        patientId: 'PAT-888',
        caseId: 'CASE-888',
        visitId: 'VIS-888',
      );
      expect(list.length, 1);

      await repo.updateReportStatus(
        patientId: 'PAT-888',
        caseId: 'CASE-888',
        visitId: 'VIS-888',
        reportId: 'REP-TEST-1',
        status: ReportReviewStatus.reviewed,
        doctorId: 'DOC-101',
      );

      final reviewed = await repo.getReportById(
        patientId: 'PAT-888',
        caseId: 'CASE-888',
        visitId: 'VIS-888',
        reportId: 'REP-TEST-1',
      );
      expect(reviewed?.reviewStatus, ReportReviewStatus.reviewed);
      expect(reviewed?.reviewedByDoctorId, 'DOC-101');
    });
  });

  group('Phase D11 — Patient App Integration Service Tests', () {
    test('11. PatientInvestigationService fetches pending investigations', () async {
      final service = PatientInvestigationService.instance;
      final pending = await service.getPendingInvestigations(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
      );

      expect(pending.isNotEmpty, isTrue);
      expect(pending.every((i) => i.isPendingUpload), isTrue);
    });

    test('12. PatientInvestigationService uploads report linked to investigation', () async {
      final service = PatientInvestigationService.instance;
      final pdfBytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]; // valid %PDF

      final doc = await service.uploadReport(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
        investigationId: 'REQ-INV-001',
        fileName: 'ecg_patient_scan.pdf',
        fileBytes: pdfBytes,
      );

      expect(doc.investigationId, 'REQ-INV-001');
      expect(doc.patientId, 'PAT-001');
      expect(doc.reviewStatus, ReportReviewStatus.uploaded);

      // Verify that the investigation request is now marked as uploaded
      final inv = await BackendProvider.instance.investigationRepository
          .getInvestigationById(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
        investigationId: 'REQ-INV-001',
      );
      expect(inv?.status, InvestigationStatus.uploaded);
    });
  });

  group('Phase D11 — PDF Data Mapping & Gating Validation Tests', () {
    final mockPatient = Patient(
      patientId: 'PAT-001',
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
      patientId: 'PAT-001',
      domain: 'Cardiology',
      title: 'Atypical Chest Pain & Palpitations',
      status: ClinicalCaseStatus.open,
      relevantHistory: 'Hypertension for 5 years on Telmisartan.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final completeVisit = ClinicalVisit(
      visitId: 'VIS-001',
      caseId: 'CASE-001',
      patientId: 'PAT-001',
      doctorId: 'DOC-101',
      doctorName: 'Dr. Rajesh Sharma',
      doctorQualification: 'MBBS, MD (Cardiology)',
      visitNumber: 1,
      startedAt: DateTime.now(),
      status: ClinicalVisitStatus.active,
      chiefComplaint: 'Chest tightness for 3 days',
      onsetDuration: '3 days, insidious onset',
      associatedSymptoms: 'Mild breathlessness on climbing stairs',
      medicalHistory: 'Known hypertensive on treatment',
      currentMedication: 'Telmisartan 40mg OD',
      clinicalObservations: 'S1 S2 normal, no murmurs, chest clear',
      assessment: 'Likely non-cardiac chest discomfort / musculoskeletal',
      plan: '12-lead ECG, blood work, reassurance, symptomatic analgesia',
      summary: 'Patient evaluated for atypical chest discomfort. Normal vitals. Advised ECG.',
      summaryText: 'Patient evaluated for atypical chest discomfort. Normal vitals. Advised ECG.',
      summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
      approvedByDoctorId: 'DOC-101',
      approvedAt: DateTime.now(),
      followUp: 'Review in 2 weeks with ECG report',
      patientInstructions: 'Take medications on time. Avoid heavy lifting.',
      prescriptions: const [
        PrescriptionItem(
          medicineName: 'Paracetamol 650mg',
          duration: '5 days',
          timesPerDay: '1-0-1',
          remarks: 'After food',
        ),
      ],
      investigationRequests: [
        InvestigationRequest(
          requestId: 'INV-1',
          name: '12-Lead ECG',
          category: InvestigationCategory.diagnostic,
          priority: InvestigationPriority.required,
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime.now(),
        ),
      ],
    );

    test('13. VisitReportData maps all 9 official sections correctly', () {
      final data = VisitReportData.fromComponents(
        patient: mockPatient,
        clinicalCase: mockCase,
        visit: completeVisit,
        vitals: VitalReading(
          vitalId: 'VIT-1',
          patientId: 'PAT-001',
          heartRate: 72,
          spo2: 98,
          temperature: 36.8,
          timestamp: DateTime.now(),
        ),
      );

      // Section 1: Visit Identification
      expect(data.patientId, 'PAT-001');
      expect(data.caseId, 'CASE-001');
      expect(data.visitNumber, 1);
      expect(data.department, 'Cardiology');

      // Section 2: Patient Info
      expect(data.patientName, 'Aarav Sharma');
      expect(data.age, 36);
      expect(data.gender, 'Male');
      expect(data.bloodGroup, 'B+');

      // Section 3: Vitals
      expect(data.spo2, '98%');
      expect(data.heartRate, '72 bpm');
      expect(data.temperature, '36.8 °C');

      // Section 4: Case Info
      expect(data.caseTitle, 'Atypical Chest Pain & Palpitations');
      expect(data.previousRelevantHistory, 'Hypertension for 5 years on Telmisartan.');

      // Section 5: Structured Consultation
      expect(data.chiefComplaint, 'Chest tightness for 3 days');
      expect(data.assessment, 'Likely non-cardiac chest discomfort / musculoskeletal');

      // Section 6: Approved Summary
      expect(data.isSummaryApproved, isTrue);
      expect(data.summaryStatus, 'APPROVED BY DOCTOR');

      // Section 7: Investigations
      expect(data.investigations.length, 1);
      expect(data.investigations.first.name, '12-Lead ECG');

      // Section 8: Follow-up
      expect(data.followUp, 'Review in 2 weeks with ECG report');

      // Section 9: Completion
      expect(data.consultingDoctor, 'Dr. Rajesh Sharma');
      expect(data.completionCaseId, 'CASE-001');
    });

    test('14. Missing required consultation fields blocks PDF generation', () {
      final incompleteVisit = completeVisit.copyWith(chiefComplaint: '');
      final data = VisitReportData.fromComponents(
        patient: mockPatient,
        clinicalCase: mockCase,
        visit: incompleteVisit,
      );

      expect(data.canGenerateReport, isFalse);
      expect(data.missingRequirements, contains('Chief Complaint'));
    });

    test('15. Unapproved summary blocks PDF generation', () {
      final unapprovedVisit = completeVisit.copyWith(
        summaryApprovalStatus: SummaryApprovalStatus.reviewRequired,
      );
      final data = VisitReportData.fromComponents(
        patient: mockPatient,
        clinicalCase: mockCase,
        visit: unapprovedVisit,
      );

      expect(data.canGenerateReport, isFalse);
      expect(data.missingRequirements, contains('Doctor Summary Approval (Must be APPROVED BY DOCTOR)'));
    });

    test('16. Fully approved visit allows PDF generation and produces valid bytes', () async {
      final data = VisitReportData.fromComponents(
        patient: mockPatient,
        clinicalCase: mockCase,
        visit: completeVisit,
      );

      expect(data.canGenerateReport, isTrue);
      expect(data.missingRequirements, isEmpty);

      final pdfBytes = await VisitReportPdfService.instance.generateVisitPdf(data);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF begins with %PDF (0x25, 0x50, 0x44, 0x46)
      expect(pdfBytes[0], 0x25);
      expect(pdfBytes[1], 0x50);
      expect(pdfBytes[2], 0x44);
      expect(pdfBytes[3], 0x46);
    });
  });

  group('Phase D11 — UI Widgets & Dialogs Tests', () {
    testWidgets('17. DoctorRequestInvestigationDialog collects category & priority and confirms',
        (tester) async {
      String? submittedName;
      InvestigationCategory? submittedCategory;
      InvestigationPriority? submittedPriority;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (_) => DoctorRequestInvestigationDialog(
                      onConfirm: (name, category, priority) {
                        submittedName = name;
                        submittedCategory = category;
                        submittedPriority = priority;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('REQUEST DIAGNOSTIC INVESTIGATION'), findsOneWidget);

      // Enter name
      await tester.enterText(find.byType(TextField), '2D Echocardiography');
      await tester.pump();

      // Tap 'As Advised' priority
      await tester.tap(find.text('As Advised'));
      await tester.pump();

      // Tap Request Investigation
      await tester.tap(find.text('+ REQUEST INVESTIGATION'));
      await tester.pumpAndSettle();

      expect(submittedName, '2D Echocardiography');
      expect(submittedCategory, InvestigationCategory.diagnostic);
      expect(submittedPriority, InvestigationPriority.asAdvised);
    });

    testWidgets('18. DoctorReportsReviewWidget renders tabs and triggers mark reviewed',
        (tester) async {
      final reqs = [
        InvestigationRequest(
          requestId: 'INV-1',
          name: '12-Lead ECG',
          category: InvestigationCategory.diagnostic,
          priority: InvestigationPriority.required,
          status: InvestigationStatus.uploaded,
          requestedAt: DateTime.now(),
        ),
      ];
      final reps = [
        ReportDocument(
          reportId: 'REP-1',
          patientId: 'PAT-001',
          caseId: 'CASE-001',
          visitId: 'VIS-001',
          investigationId: 'INV-1',
          fileName: 'ecg_trace.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: 102400,
          storagePath: 'path/to/ecg_trace.pdf',
          uploadedAt: DateTime.now(),
          uploadedByPatientId: 'PAT-001',
          reviewStatus: ReportReviewStatus.uploaded,
        ),
      ];

      bool markReviewedTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorReportsReviewWidget(
              investigations: reqs,
              reports: reps,
              onMarkReviewed: (inv, rep) {
                markReviewedTriggered = true;
              },
              onRequestInvestigation: () {},
            ),
          ),
        ),
      );

      expect(find.text('DOCTOR REPORTS & DIAGNOSTICS'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Uploaded (Pending Review)'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);

      // Switch to Uploaded Tab
      await tester.tap(find.text('Uploaded (Pending Review)'));
      await tester.pumpAndSettle();

      expect(find.text('12-Lead ECG'), findsOneWidget);
      expect(find.text('MARK AS REVIEWED'), findsOneWidget);

      await tester.tap(find.text('MARK AS REVIEWED'));
      await tester.pump();

      expect(markReviewedTriggered, isTrue);
    });

    testWidgets('19. DoctorVisitReportPreviewDialog displays draft preview and gating state',
        (tester) async {
      final mockPatient = Patient(
        patientId: 'PAT-001',
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
        patientId: 'PAT-001',
        domain: 'Cardiology',
        title: 'Cardiac Evaluation',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final unapprovedVisit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        chiefComplaint: 'Chest tightness',
        onsetDuration: '3 days',
        associatedSymptoms: 'None',
        medicalHistory: 'None',
        currentMedication: 'None',
        clinicalObservations: 'Normal',
        assessment: 'Musculoskeletal',
        plan: 'Rest and follow-up',
        summary: 'Consultation completed.',
        summaryApprovalStatus: SummaryApprovalStatus.reviewRequired,
      );

      final data = VisitReportData.fromComponents(
        patient: mockPatient,
        clinicalCase: mockCase,
        visit: unapprovedVisit,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorVisitReportPreviewDialog(
              data: data,
              onGeneratePdf: () {},
            ),
          ),
        ),
      );

      expect(find.text('AAYUSATHI'), findsOneWidget);
      expect(find.text('CASE & VISIT DOCUMENTATION — DRAFT PREVIEW'), findsOneWidget);
      expect(find.text('SECTION 1 — VISIT IDENTIFICATION'), findsOneWidget);
      expect(find.text('SECTION 2 — PATIENT INFORMATION'), findsOneWidget);

      // Gating warning is present
      expect(
        find.text(
            'Complete all required consultation fields and approve the visit summary before generating the report.'),
        findsOneWidget,
      );
    });

    testWidgets('20. PatientReportsCard displays report status and handles upload trigger',
        (tester) async {
      bool uploadTapped = false;
      final inv = InvestigationRequest(
        requestId: 'REQ-1',
        name: 'Thyroid Function Test (TFT)',
        category: InvestigationCategory.lab,
        priority: InvestigationPriority.asAdvised,
        status: InvestigationStatus.pendingUpload,
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientReportsCard(
              investigation: inv,
              onUploadPressed: () {
                uploadTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Thyroid Function Test (TFT)'), findsOneWidget);
      expect(find.text('Pending Upload'), findsOneWidget);
      expect(find.text('UPLOAD REPORT'), findsOneWidget);

      await tester.tap(find.text('UPLOAD REPORT'));
      await tester.pump();

      expect(uploadTapped, isTrue);
    });
  });

  group('Phase D11 — Localization & Multi-Language Tests', () {
    test('21. Localized strings across English, Hindi, and Marathi', () {
      final en = DoctorLocalizations.forLocale(KioskLocale.english);
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      // Investigation categories
      expect(en.labCategory, 'Lab');
      expect(hi.labCategory, 'प्रयोगशाला');
      expect(mr.labCategory, 'प्रयोगशाळा');

      // Priorities
      expect(en.requiredPriority, 'Required');
      expect(hi.requiredPriority, 'आवश्यक');
      expect(mr.requiredPriority, 'आवश्यक');

      // Actions
      expect(en.markAsReviewedButton, 'MARK AS REVIEWED');
      expect(hi.markAsReviewedButton, 'समीक्षित चिह्नित करें');
      expect(mr.markAsReviewedButton, 'तपासले म्हणून चिन्हांकित करा');

      // PDF
      expect(en.generatePdfButton, 'GENERATE VISIT PDF');
      expect(hi.generatePdfButton, 'विज़िट PDF बनाएं');
      expect(mr.generatePdfButton, 'भेट PDF तयार करा');
    });
  });

  group('Phase D11 — Responsive Viewport Tests', () {
    testWidgets('22. Renders DoctorReportsReviewWidget at 1366x768 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorReportsReviewWidget(
              investigations: const [],
              reports: const [],
              onMarkReviewed: (_, _) {},
              onRequestInvestigation: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('23. Renders DoctorReportsReviewWidget at 1920x1080 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorReportsReviewWidget(
              investigations: const [],
              reports: const [],
              onMarkReviewed: (_, _) {},
              onRequestInvestigation: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
