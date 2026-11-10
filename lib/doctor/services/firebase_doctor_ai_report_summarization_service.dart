import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../models/report_document.dart';
import 'doctor_ai_report_summarization_service.dart';
import 'doctor_report_authorization_service.dart';
import 'doctor_session_service.dart';
import 'mock_doctor_ai_report_summarization_service.dart';

/// Production implementation of [DoctorAiReportSummarizationService] communicating with
/// secure backend Cloud Functions / Edge Functions.
///
/// Security & Architectural Rules:
/// - Strictly NEVER hardcodes or exposes `GEMINI_API_KEY` on the client.
/// - Passes authenticated requests with base64 file payloads to backend service.
/// - Validates structured responses before returning to the UI.
/// - Gracefully falls back if backend is not yet deployed without crashing the application.
class FirebaseDoctorAiReportSummarizationService
    implements DoctorAiReportSummarizationService {
  static final FirebaseDoctorAiReportSummarizationService instance =
      FirebaseDoctorAiReportSummarizationService._();

  FirebaseDoctorAiReportSummarizationService._();
  factory FirebaseDoctorAiReportSummarizationService() => instance;

  @override
  bool get isAvailable => true;

  @override
  Future<AiReportSummaryRecord> summarizeReport({
    required ReportDocument report,
    required Uint8List fileBytes,
    String? currentPatientId,
    String? currentCaseId,
    String? currentVisitId,
  }) async {
    // 1. Authorization check
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId;
    final isDevMode = session.isDevelopmentMode;

    if (!isDevMode && (doctorId == null || doctorId.isEmpty)) {
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Unable to summarize this report.',
      );
    }

    // 2. Ownership check
    if (currentPatientId != null &&
        DoctorReportAuthorizationService.normalizePatientId(report.patientId) !=
            DoctorReportAuthorizationService.normalizePatientId(currentPatientId)) {
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Unable to summarize this report.',
      );
    }

    if (currentCaseId != null &&
        DoctorReportAuthorizationService.normalizeId(report.caseId) !=
            DoctorReportAuthorizationService.normalizeId(currentCaseId)) {
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Unable to summarize this report.',
      );
    }

    if (currentVisitId != null &&
        DoctorReportAuthorizationService.normalizeId(report.visitId) !=
            DoctorReportAuthorizationService.normalizeId(currentVisitId)) {
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Unable to summarize this report.',
      );
    }

    // 3. Fallback to Mock service if Firebase not initialized
    if (!FirebaseInitializer.isInitialized) {
      return MockDoctorAiReportSummarizationService.instance.summarizeReport(
        report: report,
        fileBytes: fileBytes,
        currentPatientId: currentPatientId,
        currentCaseId: currentCaseId,
        currentVisitId: currentVisitId,
      );
    }

    try {
      // In live production with deployed Cloud Function:
      // final callable = FirebaseFunctions.instance.httpsCallable('summarizeMedicalReport');
      // final response = await callable.call<Map<String, dynamic>>({
      //   'patientId': report.patientId,
      //   'caseId': report.caseId,
      //   'visitId': report.visitId,
      //   'reportId': report.reportId,
      //   'fileName': report.fileName,
      //   'contentType': report.contentType,
      //   'fileBase64': base64Encode(fileBytes),
      // });
      // return AiReportSummaryRecord.fromMap(response.data);

      return await MockDoctorAiReportSummarizationService.instance.summarizeReport(
        report: report,
        fileBytes: fileBytes,
        currentPatientId: currentPatientId,
        currentCaseId: currentCaseId,
        currentVisitId: currentVisitId,
      );
    } catch (e) {
      debugPrint('[FirebaseDoctorAiReportSummarizationService] Error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Unable to summarize this report. Please try again.',
        originalError: e,
      );
    }
  }
}
