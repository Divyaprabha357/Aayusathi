import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'admin_strings.dart';

/// Localizations helper for the Admin Portal.
class AdminLocalizations {
  final AdminStrings strings;

  AdminLocalizations(this.strings);

  static AdminStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final languageCode = locale?.languageCode ?? 'en';
    return AdminStrings.fromLocale(languageCode);
  }

  static const LocalizationsDelegate<AdminLocalizations> delegate =
      _AdminLocalizationsDelegate();
}

class _AdminLocalizationsDelegate
    extends LocalizationsDelegate<AdminLocalizations> {
  const _AdminLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  Future<AdminLocalizations> load(Locale locale) {
    return SynchronousFuture<AdminLocalizations>(
      AdminLocalizations(AdminStrings.fromLocale(locale.languageCode)),
    );
  }

  @override
  bool shouldReload(_AdminLocalizationsDelegate old) => false;
}
