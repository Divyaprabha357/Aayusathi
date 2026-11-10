import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../models/doctor_profile.dart';
import '../models/report_document.dart';
import 'doctor_profile_service.dart';
import 'doctor_session_service.dart';

/// Clinical authorization diagnostic outcomes as mandated by AAYUSATHI specifications.
enum DoctorReportAuthOutcome {
  doctorProfileNotFound,
  reportPatientMismatch,
  reportCaseMismatch,
  reportVisitMismatch,
  doctorNotClinicallyInvolved,
  authorizedStorageDownloadFailed,
  reportOpenSuccess,
}

extension DoctorReportAuthOutcomeExt on DoctorReportAuthOutcome {
  String get code {
    switch (this) {
      case DoctorReportAuthOutcome.doctorProfileNotFound:
        return 'DOCTOR_PROFILE_NOT_FOUND';
      case DoctorReportAuthOutcome.reportPatientMismatch:
        return 'REPORT_PATIENT_MISMATCH';
      case DoctorReportAuthOutcome.reportCaseMismatch:
        return 'REPORT_CASE_MISMATCH';
      case DoctorReportAuthOutcome.reportVisitMismatch:
        return 'REPORT_VISIT_MISMATCH';
      case DoctorReportAuthOutcome.doctorNotClinicallyInvolved:
        return 'DOCTOR_NOT_CLINICALLY_INVOLVED';
      case DoctorReportAuthOutcome.authorizedStorageDownloadFailed:
        return 'AUTHORIZED_STORAGE_DOWNLOAD_FAILED';
      case DoctorReportAuthOutcome.reportOpenSuccess:
        return 'REPORT_OPEN_SUCCESS';
    }
  }
}

/// Detailed clinical authorization verification result for medical report access.
class DoctorReportAuthResult {
  final bool isAuthorized;
  final DoctorReportAuthOutcome outcome;
  final String message;
  final String? doctorId;
  final bool patientMatched;
  final bool caseMatched;
  final bool visitMatched;
  final ClinicalCase? clinicalCase;
  final ClinicalVisit? clinicalVisit;
  final DoctorProfile? doctorProfile;

  const DoctorReportAuthResult({
    required this.isAuthorized,
    required this.outcome,
    required this.message,
    this.doctorId,
    this.patientMatched = false,
    this.caseMatched = false,
    this.visitMatched = false,
    this.clinicalCase,
    this.clinicalVisit,
    this.doctorProfile,
  });

  String get diagnosticOutcome => outcome.code;

  factory DoctorReportAuthResult.authorized({
    required DoctorProfile doctorProfile,
    ClinicalCase? clinicalCase,
    ClinicalVisit? clinicalVisit,
    bool patientMatched = true,
    bool caseMatched = true,
    bool visitMatched = true,
    String message = 'Doctor is authorized for this report document.',
  }) {
    return DoctorReportAuthResult(
      isAuthorized: true,
      outcome: DoctorReportAuthOutcome.reportOpenSuccess,
      message: message,
      doctorId: doctorProfile.doctorId,
      patientMatched: patientMatched,
      caseMatched: caseMatched,
      visitMatched: visitMatched,
      clinicalCase: clinicalCase,
      clinicalVisit: clinicalVisit,
      doctorProfile: doctorProfile,
    );
  }

  factory DoctorReportAuthResult.denied(
    DoctorReportAuthOutcome outcome,
    String message, {
    String? doctorId,
    bool patientMatched = false,
    bool caseMatched = false,
    bool visitMatched = false,
    DoctorProfile? doctorProfile,
  }) {
    return DoctorReportAuthResult(
      isAuthorized: false,
      outcome: outcome,
      message: message,
      doctorId: doctorId ?? doctorProfile?.doctorId,
      patientMatched: patientMatched,
      caseMatched: caseMatched,
      visitMatched: visitMatched,
      doctorProfile: doctorProfile,
    );
  }
}

/// Authoritative clinical authorization service verifying doctor report access.
///
/// Rules Enforced:
/// 1. Authenticated doctor must map to a valid, active doctor profile.
/// 2. Report must belong to the correct patient (patient isolation).
/// 3. Report's case ID must match an authoritative clinical case.
/// 4. Report's visit ID must match an authoritative clinical visit.
/// 5. Doctor must have legitimate clinical involvement in that case or visit
///    (attending doctor, completing doctor, approving doctor, case-closed/escalated/assigned doctor,
///    investigation requester, or audited transfer participant).
/// 6. Historical and completed visits remain accessible to doctors who participated in them.
/// 7. Safe structured diagnostic logging without PHI/secret leaks.
class DoctorReportAuthorizationService {
  static final DoctorReportAuthorizationService instance =
      DoctorReportAuthorizationService._();

  DoctorReportAuthorizationService._();
  factory DoctorReportAuthorizationService() => instance;

  /// Normalizes patient identifiers for deterministic comparison.
  /// Handles with/without 'AAYU-' prefix, spacing, and casing.
  static String normalizePatientId(String? raw) {
    if (raw == null) return '';
    var clean = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    if (clean.startsWith('AAYU-')) {
      clean = clean.replaceFirst('AAYU-', '');
    }
    return clean;
  }

  /// Normalizes generic IDs (case, visit, doctor, report) by trimming and uppercasing.
  static String normalizeId(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
  }

  /// Emits privacy-safe structured diagnostic log.
  static void logDiagnostic({
    required bool isAuthorized,
    required DoctorReportAuthOutcome outcome,
    String? doctorId,
    bool patientMatched = false,
    bool caseMatched = false,
    bool visitMatched = false,
    String? extra,
  }) {
    debugPrint(
      '[DoctorReportAuth] Decision: ${isAuthorized ? "AUTHORIZED" : "DENIED"} '
      '| Outcome: ${outcome.code} '
      '| DoctorId: ${doctorId ?? "UNKNOWN"} '
      '| PatientMatch: $patientMatched '
      '| CaseMatch: $caseMatched '
      '| VisitMatch: $visitMatched'
      '${extra != null && extra.isNotEmpty ? " | $extra" : ""}',
    );
  }

  /// Verifies clinical report access according to all security and clinical mandates.
  Future<DoctorReportAuthResult> verifyReportAccess({
    required ReportDocument report,
    String? expectedPatientId,
    String? expectedCaseId,
    String? expectedVisitId,
    DoctorProfile? customDoctorProfile,
  }) async {
    final session = DoctorSessionService.instance;

    // 1. Authenticated Doctor Profile Resolution
    DoctorProfile? profile = customDoctorProfile ?? session.activeProfile;
    if (profile == null && session.isDevelopmentMode) {
      profile = MockDoctorProfileService.demoDoctor;
    }

    if (profile == null || !profile.isActive) {
      logDiagnostic(
        isAuthorized: false,
        outcome: DoctorReportAuthOutcome.doctorProfileNotFound,
        doctorId: session.activeDoctorId,
      );
      return DoctorReportAuthResult.denied(
        DoctorReportAuthOutcome.doctorProfileNotFound,
        'Authenticated doctor profile could not be resolved or is inactive.',
        doctorId: session.activeDoctorId,
      );
    }

    final doctorId = profile.doctorId;
    final doctorIdentifiers = <String>{
      if (profile.doctorId.isNotEmpty) normalizeId(profile.doctorId),
      if (profile.doctorUniqueCode.isNotEmpty) normalizeId(profile.doctorUniqueCode),
      if (profile.authUid.isNotEmpty) normalizeId(profile.authUid),
      if (session.activeDoctorId != null && session.activeDoctorId!.isNotEmpty)
        normalizeId(session.activeDoctorId),
    };

    bool isDoctorMatch(String? candidateId) {
      if (candidateId == null || candidateId.trim().isEmpty) return false;
      return doctorIdentifiers.contains(normalizeId(candidateId));
    }

    // 2. Patient Isolation & Matching
    final normalizedReportPatientId = normalizePatientId(report.patientId);
    if (normalizedReportPatientId.isEmpty) {
      logDiagnostic(
        isAuthorized: false,
        outcome: DoctorReportAuthOutcome.reportPatientMismatch,
        doctorId: doctorId,
      );
      return DoctorReportAuthResult.denied(
        DoctorReportAuthOutcome.reportPatientMismatch,
        'Report document has missing or invalid patient ID.',
        doctorProfile: profile,
      );
    }

    if (expectedPatientId != null && expectedPatientId.trim().isNotEmpty) {
      final normalizedExpectedPatient = normalizePatientId(expectedPatientId);
      if (normalizedReportPatientId != normalizedExpectedPatient) {
        logDiagnostic(
          isAuthorized: false,
          outcome: DoctorReportAuthOutcome.reportPatientMismatch,
          doctorId: doctorId,
          patientMatched: false,
        );
        return DoctorReportAuthResult.denied(
          DoctorReportAuthOutcome.reportPatientMismatch,
          'Report patient does not match the active patient context.',
          doctorProfile: profile,
          patientMatched: false,
        );
      }
    }

    // 3. Case Matching & Authoritative Verification
    final normalizedReportCaseId = normalizeId(report.caseId);
    if (normalizedReportCaseId.isEmpty) {
      logDiagnostic(
        isAuthorized: false,
        outcome: DoctorReportAuthOutcome.reportCaseMismatch,
        doctorId: doctorId,
        patientMatched: true,
      );
      return DoctorReportAuthResult.denied(
        DoctorReportAuthOutcome.reportCaseMismatch,
        'Report document has missing or invalid case ID.',
        doctorProfile: profile,
        patientMatched: true,
      );
    }

    if (expectedCaseId != null && expectedCaseId.trim().isNotEmpty) {
      if (normalizedReportCaseId != normalizeId(expectedCaseId)) {
        logDiagnostic(
          isAuthorized: false,
          outcome: DoctorReportAuthOutcome.reportCaseMismatch,
          doctorId: doctorId,
          patientMatched: true,
          caseMatched: false,
        );
        return DoctorReportAuthResult.denied(
          DoctorReportAuthOutcome.reportCaseMismatch,
          'Report case does not match the expected case context.',
          doctorProfile: profile,
          patientMatched: true,
          caseMatched: false,
        );
      }
    }

    final caseRepo = BackendProvider.instance.caseRepository;
    var clinicalCase = await caseRepo.getCaseById(
      patientId: report.patientId,
      caseId: report.caseId,
    );

    if (clinicalCase == null) {
      // Check if this case exists under another patient to distinguish patient mismatch from missing case
      try {
        final allCases = await caseRepo.getAllCases();
        for (final c in allCases) {
          if (normalizeId(c.caseId) == normalizedReportCaseId) {
            if (normalizePatientId(c.patientId) != normalizedReportPatientId) {
              logDiagnostic(
                isAuthorized: false,
                outcome: DoctorReportAuthOutcome.reportPatientMismatch,
                doctorId: doctorId,
                patientMatched: false,
                caseMatched: true,
              );
              return DoctorReportAuthResult.denied(
                DoctorReportAuthOutcome.reportPatientMismatch,
                'Case exists but belongs to a different patient.',
                doctorProfile: profile,
                patientMatched: false,
                caseMatched: true,
              );
            }
          }
        }
      } catch (_) {}

      logDiagnostic(
        isAuthorized: false,
        outcome: DoctorReportAuthOutcome.reportCaseMismatch,
        doctorId: doctorId,
        patientMatched: true,
        caseMatched: false,
      );
      return DoctorReportAuthResult.denied(
        DoctorReportAuthOutcome.reportCaseMismatch,
        'Authoritative clinical case not found in repository.',
        doctorProfile: profile,
        patientMatched: true,
        caseMatched: false,
      );
    }

    if (normalizePatientId(clinicalCase.patientId) != normalizedReportPatientId) {
      logDiagnostic(
        isAuthorized: false,
        outcome: DoctorReportAuthOutcome.reportPatientMismatch,
        doctorId: doctorId,
        patientMatched: false,
        caseMatched: true,
      );
      return DoctorReportAuthResult.denied(
        DoctorReportAuthOutcome.reportPatientMismatch,
        'Case patient does not match report patient.',
        doctorProfile: profile,
        patientMatched: false,
        caseMatched: true,
      );
    }

    // 4. Visit Matching & Authoritative Verification
    final normalizedReportVisitId = normalizeId(report.visitId);
    if (expectedVisitId != null && expectedVisitId.trim().isNotEmpty) {
      if (normalizedReportVisitId != normalizeId(expectedVisitId)) {
        logDiagnostic(
          isAuthorized: false,
          outcome: DoctorReportAuthOutcome.reportVisitMismatch,
          doctorId: doctorId,
          patientMatched: true,
          caseMatched: true,
          visitMatched: false,
        );
        return DoctorReportAuthResult.denied(
          DoctorReportAuthOutcome.reportVisitMismatch,
          'Report visit does not match expected visit context.',
          doctorProfile: profile,
          patientMatched: true,
          caseMatched: true,
          visitMatched: false,
        );
      }
    }

    ClinicalVisit? clinicalVisit;
    final visitRepo = BackendProvider.instance.clinicalVisitRepository;
    if (normalizedReportVisitId.isNotEmpty) {
      clinicalVisit = await visitRepo.getVisitById(
        patientId: report.patientId,
        caseId: report.caseId,
        visitId: report.visitId,
      );

      if (clinicalVisit == null) {
        logDiagnostic(
          isAuthorized: false,
          outcome: DoctorReportAuthOutcome.reportVisitMismatch,
          doctorId: doctorId,
          patientMatched: true,
          caseMatched: true,
          visitMatched: false,
        );
        return DoctorReportAuthResult.denied(
          DoctorReportAuthOutcome.reportVisitMismatch,
          'Authoritative clinical visit not found in repository.',
          doctorProfile: profile,
          patientMatched: true,
          caseMatched: true,
          visitMatched: false,
        );
      }

      if (normalizeId(clinicalVisit.caseId) != normalizedReportCaseId) {
        logDiagnostic(
          isAuthorized: false,
          outcome: DoctorReportAuthOutcome.reportCaseMismatch,
          doctorId: doctorId,
          patientMatched: true,
          caseMatched: false,
          visitMatched: true,
        );
        return DoctorReportAuthResult.denied(
          DoctorReportAuthOutcome.reportCaseMismatch,
          'Visit is not associated with the report case ID.',
          doctorProfile: profile,
          patientMatched: true,
          caseMatched: false,
          visitMatched: true,
        );
      }

      if (normalizePatientId(clinicalVisit.patientId) != normalizedReportPatientId) {
        logDiagnostic(
          isAuthorized: false,
          outcome: DoctorReportAuthOutcome.reportPatientMismatch,
          doctorId: doctorId,
          patientMatched: false,
          caseMatched: true,
          visitMatched: true,
        );
        return DoctorReportAuthResult.denied(
          DoctorReportAuthOutcome.reportPatientMismatch,
          'Visit is not associated with the report patient ID.',
          doctorProfile: profile,
          patientMatched: false,
          caseMatched: true,
          visitMatched: true,
        );
      }
    }

    // 5. Clinical Involvement Verification
    // (Preserving access for ongoing, completed, and historical visits)
    bool isClinicallyInvolved = false;

    // 5A. Specific visit involvement
    if (clinicalVisit != null) {
      if (isDoctorMatch(clinicalVisit.doctorId) ||
          isDoctorMatch(clinicalVisit.completedByDoctorId) ||
          isDoctorMatch(clinicalVisit.approvedByDoctorId)) {
        isClinicallyInvolved = true;
      }
    }

    // 5B. Case-level involvement
    if (!isClinicallyInvolved) {
      if (isDoctorMatch(clinicalCase.closedByDoctorId) ||
          isDoctorMatch(clinicalCase.higherAuthorityDoctorId) ||
          isDoctorMatch(clinicalCase.escalatedByDoctorId)) {
        isClinicallyInvolved = true;
      }
    }

    // 5C. Historical / Any Visit under Case involvement
    if (!isClinicallyInvolved) {
      try {
        final allVisits = await visitRepo.getVisitsForCase(
          patientId: report.patientId,
          caseId: report.caseId,
        );
        for (final v in allVisits) {
          if (isDoctorMatch(v.doctorId) ||
              isDoctorMatch(v.completedByDoctorId) ||
              isDoctorMatch(v.approvedByDoctorId)) {
            isClinicallyInvolved = true;
            break;
          }
        }
      } catch (_) {}
    }

    // 5D. Investigation Request involvement
    if (!isClinicallyInvolved && report.investigationId.isNotEmpty) {
      try {
        final invs = await BackendProvider.instance.investigationRepository
            .getInvestigationRequests(
          patientId: report.patientId,
          caseId: report.caseId,
          visitId: report.visitId,
        );
        for (final inv in invs) {
          if (inv.requestId == report.investigationId &&
              isDoctorMatch(inv.requestedByDoctorId)) {
            isClinicallyInvolved = true;
            break;
          }
        }
      } catch (_) {}
    }

    // 5E. Delegated case authorization fallback
    if (!isClinicallyInvolved) {
      try {
        final authCheck = await caseRepo.isDoctorAuthorizedForCase(
          doctorId: doctorId,
          caseId: report.caseId,
          patientId: report.patientId,
        );
        if (authCheck) {
          isClinicallyInvolved = true;
        }
      } catch (_) {}
    }

    if (!isClinicallyInvolved) {
      logDiagnostic(
        isAuthorized: false,
        outcome: DoctorReportAuthOutcome.doctorNotClinicallyInvolved,
        doctorId: doctorId,
        patientMatched: true,
        caseMatched: true,
        visitMatched: true,
      );
      return DoctorReportAuthResult.denied(
        DoctorReportAuthOutcome.doctorNotClinicallyInvolved,
        'Doctor has no clinical involvement in this case or visit.',
        doctorProfile: profile,
        patientMatched: true,
        caseMatched: true,
        visitMatched: true,
      );
    }

    // 6. Authorized
    logDiagnostic(
      isAuthorized: true,
      outcome: DoctorReportAuthOutcome.reportOpenSuccess,
      doctorId: doctorId,
      patientMatched: true,
      caseMatched: true,
      visitMatched: true,
      extra: 'AUTHORIZED_CLINICAL_ACCESS',
    );

    return DoctorReportAuthResult.authorized(
      doctorProfile: profile,
      clinicalCase: clinicalCase,
      clinicalVisit: clinicalVisit,
      patientMatched: true,
      caseMatched: true,
      visitMatched: true,
    );
  }
}
