import '../localization/kiosk_locale.dart';

/// Controlled exception class for backend and repository operations in AAYUSATHI.
class BackendException implements Exception {
  final String code;
  final String message;
  final dynamic originalError;

  const BackendException({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'BackendException(code: $code, message: $message)';

  // Common error codes
  static const String unavailable = 'BACKEND_UNAVAILABLE';
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String notFound = 'DOCUMENT_NOT_FOUND';
  static const String networkError = 'NETWORK_ERROR';
  static const String serializationError = 'SERIALIZATION_ERROR';
  static const String invalidData = 'INVALID_DATA';
  static const String duplicatePatient = 'DUPLICATE_PATIENT';
  static const String queueCapacityReached = 'QUEUE_CAPACITY_REACHED';
  static const String queueAllocationFailed = 'QUEUE_ALLOCATION_FAILED';
  static const String persistenceFailed = 'PERSISTENCE_FAILED';

  /// Returns user-friendly message translated for the patient's active language.
  String getLocalizedMessage(KioskLocale locale) {
    switch (code) {
      case duplicatePatient:
        switch (locale) {
          case KioskLocale.hindi:
            return 'यह मरीज पहचान पहले से पंजीकृत है। कृपया पुनः प्रयास करें।';
          case KioskLocale.marathi:
            return 'ही रुग्ण ओळख आधीच नोंदणीकृत आहे. कृपया पुन्हा प्रयत्न करा.';
          case KioskLocale.english:
            return 'This Patient ID is already registered. Please try again.';
        }
      case queueCapacityReached:
        switch (locale) {
          case KioskLocale.hindi:
            return 'आज के लिए टोकन क्षमता समाप्त हो गई है। कृपया अस्पताल डेस्क से संपर्क करें।';
          case KioskLocale.marathi:
            return 'आजच्यासाठी टोकन क्षमता समाप्त झाली आहे. कृपया रुग्णालय डेस्कशी संपर्क साधा.';
          case KioskLocale.english:
            return 'Queue capacity limit reached for today. Please contact the hospital helpdesk.';
        }
      case queueAllocationFailed:
      case persistenceFailed:
        switch (locale) {
          case KioskLocale.hindi:
            return 'अपॉइंटमेंट सहेजने में विफल। कृपया पुनः प्रयास करें।';
          case KioskLocale.marathi:
            return 'अपॉइंटमेंट सेव्ह करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';
          case KioskLocale.english:
            return 'Failed to save appointment. Please try again.';
        }
      case networkError:
      case unavailable:
        switch (locale) {
          case KioskLocale.hindi:
            return 'सर्वर अनुपलब्ध है। कृपया थोड़ी देर बाद प्रयास करें।';
          case KioskLocale.marathi:
            return 'सर्व्हर अनुपलब्ध आहे. कृपया थोड्या वेळाने प्रयत्न करा.';
          case KioskLocale.english:
            return 'Server unavailable. Please try again in a moment.';
        }
      case permissionDenied:
        switch (locale) {
          case KioskLocale.hindi:
            return 'अनधिकृत पहुंच। आपके पास अनुमति नहीं है।';
          case KioskLocale.marathi:
            return 'अनधिकृत प्रवेश. आपल्याकडे परवानगी नाही.';
          case KioskLocale.english:
            return 'Unauthorized access. Please contact administration.';
        }
      case notFound:
        switch (locale) {
          case KioskLocale.hindi:
            return 'रिकॉर्ड नहीं मिला। कृपया अपनी जानकारी जांचें।';
          case KioskLocale.marathi:
            return 'नोंद आढळली नाही. कृपया आपली माहिती तपासा.';
          case KioskLocale.english:
            return 'Record not found. Please verify your details.';
        }
      default:
        switch (locale) {
          case KioskLocale.hindi:
            return 'एक त्रुटि हुई। कृपया पुनः प्रयास करें।';
          case KioskLocale.marathi:
            return 'एक त्रुटी आली. कृपया पुन्हा प्रयत्न करा.';
          case KioskLocale.english:
            return 'An error occurred. Please try again.';
        }
    }
  }
}
