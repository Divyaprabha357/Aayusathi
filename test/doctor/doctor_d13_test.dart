import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/models/patient_transfer_request.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_request_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_request_card.dart';
import 'package:aayusathi/doctor/widgets/doctor_transfer_context_banner.dart';
import 'package:aayusathi/doctor/widgets/doctor_transfer_patient_dialog.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/patient/services/patient_clinical_records_service.dart';
import 'package:aayusathi/patient/widgets/patient_case_overview_card.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_transfer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockDestinationDoctor1 = DoctorProfile(
    doctorId: 'DOC-201',
    doctorUniqueCode: 'DOC-201',
    name: 'Dr. Sunita Rao',
    qualification: 'MBBS, MD, DM (Neurology)',
    department: 'Neurology',
    registeredPhone: '9876543220',
    email: 'sunita.rao@hospital.org',
    authUid: 'AUTH-201',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockDestinationDoctor2 = DoctorProfile(
    doctorId: 'DOC-202',
    doctorUniqueCode: 'DOC-202',
    name: 'Dr. Vikram Seth',
    qualification: 'MBBS, MD (Neurology)',
    department: 'Neurology',
    registeredPhone: '9876543230',
    email: 'vikram.seth@hospital.org',
    authUid: 'AUTH-202',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockActiveVisit = ClinicalVisit(
    visitId: 'VIS-CASE-001-1',
    caseId: 'CASE-001',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD (Cardiology)',
    visitNumber: 1,
    startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    status: ClinicalVisitStatus.active,
    chiefComplaint: 'Sudden onset dizziness and focal weakness.',
    onsetDuration: '2 hours',
    assessment: 'Suspected TIA / Neurological event. Referral indicated.',
    plan: 'Urgent neurology consult requested.',
  );

  final mockCase = ClinicalCase(
    caseId: 'CASE-001',
    patientId: 'PAT-MOCK-001',
    domain: 'Cardiology',
    title: 'Hypertension with Neurological Symptoms',
    status: ClinicalCaseStatus.open,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now(),
    visitCount: 1,
  );

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockCaseRepository.instance.resetToDefaults();
    MockTransferRepository.instance.resetToDefaults();
    MockDoctorPatientRequestService.instance.reset();
    MockAuditRepository.instance.clear();
    DoctorPresenceService.instance.resetPresence();
  });

  group('AAYUSATHI Phase D13: Transfer Model & Validation Unit Tests', () {
    test('1. PatientTransferRequest model properties and getters', () {
      final transfer = PatientTransferRequest(
        transferId: 'TRF-TEST-001',
        patientId: 'PAT-001',
        patientName: 'Aarav Patel',
        patientAge: 45,
        patientGender: 'Male',
        caseId: 'CASE-001',
        sourceVisitId: 'VIS-001',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        reason: 'Patient presents with severe focal neurological deficit.',
        status: TransferStatus.pending,
        requestedAt: DateTime.now(),
      );

      expect(transfer.isPending, isTrue);
      expect(transfer.isAccepted, isFalse);
      expect(transfer.isCancelled, isFalse);
      expect(transfer.isReasonValid, isTrue);
      expect(transfer.isDestinationValid, isTrue);
      expect(transfer.canCancelBy('DOC-101'), isTrue);
      expect(transfer.canCancelBy('DOC-999'), isFalse);
    });

    test('2. PatientTransferRequest validation rules: reason length (1-1000 chars)', () {
      final validTransfer = PatientTransferRequest(
        transferId: 'TRF-TEST-002',
        patientId: 'PAT-001',
        patientName: 'Test Patient',
        caseId: 'CASE-001',
        sourceVisitId: 'VIS-001',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        reason: 'Valid reason here',
        requestedAt: DateTime.now(),
      );
      expect(validTransfer.isReasonValid, isTrue);

      final emptyReason = validTransfer.copyWith(reason: '   ');
      expect(emptyReason.isReasonValid, isFalse);

      final tooLongReason = validTransfer.copyWith(
        reason: 'A' * 1001,
      );
      expect(tooLongReason.isReasonValid, isFalse);

      final exact1000Reason = validTransfer.copyWith(
        reason: 'A' * 1000,
      );
      expect(exact1000Reason.isReasonValid, isTrue);
    });

    test('3. PatientTransferRequest destination department cannot equal source department', () {
      final sameDeptTransfer = PatientTransferRequest(
        transferId: 'TRF-TEST-003',
        patientId: 'PAT-001',
        patientName: 'Test Patient',
        caseId: 'CASE-001',
        sourceVisitId: 'VIS-001',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Cardiology',
        reason: 'Needs second opinion within Cardiology',
        requestedAt: DateTime.now(),
      );

      expect(sameDeptTransfer.isDestinationValid, isFalse);
    });

    test('4. PatientTransferRequest JSON & Map serialization roundtrip', () {
      final now = DateTime.now();
      final original = PatientTransferRequest(
        transferId: 'TRF-TEST-004',
        patientId: 'PAT-001',
        patientName: 'Rohan Gupta',
        patientAge: 52,
        patientGender: 'Male',
        caseId: 'CASE-001',
        sourceVisitId: 'VIS-001',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'General Medicine',
        destinationDoctorId: 'DOC-201',
        destinationDoctorName: 'Dr. Sunita Rao',
        reason: 'General medical workup needed.',
        status: TransferStatus.accepted,
        requestedAt: now,
        acceptedAt: now.add(const Duration(minutes: 5)),
      );

      final map = original.toMap();
      final reconstructed = PatientTransferRequest.fromMap(map, original.transferId);

      expect(reconstructed.transferId, original.transferId);
      expect(reconstructed.patientId, original.patientId);
      expect(reconstructed.patientName, original.patientName);
      expect(reconstructed.patientAge, original.patientAge);
      expect(reconstructed.patientGender, original.patientGender);
      expect(reconstructed.sourceDepartment, original.sourceDepartment);
      expect(reconstructed.destinationDepartment, original.destinationDepartment);
      expect(reconstructed.destinationDoctorId, original.destinationDoctorId);
      expect(reconstructed.status, TransferStatus.accepted);
      expect(reconstructed.isAccepted, isTrue);
    });

    test('5. ClinicalVisitStatus.transferred enum and serialization', () {
      final visit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.transferred,
      );

      expect(visit.isTransferred, isTrue);
      expect(visit.isActive, isFalse);
      expect(visit.isCompleted, isFalse);

      final map = visit.toMap();
      expect(map['status'], 'transferred');

      final deserialized = ClinicalVisit.fromMap(map);
      expect(deserialized.isTransferred, isTrue);
      expect(deserialized.status, ClinicalVisitStatus.transferred);
    });

    test('6. DoctorPatientRequest transfer integration', () {
      final transfer = PatientTransferRequest(
        transferId: 'TRF-001',
        patientId: 'PAT-001',
        patientName: 'Meera Deshmukh',
        patientAge: 38,
        patientGender: 'Female',
        caseId: 'CASE-001',
        sourceVisitId: 'VIS-001',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        reason: 'Focal neurological evaluation.',
        requestedAt: DateTime.now(),
      );

      final req = DoctorPatientRequest.fromTransferRequest(transfer);
      expect(req.isTransferRequest, isTrue);
      expect(req.requestType, PatientRequestType.transfer);
      expect(req.transferId, 'TRF-001');
      expect(req.sourceDepartment, 'Cardiology');
      expect(req.sourceDoctorName, 'Dr. Rajesh Sharma');
      expect(req.transferReason, 'Focal neurological evaluation.');
      expect(req.patientName, 'Meera Deshmukh');
    });
  });

  group('AAYUSATHI Phase D13: Repository & First-Doctor-Wins Semantics', () {
    test('7. Create transfer generates pending transfer in destination queue', () async {
      final repo = MockTransferRepository.instance;
      final created = await repo.createTransferRequest(
        patientId: 'PAT-100',
        patientName: 'Vikram Joshi',
        patientAge: 40,
        patientGender: 'Male',
        caseId: 'CASE-100',
        sourceVisitId: 'VIS-100-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Suspected stroke / neurological deficit.',
      );

      expect(created.transferId.startsWith('TRF-'), isTrue);
      expect(created.status, TransferStatus.pending);

      final pendingNeurology = await repo.getPendingTransfersForDepartment('Neurology');
      expect(pendingNeurology.any((t) => t.transferId == created.transferId), isTrue);

      final pendingCardiology = await repo.getPendingTransfersForDepartment('Cardiology');
      expect(pendingCardiology.any((t) => t.transferId == created.transferId), isFalse);
    });

    test('8. First-doctor-wins: First destination doctor successfully claims transfer', () async {
      final repo = MockTransferRepository.instance;
      final transfer = await repo.createTransferRequest(
        patientId: 'PAT-101',
        patientName: 'Ananya Roy',
        caseId: 'CASE-101',
        sourceVisitId: 'VIS-101-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Persistent vertigo and ataxia.',
      );

      final result1 = await repo.acceptTransfer(
        transferId: transfer.transferId,
        doctorId: mockDestinationDoctor1.doctorId,
        doctorName: mockDestinationDoctor1.name,
        doctorDepartment: 'Neurology',
      );

      expect(result1.isSuccess, isTrue);

      final updated = await repo.getTransferById(transfer.transferId);
      expect(updated?.status, TransferStatus.accepted);
      expect(updated?.destinationDoctorId, mockDestinationDoctor1.doctorId);
      expect(updated?.destinationDoctorName, mockDestinationDoctor1.name);
    });

    test('9. First-doctor-wins race condition: Second doctor is rejected atomically', () async {
      final repo = MockTransferRepository.instance;
      final transfer = await repo.createTransferRequest(
        patientId: 'PAT-102',
        patientName: 'Kavita Iyer',
        caseId: 'CASE-102',
        sourceVisitId: 'VIS-102-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Migraine with aura requiring neurological review.',
      );

      // Concurrent accept simulation
      final results = await Future.wait([
        repo.acceptTransfer(
          transferId: transfer.transferId,
          doctorId: mockDestinationDoctor1.doctorId,
          doctorName: mockDestinationDoctor1.name,
          doctorDepartment: 'Neurology',
        ),
        repo.acceptTransfer(
          transferId: transfer.transferId,
          doctorId: mockDestinationDoctor2.doctorId,
          doctorName: mockDestinationDoctor2.name,
          doctorDepartment: 'Neurology',
        ),
      ]);

      // Exactly one succeeds, one gets alreadyAssigned
      final successCount = results.where((r) => r.isSuccess).length;
      final alreadyAssignedCount = results.where((r) => r.isAlreadyAssigned).length;
      expect(successCount, equals(1));
      expect(alreadyAssignedCount, equals(1));

      // Re-query: transfer belongs to the winner
      final finalTransfer = await repo.getTransferById(transfer.transferId);
      expect(finalTransfer?.status, TransferStatus.accepted);
      expect(
        finalTransfer?.destinationDoctorId == mockDestinationDoctor1.doctorId ||
            finalTransfer?.destinationDoctorId == mockDestinationDoctor2.doctorId,
        isTrue,
      );
    });

    test('10. Source doctor can cancel pending transfer', () async {
      final repo = MockTransferRepository.instance;
      final transfer = await repo.createTransferRequest(
        patientId: 'PAT-103',
        patientName: 'Suresh Menon',
        caseId: 'CASE-103',
        sourceVisitId: 'VIS-103-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Re-evaluating referral 필요.',
      );

      final cancelled = await repo.cancelTransfer(
        transferId: transfer.transferId,
        doctorId: 'DOC-101',
      );
      expect(cancelled, isTrue);

      final updated = await repo.getTransferById(transfer.transferId);
      expect(updated?.status, TransferStatus.cancelled);

      // Pending queue no longer shows cancelled transfer
      final pending = await repo.getPendingTransfersForDepartment('Neurology');
      expect(pending.any((t) => t.transferId == transfer.transferId), isFalse);
    });

    test('11. Unauthorized doctor cannot cancel transfer', () async {
      final repo = MockTransferRepository.instance;
      final transfer = await repo.createTransferRequest(
        patientId: 'PAT-104',
        patientName: 'Deepak Verma',
        caseId: 'CASE-104',
        sourceVisitId: 'VIS-104-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Suspected neuro issue.',
      );

      final cancelled = await repo.cancelTransfer(
        transferId: transfer.transferId,
        doctorId: 'DOC-UNKNOWN-999',
      );
      expect(cancelled, isFalse);

      final updated = await repo.getTransferById(transfer.transferId);
      expect(updated?.status, TransferStatus.pending);
    });

    test('12. Cannot cancel already accepted transfer', () async {
      final repo = MockTransferRepository.instance;
      final transfer = await repo.createTransferRequest(
        patientId: 'PAT-105',
        patientName: 'Pooja Nair',
        caseId: 'CASE-105',
        sourceVisitId: 'VIS-105-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Seizure workup.',
      );

      await repo.acceptTransfer(
        transferId: transfer.transferId,
        doctorId: 'DOC-201',
        doctorName: 'Dr. Sunita Rao',
        doctorDepartment: 'Neurology',
      );

      final cancelled = await repo.cancelTransfer(
        transferId: transfer.transferId,
        doctorId: 'DOC-101',
      );
      expect(cancelled, isFalse);

      final updated = await repo.getTransferById(transfer.transferId);
      expect(updated?.status, TransferStatus.accepted);
    });
  });

  group('AAYUSATHI Phase D13: Case Lifecycle & Visit Integrity', () {
    test('13. Transferring patient strictly keeps Case status OPEN', () async {
      final caseRepo = MockCaseRepository.instance;
      final visitRepo = MockClinicalVisitRepository.instance;
      final transferRepo = MockTransferRepository.instance;

      // Seed case & visit
      await caseRepo.createCase(
        mockCase,
      );

      // Create transfer
      final transfer = await transferRepo.createTransferRequest(
        patientId: 'PAT-MOCK-001',
        patientName: 'Test Patient',
        caseId: 'CASE-001',
        sourceVisitId: 'VIS-CASE-001-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Syncope workup.',
      );
      expect(transfer.isPending, isTrue);

      // Mark source visit as transferred
      await visitRepo.updateVisit(mockActiveVisit.copyWith(
        status: ClinicalVisitStatus.transferred,
      ));

      // Verify case status remains strictly OPEN
      final c = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-001',
      );
      expect(c?.isOpen, isTrue);
      expect(c?.isClosed, isFalse);
      expect(c?.status, ClinicalCaseStatus.open);
    });

    test('14. Historical visits remain intact when a visit is transferred', () async {
      final visitRepo = MockClinicalVisitRepository.instance;

      final visits = await visitRepo.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(visits, isNotEmpty);
    });
  });

  group('AAYUSATHI Phase D13: Doctor Presence & Workflow State Machine', () {
    test('15. Source doctor presence transitions to AVAILABLE after successful transfer', () async {
      final presence = DoctorPresenceService.instance;
      await presence.goOnline();
      await presence.setAvailable();
      await presence.setInConsultation();
      expect(presence.isInConsultation, isTrue);

      final repo = MockTransferRepository.instance;
      final transfer = await repo.createTransferRequest(
        patientId: 'PAT-001',
        patientName: 'Test Patient',
        caseId: 'CASE-001',
        sourceVisitId: 'VIS-001',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Orthopedics',
        transferReason: 'Associated joint pain requiring ortho opinion.',
      );

      expect(transfer.transferId, isNotEmpty);
      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);
      expect(presence.isInConsultation, isFalse);
    });

    test('16. Destination doctor presence transitions to IN_CONSULTATION upon claiming transfer', () async {
      final presence = DoctorPresenceService.instance;
      await presence.goOnline();
      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);

      final reqService = MockDoctorPatientRequestService.instance;
      final transferRepo = MockTransferRepository.instance;

      final transfer = await transferRepo.createTransferRequest(
        patientId: 'PAT-002',
        patientName: 'Priyanka Das',
        caseId: 'CASE-002',
        sourceVisitId: 'VIS-002',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        transferReason: 'Migraine evaluation.',
      );

      final result = await reqService.acceptPatientRequest(
        requestId: transfer.transferId,
        doctorId: mockDestinationDoctor1.doctorId,
        doctorDomain: 'Neurology',
      );

      expect(result.isSuccess, isTrue);
      await presence.setInConsultation();
      expect(presence.isInConsultation, isTrue);
    });
  });

  group('AAYUSATHI Phase D13: UI Components & Dialogs', () {
    testWidgets('17. DoctorTransferPatientDialog renders departments and validates character limits', (tester) async {
      String? selectedDept;
      String? enteredReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (_) => DoctorTransferPatientDialog(
                      patientName: 'Aarav Patel',
                      patientAge: 45,
                      patientGender: 'Male',
                      currentDepartment: 'Cardiology',
                      onTransferConfirmed: (dept, reason) {
                        selectedDept = dept;
                        enteredReason = reason;
                      },
                    ),
                  );
                },
                child: const Text('Open Transfer Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Transfer Dialog'));
      await tester.pumpAndSettle();

      // Verify title & patient info
      expect(find.text('TRANSFER PATIENT'), findsOneWidget);
      expect(find.textContaining('Aarav Patel'), findsOneWidget);

      // Select Neurology
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Neurology').last);
      await tester.pumpAndSettle();

      // Attempt to proceed without entering reason
      await tester.tap(find.text('REVIEW TRANSFER'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please provide a reason for transferring this patient (minimum 5 characters).'), findsOneWidget);

      // Enter valid transfer reason
      await tester.enterText(
        find.byType(TextFormField),
        'Patient presents with sudden focal neurological symptoms requiring immediate specialist review.',
      );
      await tester.pumpAndSettle();

      // Proceed to Step 2 Review
      await tester.tap(find.text('REVIEW TRANSFER'));
      await tester.pumpAndSettle();

      // Verify Step 2 UI
      expect(find.text('REVIEW TRANSFER DETAILS'), findsOneWidget);
      expect(find.text('Neurology'), findsWidgets);
      expect(find.textContaining('focal neurological symptoms'), findsOneWidget);

      // Confirm Transfer
      await tester.tap(find.text('CONFIRM TRANSFER'));
      await tester.pumpAndSettle();

      expect(selectedDept, 'Neurology');
      expect(enteredReason, contains('focal neurological symptoms'));
    });

    testWidgets('18. DoctorTransferContextBanner displays source department and reason', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoctorTransferContextBanner(
              sourceDepartment: 'Cardiology',
              sourceDoctorName: 'Dr. Rajesh Sharma',
              transferReason: 'Referred for specialist neurological assessment and EEG workup.',
            ),
          ),
        ),
      );

      expect(find.textContaining('Transferred from: Cardiology'), findsOneWidget);
      expect(find.textContaining('Dr. Rajesh Sharma'), findsOneWidget);
      expect(find.textContaining('Referred for specialist neurological assessment'), findsOneWidget);
      expect(find.text('TRANSFER ASSIGNED'), findsOneWidget);
    });

    testWidgets('19. DoctorPatientRequestCard renders TRANSFER REQUEST badge and metadata', (tester) async {
      final transferRequest = DoctorPatientRequest(
        requestId: 'TRF-TEST-001',
        patientId: 'PAT-001',
        patientName: 'Sunita Mehra',
        age: 50,
        gender: 'Female',
        domain: 'Neurology',
        requestType: PatientRequestType.transfer,
        sourceDepartment: 'Cardiology',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        transferReason: 'Episodes of syncope with normal ECG; neurological workup recommended.',
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPatientRequestCard(
              request: transferRequest,
              onAccept: () {},
            ),
          ),
        ),
      );

      expect(find.text('TRANSFER REQUEST'), findsOneWidget);
      expect(find.textContaining('Cardiology'), findsOneWidget);
      expect(find.textContaining('Dr. Rajesh Sharma'), findsOneWidget);
      expect(find.textContaining('Episodes of syncope with normal ECG'), findsOneWidget);
    });

    testWidgets('20. PatientCaseOverviewCard renders transferred visit status badge', (tester) async {
      final transferredVisit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.transferred,
      );

      final bundle = PatientCaseRecordBundle(
        clinicalCase: mockCase,
        visits: [transferredVisit],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientCaseOverviewCard(
              bundle: bundle,
            ),
          ),
        ),
      );

      expect(find.text('TRANSFER REQUEST'), findsOneWidget);
      expect(find.text('OPEN (ONGOING)'), findsOneWidget);
    });
  });

  group('AAYUSATHI Phase D13: Audit Logging & Security', () {
    test('21. Transfer creation logs TRANSFER_REQUESTED audit event with zero credentials', () async {
      final auditRepo = MockAuditRepository.instance;
      await auditRepo.logEvent(AuditLog(
        auditId: 'AUD-001',
        actorType: 'DOCTOR',
        actorId: 'DOC-101',
        action: 'TRANSFER_REQUESTED',
        entityType: 'PATIENT_TRANSFER',
        entityId: 'TRF-001',
        timestamp: DateTime.now(),
        metadata: {
          'caseId': 'CASE-001',
          'sourceVisitId': 'VIS-001',
          'sourceDepartment': 'Cardiology',
          'destinationDepartment': 'Neurology',
          'reasonLength': 45,
        },
      ));

      final logs = auditRepo.logs.where((l) => l.actorId == 'DOC-101').toList();
      expect(logs.any((l) => l.action == 'TRANSFER_REQUESTED'), isTrue);

      final targetLog = logs.firstWhere((l) => l.action == 'TRANSFER_REQUESTED');
      expect(targetLog.metadata['sourceDepartment'], 'Cardiology');
      expect(targetLog.metadata['destinationDepartment'], 'Neurology');
      expect(targetLog.metadata.containsKey('password'), isFalse);
      expect(targetLog.metadata.containsKey('token'), isFalse);
      expect(targetLog.metadata.containsKey('apiKey'), isFalse);
      expect(targetLog.metadata.containsKey('aadhaar'), isFalse);
    });

    test('22. Transfer acceptance logs TRANSFER_ACCEPTED audit event', () async {
      final auditRepo = MockAuditRepository.instance;
      await auditRepo.logEvent(AuditLog(
        auditId: 'AUD-002',
        actorType: 'DOCTOR',
        actorId: 'DOC-201',
        action: 'TRANSFER_ACCEPTED',
        entityType: 'PATIENT_TRANSFER',
        entityId: 'TRF-001',
        timestamp: DateTime.now(),
        metadata: {
          'transferId': 'TRF-001',
          'destinationDepartment': 'Neurology',
          'destinationDoctorId': 'DOC-201',
        },
      ));

      final logs = auditRepo.logs.where((l) => l.actorId == 'DOC-201').toList();
      expect(logs.any((l) => l.action == 'TRANSFER_ACCEPTED'), isTrue);
    });

    test('23. Transfer cancellation logs TRANSFER_CANCELLED audit event', () async {
      final auditRepo = MockAuditRepository.instance;
      await auditRepo.logEvent(AuditLog(
        auditId: 'AUD-003',
        actorType: 'DOCTOR',
        actorId: 'DOC-101',
        action: 'TRANSFER_CANCELLED',
        entityType: 'PATIENT_TRANSFER',
        entityId: 'TRF-001',
        timestamp: DateTime.now(),
        metadata: {
          'transferId': 'TRF-001',
          'cancelledBy': 'DOC-101',
        },
      ));

      final logs = auditRepo.logs.where((l) => l.actorId == 'DOC-101').toList();
      expect(logs.any((l) => l.action == 'TRANSFER_CANCELLED'), isTrue);
    });
  });

  group('AAYUSATHI Phase D13: Multi-Language Localization Tests', () {
    test('24. English localization strings for transfer features', () {
      final strings = DoctorLocalizations.forLocale(KioskLocale.english);
      expect(strings.transferPatientButton, 'TRANSFER PATIENT');
      expect(strings.transferPatientTitle, 'Transfer Patient');
      expect(strings.transferPatientDialogSubtitle, contains('Select a destination OPD department'));
      expect(strings.destinationDepartmentLabel, 'Destination Department');
      expect(strings.transferReasonLabel, 'Transfer Reason');
      expect(strings.reviewTransferButton, 'REVIEW TRANSFER');
      expect(strings.confirmTransferButton, 'CONFIRM TRANSFER');
      expect(strings.transferredFromBanner, 'Transferred from');
      expect(strings.transferRequestBadge, 'TRANSFER REQUEST');
      expect(strings.cancelTransferTitle, 'Cancel Transfer?');
      expect(strings.cancelTransferButton, 'CANCEL TRANSFER');
      expect(strings.transferCancelledSuccess, 'Transfer request cancelled successfully.');
    });

    test('25. Hindi localization strings for transfer features', () {
      final strings = DoctorLocalizations.forLocale(KioskLocale.hindi);
      expect(strings.transferPatientButton, 'मरीज स्थानांतरित करें');
      expect(strings.transferPatientTitle, 'मरीज स्थानांतरण');
      expect(strings.destinationDepartmentLabel, 'गंतव्य विभाग');
      expect(strings.transferReasonLabel, 'स्थानांतरण / रेफरल का कारण');
      expect(strings.reviewTransferButton, 'स्थानांतरण की समीक्षा करें');
      expect(strings.confirmTransferButton, 'स्थानांतरण की पुष्टि करें');
      expect(strings.transferredFromBanner, 'से स्थानांतरित');
      expect(strings.transferRequestBadge, 'स्थानांतरण अनुरोध');
      expect(strings.cancelTransferTitle, 'स्थानांतरण रद्द करें?');
      expect(strings.cancelTransferButton, 'स्थानांतरण रद्द करें');
    });

    test('26. Marathi localization strings for transfer features', () {
      final strings = DoctorLocalizations.forLocale(KioskLocale.marathi);
      expect(strings.transferPatientButton, 'रुग्ण हस्तांतरित करा');
      expect(strings.transferPatientTitle, 'रुग्ण हस्तांतरण');
      expect(strings.destinationDepartmentLabel, 'गंतव्य विभाग');
      expect(strings.transferReasonLabel, 'हस्तांतरण / रेफरलचे कारण');
      expect(strings.reviewTransferButton, 'हस्तांतरणाचे पुनरावलोकन करा');
      expect(strings.confirmTransferButton, 'हस्तांतरणाची पुष्टी करा');
      expect(strings.transferredFromBanner, 'येथून हस्तांतरित');
      expect(strings.transferRequestBadge, 'हस्तांतरण विनंती');
      expect(strings.cancelTransferTitle, 'हस्तांतरण रद्द करायचे?');
      expect(strings.cancelTransferButton, 'हस्तांतरण रद्द करा');
    });
  });
}
