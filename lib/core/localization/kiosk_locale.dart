/// Supported languages for the AAYUSATHI Kiosk.
enum KioskLocale {
  english(code: 'en', nativeName: 'English', subtitle: 'English'),
  hindi(code: 'hi', nativeName: 'हिन्दी', subtitle: 'Hindi'),
  marathi(code: 'mr', nativeName: 'मराठी', subtitle: 'Marathi');

  final String code;
  final String nativeName;
  final String subtitle;

  const KioskLocale({
    required this.code,
    required this.nativeName,
    required this.subtitle,
  });
}
