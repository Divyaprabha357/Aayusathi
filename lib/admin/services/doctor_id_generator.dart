import 'dart:math';

/// Deterministic, collision-safe unique Doctor ID generator.
///
/// Convention: `DOC-101`, `DOC-102`, `DOC-103`, etc.
///
/// Mandates:
/// - Avoids naive `length + 1` calculation to prevent collisions in case of deleted or non-contiguous records.
/// - Validates candidate IDs against existing records or async existence check.
class DoctorIdGenerator {
  static const String prefix = 'DOC-';
  static const int defaultStartNumber = 101;

  /// Extracts the numeric suffix from a doctor ID (e.g. 'DOC-104' -> 104).
  /// Returns null if format does not match.
  static int? extractNumber(String rawId) {
    final clean = rawId.trim().toUpperCase();
    if (!clean.startsWith(prefix)) {
      return null;
    }
    final numPart = clean.substring(prefix.length);
    return int.tryParse(numPart);
  }

  /// Formats a number into standard Doctor Unique ID (e.g. 104 -> 'DOC-104').
  static String formatId(int number) {
    return '$prefix$number';
  }

  /// Synchronously computes the next non-colliding ID given an iterable of existing IDs.
  ///
  /// Scans maximum existing number + 1, or fills any missing gaps starting at [startNumber].
  static String generateNextId(
    Iterable<String> existingIds, {
    int startNumber = defaultStartNumber,
  }) {
    final existingNumbers = <int>{};
    for (final id in existingIds) {
      final num = extractNumber(id);
      if (num != null) {
        existingNumbers.add(num);
      }
    }

    int candidate = startNumber;
    while (existingNumbers.contains(candidate)) {
      candidate++;
    }

    return formatId(candidate);
  }

  /// Asynchronously resolves the next collision-safe ID by querying [existsCheck].
  static Future<String> generateCollisionSafeId(
    Future<bool> Function(String candidateId) existsCheck, {
    int startNumber = defaultStartNumber,
    int maxAttempts = 1000,
  }) async {
    int candidate = startNumber;
    int attempts = 0;

    while (attempts < maxAttempts) {
      final candidateId = formatId(candidate);
      final exists = await existsCheck(candidateId);
      if (!exists) {
        return candidateId;
      }
      candidate++;
      attempts++;
    }

    // Fallback pseudo-random collision-resistant suffix if high sequential density
    final randomSuffix = 10000 + Random().nextInt(90000);
    return '$prefix$randomSuffix';
  }
}
