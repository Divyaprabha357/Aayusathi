import 'package:flutter/material.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/doctor_profile.dart';
import '../controllers/admin_higher_authority_assignment_controller.dart';
import '../localization/admin_localizations.dart';
import '../localization/admin_strings.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import 'admin_buttons.dart';

/// Modal dialog allowing Hospital Administrators to assign an escalated clinical case
/// to a qualified, available higher-authority physician (Phase A10).
class AdminHigherAuthorityAssignmentDialog extends StatefulWidget {
  final ClinicalCase clinicalCase;
  final String? sourceDoctorName;
  final VoidCallback? onAssignmentSuccess;

  const AdminHigherAuthorityAssignmentDialog({
    super.key,
    required this.clinicalCase,
    this.sourceDoctorName,
    this.onAssignmentSuccess,
  });

  @override
  State<AdminHigherAuthorityAssignmentDialog> createState() =>
      _AdminHigherAuthorityAssignmentDialogState();
}

class _AdminHigherAuthorityAssignmentDialogState
    extends State<AdminHigherAuthorityAssignmentDialog> {
  late final AdminHigherAuthorityAssignmentController _controller;
  final TextEditingController _crossDeptReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final adminId = AdminAuthService.instance.currentSession?.username ?? 'admin01';
    _controller = AdminHigherAuthorityAssignmentController(
      clinicalCase: widget.clinicalCase,
      adminId: adminId,
    );
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _crossDeptReasonController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleConfirmAndAssign() async {
    final strings = AdminLocalizations.of(context);
    final selectedDoc = _controller.selectedDoctor;
    if (selectedDoc == null) return;

    // Show Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
        ),
        title: Row(
          children: [
            const Icon(Icons.assignment_turned_in_rounded, color: AdminColors.brandTeal, size: 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                strings.confirmAssignmentDialogTitle,
                style: AdminTheme.headline2.copyWith(fontSize: 16, color: AdminColors.brandNavy),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.confirmAssignmentDialogMessage,
              style: AdminTheme.bodyRegular.copyWith(fontSize: 13, color: AdminColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AdminTheme.radius8),
                border: Border.all(color: AdminColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryLine('Case:', widget.clinicalCase.caseId),
                  _buildSummaryLine('Department:', widget.clinicalCase.domain),
                  _buildSummaryLine('Assign To:', '${selectedDoc.name} (${selectedDoc.doctorId})'),
                  _buildSummaryLine('Target Dept:', selectedDoc.department),
                  _buildSummaryLine('Authority:', selectedDoc.authorityLevelDisplay),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancelButton, style: const TextStyle(color: AdminColors.textMuted)),
          ),
          AdminPrimaryButton(
            key: const ValueKey('modal_confirm_assignment_button'),
            label: strings.confirmButton,
            height: 36,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final updatedCase = await _controller.assignHigherAuthority();
      if (updatedCase != null && mounted) {
        Navigator.of(context).pop(true);
        widget.onAssignmentSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.assignmentSuccessNotification),
            backgroundColor: AdminColors.brandTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AdminTheme.caption.copyWith(fontWeight: FontWeight.bold, color: AdminColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AdminTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.brandNavy),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          boxShadow: AdminTheme.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminColors.brandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_ind_rounded, color: AdminColors.brandTeal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.assignHigherAuthorityDialogTitle,
                          style: AdminTheme.headline2.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.brandNavy),
                        ),
                        Text(
                          strings.assignHigherAuthorityDialogSubtitle,
                          style: AdminTheme.caption.copyWith(fontSize: 12, color: AdminColors.textSecondary),
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

            // 2. Modal Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Case & Escalation Baseline Card
                    _buildCaseContextCard(strings),
                    const SizedBox(height: 18),

                    // B. Cross-Department Transfer Option
                    _buildCrossDepartmentControl(strings),
                    const SizedBox(height: 18),

                    // C. Eligible Doctors Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.eligibleDoctorsSectionTitle,
                          style: AdminTheme.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!_controller.isLoading)
                          Text(
                            '${_controller.eligibleDoctors.length} doctors eligible',
                            style: AdminTheme.caption.copyWith(
                              color: AdminColors.brandTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // D. Eligible Doctors List / State
                    if (_controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AdminColors.brandTeal),
                        ),
                      )
                    else if (_controller.eligibleDoctors.isEmpty)
                      _buildEmptyEligibleDoctorsState(strings)
                    else
                      ..._controller.eligibleDoctors.map(_buildDoctorCard),

                    // E. Error Banner if applicable
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AdminColors.statusCritical.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AdminTheme.radius8),
                          border: Border.all(color: AdminColors.statusCritical.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AdminColors.statusCritical, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _controller.errorMessage!,
                                style: AdminTheme.caption.copyWith(
                                  color: AdminColors.statusCritical,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 3. Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AdminColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AdminTheme.radius16)),
                border: Border(top: BorderSide(color: AdminColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: strings.cancelButton,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AdminPrimaryButton(
                    key: const ValueKey('commit_higher_authority_assignment_button'),
                    label: _controller.isAssigning
                        ? strings.assigningHigherAuthorityButton
                        : strings.assignHigherAuthorityButton,
                    icon: Icons.check_circle_outline_rounded,
                    height: 38,
                    onPressed: (_controller.selectedDoctor == null || _controller.isAssigning)
                        ? () {}
                        : _handleConfirmAndAssign,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseContextCard(AdminStrings strings) {
    final c = widget.clinicalCase;
    final sourceName = c.escalatedByDoctorName ?? c.escalatedByDoctorId ?? 'Escalating Doctor';
    final sourceLevelText = 'Level ${_controller.sourceAuthorityLevel}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(color: AdminColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CASE CONTEXT',
                style: AdminTheme.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.statusCritical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ESCALATED CASE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.statusCritical),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _buildMetaItem('Case ID', c.caseId),
              _buildMetaItem('Patient ID', c.patientId),
              _buildMetaItem('Department', c.domain),
              _buildMetaItem('Escalated By', sourceName),
              _buildMetaItem('Source Authority', sourceLevelText, isBadge: true),
            ],
          ),
          if (c.escalationNote != null && c.escalationNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Doctor Note: ${c.escalationNote!}',
              style: AdminTheme.caption.copyWith(
                color: AdminColors.brandNavy,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, {bool isBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AdminTheme.caption.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: AdminColors.textMuted),
        ),
        const SizedBox(height: 2),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AdminColors.brandNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: const TextStyle(color: AdminColors.brandNavy, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          )
        else
          Text(
            value,
            style: AdminTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.brandNavy),
          ),
      ],
    );
  }

  Widget _buildCrossDepartmentControl(AdminStrings strings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(
          color: _controller.isCrossDepartment ? AdminColors.brandTeal : AdminColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _controller.isCrossDepartment,
                activeColor: AdminColors.brandTeal,
                onChanged: (val) => _controller.toggleCrossDepartment(val ?? false),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _controller.toggleCrossDepartment(!_controller.isCrossDepartment),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.crossDepartmentTransferOption,
                        style: AdminTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        strings.crossDepartmentTransferHelp,
                        style: AdminTheme.caption.copyWith(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_controller.isCrossDepartment) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _crossDeptReasonController,
              maxLines: 2,
              onChanged: (val) => _controller.setCrossDepartmentReason(val),
              decoration: InputDecoration(
                labelText: strings.crossDepartmentReasonLabel,
                hintText: strings.crossDepartmentReasonHint,
                hintStyle: AdminTheme.caption.copyWith(color: AdminColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyEligibleDoctorsState(AdminStrings strings) {
    return Container(
      key: const ValueKey('empty_eligible_doctors_state'),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AdminColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(color: AdminColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_search_rounded, color: AdminColors.textMuted, size: 36),
          const SizedBox(height: 10),
          Text(
            strings.noEligibleDoctorsTitle,
            textAlign: TextAlign.center,
            style: AdminTheme.headline2.copyWith(fontSize: 14, color: AdminColors.brandNavy),
          ),
          const SizedBox(height: 4),
          Text(
            strings.noEligibleDoctorsExplanation,
            textAlign: TextAlign.center,
            style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          AdminSecondaryButton(
            label: strings.retry,
            icon: Icons.refresh_rounded,
            height: 32,
            onPressed: _controller.initialize,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(DoctorProfile doc) {
    final isSelected = _controller.selectedDoctor?.doctorId == doc.doctorId;

    return Container(
      key: ValueKey('eligible_doctor_card_${doc.doctorId}'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AdminColors.brandTeal.withValues(alpha: 0.06)
            : AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(
          color: isSelected ? AdminColors.brandTeal : AdminColors.borderSubtle,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        onTap: () => _controller.selectDoctor(isSelected ? null : doc),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AdminColors.brandTeal : AdminColors.borderSubtle,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AdminColors.brandTeal,
                          ),
                        ),
                      )
                    : null,
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: AdminColors.brandNavy.withValues(alpha: 0.1),
                child: Text(
                  doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
                  style: const TextStyle(color: AdminColors.brandNavy, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doc.name,
                            style: AdminTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          doc.doctorId,
                          style: AdminTheme.caption.copyWith(color: AdminColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.qualification} • ${doc.department}',
                      style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: doc.clinicalAuthorityLevel >= 3
                          ? AdminColors.brandTeal.withValues(alpha: 0.15)
                          : AdminColors.brandOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Level ${doc.clinicalAuthorityLevel}',
                      style: TextStyle(
                        color: doc.clinicalAuthorityLevel >= 3
                            ? AdminColors.brandTeal
                            : AdminColors.brandOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AdminColors.statusAvailable,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AVAILABLE',
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.statusAvailable,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
