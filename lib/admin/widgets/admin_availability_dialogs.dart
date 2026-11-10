import 'package:flutter/material.dart';
import '../../doctor/models/doctor_profile.dart';
import '../controllers/admin_availability_controller.dart';
import '../models/admin_domain_availability.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';

// ===========================================================================
// 1. SET DOCTOR AVAILABLE DIALOG
// ===========================================================================
class AdminSetAvailableDialog extends StatefulWidget {
  final DoctorProfile doctor;
  final AdminAvailabilityController controller;

  const AdminSetAvailableDialog({
    super.key,
    required this.doctor,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DoctorProfile doctor,
    required AdminAvailabilityController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AdminSetAvailableDialog(
        doctor: doctor,
        controller: controller,
      ),
    );
  }

  @override
  State<AdminSetAvailableDialog> createState() => _AdminSetAvailableDialogState();
}

class _AdminSetAvailableDialogState extends State<AdminSetAvailableDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = await widget.controller.setDoctorAvailability(
      doctor: widget.doctor,
      targetStatus: DoctorAvailabilityStatus.available,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = widget.controller.actionError ?? 'Failed to set doctor available.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainName = AdminDomainAvailability.standardDomains.firstWhere(
      (d) => d['id'] == widget.doctor.department,
      orElse: () => {'name': widget.doctor.department.toUpperCase()},
    )['name']!;

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        side: const BorderSide(color: AdminColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.statusAvailable.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AdminColors.statusAvailable,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SET DOCTOR AS AVAILABLE',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.doctor.name} (${widget.doctor.doctorUniqueCode})',
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminTheme.space20),

              // Description
              Text(
                'Make this physician operationally available for appointment intake?',
                style: AdminTheme.bodyRegular.copyWith(
                  color: AdminColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AdminTheme.space12),

              Container(
                padding: const EdgeInsets.all(AdminTheme.space12),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  border: Border.all(color: AdminColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Department', domainName),
                    const SizedBox(height: 6),
                    _buildInfoRow('Current State', 'OFFLINE'),
                    const SizedBox(height: 6),
                    _buildInfoRow('Target State', 'AVAILABLE (Eligible for Queue Routing)'),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.space12),

              Text(
                'This will make the Doctor eligible for new appointment requests from the Kiosk queue.',
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AdminTheme.space20),

              // Error display
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: AdminTheme.caption.copyWith(
                    color: AdminColors.statusCritical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AdminTheme.space12),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: 'CANCEL',
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AdminTheme.space12),
                  AdminPrimaryButton(
                    label: 'SET AVAILABLE',
                    icon: Icons.check_circle_rounded,
                    isLoading: _isProcessing,
                    onPressed: _isProcessing ? null : _handleConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AdminTheme.caption.copyWith(
            color: AdminColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AdminTheme.space8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AdminTheme.bodyRegular.copyWith(
              color: AdminColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 2. SET DOCTOR OFFLINE DIALOG
// ===========================================================================
class AdminSetOfflineDialog extends StatefulWidget {
  final DoctorProfile doctor;
  final AdminAvailabilityController controller;

  const AdminSetOfflineDialog({
    super.key,
    required this.doctor,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DoctorProfile doctor,
    required AdminAvailabilityController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AdminSetOfflineDialog(
        doctor: doctor,
        controller: controller,
      ),
    );
  }

  @override
  State<AdminSetOfflineDialog> createState() => _AdminSetOfflineDialogState();
}

class _AdminSetOfflineDialogState extends State<AdminSetOfflineDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = await widget.controller.setDoctorAvailability(
      doctor: widget.doctor,
      targetStatus: DoctorAvailabilityStatus.offline,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = widget.controller.actionError ?? 'Failed to set doctor offline.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        side: const BorderSide(color: AdminColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.brandNavy.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.power_settings_new_rounded,
                      color: AdminColors.brandNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SET DOCTOR OFFLINE',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.doctor.name} (${widget.doctor.doctorUniqueCode})',
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminTheme.space20),

              Text(
                'Set ${widget.doctor.name} as OFFLINE?',
                style: AdminTheme.bodyRegular.copyWith(
                  color: AdminColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AdminTheme.space10),

              Container(
                padding: const EdgeInsets.all(AdminTheme.space12),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  border: Border.all(color: AdminColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• The Doctor will no longer receive new appointment requests.',
                      style: AdminTheme.caption.copyWith(
                        color: AdminColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Doctor authenticated session remains valid; only operational availability changes.',
                      style: AdminTheme.caption.copyWith(
                        color: AdminColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.space20),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: AdminTheme.caption.copyWith(
                    color: AdminColors.statusCritical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AdminTheme.space12),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: 'CANCEL',
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AdminTheme.space12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.brandNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AdminTheme.radius8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isProcessing ? null : _handleConfirm,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SET OFFLINE',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

// ===========================================================================
// 3. CONSULTATION LOCKED / SAFEGUARD EXPLANATION DIALOG
// ===========================================================================
class AdminConsultationLockedDialog extends StatelessWidget {
  final DoctorProfile doctor;

  const AdminConsultationLockedDialog({
    super.key,
    required this.doctor,
  });

  static Future<void> show(
    BuildContext context, {
    required DoctorProfile doctor,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AdminConsultationLockedDialog(
        doctor: doctor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        side: const BorderSide(color: AdminColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.brandOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: AdminColors.brandOrange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCTOR IN CONSULTATION',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doctor.name} (${doctor.doctorUniqueCode})',
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminTheme.space20),

              Container(
                padding: const EdgeInsets.all(AdminTheme.space14),
                decoration: BoxDecoration(
                  color: AdminColors.brandOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AdminTheme.radius10),
                  border: Border.all(color: AdminColors.brandOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_clock_rounded,
                      color: AdminColors.brandOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Availability cannot be manually changed while the Doctor is consulting a patient.',
                        style: AdminTheme.bodyRegular.copyWith(
                          color: AdminColors.brandNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.space16),

              Text(
                'Clinical consultations are strictly physician-managed. Once the consultation is concluded or transferred by the Doctor, the workstation will automatically return to AVAILABLE state.',
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AdminTheme.space24),

              Align(
                alignment: Alignment.centerRight,
                child: AdminSecondaryButton(
                  label: 'CLOSE',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
