import 'package:flutter/material.dart';
import '../localization/patient_localizations.dart';
import '../services/patient_notification_service.dart';
import '../theme/patient_colors.dart';

/// Educational banner explaining notification benefits before triggering the system permission request.
class PatientNotificationPermissionBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback? onPermissionGranted;

  const PatientNotificationPermissionBanner({
    super.key,
    required this.onDismiss,
    this.onPermissionGranted,
  });

  Future<void> _handleAllow(BuildContext context) async {
    final granted =
        await PatientNotificationService.instance.requestNotificationPermission();
    if (context.mounted) {
      onDismiss();
      if (granted && onPermissionGranted != null) {
        onPermissionGranted!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: PatientColors.tealLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: PatientColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: PatientColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.followUpReminder,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.navy,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: PatientColors.textMuted),
                onPressed: onDismiss,
                tooltip: strings.notNow,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.notificationRationale,
            style: const TextStyle(
              fontSize: 13,
              color: PatientColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    strings.notNow,
                    style: const TextStyle(
                      color: PatientColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleAllow(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PatientColors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    strings.allowNotifications,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
