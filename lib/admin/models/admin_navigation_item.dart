import 'package:flutter/material.dart';

/// Navigation item model for the persistent Admin Sidebar.
class AdminNavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String routeName;
  final int? badgeCount;

  const AdminNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routeName,
    this.badgeCount,
  });

  AdminNavigationItem copyWith({
    String? id,
    String? label,
    IconData? icon,
    IconData? selectedIcon,
    String? routeName,
    int? badgeCount,
  }) {
    return AdminNavigationItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      routeName: routeName ?? this.routeName,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }
}
