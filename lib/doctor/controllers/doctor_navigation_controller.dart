import 'package:flutter/material.dart';

/// Architectural controller managing the active section in the Doctor Desktop Shell.
class DoctorNavigationController extends ChangeNotifier {
  String _activeRoute;
  bool _isSidebarCollapsed = false;

  DoctorNavigationController({String initialRoute = '/doctor/dashboard'})
      : _activeRoute = initialRoute;

  String get activeRoute => _activeRoute;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  void navigateTo(String route) {
    if (_activeRoute != route) {
      _activeRoute = route;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    if (_isSidebarCollapsed != collapsed) {
      _isSidebarCollapsed = collapsed;
      notifyListeners();
    }
  }
}
