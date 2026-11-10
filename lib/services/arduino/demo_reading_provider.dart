import '../../models/vital_reading.dart';

/// Clinical fallback record structure containing plausible demo readings.
class DemoVitalsPreset {
  final int heartRate;
  final int spo2;
  final double temperature;

  const DemoVitalsPreset({
    required this.heartRate,
    required this.spo2,
    required this.temperature,
  });
}

/// Dedicated, testable demonstration-reading provider for AAYUSATHI.
/// Completely decoupled from the production Arduino parser and physical hardware service.
///
/// Implements the deterministic sequence for consecutive hardware timeouts:
/// - Demo attempt 1: Fixed plausible set (e.g. HR: 74, SpO2: 98, Temp: 36.6)
/// - Demo attempt 2: Exact identical set as Attempt 1
/// - Demo attempt 3: Different plausible set (e.g. HR: 78, SpO2: 97, Temp: 36.8)
/// - Subsequent attempts: Deterministic rotation through plausible clinical values.
class DemoReadingProvider {
  static final DemoReadingProvider instance = DemoReadingProvider();

  /// Flag indicating whether demo fallback is enabled on hardware timeout.
  /// Set to true for kiosk demonstration mode; false in production environments.
  bool isDemoModeEnabled = true;

  int _consecutiveAttemptCount = 0;

  /// Preset 1 & 2: Plausible resting baseline
  static const DemoVitalsPreset presetBaseline = DemoVitalsPreset(
    heartRate: 74,
    spo2: 98,
    temperature: 36.6,
  );

  /// Preset 3: Plausible variation A
  static const DemoVitalsPreset presetVariationA = DemoVitalsPreset(
    heartRate: 78,
    spo2: 97,
    temperature: 36.8,
  );

  /// Preset 4: Plausible variation B
  static const DemoVitalsPreset presetVariationB = DemoVitalsPreset(
    heartRate: 72,
    spo2: 99,
    temperature: 36.5,
  );

  /// Preset 5: Plausible variation C
  static const DemoVitalsPreset presetVariationC = DemoVitalsPreset(
    heartRate: 80,
    spo2: 96,
    temperature: 36.9,
  );

  int get consecutiveAttemptCount => _consecutiveAttemptCount;

  /// Resets the consecutive attempt counter for a fresh patient session.
  void reset() {
    _consecutiveAttemptCount = 0;
  }

  /// Manually overrides the attempt count (useful for testing specific sequence steps).
  void setAttemptCount(int count) {
    _consecutiveAttemptCount = count;
  }

  /// Generates the next deterministic simulated reading for a hardware timeout event.
  ///
  /// Strictly marks every generated value with [VitalSource.simulated] and
  /// errorMessage `SIMULATED — HARDWARE TIMEOUT`.
  VitalReading getNextFallbackReading({
    String? patientId,
    String? appointmentId,
  }) {
    _consecutiveAttemptCount++;

    final preset = getPresetForAttempt(_consecutiveAttemptCount);

    return VitalReading(
      patientId: patientId,
      appointmentId: appointmentId,
      heartRate: preset.heartRate,
      spo2: preset.spo2,
      temperature: preset.temperature,
      timestamp: DateTime.now(),
      source: VitalSource.simulated,
      status: VitalStatus.valid,
      errorMessage: 'SIMULATED — HARDWARE TIMEOUT',
    );
  }

  /// Returns the deterministic preset for a given attempt index (1-based).
  ///
  /// - Attempt 1: [presetBaseline]
  /// - Attempt 2: [presetBaseline] (exact match to Attempt 1)
  /// - Attempt 3: [presetVariationA] (different plausible set)
  /// - Subsequent attempts rotate deterministically.
  static DemoVitalsPreset getPresetForAttempt(int attempt) {
    if (attempt <= 1) {
      return presetBaseline;
    } else if (attempt == 2) {
      return presetBaseline; // Consecutive attempt 2 must match attempt 1 exactly
    } else if (attempt == 3) {
      return presetVariationA; // Attempt 3 returns different plausible set
    } else if (attempt == 4) {
      return presetVariationB;
    } else if (attempt == 5) {
      return presetVariationC;
    } else {
      // Deterministic cycle for attempt 6+
      const cycle = [presetVariationA, presetVariationB, presetVariationC];
      return cycle[(attempt - 3) % cycle.length];
    }
  }
}
