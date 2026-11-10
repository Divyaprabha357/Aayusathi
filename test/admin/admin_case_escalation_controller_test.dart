import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_case_escalation_controller.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository caseRepo;
  late MockAuditRepository auditRepo;
  late AdminCaseEscalationController controller;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    caseRepo = MockCaseRepository.instance;
    auditRepo = MockAuditRepository.instance;

    caseRepo.resetToDefaults();
    auditRepo.clear();

    // Escalate 2 initial cases for controller tests
    await caseRepo.escalateCase(
      patientId: 'PAT-MOCK-001',
      caseId: 'CASE-PAT-001-01',
      visitId: 'VISIT-001',
      reason: CaseEscalationReason.clinicalDeterioration,
      doctorId: 'DOC-101',
      doctorName: 'Dr. Ramesh Sharma',
      note: 'SPO2 dropping rapidly',
    );
    await caseRepo.escalateCase(
      patientId: 'AAYU-102938',
      caseId: 'CASE-102938-01',
      visitId: 'VISIT-002',
      reason: CaseEscalationReason.repeatedVisitsNoResolution,
      doctorId: 'DOC-102',
      doctorName: 'Dr. Priya Patel',
      note: '3rd visit with uncontrolled BP',
    );

    await AdminAuthService.instance.login(
      username: 'admin01',
      password: 'aayusathi1226',
    );

    controller = AdminCaseEscalationController.instance;
    controller.resetForTesting();
    controller.initialize();
    // Allow stream to emit initial data
    await Future.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() {
    controller.resetForTesting();
  });

  group('Phase A8: AdminCaseEscalationController KPI Metric Tests', () {
    test('1. Calculates totalEscalatedCases, pendingReviewCount, repeatedVisitsCount, and underReviewCount correctly', () {
      expect(controller.totalEscalatedCases, equals(2));
      expect(controller.pendingReviewCount, equals(2));
      expect(controller.repeatedVisitsCount, equals(1));
      expect(controller.underReviewCount, equals(0));
    });

    test('2. Dynamically updates KPI metrics when a new case is escalated in repository', () async {
      final initialTotal = controller.totalEscalatedCases;

      // Escalate another existing case
      await caseRepo.escalateCase(
        patientId: 'AAYU-482910',
        caseId: 'CASE-482910-01',
        visitId: 'VISIT-003',
        reason: CaseEscalationReason.clinicalDeterioration,
        doctorId: 'DOC-103',
        doctorName: 'Dr. Sneha Joshi',
        note: 'Severe allergic reaction',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.totalEscalatedCases, equals(initialTotal + 1));
      expect(controller.pendingReviewCount, equals(3));
    });
  });

  group('Phase A8: AdminCaseEscalationController Filtering & Search Tests', () {
    test('1. Search query filters by patient ID, case ID, doctor name, and title', () {
      // Search by case ID
      controller.setSearchQuery('CASE-PAT-001-01');
      expect(controller.filteredEscalations.length, equals(1));
      expect(controller.filteredEscalations.first.caseId, equals('CASE-PAT-001-01'));

      // Search by doctor name
      controller.setSearchQuery('Ramesh');
      expect(controller.filteredEscalations.every((c) => c.escalatedByDoctorName?.contains('Ramesh') == true), isTrue);

      // Search by non-matching query
      controller.setSearchQuery('NONEXISTENT_QUERY_123');
      expect(controller.filteredEscalations, isEmpty);

      // Clear search
      controller.setSearchQuery('');
      expect(controller.filteredEscalations.length, equals(controller.allEscalations.length));
    });

    test('2. Department filter correctly isolates specialty cases', () {
      controller.setSelectedDepartment('CARDIOLOGY');
      expect(controller.filteredEscalations.every((c) => c.domain.toUpperCase().contains('CARDIOLOGY')), isTrue);

      controller.setSelectedDepartment('ALL');
      expect(controller.filteredEscalations.length, equals(controller.allEscalations.length));
    });

    test('3. Reason filter filters cases by escalation reason', () {
      controller.setSelectedReason(CaseEscalationReason.clinicalDeterioration);
      expect(
        controller.filteredEscalations.every((c) => c.escalationReason == CaseEscalationReason.clinicalDeterioration),
        isTrue,
      );

      controller.setSelectedReason(CaseEscalationReason.repeatedVisitsNoResolution);
      expect(
        controller.filteredEscalations.every((c) => c.escalationReason == CaseEscalationReason.repeatedVisitsNoResolution),
        isTrue,
      );

      controller.setSelectedReason(null);
      expect(controller.filteredEscalations.length, equals(controller.allEscalations.length));
    });

    test('4. Status filter filters cases by status (escalated vs underReview)', () async {
      controller.setSelectedReviewStatus(CaseEscalationStatus.escalated);
      expect(
        controller.filteredEscalations.every((c) => c.escalationStatus == CaseEscalationStatus.escalated),
        isTrue,
      );

      // Transition one case to under review
      final firstCase = controller.filteredEscalations.first;
      await controller.startReview(patientId: firstCase.patientId, caseId: firstCase.caseId);
      await Future.delayed(const Duration(milliseconds: 100));

      controller.setSelectedReviewStatus(CaseEscalationStatus.underReview);
      expect(
        controller.filteredEscalations.every((c) => c.escalationStatus == CaseEscalationStatus.underReview),
        isTrue,
      );
      expect(controller.filteredEscalations.length, equals(1));
      expect(controller.filteredEscalations.first.caseId, equals(firstCase.caseId));
    });
  });

  group('Phase A8: AdminCaseEscalationController Sorting Tests', () {
    test('1. Sorts by newestEscalation', () {
      controller.setSortOption(AdminCaseSortOption.newestEscalation);
      final list = controller.filteredEscalations;
      for (int i = 0; i < list.length - 1; i++) {
        final d1 = list[i].escalatedAt ?? list[i].updatedAt;
        final d2 = list[i + 1].escalatedAt ?? list[i + 1].updatedAt;
        expect(d1.isAfter(d2) || d1.isAtSameMomentAs(d2), isTrue);
      }
    });

    test('2. Sorts by oldestEscalation', () {
      controller.setSortOption(AdminCaseSortOption.oldestEscalation);
      final list = controller.filteredEscalations;
      for (int i = 0; i < list.length - 1; i++) {
        final d1 = list[i].escalatedAt ?? list[i].updatedAt;
        final d2 = list[i + 1].escalatedAt ?? list[i + 1].updatedAt;
        expect(d1.isBefore(d2) || d1.isAtSameMomentAs(d2), isTrue);
      }
    });

    test('3. Sorts by department name', () {
      controller.setSortOption(AdminCaseSortOption.department);
      final list = controller.filteredEscalations;
      for (int i = 0; i < list.length - 1; i++) {
        final d1 = list[i].domain.toLowerCase();
        final d2 = list[i + 1].domain.toLowerCase();
        expect(d1.compareTo(d2) <= 0, isTrue);
      }
    });
  });

  group('Phase A8: Admin Start Review Action Tests', () {
    test('1. startReview updates case to underReview and records admin metadata', () async {
      final targetCase = controller.allEscalations.firstWhere(
        (c) => c.escalationStatus == CaseEscalationStatus.escalated,
      );

      await controller.startReview(patientId: targetCase.patientId, caseId: targetCase.caseId);
      await Future.delayed(const Duration(milliseconds: 100));

      final updated = await caseRepo.getCaseById(
        patientId: targetCase.patientId,
        caseId: targetCase.caseId,
      );

      expect(updated, isNotNull);
      expect(updated!.escalationStatus, equals(CaseEscalationStatus.underReview));
      expect(updated.isUnderReview, isTrue);
      expect(updated.adminReviewStartedBy, equals('admin01'));
      expect(updated.adminReviewStartedAt, isNotNull);
      expect(updated.isOpen, isTrue); // Invariant: case remains OPEN

      // Verify audit event
      final events = await auditRepo.getLogsForEntity(
        entityType: 'CLINICAL_CASE',
        entityId: targetCase.caseId,
      );
      expect(events.any((e) => e.action == 'CASE_ESCALATION_REVIEW_STARTED'), isTrue);
    });

    test('2. startReview throws Exception if case is already underReview (duplicate protection)', () async {
      final targetCase = controller.allEscalations.firstWhere(
        (c) => c.escalationStatus == CaseEscalationStatus.escalated,
      );

      await controller.startReview(patientId: targetCase.patientId, caseId: targetCase.caseId);

      // Attempt duplicate review on already reviewed case
      expect(
        () async => await controller.startReview(patientId: targetCase.patientId, caseId: targetCase.caseId),
        throwsA(isA<Exception>()),
      );
    });
  });
}
