import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized shadows, elevations, and controlled glows for AAYUSATHI Kiosk.
class AppShadows {
  AppShadows._();

  /// Soft ambient elevation for resting cards and surfaces.
  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color(0x0A0A1E3F),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050A1E3F),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Dark card resting shadow for dark theme workflow cards.
  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Hover / Active touchscreen card elevation.
  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x14007E8A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A0A1E3F),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Controlled brand teal glow for primary action buttons and focus states.
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x38007E8A),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];

  /// Subtle medical heartbeat radial glow.
  static List<BoxShadow> heartbeatGlow(double intensity) {
    return [
      BoxShadow(
        color: AppColors.brandTeal.withValues(alpha: 0.25 * intensity),
        blurRadius: 40 * intensity,
        spreadRadius: 8 * intensity,
      ),
      BoxShadow(
        color: AppColors.brandOrange.withValues(alpha: 0.15 * intensity),
        blurRadius: 60 * intensity,
        spreadRadius: 12 * intensity,
      ),
    ];
  }

  /// Critical alert glow for IPD warning banners.
  static const List<BoxShadow> alertGlow = [
    BoxShadow(
      color: Color(0x2EEF4444),
      blurRadius: 24,
      offset: Offset(0, 4),
    ),
  ];
}
