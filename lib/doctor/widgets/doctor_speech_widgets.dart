import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../services/speech_to_text_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Interactive Microphone trigger button attached to a clinical input field.
class DoctorSpeechFieldButton extends StatefulWidget {
  final String fieldId;
  final String fieldLabel;
  final String? activeListeningField;
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onTrigger;
  final KioskLocale locale;

  const DoctorSpeechFieldButton({
    super.key,
    required this.fieldId,
    required this.fieldLabel,
    required this.activeListeningField,
    required this.isListening,
    this.isProcessing = false,
    required this.onTrigger,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorSpeechFieldButton> createState() => _DoctorSpeechFieldButtonState();
}

class _DoctorSpeechFieldButtonState extends State<DoctorSpeechFieldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_isSelfActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  bool get _isSelfActive =>
      widget.activeListeningField == widget.fieldId && widget.isListening;

  bool get _isSelfProcessing =>
      widget.activeListeningField == widget.fieldId &&
      (widget.isProcessing || SpeechToTextService.instance.isProcessing);

  @override
  void didUpdateWidget(DoctorSpeechFieldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSelfActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_isSelfActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final isProcessing =
        widget.isProcessing || SpeechToTextService.instance.isProcessing;
    final isSelfActive = _isSelfActive;
    final isSelfProcessing = _isSelfProcessing;
    final isOtherActive =
        widget.activeListeningField != null && !isSelfActive && widget.isListening;
    final isBusy = isOtherActive || isProcessing;

    final tooltipMsg = isSelfActive
        ? strings.recordingActive
        : (isSelfProcessing
            ? strings.processingSpeech
            : (isBusy
                ? (isProcessing
                    ? strings.processingSpeech
                    : 'Another field is currently recording')
                : strings.dictateField));

    return Tooltip(
      message: tooltipMsg,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('speech_mic_button_${widget.fieldId}'),
          onTap: isBusy ? null : widget.onTrigger,
          borderRadius: BorderRadius.circular(DoctorTheme.radius6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelfActive
                  ? DoctorColors.statusCritical.withValues(alpha: 0.12)
                  : (isSelfProcessing
                      ? DoctorColors.brandTeal.withValues(alpha: 0.14)
                      : (isBusy
                          ? Colors.transparent
                          : DoctorColors.brandTeal.withValues(alpha: 0.08))),
              borderRadius: BorderRadius.circular(DoctorTheme.radius6),
              border: Border.all(
                color: isSelfActive
                    ? DoctorColors.statusCritical
                    : (isSelfProcessing
                        ? DoctorColors.brandTeal
                        : (isBusy
                            ? DoctorColors.border.withValues(alpha: 0.5)
                            : DoctorColors.brandTeal.withValues(alpha: 0.3))),
                width: (isSelfActive || isSelfProcessing) ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelfActive) ...[
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: DoctorColors.statusCritical,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.mic_rounded,
                    size: 14,
                    color: DoctorColors.statusCritical,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'REC',
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.statusCritical,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ] else if (isSelfProcessing) ...[
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PROCESSING',
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.brandTeal,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.mic_none_rounded,
                    size: 14,
                    color: isBusy
                        ? DoctorColors.textMuted.withValues(alpha: 0.4)
                        : DoctorColors.brandTeal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'DICTATE',
                    style: DoctorTheme.caption.copyWith(
                      color: isBusy
                          ? DoctorColors.textMuted.withValues(alpha: 0.4)
                          : DoctorColors.brandTeal,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating active recording status and controls bar.
class DoctorSpeechRecordingBar extends StatelessWidget {
  final String fieldId;
  final String fieldLabel;
  final Duration elapsedDuration;
  final String? partialTranscript;
  final bool isProcessing;
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final KioskLocale locale;

  const DoctorSpeechRecordingBar({
    super.key,
    required this.fieldId,
    required this.fieldLabel,
    required this.elapsedDuration,
    this.partialTranscript,
    this.isProcessing = false,
    required this.onStop,
    required this.onCancel,
    this.locale = KioskLocale.english,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      key: const Key('speech_recording_bar'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DoctorColors.brandNavy,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: DoctorColors.brandTeal.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          return Row(
            children: [
              // Live pulse recording indicator & badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DoctorColors.statusCritical.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(
                    color: DoctorColors.statusCritical.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AudioWaveformAnimation(isProcessing: isProcessing),
                    const SizedBox(width: 8),
                    Text(
                      isProcessing ? strings.processingSpeech : strings.listeningToSpeech,
                      style: DoctorTheme.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Target field and elapsed duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FIELD: ',
                        style: DoctorTheme.caption.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          fieldLabel.toUpperCase(),
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.brandTeal,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(elapsedDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Live partial transcript preview
              if (!isCompact)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    ),
                    child: Text(
                      (partialTranscript != null && partialTranscript!.isNotEmpty)
                          ? partialTranscript!
                          : 'Doctor speech is streaming live...',
                      style: TextStyle(
                        color: (partialTranscript != null && partialTranscript!.isNotEmpty)
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                const Spacer(),

              const SizedBox(width: 12),

              // Action buttons: Cancel and Stop & Insert
              TextButton.icon(
                key: const Key('speech_cancel_button'),
                onPressed: isProcessing ? null : onCancel,
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                label: Text(
                  strings.cancel,
                  style: DoctorTheme.caption.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              ElevatedButton.icon(
                key: const Key('speech_stop_button'),
                onPressed: isProcessing ? null : onStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorColors.brandTeal,
                  foregroundColor: DoctorColors.brandNavy,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  ),
                ),
                icon: isProcessing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(DoctorColors.brandNavy),
                        ),
                      )
                    : const Icon(Icons.stop_rounded, size: 16),
                label: Text(
                  strings.stopDictation,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.brandNavy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Simulated audio equalizer waveform bars.
class _AudioWaveformAnimation extends StatefulWidget {
  final bool isProcessing;
  const _AudioWaveformAnimation({this.isProcessing = false});

  @override
  State<_AudioWaveformAnimation> createState() => _AudioWaveformAnimationState();
}

class _AudioWaveformAnimationState extends State<_AudioWaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isProcessing) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBar(0.4 + (_controller.value * 0.6)),
            const SizedBox(width: 2),
            _buildBar(1.0 - (_controller.value * 0.5)),
            const SizedBox(width: 2),
            _buildBar(0.3 + (_controller.value * 0.7)),
            const SizedBox(width: 2),
            _buildBar(0.8 - (_controller.value * 0.4)),
          ],
        );
      },
    );
  }

  Widget _buildBar(double factor) {
    return Container(
      width: 3,
      height: 14 * factor.clamp(0.2, 1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Dialog presented when dictating into a clinical field that already contains text.
class DoctorSpeechAppendReplaceDialog extends StatelessWidget {
  final String fieldLabel;
  final String existingText;
  final String newTranscript;
  final KioskLocale locale;

  const DoctorSpeechAppendReplaceDialog({
    super.key,
    required this.fieldLabel,
    required this.existingText,
    required this.newTranscript,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      title: Row(
        children: [
          const Icon(Icons.merge_type_rounded,
              color: DoctorColors.brandTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.appendOrReplaceTitle,
              style: DoctorTheme.headline2.copyWith(
                color: DoctorColors.brandNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.appendOrReplacePrompt,
              style: DoctorTheme.bodyRegular.copyWith(
                color: DoctorColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Existing text snippet
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DoctorColors.background,
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(color: DoctorColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT TEXT IN $fieldLabel:',
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    existingText,
                    style: DoctorTheme.bodyMuted.copyWith(
                      color: DoctorColors.textPrimary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // New transcript snippet
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DoctorColors.brandTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(
                  color: DoctorColors.brandTeal.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEW SPEECH TRANSCRIPT:',
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.brandTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    newTranscript,
                    style: DoctorTheme.bodyBold.copyWith(
                      color: DoctorColors.brandNavy,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          key: const Key('speech_append_replace_cancel'),
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            strings.cancel,
            style: const TextStyle(color: DoctorColors.textSecondary),
          ),
        ),
        OutlinedButton(
          key: const Key('speech_replace_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DoctorColors.statusCritical,
            side: const BorderSide(color: DoctorColors.statusCritical),
          ),
          onPressed: () => Navigator.of(context).pop('replace'),
          child: Text(strings.replaceButton),
        ),
        ElevatedButton(
          key: const Key('speech_append_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DoctorColors.brandTeal,
            foregroundColor: DoctorColors.brandNavy,
          ),
          onPressed: () => Navigator.of(context).pop('append'),
          child: Text(
            strings.appendButton,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Helper banner for speech-to-text error states.
class DoctorSpeechErrorCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;
  final KioskLocale locale;

  const DoctorSpeechErrorCard({
    super.key,
    required this.errorMessage,
    required this.onDismiss,
    this.onRetry,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      key: const Key('speech_error_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DoctorColors.statusCritical.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(
          color: DoctorColors.statusCritical.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_off_rounded,
              color: DoctorColors.statusCritical, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.speechErrorTitle,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.statusCritical,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  errorMessage,
                  style: DoctorTheme.bodyMuted.copyWith(
                    color: DoctorColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            TextButton(
              onPressed: onRetry,
              child: Text(
                strings.retryButton,
                style: const TextStyle(
                  color: DoctorColors.statusCritical,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: DoctorColors.textMuted,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
