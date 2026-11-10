import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/investigation_request.dart';
import '../models/report_document.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Interactive review widget embedded in the Doctor Patient Workspace providing
/// tabbed filtering across Requested, Uploaded (Pending Review), and Reviewed diagnostic reports.
class DoctorReportsReviewWidget extends StatefulWidget {
  final List<InvestigationRequest> investigations;
  final List<ReportDocument> reports;
  final Function(InvestigationRequest investigation, ReportDocument? report)
      onMarkReviewed;
  final Function(ReportDocument report)? onViewReport;
  final VoidCallback onRequestInvestigation;
  final KioskLocale locale;

  const DoctorReportsReviewWidget({
    super.key,
    required this.investigations,
    required this.reports,
    required this.onMarkReviewed,
    this.onViewReport,
    required this.onRequestInvestigation,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorReportsReviewWidget> createState() =>
      _DoctorReportsReviewWidgetState();
}

class _DoctorReportsReviewWidgetState extends State<DoctorReportsReviewWidget> {
  int _selectedTabIndex = 0; // 0: Requested, 1: Uploaded, 2: Reviewed

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    final requestedList =
        widget.investigations.where((i) => i.isPendingUpload).toList();

    final uploadedList = widget.investigations.where((i) {
      if (i.isUploaded) return true;
      final rep = _findReportForInvestigation(i.requestId);
      return rep != null && rep.reviewStatus == ReportReviewStatus.uploaded;
    }).toList();

    final reviewedList = widget.investigations.where((i) {
      if (i.isReviewed) return true;
      final rep = _findReportForInvestigation(i.requestId);
      return rep != null && rep.reviewStatus == ReportReviewStatus.reviewed;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space20),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DoctorColors.brandTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      ),
                      child: const Icon(Icons.assignment_outlined,
                          color: DoctorColors.brandTeal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.reportsReviewTitle,
                            style: DoctorTheme.headline2.copyWith(
                              color: DoctorColors.brandNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Investigation Lifecycle & Patient Document Verification',
                            style: DoctorTheme.caption.copyWith(
                              color: DoctorColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DoctorSecondaryButton(
                label: strings.requestInvestigationButton,
                icon: Icons.add_rounded,
                onPressed: widget.onRequestInvestigation,
                height: 36,
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space16),

          // Tab Navigation Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: DoctorColors.background,
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              border: Border.all(color: DoctorColors.border),
            ),
            child: Row(
              children: [
                _buildTab(0, strings.tabRequested, requestedList.length,
                    Icons.hourglass_empty_rounded),
                const SizedBox(width: 6),
                _buildTab(1, strings.tabUploaded, uploadedList.length,
                    Icons.upload_file_rounded),
                const SizedBox(width: 6),
                _buildTab(2, strings.tabReviewed, reviewedList.length,
                    Icons.check_circle_outline_rounded),
              ],
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),

          // Content List for Selected Tab
          if (_selectedTabIndex == 0)
            _buildItemsList(requestedList, strings.noReportsInTab, 0)
          else if (_selectedTabIndex == 1)
            _buildItemsList(uploadedList, strings.noReportsInTab, 1)
          else
            _buildItemsList(reviewedList, strings.noReportsInTab, 2),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? DoctorColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(DoctorTheme.radius6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? DoctorColors.brandTeal
                    : DoctorColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected
                        ? DoctorColors.brandNavy
                        : DoctorColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DoctorColors.brandTeal.withValues(alpha: 0.15)
                      : DoctorColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? DoctorColors.brandTeal
                        : DoctorColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(
      List<InvestigationRequest> items, String emptyMessage, int tabMode) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DoctorTheme.space24),
        alignment: Alignment.center,
        child: Text(
          emptyMessage,
          style: DoctorTheme.bodyMuted,
        ),
      );
    }

    return Column(
      children: items.map((inv) {
        final rep = _findReportForInvestigation(inv.requestId);
        return _buildReportCard(inv, rep, tabMode);
      }).toList(),
    );
  }

  Widget _buildReportCard(
      InvestigationRequest inv, ReportDocument? rep, int tabMode) {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    return Container(
      margin: const EdgeInsets.only(bottom: DoctorTheme.space12),
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: DoctorTheme.bodyBold.copyWith(
                        color: DoctorColors.brandNavy,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: DoctorColors.brandTeal
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            inv.category.label,
                            style: const TextStyle(
                              color: DoctorColors.brandTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: inv.isRequired
                                ? DoctorColors.statusCritical
                                    .withValues(alpha: 0.1)
                                : DoctorColors.brandNavy
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            inv.priority.label,
                            style: TextStyle(
                              color: inv.isRequired
                                  ? DoctorColors.statusCritical
                                  : DoctorColors.brandNavy,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: inv.isReviewed
                                ? DoctorColors.statusNormal
                                    .withValues(alpha: 0.1)
                                : (inv.isUploaded
                                    ? DoctorColors.brandTeal
                                        .withValues(alpha: 0.1)
                                    : DoctorColors.statusBusy
                                        .withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            inv.status.label,
                            style: TextStyle(
                              color: inv.isReviewed
                                  ? DoctorColors.statusNormal
                                  : (inv.isUploaded
                                      ? DoctorColors.brandTeal
                                      : DoctorColors.statusBusy),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (tabMode == 1) // Uploaded -> Show "Mark as Reviewed"
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 16),
                  label: Text(strings.markAsReviewedButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DoctorColors.statusNormal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => widget.onMarkReviewed(inv, rep),
                ),
            ],
          ),
          if (rep != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: DoctorColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: DoctorColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    rep.isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                    size: 16,
                    color: DoctorColors.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rep.fileName} (${(rep.fileSizeBytes / 1024).round()} KB) • Uploaded ${_formatDate(rep.uploadedAt)}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onViewReport != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => widget.onViewReport!(rep),
                      child: Text(
                        strings.viewReportButton,
                        style: const TextStyle(
                          color: DoctorColors.brandTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  ReportDocument? _findReportForInvestigation(String invId) {
    return widget.reports.cast<ReportDocument?>().firstWhere(
          (r) => r?.investigationId == invId,
          orElse: () => null,
        );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
