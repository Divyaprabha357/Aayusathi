/// Classification of patient notifications.
enum PatientNotificationType {
  followUpReminder,
  general,
}

/// Represents an in-app or system notification for the authenticated patient.
///
/// Strictly privacy-safe: NEVER includes Aadhaar, phone numbers, Firebase UIDs,
/// clinical diagnoses, medications, or doctor notes.
class PatientNotificationItem {
  final String id;
  final String patientId;
  final String eventId;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final DateTime visitDate;
  final bool isRead;
  final DateTime createdAt;
  final String? department;
  final PatientNotificationType type;

  const PatientNotificationItem({
    required this.id,
    required this.patientId,
    required this.eventId,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.visitDate,
    this.isRead = false,
    required this.createdAt,
    this.department,
    this.type = PatientNotificationType.followUpReminder,
  });

  /// Deterministic ID generator derived from patient, event, and reminder date.
  ///
  /// Guarantees that opening screens repeatedly will NOT duplicate reminders.
  static String generateDeterministicId({
    required String patientId,
    required String eventId,
    required DateTime reminderDate,
  }) {
    final y = reminderDate.year.toString().padLeft(4, '0');
    final m = reminderDate.month.toString().padLeft(2, '0');
    final d = reminderDate.day.toString().padLeft(2, '0');
    return 'REM_${patientId}_${eventId}_$y-$m-$d';
  }

  /// Deterministic 31-bit positive integer hash for Android notification IDs and alarms.
  int get numericNotificationId => id.hashCode & 0x7FFFFFFF;

  PatientNotificationItem copyWith({
    String? id,
    String? patientId,
    String? eventId,
    String? title,
    String? body,
    DateTime? scheduledDate,
    DateTime? visitDate,
    bool? isRead,
    DateTime? createdAt,
    String? department,
    PatientNotificationType? type,
  }) {
    return PatientNotificationItem(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      visitDate: visitDate ?? this.visitDate,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      department: department ?? this.department,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'eventId': eventId,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate.toIso8601String(),
      'visitDate': visitDate.toIso8601String(),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'department': department,
      'type': type.name,
    };
  }

  factory PatientNotificationItem.fromJson(Map<String, dynamic> json) {
    return PatientNotificationItem(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      visitDate: DateTime.parse(json['visitDate'] as String),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      department: json['department'] as String?,
      type: PatientNotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PatientNotificationType.followUpReminder,
      ),
    );
  }
}
