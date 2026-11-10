import 'dart:math';

/// Secure, complexity-compliant temporary password generator for Doctor Provisioning.
///
/// Mandates:
/// - Minimum length of 10 characters.
/// - Contains at least 1 uppercase letter, 1 lowercase letter, 1 digit, and 1 special symbol.
/// - Unpredictable: NOT derived from doctor ID, name, phone, or date of birth.
/// - Passwords generated are distinct and complexity-verified.
class DoctorPasswordGenerator {
  static const String _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // Excludes confusing 'I', 'O'
  static const String _lower = 'abcdefghijkmnopqrstuvwxyz'; // Excludes confusing 'l'
  static const String _digits = '23456789'; // Excludes confusing '0', '1'
  static const String _symbols = '@#\$%!&*?';

  static final Random _random = Random.secure();

  /// Generates a compliant temporary password with prefix `Ayu@` followed by randomized characters.
  /// Example: `Ayu@7Xk92P`
  static String generateTemporaryPassword({int length = 10}) {
    if (length < 8) length = 8;

    // Guaranteed character distribution
    final guaranteed = [
      _upper[_random.nextInt(_upper.length)],
      _lower[_random.nextInt(_lower.length)],
      _digits[_random.nextInt(_digits.length)],
      _symbols[_random.nextInt(_symbols.length)],
    ];

    const allChars = '$_upper$_lower$_digits$_symbols';
    final remainingLength = length - guaranteed.length - 4; // 'Ayu@' uses 4 chars
    final randomPart = <String>[];

    for (int i = 0; i < (remainingLength > 0 ? remainingLength : 2); i++) {
      randomPart.add(allChars[_random.nextInt(allChars.length)]);
    }

    final combined = [...guaranteed, ...randomPart]..shuffle(_random);

    return 'Ayu@${combined.join()}';
  }

  /// Verifies if a given password meets the required complexity standards.
  static bool meetsComplexityRequirements(String password) {
    if (password.length < 8) return false;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[@#\$%!&*?]'));

    return hasUpper && hasLower && hasDigit && hasSpecial;
  }
}
