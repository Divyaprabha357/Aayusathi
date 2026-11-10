import 'package:flutter/widgets.dart';
import 'kiosk_locale.dart';
import 'kiosk_strings.dart';

/// Central localization accessor for the AAYUSATHI Kiosk interface.
class KioskLocalizations {
  final KioskLocale locale;
  final KioskStrings strings;

  KioskLocalizations(this.locale) : strings = KioskStrings(locale);

  static KioskStrings of(BuildContext context) {
    final _InheritedKioskLocalizations? result =
        context.dependOnInheritedWidgetOfExactType<_InheritedKioskLocalizations>();
    return result?.strings ?? const KioskStrings(KioskLocale.english);
  }

  static Widget provider({
    required KioskLocale locale,
    required Widget child,
  }) {
    return _InheritedKioskLocalizations(
      locale: locale,
      strings: KioskStrings(locale),
      child: child,
    );
  }
}

class _InheritedKioskLocalizations extends InheritedWidget {
  final KioskLocale locale;
  final KioskStrings strings;

  const _InheritedKioskLocalizations({
    required this.locale,
    required this.strings,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedKioskLocalizations oldWidget) {
    return locale != oldWidget.locale;
  }
}
