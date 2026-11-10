import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/patient_calendar_item.dart';
import '../models/patient_notification_config.dart';
import '../models/patient_notification_item.dart';

/// Contract for Patient Notification & Follow-up Reminder management.
///
/// Designed to be robust, secure, and privacy-safe.
abstract class PatientNotificationService extends ChangeNotifier {
  /// Global singleton instance.
  static PatientNotificationService instance = DefaultPatientNotificationService();

  /// Safe initialization of notification system post-authentication.
  Future<void> initialize();

  /// Requests notification permission on platforms where runtime permission is required.
  Future<bool> requestNotificationPermission();

  /// Checks whether reminders are supported and enabled on the platform.
  Future<bool> areRemindersEnabled();

  /// Opens the device/system notification settings for the application.
  Future<void> openNotificationSettings();

  /// Schedules a reminder for an upcoming clinical follow-up visit.
  Future<void> scheduleFollowUpReminder({
    required String eventId,
    required DateTime visitDate,
    required String title,
    required String department,
    String? patientId,
  });

  /// Cancels an existing scheduled reminder by event ID.
  Future<void> cancelReminder(String eventId);

  /// Synchronizes scheduled follow-up reminders with current clinical visits and appointments.
  ///
  /// Guarantees:
  /// 1. Only upcoming visits (future) are scheduled.
  /// 2. Deterministic IDs prevent duplicate notifications across repeated visits.
  /// 3. Rescheduled visits cancel old reminders and schedule new ones.
  /// 4. Removed or cancelled visits are cancelled.
  Future<void> syncFollowUpReminders({
    required String patientId,
    required List<PatientCalendarItem> followUps,
  });

  /// Returns list of notifications for the specified patient (newest first).
  List<PatientNotificationItem> getNotifications(String patientId);

  /// Returns unread notification count for the specified patient.
  int getUnreadCount(String patientId);

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId);

  /// Marks all notifications for a patient as read.
  Future<void> markAllAsRead(String patientId);

  /// Cleans up state and scheduling when patient logs out.
  Future<void> clearPatientSession(String patientId);
}

/// Default implementation communicating with native Android through MethodChannel
/// and maintaining privacy-safe in-memory inbox partitioned by patient ID.
class DefaultPatientNotificationService extends ChangeNotifier
    implements PatientNotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.example.aayusathi/patient_notifications');

  // In-memory store of notifications strictly partitioned by patientId
  final Map<String, List<PatientNotificationItem>> _patientNotifications = {};

  // Track active scheduled deterministic reminder IDs per patient
  final Map<String, Map<String, PatientNotificationItem>> _activeReminders = {};

  bool _initialized = false;
  bool _mockPermissionGranted = false;

  DefaultPatientNotificationService();

  bool get isAndroidPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (isAndroidPlatform) {
      try {
        await _channel.invokeMethod('createNotificationChannel', {
          'channelId': PatientNotificationConfig.channelId,
          'channelName': PatientNotificationConfig.channelName,
          'channelDescription': PatientNotificationConfig.channelDescription,
        });
      } catch (e) {
        debugPrint('[PatientNotificationService] Native channel creation error: $e');
      }
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (isAndroidPlatform) {
      try {
        final result = await _channel.invokeMethod<bool>('requestPermission');
        final granted = result ?? false;
        notifyListeners();
        return granted;
      } catch (e) {
        debugPrint('[PatientNotificationService] Error requesting permission: $e');
        return false;
      }
    }
    // On non-Android (desktop, testing), toggle simulated permission
    _mockPermissionGranted = true;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> areRemindersEnabled() async {
    if (isAndroidPlatform) {
      try {
        final enabled = await _channel.invokeMethod<bool>('areNotificationsEnabled');
        return enabled ?? false;
      } catch (e) {
        debugPrint('[PatientNotificationService] areNotificationsEnabled error: $e');
        return false;
      }
    }
    return _mockPermissionGranted;
  }

  @override
  Future<void> openNotificationSettings() async {
    if (isAndroidPlatform) {
      try {
        await _channel.invokeMethod('openNotificationSettings');
      } catch (e) {
        debugPrint('[PatientNotificationService] openNotificationSettings error: $e');
      }
    }
  }

  @override
  Future<void> scheduleFollowUpReminder({
    required String eventId,
    required DateTime visitDate,
    required String title,
    required String department,
    String? patientId,
  }) async {
    final pid = patientId ?? 'CURRENT_PATIENT';
    final now = DateTime.now();

    // Guard: Past visit
    if (visitDate.isBefore(now)) {
      debugPrint('[PatientNotificationService] Skipping past visit reminder for $eventId');
      return;
    }

    final scheduledDate = visitDate.subtract(PatientNotificationConfig.defaultReminderBefore);
    final deterministicId = PatientNotificationItem.generateDeterministicId(
      patientId: pid,
      eventId: eventId,
      reminderDate: visitDate,
    );

    // Guard: Duplicate prevention
    final patientReminders = _activeReminders.putIfAbsent(pid, () => {});
    if (patientReminders.containsKey(deterministicId)) {
      debugPrint('[PatientNotificationService] Reminder $deterministicId already scheduled');
      return;
    }

    final body = PatientNotificationConfig.formatFollowUpBody(department: department);

    final item = PatientNotificationItem(
      id: deterministicId,
      patientId: pid,
      eventId: eventId,
      title: title.isNotEmpty ? title : PatientNotificationConfig.followUpTitle,
      body: body,
      scheduledDate: scheduledDate,
      visitDate: visitDate,
      createdAt: now,
      department: department.isNotEmpty ? department : null,
      type: PatientNotificationType.followUpReminder,
    );

    patientReminders[deterministicId] = item;

    // Add to patient's notification inbox
    final list = _patientNotifications.putIfAbsent(pid, () => []);
    final existingIdx = list.indexWhere((n) => n.id == deterministicId);
    if (existingIdx >= 0) {
      list[existingIdx] = item;
    } else {
      list.insert(0, item);
    }

    // Schedule on Android if on device
    if (isAndroidPlatform) {
      try {
        await _channel.invokeMethod('scheduleNotification', {
          'id': item.numericNotificationId,
          'title': item.title,
          'body': item.body,
          'triggerTimestamp': scheduledDate.millisecondsSinceEpoch,
          'payload': visitDate.toIso8601String(),
        });
      } catch (e) {
        debugPrint('[PatientNotificationService] Failed to schedule Android notification: $e');
      }
    }

    notifyListeners();
  }

  @override
  Future<void> cancelReminder(String eventId) async {
    for (final pid in _activeReminders.keys) {
      final reminders = _activeReminders[pid]!;
      final matchingKeys = reminders.keys
          .where((k) => reminders[k]?.eventId == eventId)
          .toList();

      for (final key in matchingKeys) {
        final item = reminders.remove(key);
        if (item != null && isAndroidPlatform) {
          try {
            await _channel.invokeMethod('cancelNotification', {
              'id': item.numericNotificationId,
            });
          } catch (e) {
            debugPrint('[PatientNotificationService] Failed to cancel Android notification: $e');
          }
        }
      }
    }
    for (final pid in _patientNotifications.keys) {
      _patientNotifications[pid]?.removeWhere((n) => n.eventId == eventId);
    }
    notifyListeners();
  }

  @override
  Future<void> syncFollowUpReminders({
    required String patientId,
    required List<PatientCalendarItem> followUps,
  }) async {
    final now = DateTime.now();
    final patientReminders = _activeReminders.putIfAbsent(patientId, () => {});

    // 1. Identify all valid upcoming follow-ups
    final upcomingFollowUps = followUps.where((item) {
      return item.date.isAfter(now) ||
          (item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day);
    }).toList();

    final validDeterministicIds = <String>{};

    for (final item in upcomingFollowUps) {
      final deterministicId = PatientNotificationItem.generateDeterministicId(
        patientId: patientId,
        eventId: item.id,
        reminderDate: item.date,
      );
      validDeterministicIds.add(deterministicId);

      // Check if already scheduled with the exact same date
      final existing = patientReminders[deterministicId];
      if (existing != null) {
        // Already active with same date -> skip duplicate
        continue;
      }

      // Check if event had a previously scheduled reminder on a different date (rescheduled)
      final oldKey = patientReminders.keys.firstWhere(
        (k) => patientReminders[k]?.eventId == item.id,
        orElse: () => '',
      );

      if (oldKey.isNotEmpty) {
        // Cancel old reminder
        final oldItem = patientReminders.remove(oldKey);
        _patientNotifications[patientId]?.removeWhere((n) => n.id == oldKey);
        if (oldItem != null && isAndroidPlatform) {
          try {
            await _channel.invokeMethod('cancelNotification', {
              'id': oldItem.numericNotificationId,
            });
          } catch (_) {}
        }
      }

      // Schedule new reminder
      await scheduleFollowUpReminder(
        eventId: item.id,
        visitDate: item.date,
        title: PatientNotificationConfig.followUpTitle,
        department: item.department ?? item.doctorName ?? '',
        patientId: patientId,
      );
    }

    // 2. Cancel any reminders that no longer exist in upcoming follow-ups
    final keysToRemove = patientReminders.keys
        .where((k) => !validDeterministicIds.contains(k))
        .toList();

    for (final key in keysToRemove) {
      final item = patientReminders.remove(key);
      _patientNotifications[patientId]?.removeWhere((n) => n.id == key);
      if (item != null && isAndroidPlatform) {
        try {
          await _channel.invokeMethod('cancelNotification', {
            'id': item.numericNotificationId,
          });
        } catch (_) {}
      }
    }

    notifyListeners();
  }

  @override
  List<PatientNotificationItem> getNotifications(String patientId) {
    return List.unmodifiable(_patientNotifications[patientId] ?? []);
  }

  @override
  int getUnreadCount(String patientId) {
    final list = _patientNotifications[patientId];
    if (list == null || list.isEmpty) return 0;
    return list.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    for (final list in _patientNotifications.values) {
      final idx = list.indexWhere((n) => n.id == notificationId);
      if (idx >= 0) {
        list[idx] = list[idx].copyWith(isRead: true);
        notifyListeners();
        return;
      }
    }
  }

  @override
  Future<void> markAllAsRead(String patientId) async {
    final list = _patientNotifications[patientId];
    if (list == null || list.isEmpty) return;

    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  @override
  Future<void> clearPatientSession(String patientId) async {
    // Clear in-memory inbox and cancel pending alarms for this patient
    final reminders = _activeReminders.remove(patientId);
    if (reminders != null && isAndroidPlatform) {
      for (final item in reminders.values) {
        try {
          await _channel.invokeMethod('cancelNotification', {
            'id': item.numericNotificationId,
          });
        } catch (_) {}
      }
    }
    _patientNotifications.remove(patientId);
    notifyListeners();
  }

  /// Helper for tests to inject custom notification items directly.
  @visibleForTesting
  void injectNotificationForTesting(String patientId, PatientNotificationItem item) {
    final list = _patientNotifications.putIfAbsent(patientId, () => []);
    list.insert(0, item);
    notifyListeners();
  }

  /// Helper for tests to reset in-memory state.
  @visibleForTesting
  void resetForTesting() {
    _patientNotifications.clear();
    _activeReminders.clear();
    _initialized = false;
    _mockPermissionGranted = false;
    notifyListeners();
  }
}

/// No-op stub implementation maintained for test isolation and fallback.
class PatientNotificationServiceStub extends ChangeNotifier
    implements PatientNotificationService {
  PatientNotificationServiceStub();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<bool> areRemindersEnabled() async => false;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> scheduleFollowUpReminder({
    required String eventId,
    required DateTime visitDate,
    required String title,
    required String department,
    String? patientId,
  }) async {}

  @override
  Future<void> cancelReminder(String eventId) async {}

  @override
  Future<void> syncFollowUpReminders({
    required String patientId,
    required List<PatientCalendarItem> followUps,
  }) async {}

  @override
  List<PatientNotificationItem> getNotifications(String patientId) => const [];

  @override
  int getUnreadCount(String patientId) => 0;

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String patientId) async {}

  @override
  Future<void> clearPatientSession(String patientId) async {}
}
