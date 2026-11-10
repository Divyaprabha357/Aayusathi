import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/appointment_request.dart';
import '../../services/appointment_escalation_policy.dart';
import '../models/admin_dashboard_overview.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_waiting_appointment_summary.dart';
import 'admin_dashboard_service.dart';

/// Cloud Firestore implementation of [AdminDashboardService].
///
/// Performs real-time aggregation across:
/// - `/doctors` (active & online doctors, domain presence)
/// - `/appointments` (active waiting queues and 20-minute SLA escalations)
/// - `collectionGroup('cases')` (open clinical cases)
class FirebaseAdminDashboardService implements AdminDashboardService {
  final FirebaseFirestore _firestore;

  FirebaseAdminDashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctorsCollection =>
      _firestore.collection(FirebaseConfig.doctorsCollection);

  CollectionReference<Map<String, dynamic>> get _appointmentsCollection =>
      _firestore.collection(FirebaseConfig.appointmentsCollection);

  CollectionReference<Map<String, dynamic>> get _patientsCollection =>
      _firestore.collection(FirebaseConfig.patientsCollection);

  @override
  Future<AdminDashboardOverview> getDashboardOverview() async {
    try {
      // 1. Fetch Doctors (Active & Presence)
      final doctorsSnap = await _doctorsCollection.get();
      final List<DoctorProfile> doctors = [];
      for (final doc in doctorsSnap.docs) {
        final profile = DoctorProfile.fromFirestore(doc.data(), doc.id);
        if (profile.isActive) {
          doctors.add(profile);
        }
      }

      final registeredDoctors = doctors.length;
      final availableDoctors = doctors
          .where((d) =>
              d.isActive &&
              d.availabilityStatus == DoctorAvailabilityStatus.available)
          .length;

      // Calculate Domain Availability across the 8 standard domains
      final domainAvailability = _calculateDomainAvailability(doctors);

      // 2. Fetch Waiting & Escalated Appointments
      final appointmentsSnap = await _appointmentsCollection
          .where('status', whereIn: ['waiting', 'pending'])
          .get();

      final List<AppointmentRequest> waitingAppointmentsList = [];
      int escalatedCount = 0;
      final now = DateTime.now();

      for (final doc in appointmentsSnap.docs) {
        final appt = AppointmentRequest.fromFirestore(doc.data(), doc.id);
        waitingAppointmentsList.add(appt);
        if (appt.isEscalated || AppointmentEscalationPolicy.shouldEscalate(appt, now)) {
          escalatedCount++;
        }
      }

      // Sort FIFO by createdAt
      waitingAppointmentsList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final waitingAppointmentsCount = waitingAppointmentsList.length;

      // Build privacy-safe summaries for the top waiting items
      final List<AdminWaitingAppointmentSummary> waitingSummaries = [];
      for (final apt in waitingAppointmentsList.take(10)) {
        int? age;
        String? gender;
        try {
          if (apt.patientId.isNotEmpty) {
            final patientDoc = await _patientsCollection.doc(apt.patientId).get();
            if (patientDoc.exists && patientDoc.data() != null) {
              final data = patientDoc.data()!;
              age = (data['age'] as num?)?.toInt();
              gender = data['gender'] as String?;
            }
          }
        } catch (_) {
          // Graceful fallback for demographics
        }

        final waitDiff = DateTime.now().difference(apt.createdAt);
        final waitMinutes = waitDiff.inMinutes.clamp(0, 9999);
        final waitDurationFormatted =
            '${waitMinutes.toString().padLeft(2, '0')} min';

        final requestTypeStr = apt.previousDoctorId != null &&
                apt.previousDoctorId!.isNotEmpty
            ? 'Previous Doctor'
            : 'New Visit';

        waitingSummaries.add(
          AdminWaitingAppointmentSummary(
            requestId: apt.requestId,
            queueNumber: apt.queueNumber,
            age: age,
            gender: gender,
            domain: _formatDomainName(apt.domainId),
            requestType: requestTypeStr,
            waitingDurationFormatted: waitDurationFormatted,
            status: apt.isEscalated || AppointmentEscalationPolicy.shouldEscalate(apt)
                ? 'Escalated'
                : 'Waiting',
            createdAt: apt.createdAt,
          ),
        );
      }

      // 3. Fetch Active Cases & Escalated Cases (Robust querying with in-memory filtering)
      QuerySnapshot<Map<String, dynamic>>? casesSnap;
      try {
        casesSnap = await _firestore.collectionGroup('cases').get();
      } catch (casesErr) {
        debugPrint('[FirebaseAdminDashboardService] collectionGroup cases query note: $casesErr');
      }

      int activeCasesCount = 0;
      int escalatedCasesCount = 0;
      final Map<String, int> activeCasesByDomain = {};

      if (casesSnap != null) {
        for (final doc in casesSnap.docs) {
          final c = ClinicalCase.fromFirestore(doc.data(), doc.id);
          if (c.isOpen) {
            activeCasesCount++;
            if (c.isEscalated) {
              escalatedCasesCount++;
            }
            final domainName = _formatDomainName(c.domain);
            activeCasesByDomain[domainName] =
                (activeCasesByDomain[domainName] ?? 0) + 1;
          }
        }
      }

      return AdminDashboardOverview(
        registeredDoctors: registeredDoctors,
        onlineDoctors: availableDoctors,
        waitingAppointments: waitingAppointmentsCount,
        escalatedAppointments: escalatedCount,
        escalatedCases: escalatedCasesCount,
        activeCases: activeCasesCount,
        domainAvailability: domainAvailability,
        waitingAppointmentsList: waitingSummaries,
        activeCasesByDomain: activeCasesByDomain,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint('[FirebaseAdminDashboardService] Error querying dashboard metrics: $e\n$stack');
      rethrow;
    }
  }

  @override
  Stream<AdminDashboardOverview> streamDashboardOverview() async* {
    yield await getDashboardOverview();

    final controller = StreamController<AdminDashboardOverview>();

    void emitUpdate() async {
      try {
        final overview = await getDashboardOverview();
        if (!controller.isClosed) {
          controller.add(overview);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    final sub1 = _doctorsCollection.snapshots().listen(
      (_) => emitUpdate(),
      onError: (err) {
        debugPrint('[FirebaseAdminDashboardService] Doctors stream error: $err');
        if (!controller.isClosed) controller.addError(err);
      },
    );
    final sub2 = _appointmentsCollection
        .where('status', whereIn: ['waiting', 'pending'])
        .snapshots()
        .listen(
      (_) => emitUpdate(),
      onError: (err) {
        debugPrint('[FirebaseAdminDashboardService] Appointments stream error: $err');
        if (!controller.isClosed) controller.addError(err);
      },
    );
    final sub3 = _firestore
        .collectionGroup('cases')
        .snapshots()
        .listen(
      (_) => emitUpdate(),
      onError: (err) {
        debugPrint('[FirebaseAdminDashboardService] Cases stream error: $err');
        if (!controller.isClosed) controller.addError(err);
      },
    );

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      controller.close();
    };

    yield* controller.stream;
  }

  @override
  Future<void> refresh() async {
    await getDashboardOverview();
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
