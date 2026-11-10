import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../../models/audit_log.dart';
import '../models/report_document.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_buttons.dart';
import 'doctor_report_authorization_service.dart';
import 'doctor_session_service.dart';
import 'firebase_doctor_ai_report_summarization_service.dart';
import 'mock_doctor_ai_report_summarization_service.dart';

/// Legacy alias for backward compatibility.
typedef AiReportSummaryResult = AiReportSummaryRecord;

/// Strict medical document summarization prompt and guidelines (Sections 9, 10–14).
class DoctorAiReportPrompts {
  static const String systemInstruction = '''
You are an AI medical report summarization assistant for authorized healthcare professionals.
Analyze ONLY the information contained in the uploaded medical report.
Do not invent values, findings, reference ranges, diagnoses, medication, or treatment.
Clearly distinguish reported findings from any explanatory wording.
Summarize the document accurately and conservatively.
If information is unreadable, missing, ambiguous, or unavailable, say so.
Do not make treatment recommendations.
Do not independently diagnose the patient.
The Doctor is responsible for clinical interpretation.
''';
}

/// Abstract contract for AI-assisted diagnostic report summarization (Phase D16).
///
/// Features & Rules:
/// - Reuses established Gemini service architecture.
/// - Never exposes Gemini API keys on the Flutter client.
/// - Prioritizes [MockDoctorAiReportSummarizationService] in Development Mode (`isDevelopmentMode`).
/// - Uses [FirebaseDoctorAiReportSummarizationService] in Firebase production mode.
abstract class DoctorAiReportSummarizationService {
  static DoctorAiReportSummarizationService? _customInstance;

  /// Sets custom service override for testing.
  static set instance(DoctorAiReportSummarizationService? service) {
    _customInstance = service;
  }

  /// Resolves the active AI summarization service based on session and backend mode.
  static DoctorAiReportSummarizationService get instance {
    if (_customInstance != null) return _customInstance!;

    if (DoctorSessionService.instance.isDevelopmentMode) {
      return MockDoctorAiReportSummarizationService.instance;
    }

    if (BackendProvider.instance.isFirebaseMode &&
        FirebaseInitializer.isInitialized) {
      return FirebaseDoctorAiReportSummarizationService.instance;
    }

    return MockDoctorAiReportSummarizationService.instance;
  }

  /// Whether the AI summarization engine is connected and ready.
  bool get isAvailable;

  /// Analyzes the actual report document file and generates a structured clinical summary.
  Future<AiReportSummaryRecord> summarizeReport({
    required ReportDocument report,
    required Uint8List fileBytes,
    String? currentPatientId,
    String? currentCaseId,
    String? currentVisitId,
  });
}

/// Interactive Doctor Modal Dialog for AI Report Summarization.
///
/// Features:
/// - Enforces doctor authentication and ownership verification before processing.
/// - Displays structured clinical summary with prominent safety disclaimer.
/// - Provides complete Doctor Review, Edit, Approve, and Regenerate workflows.
/// - Persists approved summaries to Cloud Firestore / ReportRepository.
/// - Emits privacy-compliant audit logs for all lifecycle actions.
class DoctorAiReportSummaryDialog extends StatefulWidget {
  final ReportDocument report;
  final String? currentPatientId;
  final String? currentCaseId;
  final String? currentVisitId;
  final Uint8List? preloadedFileBytes;

  const DoctorAiReportSummaryDialog({
    super.key,
    required this.report,
    this.currentPatientId,
    this.currentCaseId,
    this.currentVisitId,
    this.preloadedFileBytes,
  });

  static Future<void> show(
    BuildContext context,
    ReportDocument report, {
    String? currentPatientId,
    String? currentCaseId,
    String? currentVisitId,
    Uint8List? preloadedFileBytes,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DoctorAiReportSummaryDialog(
        report: report,
        currentPatientId: currentPatientId ?? report.patientId,
        currentCaseId: currentCaseId ?? report.caseId,
        currentVisitId: currentVisitId ?? report.visitId,
        preloadedFileBytes: preloadedFileBytes,
      ),
    );
  }

  @override
  State<DoctorAiReportSummaryDialog> createState() =>
      _DoctorAiReportSummaryDialogState();
}

class _DoctorAiReportSummaryDialogState
    extends State<DoctorAiReportSummaryDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  AiReportSummaryRecord? _summary;
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _initializeSummaryState();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _initializeSummaryState() {
    // 1. Ownership & Authorization check
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId;
    final isDevMode = session.isDevelopmentMode;

    if (!isDevMode && (doctorId == null || doctorId.isEmpty)) {
      setState(() {
        _errorMessage = 'Unable to summarize this report.';
      });
      return;
    }

    if (widget.currentPatientId != null &&
        DoctorReportAuthorizationService.normalizePatientId(widget.report.patientId) !=
            DoctorReportAuthorizationService.normalizePatientId(widget.currentPatientId)) {
      setState(() {
        _errorMessage = 'Unable to summarize this report.';
      });
      return;
    }

    if (widget.currentCaseId != null &&
        DoctorReportAuthorizationService.normalizeId(widget.report.caseId) !=
            DoctorReportAuthorizationService.normalizeId(widget.currentCaseId)) {
      setState(() {
        _errorMessage = 'Unable to summarize this report.';
      });
      return;
    }

    if (widget.currentVisitId != null &&
        DoctorReportAuthorizationService.normalizeId(widget.report.visitId) !=
            DoctorReportAuthorizationService.normalizeId(widget.currentVisitId)) {
      setState(() {
        _errorMessage = 'Unable to summarize this report.';
      });
      return;
    }

    // 2. Check if report already has an AI summary
    if (widget.report.aiSummary != null) {
      setState(() {
        _summary = widget.report.aiSummary;
        _editController.text = _summary!.rawSummaryText;
      });
      return;
    }

    // 3. Check repository or auto-generate
    _fetchOrGenerate();
  }

  Future<void> _fetchOrGenerate() async {
    AiReportSummaryRecord? existing = widget.report.aiSummary;
    if (existing == null) {
      final repo = BackendProvider.instance.reportRepository;
      existing = await repo.getReportAiSummary(
        patientId: widget.report.patientId,
        caseId: widget.report.caseId,
        visitId: widget.report.visitId,
        reportId: widget.report.reportId,
      );
    }

    final record = existing;
    if (record != null && mounted) {
      setState(() {
        _summary = record;
        _editController.text = record.rawSummaryText.isNotEmpty
            ? record.rawSummaryText
            : record.toFormattedDisplayString();
      });
      return;
    }

    await _generateSummary();
  }

  Future<void> _recordAudit(String action) async {
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-DEV';
    final audit = AuditLog(
      auditId: 'AUD-AI-${DateTime.now().millisecondsSinceEpoch}',
      actorType: 'DOCTOR',
      actorId: doctorId,
      action: action,
      entityType: 'REPORT',
      entityId: widget.report.reportId,
      timestamp: DateTime.now(),
      metadata: {
        'patientId': widget.report.patientId,
        'caseId': widget.report.caseId,
        'visitId': widget.report.visitId,
        'investigationId': widget.report.investigationId,
      },
    );
    try {
      await BackendProvider.instance.auditRepository.logEvent(audit);
    } catch (_) {}
  }

  Future<void> _generateSummary() async {
    if (_isLoading) return; // Prevent duplicate requests

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isEditing = false;
    });

    await _recordAudit('AI_REPORT_SUMMARY_REQUESTED');

    try {
      // Retrieve actual file bytes
      Uint8List? bytes = widget.preloadedFileBytes;
      if (bytes == null || bytes.isEmpty) {
        bytes = await BackendProvider.instance.storageService
            .getFileBytes(widget.report.storagePath);
      }

      if (bytes == null || bytes.isEmpty) {
        throw BackendException(
          code: 'FILE_EMPTY',
          message: 'Unable to summarize this report. Please try again.',
        );
      }

      final result = await DoctorAiReportSummarizationService.instance
          .summarizeReport(
        report: widget.report,
        fileBytes: bytes,
        currentPatientId: widget.currentPatientId,
        currentCaseId: widget.currentCaseId,
        currentVisitId: widget.currentVisitId,
      );

      if (mounted) {
        setState(() {
          _summary = result;
          _editController.text = result.rawSummaryText;
          _isLoading = false;
        });
        await _recordAudit('AI_REPORT_SUMMARY_GENERATED');
      }
    } catch (e) {
      debugPrint('[DoctorAiReportSummaryDialog] Error summarizing: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is BackendException) {
            _errorMessage = e.message;
          } else {
            _errorMessage =
                'Unable to summarize this report. Please try again.';
          }
        });
        await _recordAudit('AI_REPORT_SUMMARY_FAILED');
      }
    }
  }

  Future<void> _handleApprove() async {
    if (_summary == null) return;
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-DEV';

    final approved = _summary!.copyWith(
      status: AiReportSummaryStatus.approvedByDoctor,
      approvedByDoctorId: doctorId,
      approvedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _summary = approved;
      _isEditing = false;
    });

    try {
      await BackendProvider.instance.reportRepository.saveReportAiSummary(
        patientId: widget.report.patientId,
        caseId: widget.report.caseId,
        visitId: widget.report.visitId,
        reportId: widget.report.reportId,
        summary: approved,
      );
      await _recordAudit('AI_REPORT_SUMMARY_APPROVED');

      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('AI summary approved and saved by doctor.'),
            backgroundColor: DoctorColors.brandTeal,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DoctorAiReportSummaryDialog] Error saving summary: $e');
    }
  }

  Future<void> _handleSaveEdit() async {
    if (_summary == null) return;
    final editedText = _editController.text.trim();

    final updated = _summary!.copyWith(
      rawSummaryText: editedText,
      status: AiReportSummaryStatus.reviewRequired,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _summary = updated;
      _isEditing = false;
    });

    await _recordAudit('AI_REPORT_SUMMARY_EDITED');

    try {
      await BackendProvider.instance.reportRepository.saveReportAiSummary(
        patientId: widget.report.patientId,
        caseId: widget.report.caseId,
        visitId: widget.report.visitId,
        reportId: widget.report.reportId,
        summary: updated,
      );
    } catch (_) {}
  }

  Future<void> _confirmAndRegenerate() async {
    if (_summary?.isApproved == true) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DoctorTheme.radius12),
          ),
          title: const Text(
            'Regenerate AI Summary?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: DoctorColors.brandNavy,
            ),
          ),
          content: const Text(
            'Regenerating will replace the approved summary and reset its status to REVIEW REQUIRED. Do you wish to continue?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            DoctorPrimaryButton(
              label: 'Regenerate',
              onPressed: () => Navigator.of(ctx).pop(true),
              height: 36,
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await _generateSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DoctorTheme.space20),
                child: _buildBody(),
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space24,
        vertical: DoctorTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: DoctorColors.brandNavy,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DoctorTheme.radius16),
          topRight: Radius.circular(DoctorTheme.radius16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: DoctorColors.brandOrange,
            size: 22,
          ),
          const SizedBox(width: DoctorTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Report Summary Assistant',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.report.fileName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: DoctorColors.brandTeal),
              SizedBox(height: 16),
              Text(
                'Analyzing report...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DoctorColors.brandNavy,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Extracting findings safely without autonomous diagnosis...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: DoctorColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DoctorColors.statusCritical.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
          border: Border.all(color: DoctorColors.statusCritical.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: DoctorColors.statusCritical, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: DoctorColors.statusCritical,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != 'Unable to summarize this report.')
                    DoctorSecondaryButton(
                      label: 'Retry Analysis',
                      icon: Icons.refresh_rounded,
                      onPressed: _generateSummary,
                      height: 32,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_summary != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Safety Banner
          _buildSafetyBanner(),
          const SizedBox(height: DoctorTheme.space16),

          // Status & Review Strip
          _buildStatusStrip(),
          const SizedBox(height: DoctorTheme.space16),

          // Edit View vs Formatted View
          if (_isEditing) _buildEditView() else _buildStructuredSummary(),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.brandOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(
          color: DoctorColors.brandOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.verified_user_outlined,
            color: DoctorColors.brandOrange,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-generated summary — Doctor verification required.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: DoctorColors.brandNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'AI assistance strictly provides documentation structure (Key Findings, Reported Measurements, Review Items) and never diagnoses or prescribes treatment.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: DoctorColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip() {
    final isApproved = _summary?.isApproved == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isApproved
            ? DoctorColors.brandTeal.withValues(alpha: 0.08)
            : DoctorColors.brandOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(
          color: isApproved
              ? DoctorColors.brandTeal.withValues(alpha: 0.3)
              : DoctorColors.brandOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? DoctorColors.brandTeal : DoctorColors.brandOrange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isApproved ? 'APPROVED BY DOCTOR' : 'REVIEW REQUIRED',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isApproved
                  ? 'Approved by Dr. ${_summary?.approvedByDoctorId ?? "Physician"}'
                  : 'Pending physician verification and sign-off.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: isApproved
                    ? DoctorColors.brandTeal
                    : DoctorColors.brandNavy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredSummary() {
    final s = _summary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Doctor Edits / Notes (if edited by doctor)
        if (s.rawSummaryText.isNotEmpty && s.updatedAt != null) ...[
          _buildSectionTitle('DOCTOR EDITS / CLINICAL NOTES'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DoctorColors.brandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              border: Border.all(color: DoctorColors.brandTeal.withValues(alpha: 0.3)),
            ),
            child: Text(
              s.rawSummaryText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: DoctorColors.brandNavy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),
        ],

        // 1. REPORT OVERVIEW
        _buildSectionTitle('1. REPORT OVERVIEW'),
        Text(
          s.reportOverview,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            height: 1.5,
            color: DoctorColors.brandNavy,
          ),
        ),
        const SizedBox(height: DoctorTheme.space16),

        // 2. KEY FINDINGS
        _buildSectionTitle('2. KEY FINDINGS'),
        if (s.keyFindings.isEmpty)
          const Text(
            'No specific findings explicitly noted.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: Colors.grey),
          )
        else
          ...s.keyFindings.map((f) => _buildBullet(f)),
        const SizedBox(height: DoctorTheme.space16),

        // 3. REPORTED MEASUREMENTS
        if (s.reportedMeasurements.isNotEmpty) ...[
          _buildSectionTitle('3. REPORTED MEASUREMENTS'),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: DoctorColors.border),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: DoctorColors.background,
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('Parameter',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Value / Unit',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text('Reference Range',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                ...s.reportedMeasurements.map((m) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: DoctorColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              m.parameter,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  '${m.value} ${m.unit}'.trim(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (m.flag != null && m.flag!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: DoctorColors.brandOrange
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      m.flag!,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: DoctorColors.brandOrange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              m.referenceRange.isNotEmpty
                                  ? m.referenceRange
                                  : '--',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: DoctorColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),
        ],

        // 4. REPORTED FINDINGS
        if (s.reportedFindings.isNotEmpty) ...[
          _buildSectionTitle('4. REPORTED FINDINGS'),
          ...s.reportedFindings.map((f) => _buildBullet(f)),
          const SizedBox(height: DoctorTheme.space16),
        ],

        // 5. REPORTED IMPRESSION / CONCLUSION
        _buildSectionTitle('5. REPORTED IMPRESSION / CONCLUSION'),
        Text(
          s.reportedImpression.isNotEmpty
              ? s.reportedImpression
              : 'No separate impression section reported.',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            height: 1.4,
            color: DoctorColors.brandNavy,
          ),
        ),
        const SizedBox(height: DoctorTheme.space16),

        // 6. ITEMS TO REVIEW
        _buildSectionTitle('6. ITEMS TO REVIEW'),
        if (s.itemsToReview.isEmpty)
          const Text('No flagged review items.',
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, color: Colors.grey))
        else
          ...s.itemsToReview.map((r) => _buildBullet(r, isAlert: true)),
        const SizedBox(height: DoctorTheme.space16),

        // 7. DATA QUALITY / UNCERTAINTY
        _buildSectionTitle('7. DATA QUALITY / UNCERTAINTY'),
        if (s.dataQualityOrUncertainty.isEmpty)
          const Text('None reported.',
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, color: Colors.grey))
        else
          ...s.dataQualityOrUncertainty.map((dq) => _buildBullet(dq)),
      ],
    );
  }

  Widget _buildEditView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Summary (Doctor Documentation Mode)',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: DoctorColors.brandNavy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Modify or add clinical notes. The status remains REVIEW REQUIRED until explicitly approved.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: DoctorColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _editController,
          maxLines: 14,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            hintText: 'Edit summary content...',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _editController.text = _summary?.rawSummaryText ?? '';
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            DoctorPrimaryButton(
              label: 'SAVE CHANGES',
              onPressed: _handleSaveEdit,
              height: 36,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: DoctorColors.brandNavy,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildBullet(String text, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAlert ? Icons.flag_outlined : Icons.circle,
            size: isAlert ? 15 : 6,
            color: isAlert ? DoctorColors.brandOrange : DoctorColors.brandTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                height: 1.4,
                color: isAlert ? DoctorColors.brandNavy : DoctorColors.brandNavy,
                fontWeight: isAlert ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: const BoxDecoration(
        color: DoctorColors.background,
        border: Border(top: BorderSide(color: DoctorColors.border)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DoctorTheme.radius16),
          bottomRight: Radius.circular(DoctorTheme.radius16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),

          // Actions
          if (_summary != null && !_isLoading && !_isEditing)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    // Regenerate
                    DoctorSecondaryButton(
                      label: 'Regenerate',
                      icon: Icons.refresh_rounded,
                      onPressed: _confirmAndRegenerate,
                      height: 36,
                    ),

                    // Edit Summary
                    DoctorSecondaryButton(
                      label: 'Edit Summary',
                      icon: Icons.edit_note_rounded,
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      height: 36,
                    ),

                    // Approve Summary
                    if (_summary?.isApproved != true)
                      DoctorPrimaryButton(
                        label: 'Approve Summary',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _handleApprove,
                        height: 36,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
