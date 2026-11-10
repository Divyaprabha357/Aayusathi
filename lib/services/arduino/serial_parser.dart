import '../../models/vital_reading.dart';

/// Clinical boundaries used by the parser to reject physically absurd or corrupt sensor data.
class SensorDataBounds {
  static const int minHeartRate = 25;
  static const int maxHeartRate = 250;

  static const int minSpo2 = 50;
  static const int maxSpo2 = 100;

  static const double minTemperature = 30.0;
  static const double maxTemperature = 45.0;
}

/// Robust streaming parser for Arduino serial telemetry.
/// Supports both:
/// 1. Compact token strings (e.g. `HR:78,SPO2:98,TEMP:36.7` or `HR:82`)
/// 2. Human-readable Arduino output lines:
///    `Heart Rate : 150 BPM`
///    `SpO2       : 74 %`
///    `Temperature: 92.64 F`
///
/// Automatically converts Fahrenheit to Celsius.
/// Safely ignores non-vital lines (headers, borders, blank lines) and rejects
/// invalid sensor states (`ERROR`, `--`, out-of-bounds).
class ArduinoSerialParser {
  /// Parses an incoming serial line or message, merging valid values into the [current] reading.
  /// If the message is completely invalid, returns [current] unmodified.
  static VitalReading parseLine(String rawLine, VitalReading current) {
    if (rawLine.isEmpty) return current;

    final sanitized = rawLine.trim();
    if (sanitized.isEmpty) return current;

    int? hr = current.heartRate;
    int? spo2 = current.spo2;
    double? temp = current.temperature;
    bool updated = false;

    // Split on delimiters (commas, semicolons, newlines) or treat as single line
    final segments = sanitized.split(RegExp(r'[\r\n,;]+'));

    for (final segment in segments) {
      final trimmedSegment = segment.trim();
      if (!trimmedSegment.contains(':')) continue;

      final colonIndex = trimmedSegment.indexOf(':');
      final rawKey = trimmedSegment.substring(0, colonIndex).trim();
      final rawVal = trimmedSegment.substring(colonIndex + 1).trim();

      if (rawKey.isEmpty || rawVal.isEmpty) continue;

      final key = rawKey.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '');

      switch (key) {
        case 'HEARTRATE':
        case 'HR':
        case 'PULSE':
          final parsedHr = _extractFirstInt(rawVal);
          if (parsedHr != null &&
              parsedHr >= SensorDataBounds.minHeartRate &&
              parsedHr <= SensorDataBounds.maxHeartRate) {
            hr = parsedHr;
            updated = true;
          }
          break;

        case 'SPO2':
        case 'SPO2EST':
        case 'SPO2ESTIMATE':
        case 'O2':
        case 'OXYGEN':
        case 'BLOODOXYGEN':
          final parsedSpo2 = _extractFirstInt(rawVal);
          if (parsedSpo2 != null &&
              parsedSpo2 >= SensorDataBounds.minSpo2 &&
              parsedSpo2 <= SensorDataBounds.maxSpo2) {
            spo2 = parsedSpo2;
            updated = true;
          }
          break;

        case 'TEMPERATURE':
        case 'TEMP':
          final parsedTemp = _parseTemperature(rawVal, trimmedSegment);
          if (parsedTemp != null) {
            temp = parsedTemp;
            updated = true;
          }
          break;

        default:
          // Safely ignore unrecognized keys/tokens (including any unexpected BP data)
          break;
      }
    }

    if (!updated) return current;

    final bool isComplete = hr != null && spo2 != null && temp != null;

    return current.copyWith(
      heartRate: hr,
      spo2: spo2,
      temperature: temp,
      timestamp: DateTime.now(),
      status: isComplete ? VitalStatus.valid : VitalStatus.reading,
    );
  }

  /// Extracts the first integer match from a value token (e.g. '150 BPM' -> 150, '74 %' -> 74).
  static int? _extractFirstInt(String valStr) {
    final match = RegExp(r'[+-]?\d+').firstMatch(valStr);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  /// Parses temperature with automatic unit detection and conversion.
  /// If in Fahrenheit (indicated by 'F' or value > 50), converts to Celsius.
  static double? _parseTemperature(String rawVal, String contextLine) {
    final match = RegExp(r'[+-]?\d+(?:\.\d+)?').firstMatch(rawVal);
    if (match == null) return null;

    final numVal = double.tryParse(match.group(0)!);
    if (numVal == null) return null;

    final upperContext = (contextLine + rawVal).toUpperCase();
    // Check if explicitly marked Fahrenheit or Celsius
    final hasF = upperContext.contains('F') && !upperContext.contains('C');
    final isFahrenheit = hasF || numVal > 50.0;

    double celsius = numVal;
    if (isFahrenheit) {
      celsius = (numVal - 32.0) * 5.0 / 9.0;
    }

    // Format to single decimal place
    celsius = double.parse(celsius.toStringAsFixed(1));

    if (celsius >= SensorDataBounds.minTemperature &&
        celsius <= SensorDataBounds.maxTemperature) {
      return celsius;
    }

    return null;
  }
}
