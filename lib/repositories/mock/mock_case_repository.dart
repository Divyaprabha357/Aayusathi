import 'dart:async';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../doctor/models/higher_authority_assignment.dart';
import '../../models/audit_log.dart';
import '../case_repository.dart';
import 'mock_clinical_visit_repository.dart';

/// In-memory mock implementation of [CaseRepository] providing deterministic
/// clinical case fixtures for development and testing.
class MockCaseRepository implements CaseRepository {
  static final MockCaseRepository instance = MockCaseRepository._();
  MockCaseRepository._() {
    resetToDefaults();
  }
  factory MockCaseRepository() => instance;

  final List<ClinicalCase> _cases = [];
  final StreamController<List<ClinicalCase>> _escalatedStreamController =
      StreamController<List<ClinicalCase>>.broadcast();

  void _notifyEscalatedStream() {
    if (!_escalatedStreamController.isClosed) {
      _escalatedStreamController.add(
        _cases.where((c) => c.isEscalated).toList()
          ..sort((a, b) => (b.escalatedAt ?? b.updatedAt).compareTo(a.escalatedAt ?? a.updatedAt)),
      );
    }
  }

  void resetToDefaults() {
    _mockStreamError = null;
    _cases.clear();
    _cases.addAll([
      ClinicalCase(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        domain: 'general_medicine',
        title: 'Hypertension & Exertional Dyspnea',
        status: ClinicalCaseStatus.open,
        visitCount: 2,
        relevantHistory: 'Hypertension (3 yrs), Seasonal Asthma, allergic to Penicillin.',
        createdAt: DateTime(2026, 9, 1, 9, 30),
        updatedAt: DateTime(2026, 9, 8, 10, 15),
      ),
      ClinicalCase(
        caseId: 'CASE-PAT-001-02',
        patientId: 'PAT-MOCK-001',
        domain: 'Orthopedics',
        title: 'Right Knee Sprain',
        status: ClinicalCaseStatus.closed,
        closedAt: DateTime(2026, 8, 20, 15, 0),
        closedByDoctorId: 'DOC-103',
        closedByDoctorName: 'Dr. Anita Desai',
        closureNote: 'Patient completely recovered with conservative management.',
        visitCount: 1,
        relevantHistory: 'No prior knee surgery.',
        createdAt: DateTime(2026, 8, 1, 10, 0),
        updatedAt: DateTime(2026, 8, 20, 15, 0),
      ),
      ClinicalCase(
        caseId: 'CASE-PAT-002-01',
        patientId: 'PAT-MOCK-002',
        domain: 'Cardiology',
        title: 'Unstable angina with atypical chest pain and dyslipidemia',
        status: ClinicalCaseStatus.open,
        visitCount: 1,
        relevantHistory: 'Type 2 Diabetes Mellitus (5 yrs), smoker (10 pack-years).',
        createdAt: DateTime(2026, 9, 5, 11, 0),
        updatedAt: DateTime(2026, 9, 5, 11, 45),
      ),
      ClinicalCase(
        caseId: 'CASE-PAT-003-01',
        patientId: 'PAT-MOCK-003',
        domain: 'Orthopedics',
        title: 'Right knee osteoarthritis Grade III with acute effusion',
        status: ClinicalCaseStatus.open,
        visitCount: 3,
        relevantHistory: 'Post-traumatic arthrosis following sports injury in 2018.',
        createdAt: DateTime(2026, 8, 15, 14, 0),
        updatedAt: DateTime(2026, 9, 7, 16, 20),
      ),
      ClinicalCase(
        caseId: 'CASE-PAT-004-01',
        patientId: 'PAT-MOCK-004',
        domain: 'Neurology',
        title: 'Refractory migraine with aura and visual disturbances',
        status: ClinicalCaseStatus.open,
        visitCount: 2,
        relevantHistory: 'Family history of migraines. No known drug allergies.',
        createdAt: DateTime(2026, 9, 2, 10, 0),
        updatedAt: DateTime(2026, 9, 6, 12, 30),
      ),
      ClinicalCase(
        caseId: 'CASE-PAT-005-01',
        patientId: 'PAT-MOCK-005',
        domain: 'Dermatology',
        title: 'Severe plaque psoriasis resistant to topical corticosteroids',
        status: ClinicalCaseStatus.open,
        visitCount: 4,
        relevantHistory: 'Psoriatic arthritis symptoms present in distal phalanges.',
        createdAt: DateTime(2026, 7, 20, 15, 0),
        updatedAt: DateTime(2026, 9, 4, 17, 10),
      ),
      ClinicalCase(
        caseId: 'CASE-102938-01',
        patientId: 'AAYU-102938',
        domain: 'Cardiology',
        title: 'Essential Hypertension Review',
        status: ClinicalCaseStatus.open,
        visitCount: 3,
        relevantHistory: 'Essential hypertension (5 yrs).',
        createdAt: DateTime(2026, 9, 3, 11, 0),
        updatedAt: DateTime(2026, 9, 8, 14, 0),
      ),
      ClinicalCase(
        caseId: 'CASE-482910-01',
        patientId: 'AAYU-482910',
        domain: 'Dermatology',
        title: 'Contact Dermatitis',
        status: ClinicalCaseStatus.open,
        visitCount: 1,
        relevantHistory: 'Atopic dermatitis, allergic rhinitis.',
        createdAt: DateTime(2026, 9, 4, 10, 0),
        updatedAt: DateTime(2026, 9, 8, 15, 0),
      ),
    ]);
    _notifyEscalatedStream();
  }

  @override
  Future<List<ClinicalCase>> getCasesForPatient(String patientId) async {
    return _cases.where((c) => c.patientId == patientId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<ClinicalCase?> getCaseById({
    required String patientId,
    required String caseId,
  }) async {
    try {
      return _cases.firstWhere(
        (c) => c.patientId == patientId && c.caseId == caseId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClinicalCase> createCase(ClinicalCase clinicalCase) async {
    _cases.add(clinicalCase);
    _notifyEscalatedStream();
    return clinicalCase;
  }

  @override
  Future<void> updateCase(ClinicalCase clinicalCase) async {
    final index = _cases.indexWhere(
      (c) => c.patientId == clinicalCase.patientId && c.caseId == clinicalCase.caseId,
    );
    if (index != -1) {
      _cases[index] = clinicalCase;
      _notifyEscalatedStream();
    }
  }

  @override
  Future<ClinicalCase> closeCase({
    required String patientId,
    required String caseId,
    required String doctorId,
    String? doctorName,
    required String closureNote,
  }) async {
    if (closureNote.trim().isEmpty) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'A non-empty closure note is required to close a clinical case.',
      );
    }

    final index = _cases.indexWhere(
      (c) => c.patientId == patientId && c.caseId == caseId,
    );
    if (index == -1) {
      throw const BackendException(
        code: BackendException.notFound,
        message: 'Clinical Case not found.',
      );
    }

    final target = _cases[index];
    if (target.isClosed) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Clinical Case is already closed.',
      );
    }

    final now = DateTime.now();
    final closedCase = target.copyWith(
      status: ClinicalCaseStatus.closed,
      closedAt: now,
      closedByDoctorId: doctorId,
      closedByDoctorName: doctorName,
      closureNote: closureNote.trim(),
      updatedAt: now,
    );

    _cases[index] = closedCase;
    _notifyEscalatedStream();
    return closedCase;
  }

  @override
  Future<ClinicalCase> escalateCase({
    required String patientId,
    required String caseId,
    required String visitId,
    required String doctorId,
    String? doctorName,
    required CaseEscalationReason reason,
    String? note,
  }) async {
    if (reason == CaseEscalationReason.other && (note == null || note.trim().isEmpty)) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'An explanation is required when selecting "Other" escalation reason.',
      );
    }

    final index = _cases.indexWhere(
      (c) => c.patientId == patientId && c.caseId == caseId,
    );
    if (index == -1) {
      throw const BackendException(
        code: BackendException.notFound,
        message: 'Clinical Case not found.',
      );
    }

    final target = _cases[index];
    if (!target.isOpen) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Cannot escalate a closed clinical case.',
      );
    }

    if (target.escalationStatus != CaseEscalationStatus.none) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'This clinical case is already escalated.',
      );
    }

    final now = DateTime.now();
    final escalatedCase = target.copyWith(
      escalationStatus: CaseEscalationStatus.escalated,
      escalationReason: reason,
      escalationNote: note?.trim(),
      escalatedAt: now,
      escalatedByDoctorId: doctorId,
      escalatedByDoctorName: doctorName,
      escalationSourceVisitId: visitId,
      updatedAt: now,
    );

    _cases[index] = escalatedCase;

    // Log audit trail
    try {
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUD-ESC-${now.millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: 'CASE_ESCALATED',
          entityType: 'CLINICAL_CASE',
          entityId: caseId,
          timestamp: now,
          metadata: {
            'caseId': caseId,
            'patientId': patientId,
            'visitId': visitId,
            'reason': reason.name,
            'note': note,
            'doctorName': doctorName,
            'department': target.domain,
          },
        ),
      );
    } catch (_) {}

    _notifyEscalatedStream();
    return escalatedCase;
  }

  @override
  Future<ClinicalCase> startAdminCaseReview({
    required String patientId,
    required String caseId,
    required String adminId,
  }) async {
    final index = _cases.indexWhere(
      (c) => c.patientId == patientId && c.caseId == caseId,
    );
    if (index == -1) {
      throw const BackendException(
        code: BackendException.notFound,
        message: 'Clinical Case not found.',
      );
    }

    final target = _cases[index];
    if (target.escalationStatus != CaseEscalationStatus.escalated) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Only pending escalated cases can be placed under review.',
      );
    }

    final now = DateTime.now();
    final underReviewCase = target.copyWith(
      escalationStatus: CaseEscalationStatus.underReview,
      adminReviewStartedAt: now,
      adminReviewStartedBy: adminId,
      updatedAt: now,
    );

    _cases[index] = underReviewCase;

    // Log audit trail
    try {
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUD-REV-${now.millisecondsSinceEpoch}',
          actorType: 'ADMIN',
          actorId: adminId,
          action: 'CASE_ESCALATION_REVIEW_STARTED',
          entityType: 'CLINICAL_CASE',
          entityId: caseId,
          timestamp: now,
          metadata: {
            'caseId': caseId,
            'patientId': patientId,
            'department': target.domain,
            'oldEscalationStatus': target.escalationStatus.name,
            'newEscalationStatus': CaseEscalationStatus.underReview.name,
          },
        ),
      );
    } catch (_) {}

    _notifyEscalatedStream();
    return underReviewCase;
  }

  @override
  Future<ClinicalCase> assignHigherAuthorityDoctor({
    required String patientId,
    required String caseId,
    required String targetDoctorId,
    required String targetDoctorName,
    required String targetDepartment,
    required String assignedByAdminId,
    String? crossDepartmentReason,
  }) async {
    final index = _cases.indexWhere(
      (c) => c.patientId == patientId && c.caseId == caseId,
    );
    if (index == -1) {
      throw const BackendException(
        code: BackendException.notFound,
        message: 'Clinical Case not found.',
      );
    }

    final targetCase = _cases[index];
    if (!targetCase.isOpen) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Cannot assign a closed clinical case.',
      );
    }

    if (targetCase.escalationStatus == CaseEscalationStatus.none) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Only escalated clinical cases can be assigned to higher authority.',
      );
    }

    if (targetCase.isAssignedToHigherAuthority) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'This case has already been assigned to a higher-authority doctor.',
      );
    }

    // Verify target doctor from DoctorRepository
    final doctorRepo = BackendProvider.instance.doctorRepository;
    final targetDocProfile = await doctorRepo.getDoctorProfileById(targetDoctorId);
    if (targetDocProfile == null) {
      throw const BackendException(
        code: BackendException.notFound,
        message: 'Selected doctor profile does not exist.',
      );
    }

    if (!targetDocProfile.isActive) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Selected doctor account is inactive.',
      );
    }

    if (targetDocProfile.availabilityStatus != DoctorAvailabilityStatus.available) {
      throw BackendException(
        code: BackendException.unavailable,
        message: targetDocProfile.availabilityStatus == DoctorAvailabilityStatus.inConsultation
            ? 'Doctor is currently in an active consultation.'
            : 'Doctor is currently offline and unavailable.',
      );
    }

    // Verify source doctor authority level
    final sourceDocId = targetCase.escalatedByDoctorId;
    int sourceAuthorityLevel = 1;
    if (sourceDocId != null && sourceDocId.isNotEmpty) {
      final sourceProfile = await doctorRepo.getDoctorProfileById(sourceDocId);
      if (sourceProfile != null) {
        sourceAuthorityLevel = sourceProfile.clinicalAuthorityLevel;
      }
    }

    if (targetDocProfile.clinicalAuthorityLevel <= sourceAuthorityLevel) {
      throw const BackendException(
        code: BackendException.permissionDenied,
        message: 'Selected doctor authority level must be strictly higher than the source doctor authority level.',
      );
    }

    if (targetDocProfile.doctorId.toUpperCase() == sourceDocId?.toUpperCase()) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Cannot assign the case back to the source doctor who escalated it.',
      );
    }

    // Department match check
    final caseDomain = targetCase.domain.replaceAll('_', ' ').trim().toLowerCase();
    final targetDept = targetDepartment.replaceAll('_', ' ').trim().toLowerCase();
    final isCrossDept = caseDomain != targetDept;
    if (isCrossDept && (crossDepartmentReason == null || crossDepartmentReason.trim().isEmpty)) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'A reason is required when assigning across different medical departments.',
      );
    }

    final now = DateTime.now();
    final assignedCase = targetCase.copyWith(
      higherAuthorityDoctorId: targetDoctorId,
      higherAuthorityDoctorName: targetDoctorName,
      higherAuthorityDepartment: targetDepartment,
      higherAuthorityAssignedAt: now,
      higherAuthorityAssignedBy: assignedByAdminId,
      higherAuthorityAssignmentStatus: HigherAuthorityAssignmentStatus.assigned,
      higherAuthorityAssignmentReason: crossDepartmentReason,
      updatedAt: now,
    );

    _cases[index] = assignedCase;

    // Log audit
    try {
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUD-HAA-${now.millisecondsSinceEpoch}',
          actorType: 'ADMIN',
          actorId: assignedByAdminId,
          action: 'HIGHER_AUTHORITY_ASSIGNED',
          entityType: 'CLINICAL_CASE',
          entityId: caseId,
          timestamp: now,
          metadata: {
            'caseId': caseId,
            'patientId': patientId,
            'sourceDoctorId': sourceDocId,
            'sourceAuthorityLevel': sourceAuthorityLevel,
            'targetDoctorId': targetDoctorId,
            'targetDoctorName': targetDoctorName,
            'targetDepartment': targetDepartment,
            'targetAuthorityLevel': targetDocProfile.clinicalAuthorityLevel,
            'isCrossDepartment': isCrossDept,
            'reason': crossDepartmentReason,
          },
        ),
      );
    } catch (_) {}

    _notifyEscalatedStream();
    return assignedCase;
  }

  @override
  Future<ClinicalCase> acceptHigherAuthorityAssignment({
    required String patientId,
    required String caseId,
    required String doctorId,
  }) async {
    final index = _cases.indexWhere(
      (c) => c.patientId == patientId && c.caseId == caseId,
    );
    if (index == -1) {
      throw const BackendException(
        code: BackendException.notFound,
        message: 'Clinical Case not found.',
      );
    }

    final targetCase = _cases[index];
    if (!targetCase.isOpen) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Cannot accept assignment for a closed clinical case.',
      );
    }

    if (targetCase.higherAuthorityDoctorId?.toUpperCase() != doctorId.toUpperCase()) {
      throw const BackendException(
        code: BackendException.permissionDenied,
        message: 'Only the assigned higher-authority doctor can accept this case.',
      );
    }

    final now = DateTime.now();
    final acceptedCase = targetCase.copyWith(
      higherAuthorityAssignmentStatus: HigherAuthorityAssignmentStatus.accepted,
      higherAuthorityAcceptedAt: now,
      updatedAt: now,
    );

    _cases[index] = acceptedCase;

    // Log audit
    try {
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUD-HAA-ACC-${now.millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: 'HIGHER_AUTHORITY_ASSIGNMENT_ACCEPTED',
          entityType: 'CLINICAL_CASE',
          entityId: caseId,
          timestamp: now,
          metadata: {
            'caseId': caseId,
            'patientId': patientId,
            'doctorId': doctorId,
          },
        ),
      );
    } catch (_) {}

    _notifyEscalatedStream();
    return acceptedCase;
  }

  Object? _mockStreamError;

  /// Sets or clears a simulated stream error for unit and widget testing.
  void setMockStreamError(Object? error) {
    _mockStreamError = error;
    if (error != null && !_escalatedStreamController.isClosed) {
      _escalatedStreamController.addError(error);
    }
  }

  @override
  Stream<List<ClinicalCase>> watchEscalatedCases() async* {
    if (_mockStreamError != null) {
      throw _mockStreamError!;
    }
    yield _cases.where((c) => c.isEscalated).toList()
      ..sort((a, b) => (b.escalatedAt ?? b.updatedAt).compareTo(a.escalatedAt ?? a.updatedAt));
    yield* _escalatedStreamController.stream;
  }

  @override
  Future<List<ClinicalCase>> getEscalatedCases() async {
    return _cases.where((c) => c.isEscalated).toList()
      ..sort((a, b) => (b.escalatedAt ?? b.updatedAt).compareTo(a.escalatedAt ?? a.updatedAt));
  }

  @override
  Future<List<ClinicalCase>> getAllCases() async {
    return List<ClinicalCase>.from(_cases)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<ClinicalCase>> getCasesForDoctor(String doctorId) async {
    final cleanDocId = doctorId.trim().toUpperCase();
    final allVisits = MockClinicalVisitRepository.instance.visits;
    final matchedCaseIds = <String>{};
    for (final v in allVisits) {
      if (v.doctorId.toUpperCase() == cleanDocId ||
          (v.completedByDoctorId?.toUpperCase() == cleanDocId)) {
        matchedCaseIds.add(v.caseId);
      }
    }
    return _cases
        .where((c) =>
            matchedCaseIds.contains(c.caseId) ||
            c.closedByDoctorId?.toUpperCase() == cleanDocId ||
            c.higherAuthorityDoctorId?.toUpperCase() == cleanDocId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<bool> isDoctorAuthorizedForCase({
    required String doctorId,
    required String caseId,
    required String patientId,
  }) async {
    final cleanDocId = doctorId.trim().toUpperCase();
    final c = await getCaseById(patientId: patientId, caseId: caseId);
    if (c == null) return false;

    if (c.closedByDoctorId?.toUpperCase() == cleanDocId) return true;
    if (c.higherAuthorityDoctorId?.toUpperCase() == cleanDocId) return true;
    if (c.escalatedByDoctorId?.toUpperCase() == cleanDocId) return true;

    final caseVisits = await MockClinicalVisitRepository.instance
        .getVisitsForCase(patientId: patientId, caseId: caseId);
    if (caseVisits.any((v) =>
        v.doctorId.toUpperCase() == cleanDocId ||
        v.completedByDoctorId?.toUpperCase() == cleanDocId ||
        v.approvedByDoctorId?.toUpperCase() == cleanDocId)) {
      return true;
    }
    return false;
  }

  int get count => _cases.length;
}
