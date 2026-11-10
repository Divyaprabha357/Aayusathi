import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Dedicated UI card for the Gemini Clinical Documentation Assistant in the Doctor Workspace.
///
/// Features:
/// - Clean medical aesthetic matching the AAYUSATHI greenish-white design system.
/// - Validates mandatory field completeness and displays missing field alerts.
/// - Provides progress loading state without flashy AI animations.
/// - Displays draft disclaimer and development mode indicator.
/// - Manages generate and regenerate draft actions safely.
class DoctorGeminiDocumentationCard extends StatelessWidget {
  final bool isGenerating;
  final bool isComplete;
  final List<String> missingFields;
  final bool hasDraft;
  final String? errorMessage;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final VoidCallback? onDismissError;
  final KioskLocale locale;

  const DoctorGeminiDocumentationCard({
    super.key,
    required this.isGenerating,
    required this.isComplete,
    this.missingFields = const [],
    this.hasDraft = false,
    this.errorMessage,
    required this.onGenerate,
    required this.onRegenerate,
    this.onDismissError,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);
    final isDevMode = DoctorSessionService.instance.isDevelopmentMode;

    return Container(
      key: const Key('gemini_documentation_card'),
      padding: const EdgeInsets.all(DoctorTheme.space20),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: isGenerating
              ? DoctorColors.brandTeal.withValues(alpha: 0.6)
              : DoctorColors.border,
          width: isGenerating ? 1.5 : 1.0,
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DoctorColors.brandTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: DoctorColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    strings.doctorAssistedDocumentation,
                    style: DoctorTheme.badgeText.copyWith(
                      color: DoctorColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDevMode) ...[
                    Container(
                      key: const Key('gemini_dev_mode_badge'),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DoctorColors.statusBusy.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                        border: Border.all(
                          color: DoctorColors.statusBusy.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        strings.devModeBadge,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.statusBusy,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DoctorColors.brandTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                      border: Border.all(
                        color: DoctorColors.brandTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 12,
                          color: DoctorColors.brandTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.aiAssistedBadge,
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.brandTeal,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space8),

          // Subtitle / Disclaimer
          Text(
            strings.aiDraftDisclaimer,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),

          // Error Banner if present
          if (errorMessage != null) ...[
            Container(
              key: const Key('gemini_error_banner'),
              padding: const EdgeInsets.all(DoctorTheme.space12),
              margin: const EdgeInsets.only(bottom: DoctorTheme.space16),
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
                    Icons.error_outline_rounded,
                    color: DoctorColors.statusCritical,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.statusCritical,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (onDismissError != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: DoctorColors.statusCritical,
                      onPressed: onDismissError,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ],

          // Active Generating State
          if (isGenerating) ...[
            Container(
              key: const Key('gemini_generating_indicator'),
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space16,
                vertical: DoctorTheme.space12,
              ),
              decoration: BoxDecoration(
                color: DoctorColors.background,
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(color: DoctorColors.border),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.aiPreparingDocumentation,
                      style: DoctorTheme.bodyRegular.copyWith(
                        color: DoctorColors.brandNavy,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!isComplete) ...[
            // Incomplete Mandatory Fields Notice
            Container(
              key: const Key('gemini_incomplete_notice'),
              padding: const EdgeInsets.all(DoctorTheme.space12),
              decoration: BoxDecoration(
                color: DoctorColors.brandOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(
                  color: DoctorColors.brandOrange.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: DoctorColors.brandOrange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.completeMandatoryFieldsPrompt,
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.brandOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (missingFields.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Missing: ${missingFields.join(", ")}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Ready State: Action Button (Generate or Regenerate)
            Row(
              children: [
                if (!hasDraft)
                  ElevatedButton.icon(
                    key: const Key('generate_draft_summary_button'),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(
                      strings.generateDraftSummary,
                      style: DoctorTheme.buttonText.copyWith(
                        color: DoctorColors.brandNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DoctorColors.brandTeal,
                      foregroundColor: DoctorColors.brandNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onGenerate,
                  )
                else
                  OutlinedButton.icon(
                    key: const Key('regenerate_draft_summary_button'),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      strings.regenerateDraftSummary,
                      style: DoctorTheme.buttonText.copyWith(
                        color: DoctorColors.brandTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DoctorColors.brandTeal,
                      side: const BorderSide(color: DoctorColors.brandTeal, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      ),
                    ),
                    onPressed: onRegenerate,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirmation dialog when doctor requests regeneration of documentation draft over existing edits.
class DoctorRegenerateWarningDialog extends StatelessWidget {
  final KioskLocale locale;

  const DoctorRegenerateWarningDialog({
    super.key,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return AlertDialog(
      key: const Key('gemini_regenerate_warning_dialog'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: DoctorColors.brandOrange,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            strings.regenerateWarningTitle,
            style: DoctorTheme.headline2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Text(
        strings.regenerateWarningPrompt,
        style: DoctorTheme.bodyRegular.copyWith(fontSize: 13, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          key: const Key('gemini_dialog_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            strings.cancel,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('gemini_dialog_confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: DoctorColors.brandTeal,
            foregroundColor: DoctorColors.brandNavy,
          ),
          child: Text(
            strings.regenerateButton,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.brandNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
