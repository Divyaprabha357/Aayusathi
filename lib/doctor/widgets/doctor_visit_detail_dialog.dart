import 'package:flutter/material.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/clinical_visit.dart';
import '../models/investigation_request.dart';
import '../models/report_document.dart';
import '../services/doctor_ai_report_summarization_service.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';
import 'doctor_report_viewer_dialog.dart';

/// Read-only inspection dialog for historical completed consultation encounters.
///
/// Ensures:
/// 1. Completed visits cannot be modified through the active consultation workflow.
/// 2. Displays full 8-field consultation record, vitals telemetry, prescriptions,
///    approved summary, and investigation requests.
/// 3. Displays Patient Uploaded Reports strictly scoped to this exact clinical visit
///    (`report.patientId == visit.patientId && report.caseId == visit.caseId && report.visitId == visit.visitId`).
/// 4. Zero sensitive credentials or Aadhaar displayed.
class DoctorVisitDetailDialog extends StatefulWidget {
  final ClinicalVisit visit;
  final String domain;
  final KioskLocale locale;

  const DoctorVisitDetailDialog({
    super.key,
    required this.visit,
    required this.domain,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorVisitDetailDialog> createState() =>
      _DoctorVisitDetailDialogState();
}

class _DoctorVisitDetailDialogState extends State<DoctorVisitDetailDialog> {
  ClinicalVisit get visit => widget.visit;

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markReportReviewed(ReportDocument report) async {
    final doctorId =
        DoctorSessionService.instance.activeDoctorId ?? visit.doctorId;
    try {
      await BackendProvider.instance.reportRepository.updateReportStatus(
        patientId: visit.patientId,
        caseId: visit.caseId,
        visitId: visit.visitId,
        reportId: report.reportId,
        status: ReportReviewStatus.reviewed,
        doctorId: doctorId,
      );

      if (report.investigationId.isNotEmpty) {
        await BackendProvider.instance.investigationRepository.markReviewed(
          patientId: visit.patientId,
          caseId: visit.caseId,
          visitId: visit.visitId,
          investigationId: report.investigationId,
          doctorId: doctorId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report marked as reviewed by attending doctor.'),
            backgroundColor: DoctorColors.brandTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update report review status: $e'),
            backgroundColor: DoctorColors.brandOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final formattedStarted = _formatDateTime(visit.startedAt);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 820,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
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
                    Icons.history_edu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: DoctorTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.visit} ${visit.visitNumber} • ${widget.domain}',
                          style: DoctorTheme.cardTitle.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${visit.caseId} • $formattedStarted',
                          style: DoctorTheme.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DoctorColors.statusAvailable.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            DoctorColors.statusAvailable.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      strings.completedStatusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Read-Only Warning Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space24,
                vertical: 10,
              ),
              color: DoctorColors.brandTeal.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: DoctorColors.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.historicalVisitNotice,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.brandTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DoctorTheme.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Info
                    _buildSectionHeader(
                      Icons.person_outline_rounded,
                      'Attending Physician',
                    ),
                    _buildTextRow('Doctor', visit.doctorName ?? visit.doctorId),
                    if (visit.doctorQualification != null)
                      _buildTextRow(
                        'Qualification',
                        visit.doctorQualification!,
                      ),
                    const SizedBox(height: DoctorTheme.space16),

                    // Vitals Telemetry (Section 5)
                    if (visit.vitals != null) ...[
                      _buildSectionHeader(
                        Icons.monitor_heart_outlined,
                        'Encounter Vitals Telemetry',
                      ),
                      _buildVitalsCard(visit.vitals!, strings),
                      const SizedBox(height: DoctorTheme.space16),
                    ],

                    // Structured Consultation (8 Official Fields)
                    _buildSectionHeader(
                      Icons.medical_services_outlined,
                      'Structured Consultation (8 Clinical Fields)',
                    ),
                    _buildFieldBlock(
                      strings.chiefComplaintLabel,
                      visit.chiefComplaint,
                    ),
                    _buildFieldBlock(
                      strings.onsetDurationLabel,
                      visit.onsetDuration,
                    ),
                    _buildFieldBlock(
                      strings.associatedSymptomsLabel,
                      visit.associatedSymptoms,
                    ),
                    _buildFieldBlock(
                      strings.medicalHistoryLabel,
                      visit.medicalHistory,
                    ),
                    _buildFieldBlock(
                      strings.currentMedicationLabel,
                      visit.currentMedication,
                    ),
                    _buildFieldBlock(
                      strings.clinicalObservationsLabel,
                      visit.clinicalObservations,
                    ),
                    _buildFieldBlock(strings.assessmentLabel, visit.assessment),
                    _buildFieldBlock(strings.planLabel, visit.plan),
                    const SizedBox(height: DoctorTheme.space16),

                    // Prescriptions
                    if (visit.prescriptions.isNotEmpty) ...[
                      _buildSectionHeader(
                        Icons.medication_outlined,
                        'Prescriptions',
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visit.prescriptions.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final p = visit.prescriptions[index];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: DoctorColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: DoctorColors.border),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: DoctorTheme.bodyBold.copyWith(
                                    color: DoctorColors.brandTeal,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.medicineName,
                                        style: DoctorTheme.bodyBold.copyWith(
                                          color: DoctorColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${p.duration} • ${p.timesPerDay}${p.remarks.isNotEmpty ? " • ${p.remarks}" : ""}',
                                        style: DoctorTheme.caption.copyWith(
                                          color: DoctorColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: DoctorTheme.space16),
                    ],

                    // Doctor-Approved Summary
                    _buildSectionHeader(
                      Icons.fact_check_outlined,
                      'Doctor-Approved Visit Summary',
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DoctorColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DoctorColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DoctorColors.statusAvailable
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  visit.summaryApprovalStatus.label,
                                  style: const TextStyle(
                                    color: DoctorColors.statusAvailable,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (visit.approvedAt != null)
                                Text(
                                  'Approved: ${visit.approvedAt!.day}/${visit.approvedAt!.month}/${visit.approvedAt!.year}',
                                  style: DoctorTheme.caption.copyWith(
                                    fontSize: 10,
                                    color: DoctorColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            visit.effectiveSummary.isNotEmpty
                                ? visit.effectiveSummary
                                : 'No summary recorded.',
                            style: DoctorTheme.body.copyWith(
                              color: DoctorColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DoctorTheme.space16),

                    // Diagnostic Investigations (Prescribed)
                    if (visit.investigationRequests.isNotEmpty) ...[
                      _buildSectionHeader(
                        Icons.biotech_outlined,
                        'Diagnostic & Lab Investigations Requested',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: visit.investigationRequests.map((req) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: DoctorColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: DoctorColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 14,
                                  color: DoctorColors.brandTeal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  req.name,
                                  style: DoctorTheme.caption.copyWith(
                                    color: DoctorColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: DoctorTheme.space16),
                    ],

                    // Patient Uploaded Reports (Sections 5, 6, 7)
                    _buildSectionHeader(
                      Icons.upload_file_rounded,
                      strings.patientUploadedReportsHeader,
                    ),
                    _buildPatientUploadedReportsSection(strings),
                    const SizedBox(height: DoctorTheme.space16),

                    // Follow-Up & Instructions
                    if ((visit.followUp != null &&
                            visit.followUp!.isNotEmpty) ||
                        (visit.patientInstructions != null &&
                            visit.patientInstructions!.isNotEmpty)) ...[
                      _buildSectionHeader(
                        Icons.event_note_outlined,
                        'Plan, Follow-Up & Patient Instructions',
                      ),
                      if (visit.followUp != null &&
                          visit.followUp!.isNotEmpty)
                        _buildFieldBlock(
                          strings.followUpLabel,
                          visit.followUp,
                        ),
                      if (visit.patientInstructions != null &&
                          visit.patientInstructions!.isNotEmpty)
                        _buildFieldBlock(
                          strings.patientInstructionsLabel,
                          visit.patientInstructions,
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(DoctorTheme.space16),
              decoration: const BoxDecoration(
                color: DoctorColors.background,
                border: Border(
                  top: BorderSide(color: DoctorColors.border),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DoctorTheme.radius16),
                  bottomRight: Radius.circular(DoctorTheme.radius16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DoctorPrimaryButton(
                    label: strings.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientUploadedReportsSection(DoctorStrings strings) {
    return StreamBuilder<List<ReportDocument>>(
      stream: BackendProvider.instance.reportRepository.watchReportsForVisit(
        patientId: visit.patientId,
        caseId: visit.caseId,
        visitId: visit.visitId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
              ),
            ),
          );
        }

        final allReports = snapshot.data ?? [];

        // STRICT VISIT MATCHING & Filter out doctor official visit PDF
        final visitReports = allReports.where((r) {
          final matchesVisit = r.patientId == visit.patientId &&
              r.caseId == visit.caseId &&
              r.visitId == visit.visitId;
          return matchesVisit && r.isPatientUploadedReport;
        }).toList();

        // If investigations were requested, correlate each
        final investigationItems = <Widget>[];
        final matchedReportIds = <String>{};

        for (final inv in visit.investigationRequests) {
          final matchingReport = visitReports.cast<ReportDocument?>().firstWhere(
                (r) => r?.investigationId == inv.requestId,
                orElse: () => null,
              );

          if (matchingReport != null) {
            matchedReportIds.add(matchingReport.reportId);
            investigationItems.add(
              _buildReportItemCard(
                report: matchingReport,
                investigation: inv,
                strings: strings,
              ),
            );
          } else {
            // Requested but pending patient upload (Section 7)
            investigationItems.add(
              _buildPendingInvestigationCard(inv, strings),
            );
          }
        }

        // Add any additional uploaded reports that were not mapped to a specific investigation
        for (final rep in visitReports) {
          if (!matchedReportIds.contains(rep.reportId)) {
            investigationItems.add(
              _buildReportItemCard(
                report: rep,
                investigation: null,
                strings: strings,
              ),
            );
          }
        }

        // If no reports uploaded at all for this visit (Section 7)
        if (visitReports.isEmpty && visit.investigationRequests.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DoctorColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DoctorColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_open_rounded,
                  size: 18,
                  color: DoctorColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.noPatientReportsForVisit,
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (visitReports.isEmpty && visit.investigationRequests.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...investigationItems,
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  strings.noPatientReportsForVisit,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: investigationItems,
        );
      },
    );
  }

  Widget _buildReportItemCard({
    required ReportDocument report,
    required InvestigationRequest? investigation,
    required DoctorStrings strings,
  }) {
    final invName = investigation?.name ??
        (report.investigationId.isNotEmpty ? report.investigationId : 'Investigation');
    final formattedDate =
        '${report.uploadedAt.day.toString().padLeft(2, '0')} '
        '${_monthName(report.uploadedAt.month)} '
        '${report.uploadedAt.year}';

    final isReviewed = report.isReviewed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(
          color: isReviewed
              ? DoctorColors.statusAvailable.withValues(alpha: 0.3)
              : DoctorColors.brandTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (report.isPdf
                          ? DoctorColors.brandNavy
                          : DoctorColors.brandTeal)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  report.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  size: 20,
                  color: report.isPdf
                      ? DoctorColors.brandNavy
                      : DoctorColors.brandTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.fileName,
                      style: DoctorTheme.bodyBold.copyWith(
                        color: DoctorColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Investigation: $invName',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '•  Uploaded: $formattedDate',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '•  ${(report.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isReviewed
                      ? DoctorColors.statusAvailable.withValues(alpha: 0.12)
                      : DoctorColors.brandTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReviewed ? 'Reviewed' : 'Uploaded',
                  style: TextStyle(
                    color: isReviewed
                        ? DoctorColors.statusAvailable
                        : DoctorColors.brandTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Actions Row: [ View Report ] and [ AI Summarize Report ]
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // AI Summarize Report extension point
              InkWell(
                onTap: () {
                  DoctorAiReportSummaryDialog.show(context, report);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: DoctorColors.brandOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        strings.aiSummarizeReportButton,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.brandOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Mark as Reviewed (if pending review)
              if (!isReviewed) ...[
                InkWell(
                  onTap: () => _markReportReviewed(report),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: DoctorColors.statusAvailable,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.markAsReviewedButton,
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.statusAvailable,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // View Report Button
              ElevatedButton.icon(
                key: ValueKey('view_report_button_${report.reportId}'),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: Text(strings.viewReportButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorColors.brandTeal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  DoctorReportViewerDialog.show(
                    context,
                    reportDoc: report,
                    investigation: investigation,
                    locale: widget.locale,
                    currentPatientId: widget.visit.patientId,
                    currentCaseId: widget.visit.caseId,
                    currentVisitId: widget.visit.visitId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvestigationCard(
    InvestigationRequest inv,
    DoctorStrings strings,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DoctorColors.brandOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 18,
              color: DoctorColors.brandOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.name,
                  style: DoctorTheme.bodyBold.copyWith(
                    color: DoctorColors.brandNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.waitingForPatientReport,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.brandOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DoctorColors.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Pending Upload',
              style: const TextStyle(
                color: DoctorColors.brandOrange,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(dynamic vitals, DoctorStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildVitalItem(
            'SpO₂',
            vitals.spo2 != null ? '${vitals.spo2}%' : '--',
          ),
          _buildVitalItem(
            'Pulse',
            vitals.heartRate != null ? '${vitals.heartRate} bpm' : '--',
          ),
          _buildVitalItem(
            'Temperature',
            vitals.temperature != null ? '${vitals.temperatureDisplay} °C' : '--',
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: DoctorTheme.bodyBold.copyWith(
            color: DoctorColors.brandNavy,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DoctorColors.brandNavy),
          const SizedBox(width: 6),
          Text(
            title,
            style: DoctorTheme.bodyBold.copyWith(
              color: DoctorColors.brandNavy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DoctorTheme.body.copyWith(
                color: DoctorColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldBlock(String label, String? content) {
    if (content == null || content.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DoctorColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: DoctorColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.brandNavy,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              content,
              style: DoctorTheme.body.copyWith(
                color: DoctorColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
