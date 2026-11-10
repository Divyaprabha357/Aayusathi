/// Types of vital measurements captured across AAYUSATHI interfaces.
enum VitalType {
  heartRate,
  bloodOxygen,
  bodyTemperature,
  weight,
}

/// Standardized health vital data record captured by sensors or manually inputted.
class HealthVital {
  final String id;
  final String patientId;
  final VitalType type;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final String? deviceId;

  const HealthVital({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'recordedAt': recordedAt.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory HealthVital.fromMap(Map<String, dynamic> map) {
    return HealthVital(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      type: VitalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VitalType.heartRate,
      ),
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      deviceId: map['deviceId'] as String?,
    );
  }
}
