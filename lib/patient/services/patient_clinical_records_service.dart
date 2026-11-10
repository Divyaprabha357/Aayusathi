import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/clinical_visit.dart';
import '../../doctor/models/report_document.dart';

/// Representation bundle of a patient clinical case along with its consultation visits
/// and linked diagnostic reports for the Patient application.
class PatientCaseRecordBundle {
  final ClinicalCase clinicalCase;
  final List<ClinicalVisit> visits;
  final Map<String, List<ReportDocument>> visitReports;

  const PatientCaseRecordBundle({
    required this.clinicalCase,
    this.visits = const [],
    this.visitReports = const {},
  });

  String get caseId => clinicalCase.caseId;
  String get domain => clinicalCase.domain;
  String get title => clinicalCase.title;
  bool get isOpen => clinicalCase.isOpen;
  bool get isClosed => clinicalCase.isClosed;
  int get visitCount => visits.length;

  List<ClinicalVisit> get completedVisits =>
      visits.where((v) => v.isCompleted).toList();

  List<ClinicalVisit> get activeVisits =>
      visits.where((v) => v.isActive).toList();
}

/// Domain service for the Patient module to query cases, completed visits,
/// and associated diagnostic reports.
class PatientClinicalRecordsService {
  static final PatientClinicalRecordsService instance =
      PatientClinicalRecordsService._();
  PatientClinicalRecordsService._();
  factory PatientClinicalRecordsService() => instance;

  /// Retrieves all clinical cases and scoped visit histories for a patient.
  Future<List<PatientCaseRecordBundle>> getPatientCases(String patientId) async {
    final cleanId = patientId.trim().toUpperCase();
    if (cleanId.isEmpty) return [];

    try {
      final cases =
          await BackendProvider.instance.caseRepository.getCasesForPatient(cleanId);
      final bundles = <PatientCaseRecordBundle>[];

      for (final c in cases) {
        final visits = await BackendProvider.instance.clinicalVisitRepository
            .getVisitsForCase(
          patientId: cleanId,
          caseId: c.caseId,
        );

        final reportsMap = <String, List<ReportDocument>>{};
        for (final v in visits) {
          try {
            final reports = await BackendProvider.instance.reportRepository
                .getReportsForVisit(
              patientId: cleanId,
              caseId: c.caseId,
              visitId: v.visitId,
            );
            reportsMap[v.visitId] = reports;
          } catch (_) {
            reportsMap[v.visitId] = const [];
          }
        }

        bundles.add(PatientCaseRecordBundle(
          clinicalCase: c,
          visits: visits,
          visitReports: reportsMap,
        ));
      }

      return bundles;
    } catch (e) {
      debugPrint('[PatientClinicalRecordsService] Error fetching cases: $e');
      return [];
    }
  }

  /// Retrieves a specific case record bundle by [caseId].
  Future<PatientCaseRecordBundle?> getCaseBundle({
    required String patientId,
    required String caseId,
  }) async {
    final cleanId = patientId.trim().toUpperCase();
    final c = await BackendProvider.instance.caseRepository.getCaseById(
      patientId: cleanId,
      caseId: caseId,
    );
    if (c == null) return null;

    final visits = await BackendProvider.instance.clinicalVisitRepository
        .getVisitsForCase(
      patientId: cleanId,
      caseId: caseId,
    );

    final reportsMap = <String, List<ReportDocument>>{};
    for (final v in visits) {
      try {
        final reports = await BackendProvider.instance.reportRepository
            .getReportsForVisit(
          patientId: cleanId,
          caseId: caseId,
          visitId: v.visitId,
        );
        reportsMap[v.visitId] = reports;
      } catch (_) {
        reportsMap[v.visitId] = const [];
      }
    }

    return PatientCaseRecordBundle(
      clinicalCase: c,
      visits: visits,
      visitReports: reportsMap,
    );
  }
}
