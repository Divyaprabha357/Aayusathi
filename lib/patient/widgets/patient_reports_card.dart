import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../doctor/localization/doctor_localizations.dart';
import '../../doctor/models/investigation_request.dart';
import '../../doctor/models/report_document.dart';
import '../../doctor/theme/doctor_colors.dart';
import '../../doctor/theme/doctor_theme.dart';

/// Integration-ready reusable UI component for displaying requested investigations
/// and facilitating patient report uploads in the Patient app.
class PatientReportsCard extends StatelessWidget {
  final InvestigationRequest investigation;
  final ReportDocument? uploadedReport;
  final VoidCallback onUploadPressed;
  final VoidCallback? onViewReportPressed;
  final KioskLocale locale;

  const PatientReportsCard({
    super.key,
    required this.investigation,
    this.uploadedReport,
    required this.onUploadPressed,
    this.onViewReportPressed,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    final isUploaded = investigation.isUploaded || uploadedReport != null;
    final isReviewed = investigation.isReviewed ||
        uploadedReport?.reviewStatus == ReportReviewStatus.reviewed;

    Color statusColor;
    String statusLabel;
    if (isReviewed) {
      statusColor = DoctorColors.statusNormal;
      statusLabel = strings.reviewedStatus;
    } else if (isUploaded) {
      statusColor = DoctorColors.brandTeal;
      statusLabel = strings.uploadedStatus;
    } else {
      statusColor = DoctorColors.statusBusy;
      statusLabel = strings.pendingUploadStatus;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  investigation.name,
                  style: DoctorTheme.bodyBold.copyWith(
                    color: DoctorColors.brandNavy,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DoctorColors.brandTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  investigation.category.label,
                  style: const TextStyle(
                    color: DoctorColors.brandTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: investigation.isRequired
                      ? DoctorColors.statusCritical.withValues(alpha: 0.1)
                      : DoctorColors.brandNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  investigation.priority.label,
                  style: TextStyle(
                    color: investigation.isRequired
                        ? DoctorColors.statusCritical
                        : DoctorColors.brandNavy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (uploadedReport != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded,
                    size: 16, color: DoctorColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    uploadedReport!.fileName,
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isUploaded && onViewReportPressed != null) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(strings.viewReportButton),
                  onPressed: onViewReportPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DoctorColors.brandNavy,
                    side: const BorderSide(color: DoctorColors.border),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!isReviewed)
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(strings.uploadReportButton),
                  onPressed: onUploadPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DoctorColors.brandTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
