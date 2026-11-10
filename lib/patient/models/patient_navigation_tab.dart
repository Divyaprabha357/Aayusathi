import 'package:flutter/material.dart';

/// The four primary navigation tabs for the AAYUSATHI Patient App.
enum PatientNavigationTab {
  dashboard,
  cases,
  reports,
  calendar;

  String get routeName {
    switch (this) {
      case PatientNavigationTab.dashboard:
        return '/patient/dashboard';
      case PatientNavigationTab.cases:
        return '/patient/cases';
      case PatientNavigationTab.reports:
        return '/patient/reports';
      case PatientNavigationTab.calendar:
        return '/patient/calendar';
    }
  }

  IconData get icon {
    switch (this) {
      case PatientNavigationTab.dashboard:
        return Icons.home_rounded;
      case PatientNavigationTab.cases:
        return Icons.folder_shared_rounded;
      case PatientNavigationTab.reports:
        return Icons.description_rounded;
      case PatientNavigationTab.calendar:
        return Icons.calendar_month_rounded;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case PatientNavigationTab.dashboard:
        return Icons.home_rounded;
      case PatientNavigationTab.cases:
        return Icons.folder_shared_rounded;
      case PatientNavigationTab.reports:
        return Icons.description_rounded;
      case PatientNavigationTab.calendar:
        return Icons.calendar_month_rounded;
    }
  }
}
