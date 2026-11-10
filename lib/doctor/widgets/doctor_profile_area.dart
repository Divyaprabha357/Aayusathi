import 'package:flutter/material.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_ui_status.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_status_indicator.dart';

/// Doctor profile badge and menu component for the desktop header.
///
/// Displays:
/// - Physician medical avatar icon
/// - Doctor Name
/// - Qualification & Clinical Department
/// - Live availability status dot and text
/// - Menu with View Profile, Availability Switch, Settings, and Logout.
class DoctorProfileArea extends StatelessWidget {
  final String title;
  final String? qualification;
  final String department;
  final DoctorAvailabilityStatus availabilityStatus;
  final DoctorWorkStatus workStatus;
  final VoidCallback? onStatusTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onToggleAvailability;

  const DoctorProfileArea({
    super.key,
    this.title = 'Dr. Rajesh Sharma',
    this.qualification = 'MBBS, MD (Cardiology)',
    this.department = 'Cardiology',
    this.availabilityStatus = DoctorAvailabilityStatus.available,
    this.workStatus = DoctorWorkStatus.available,
    this.onStatusTap,
    this.onSettingsTap,
    this.onLogoutTap,
    this.onProfileTap,
    this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Workstation Profile & Status',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        side: const BorderSide(color: DoctorColors.border),
      ),
      color: DoctorColors.surface,
      elevation: 6,
      onSelected: (value) {
        switch (value) {
          case 'details':
          case 'profile':
            onProfileTap?.call();
            break;
          case 'logout':
            onLogoutTap?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'details',
          child: Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 18,
                color: DoctorColors.brandTeal,
              ),
              const SizedBox(width: DoctorTheme.space12),
              Text(
                'View Details',
                style: DoctorTheme.bodyRegular.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: DoctorColors.brandOrange,
              ),
              const SizedBox(width: DoctorTheme.space12),
              Text(
                'Logout',
                style: DoctorTheme.bodyRegular.copyWith(
                  color: DoctorColors.brandOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DoctorTheme.space12,
          vertical: DoctorTheme.space6,
        ),
        decoration: BoxDecoration(
          color: DoctorColors.surface,
          borderRadius: BorderRadius.circular(DoctorTheme.radiusFull),
          border: Border.all(color: DoctorColors.border),
          boxShadow: DoctorTheme.shadowSubtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Physician Medical Avatar
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: DoctorColors.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 18,
                color: DoctorColors.brandTeal,
              ),
            ),
            const SizedBox(width: DoctorTheme.space8),

            // Profile info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: DoctorTheme.bodyBold.copyWith(
                    fontSize: 12,
                    color: DoctorColors.brandNavy,
                  ),
                ),
                Text(
                  qualification != null ? '$qualification • $department' : department,
                  style: DoctorTheme.caption.copyWith(
                    fontSize: 10,
                    color: DoctorColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: DoctorTheme.space8),

            // Availability Status Dot & Label
            DoctorStatusDot(color: availabilityStatus.color, size: 8),
            const SizedBox(width: DoctorTheme.space4),
            Text(
              availabilityStatus.label,
              style: DoctorTheme.caption.copyWith(
                color: availabilityStatus.color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: DoctorTheme.space4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: DoctorColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
