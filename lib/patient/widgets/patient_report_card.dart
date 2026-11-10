import 'package:flutter/material.dart';
import '../../doctor/models/investigation_request.dart';
import '../localization/patient_localizations.dart';
import '../localization/patient_strings.dart';
import '../theme/patient_colors.dart';

/// Reusable Senior-Accessible Card representing a medical lab/investigation report.
class PatientReportCard extends StatelessWidget {
  final InvestigationRequest report;
  final String? caseTitle;
  final DateTime? visitDate;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback? onSubmitTap;

  const PatientReportCard({
    super.key,
    required this.report,
    this.caseTitle,
    this.visitDate,
    this.isHighlighted = false,
    required this.onTap,
    this.onSubmitTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final isPending = report.status == InvestigationStatus.pendingUpload;
    final isReviewed = report.status == InvestigationStatus.reviewed;
    final isUploaded = report.status == InvestigationStatus.uploaded;
    final effectiveVisitDate = visitDate ?? report.requestedAt;

    return Material(
      color: isHighlighted ? const Color(0xFFFFFBF5) : PatientColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isPending
            ? () {
                if (onSubmitTap != null) {
                  onSubmitTap!();
                } else {
                  _navigateToUpload(context);
                }
              }
            : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? PatientColors.orange
                  : isPending
                      ? const Color(0xFFFFCC80)
                      : PatientColors.borderSubtle,
              width: isHighlighted ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isHighlighted
                    ? const Color(0x1FFF9800)
                    : PatientColors.shadow,
                blurRadius: isHighlighted ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Highlight Tag (when navigated from Report Required)
              if (isHighlighted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: PatientColors.orangeLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PatientColors.orange, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: PatientColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        strings.reportRequiredStatus.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: PatientColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Header Row: Title & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PatientColors.navy,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (report.isRequired) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBE9E7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'REQUIRED',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD84315),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(strings, isPending, isUploaded, isReviewed),
                ],
              ),
              const SizedBox(height: 14),

              // Metadata Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PatientColors.borderSubtle, width: 1),
                ),
                child: Column(
                  children: [
                    // Case Reference Row
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined, size: 14, color: PatientColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${strings.reportCaseLabel}:',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PatientColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            caseTitle ?? 'General Consultation',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PatientColors.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Visit Date Row
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: PatientColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${strings.reportRequestedDate}:',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PatientColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDate(effectiveVisitDate),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PatientColors.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Submission Date Row (if uploaded / reviewed)
                    if (report.uploadedAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 14, color: PatientColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            '${strings.reportSubmissionDate}:',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PatientColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDate(report.uploadedAt!),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PatientColors.tealDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action Footer
              if (isPending) ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (onSubmitTap != null) {
                        onSubmitTap!();
                      } else {
                        _showSubmissionGuidance(context, strings);
                      }
                    },
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      strings.submitReportAction,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PatientColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      strings.viewReportButton,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.teal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: PatientColors.teal,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUpload(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/patient/reports/${report.requestId}/upload',
      arguments: {
        'investigation': report,
        'report': report,
        'caseTitle': caseTitle,
        'visitDate': visitDate ?? report.requestedAt,
      },
    );
  }

  void _showSubmissionGuidance(BuildContext context, PatientStrings strings) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: PatientColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: PatientColors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.submitReportGuidanceTitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.navy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          strings.submitReportGuidanceDesc,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            height: 1.5,
            color: PatientColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              strings.close,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: PatientColors.textMuted,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _navigateToUpload(context);
            },
            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
            label: Text(
              strings.uploadReportTitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: PatientColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    PatientStrings strings,
    bool isPending,
    bool isUploaded,
    bool isReviewed,
  ) {
    if (isReviewed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 14, color: PatientColors.tealDark),
            const SizedBox(width: 4),
            Text(
              strings.reviewedStatus,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PatientColors.tealDark,
              ),
            ),
          ],
        ),
      );
    }

    if (isUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: PatientColors.statusSuccessLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: PatientColors.statusSuccess),
            const SizedBox(width: 4),
            Text(
              strings.reportStatusUploaded,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PatientColors.statusSuccess,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: PatientColors.orangeLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.priority_high_rounded, size: 14, color: PatientColors.orange),
          const SizedBox(width: 4),
          Text(
            strings.reportRequiredStatus,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PatientColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[(dt.month - 1).clamp(0, 11)];
    return '$day $month ${dt.year}';
  }
}
