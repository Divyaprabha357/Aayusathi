import '../localization/kiosk_locale.dart';

/// Controlled authentication exception in the AAYUSATHI ecosystem.
///
/// Features:
/// - Strongly typed error codes.
/// - Multi-language patient-safe messages (English, Hindi, Marathi).
/// - Redacts internal stack traces from client UI.
class AuthException implements Exception {
  final String code;
  final String message;
  final dynamic originalError;

  const AuthException({
    required this.code,
    required this.message,
    this.originalError,
  });

  // Standard error codes
  static const String authFailed = 'AUTH_FAILED';
  static const String accountDisabled = 'ACCOUNT_DISABLED';
  static const String networkError = 'NETWORK_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String sessionExpired = 'SESSION_EXPIRED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';

  /// Returns user-friendly message translated for the patient's active language.
  String getLocalizedMessage(KioskLocale locale) {
    switch (code) {
      case accountDisabled:
        switch (locale) {
          case KioskLocale.hindi:
            return 'यह खाता अक्षम कर दिया गया है। कृपया अस्पताल प्रशासन से संपर्क करें।';
          case KioskLocale.marathi:
            return 'हे खाते अक्षम केले गेले आहे. कृपया रुग्णालय प्रशासनाशी संपर्क साधा.';
          case KioskLocale.english:
            return 'This account has been disabled. Please contact hospital administration.';
        }
      case networkError:
        switch (locale) {
          case KioskLocale.hindi:
            return 'नेटवर्क अनुपलब्ध है। कृपया अपना इंटरनेट कनेक्शन जांचें।';
          case KioskLocale.marathi:
            return 'नेटवर्क अनुपलब्ध आहे. कृपया आपले इंटरनेट कनेक्शन तपासा.';
          case KioskLocale.english:
            return 'Network unavailable. Please check your connectivity.';
        }
      case unauthorized:
      case permissionDenied:
        switch (locale) {
          case KioskLocale.hindi:
            return 'अनधिकृत पहुंच। आपके पास अनुमति नहीं है।';
          case KioskLocale.marathi:
            return 'अनधिकृत प्रवेश. आपल्याकडे परवानगी नाही.';
          case KioskLocale.english:
            return 'Unauthorized access. You do not have permission.';
        }
      case sessionExpired:
        switch (locale) {
          case KioskLocale.hindi:
            return 'सत्र समाप्त हो गया है। कृपया पुनः प्रयास करें।';
          case KioskLocale.marathi:
            return 'सत्र समाप्त झाले आहे. कृपया पुन्हा प्रयत्न करा.';
          case KioskLocale.english:
            return 'Session expired. Please try again.';
        }
      case authFailed:
      case invalidCredentials:
      default:
        switch (locale) {
          case KioskLocale.hindi:
            return 'प्रमाणीकरण विफल रहा। कृपया पुनः प्रयास करें।';
          case KioskLocale.marathi:
            return 'प्रमाणीकरण अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.';
          case KioskLocale.english:
            return 'Authentication failed. Please try again.';
        }
    }
  }

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
