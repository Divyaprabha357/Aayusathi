import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/investigation_request.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog for doctors to request diagnostic and laboratory investigations.
class DoctorRequestInvestigationDialog extends StatefulWidget {
  final Function(String name, InvestigationCategory category,
      InvestigationPriority priority) onConfirm;
  final KioskLocale locale;

  const DoctorRequestInvestigationDialog({
    super.key,
    required this.onConfirm,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorRequestInvestigationDialog> createState() =>
      _DoctorRequestInvestigationDialogState();
}

class _DoctorRequestInvestigationDialogState
    extends State<DoctorRequestInvestigationDialog> {
  late final TextEditingController _nameController;
  InvestigationCategory _category = InvestigationCategory.diagnostic;
  InvestigationPriority _priority = InvestigationPriority.required;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an investigation name.';
      });
      return;
    }

    widget.onConfirm(name, _category, _priority);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DoctorColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            child: const Icon(Icons.biotech_rounded,
                color: DoctorColors.brandTeal, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            strings.requestInvestigationDialogTitle,
            style: DoctorTheme.headline2.copyWith(
              color: DoctorColors.brandNavy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Investigation Name
              Text(
                strings.investigationNameLabel,
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: DoctorTheme.bodyRegular,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: strings.investigationNameHint,
                  hintStyle: DoctorTheme.bodyMuted,
                  filled: true,
                  fillColor: DoctorColors.background,
                  errorText: _errorMessage,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    borderSide: const BorderSide(color: DoctorColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    borderSide: const BorderSide(color: DoctorColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    borderSide: const BorderSide(
                        color: DoctorColors.brandTeal, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: DoctorTheme.space16),

              // 2. Category Dropdown
              Text(
                strings.investigationCategoryLabel,
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DoctorColors.background,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(color: DoctorColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InvestigationCategory>(
                    value: _category,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: DoctorColors.brandNavy),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                    items: InvestigationCategory.values.map((cat) {
                      return DropdownMenuItem<InvestigationCategory>(
                        value: cat,
                        child: Text(
                          cat.label,
                          style: DoctorTheme.bodyRegular.copyWith(
                            color: DoctorColors.brandNavy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: DoctorTheme.space16),

              // 3. Priority Selector
              Text(
                strings.priorityLabel,
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(strings.requiredPriority),
                      selected: _priority == InvestigationPriority.required,
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                              () => _priority = InvestigationPriority.required);
                        }
                      },
                      selectedColor:
                          DoctorColors.brandTeal.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _priority == InvestigationPriority.required
                            ? DoctorColors.brandTeal
                            : DoctorColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(strings.asAdvisedPriority),
                      selected: _priority == InvestigationPriority.asAdvised,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() =>
                              _priority = InvestigationPriority.asAdvised);
                        }
                      },
                      selectedColor:
                          DoctorColors.brandNavy.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _priority == InvestigationPriority.asAdvised
                            ? DoctorColors.brandNavy
                            : DoctorColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        DoctorOutlineButton(
          label: strings.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        DoctorPrimaryButton(
          label: strings.requestInvestigationButton,
          icon: Icons.send_rounded,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }
}
