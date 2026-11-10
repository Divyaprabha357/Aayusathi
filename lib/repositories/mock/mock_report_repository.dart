import 'dart:async';
import '../../doctor/models/report_document.dart';
import '../report_repository.dart';

/// Deterministic in-memory implementation of [ReportRepository] for
/// offline development mode (`DOCTOR_DEV_MODE=true`) and automated tests.
class MockReportRepository implements ReportRepository {
  static final MockReportRepository instance = MockReportRepository._();
  MockReportRepository._() {
    _seedDefaultData();
  }
  factory MockReportRepository() => instance;

  final Map<String, List<ReportDocument>> _storage = {};
  final Map<String, StreamController<List<ReportDocument>>> _streamControllers = {};

  String _key(String patientId, String caseId, String visitId) =>
      '${patientId.toUpperCase().trim()}:${caseId.trim()}:${visitId.trim()}';

  void _notifyVisitStream(String key) {
    final controller = _streamControllers[key];
    if (controller != null && !controller.isClosed) {
      final list = _storage[key] ?? [];
      controller.add(List<ReportDocument>.from(list));
    }
  }

  void _seedDefaultData() {
    _storage.clear();
    // Pre-seeded demo report for testing
    final defaultKey = _key('PAT-001', 'CASE-001', 'VIS-CASE-001-1');
    _storage[defaultKey] = [
      ReportDocument(
        reportId: 'REP-DEMO-001',
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
        investigationId: 'REQ-INV-001',
        fileName: 'ECG_Tracing_Report_Aarav.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 142800,
        storagePath:
            'patients/PAT-001/cases/CASE-001/visits/VIS-CASE-001-1/reports/REQ-INV-001/ECG_Tracing_Report_Aarav.pdf',
        uploadedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        uploadedByPatientId: 'PAT-001',
        reviewStatus: ReportReviewStatus.uploaded,
      ),
    ];
    for (final k in _storage.keys) {
      _notifyVisitStream(k);
    }
  }

  void reset() {
    _seedDefaultData();
  }

  void clearAll() {
    _storage.clear();
    for (final k in _streamControllers.keys) {
      _notifyVisitStream(k);
    }
  }

  @override
  Future<ReportDocument> saveReportDocument(ReportDocument report) async {
    final docId = report.reportId.isNotEmpty
        ? report.reportId
        : 'REP-${report.investigationId}-${DateTime.now().millisecondsSinceEpoch}';

    final now = DateTime.now();
    final toSave = report.copyWith(
      reportId: docId,
      uploadedAt: report.uploadedAt,
      reviewStatus: report.reviewStatus,
      createdAt: report.createdAt ?? now,
      updatedAt: now,
    );

    final key = _key(toSave.patientId, toSave.caseId, toSave.visitId);
    _storage.putIfAbsent(key, () => []);
    _storage[key]!.removeWhere((r) => r.reportId == docId);
    _storage[key]!.add(toSave);
    _notifyVisitStream(key);

    return toSave;
  }

  @override
  Future<List<ReportDocument>> getReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    final key = _key(patientId, caseId, visitId);
    final list = _storage[key] ?? [];
    return List<ReportDocument>.from(list);
  }

  @override
  Stream<List<ReportDocument>> watchReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async* {
    final key = _key(patientId, caseId, visitId);
    yield List<ReportDocument>.from(_storage[key] ?? []);
    final controller = _streamControllers.putIfAbsent(
      key,
      () => StreamController<List<ReportDocument>>.broadcast(),
    );
    yield* controller.stream;
  }


  @override
  Future<ReportDocument?> getReportById({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  }) async {
    final list = await getReportsForVisit(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
    );
    return list.cast<ReportDocument?>().firstWhere(
          (r) => r?.reportId == reportId,
          orElse: () => null,
        );
  }

  @override
  Future<ReportDocument?> getReportForInvestigation({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  }) async {
    final list = await getReportsForVisit(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
    );
    return list.cast<ReportDocument?>().firstWhere(
          (r) => r?.investigationId == investigationId,
          orElse: () => null,
        );
  }

  @override
  Future<void> updateReportStatus({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required ReportReviewStatus status,
    required String doctorId,
  }) async {
    final key = _key(patientId, caseId, visitId);
    final list = _storage[key];
    if (list != null) {
      final index = list.indexWhere((r) => r.reportId == reportId);
      if (index != -1) {
        final current = list[index];
        list[index] = current.copyWith(
          reviewStatus: status,
          reviewedAt: status == ReportReviewStatus.reviewed
              ? DateTime.now()
              : current.reviewedAt,
          reviewedByDoctorId: doctorId,
        );
        _notifyVisitStream(key);
      }
    }
  }

  @override
  Future<void> saveReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required AiReportSummaryRecord summary,
  }) async {
    final key = _key(patientId, caseId, visitId);
    final list = _storage[key];
    if (list != null) {
      final index = list.indexWhere((r) => r.reportId == reportId);
      if (index != -1) {
        final current = list[index];
        list[index] = current.copyWith(
          aiSummary: summary,
          updatedAt: DateTime.now(),
        );
        _notifyVisitStream(key);
      }
    }
  }

  @override
  Future<AiReportSummaryRecord?> getReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  }) async {
    final report = await getReportById(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      reportId: reportId,
    );
    return report?.aiSummary;
  }
}
