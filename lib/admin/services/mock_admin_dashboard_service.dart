import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/appointment_request.dart';
import '../../services/appointment_escalation_policy.dart';
import '../models/admin_dashboard_overview.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_waiting_appointment_summary.dart';
import 'admin_dashboard_service.dart';

/// In-memory mock implementation of [AdminDashboardService] for automated testing
/// and offline development.
class MockAdminDashboardService implements AdminDashboardService {
  static final MockAdminDashboardService instance = MockAdminDashboardService._();
  MockAdminDashboardService._();
  factory MockAdminDashboardService() => instance;

  AdminDashboardOverview? _customOverview;
  bool _shouldSimulateError = false;
  String _simulatedErrorMessage = 'Simulated Firestore connection failure';

  final StreamController<AdminDashboardOverview> _streamController =
      StreamController<AdminDashboardOverview>.broadcast();

  /// Configure simulated error for test cases.
  void simulateError([String? message]) {
    _shouldSimulateError = true;
    if (message != null) _simulatedErrorMessage = message;
    _streamController.addError(Exception(_simulatedErrorMessage));
  }

  /// Sets explicit mock data for deterministic UI verification.
  void setCustomOverview(AdminDashboardOverview overview) {
    _customOverview = overview;
    _shouldSimulateError = false;
    _streamController.add(overview);
  }

  /// Sets mock data with individual count parameters for convenience.
  void setMockData({
    int? registeredDoctors,
    int? onlineDoctors,
    int? waitingAppointments,
    int? escalatedAppointments,
    int? escalatedCases,
    int? activeCases,
    List<AdminDomainAvailability>? domainAvailability,
    List<AdminWaitingAppointmentSummary>? waitingAppointmentsList,
    Map<String, int>? activeCasesByDomain,
  }) {
    final overview = AdminDashboardOverview(
      registeredDoctors: registeredDoctors ?? 0,
      onlineDoctors: onlineDoctors ?? 0,
      waitingAppointments: waitingAppointments ?? 0,
      escalatedAppointments: escalatedAppointments ?? 0,
      escalatedCases: escalatedCases ?? 0,
      activeCases: activeCases ?? 0,
      domainAvailability: domainAvailability ?? AdminDomainAvailability.defaultEightDomains,
      waitingAppointmentsList: waitingAppointmentsList ?? [],
      activeCasesByDomain: activeCasesByDomain ?? {},
      lastUpdated: DateTime.now(),
    );
    setCustomOverview(overview);
  }

  /// Resets mock service to normal state.
  void reset() {
    _customOverview = null;
    _shouldSimulateError = false;
  }

  /// Alias for reset().
  void resetMockData() => reset();

  @override
  Future<AdminDashboardOverview> getDashboardOverview() async {
    if (_shouldSimulateError) {
      throw Exception(_simulatedErrorMessage);
    }

    if (_customOverview != null) {
      return _customOverview!;
    }

    // Derive overview dynamically from BackendProvider mock repositories
    try {
      final List<DoctorProfile> mockDoctors = [
        DoctorProfile(
          doctorId: 'DOC-101',
          doctorUniqueCode: 'DOC101',
          name: 'Dr. Aaradhya Sharma',
          qualification: 'MBBS, MD (Cardiology)',
          department: 'cardiology',
          registeredPhone: '9876543210',
          email: 'aaradhya@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
          authUid: 'mock_uid_101',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        DoctorProfile(
          doctorId: 'DOC-102',
          doctorUniqueCode: 'DOC102',
          name: 'Dr. Rajesh Patel',
          qualification: 'MBBS, MS (Orthopedics)',
          department: 'orthopedics',
          registeredPhone: '9876543211',
          email: 'rajesh@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.inConsultation,
          authUid: 'mock_uid_102',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        ),
        DoctorProfile(
          doctorId: 'DOC-103',
          doctorUniqueCode: 'DOC103',
          name: 'Dr. Sneha Verma',
          qualification: 'MBBS, MD (Pediatrics)',
          department: 'pediatrics',
          registeredPhone: '9876543212',
          email: 'sneha@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.online,
          authUid: 'mock_uid_103',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
        ),
        DoctorProfile(
          doctorId: 'DOC-104',
          doctorUniqueCode: 'DOC104',
          name: 'Dr. Vikram Deshmukh',
          qualification: 'MBBS, MD (General Medicine)',
          department: 'general_medicine',
          registeredPhone: '9876543213',
          email: 'vikram@aayusathi.com',
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.offline,
          authUid: 'mock_uid_104',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
        ),
      ];

      // Fetch all cases from BackendProvider case repository
      List<ClinicalCase> cases = [];
      try {
        cases = await BackendProvider.instance.caseRepository.getAllCases();
      } catch (_) {
        cases = [
          ClinicalCase(
            caseId: 'CASE-001',
            patientId: 'AAYU-102938',
            domain: 'cardiology',
            title: 'Hypertensive Heart Disease Follow-up',
            status: ClinicalCaseStatus.open,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ClinicalCase(
            caseId: 'CASE-002',
            patientId: 'AAYU-203948',
            domain: 'orthopedics',
            title: 'Right Knee Osteoarthritis',
            status: ClinicalCaseStatus.open,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
      }

      final activeCases = cases.where((c) => c.isOpen).length;
      final escalatedCasesCount = cases.where((c) => c.isOpen && c.isEscalated).length;
      final Map<String, int> activeCasesByDomain = {};
      for (final c in cases.where((c) => c.isOpen)) {
        final dName = _formatDomainName(c.domain);
        activeCasesByDomain[dName] = (activeCasesByDomain[dName] ?? 0) + 1;
      }

      // Fetch appointments from mock appointment repository
      List<AppointmentRequest> appointments = [];
      try {
        appointments = await BackendProvider.instance.appointmentRepository.getAllAppointments();
      } catch (_) {}

      final now = DateTime.now();
      int waitingCount = 0;
      int escalatedCount = 0;
      final List<AdminWaitingAppointmentSummary> waitingList = [];

      final waitingAppts = appointments.where((a) =>
          a.status == AppointmentStatus.waiting ||
          a.status == AppointmentStatus.pending).toList();

      if (waitingAppts.isEmpty) {
        // Default fixture item if repository is empty
        waitingList.add(
          AdminWaitingAppointmentSummary(
            requestId: 'REQ-001',
            queueNumber: 'A-00042',
            age: 34,
            gender: 'Male',
            domain: 'Cardiology',
            requestType: 'New Visit',
            waitingDurationFormatted: '04 min',
            status: 'Waiting',
            createdAt: now.subtract(const Duration(minutes: 4)),
          ),
        );
        waitingCount = 1;
      } else {
        waitingCount = waitingAppts.length;
        for (final apt in waitingAppts) {
          if (apt.isEscalated || AppointmentEscalationPolicy.shouldEscalate(apt, now)) {
            escalatedCount++;
          }
          final waitDuration = AppointmentEscalationPolicy.calculateWaitDuration(apt.createdAt, now);
          waitingList.add(
            AdminWaitingAppointmentSummary(
              requestId: apt.requestId,
              queueNumber: apt.queueNumber,
              domain: _formatDomainName(apt.domainId),
              requestType: apt.previousDoctorId != null && apt.previousDoctorId!.isNotEmpty
                  ? 'Previous Doctor'
                  : 'New Visit',
              waitingDurationFormatted: AppointmentEscalationPolicy.formatWaitDuration(waitDuration),
              status: apt.isEscalated || AppointmentEscalationPolicy.shouldEscalate(apt, now)
                  ? 'Escalated'
                  : 'Waiting',
              createdAt: apt.createdAt,
            ),
          );
        }
      }

      final domainAvailability = _calculateDomainAvailability(mockDoctors);

      return AdminDashboardOverview(
        registeredDoctors: mockDoctors.where((d) => d.isActive).length,
        onlineDoctors: mockDoctors
            .where((d) => d.isActive && d.availabilityStatus != DoctorAvailabilityStatus.offline)
            .length,
        waitingAppointments: waitingCount,
        escalatedAppointments: escalatedCount,
        escalatedCases: escalatedCasesCount,
        activeCases: activeCases,
        domainAvailability: domainAvailability,
        waitingAppointmentsList: waitingList,
        activeCasesByDomain: activeCasesByDomain,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[MockAdminDashboardService] Error generating mock overview: $e');
      return AdminDashboardOverview.empty();
    }
  }

  @override
  Stream<AdminDashboardOverview> streamDashboardOverview() async* {
    yield await getDashboardOverview();
    yield* _streamController.stream;
  }

  @override
  Future<void> refresh() async {
    final overview = await getDashboardOverview();
    _streamController.add(overview);
  }

  List<AdminDomainAvailability> _calculateDomainAvailability(List<DoctorProfile> doctors) {
    final Map<String, AdminDomainAvailability> domainMap = {};

    for (final domain in AdminDomainAvailability.standardDomains) {
      domainMap[domain['id']!] = AdminDomainAvailability.empty(domain['id']!, domain['name']!);
    }

    for (final doc in doctors) {
      final domainKey = _normalizeDomainId(doc.department);
      if (domainMap.containsKey(domainKey)) {
        final current = domainMap[domainKey]!;
        final isOnline = doc.availabilityStatus != DoctorAvailabilityStatus.offline;
        final isAvail = doc.availabilityStatus == DoctorAvailabilityStatus.available;
        final isConsult = doc.availabilityStatus == DoctorAvailabilityStatus.inConsultation;

        domainMap[domainKey] = current.copyWith(
          totalDoctors: current.totalDoctors + 1,
          onlineDoctors: current.onlineDoctors + (isOnline ? 1 : 0),
          available: current.available + (isAvail ? 1 : 0),
          inConsultation: current.inConsultation + (isConsult ? 1 : 0),
        );
      }
    }

    return AdminDomainAvailability.standardDomains
        .map((d) => domainMap[d['id']!]!)
        .toList();
  }

  String _normalizeDomainId(String raw) {
    final lower = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '_');
    if (lower.contains('cardio')) return 'cardiology';
    if (lower.contains('neuro')) return 'neurology';
    if (lower.contains('gastro')) return 'gastroenterology';
    if (lower.contains('ortho')) return 'orthopedics';
    if (lower.contains('pediatric') || lower.contains('paediatric')) return 'pediatrics';
    if (lower.contains('ent')) return 'ent';
    if (lower.contains('derma')) return 'dermatology';
    if (lower.contains('general') || lower.contains('medicine')) return 'general_medicine';
    return lower;
  }

  String _formatDomainName(String raw) {
    final id = _normalizeDomainId(raw);
    for (final d in AdminDomainAvailability.standardDomains) {
      if (d['id'] == id) return d['name']!;
    }
    return raw;
  }
}
