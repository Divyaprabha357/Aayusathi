import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/opd_domain.dart';
import '../models/admin_domain_availability.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';

/// Read-only inspection modal displaying verified physician credentials,
/// department assignment, presence status, and registration metadata.
///
/// Mandates:
/// - Masked mobile number display (e.g., '******3210')
/// - Zero password/auth token exposure
/// - Immutable historical record confirmation
class AdminDoctorDetailsDialog extends StatelessWidget {
  final DoctorProfile doctor;
  final VoidCallback? onEdit;

  const AdminDoctorDetailsDialog({
    super.key,
    required this.doctor,
    this.onEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required DoctorProfile doctor,
    VoidCallback? onEdit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AdminDoctorDetailsDialog(
        doctor: doctor,
        onEdit: onEdit,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard.'),
        backgroundColor: AdminColors.brandNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final domainName = AdminDomainAvailability.standardDomains.firstWhere(
      (d) => d['id'] == doctor.department,
      orElse: () => {'name': doctor.department.toUpperCase()},
    )['name']!;

    final opdDomain = OpdDomain.findById(doctor.department);

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        side: const BorderSide(color: AdminColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.brandNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: AdminColors.brandNavy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHYSICIAN PROFILE RECORD',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verified clinician credentials and hospital registration data.',
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AdminColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AdminTheme.space20),

              // Status Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16, vertical: AdminTheme.space12),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AdminTheme.radius10),
                  border: Border.all(color: AdminColors.borderSubtle),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AdminTheme.radius6),
                            border: Border.all(
                              color: (doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                doctor.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 14,
                                color: doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                doctor.isActive ? 'ACTIVE ACCOUNT' : 'DEACTIVATED',
                                style: AdminTheme.badgeText.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: doctor.availabilityStatus.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AdminTheme.radius6),
                            border: Border.all(
                              color: doctor.availabilityStatus.color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                doctor.availabilityStatus.icon,
                                size: 14,
                                color: doctor.availabilityStatus.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                doctor.availabilityStatus.label.toUpperCase(),
                                style: AdminTheme.badgeText.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: doctor.availabilityStatus.color,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      doctor.doctorUniqueCode,
                      style: AdminTheme.headline2.copyWith(
                        color: AdminColors.brandTeal,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.space16),


              // Detail Grid
              Container(
                padding: const EdgeInsets.all(AdminTheme.space16),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(AdminTheme.radius10),
                  border: Border.all(color: AdminColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      label: 'Doctor Unique ID',
                      valueWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            doctor.doctorUniqueCode,
                            style: AdminTheme.bodyRegular.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AdminColors.brandNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _copyToClipboard(context, doctor.doctorUniqueCode, 'Doctor ID'),
                            child: const Icon(Icons.copy_rounded, size: 16, color: AdminColors.brandTeal),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16, color: AdminColors.borderSubtle),
                    _buildRow(
                      label: 'Full Name',
                      value: doctor.name,
                      isBold: true,
                    ),
                    const Divider(height: 16, color: AdminColors.borderSubtle),
                    _buildRow(
                      label: 'Specialty Department',
                      valueWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opdDomain?.icon ?? Icons.medical_services_outlined,
                            size: 16,
                            color: AdminColors.brandNavy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            domainName,
                            style: AdminTheme.bodyRegular.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16, color: AdminColors.borderSubtle),
                    _buildRow(
                      label: 'Qualification / Degree',
                      value: doctor.qualification,
                    ),
                    const Divider(height: 16, color: AdminColors.borderSubtle),
                    _buildRow(
                      label: 'Registered Phone',
                      valueWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 14, color: AdminColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            doctor.maskedPhone,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16, color: AdminColors.borderSubtle),
                    _buildRow(
                      label: 'Official Email',
                      value: doctor.email.isNotEmpty ? doctor.email : '—',
                    ),
                    const Divider(height: 16, color: AdminColors.borderSubtle),
                    _buildRow(
                      label: 'Account Provisioned On',
                      value: _formatDate(doctor.createdAt),
                    ),
                    const Divider(height: 16, color: AdminColors.borderSubtle),
                    _buildRow(
                      label: 'Last Profile Update',
                      value: _formatDate(doctor.updatedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.space16),

              // Governance Assurance Box
              Container(
                padding: const EdgeInsets.all(AdminTheme.space12),
                decoration: BoxDecoration(
                  color: AdminColors.brandNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  border: Border.all(color: AdminColors.brandNavy.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AdminColors.brandNavy,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Historical consultation, diagnostic, and prescription records remain permanently associated with this physician identity.',
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.brandNavy,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.space20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: 'CLOSE',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: AdminTheme.space12),
                    AdminPrimaryButton(
                      label: 'EDIT PROFILE',
                      icon: Icons.edit_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit!();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    String? value,
    Widget? valueWidget,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (valueWidget != null)
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget,
            ),
          )
        else
          Flexible(
            flex: 3,
            child: Text(
              value ?? '—',
              style: AdminTheme.bodyRegular.copyWith(
                color: AdminColors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }
}

