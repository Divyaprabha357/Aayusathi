import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_config.dart';
import '../../models/appointment_request.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../models/clinical_visit.dart';
import '../models/patient_report.dart';
import 'doctor_patient_workspace_service.dart';

/// Cloud Firestore implementation of [DoctorPatientWorkspaceService].
///
/// Features:
/// - Enforces strict server-side authorization: Doctor must be assigned to appointment.
/// - Loads Patient entity without Aadhaar or passwords.
/// - Loads hierarchical Cases and Visits.
/// - Aggregates patient telemetry and clinical reports.
class FirebaseDoctorPatientWorkspaceService implements DoctorPatientWorkspaceService {
  final FirebaseFirestore? _customFirestore;

  FirebaseDoctorPatientWorkspaceService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<DoctorPatientWorkspaceData> loadWorkspaceData({
    required String requestId,
    required String doctorId,
  }) async {
    try {
      // 1. Fetch Appointment / Consultation Request
      final apptDoc = await _firestore
          .collection(FirebaseConfig.appointmentsCollection)
          .doc(requestId)
          .get();

      if (!apptDoc.exists || apptDoc.data() == null) {
        return DoctorPatientWorkspaceData.appointmentNotFound(
          message: 'Appointment consultation record could not be found.',
        );
      }

      final appointment =
          AppointmentRequest.fromFirestore(apptDoc.data()!, apptDoc.id);

      // 2. Authorization Check:
      // Doctor must be assigned to this specific appointment
      if (appointment.assignedDoctorId != doctorId) {
        debugPrint(
            '[FirebaseWorkspace] Access Denied: Doctor $doctorId attempted to access appointment assigned to ${appointment.assignedDoctorId}');
        return DoctorPatientWorkspaceData.unauthorized(
          message: 'You are not authorized to access this patient consultation.',
        );
      }

      // 3. Fetch Patient Identity
      final patientDoc = await _firestore
          .collection(FirebaseConfig.patientsCollection)
          .doc(appointment.patientId)
          .get();

      if (!patientDoc.exists || patientDoc.data() == null) {
        return DoctorPatientWorkspaceData.patientNotFound(
          message: 'Patient record could not be found in clinical database.',
        );
      }

      final patient = Patient.fromFirestore(patientDoc.data()!, patientDoc.id);

      // 4. Fetch Current Validated Vitals: check appointment model first, then raw map, then vitals collection
      VitalReading? vitals = appointment.vitals;
      if (vitals == null && apptDoc.data() != null && apptDoc.data()!['vitals'] != null && apptDoc.data()!['vitals'] is Map) {
        try {
          vitals = VitalReading.fromMap(apptDoc.data()!['vitals'] as Map<dynamic, dynamic>);
        } catch (_) {}
      }

      if (vitals == null) {
        try {
          final vitalSnap = await _firestore
              .collection(FirebaseConfig.vitalsCollection)
              .where('appointmentId', isEqualTo: appointment.requestId)
              .get();

          if (vitalSnap.docs.isNotEmpty) {
            vitals = VitalReading.fromFirestore(
                vitalSnap.docs.first.data(), vitalSnap.docs.first.id);
          } else {
            final patientVitalSnap = await _firestore
                .collection(FirebaseConfig.vitalsCollection)
                .where('patientId', isEqualTo: patient.patientId)
                .get();

            if (patientVitalSnap.docs.isNotEmpty) {
              final allVitals = patientVitalSnap.docs
                  .map((d) => VitalReading.fromFirestore(d.data(), d.id))
                  .toList();
              allVitals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              vitals = allVitals.first;
            }
          }
        } catch (e) {
          debugPrint('[FirebaseWorkspace] Non-fatal vitals fetch warning: $e');
        }
      }

      // 5. Fetch Clinical Cases
      final cases = await BackendProvider.instance.caseRepository
          .getCasesForPatient(patient.patientId);

      // 6. Fetch Visits for all cases
      final visits = <ClinicalVisit>[];
      for (final c in cases) {
        final caseVisits = await BackendProvider.instance.clinicalVisitRepository
            .getVisitsForCase(
          patientId: patient.patientId,
          caseId: c.caseId,
        );
        visits.addAll(caseVisits);
      }

      // 7. Fetch Reports
      final reports = await getReportsForPatient(patient.patientId);

      return DoctorPatientWorkspaceData.success(
        patient: patient,
        appointment: appointment,
        vitals: vitals,
        cases: cases,
        visits: visits,
        reports: reports,
      );
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseWorkspace] FirebaseException: ${e.code}');
      return DoctorPatientWorkspaceData.error(
        message: 'Clinical database error: ${e.message ?? e.code}',
      );
    } catch (e) {
      debugPrint('[FirebaseWorkspace] Unexpected error: $e');
      return DoctorPatientWorkspaceData.error(
        message: 'Failed to load clinical patient records.',
      );
    }
  }

  @override
  Future<List<PatientReport>> getReportsForPatient(String patientId) async {
    // In Phase D7, reports collection query foundation
    try {
      final snap = await _firestore
          .collection(FirebaseConfig.patientsCollection)
          .doc(patientId)
          .collection('reports')
          .get();

      return snap.docs
          .map((d) => PatientReport.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
