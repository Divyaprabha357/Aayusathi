/// Centralized configuration for patient follow-up notifications.
///
/// Designed to be easily configurable and extensible.
class PatientNotificationConfig {
  const PatientNotificationConfig._();

  /// Default notification advance notice policy: 24 hours before visit.
  static const Duration defaultReminderBefore = Duration(hours: 24);

  /// Native Android notification channel ID.
  static const String channelId = 'aayusathi_followups';

  /// Native Android notification channel name.
  static const String channelName = 'AAYUSATHI Follow-ups';

  /// Native Android notification channel description.
  static const String channelDescription = 'Follow-up visit reminders';

  /// Notification title for clinical follow-up reminders.
  static const String followUpTitle = 'AAYUSATHI Follow-up Reminder';

  /// Fallback notification body text.
  static const String defaultFollowUpBody = 'Your follow-up visit is scheduled for tomorrow.';

  /// Formats privacy-safe body text using optional department.
  static String formatFollowUpBody({String? department}) {
    if (department != null && department.trim().isNotEmpty) {
      final dept = department.trim();
      return 'Your $dept follow-up is scheduled for tomorrow.';
    }
    return defaultFollowUpBody;
  }
}
