/// Date and time formatting utilities for AAYUSATHI.
class AppDateUtils {
  AppDateUtils._();

  /// Formats DateTime as YYYY-MM-DD
  static String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Formats DateTime as HH:MM AM/PM
  static String formatTime(DateTime date) {
    final hour24 = date.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Formats DateTime as a user-friendly timestamp: YYYY-MM-DD HH:MM
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }
}
