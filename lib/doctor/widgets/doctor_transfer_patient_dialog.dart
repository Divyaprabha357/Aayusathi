import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../models/opd_domain.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Interactive modal dialog for Doctor-initiated inter-department patient referral and transfer.
///
/// Multi-step workflow:
/// 1. Input Step: Select destination department (excluding current), enter non-empty transfer reason.
/// 2. Review Step: Explicit confirmation of transfer details with case preservation note.
class DoctorTransferPatientDialog extends StatefulWidget {
  final String currentDepartment;
  final String? patientId;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final ClinicalCase? clinicalCase;
  final ClinicalVisit? currentVisit;
  final Function(String destinationDepartment, String transferReason)? onConfirmTransfer;
  final Function(String destinationDepartment, String transferReason)? onTransferConfirmed;
  final KioskLocale locale;

  const DoctorTransferPatientDialog({
    super.key,
    required this.currentDepartment,
    this.patientId,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.clinicalCase,
    this.currentVisit,
    this.onConfirmTransfer,
    this.onTransferConfirmed,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorTransferPatientDialog> createState() =>
      _DoctorTransferPatientDialogState();
}

class _DoctorTransferPatientDialogState
    extends State<DoctorTransferPatientDialog> {
  int _currentStep = 0; // 0 = Input, 1 = Review
  String? _selectedDestinationDepartment;
  late final TextEditingController _reasonController;
  String? _reasonError;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<String> get _availableDepartments {
    final cleanCurrent = widget.currentDepartment.trim().toLowerCase();
    return OpdDomain.all
        .map((d) => _formatDepartmentName(d.id))
        .where((name) => name.toLowerCase() != cleanCurrent)
        .toList();
  }

  String _formatDepartmentName(String domainId) {
    switch (domainId.toLowerCase()) {
      case 'cardiology':
        return 'Cardiology';
      case 'neurology':
        return 'Neurology';
      case 'gastroenterology':
        return 'Gastroenterology';
      case 'orthopedics':
        return 'Orthopedics';
      case 'pediatrics':
        return 'Pediatrics';
      case 'ent':
        return 'ENT';
      case 'dermatology':
        return 'Dermatology';
      case 'general_medicine':
      default:
        return 'General Medicine';
    }
  }

  IconData _getDepartmentIcon(String dept) {
    switch (dept.toLowerCase()) {
      case 'cardiology':
        return Icons.favorite_rounded;
      case 'neurology':
        return Icons.psychology_rounded;
      case 'gastroenterology':
        return Icons.medication_rounded;
      case 'orthopedics':
        return Icons.accessibility_new_rounded;
      case 'pediatrics':
        return Icons.child_care_rounded;
      case 'ent':
        return Icons.hearing_rounded;
      case 'dermatology':
        return Icons.face_rounded;
      case 'general medicine':
      default:
        return Icons.local_hospital_rounded;
    }
  }

  bool _validateInput() {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final text = _reasonController.text.trim();

    if (_selectedDestinationDepartment == null ||
        _selectedDestinationDepartment!.trim().isEmpty) {
      setState(() => _reasonError = strings.selectDestinationDepartment);
      return false;
    }

    if (text.isEmpty || text.length < 5) {
      setState(() => _reasonError =
          'Please provide a reason for transferring this patient (minimum 5 characters).');
      return false;
    }

    if (text.length > 1000) {
      setState(() => _reasonError = strings.transferReasonTooLongError);
      return false;
    }

    setState(() => _reasonError = null);
    return true;
  }

  void _handleContinue() {
    if (_validateInput()) {
      setState(() => _currentStep = 1);
    }
  }

  void _handleConfirm() {
    if (_validateInput() && _selectedDestinationDepartment != null) {
      final dept = _selectedDestinationDepartment!;
      final reason = _reasonController.text.trim();
      Navigator.of(context).pop();
      widget.onConfirmTransfer?.call(dept, reason);
      widget.onTransferConfirmed?.call(dept, reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        side: const BorderSide(color: DoctorColors.dialogBorder, width: 1.0),
      ),
      backgroundColor: DoctorColors.dialogBg,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 580,
          maxHeight: 680,
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
                      Icons.swap_horiz_rounded,
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
                          _currentStep == 0
                              ? strings.transferPatientTitle.toUpperCase()
                              : 'REVIEW TRANSFER DETAILS',
                          style: DoctorTheme.cardTitle.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.clinicalCase != null
                              ? '${strings.caseStatusOpenBadge} • ${widget.clinicalCase!.caseId}'
                              : (widget.patientName ?? widget.patientId ?? 'PATIENT'),
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
                child: _currentStep == 0
                    ? _buildInputStep(strings)
                    : _buildReviewStep(strings),
              ),
            ),

            // Actions Bottom Bar
            Container(
              padding: const EdgeInsets.all(DoctorTheme.space16),
              decoration: const BoxDecoration(
                color: DoctorColors.dialogBg,
                border: Border(
                  top: BorderSide(color: DoctorColors.dialogBorder),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DoctorTheme.radius16),
                  bottomRight: Radius.circular(DoctorTheme.radius16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentStep == 0) ...[
                    DoctorOutlineButton(
                      label: strings.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: DoctorTheme.space12),
                    DoctorPrimaryButton(
                      label: strings.reviewTransferButton,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _handleContinue,
                    ),
                  ] else ...[
                    DoctorOutlineButton(
                      label: strings.back,
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => setState(() => _currentStep = 0),
                    ),
                    const SizedBox(width: DoctorTheme.space12),
                    DoctorPrimaryButton(
                      label: strings.confirmTransferButton,
                      icon: Icons.check_circle_rounded,
                      onPressed: _handleConfirm,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputStep(DoctorStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle explanation
        Text(
          strings.transferPatientSubtitle,
          style: DoctorTheme.body.copyWith(
            color: DoctorColors.dialogSecondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: DoctorTheme.space16),

        // Current Department (Read-Only)
        Container(
          padding: const EdgeInsets.all(DoctorTheme.space12),
          decoration: BoxDecoration(
            color: DoctorColors.pageTint,
            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            border: Border.all(color: DoctorColors.dialogBorder),
          ),
          child: Row(
            children: [
              Text(
                '${strings.currentDepartmentLabel}: ',
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.dialogSecondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.currentDepartment,
                style: DoctorTheme.bodyBold.copyWith(
                  color: DoctorColors.dialogPrimaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DoctorTheme.space16),

        // Destination Department Dropdown
        Text(
          strings.destinationDepartmentLabel.toUpperCase(),
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.dialogPrimaryText,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: DoctorColors.dialogBg,
            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            border: Border.all(
              color: _selectedDestinationDepartment != null
                  ? DoctorColors.dialogPrimaryTeal
                  : DoctorColors.dialogBorder,
              width: _selectedDestinationDepartment != null ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              dropdownColor: DoctorColors.dialogBg,
              menuMaxHeight: 320,
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              elevation: 4,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: DoctorColors.dialogPrimaryTeal,
                size: 22,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              isExpanded: true,
              initialValue: _selectedDestinationDepartment,
              hint: Text(
                strings.selectDestinationDepartment,
                style: DoctorTheme.body.copyWith(
                  color: DoctorColors.dialogSecondaryText,
                ),
              ),
              selectedItemBuilder: (context) {
                return _availableDepartments.map((dept) {
                  return Row(
                    children: [
                      Icon(
                        _getDepartmentIcon(dept),
                        size: 18,
                        color: DoctorColors.dialogPrimaryTeal,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dept,
                          style: DoctorTheme.bodyBold.copyWith(
                            color: DoctorColors.dialogPrimaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: _availableDepartments.map((dept) {
                final isSelected = dept == _selectedDestinationDepartment;
                return DropdownMenuItem<String>(
                  value: dept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? DoctorColors.pageTint : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getDepartmentIcon(dept),
                          size: 18,
                          color: isSelected
                              ? DoctorColors.dialogPrimaryTeal
                              : DoctorColors.dialogSecondaryText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dept,
                            style: TextStyle(
                              color: isSelected
                                  ? DoctorColors.dialogDarkTeal
                                  : DoctorColors.dialogPrimaryText,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: DoctorColors.dialogPrimaryTeal,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDestinationDepartment = val;
                  _reasonError = null;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: DoctorTheme.space16),

        // Transfer Reason Input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.transferReasonLabel.toUpperCase(),
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.dialogPrimaryText,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${_reasonController.text.length}/1000',
              style: DoctorTheme.caption.copyWith(
                color: _reasonController.text.length > 1000
                    ? DoctorColors.dialogWarningText
                    : DoctorColors.dialogSecondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _reasonController,
          maxLines: 4,
          maxLength: 1000,
          buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
          style: DoctorTheme.body.copyWith(
            color: DoctorColors.dialogPrimaryText,
          ),
          decoration: InputDecoration(
            hintText: strings.transferReasonHint,
            hintStyle: DoctorTheme.body.copyWith(
              color: DoctorColors.dialogSecondaryText.withValues(alpha: 0.7),
            ),
            fillColor: DoctorColors.dialogBg,
            filled: true,
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
            setState(() => _reasonError = null);
          },
        ),

        if (_reasonError != null) ...[
          const SizedBox(height: 4),
          Text(
            _reasonError!,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.dialogWarningText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: DoctorTheme.space16),

        // Informational Callout: Case and Visit history preserved
        Container(
          padding: const EdgeInsets.all(DoctorTheme.space12),
          decoration: BoxDecoration(
            color: DoctorColors.pageTint,
            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            border: Border.all(
              color: DoctorColors.dialogBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: DoctorColors.dialogPrimaryTeal,
              ),
              const SizedBox(width: DoctorTheme.space12),
              Expanded(
                child: Text(
                  strings.transferPreservesCaseNote,
                  style: DoctorTheme.bodyMuted.copyWith(
                    color: DoctorColors.dialogDarkTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(DoctorStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.reviewTransferSubtitle,
          style: DoctorTheme.body.copyWith(
            color: DoctorColors.dialogSecondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: DoctorTheme.space16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(DoctorTheme.space16),
          decoration: BoxDecoration(
            color: DoctorColors.pageTint,
            borderRadius: BorderRadius.circular(DoctorTheme.radius12),
            border: Border.all(color: DoctorColors.dialogBorder),
          ),
          child: Column(
            children: [
              _buildReviewRow(
                label: 'Patient',
                value: widget.patientName != null
                    ? '${widget.patientName} (${widget.patientId ?? ""})'
                    : (widget.patientId ?? 'Patient'),
              ),
              const Divider(height: 16, color: DoctorColors.dialogBorder),
              if (widget.clinicalCase != null) ...[
                _buildReviewRow(
                  label: 'Case',
                  value: widget.clinicalCase!.caseId,
                ),
                const Divider(height: 16, color: DoctorColors.dialogBorder),
              ],
              _buildReviewRow(
                label: strings.currentDepartmentLabel,
                value: widget.currentDepartment,
              ),
              const Divider(height: 16, color: DoctorColors.dialogBorder),
              _buildReviewRow(
                label: strings.destinationDepartmentLabel,
                value: _selectedDestinationDepartment ?? '',
                highlight: true,
              ),
              const Divider(height: 16, color: DoctorColors.dialogBorder),
              _buildReviewRow(
                label: strings.transferReasonLabel,
                value: _reasonController.text.trim(),
                isMultiline: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: DoctorTheme.space16),

        // Reassurance Notice
        Container(
          padding: const EdgeInsets.all(DoctorTheme.space12),
          decoration: BoxDecoration(
            color: DoctorColors.pageTint,
            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            border: Border.all(
              color: DoctorColors.dialogBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: DoctorColors.dialogPrimaryTeal,
              ),
              const SizedBox(width: DoctorTheme.space12),
              Expanded(
                child: Text(
                  strings.transferPreservesCaseNote,
                  style: DoctorTheme.bodyMuted.copyWith(
                    color: DoctorColors.dialogDarkTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow({
    required String label,
    required String value,
    bool highlight = false,
    bool isMultiline = false,
  }) {
    if (isMultiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.dialogSecondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DoctorTheme.body.copyWith(
              color: DoctorColors.dialogPrimaryText,
              height: 1.3,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.dialogSecondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: DoctorTheme.bodyBold.copyWith(
            color: highlight ? DoctorColors.dialogPrimaryTeal : DoctorColors.dialogPrimaryText,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
