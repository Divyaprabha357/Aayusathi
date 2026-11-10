import 'package:flutter/widgets.dart';
import '../../core/localization/kiosk_locale.dart';
import 'doctor_strings.dart';

/// Central localization accessor for the AAYUSATHI Doctor module.
class DoctorLocalizations {
  final DoctorStrings strings;

  const DoctorLocalizations([this.strings = const DoctorStrings()]);

  static DoctorStrings forLocale(KioskLocale locale) {
    switch (locale) {
      case KioskLocale.english:
        return const DoctorStrings();
      case KioskLocale.hindi:
        return const DoctorStringsHindi();
      case KioskLocale.marathi:
        return const DoctorStringsMarathi();
    }
  }

  static DoctorStrings forLocaleCode(String code) {
    switch (code.toLowerCase()) {
      case 'hi':
        return const DoctorStringsHindi();
      case 'mr':
        return const DoctorStringsMarathi();
      default:
        return const DoctorStrings();
    }
  }

  static DoctorStrings of(BuildContext context) {
    final _InheritedDoctorLocalizations? result =
        context.dependOnInheritedWidgetOfExactType<_InheritedDoctorLocalizations>();
    return result?.strings ?? const DoctorStrings();
  }

  static Widget provider({
    required DoctorStrings strings,
    required Widget child,
  }) {
    return _InheritedDoctorLocalizations(
      strings: strings,
      child: child,
    );
  }
}

class _InheritedDoctorLocalizations extends InheritedWidget {
  final DoctorStrings strings;

  const _InheritedDoctorLocalizations({
    required this.strings,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedDoctorLocalizations oldWidget) {
    return strings != oldWidget.strings;
  }
}
