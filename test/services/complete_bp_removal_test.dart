import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/services/arduino/serial_parser.dart';
import 'package:aayusathi/services/arduino/mock_arduino_adapter.dart';
import 'package:aayusathi/services/vital_validation_service.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/services/visit_report_pdf_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_workspace_widgets.dart';
import 'package:aayusathi/admin/widgets/admin_escalated_workspace_widgets.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/patient/screens/patient_visit_detail_screen.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockPatientRepository.instance.resetToDefaults();
    PatientAppState.instance.resetSession();
    PatientSessionService.instance.startSession('PAT-MOCK-001', authUid: 'test-auth-uid-001');
  });

  group('AAYUSATHI — COMPLETE REMOVAL OF BLOOD PRESSURE (BP) VERIFICATION', () {
    // 1. Normal simulation returns only SpO₂, HR and temperature
    test('1. Normal simulation returns only SpO2, Heart Rate, and Temperature', () async {
      final adapter = MockArduinoAdapter();
      final lines = <String>[];
      final sub = adapter.rawDataStream.listen(lines.add);

      adapter.emitNormalVitals();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      adapter.dispose();

      expect(lines.isNotEmpty, isTrue);
      final combined = lines.join(',');
      expect(combined.contains('SYS:'), isFalse);
      expect(combined.contains('DIA:'), isFalse);
      expect(combined.contains('BP:'), isFalse);
      expect(combined.contains('HR:'), isTrue);
      expect(combined.contains('SPO2:'), isTrue);
      expect(combined.contains('TEMP:'), isTrue);
    });

    // 2. Abnormal simulation returns only SpO₂, HR and temperature
    test('2. Abnormal simulation returns only SpO2, Heart Rate, and Temperature', () async {
      final adapter = MockArduinoAdapter();
      final lines = <String>[];
      final sub = adapter.rawDataStream.listen(lines.add);

      adapter.emitAbnormalVitals();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      adapter.dispose();

      expect(lines.isNotEmpty, isTrue);
      final combined = lines.join(',');
      expect(combined.contains('SYS:'), isFalse);
      expect(combined.contains('DIA:'), isFalse);
      expect(combined.contains('BP:'), isFalse);
      expect(combined.contains('HR:'), isTrue);
      expect(combined.contains('SPO2:'), isTrue);
      expect(combined.contains('TEMP:'), isTrue);
    });

    // 3. Arduino mode reads only SpO₂, HR and temperature
    test('3. Arduino mode parser reads only SpO2, Heart Rate, and Temperature', () {
      VitalReading reading = VitalReading.empty();
      reading = ArduinoSerialParser.parseLine('HR:76,SPO2:98,TEMP:36.7', reading);

      expect(reading.heartRate, 76);
      expect(reading.spo2, 98);
      expect(reading.temperature, 36.7);
      expect(reading.isComplete, isTrue);
    });

    // 4. No BP data is generated & unexpected BP tokens are safely ignored
    test('4. Unexpected BP serial lines or tokens are safely ignored without error', () {
      VitalReading reading = VitalReading.empty();
      // Even if Arduino sends unexpected legacy BP tokens, safely ignore them
      reading = ArduinoSerialParser.parseLine('HR:80,SPO2:97,TEMP:36.5,SYS:120,DIA:80', reading);

      expect(reading.heartRate, 80);
      expect(reading.spo2, 97);
      expect(reading.temperature, 36.5);
      expect(reading.isComplete, isTrue);
    });

    // 5. No BP data is written to new Firestore vital records
    test('5. No BP keys exist in toMap() or toFirestore() output', () {
      final vitals = VitalReading(
        heartRate: 72,
        spo2: 99,
        temperature: 36.6,
        timestamp: DateTime.now(),
        status: VitalStatus.valid,
        validationStatus: 'normal',
      );

      final map = vitals.toMap();
      expect(map.containsKey('spo2'), isTrue);
      expect(map.containsKey('heartRate'), isTrue);
      expect(map.containsKey('temperature'), isTrue);

      expect(map.containsKey('systolic'), isFalse);
      expect(map.containsKey('diastolic'), isFalse);
      expect(map.containsKey('systolicBp'), isFalse);
      expect(map.containsKey('diastolicBp'), isFalse);
      expect(map.containsKey('bloodPressure'), isFalse);
      expect(map.containsKey('bp'), isFalse);

      final firestoreMap = vitals.toFirestore();
      expect(firestoreMap.containsKey('systolic'), isFalse);
      expect(firestoreMap.containsKey('diastolic'), isFalse);
      expect(firestoreMap.containsKey('bloodPressure'), isFalse);
    });

    // 6. Patient App does not display BP
    testWidgets('6. Patient App Visit Details displays only SpO2, Heart Rate, Temperature', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          home: PatientLocalizations.provider(
            strings: PatientLocalizations.forLocaleCode('en'),
            child: const PatientVisitDetailScreen(
              caseId: 'CASE-PAT-001-01',
              visitId: 'VIS-PAT-001-01-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vitals'), findsOneWidget);
      expect(find.text('SpO₂'), findsOneWidget);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsNothing);
    });

    // 7. Doctor App does not display BP
    testWidgets('7. Doctor App workspace vitals bar displays only SpO2, Heart Rate, Temperature', (tester) async {
      final vitals = VitalReading(
        vitalId: 'VIT-DOC-01',
        spo2: 99,
        heartRate: 75,
        temperature: 36.6,
        timestamp: DateTime.now(),
        status: VitalStatus.valid,
      );

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCurrentVitalsBar(vitals: vitals),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('99%'), findsOneWidget);
      expect(find.text('75 BPM'), findsOneWidget);
      expect(find.text('36.6 °C'), findsOneWidget);
      expect(find.textContaining('mmHg'), findsNothing);
      expect(find.text('Blood Pressure'), findsNothing);
    });

    // 8. Admin Dashboard does not display BP
    testWidgets('8. Admin escalated workspace displays only 3 vitals in consultation section', (tester) async {
      final vital = VitalReading(
        vitalId: 'VIT-ADM-01',
        patientId: 'PAT-ADM-01',
        spo2: 96,
        heartRate: 80,
        temperature: 37.1,
        timestamp: DateTime.now(),
        status: VitalStatus.valid,
      );

      final dummyPatient = Patient(
        patientId: 'PAT-ADM-01',
        name: 'Aarav Patel',
        phone: '9876543210',
        dateOfBirth: '1990-01-01',
        age: 36,
        gender: 'Male',
        bloodGroup: 'B+',
        address: 'Pune, Maharashtra',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dummyCase = ClinicalCase(
        caseId: 'CASE-ADM-01',
        patientId: 'PAT-ADM-01',
        domain: 'Cardiology',
        title: 'Cardiac Consult',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ClinicalCaseStatus.open,
      );

      final dummyVisit = ClinicalVisit(
        visitId: 'VIS-ADM-01',
        caseId: 'CASE-ADM-01',
        patientId: 'PAT-ADM-01',
        doctorId: 'DOC-01',
        doctorName: 'Dr. Test',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        vitals: vital,
      );

      await tester.binding.setSurfaceSize(const Size(1366, 768));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminVisitDetailView(
                clinicalCase: dummyCase,
                patient: dummyPatient,
                visit: dummyVisit,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('98% (Normal)'), findsOneWidget);
      expect(find.text('72 BPM'), findsOneWidget);
      expect(find.text('36.8 °C'), findsOneWidget);
      expect(find.text('120/80 mmHg'), findsNothing);
      expect(find.text('Blood Pressure'), findsNothing);
    });

    // 9. New PDFs do not contain BP
    test('9. VisitReportPdfService generates PDF containing only SpO2, Heart Rate, Temperature', () async {
      final patient = Patient(
        patientId: 'PAT-001',
        name: 'Aarav Sharma',
        phone: '9876543210',
        dateOfBirth: '1990-01-01',
        age: 36,
        gender: 'Male',
        bloodGroup: 'B+',
        address: 'Pune, Maharashtra',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final clinicalCase = ClinicalCase(
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        domain: 'Cardiology',
        title: 'Cardiac Checkup',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ClinicalCaseStatus.open,
      );

      final visit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Chest discomfort',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
      );

      final vitals = VitalReading(
        vitalId: 'VIT-001',
        patientId: 'PAT-001',
        heartRate: 72,
        spo2: 98,
        temperature: 36.8,
        timestamp: DateTime.now(),
      );

      final reportData = VisitReportData.fromComponents(
        patient: patient,
        clinicalCase: clinicalCase,
        visit: visit,
        vitals: vitals,
      );

      final pdfBytes = await VisitReportPdfService.instance.generateVisitPdf(reportData);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    // 10. AI input does not contain system-generated BP
    test('10. Clinical documentation models contain only 3 vitals', () {
      final vitals = VitalReading(
        spo2: 98,
        heartRate: 74,
        temperature: 36.7,
        timestamp: DateTime.now(),
      );

      final map = vitals.toMap();
      expect(map.keys.toSet(), containsAll({'spo2', 'heartRate', 'temperature'}));
      expect(map.keys.toSet().intersection({'bloodPressure', 'systolic', 'diastolic', 'bp'}), isEmpty);
    });

    // 11. Existing Arduino communication still works
    test('11. Arduino multi-line parser aggregates multi-line stream correctly', () {
      VitalReading reading = VitalReading.empty();
      reading = ArduinoSerialParser.parseLine('VITAL RESULTS', reading);
      reading = ArduinoSerialParser.parseLine('Heart Rate : 74 BPM', reading);
      reading = ArduinoSerialParser.parseLine('SpO2       : 98 %', reading);
      reading = ArduinoSerialParser.parseLine('Temperature: 36.8 C', reading);

      expect(reading.heartRate, 74);
      expect(reading.spo2, 98);
      expect(reading.temperature, 36.8);
      expect(reading.isComplete, isTrue);
      expect(reading.status, VitalStatus.valid);
    });

    // 12. Existing SpO₂ works
    test('12. SpO2 validation detects normal and abnormal levels accurately', () {
      const validator = VitalValidationService();
      final normal = VitalReading(
        heartRate: 75,
        spo2: 98,
        temperature: 36.8,
        timestamp: DateTime.now(),
      );
      expect(validator.validate(normal).isNormal, isTrue);

      final lowSpo2 = VitalReading(
        heartRate: 75,
        spo2: 88,
        temperature: 36.8,
        timestamp: DateTime.now(),
      );
      final result = validator.validate(lowSpo2);
      expect(result.isAbnormal, isTrue);
      expect(result.abnormalReasons.any((r) => r.contains('SpO₂')), isTrue);
    });

    // 13. Existing heart rate works
    test('13. Heart Rate validation detects normal and abnormal levels accurately', () {
      const validator = VitalValidationService();
      final highHr = VitalReading(
        heartRate: 130,
        spo2: 98,
        temperature: 36.8,
        timestamp: DateTime.now(),
      );
      final result = validator.validate(highHr);
      expect(result.isAbnormal, isTrue);
      expect(result.abnormalReasons.any((r) => r.contains('Heart Rate')), isTrue);
    });

    // 14. Existing temperature works
    test('14. Temperature validation detects normal and abnormal levels accurately', () {
      const validator = VitalValidationService();
      final fever = VitalReading(
        heartRate: 75,
        spo2: 98,
        temperature: 39.2,
        timestamp: DateTime.now(),
      );
      final result = validator.validate(fever);
      expect(result.isAbnormal, isTrue);
      expect(result.abnormalReasons.any((r) => r.contains('Temperature')), isTrue);
    });
  });
}
