import '../../doctor/models/clinical_visit.dart';
import '../../doctor/models/investigation_request.dart';
import '../../models/vital_reading.dart';
import '../clinical_visit_repository.dart';
import 'mock_case_repository.dart';

/// In-memory mock implementation of [ClinicalVisitRepository].
///
/// Implements case-scoped sequential visit numbering and duplicate prevention.
class MockClinicalVisitRepository implements ClinicalVisitRepository {
  static final MockClinicalVisitRepository instance = MockClinicalVisitRepository._();
  MockClinicalVisitRepository._() {
    resetToDefaults();
  }
  factory MockClinicalVisitRepository() => instance;

  final List<ClinicalVisit> _visits = [];
  bool simulateCompletionError = false;

  void resetToDefaults() {
    simulateCompletionError = false;
    _visits.clear();
    _visits.addAll([
      ClinicalVisit(
        visitId: 'VIS-PAT-001-01-1',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        doctorQualification: 'MBBS, MD (Cardiology)',
        appointmentId: 'APT-MOCK-PAST-1',
        visitNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(days: 14)),
        completedAt: DateTime.now().subtract(const Duration(days: 14, hours: -1)),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Chest tightness and shortness of breath during exertion.',
        onsetDuration: '2 weeks, worsening on climbing stairs.',
        associatedSymptoms: 'Mild palpitations, occasional dizziness.',
        medicalHistory: 'Known hypertension for 5 years, non-smoker.',
        currentMedication: 'Amlodipine 5mg OD, Telmisartan 40mg OD.',
        clinicalObservations: 'BP 148/92 mmHg, S1 S2 normal, no murmur.',
        assessment: 'Uncontrolled Stage 1 Essential Hypertension with exertional dyspnea.',
        plan: 'Adjust antihypertensive regimen, request 12-lead ECG and Lipid Profile.',
        summary: 'Initial consultation for elevated blood pressure and exertional dyspnea.',
        summaryText: 'Initial consultation for elevated blood pressure and exertional dyspnea.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-101',
        approvedAt: DateTime.now().subtract(const Duration(days: 14, hours: -1)),
        followUp: 'Review in 2 weeks with ECG and Lipid profile results.',
        patientInstructions: 'Low sodium diet, daily 30-minute light walk, log BP daily.',
        investigationRequests: [
          InvestigationRequest(
            requestId: 'REQ-INV-001',
            name: '12-Lead Electrocardiogram (ECG)',
            priority: InvestigationPriority.required,
            status: InvestigationStatus.uploaded,
            requestedAt: DateTime.now().subtract(const Duration(days: 14)),
          ),
          InvestigationRequest(
            requestId: 'REQ-INV-002',
            name: 'Comprehensive Lipid Profile',
            priority: InvestigationPriority.required,
            status: InvestigationStatus.uploaded,
            requestedAt: DateTime.now().subtract(const Duration(days: 14)),
          ),
        ],
      ),
      ClinicalVisit(
        visitId: 'VIS-PAT-001-01-2',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        doctorQualification: 'MBBS, MD (Cardiology)',
        appointmentId: 'APT-MOCK-PAST-2',
        visitNumber: 2,
        startedAt: DateTime.now().subtract(const Duration(days: 7)),
        completedAt: DateTime.now().subtract(const Duration(days: 7, hours: -1)),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Follow-up on blood pressure control and ECG review.',
        onsetDuration: 'Ongoing 1 week follow-up.',
        associatedSymptoms: 'Exertional dyspnea significantly reduced.',
        medicalHistory: 'Hypertension managed.',
        currentMedication: 'Telmisartan 40mg + Amlodipine 5mg combination OD.',
        clinicalObservations: 'BP 128/82 mmHg, HR 74 bpm regular.',
        assessment: 'Hypertension well controlled on current regimen. ECG sinus rhythm.',
        plan: 'Continue present medication, order routine 2D Echo.',
        summary: 'Follow-up consultation. Medication tolerability good.',
        summaryText: 'Follow-up consultation. Medication tolerability good.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-101',
        approvedAt: DateTime.now().subtract(const Duration(days: 7, hours: -1)),
        followUp: 'Routine follow-up in 1 month.',
        patientInstructions: 'Continue regular medication without skipping doses.',
        investigationRequests: [
          InvestigationRequest(
            requestId: 'REQ-INV-003',
            name: '2D Echocardiography',
            priority: InvestigationPriority.asAdvised,
            status: InvestigationStatus.pendingUpload,
            requestedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ],
      ),
      ClinicalVisit(
        visitId: 'VIS-PAT-001-02-1',
        caseId: 'CASE-PAT-001-02',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-103',
        doctorName: 'Dr. Sneha Joshi',
        doctorQualification: 'MBBS, MS (Orthopedics)',
        appointmentId: 'APT-MOCK-PAST-3',
        visitNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(days: 45)),
        completedAt: DateTime.now().subtract(const Duration(days: 45, hours: -1)),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Right knee pain after twisting injury.',
        onsetDuration: '3 days.',
        associatedSymptoms: 'Mild swelling over medial joint line.',
        medicalHistory: 'No prior knee surgery.',
        currentMedication: 'Paracetamol 650mg SOS.',
        clinicalObservations: 'No ligamentous instability, McMurray test negative.',
        assessment: 'Grade 1 medial collateral ligament sprain.',
        plan: 'Knee brace for 10 days, ice pack application, analgesics.',
        summary: 'Right knee sprain assessment. Conservative management advised.',
        summaryText: 'Right knee sprain assessment. Conservative management advised.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-103',
        approvedAt: DateTime.now().subtract(const Duration(days: 45, hours: -1)),
        followUp: 'Review if pain persists after 2 weeks.',
        patientInstructions: 'Avoid squatting and heavy weight bearing for 10 days.',
      ),
      ClinicalVisit(
        visitId: 'VIS-102938-01-1',
        caseId: 'CASE-102938-01',
        patientId: 'AAYU-102938',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        doctorQualification: 'MBBS, MD (Cardiology)',
        appointmentId: 'APT-102938-1',
        visitNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(days: 30)),
        completedAt: DateTime.now().subtract(const Duration(days: 30, hours: -1)),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'General health checkup and blood pressure evaluation.',
        onsetDuration: 'Routine baseline evaluation.',
        associatedSymptoms: 'None reported.',
        medicalHistory: 'No chronic illnesses.',
        currentMedication: 'None.',
        clinicalObservations: 'BP 122/80 mmHg, HR 72 bpm, BMI 23.4.',
        assessment: 'Normal clinical evaluation, normotensive.',
        plan: 'Annual routine health checkup recommended.',
        summary: 'Routine hypertension checkup.',
        summaryText: 'Routine hypertension checkup.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-101',
        approvedAt: DateTime.now().subtract(const Duration(days: 30, hours: -1)),
        followUp: 'Annual review.',
        patientInstructions: 'Maintain balanced diet and regular physical activity.',
      ),
      ClinicalVisit(
        visitId: 'VIS-102938-01-2',
        caseId: 'CASE-102938-01',
        patientId: 'AAYU-102938',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        doctorQualification: 'MBBS, MD (Cardiology)',
        appointmentId: 'APT-102938-2',
        visitNumber: 2,
        startedAt: DateTime.now().subtract(const Duration(days: 10)),
        completedAt: DateTime.now().subtract(const Duration(days: 10, hours: -1)),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Routine follow-up evaluation.',
        onsetDuration: 'As scheduled.',
        associatedSymptoms: 'None.',
        medicalHistory: 'Normal baseline.',
        currentMedication: 'None.',
        clinicalObservations: 'BP 120/78 mmHg, clear chest.',
        assessment: 'Stable and healthy cardiovascular parameters.',
        plan: 'Continue healthy lifestyle.',
        summary: 'Follow-up evaluation. Blood pressure within normal range.',
        summaryText: 'Follow-up evaluation. Blood pressure within normal range.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-101',
        approvedAt: DateTime.now().subtract(const Duration(days: 10, hours: -1)),
        followUp: 'Annual checkup.',
        patientInstructions: 'Maintain regular hydration and sleep cycle.',
      ),
      ClinicalVisit(
        visitId: 'VIS-482910-01-1',
        caseId: 'CASE-482910-01',
        patientId: 'AAYU-482910',
        doctorId: 'DOC-102',
        doctorName: 'Dr. Ananya Sen',
        doctorQualification: 'MBBS, MD (Dermatology)',
        appointmentId: 'APT-482910-1',
        visitNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(days: 5)),
        completedAt: DateTime.now().subtract(const Duration(days: 5, hours: -1)),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Erythematous itchy patch on left forearm.',
        onsetDuration: '5 days.',
        associatedSymptoms: 'Mild burning sensation.',
        medicalHistory: 'History of allergic contact dermatitis.',
        currentMedication: 'None.',
        clinicalObservations: 'Localized maculopapular rash, no secondary infection.',
        assessment: 'Acute Contact Dermatitis.',
        plan: 'Topical hydrocortisone 1% cream, oral antihistamines.',
        summary: 'Contact dermatitis on left forearm. Topical therapy initiated.',
        summaryText: 'Contact dermatitis on left forearm. Topical therapy initiated.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: 'DOC-102',
        approvedAt: DateTime.now().subtract(const Duration(days: 5, hours: -1)),
        followUp: 'Review after 1 week if no improvement.',
        patientInstructions: 'Avoid contact with harsh detergents and soaps.',
      ),
    ]);
  }

  @override
  Future<List<ClinicalVisit>> getVisitsForCase({
    required String patientId,
    required String caseId,
  }) async {
    final cleanPatient = patientId.trim().toUpperCase();
    return _visits
        .where(
          (v) =>
              v.patientId.toUpperCase() == cleanPatient &&
              v.caseId == caseId,
        )
        .toList()
      ..sort((a, b) => a.visitNumber.compareTo(b.visitNumber));
  }

  @override
  Future<ClinicalVisit?> getVisitById({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    final cleanPatient = patientId.trim().toUpperCase();
    try {
      return _visits.firstWhere(
        (v) =>
            v.patientId.toUpperCase() == cleanPatient &&
            v.caseId == caseId &&
            v.visitId == visitId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> getNextVisitNumber({
    required String patientId,
    required String caseId,
  }) async {
    final caseVisits = await getVisitsForCase(patientId: patientId, caseId: caseId);
    if (caseVisits.isEmpty) return 1;
    final maxNumber = caseVisits
        .map((v) => v.visitNumber)
        .reduce((curr, next) => curr > next ? curr : next);
    return maxNumber + 1;
  }

  @override
  Future<ClinicalVisit?> getActiveVisitForCase({
    required String patientId,
    required String caseId,
  }) async {
    final visits = await getVisitsForCase(patientId: patientId, caseId: caseId);
    try {
      return visits.firstWhere((v) => v.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClinicalVisit> createNextVisit({
    required String patientId,
    required String caseId,
    required String doctorId,
    required String doctorName,
    String? doctorQualification,
    String? appointmentId,
    String? chiefComplaint,
    VitalReading? vitals,
    String? department,
  }) async {
    final activeVisit = await getActiveVisitForCase(
      patientId: patientId,
      caseId: caseId,
    );
    if (activeVisit != null) {
      throw StateError(
        'An active consultation already exists for this Case.',
      );
    }

    final nextNumber = await getNextVisitNumber(
      patientId: patientId,
      caseId: caseId,
    );

    String? resolvedDept = department;
    if (resolvedDept == null || resolvedDept.trim().isEmpty) {
      try {
        final c = await MockCaseRepository.instance.getCaseById(
          patientId: patientId,
          caseId: caseId,
        );
        if (c != null && c.domain.trim().isNotEmpty) {
          resolvedDept = c.domain;
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    final newVisit = ClinicalVisit(
      visitId: 'VIS-$caseId-$nextNumber-${now.millisecondsSinceEpoch}',
      caseId: caseId,
      patientId: patientId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorQualification: doctorQualification,
      appointmentId: appointmentId,
      department: resolvedDept,
      visitNumber: nextNumber,
      startedAt: now,
      status: ClinicalVisitStatus.active,
      chiefComplaint: chiefComplaint ?? '',
      vitals: vitals,
    );

    _visits.add(newVisit);
    return newVisit;
  }

  @override
  Future<ClinicalVisit> createVisit(ClinicalVisit visit) async {
    // 1. Scoped numbering: compute next if not specified or check duplicate
    final caseVisits = await getVisitsForCase(
      patientId: visit.patientId,
      caseId: visit.caseId,
    );

    int computedNumber = visit.visitNumber;
    if (caseVisits.any((v) => v.visitNumber == computedNumber)) {
      // Auto increment to prevent duplicate visit numbers within the same case
      final maxNum = caseVisits
          .map((v) => v.visitNumber)
          .reduce((curr, next) => curr > next ? curr : next);
      computedNumber = maxNum + 1;
    }

    final newVisit = visit.copyWith(
      visitId: visit.visitId.isNotEmpty
          ? visit.visitId
          : 'VIS-${visit.caseId}-$computedNumber-${DateTime.now().millisecondsSinceEpoch}',
      visitNumber: computedNumber,
      startedAt: visit.startedAt,
      status: visit.status,
    );

    _visits.add(newVisit);
    return newVisit;
  }

  @override
  Future<void> updateVisit(ClinicalVisit visit) async {
    final index = _visits.indexWhere((v) => v.visitId == visit.visitId);
    if (index != -1) {
      _visits[index] = visit;
    } else {
      _visits.add(visit);
    }
  }

  @override
  Future<ClinicalVisit> completeVisit({
    required String patientId,
    required String caseId,
    required String visitId,
    required String doctorId,
  }) async {
    if (simulateCompletionError) {
      throw Exception('Simulated database error during visit completion.');
    }

    final cleanPatient = patientId.trim().toUpperCase();
    final index = _visits.indexWhere(
      (v) =>
          v.patientId.toUpperCase() == cleanPatient &&
          v.caseId == caseId &&
          v.visitId == visitId,
    );

    if (index == -1) {
      throw Exception('Consultation visit $visitId not found.');
    }

    final current = _visits[index];
    if (current.status != ClinicalVisitStatus.active) {
      throw Exception('Only active visits can be completed.');
    }

    final completed = current.copyWith(
      status: ClinicalVisitStatus.completed,
      completedAt: DateTime.now(),
      completedByDoctorId: doctorId,
    );

    _visits[index] = completed;
    return completed;
  }

  int get count => _visits.length;
  List<ClinicalVisit> get visits => List.unmodifiable(_visits);
}
