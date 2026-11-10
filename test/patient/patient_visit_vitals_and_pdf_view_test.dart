import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/screens/patient_visit_detail_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_visit_report_pdf_viewer.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';
import 'package:aayusathi/repositories/mock/mock_vital_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService mockStorage;
  late MockReportRepository mockReportRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockCaseRepository mockCaseRepo;
  late MockVitalRepository mockVitalRepo;
  late MockPatientRepository mockPatientRepo;
  final sessionService = PatientSessionService.instance;

  final sampleVitals = VitalReading(
    vitalId: 'VIT-001',
    patientId: 'PAT-P9-001',
    timestamp: DateTime(2026, 9, 10, 10, 0),
    spo2: 98,
    heartRate: 72,
    temperature: 98.6,
  );

  final samplePatient = Patient(
    patientId: 'PAT-P9-001',
    name: 'Sunita Sharma',
    phone: '9876543210',
    dateOfBirth: '1978-05-20',
    age: 48,
    gender: 'Female',
    bloodGroup: 'B+',
    address: 'Pune, Maharashtra',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final sampleCase = ClinicalCase(
    caseId: 'CASE-P9-001',
    patientId: 'PAT-P9-001',
    title: 'Hypertension Management',
    domain: 'Cardiology',
    status: ClinicalCaseStatus.open,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 10),
  );

  final sampleVisitWithVitals = ClinicalVisit(
    visitId: 'VIS-P9-001',
    caseId: 'CASE-P9-001',
    patientId: 'PAT-P9-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD (Cardiology)',
    visitNumber: 1,
    startedAt: DateTime(2026, 9, 10, 10, 0),
    completedAt: DateTime(2026, 9, 10, 10, 30),
    status: ClinicalVisitStatus.completed,
    chiefComplaint: 'Follow up for BP check',
    summary: 'Blood pressure is well controlled on current regimen.',
    summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
    approvedByDoctorId: 'DOC-101',
    approvedAt: DateTime(2026, 9, 10, 10, 30),
    vitals: sampleVitals,
  );

  final sampleVisitWithoutVitals = ClinicalVisit(
    visitId: 'VIS-P9-002',
    caseId: 'CASE-P9-001',
    patientId: 'PAT-P9-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD (Cardiology)',
    visitNumber: 2,
    startedAt: DateTime(2026, 9, 10, 11, 0),
    completedAt: DateTime(2026, 9, 10, 11, 30),
    status: ClinicalVisitStatus.completed,
    chiefComplaint: 'Follow up check',
    summary: 'Patient recovering well.',
    summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
    approvedByDoctorId: 'DOC-101',
    approvedAt: DateTime(2026, 9, 10, 11, 30),
  );

  final validPdfBytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, // %PDF-1.5
    0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A,
  ]);

  setUp(() async {
    mockStorage = MockStorageService.instance..reset();
    mockReportRepo = MockReportRepository.instance..clearAll();
    mockVisitRepo = MockClinicalVisitRepository.instance..resetToDefaults();
    mockCaseRepo = MockCaseRepository.instance..resetToDefaults();
    mockVitalRepo = MockVitalRepository.instance..reset();
    mockPatientRepo = MockPatientRepository.instance..resetToDefaults();

    BackendProvider.instance.setCustomRepositories(
      storageService: mockStorage,
      reportRepo: mockReportRepo,
      clinicalVisitRepo: mockVisitRepo,
      caseRepo: mockCaseRepo,
      vitalRepo: mockVitalRepo,
      patientRepo: mockPatientRepo,
    );

    await mockPatientRepo.savePatient(samplePatient);
    await mockCaseRepo.createCase(sampleCase);
    await mockVisitRepo.createVisit(sampleVisitWithVitals);
    await mockVisitRepo.createVisit(sampleVisitWithoutVitals);

    sessionService.startSession('PAT-P9-001', authUid: 'auth-p9-sunita');
  });

  tearDown(() {
    sessionService.logout();
    BackendProvider.instance.resetOverrides();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: PatientTheme.theme,
      home: PatientLocalizations.provider(
        strings: PatientLocalizations.forLocaleCode('en'),
        child: child,
      ),
    );
  }

  group('AAYUSATHI: Vitals & PDF Viewing in Patient App', () {
    test('1. VitalReading.fromMap parses diverse field variations (spo2, bpm, bp string, temp)', () {
      final mapWithVariants = {
        'readingId': 'VIT-VAR-1',
        'patientId': 'PAT-001',
        'oxygenSaturation': 97,
        'pulseRate': 78,
        'bp': '130/85',
        'temp': 99.1,
      };

      final parsed = VitalReading.fromMap(mapWithVariants);
      expect(parsed.spo2, 97);
      expect(parsed.heartRate, 78);
      expect(parsed.temperature, 99.1);
    });

    test('2. ClinicalVisit serialization preserves VitalReading in Firestore format and map', () {
      final visit = sampleVisitWithVitals;
      final firestoreMap = visit.toFirestore();
      expect(firestoreMap.containsKey('vitals'), isTrue);
      expect(firestoreMap['vitals']['spo2'], 98);
      expect(firestoreMap['vitals'].containsKey('systolic'), isFalse);
      expect(firestoreMap['vitals'].containsKey('diastolic'), isFalse);

      // Rehydrate
      final rehydrated = ClinicalVisit.fromFirestore(firestoreMap, visit.visitId);
      expect(rehydrated.vitals, isNotNull);
      expect(rehydrated.vitals!.spo2, 98);
      expect(rehydrated.vitals!.heartRate, 72);
      expect(rehydrated.vitals!.temperature, 98.6);
    });

    testWidgets('3. Patient Visit Details displays recorded vitals', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-P9-001',
            visitId: 'VIS-P9-001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify vitals card shows recorded values
      expect(find.text('98%'), findsOneWidget); // SpO2
      expect(find.text('120/80 mmHg'), findsNothing); // BP removed
      expect(find.text('72 bpm'), findsOneWidget); // Heart Rate
      expect(find.text('98.6 °F'), findsOneWidget); // Temperature
    });

    testWidgets('4. Patient Visit Details shows "Not recorded" gracefully when vitals are missing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-P9-001',
            visitId: 'VIS-P9-002',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vitals should show "Not recorded" for all 3 vitals
      expect(find.text('Not recorded'), findsNWidgets(3));
    });

    testWidgets('5. Official Visit Report PDF card displays "not available yet" when report is pending', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-P9-001',
            visitId: 'VIS-P9-001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Official Visit Report'), findsOneWidget);
      expect(find.text('Visit report PDF is not available yet.'), findsOneWidget);
      expect(
        find.text("Your doctor's signed consultation report will appear here once finalized."),
        findsOneWidget,
      );
      expect(find.byKey(const Key('patient_view_visit_report_pdf_button')), findsNothing);
    });

    testWidgets('6. Official Visit Report PDF card displays button and opens in-app viewer with 5-minute signed URL', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      // 1. Upload mock official PDF to mock storage
      const storagePath =
          'patients/PAT-P9-001/cases/CASE-P9-001/visits/VIS-P9-001/reports/Visit_Report_VIS-P9-001.pdf';
      await mockStorage.uploadVisitPdf(
        patientId: 'PAT-P9-001',
        caseId: 'CASE-P9-001',
        visitId: 'VIS-P9-001',
        fileName: 'Visit_Report_VIS-P9-001.pdf',
        bytes: validPdfBytes,
      );

      // 2. Register ReportDocument in Firestore
      final officialDoc = ReportDocument(
        reportId: 'OFFICIAL-REPORT-VIS-P9-001',
        patientId: 'PAT-P9-001',
        caseId: 'CASE-P9-001',
        visitId: 'VIS-P9-001',
        investigationId: 'OFFICIAL_VISIT_REPORT',
        fileName: 'Visit_Report_VIS-P9-001.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: validPdfBytes.length,
        storagePath: storagePath,
        storageProvider: 'supabase',
        storageBucket: 'aayusathi-reports',
        uploadedAt: DateTime(2026, 9, 10, 10, 35),
        uploadedByPatientId: 'DOC-101',
        reviewStatus: ReportReviewStatus.reviewed,
      );
      await mockReportRepo.saveReportDocument(officialDoc);

      // 3. Render Patient Visit Detail Screen
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-P9-001',
            visitId: 'VIS-P9-001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify official report card is available
      expect(find.text('Official Visit Report'), findsOneWidget);
      expect(find.text('OFFICIAL'), findsOneWidget);
      expect(find.byKey(const Key('patient_view_visit_report_pdf_button')), findsOneWidget);
      expect(find.text('View Visit Report PDF'), findsOneWidget);

      // 4. Tap "View Visit Report PDF"
      await tester.tap(find.byKey(const Key('patient_view_visit_report_pdf_button')));
      await tester.pump(); // Start opening dialog
      await tester.pumpAndSettle();

      // 5. Verify In-App PDF Preview Viewer Dialog opened
      expect(find.byType(PatientVisitReportPdfViewerDialog), findsOneWidget);
      expect(find.text('Visit Report PDF'), findsOneWidget);
      expect(find.text('Visit_Report_VIS-P9-001.pdf'), findsOneWidget);
    });
  });
}
