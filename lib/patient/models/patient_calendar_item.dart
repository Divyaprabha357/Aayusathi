import 'package:flutter/material.dart';

enum PatientCalendarEventType {
  visit,
  followUp,
  investigation;

  String get displayName {
    switch (this) {
      case PatientCalendarEventType.visit:
        return 'OPD Consultation';
      case PatientCalendarEventType.followUp:
        return 'Follow-up Visit';
      case PatientCalendarEventType.investigation:
        return 'Diagnostic Test';
    }
  }

  Color get color {
    switch (this) {
      case PatientCalendarEventType.visit:
        return const Color(0xFF00897B); // Medical Teal
      case PatientCalendarEventType.followUp:
        return const Color(0xFFE65100); // Care Orange
      case PatientCalendarEventType.investigation:
        return const Color(0xFF0288D1); // Info Blue
    }
  }
}

/// Represents an appointment, consultation, or follow-up item on the Patient Calendar.
class PatientCalendarItem {
  final String id;
  final DateTime date;
  final String title;
  final String? department;
  final String? doctorName;
  final String? location;
  final PatientCalendarEventType type;

  // Clinical context links
  final String? caseId;
  final String? visitId;
  final int? visitNumber;
  final String? caseTitle;
  final String? rawFollowUpText;

  const PatientCalendarItem({
    required this.id,
    required this.date,
    required this.title,
    this.department,
    this.doctorName,
    this.location,
    this.type = PatientCalendarEventType.visit,
    this.caseId,
    this.visitId,
    this.visitNumber,
    this.caseTitle,
    this.rawFollowUpText,
  });

  /// Whether this calendar event represents a past date relative to today 00:00.
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    return itemDate.isBefore(today);
  }

  /// Whether this calendar event represents an upcoming / today date.
  bool get isUpcoming => !isPast;

  /// Whether this item occurs on the same calendar day as [other].
  bool isSameDay(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }
}
