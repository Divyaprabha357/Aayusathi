import 'package:flutter/widgets.dart';
import '../../core/localization/kiosk_locale.dart';
import 'patient_strings.dart';

/// Central localization accessor for the AAYUSATHI Patient App.
class PatientLocalizations {
  final PatientStrings strings;

  const PatientLocalizations([this.strings = const PatientStrings()]);

  static PatientStrings forLocale(KioskLocale locale) {
    switch (locale) {
      case KioskLocale.english:
        return const PatientStrings();
      case KioskLocale.hindi:
        return const PatientStringsHindi();
      case KioskLocale.marathi:
        return const PatientStringsMarathi();
    }
  }

  static PatientStrings forLocaleCode(String code) {
    switch (code.toLowerCase()) {
      case 'hi':
        return const PatientStringsHindi();
      case 'mr':
        return const PatientStringsMarathi();
      default:
        return const PatientStrings();
    }
  }

  static PatientStrings of(BuildContext context) {
    final _InheritedPatientLocalizations? result =
        context.dependOnInheritedWidgetOfExactType<_InheritedPatientLocalizations>();
    return result?.strings ?? const PatientStrings();
  }

  static Widget provider({
    required PatientStrings strings,
    required Widget child,
  }) {
    return _InheritedPatientLocalizations(
      strings: strings,
      child: child,
    );
  }
}

class _InheritedPatientLocalizations extends InheritedWidget {
  final PatientStrings strings;

  const _InheritedPatientLocalizations({
    required this.strings,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedPatientLocalizations oldWidget) {
    return strings != oldWidget.strings;
  }
}
