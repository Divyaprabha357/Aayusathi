import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/prescription_item.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_speech_widgets.dart';

/// Controller holder for a single prescription table row.
class PrescriptionRowControllers {
  final TextEditingController medicineController;
  final TextEditingController durationController;
  final TextEditingController timesPerDayController;
  final TextEditingController remarksController;

  PrescriptionRowControllers({
    String medicineName = '',
    String duration = '',
    String timesPerDay = '',
    String remarks = '',
  })  : medicineController = TextEditingController(text: medicineName),
        durationController = TextEditingController(text: duration),
        timesPerDayController = TextEditingController(text: timesPerDay),
        remarksController = TextEditingController(text: remarks);

  factory PrescriptionRowControllers.fromItem(PrescriptionItem item) {
    return PrescriptionRowControllers(
      medicineName: item.medicineName,
      duration: item.duration,
      timesPerDay: item.timesPerDay,
      remarks: item.remarks,
    );
  }

  PrescriptionItem toPrescriptionItem() {
    return PrescriptionItem(
      medicineName: medicineController.text.trim(),
      duration: durationController.text.trim(),
      timesPerDay: timesPerDayController.text.trim(),
      remarks: remarksController.text.trim(),
    );
  }

  void dispose() {
    medicineController.dispose();
    durationController.dispose();
    timesPerDayController.dispose();
    remarksController.dispose();
  }
}

/// Dedicated Prescription Card inside the consultation workstation.
class DoctorPrescriptionCard extends StatefulWidget {
  final List<PrescriptionRowControllers> rows;
  final VoidCallback onAddMedicine;
  final ValueChanged<int> onRemoveMedicine;
  final ValueChanged<int> onCreateWithCount;
  final VoidCallback onDictate;
  final bool isListening;
  final String? activeListeningField;
  final String? prescriptionTranscript;
  final VoidCallback onUseTranscript;
  final ValueChanged<String>? onTranscriptChanged;
  final VoidCallback onDiscardTranscript;
  final KioskLocale locale;

  const DoctorPrescriptionCard({
    super.key,
    required this.rows,
    required this.onAddMedicine,
    required this.onRemoveMedicine,
    required this.onCreateWithCount,
    required this.onDictate,
    this.isListening = false,
    this.activeListeningField,
    this.prescriptionTranscript,
    required this.onUseTranscript,
    this.onTranscriptChanged,
    required this.onDiscardTranscript,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorPrescriptionCard> createState() => _DoctorPrescriptionCardState();
}

class _DoctorPrescriptionCardState extends State<DoctorPrescriptionCard> {
  int _desiredCount = 3;
  late TextEditingController _transcriptEditingController;

  @override
  void initState() {
    super.initState();
    _transcriptEditingController =
        TextEditingController(text: widget.prescriptionTranscript ?? '');
  }

  @override
  void didUpdateWidget(DoctorPrescriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prescriptionTranscript != oldWidget.prescriptionTranscript &&
        widget.prescriptionTranscript != _transcriptEditingController.text) {
      _transcriptEditingController.text = widget.prescriptionTranscript ?? '';
    }
  }

  @override
  void dispose() {
    _transcriptEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final hasRows = widget.rows.isNotEmpty;
    final isRecordingSelf = widget.activeListeningField == 'prescription' && widget.isListening;

    return Container(
      key: const Key('doctor_prescription_card'),
      padding: const EdgeInsets.all(DoctorTheme.space20),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: isRecordingSelf
              ? DoctorColors.statusCritical.withValues(alpha: 0.5)
              : DoctorColors.border,
          width: isRecordingSelf ? 1.5 : 1.0,
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Count Badge, and Unified Dictation Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.medication_outlined,
                    size: 20,
                    color: DoctorColors.brandNavy,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.prescriptionSectionTitle,
                    style: DoctorTheme.badgeText.copyWith(
                      color: DoctorColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (hasRows) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DoctorColors.brandTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                        border: Border.all(
                          color: DoctorColors.brandTeal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${widget.rows.length} ${widget.rows.length == 1 ? "MEDICINE" : "MEDICINES"}',
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.brandTeal,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Unified Prescription Voice-to-Text Button (ONE button for whole prescription)
              DoctorSpeechFieldButton(
                fieldId: 'prescription',
                fieldLabel: strings.prescription,
                activeListeningField: widget.activeListeningField,
                isListening: widget.isListening,
                onTrigger: widget.onDictate,
                locale: widget.locale,
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space16),

          // Prescription Transcript Review Box (if transcript exists)
          if (widget.prescriptionTranscript != null &&
              widget.prescriptionTranscript!.trim().isNotEmpty) ...[
            _buildTranscriptReviewBox(strings),
            const SizedBox(height: DoctorTheme.space16),
          ],

          // Prescription Rows Generator or Active Table
          if (!hasRows)
            _buildRowGenerator(strings)
          else
            _buildPrescriptionTable(strings),
        ],
      ),
    );
  }

  /// Initial state: Prompt for number of medicines with numeric counter
  Widget _buildRowGenerator(dynamic strings) {
    return Container(
      key: const Key('prescription_generator_box'),
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(
          color: DoctorColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.playlist_add_rounded,
                size: 18,
                color: DoctorColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.enterNumberOfMedicinesPrompt,
                  style: DoctorTheme.bodyRegular.copyWith(
                    fontSize: 13,
                    color: DoctorColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${strings.numberOfMedicines}:',
                    style: DoctorTheme.bodyBold.copyWith(
                      fontSize: 13,
                      color: DoctorColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stepper controls: [ − ]   2   [ + ]
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      border: Border.all(color: DoctorColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          key: const Key('prescription_count_decrement'),
                          tooltip: 'Decrease number of medicines',
                          icon: Icon(
                            Icons.remove_rounded,
                            size: 18,
                            color: _desiredCount > 1
                                ? DoctorColors.brandTeal
                                : DoctorColors.textMuted.withValues(alpha: 0.5),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _desiredCount > 1
                                ? DoctorColors.brandTeal.withValues(alpha: 0.12)
                                : DoctorColors.surfaceSubtle,
                            disabledBackgroundColor: DoctorColors.surfaceSubtle,
                            foregroundColor: DoctorColors.brandTeal,
                            disabledForegroundColor:
                                DoctorColors.textMuted.withValues(alpha: 0.5),
                            side: BorderSide(
                              color: _desiredCount > 1
                                  ? DoctorColors.brandTeal.withValues(alpha: 0.35)
                                  : DoctorColors.border,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                            ),
                            minimumSize: const Size(36, 36),
                            maximumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _desiredCount > 1
                              ? () => setState(() => _desiredCount--)
                              : null,
                        ),
                        Container(
                          width: 40,
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '$_desiredCount',
                            key: const Key('prescription_count_text'),
                            style: DoctorTheme.bodyBold.copyWith(
                              fontSize: 15,
                              color: DoctorColors.brandNavy,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('prescription_count_increment'),
                          tooltip: 'Increase number of medicines',
                          icon: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: _desiredCount < 20
                                ? DoctorColors.brandTeal
                                : DoctorColors.textMuted.withValues(alpha: 0.5),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _desiredCount < 20
                                ? DoctorColors.brandTeal.withValues(alpha: 0.12)
                                : DoctorColors.surfaceSubtle,
                            disabledBackgroundColor: DoctorColors.surfaceSubtle,
                            foregroundColor: DoctorColors.brandTeal,
                            disabledForegroundColor:
                                DoctorColors.textMuted.withValues(alpha: 0.5),
                            side: BorderSide(
                              color: _desiredCount < 20
                                  ? DoctorColors.brandTeal.withValues(alpha: 0.35)
                                  : DoctorColors.border,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                            ),
                            minimumSize: const Size(36, 36),
                            maximumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _desiredCount < 20
                              ? () => setState(() => _desiredCount++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('create_prescription_button'),
                onPressed: () => widget.onCreateWithCount(_desiredCount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorColors.brandTeal,
                  foregroundColor: DoctorColors.brandNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  ),
                  elevation: 1,
                ),
                icon: const Icon(Icons.table_chart_outlined, size: 16),
                label: Text(
                  strings.createPrescription,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.brandNavy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Active Prescription Table UI
  Widget _buildPrescriptionTable(dynamic strings) {
    return Column(
      key: const Key('prescription_table_container'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DoctorColors.brandNavy,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DoctorTheme.radius8)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  strings.srNo.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: DoctorTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Text(
                  strings.medicineName.toUpperCase(),
                  style: DoctorTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  strings.duration.toUpperCase(),
                  style: DoctorTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  strings.timesADay.toUpperCase(),
                  style: DoctorTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  strings.remarks.toUpperCase(),
                  style: DoctorTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 44), // space for delete action
            ],
          ),
        ),

        // Table Rows
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: DoctorColors.border),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(DoctorTheme.radius8)),
            color: Colors.white,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.rows.length,
            separatorBuilder: (ctx, idx) => const Divider(height: 1, color: DoctorColors.border),
            itemBuilder: (ctx, index) {
              final row = widget.rows[index];
              return _buildTableRow(index + 1, index, row, strings);
            },
          ),
        ),
        const SizedBox(height: DoctorTheme.space12),

        // Bottom Actions: + Add Medicine button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              key: const Key('add_medicine_button'),
              onPressed: widget.onAddMedicine,
              style: OutlinedButton.styleFrom(
                foregroundColor: DoctorColors.brandNavy,
                side: const BorderSide(color: DoctorColors.brandTeal, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16, color: DoctorColors.brandNavy),
              label: Text(
                strings.addMedicine,
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Single table row with editable text fields
  Widget _buildTableRow(
    int srNo,
    int rowIndex,
    PrescriptionRowControllers row,
    dynamic strings,
  ) {
    return Container(
      key: Key('prescription_row_$rowIndex'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: rowIndex.isEven ? Colors.white : DoctorColors.background.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Sr. No. (Auto-numbered, not editable)
          SizedBox(
            width: 50,
            child: Text(
              '$srNo',
              key: Key('prescription_sr_no_$rowIndex'),
              textAlign: TextAlign.center,
              style: DoctorTheme.bodyBold.copyWith(
                color: DoctorColors.brandNavy,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Name of Medicine (Manual Editable TextField)
          Expanded(
            flex: 4,
            child: TextField(
              key: Key('prescription_medicine_$rowIndex'),
              controller: row.medicineController,
              style: DoctorTheme.bodyRegular.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.medicineNameHint,
                hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Duration (Manual Editable TextField)
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('prescription_duration_$rowIndex'),
              controller: row.durationController,
              style: DoctorTheme.bodyRegular.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.durationHint,
                hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Times a Day (Manual Editable TextField)
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('prescription_times_$rowIndex'),
              controller: row.timesPerDayController,
              style: DoctorTheme.bodyRegular.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.timesADayHint,
                hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. Remarks (Manual Editable TextField)
          Expanded(
            flex: 3,
            child: TextField(
              key: Key('prescription_remarks_$rowIndex'),
              controller: row.remarksController,
              style: DoctorTheme.bodyRegular.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.remarksHint,
                hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Delete Row Button
          IconButton(
            key: Key('remove_medicine_button_$rowIndex'),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: DoctorColors.statusCritical,
              size: 20,
            ),
            tooltip: strings.removeMedicine,
            onPressed: () => widget.onRemoveMedicine(rowIndex),
          ),
        ],
      ),
    );
  }

  /// Editable transcript review area before moving content into structured table
  Widget _buildTranscriptReviewBox(dynamic strings) {
    return Container(
      key: const Key('prescription_transcript_box'),
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.brandNavy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(
          color: DoctorColors.brandTeal.withValues(alpha: 0.4),
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
                  const Icon(
                    Icons.record_voice_over_outlined,
                    size: 16,
                    color: DoctorColors.brandTeal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.prescriptionTranscript.toUpperCase(),
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.brandNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                key: const Key('prescription_transcript_discard'),
                icon: const Icon(Icons.close_rounded, size: 16, color: DoctorColors.textSecondary),
                tooltip: strings.cancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onDiscardTranscript,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('prescription_transcript_textfield'),
            controller: _transcriptEditingController,
            onChanged: widget.onTranscriptChanged,
            maxLines: 3,
            minLines: 2,
            style: DoctorTheme.bodyRegular.copyWith(fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                borderSide: const BorderSide(color: DoctorColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                borderSide: const BorderSide(color: DoctorColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('prescription_transcript_cancel_btn'),
                onPressed: widget.onDiscardTranscript,
                child: Text(
                  strings.cancel,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: const Key('use_in_prescription_button'),
                onPressed: widget.onUseTranscript,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  ),
                ),
                icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                label: Text(
                  strings.useInPrescription,
                  style: DoctorTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dialog for choosing whether to append or replace existing prescription when voice transcript is inserted
class DoctorPrescriptionAppendReplaceDialog extends StatelessWidget {
  final int existingCount;
  final KioskLocale locale;

  const DoctorPrescriptionAppendReplaceDialog({
    super.key,
    required this.existingCount,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return AlertDialog(
      key: const Key('prescription_append_replace_dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DoctorTheme.radius12)),
      title: Row(
        children: [
          const Icon(Icons.medical_services_outlined, color: DoctorColors.brandNavy, size: 22),
          const SizedBox(width: 8),
          Text(
            strings.prescription,
            style: DoctorTheme.headline2.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        'You already have $existingCount medicine(s) in your prescription table.\nWould you like to add the dictated items to your existing prescription or replace the table?',
        style: DoctorTheme.bodyRegular.copyWith(fontSize: 13, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          key: const Key('prescription_dialog_cancel'),
          onPressed: () => Navigator.of(context).pop('cancel'),
          child: Text(
            strings.cancel,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        OutlinedButton(
          key: const Key('prescription_dialog_replace'),
          onPressed: () => Navigator.of(context).pop('replace'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DoctorColors.statusCritical,
            side: const BorderSide(color: DoctorColors.statusCritical),
          ),
          child: Text(
            strings.replacePrescription,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.statusCritical,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('prescription_dialog_append'),
          onPressed: () => Navigator.of(context).pop('append'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DoctorColors.brandTeal,
            foregroundColor: DoctorColors.brandNavy,
          ),
          child: Text(
            strings.addToExistingPrescription,
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
