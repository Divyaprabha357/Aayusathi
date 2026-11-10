import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/transcript_cleanup_input.dart';
import '../services/doctor_session_service.dart';
import '../services/gemini_transcript_cleanup_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// The doctor's explicit acceptance choice from the review modal.
enum TranscriptChoiceType {
  cleaned,
  original,
  edited,
}

/// Structured response object returned when the doctor accepts or dismisses the review dialog.
class DoctorTranscriptReviewResult {
  final String acceptedText;
  final TranscriptChoiceType choiceType;
  final String originalTranscript;
  final String cleanedDraft;

  const DoctorTranscriptReviewResult({
    required this.acceptedText,
    required this.choiceType,
    required this.originalTranscript,
    required this.cleanedDraft,
  });
}

/// Clinical Review Modal presented after speech-to-text finishes.
///
/// Features & Invariants:
/// - Displays both the raw STT transcript and the Gemini-cleaned draft.
/// - Never overwrites consultation fields without explicit doctor approval.
/// - Allows the doctor to choose between Cleaned Version, Original STT, or Manual Edit.
/// - Provides a safe "CLEAN AGAIN" option that always regenerates from the ORIGINAL STT transcript.
/// - Displays ambiguity / uncertainty warnings when detected.
class DoctorVoiceTranscriptReviewDialog extends StatefulWidget {
  final String fieldId;
  final String fieldLabel;
  final String originalTranscript;
  final KioskLocale locale;
  final GeminiTranscriptCleanupService? cleanupService;

  const DoctorVoiceTranscriptReviewDialog({
    super.key,
    required this.fieldId,
    required this.fieldLabel,
    required this.originalTranscript,
    this.locale = KioskLocale.english,
    this.cleanupService,
  });

  @override
  State<DoctorVoiceTranscriptReviewDialog> createState() =>
      _DoctorVoiceTranscriptReviewDialogState();
}

class _DoctorVoiceTranscriptReviewDialogState
    extends State<DoctorVoiceTranscriptReviewDialog> {
  late GeminiTranscriptCleanupService _cleanupService;
  late TextEditingController _editingController;

  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;
  late String _originalText;
  late String _cleanedText;
  List<String> _uncertainSegments = const [];

  @override
  void initState() {
    super.initState();
    _cleanupService =
        widget.cleanupService ?? GeminiTranscriptCleanupService.instance;
    _originalText = widget.originalTranscript.trim();
    _cleanedText = _originalText;
    _editingController = TextEditingController(text: _originalText);

    _performCleanup();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  Future<void> _performCleanup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final input = TranscriptCleanupInput(
      transcript: _originalText,
      locale: widget.locale,
    );

    try {
      final result = await _cleanupService.cleanupTranscript(input);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.isSuccess) {
            _cleanedText = result.cleanedTranscript;
            _uncertainSegments = result.uncertainSegments;
            if (!_isEditing) {
              _editingController.text = _cleanedText;
            }
          } else {
            _errorMessage = result.errorMessage;
            _cleanedText = _originalText;
            if (!_isEditing) {
              _editingController.text = _originalText;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _cleanedText = _originalText;
          if (!_isEditing) {
            _editingController.text = _originalText;
          }
        });
      }
    }
  }

  Future<void> _handleCleanAgain() async {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        ),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: DoctorColors.brandTeal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.cleanAgainTitle,
                style: DoctorTheme.headline2.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          strings.cleanAgainPrompt,
          style: DoctorTheme.bodyRegular,
        ),
        actions: [
          TextButton(
            key: const Key('clean_again_cancel_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            key: const Key('clean_again_confirm_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorColors.brandTeal,
              foregroundColor: DoctorColors.brandNavy,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              strings.cleanAgainConfirm,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_isEditing) {
        setState(() {
          _isEditing = false;
        });
      }
      await _performCleanup();
    }
  }

  void _acceptCleaned() {
    final text = _isEditing ? _editingController.text.trim() : _cleanedText;
    final choice = _isEditing ? TranscriptChoiceType.edited : TranscriptChoiceType.cleaned;
    Navigator.of(context).pop(
      DoctorTranscriptReviewResult(
        acceptedText: text,
        choiceType: choice,
        originalTranscript: _originalText,
        cleanedDraft: _cleanedText,
      ),
    );
  }

  void _acceptOriginal() {
    Navigator.of(context).pop(
      DoctorTranscriptReviewResult(
        acceptedText: _originalText,
        choiceType: TranscriptChoiceType.original,
        originalTranscript: _originalText,
        cleanedDraft: _cleanedText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final isDevMode = DoctorSessionService.instance.isDevelopmentMode;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 680,
          maxHeight: 720,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DoctorColors.brandTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: DoctorColors.brandTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              strings.voiceTranscriptReviewTitle,
                              style: DoctorTheme.headline2.copyWith(
                                color: DoctorColors.brandNavy,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            if (isDevMode) ...[
                              Container(
                                key: const Key('transcript_dev_mode_badge'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DoctorColors.statusBusy
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: DoctorColors.statusBusy
                                        .withValues(alpha: 0.3),
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
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: DoctorColors.brandTeal
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: DoctorColors.brandTeal
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                strings.aiAssistedBadge,
                                style: DoctorTheme.caption.copyWith(
                                  color: DoctorColors.brandTeal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'FIELD: ${widget.fieldLabel.toUpperCase()}',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('transcript_close_button'),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: DoctorColors.textMuted,
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Area (Scrollable)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Original STT Transcript Section
                      Container(
                        key: const Key('transcript_original_container'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DoctorColors.background,
                          borderRadius:
                              BorderRadius.circular(DoctorTheme.radius8),
                          border: Border.all(color: DoctorColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.mic_none_rounded,
                                  size: 14,
                                  color: DoctorColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  strings.originalTranscriptLabel,
                                  style: DoctorTheme.caption.copyWith(
                                    color: DoctorColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              _originalText,
                              style: DoctorTheme.bodyMuted.copyWith(
                                color: DoctorColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Cleaned Transcript Draft Section
                      Container(
                        key: const Key('transcript_cleaned_container'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _errorMessage != null
                              ? DoctorColors.statusCritical.withValues(alpha: 0.05)
                              : DoctorColors.brandTeal.withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(DoctorTheme.radius8),
                          border: Border.all(
                            color: _errorMessage != null
                                ? DoctorColors.statusCritical.withValues(alpha: 0.4)
                                : DoctorColors.brandTeal.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: _errorMessage != null
                                          ? DoctorColors.statusCritical
                                          : DoctorColors.brandTeal,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      strings.geminiCleanedDraftLabel,
                                      style: DoctorTheme.caption.copyWith(
                                        color: _errorMessage != null
                                            ? DoctorColors.statusCritical
                                            : DoctorColors.brandTeal,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_isLoading) ...[
                                  InkWell(
                                    key: const Key('transcript_clean_again_button'),
                                    onTap: _handleCleanAgain,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.refresh_rounded,
                                            size: 13,
                                            color: DoctorColors.brandTeal,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            strings.cleanAgain,
                                            style: DoctorTheme.caption.copyWith(
                                              color: DoctorColors.brandTeal,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Loading state
                            if (_isLoading) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            DoctorColors.brandTeal),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      strings.aiCleaningInProgress,
                                      style: DoctorTheme.bodyMuted.copyWith(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_errorMessage != null) ...[
                              // Error banner
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: DoctorColors.statusCritical
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: DoctorColors.statusCritical,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        strings.cleanupUnavailable,
                                        style: DoctorTheme.caption.copyWith(
                                          color: DoctorColors.statusCritical,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_isEditing) ...[
                              // Inline Editable TextField
                              TextField(
                                key: const Key('transcript_edit_textfield'),
                                controller: _editingController,
                                maxLines: 4,
                                style: DoctorTheme.bodyRegular.copyWith(
                                  color: DoctorColors.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: DoctorColors.brandTeal,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Display cleaned text
                              SelectableText(
                                _cleanedText,
                                style: DoctorTheme.bodyBold.copyWith(
                                  color: DoctorColors.brandNavy,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],

                            // Uncertain segments warning box
                            if (!_isLoading && _uncertainSegments.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                key: const Key('transcript_uncertainty_box'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: DoctorColors.statusBusy
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: DoctorColors.statusBusy
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 15,
                                      color: DoctorColors.statusBusy,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${strings.unclearPhraseWarning} (${_uncertainSegments.join(", ")})',
                                        style: DoctorTheme.caption.copyWith(
                                          color: DoctorColors.statusBusy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
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
                      const SizedBox(height: 12),

                      // Draft Disclaimer
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 14,
                            color: DoctorColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              strings.aiDraftNotice,
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Cancel button
                  TextButton(
                    key: const Key('transcript_review_cancel_button'),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      strings.cancel,
                      style: const TextStyle(color: DoctorColors.textSecondary),
                    ),
                  ),

                  // Edit Mode Toggle Button
                  OutlinedButton.icon(
                    key: const Key('transcript_edit_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DoctorColors.brandNavy,
                      side: const BorderSide(color: DoctorColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (_isEditing) {
                          _editingController.text = _cleanedText;
                        }
                      });
                    },
                    icon: Icon(
                      _isEditing
                          ? Icons.check_circle_outline_rounded
                          : Icons.edit_note_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _isEditing ? strings.doneEditing : strings.editManually,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  // Use Original Button
                  OutlinedButton(
                    key: const Key('transcript_use_original_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DoctorColors.brandNavy,
                      side: const BorderSide(color: DoctorColors.brandTeal),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _acceptOriginal,
                    child: Text(
                      strings.useOriginal,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  // Use Cleaned / Accepted Button
                  ElevatedButton(
                    key: const Key('transcript_use_cleaned_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DoctorColors.brandTeal,
                      foregroundColor: DoctorColors.brandNavy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _acceptCleaned,
                    child: Text(
                      strings.useCleanedVersion,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
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
