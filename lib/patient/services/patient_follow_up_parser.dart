import 'package:cloud_firestore/cloud_firestore.dart';

/// Senior-safe, robust parser for Doctor-recorded clinical follow-up dates.
///
/// Supports:
/// - Firestore [Timestamp]
/// - Standard [DateTime]
/// - Epoch milliseconds [int]
/// - Explicit string formats (e.g. "20 September 2026", "20-09-2026", "September 20, 2026")
/// - Relative duration strings (e.g. "Review in 2 weeks", "3 days", "1 month")
/// - Gracefully returns `null` on missing, malformed, or purely qualitative follow-ups without crashing.
class PatientFollowUpParser {
  PatientFollowUpParser._();

  static const Map<String, int> _monthMap = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  /// Parses [rawValue] into a normalized [DateTime] representing the scheduled follow-up date.
  ///
  /// If [referenceDate] is provided, relative duration strings (e.g., "in 2 weeks")
  /// will be calculated relative to [referenceDate] (defaults to `DateTime.now()`).
  static DateTime? parse(dynamic rawValue, {DateTime? referenceDate}) {
    if (rawValue == null) return null;

    try {
      if (rawValue is DateTime) {
        return DateTime(rawValue.year, rawValue.month, rawValue.day);
      }

      if (rawValue is Timestamp) {
        final dt = rawValue.toDate();
        return DateTime(dt.year, dt.month, dt.day);
      }

      if (rawValue is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(rawValue);
        return DateTime(dt.year, dt.month, dt.day);
      }

      if (rawValue is String) {
        final trimmed = rawValue.trim();
        if (trimmed.isEmpty) return null;

        // 1. Direct ISO / Standard parse
        final directDt = DateTime.tryParse(trimmed);
        if (directDt != null) {
          return DateTime(directDt.year, directDt.month, directDt.day);
        }

        final lower = trimmed.toLowerCase();

        // 2. Format: "20 September 2026" or "20th September 2026" or "20-Sep-2026"
        final dayMonthYearRegex = RegExp(
          r'(\b\d{1,2})(?:st|nd|rd|th)?[\s\-\/\.]+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)[\s\-\/\.]+(\d{4})\b',
          caseSensitive: false,
        );
        final dmyMatch = dayMonthYearRegex.firstMatch(lower);
        if (dmyMatch != null) {
          final day = int.tryParse(dmyMatch.group(1) ?? '');
          final monthStr = dmyMatch.group(2) ?? '';
          final year = int.tryParse(dmyMatch.group(3) ?? '');
          final month = _monthMap[monthStr];
          if (day != null && year != null && month != null) {
            return DateTime(year, month, day);
          }
        }

        // 3. Format: "September 20, 2026" or "Sep 20 2026"
        final monthDayYearRegex = RegExp(
          r'\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)[\s\-\/\.]+(\d{1,2})(?:st|nd|rd|th)?(?:[\,\s\-\/\.]+)+(\d{4})\b',
          caseSensitive: false,
        );
        final mdyMatch = monthDayYearRegex.firstMatch(lower);
        if (mdyMatch != null) {
          final monthStr = mdyMatch.group(1) ?? '';
          final day = int.tryParse(mdyMatch.group(2) ?? '');
          final year = int.tryParse(mdyMatch.group(3) ?? '');
          final month = _monthMap[monthStr];
          if (day != null && year != null && month != null) {
            return DateTime(year, month, day);
          }
        }

        // 4. Numeric formats: DD/MM/YYYY or DD-MM-YYYY
        final numericDmyRegex = RegExp(
          r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b',
        );
        final numMatch = numericDmyRegex.firstMatch(lower);
        if (numMatch != null) {
          final day = int.tryParse(numMatch.group(1) ?? '');
          final month = int.tryParse(numMatch.group(2) ?? '');
          final year = int.tryParse(numMatch.group(3) ?? '');
          if (day != null && month != null && year != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }

        // 5. ISO Numeric formats: YYYY/MM/DD or YYYY-MM-DD
        final numericYmdRegex = RegExp(
          r'\b(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})\b',
        );
        final ymdMatch = numericYmdRegex.firstMatch(lower);
        if (ymdMatch != null) {
          final year = int.tryParse(ymdMatch.group(1) ?? '');
          final month = int.tryParse(ymdMatch.group(2) ?? '');
          final day = int.tryParse(ymdMatch.group(3) ?? '');
          if (day != null && month != null && year != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }

        // 6. Relative offsets: "2 weeks", "in 3 days", "after 1 month", "5 days if fever persists"
        final relativeRegex = RegExp(
          r'(?:in|after)?\s*(\d+)\s*(day|days|week|weeks|month|months|year|years)\b',
          caseSensitive: false,
        );
        final relMatch = relativeRegex.firstMatch(lower);
        if (relMatch != null) {
          final count = int.tryParse(relMatch.group(1) ?? '');
          final unit = relMatch.group(2) ?? '';
          if (count != null && count > 0) {
            final base = referenceDate ?? DateTime.now();
            final baseDate = DateTime(base.year, base.month, base.day);
            if (unit.startsWith('day')) {
              return baseDate.add(Duration(days: count));
            } else if (unit.startsWith('week')) {
              return baseDate.add(Duration(days: count * 7));
            } else if (unit.startsWith('month')) {
              return DateTime(baseDate.year, baseDate.month + count, baseDate.day);
            } else if (unit.startsWith('year')) {
              return DateTime(baseDate.year + count, baseDate.month, baseDate.day);
            }
          }
        }
      }
    } catch (_) {
      // Safe fallback on any unexpected error: return null
      return null;
    }

    return null;
  }
}
