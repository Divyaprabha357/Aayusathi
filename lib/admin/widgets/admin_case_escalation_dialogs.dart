import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../doctor/models/clinical_case.dart';
import '../controllers/admin_case_escalation_controller.dart';
import '../localization/admin_localizations.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import 'admin_buttons.dart';

/// Modal dialog for reviewing physician-escalated clinical case metadata (Phase A8).
///
/// Features:
/// - Displays structured escalation metadata (Reason, Source Visit, Doctor, Timestamp, Note).
/// - Displays case history overview (Total Visits, Domain, Status).
/// - Offers explicit "Start Review" administrative action transitioning `escalated -> underReview`.
/// - Explanatory notice pointing to future Phase A9 full clinical workspace.
/// - Hard safeguards: Zero clinical note editing, zero case closure, zero doctor assignment.
class AdminCaseEscalationReviewDialog extends StatefulWidget {
  final ClinicalCase clinicalCase;
  final AdminCaseEscalationController controller;

  const AdminCaseEscalationReviewDialog({
    super.key,
    required this.clinicalCase,
    required this.controller,
  });

  @override
  State<AdminCaseEscalationReviewDialog> createState() =>
      _AdminCaseEscalationReviewDialogState();
}

class _AdminCaseEscalationReviewDialogState
    extends State<AdminCaseEscalationReviewDialog> {
  late ClinicalCase _currentCase;
  bool _isStartingReview = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentCase = widget.clinicalCase;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _getReasonLabel(dynamic strings, CaseEscalationReason? reason) {
    if (reason == null) return 'N/A';
    switch (reason) {
      case CaseEscalationReason.clinicalDeterioration:
        return strings.filterReasonDeterioration;
      case CaseEscalationReason.repeatedVisitsNoResolution:
        return strings.filterReasonRepeatedVisits;
      case CaseEscalationReason.higherAuthorityReview:
        return strings.filterReasonHigherAuthority;
      case CaseEscalationReason.doctorConcern:
        return strings.filterReasonDoctorConcern;
      case CaseEscalationReason.other:
        return strings.filterReasonOther;
    }
  }

  Future<void> _handleStartReview() async {
    setState(() {
      _isStartingReview = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.startReview(
        patientId: _currentCase.patientId,
        caseId: _currentCase.caseId,
      );

      if (mounted) {
        setState(() {
          _isStartingReview = false;
          _currentCase = _currentCase.copyWith(
            escalationStatus: CaseEscalationStatus.underReview,
            adminReviewStartedAt: DateTime.now(),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdminLocalizations.of(context).reviewStartedSuccess,
            ),
            backgroundColor: AdminColors.brandTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStartingReview = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final isUnderReview = _currentCase.isUnderReview;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
      ),
      backgroundColor: AdminColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 680,
          maxHeight: 740,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(AdminTheme.space20),
              decoration: const BoxDecoration(
                color: AdminColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AdminTheme.radius16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AdminColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isUnderReview
                          ? AdminColors.brandTeal.withValues(alpha: 0.12)
                          : AdminColors.statusCritical.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AdminTheme.radius12),
                    ),
                    child: Icon(
                      isUnderReview
                          ? Icons.rate_review_rounded
                          : Icons.warning_amber_rounded,
                      color: isUnderReview
                          ? AdminColors.brandTeal
                          : AdminColors.statusCritical,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.caseReviewModalTitle,
                          style: AdminTheme.headline2.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.brandNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.caseReviewModalSubtitle,
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AdminTheme.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner
                    Container(
                      padding: const EdgeInsets.all(AdminTheme.space16),
                      decoration: BoxDecoration(
                        color: isUnderReview
                            ? AdminColors.brandTeal.withValues(alpha: 0.08)
                            : AdminColors.statusCritical.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AdminTheme.radius12),
                        border: Border.all(
                          color: isUnderReview
                              ? AdminColors.brandTeal.withValues(alpha: 0.3)
                              : AdminColors.statusCritical.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUnderReview
                                ? Icons.pending_actions_rounded
                                : Icons.priority_high_rounded,
                            color: isUnderReview
                                ? AdminColors.brandTeal
                                : AdminColors.statusCritical,
                            size: 22,
                          ),
                          const SizedBox(width: AdminTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUnderReview
                                      ? strings.currentlyUnderReviewNotice
                                      : strings.statusBadgePendingReview,
                                  style: AdminTheme.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isUnderReview
                                        ? AdminColors.brandTeal
                                        : AdminColors.statusCritical,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isUnderReview &&
                                    _currentCase.adminReviewStartedBy != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${strings.reviewedByLabel}: ${_currentCase.adminReviewStartedBy} • ${_formatDateTime(_currentCase.adminReviewStartedAt)}',
                                    style: AdminTheme.caption.copyWith(
                                      color: AdminColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AdminTheme.space16),

                    // Case Identification Grid
                    Text(
                      'CASE METADATA',
                      style: AdminTheme.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AdminTheme.space8),
                    Container(
                      padding: const EdgeInsets.all(AdminTheme.space16),
                      decoration: BoxDecoration(
                        color: AdminColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(AdminTheme.radius12),
                        border: Border.all(color: AdminColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildMetaField(
                                label: strings.tableColCaseId,
                                value: _currentCase.caseId,
                                isPrimary: true,
                              ),
                              _buildMetaField(
                                label: strings.tableColPatientId,
                                value: _currentCase.patientId,
                              ),
                              _buildMetaField(
                                label: strings.tableColDepartmentA8,
                                value: _currentCase.domain,
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AdminColors.borderSubtle),
                          Row(
                            children: [
                              _buildMetaField(
                                label: strings.tableColCaseStatus,
                                value: _currentCase.isOpen ? 'OPEN' : 'CLOSED',
                                badgeColor: _currentCase.isOpen
                                    ? AdminColors.statusAvailable
                                    : AdminColors.textMuted,
                              ),
                              _buildMetaField(
                                label: 'TOTAL VISITS',
                                value: '${_currentCase.visitCount} visits',
                              ),
                              _buildMetaField(
                                label: strings.tableColSourceVisit,
                                value: _currentCase.escalationSourceVisitId ??
                                    'Visit ${_currentCase.visitCount}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AdminTheme.space16),

                    // Escalation Reason & Clinical Context
                    Text(
                      'ESCALATION DETAILS',
                      style: AdminTheme.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AdminTheme.space8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AdminTheme.space16),
                      decoration: BoxDecoration(
                        color: AdminColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(AdminTheme.radius12),
                        border: Border.all(color: AdminColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildMetaField(
                                label: strings.tableColReason,
                                value: _getReasonLabel(
                                  strings,
                                  _currentCase.escalationReason,
                                ),
                                isHighlight: true,
                              ),
                              _buildMetaField(
                                label: strings.tableColEscalatedBy,
                                value: _currentCase.escalatedByDoctorName ??
                                    _currentCase.escalatedByDoctorId ??
                                    'Doctor',
                              ),
                              _buildMetaField(
                                label: strings.tableColEscalatedAtA8,
                                value: _formatDateTime(_currentCase.escalatedAt),
                              ),
                            ],
                          ),
                          if (_currentCase.escalationNote != null &&
                              _currentCase.escalationNote!.isNotEmpty) ...[
                            const Divider(height: 20, color: AdminColors.borderSubtle),
                            Text(
                              'DOCTOR EXPLANATION / NOTE',
                              style: AdminTheme.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentCase.escalationNote!,
                              style: AdminTheme.bodyRegular.copyWith(
                                color: AdminColors.brandNavy,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_currentCase.isAssignedToHigherAuthority) ...[
                      const SizedBox(height: AdminTheme.space16),
                      Text(
                        strings.higherAuthorityAssignmentSection.toUpperCase(),
                        style: AdminTheme.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.brandTeal,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AdminTheme.space8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AdminTheme.space16),
                        decoration: BoxDecoration(
                          color: AdminColors.brandTeal.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AdminTheme.radius12),
                          border: Border.all(
                            color: AdminColors.brandTeal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildMetaField(
                                  label: strings.assignedDoctorCol,
                                  value: _currentCase.higherAuthorityDoctorName ??
                                      _currentCase.higherAuthorityDoctorId ??
                                      'Doctor',
                                  isPrimary: true,
                                ),
                                _buildMetaField(
                                  label: strings.assignedDeptCol,
                                  value: _currentCase.higherAuthorityDepartment ??
                                      _currentCase.domain,
                                ),
                                _buildMetaField(
                                  label: strings.assignedStatusCol,
                                  value: _currentCase.higherAuthorityAssignmentStatus.name.toUpperCase(),
                                  badgeColor: _currentCase.isHigherAuthorityAccepted
                                      ? AdminColors.statusAvailable
                                      : AdminColors.brandOrange,
                                ),
                              ],
                            ),
                            if (_currentCase.higherAuthorityAssignedAt != null) ...[
                              const Divider(height: 16, color: AdminColors.borderSubtle),
                              Text(
                                '${strings.assignedAtLabel}: ${_formatDateTime(_currentCase.higherAuthorityAssignedAt)} • ${strings.assignedByLabel}: ${_currentCase.higherAuthorityAssignedBy ?? "Admin"}',
                                style: AdminTheme.caption.copyWith(
                                  color: AdminColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AdminTheme.space16),

                    // Phase A9 Clinical Workspace Action Banner
                    Container(
                      padding: const EdgeInsets.all(AdminTheme.space16),
                      decoration: BoxDecoration(
                        color: AdminColors.brandTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AdminTheme.radius12),
                        border: Border.all(
                          color: AdminColors.brandTeal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medical_information_rounded,
                            color: AdminColors.brandTeal,
                            size: 24,
                          ),
                          const SizedBox(width: AdminTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.openClinicalWorkspace,
                                  style: AdminTheme.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AdminColors.brandNavy,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Inspect complete longitudinal clinical record, visits, vitals, and reports.',
                                  style: AdminTheme.caption.copyWith(
                                    color: AdminColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AdminPrimaryButton(
                            key: const ValueKey('open_workspace_banner_button'),
                            label: strings.openClinicalWorkspace,
                            icon: Icons.open_in_new_rounded,
                            height: 32,
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AppRoutes.adminEscalatedPatient,
                                arguments: {
                                  'patientId': _currentCase.patientId,
                                  'caseId': _currentCase.caseId,
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AdminTheme.space12),
                      Container(
                        padding: const EdgeInsets.all(AdminTheme.space12),
                        decoration: BoxDecoration(
                          color: AdminColors.statusCritical.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AdminTheme.radius8),
                          border: Border.all(
                            color: AdminColors.statusCritical.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.statusCritical,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.all(AdminTheme.space16),
              decoration: const BoxDecoration(
                color: AdminColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AdminTheme.radius16),
                ),
                border: Border(
                  top: BorderSide(
                    color: AdminColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AdminTheme.space12,
                runSpacing: AdminTheme.space8,
                children: [
                  AdminSecondaryButton(
                    label: strings.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AdminSecondaryButton(
                    key: const ValueKey('open_workspace_modal_button'),
                    label: strings.openClinicalWorkspace,
                    icon: Icons.open_in_new_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminEscalatedPatient,
                        arguments: {
                          'patientId': _currentCase.patientId,
                          'caseId': _currentCase.caseId,
                        },
                      );
                    },
                  ),
                  if (!isUnderReview)
                    AdminPrimaryButton(
                      key: const ValueKey('start_review_modal_button'),
                      label: _isStartingReview
                          ? strings.startingReviewButton
                          : strings.startReviewButton,
                      icon: Icons.rate_review_rounded,
                      onPressed: _isStartingReview ? () {} : _handleStartReview,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaField({
    required String label,
    required String value,
    bool isPrimary = false,
    bool isHighlight = false,
    Color? badgeColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AdminTheme.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            )
          else
            Text(
              value,
              style: AdminTheme.body.copyWith(
                fontWeight:
                    isPrimary || isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight
                    ? AdminColors.statusCritical
                    : (isPrimary ? AdminColors.brandTeal : AdminColors.brandNavy),
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
