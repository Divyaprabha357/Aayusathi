import 'package:cloud_firestore/cloud_firestore.dart';

/// Sensor source of a vital reading.
enum VitalSource {
  arduino,
  manual,
  simulated,
}

/// Status of an individual vital measurement or overall reading.
enum VitalStatus {
  waiting,
  reading,
  valid,
  abnormal,
  error,
}

/// Complete health vital measurement bundle captured from sensors or input.
/// Independent of UI and structured for validation, clinical routing, and Firestore persistence.
class VitalReading {
  final String? vitalId;
  final String? patientId;
  final String? appointmentId;
  final int? heartRate; // Beats per minute (BPM)
  final int? spo2; // Blood oxygen saturation percentage (%)
  final double? temperature; // Body temperature in Celsius (°C)
  final DateTime timestamp;
  final VitalSource source;
  final VitalStatus status;
  final String? validationStatus; // 'normal', 'abnormal', 'incomplete'
  final String? errorMessage;

  const VitalReading({
    this.vitalId,
    this.patientId,
    this.appointmentId,
    this.heartRate,
    this.spo2,
    this.temperature,
    required this.timestamp,
    this.source = VitalSource.arduino,
    this.status = VitalStatus.waiting,
    this.validationStatus,
    this.errorMessage,
  });

  /// True when all required vital channels (HR, SpO2, Temp) have been measured.
  bool get isComplete =>
      heartRate != null && spo2 != null && temperature != null;

  bool get hasHeartRate => heartRate != null;
  bool get hasSpo2 => spo2 != null;
  bool get hasTemperature => temperature != null;

  /// Formatted heart rate string or placeholder.
  String get heartRateDisplay => heartRate != null ? '$heartRate' : '--';

  /// Formatted SpO2 string or placeholder.
  String get spo2Display => spo2 != null ? '$spo2' : '--';

  /// Formatted temperature string or placeholder.
  String get temperatureDisplay =>
      temperature != null ? temperature!.toStringAsFixed(1) : '--';

  VitalReading copyWith({
    String? vitalId,
    String? patientId,
    String? appointmentId,
    int? heartRate,
    int? spo2,
    double? temperature,
    DateTime? timestamp,
    VitalSource? source,
    VitalStatus? status,
    String? validationStatus,
    String? errorMessage,
  }) {
    return VitalReading(
      vitalId: vitalId ?? this.vitalId,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      status: status ?? this.status,
      validationStatus: validationStatus ?? this.validationStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (vitalId != null) 'vitalId': vitalId,
      if (patientId != null) 'patientId': patientId,
      if (appointmentId != null) 'appointmentId': appointmentId,
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
      'source': source.name,
      'status': status.name,
      if (validationStatus != null) 'validationStatus': validationStatus,
      'errorMessage': errorMessage,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (vitalId != null) 'vitalId': vitalId,
      if (patientId != null) 'patientId': patientId,
      if (appointmentId != null) 'appointmentId': appointmentId,
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source.name,
      'status': status.name,
      if (validationStatus != null) 'validationStatus': validationStatus,
      'errorMessage': errorMessage,
    };
  }

  factory VitalReading.fromMap(Map<dynamic, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) {
        final clean = val.replaceAll(RegExp(r'[^\d\-]'), '');
        return int.tryParse(clean);
      }
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val;
      if (val is num) return val.toDouble();
      if (val is String) {
        final clean = val.replaceAll(RegExp(r'[^\d.\-]'), '');
        return double.tryParse(clean);
      }
      return null;
    }

    final parsedHeartRate = parseInt(
      map['heartRate'] ?? map['pulseRate'] ?? map['pulse'] ?? map['bpm'],
    );
    final parsedSpo2 = parseInt(
      map['spo2'] ?? map['spO2'] ?? map['oxygenSaturation'] ?? map['oximetry'],
    );
    final parsedTemperature = parseDouble(
      map['temperature'] ?? map['temp'],
    );

    return VitalReading(
      vitalId: map['vitalId']?.toString(),
      patientId: map['patientId']?.toString(),
      appointmentId: map['appointmentId']?.toString(),
      heartRate: parsedHeartRate,
      spo2: parsedSpo2,
      temperature: parsedTemperature,
      timestamp: parseDate(map['timestamp'] ?? map['recordedAt']),
      source: VitalSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => VitalSource.arduino,
      ),
      status: VitalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VitalStatus.waiting,
      ),
      validationStatus: map['validationStatus']?.toString(),
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  factory VitalReading.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('vitalId')) {
      map['vitalId'] = documentId;
    }
    return VitalReading.fromMap(map);
  }

  /// Empty initial reading state waiting for sensor detection.
  factory VitalReading.empty() {
    return VitalReading(
      timestamp: DateTime.now(),
      status: VitalStatus.waiting,
    );
  }
}
