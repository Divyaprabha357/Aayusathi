import '../models/vital_reading.dart';

/// Clinical threshold boundaries used to determine outpatient OPD vs inpatient IPD routing.
/// Fully configurable without modifying UI widgets or hardcoding clinical numbers.
class VitalThresholds {
  final int minHeartRate;
  final int maxHeartRate;
  final int minSpo2;
  final double minTemperature;
  final double maxTemperature;

  const VitalThresholds({
    this.minHeartRate = 60,
    this.maxHeartRate = 100,
    this.minSpo2 = 95,
    this.minTemperature = 36.0,
    this.maxTemperature = 37.5,
  });
}

/// Validation result status for clinical routing.
enum VitalValidationStatus {
  normal,
  abnormal,
  incomplete,
  error,
}

/// Clinical validation result output by [VitalValidationService].
/// UI simply evaluates whether reading is [isNormal] or [isAbnormal] for routing.
class VitalValidationResult {
  final VitalValidationStatus status;
  final List<String> abnormalReasons;
  final VitalReading reading;

  const VitalValidationResult({
    required this.status,
    this.abnormalReasons = const [],
    required this.reading,
  });

  bool get isNormal => status == VitalValidationStatus.normal;
  bool get isAbnormal => status == VitalValidationStatus.abnormal;
  bool get isIncomplete => status == VitalValidationStatus.incomplete;
  bool get hasError => status == VitalValidationStatus.error;

  const VitalValidationResult.normal(this.reading)
      : status = VitalValidationStatus.normal,
        abnormalReasons = const [];

  const VitalValidationResult.abnormal(this.reading, this.abnormalReasons)
      : status = VitalValidationStatus.abnormal;

  const VitalValidationResult.incomplete(this.reading, [this.abnormalReasons = const []])
      : status = VitalValidationStatus.incomplete;

  VitalValidationResult.error(this.reading, [String? error])
      : status = VitalValidationStatus.error,
        abnormalReasons = error != null ? [error] : const [];
}

/// Independent service responsible for validating vital readings against clinical bounds.
/// Contains zero diagnosis or treatment logic; only determines OPD vs IPD safety routing.
class VitalValidationService {
  final VitalThresholds thresholds;

  const VitalValidationService({
    this.thresholds = const VitalThresholds(),
  });

  /// Evaluates the given [reading] against the configured [thresholds].
  VitalValidationResult validate(VitalReading reading) {
    if (!reading.isComplete) {
      final missing = <String>[];
      if (!reading.hasHeartRate) missing.add('Heart Rate');
      if (!reading.hasSpo2) missing.add('SpO₂');
      if (!reading.hasTemperature) missing.add('Body Temperature');
      return VitalValidationResult.incomplete(reading, missing);
    }

    final abnormalReasons = <String>[];

    final hr = reading.heartRate!;
    if (hr < thresholds.minHeartRate || hr > thresholds.maxHeartRate) {
      abnormalReasons.add('Heart Rate ($hr BPM) outside ${thresholds.minHeartRate}-${thresholds.maxHeartRate} BPM');
    }

    final spo2 = reading.spo2!;
    if (spo2 < thresholds.minSpo2) {
      abnormalReasons.add('SpO₂ ($spo2%) below minimum threshold of ${thresholds.minSpo2}%');
    }

    final temp = reading.temperature!;
    if (temp < thresholds.minTemperature || temp > thresholds.maxTemperature) {
      abnormalReasons.add('Temperature (${temp.toStringAsFixed(1)}°C) outside ${thresholds.minTemperature}-${thresholds.maxTemperature}°C');
    }

    if (abnormalReasons.isNotEmpty) {
      return VitalValidationResult.abnormal(reading, abnormalReasons);
    }

    return VitalValidationResult.normal(reading);
  }
}
