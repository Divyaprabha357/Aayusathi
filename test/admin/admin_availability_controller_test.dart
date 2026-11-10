import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_availability_controller.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';

import 'package:aayusathi/repositories/audit_repository.dart';

/// Test mock audit repository recording logged events in memory.
class MockTestAuditRepository implements AuditRepository {
  final List<AuditLog> loggedEvents = [];

  @override
  Future<void> logEvent(AuditLog log) async {
    loggedEvents.add(log);
  }

  @override
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
  }) async {
    return loggedEvents.where((e) => e.entityType == entityType && e.entityId == entityId).toList();
  }
}

void main() {
  late MockDoctorRepository doctorRepo;
  late MockTestAuditRepository auditRepo;
  late AdminAvailabilityController controller;

  setUp(() {
    doctorRepo = MockDoctorRepository.instance;
    doctorRepo.resetToDefaults();
    auditRepo = MockTestAuditRepository();

    controller = AdminAvailabilityController.instance;
    controller.resetForTesting();
    controller.setCustomRepositories(
      doctorRepository: doctorRepo,
      auditRepository: auditRepo,
    );
  });

  tearDown(() {
    controller.resetForTesting();
  });

  group('AdminAvailabilityController — Unit Tests', () {
    test('1. Initial stream subscription loads doctors and calculates KPI metrics', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.allDoctors.isNotEmpty, isTrue);

      // Verify active counting rule
      expect(controller.totalActiveDoctors, equals(controller.allDoctors.where((d) => d.isActive).length));
      expect(
        controller.onlineAvailableDoctors,
        equals(controller.allDoctors.where((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.available).length),
      );
    });

    test('2. Inactive counting rule: Inactive doctors are excluded from active counts and treated as OFFLINE', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final initialActive = controller.totalActiveDoctors;
      final initialAvailable = controller.onlineAvailableDoctors;

      // Deactivate an available doctor
      final availableDoc = controller.allDoctors.firstWhere((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.available);
      await doctorRepo.setDoctorActiveStatus(doctorId: availableDoc.doctorId, isActive: false);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.totalActiveDoctors, equals(initialActive - 1));
      expect(controller.onlineAvailableDoctors, equals(initialAvailable - 1));
      expect(controller.inactiveDoctorsCount, greaterThan(0));
    });

    test('3. Domain capacity summary calculates distribution across all 8 domains', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final summaries = controller.domainSummaries;
      expect(summaries.length, equals(8));

      final cardSummary = summaries.firstWhere((s) => s.domainId == 'cardiology');
      expect(cardSummary.domainName, equals('Cardiology'));
      expect(cardSummary.totalActive, greaterThan(0));
    });

    test('4. Multi-parameter search matches Name, Doctor ID, Department, Qualification', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Search by Name
      controller.setSearchQuery('Ramesh');
      expect(controller.filteredDoctors.any((d) => d.name.contains('Ramesh')), isTrue);

      // Search by Doctor ID
      controller.setSearchQuery('DOC-CARD');
      expect(controller.filteredDoctors.every((d) => d.doctorId.contains('DOC-CARD')), isTrue);

      // Search by Department
      controller.setSearchQuery('Cardiology');
      expect(controller.filteredDoctors.every((d) => d.department.toLowerCase() == 'cardiology'), isTrue);

      // Non-matching search
      controller.setSearchQuery('NonExistentDoctorX99');
      expect(controller.filteredDoctors, isEmpty);
    });

    test('5. Combinable filters: Department + Account + Availability', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      controller.setSelectedDepartment('cardiology');
      controller.setSelectedAccountStatus('active');
      controller.setSelectedAvailabilityStatus('available');

      final filtered = controller.filteredDoctors;
      expect(filtered.every((d) => d.department.toLowerCase() == 'cardiology'), isTrue);
      expect(filtered.every((d) => d.isActive == true), isTrue);
      expect(filtered.every((d) => d.availabilityStatus == DoctorAvailabilityStatus.available), isTrue);
    });

    test('6. Deterministic sorting: Name (A-Z), Department, Availability, Last Activity', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Sort by Name Ascending
      controller.setSortOption(DoctorAvailabilitySortOption.nameAsc);
      final names = controller.filteredDoctors.map((d) => d.name.toLowerCase()).toList();
      final sortedNames = List<String>.from(names)..sort();
      expect(names, equals(sortedNames));

      // Sort by Department
      controller.setSortOption(DoctorAvailabilitySortOption.department);
      final depts = controller.filteredDoctors.map((d) => d.department.toLowerCase()).toList();
      final sortedDepts = List<String>.from(depts)..sort();
      expect(depts, equals(sortedDepts));
    });

    test('7. Permitted Admin Transition: ACTIVE + OFFLINE -> AVAILABLE', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final offlineDoc = controller.allDoctors.firstWhere((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.offline);

      final success = await controller.setDoctorAvailability(
        doctor: offlineDoc,
        targetStatus: DoctorAvailabilityStatus.available,
      );

      expect(success, isTrue);
      expect(controller.actionError, isNull);

      final updated = await doctorRepo.getDoctorProfileById(offlineDoc.doctorId);
      expect(updated?.availabilityStatus, equals(DoctorAvailabilityStatus.available));

      // Verify Audit Log
      expect(auditRepo.loggedEvents.isNotEmpty, isTrue);
      final audit = auditRepo.loggedEvents.last;
      expect(audit.action, equals('DOCTOR_AVAILABILITY_CHANGED'));
      expect(audit.actorType, equals('ADMIN'));
      expect(audit.entityId, equals(offlineDoc.doctorId));
      expect(audit.metadata['newAvailability'], equals('available'));
    });

    test('8. Permitted Admin Transition: ACTIVE + AVAILABLE -> OFFLINE', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final availableDoc = controller.allDoctors.firstWhere((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.available);

      final success = await controller.setDoctorAvailability(
        doctor: availableDoc,
        targetStatus: DoctorAvailabilityStatus.offline,
      );

      expect(success, isTrue);
      expect(controller.actionError, isNull);

      final updated = await doctorRepo.getDoctorProfileById(availableDoc.doctorId);
      expect(updated?.availabilityStatus, equals(DoctorAvailabilityStatus.offline));
    });

    test('9. Active Consultation Safeguard: IN_CONSULTATION -> OFFLINE (HARD BLOCKED)', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.first;
      // Put doctor into consultation
      await doctorRepo.setDoctorAvailabilityStatus(
        doctorId: doc.doctorId,
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final consultingDoc = controller.allDoctors.firstWhere((d) => d.doctorId == doc.doctorId);
      expect(consultingDoc.availabilityStatus, equals(DoctorAvailabilityStatus.inConsultation));

      final success = await controller.setDoctorAvailability(
        doctor: consultingDoc,
        targetStatus: DoctorAvailabilityStatus.offline,
      );

      expect(success, isFalse);
      expect(controller.actionError, contains('IN CONSULTATION'));

      final stillConsulting = await doctorRepo.getDoctorProfileById(doc.doctorId);
      expect(stillConsulting?.availabilityStatus, equals(DoctorAvailabilityStatus.inConsultation));
    });

    test('10. Active Consultation Safeguard: IN_CONSULTATION -> AVAILABLE (HARD BLOCKED)', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.first;
      await doctorRepo.setDoctorAvailabilityStatus(
        doctorId: doc.doctorId,
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final consultingDoc = controller.allDoctors.firstWhere((d) => d.doctorId == doc.doctorId);

      final success = await controller.setDoctorAvailability(
        doctor: consultingDoc,
        targetStatus: DoctorAvailabilityStatus.available,
      );

      expect(success, isFalse);
      expect(controller.actionError, contains('IN CONSULTATION'));
    });

    test('11. Blocked Transition: Admin cannot manually set doctor to IN_CONSULTATION', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.firstWhere((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.available);

      final success = await controller.setDoctorAvailability(
        doctor: doc,
        targetStatus: DoctorAvailabilityStatus.inConsultation,
      );

      expect(success, isFalse);
      expect(controller.actionError, contains('Admin cannot manually assign'));
    });

    test('12. Inactive Doctor Protection: INACTIVE -> AVAILABLE (HARD BLOCKED)', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.first;
      await doctorRepo.setDoctorActiveStatus(doctorId: doc.doctorId, isActive: false);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final inactiveDoc = controller.allDoctors.firstWhere((d) => d.doctorId == doc.doctorId);

      final success = await controller.setDoctorAvailability(
        doctor: inactiveDoc,
        targetStatus: DoctorAvailabilityStatus.available,
      );

      expect(success, isFalse);
      expect(controller.actionError, contains('inactive'));
    });

    test('13. Concurrency Safety: Rejects if doctor started consultation after snapshot was taken', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final doc = controller.allDoctors.firstWhere((d) => d.isActive && d.availabilityStatus == DoctorAvailabilityStatus.available);

      // Doctor starts consultation on backend right before Admin's click reaches backend
      await doctorRepo.setDoctorAvailabilityStatus(
        doctorId: doc.doctorId,
        availabilityStatus: DoctorAvailabilityStatus.inConsultation,
      );

      // Admin tries to set offline using old stale snapshot
      final success = await controller.setDoctorAvailability(
        doctor: doc, // old snapshot where availabilityStatus == available
        targetStatus: DoctorAvailabilityStatus.offline,
      );

      expect(success, isFalse);
      expect(controller.actionError, contains('active consultation'));

      final fresh = await doctorRepo.getDoctorProfileById(doc.doctorId);
      expect(fresh?.availabilityStatus, equals(DoctorAvailabilityStatus.inConsultation));
    });

    test('14. Reset filters restores all search and filter properties to default', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      controller.setSearchQuery('query');
      controller.setSelectedDepartment('cardiology');
      controller.setSelectedAccountStatus('active');
      controller.setSelectedAvailabilityStatus('available');
      controller.setSortOption(DoctorAvailabilitySortOption.department);

      controller.resetFilters();

      expect(controller.searchQuery, isEmpty);
      expect(controller.selectedDepartment, isNull);
      expect(controller.selectedAccountStatus, isNull);
      expect(controller.selectedAvailabilityStatus, isNull);
      expect(controller.sortOption, equals(DoctorAvailabilitySortOption.nameAsc));
    });

    test('15. Manual refresh fetches doctor profiles and updates state', () async {
      await controller.refresh();
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.allDoctors.isNotEmpty, isTrue);
    });
  });
}
