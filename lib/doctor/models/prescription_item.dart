/// Model representing a single prescribed medicine in a clinical visit.
///
/// Hierarchy:
/// PATIENT -> CLINICAL CASE -> CLINICAL VISIT -> PRESCRIPTIONS
///
/// Rules:
/// - Strictly NO Aadhaar numbers or raw sensitive credentials stored.
/// - Every prescription row requires medicineName, duration, timesPerDay, remarks.
/// - 100% manually editable by attending doctor.
class PrescriptionItem {
  final String medicineName;
  final String duration;
  final String timesPerDay;
  final String remarks;

  const PrescriptionItem({
    required this.medicineName,
    required this.duration,
    required this.timesPerDay,
    required this.remarks,
  });

  /// Factory for an empty row
  factory PrescriptionItem.empty() {
    return const PrescriptionItem(
      medicineName: '',
      duration: '',
      timesPerDay: '',
      remarks: '',
    );
  }

  /// Whether all 4 mandatory fields are filled with non-whitespace content.
  bool get isComplete =>
      medicineName.trim().isNotEmpty &&
      duration.trim().isNotEmpty &&
      timesPerDay.trim().isNotEmpty &&
      remarks.trim().isNotEmpty;

  /// Whether any field contains content.
  bool get isPartiallyFilled =>
      medicineName.trim().isNotEmpty ||
      duration.trim().isNotEmpty ||
      timesPerDay.trim().isNotEmpty ||
      remarks.trim().isNotEmpty;

  /// Returns missing field names for validation reporting.
  List<String> get missingFields {
    final missing = <String>[];
    if (medicineName.trim().isEmpty) missing.add('Name of Medicine');
    if (duration.trim().isEmpty) missing.add('Duration');
    if (timesPerDay.trim().isEmpty) missing.add('Times a Day');
    if (remarks.trim().isEmpty) missing.add('Remarks');
    return missing;
  }

  PrescriptionItem copyWith({
    String? medicineName,
    String? duration,
    String? timesPerDay,
    String? remarks,
  }) {
    return PrescriptionItem(
      medicineName: medicineName ?? this.medicineName,
      duration: duration ?? this.duration,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'duration': duration,
      'timesPerDay': timesPerDay,
      'remarks': remarks,
    };
  }

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      medicineName: map['medicineName'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      timesPerDay: map['timesPerDay'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrescriptionItem &&
          runtimeType == other.runtimeType &&
          medicineName == other.medicineName &&
          duration == other.duration &&
          timesPerDay == other.timesPerDay &&
          remarks == other.remarks;

  @override
  int get hashCode =>
      medicineName.hashCode ^
      duration.hashCode ^
      timesPerDay.hashCode ^
      remarks.hashCode;

  @override
  String toString() {
    return 'PrescriptionItem(medicineName: $medicineName, duration: $duration, timesPerDay: $timesPerDay, remarks: $remarks)';
  }
}
