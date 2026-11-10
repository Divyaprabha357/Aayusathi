import 'package:flutter/material.dart';
import '../models/admin_section.dart';

/// Global controller managing active administrative section state.
class AdminNavigationController extends ChangeNotifier {
  static final AdminNavigationController instance = AdminNavigationController._();
  AdminNavigationController._();

  AdminSection _activeSection = AdminSection.dashboard;
  AdminSection get activeSection => _activeSection;

  void setSection(AdminSection section) {
    if (_activeSection != section) {
      _activeSection = section;
      notifyListeners();
    }
  }

  void reset() {
    _activeSection = AdminSection.dashboard;
    notifyListeners();
  }
}
