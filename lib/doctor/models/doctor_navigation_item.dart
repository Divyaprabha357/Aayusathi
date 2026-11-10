import 'package:flutter/material.dart';

/// Navigation descriptor for the Doctor desktop workstation sidebar and routing.
class DoctorNavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String routeName;
  final int? badgeCount;

  const DoctorNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routeName,
    this.badgeCount,
  });
}
