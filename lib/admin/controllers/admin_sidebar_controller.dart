import 'package:flutter/material.dart';

/// Global controller managing persistent Admin Sidebar collapse state.
/// Guarantees zero layout shift across screen navigations.
class AdminSidebarController extends ChangeNotifier {
  static final AdminSidebarController instance = AdminSidebarController._();
  AdminSidebarController._();

  bool _isCollapsed = false;
  bool get isCollapsed => _isCollapsed;

  void toggle() {
    _isCollapsed = !_isCollapsed;
    notifyListeners();
  }

  void setCollapsed(bool value) {
    if (_isCollapsed != value) {
      _isCollapsed = value;
      notifyListeners();
    }
  }

  void reset() {
    _isCollapsed = false;
    notifyListeners();
  }
}
