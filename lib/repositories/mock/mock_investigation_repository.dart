import '../../doctor/models/investigation_request.dart';
import '../investigation_repository.dart';

/// Deterministic in-memory implementation of [InvestigationRepository] for
/// offline development mode (`DOCTOR_DEV_MODE=true`) and automated tests.
class MockInvestigationRepository implements InvestigationRepository {
  static final MockInvestigationRepository instance =
      MockInvestigationRepository._();
  MockInvestigationRepository._() {
    _seedDefaultData();
  }
  factory MockInvestigationRepository() => instance;

  final Map<String, List<InvestigationRequest>> _storage = {};

  String _key(String patientId, String caseId, String visitId) =>
      '${patientId.toUpperCase().trim()}:${caseId.trim()}:${visitId.trim()}';

  void _seedDefaultData() {
    _storage.clear();
    // Default demo investigation for Aarav Sharma / Dr. Rajesh Sharma
    final defaultKey = _key('PAT-001', 'CASE-001', 'VIS-CASE-001-1');
    _storage[defaultKey] = [
      InvestigationRequest(
        requestId: 'REQ-INV-001',
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
        requestedByDoctorId: 'DOC-101',
        department: 'Cardiology',
        name: '12-Lead Electrocardiogram (ECG)',
        category: InvestigationCategory.diagnostic,
        priority: InvestigationPriority.required,
        status: InvestigationStatus.pendingUpload,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      InvestigationRequest(
        requestId: 'REQ-INV-002',
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
        requestedByDoctorId: 'DOC-101',
        department: 'Cardiology',
        name: 'Complete Blood Count (CBC) with Platelets',
        category: InvestigationCategory.lab,
        priority: InvestigationPriority.asAdvised,
        status: InvestigationStatus.pendingUpload,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ];
  }

  /// Resets mock repository to clean initial state.
  void reset() {
    _seedDefaultData();
  }

  /// Clears all stored data (empty state).
  void clearAll() {
    _storage.clear();
  }

  @override
  Future<InvestigationRequest> createInvestigationRequest(
    InvestigationRequest request,
  ) async {
    final patientId = request.patientId ?? 'PAT-001';
    final caseId = request.caseId ?? 'CASE-001';
    final visitId = request.visitId ?? 'VIS-001';

    final docId = request.requestId.isNotEmpty
        ? request.requestId
        : 'INV-$visitId-${DateTime.now().millisecondsSinceEpoch}';

    final created = request.copyWith(
      requestId: docId,
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      requestedAt: request.requestedAt,
      status: request.status,
    );

    final key = _key(patientId, caseId, visitId);
    _storage.putIfAbsent(key, () => []);
    _storage[key]!.add(created);

    return created;
  }

  @override
  Future<List<InvestigationRequest>> getInvestigationRequests({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    final key = _key(patientId, caseId, visitId);
    final list = _storage[key] ?? [];
    return List<InvestigationRequest>.from(list);
  }

  @override
  Future<InvestigationRequest?> getInvestigationById({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  }) async {
    final list = await getInvestigationRequests(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
    );
    return list.cast<InvestigationRequest?>().firstWhere(
          (req) => req?.requestId == investigationId,
          orElse: () => null,
        );
  }

  @override
  Future<void> updateInvestigationStatus({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required InvestigationStatus status,
    String? doctorId,
    String? reportId,
  }) async {
    final key = _key(patientId, caseId, visitId);
    final list = _storage[key];
    if (list != null) {
      final index = list.indexWhere((r) => r.requestId == investigationId);
      if (index != -1) {
        final current = list[index];
        list[index] = current.copyWith(
          status: status,
          uploadedAt: status == InvestigationStatus.uploaded
              ? (current.uploadedAt ?? DateTime.now())
              : current.uploadedAt,
          uploadedReportId: reportId ?? current.uploadedReportId,
          reviewedAt: status == InvestigationStatus.reviewed
              ? DateTime.now()
              : current.reviewedAt,
          reviewedByDoctorId: doctorId ?? current.reviewedByDoctorId,
        );
      }
    }
  }

  @override
  Future<void> markUploaded({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String reportId,
  }) async {
    await updateInvestigationStatus(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      status: InvestigationStatus.uploaded,
      reportId: reportId,
    );
  }

  @override
  Future<void> markReviewed({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String doctorId,
  }) async {
    await updateInvestigationStatus(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      status: InvestigationStatus.reviewed,
      doctorId: doctorId,
    );
  }

  @override
  Future<void> deleteInvestigation({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  }) async {
    final key = _key(patientId, caseId, visitId);
    _storage[key]?.removeWhere((r) => r.requestId == investigationId);
  }
}
