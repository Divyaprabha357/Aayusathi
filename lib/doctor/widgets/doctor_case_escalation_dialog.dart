import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/clinical_case.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog for requesting higher-authority administrative clinical case review (Phase A8).
///
/// Provides a controlled, structured reason selector for doctor-initiated
/// case escalation without interrupting the active consultation or closing the case.
class DoctorCaseEscalationDialog extends StatefulWidget {
  final ClinicalCase clinicalCase;
  final int currentVisitNumber;
  final String department;
  final KioskLocale locale;
  final Future<void> Function(CaseEscalationReason reason, String? note) onConfirm;

  const DoctorCaseEscalationDialog({
    super.key,
    required this.clinicalCase,
    required this.currentVisitNumber,
    required this.department,
    this.locale = KioskLocale.english,
    required this.onConfirm,
  });

  @override
  State<DoctorCaseEscalationDialog> createState() =>
      _DoctorCaseEscalationDialogState();
}

class _DoctorCaseEscalationDialogState extends State<DoctorCaseEscalationDialog> {
  CaseEscalationReason _selectedReason =
      CaseEscalationReason.clinicalDeterioration;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _getReasonLabel(CaseEscalationReason reason) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    switch (reason) {
      case CaseEscalationReason.clinicalDeterioration:
        return strings.reasonClinicalDeterioration;
      case CaseEscalationReason.repeatedVisitsNoResolution:
        return strings.reasonRepeatedVisits;
      case CaseEscalationReason.higherAuthorityReview:
        return strings.reasonHigherAuthority;
      case CaseEscalationReason.doctorConcern:
        return strings.reasonDoctorConcern;
      case CaseEscalationReason.other:
        return strings.reasonOther;
    }
  }

  Future<void> _handleSubmit() async {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    if (_selectedReason == CaseEscalationReason.other &&
        _noteController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = strings.escalationNoteRequiredError;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm(
        _selectedReason,
        _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final isAlreadyEscalated = widget.clinicalCase.isEscalated;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 580,
          maxHeight: 720,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(DoctorTheme.space20),
              decoration: const BoxDecoration(
                color: DoctorColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DoctorTheme.radius16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: DoctorColors.border,
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
                      color: DoctorColors.statusCritical.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: DoctorColors.statusCritical,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DoctorTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.escalateCaseDialogTitle,
                          style: DoctorTheme.headline2.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: DoctorColors.brandNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.escalateCaseDialogSubtitle,
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textSecondary,
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

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DoctorTheme.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case Metadata Overview Box
                    Container(
                      padding: const EdgeInsets.all(DoctorTheme.space12),
                      decoration: BoxDecoration(
                        color: DoctorColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                        border: Border.all(color: DoctorColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CASE ID',
                                  style: DoctorTheme.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: DoctorColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.clinicalCase.caseId,
                                  style: DoctorTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DoctorColors.brandNavy,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PATIENT ID',
                                  style: DoctorTheme.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: DoctorColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.clinicalCase.patientId,
                                  style: DoctorTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DoctorColors.brandNavy,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEPARTMENT',
                                  style: DoctorTheme.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: DoctorColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.department,
                                  style: DoctorTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DoctorColors.brandNavy,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT VISIT',
                                  style: DoctorTheme.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: DoctorColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Visit ${widget.currentVisitNumber}',
                                  style: DoctorTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DoctorColors.brandTeal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DoctorTheme.space16),

                    if (isAlreadyEscalated) ...[
                      // Warning if already escalated
                      Container(
                        padding: const EdgeInsets.all(DoctorTheme.space16),
                        decoration: BoxDecoration(
                          color: DoctorColors.statusCritical.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          border: Border.all(
                            color: DoctorColors.statusCritical.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: DoctorColors.statusCritical,
                              size: 20,
                            ),
                            const SizedBox(width: DoctorTheme.space12),
                            Expanded(
                              child: Text(
                                strings.caseAlreadyEscalatedMessage,
                                style: DoctorTheme.bodyRegular.copyWith(
                                  color: DoctorColors.statusCritical,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Reason Selection
                      Text(
                        strings.escalationReasonPrompt,
                        style: DoctorTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DoctorColors.brandNavy,
                        ),
                      ),
                      const SizedBox(height: DoctorTheme.space8),

                      ...CaseEscalationReason.values.map((reason) {
                        final isSelected = _selectedReason == reason;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DoctorColors.brandTeal.withValues(alpha: 0.06)
                                : DoctorColors.surface,
                            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                            border: Border.all(
                              color: isSelected
                                  ? DoctorColors.brandTeal
                                  : DoctorColors.border,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                            onTap: () {
                              setState(() {
                                _selectedReason = reason;
                                _errorMessage = null;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? DoctorColors.brandTeal
                                        : DoctorColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _getReasonLabel(reason),
                                      style: DoctorTheme.bodyRegular.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: DoctorColors.brandNavy,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Note field for additional details / 'Other'
                      const SizedBox(height: DoctorTheme.space12),
                      Text(
                        strings.escalationNoteLabel,
                        style: DoctorTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DoctorColors.brandNavy,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: DoctorTheme.space4),
                      TextField(
                        key: const ValueKey('doctor_escalation_note_input'),
                        controller: _noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: strings.escalationNoteHint,
                          hintStyle: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textMuted,
                          ),
                          filled: true,
                          fillColor: DoctorColors.backgroundSecondary,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DoctorTheme.radius8),
                            borderSide:
                                const BorderSide(color: DoctorColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DoctorTheme.radius8),
                            borderSide:
                                const BorderSide(color: DoctorColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DoctorTheme.radius8),
                            borderSide: const BorderSide(
                              color: DoctorColors.brandTeal,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),

                      // Non-interruption notice
                      const SizedBox(height: DoctorTheme.space12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DoctorColors.brandTeal.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          border: Border.all(
                            color: DoctorColors.brandTeal.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: DoctorColors.brandTeal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                strings.confirmEscalateNotice,
                                style: DoctorTheme.caption.copyWith(
                                  color: DoctorColors.brandTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Error display if any
                    if (_errorMessage != null) ...[
                      const SizedBox(height: DoctorTheme.space12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DoctorColors.statusCritical.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          border: Border.all(
                            color: DoctorColors.statusCritical.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.statusCritical,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(DoctorTheme.space16),
              decoration: const BoxDecoration(
                color: DoctorColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(DoctorTheme.radius16),
                ),
                border: Border(
                  top: BorderSide(
                    color: DoctorColors.border,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DoctorOutlineButton(
                    label: strings.cancel,
                    onPressed: _isSubmitting
                        ? () {}
                        : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: DoctorTheme.space12),
                  if (!isAlreadyEscalated)
                    DoctorPrimaryButton(
                      key: const ValueKey('confirm_escalate_button'),
                      label: _isSubmitting
                          ? strings.escalating
                          : strings.escalateCaseButton,
                      icon: Icons.warning_amber_rounded,
                      onPressed: _isSubmitting ? () {} : _handleSubmit,
                    )
                  else
                    DoctorPrimaryButton(
                      label: strings.close,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
