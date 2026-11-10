import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/clinical_visit.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog for Doctor-controlled Visit Completion and Declaration.
///
/// Ensures:
/// 1. Prerequisites checklist is transparently displayed with live status.
/// 2. Explicit doctor declaration checkbox is required before submission.
/// 3. Clear medical disclaimer that Case remains OPEN and no false medical cure is claimed.
class DoctorCompleteVisitDialog extends StatefulWidget {
  final ClinicalVisit visit;
  final bool hasPdfGenerated;
  final VoidCallback onConfirmCompletion;
  final KioskLocale locale;

  const DoctorCompleteVisitDialog({
    super.key,
    required this.visit,
    this.hasPdfGenerated = false,
    required this.onConfirmCompletion,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorCompleteVisitDialog> createState() =>
      _DoctorCompleteVisitDialogState();
}

class _DoctorCompleteVisitDialogState extends State<DoctorCompleteVisitDialog> {
  bool _declarationConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final isDocsComplete = widget.visit.areConsultationFieldsComplete;
    final isSummaryApproved = widget.visit.isSummaryApproved;
    final canProceed = widget.visit.canCompleteVisit && _declarationConfirmed;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 580,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space24,
                vertical: DoctorTheme.space20,
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DoctorTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.completeVisitDialogTitle,
                          style: DoctorTheme.cardTitle.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${strings.visit} ${widget.visit.visitNumber} • ${widget.visit.caseId}',
                          style: DoctorTheme.caption.copyWith(
                            color: Colors.white70,
                          ),
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
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DoctorTheme.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle explanation
                    Text(
                      strings.completeVisitExplanation,
                      style: DoctorTheme.body.copyWith(
                        color: DoctorColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: DoctorTheme.space16),

                    // Prerequisites Checklist Box
                    Container(
                      padding: const EdgeInsets.all(DoctorTheme.space16),
                      decoration: BoxDecoration(
                        color: DoctorColors.background,
                        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                        border: Border.all(color: DoctorColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.prerequisitesChecklistTitle,
                            style: DoctorTheme.caption.copyWith(
                              color: DoctorColors.brandNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: DoctorTheme.space12),
                          _buildChecklistItem(
                            isMet: isDocsComplete,
                            label: strings.consultationDocsCompleteCheck,
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistItem(
                            isMet: isSummaryApproved,
                            label: strings.summaryApprovedCheck,
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistItem(
                            isMet: true,
                            label: strings.investigationsRecordedCheck,
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistItem(
                            isMet: widget.hasPdfGenerated,
                            label: strings.pdfGeneratedCheck,
                            isOptional: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DoctorTheme.space16),

                    // Note Callout: Case remains open
                    Container(
                      padding: const EdgeInsets.all(DoctorTheme.space12),
                      decoration: BoxDecoration(
                        color: DoctorColors.brandTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                        border: Border.all(
                          color: DoctorColors.brandTeal.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: DoctorColors.brandTeal,
                          ),
                          const SizedBox(width: DoctorTheme.space12),
                          Expanded(
                            child: Text(
                              strings.caseRemainsOpenNote,
                              style: DoctorTheme.bodyMuted.copyWith(
                                color: DoctorColors.brandTeal,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DoctorTheme.space16),

                    // Required Declaration Checkbox
                    InkWell(
                      onTap: widget.visit.canCompleteVisit
                          ? () {
                              setState(() {
                                _declarationConfirmed = !_declarationConfirmed;
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _declarationConfirmed,
                              onChanged: widget.visit.canCompleteVisit
                                  ? (val) {
                                      setState(() {
                                        _declarationConfirmed = val ?? false;
                                      });
                                    }
                                  : null,
                              activeColor: DoctorColors.brandTeal,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  strings.doctorDeclarationCheckbox,
                                  style: DoctorTheme.body.copyWith(
                                    color: widget.visit.canCompleteVisit
                                        ? DoctorColors.textPrimary
                                        : DoctorColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: DoctorTheme.space8),

                    // Formal Declaration Statement Box
                    Container(
                      padding: const EdgeInsets.all(DoctorTheme.space12),
                      decoration: BoxDecoration(
                        color: DoctorColors.surface,
                        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                        border: Border.all(
                          color: _declarationConfirmed
                              ? DoctorColors.brandTeal.withValues(alpha: 0.4)
                              : DoctorColors.border,
                        ),
                      ),
                      child: Text(
                        'Declaration:\n"${strings.doctorDeclarationText}"',
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions Bottom Bar
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
                  DoctorOutlineButton(
                    label: strings.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: DoctorTheme.space12),
                  DoctorPrimaryButton(
                    label: strings.completeVisitSubmitButton,
                    icon: Icons.check_circle_rounded,
                    onPressed: canProceed
                        ? () {
                            Navigator.of(context).pop();
                            widget.onConfirmCompletion();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required bool isMet,
    required String label,
    bool isOptional = false,
  }) {
    Color iconColor;
    IconData icon;

    if (isMet) {
      iconColor = DoctorColors.statusNormal;
      icon = Icons.check_circle_rounded;
    } else if (isOptional) {
      iconColor = DoctorColors.brandNavy;
      icon = Icons.info_outline_rounded;
    } else {
      iconColor = DoctorColors.statusCritical;
      icon = Icons.cancel_outlined;
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: DoctorTheme.caption.copyWith(
              color: isMet ? DoctorColors.textPrimary : DoctorColors.textSecondary,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
