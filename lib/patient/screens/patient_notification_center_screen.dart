import 'package:flutter/material.dart';
import '../localization/patient_localizations.dart';
import '../localization/patient_strings.dart';
import '../models/patient_app_state.dart';
import '../models/patient_notification_item.dart';
import '../services/patient_notification_service.dart';
import '../theme/patient_colors.dart';
import '../widgets/patient_empty_state.dart';
import '../widgets/patient_top_bar.dart';

/// Notification Center screen for the authenticated patient (`/patient/notifications`).
///
/// Strictly adheres to privacy guarantees (zero diagnoses, Aadhaar, or sensitive notes).
class PatientNotificationCenterScreen extends StatefulWidget {
  final PatientNotificationService? service;

  const PatientNotificationCenterScreen({
    super.key,
    this.service,
  });

  @override
  State<PatientNotificationCenterScreen> createState() =>
      _PatientNotificationCenterScreenState();
}

class _PatientNotificationCenterScreenState
    extends State<PatientNotificationCenterScreen> {
  late final PatientNotificationService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PatientNotificationService.instance;
  }

  String get _patientId =>
      PatientAppState.instance.authenticatedPatientId ?? 'CURRENT_PATIENT';

  void _handleNotificationTap(PatientNotificationItem item) {
    _service.markAsRead(item.id);

    // If follow-up reminder, deep link to Calendar focusing that date
    if (item.type == PatientNotificationType.followUpReminder) {
      PatientAppState.instance.navigateToCalendarWithDate(item.visitDate);
      Navigator.of(context).pop(); // Return to previous shell screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Scaffold(
      backgroundColor: PatientColors.background,
      appBar: PatientTopBar(
        title: strings.notifications,
        showBackButton: true,
        showNotificationButton: false, // Don't show recursive bell
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final notifications = _service.getNotifications(_patientId);
          final hasUnread = notifications.any((n) => !n.isRead);

          if (notifications.isEmpty) {
            return Center(
              child: PatientEmptyState(
                icon: Icons.notifications_none_rounded,
                title: strings.noNotifications,
                message: strings.youreAllCaughtUp,
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  if (hasUnread)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _service.markAllAsRead(_patientId),
                            icon: const Icon(Icons.done_all_rounded,
                                size: 18, color: PatientColors.teal),
                            label: Text(
                              strings.markAllAsRead,
                              style: const TextStyle(
                                color: PatientColors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return _buildNotificationCard(context, item, strings);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    PatientNotificationItem item,
    PatientStrings strings,
  ) {
    final isUnread = !item.isRead;

    return Semantics(
      label: '${item.title}. ${item.body}. ${isUnread ? "Unread" : "Read"}',
      button: true,
      child: Material(
        color: isUnread ? PatientColors.surface : const Color(0xFFF4F8F6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleNotificationTap(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread ? PatientColors.teal : PatientColors.border,
                width: isUnread ? 1.5 : 1.0,
              ),
              boxShadow: isUnread
                  ? const [
                      BoxShadow(
                        color: PatientColors.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visual Indicator: Teal Bell for unread with dot, Muted for read
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? PatientColors.tealLight
                        : PatientColors.borderSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnread
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_outlined,
                    color: isUnread
                        ? PatientColors.teal
                        : PatientColors.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: PatientColors.navy,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PatientColors.teal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnread
                              ? PatientColors.navy
                              : PatientColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event_outlined,
                              size: 14, color: PatientColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.visitDate),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PatientColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            strings.viewDetails,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PatientColors.teal,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: PatientColors.teal),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
