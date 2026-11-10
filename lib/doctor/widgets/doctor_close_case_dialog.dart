import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/clinical_case.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog for an authorized Doctor to explicitly declare and close an OPEN Case.
class DoctorCloseCaseDialog extends StatefulWidget {
  final ClinicalCase clinicalCase;
  final KioskLocale locale;

  const DoctorCloseCaseDialog({
    super.key,
    required this.clinicalCase,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorCloseCaseDialog> createState() => _DoctorCloseCaseDialogState();
}

class _DoctorCloseCaseDialogState extends State<DoctorCloseCaseDialog> {
  late final TextEditingController _noteController;
  bool _declarationConfirmed = false;
  String? _validationError;

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

  void _onConfirmClose() {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final note = _noteController.text.trim();

    if (!_declarationConfirmed) {
      setState(() {
        _validationError = strings.closureDeclarationError;
      });
      return;
    }

    if (note.isEmpty) {
      setState(() {
        _validationError = strings.closureNoteRequiredError;
      });
      return;
    }

    if (note.length > 1000) {
      setState(() {
        _validationError = strings.closureNoteTooLongError;
      });
      return;
    }

    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final c = widget.clinicalCase;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        side: const BorderSide(color: DoctorColors.dialogBorder, width: 1.0),
      ),
      backgroundColor: DoctorColors.dialogBg,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Container(
          padding: const EdgeInsets.all(DoctorTheme.space24),
          decoration: BoxDecoration(
            color: DoctorColors.dialogBg,
            borderRadius: BorderRadius.circular(DoctorTheme.radius16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DoctorColors.brandOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: DoctorColors.brandOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.closeCaseTitle.toUpperCase(),
                        style: DoctorTheme.headline2.copyWith(
                          color: DoctorColors.dialogPrimaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.closeCaseSubtitle,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.dialogSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: DoctorColors.dialogSecondaryText),
                  onPressed: () => Navigator.of(context).pop(null),
                  tooltip: strings.cancel,
                ),
              ],
            ),
            const SizedBox(height: DoctorTheme.space16),

            // Case Details Card
            Container(
              padding: const EdgeInsets.all(DoctorTheme.space12),
              decoration: BoxDecoration(
                color: DoctorColors.dialogPageTint,
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(color: DoctorColors.dialogBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.domain} • ${c.title}',
                          style: DoctorTheme.bodyBold.copyWith(
                            color: DoctorColors.dialogPrimaryText,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${strings.cases}: ${c.caseId} (${c.visitCount} ${strings.visits.toLowerCase()})',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.dialogSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DoctorColors.statusAvailable.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                    ),
                    child: Text(
                      strings.openCase,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.statusAvailable,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DoctorTheme.space16),

            // Clinical Guidance Explanation
            Text(
              strings.closeCaseExplanation,
              style: DoctorTheme.bodyRegular.copyWith(
                color: DoctorColors.dialogSecondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: DoctorTheme.space16),

            // Mandatory Doctor Declaration Checkbox
            InkWell(
              onTap: () {
                setState(() {
                  _declarationConfirmed = !_declarationConfirmed;
                  if (_declarationConfirmed) _validationError = null;
                });
              },
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              child: Container(
                padding: const EdgeInsets.all(DoctorTheme.space12),
                decoration: BoxDecoration(
                  color: _declarationConfirmed
                      ? DoctorColors.dialogPrimaryTeal.withValues(alpha: 0.08)
                      : DoctorColors.dialogPageTint,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(
                    color: _declarationConfirmed
                        ? DoctorColors.dialogPrimaryTeal
                        : DoctorColors.dialogBorder,
                    width: _declarationConfirmed ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _declarationConfirmed,
                      activeColor: DoctorColors.dialogPrimaryTeal,
                      onChanged: (val) {
                        setState(() {
                          _declarationConfirmed = val ?? false;
                          if (_declarationConfirmed) _validationError = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.closeCaseDeclarationCheckbox,
                        style: DoctorTheme.bodyBold.copyWith(
                          color: DoctorColors.dialogPrimaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DoctorTheme.space16),

            // Doctor-Entered Closure Note Field
            Text(
              strings.closureNoteLabel,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.dialogPrimaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 4,
              maxLength: 1000,
              style: const TextStyle(
                color: DoctorColors.dialogPrimaryText,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: strings.closureNoteHint,
                hintStyle: DoctorTheme.bodyMuted.copyWith(
                  color: DoctorColors.dialogSecondaryText,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: DoctorColors.dialogPageTint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  borderSide: const BorderSide(color: DoctorColors.dialogBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  borderSide: const BorderSide(color: DoctorColors.dialogBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  borderSide: const BorderSide(color: DoctorColors.dialogPrimaryTeal, width: 1.5),
                ),
              ),
              onChanged: (_) {
                setState(() {
                  if (_validationError != null) _validationError = null;
                });
              },
            ),

            // Validation error message if any
            if (_validationError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DoctorColors.dialogWarningBg,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  border: Border.all(color: DoctorColors.dialogWarningBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 14, color: DoctorColors.dialogWarningText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.dialogWarningText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: DoctorTheme.space20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DoctorSecondaryButton(
                  label: strings.cancel,
                  onPressed: () => Navigator.of(context).pop(null),
                  height: 40,
                ),
                const SizedBox(width: DoctorTheme.space12),
                DoctorPrimaryButton(
                  label: strings.closeCaseButton,
                  icon: Icons.lock_outline_rounded,
                  onPressed: (_declarationConfirmed &&
                          _noteController.text.trim().isNotEmpty)
                      ? _onConfirmClose
                      : null,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
