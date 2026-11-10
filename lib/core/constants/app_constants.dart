/// Global constants for the AAYUSATHI ecosystem.
class AppConstants {
  AppConstants._();

  // Branding
  static const String appName = 'AAYUSATHI';
  static const String appTagline = 'LIVE BETTER, TOGETHER';
  static const String appVersion = '1.0.0';

  // Interfaces
  static const String interfaceKiosk = 'kiosk';
  static const String interfacePatient = 'patient';
  static const String interfaceDoctor = 'doctor';
  static const String interfaceAdmin = 'admin';

  // Common UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double kioskCardRadius = 20.0;
}

/// Interface types supported across synchronized AAYUSATHI platforms.
enum AppInterfaceType {
  kiosk,
  patient,
  doctor,
  admin,
}
