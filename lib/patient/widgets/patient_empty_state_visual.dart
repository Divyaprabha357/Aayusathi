import 'package:flutter/material.dart';
import '../theme/patient_colors.dart';

/// Semantic types of healthcare empty state visuals across the Patient app.
enum PatientEmptyStateVisualType {
  noActiveCases,
  noCompletedCases,
  noSubmittedReports,
  noPendingReports,
  noUpcomingVisits,
  genericMedical,
}

/// A clean, professional healthcare visual for patient zero-data states.
///
/// Features:
/// - Soothing multi-layered concentric rings with subtle gradients
/// - Meaningful healthcare icon
/// - Zero generic folder icons
/// - Fully responsive across 360–430dp Android viewports
class PatientEmptyStateVisual extends StatelessWidget {
  final PatientEmptyStateVisualType type;
  final double size;

  const PatientEmptyStateVisual({
    super.key,
    this.type = PatientEmptyStateVisualType.noActiveCases,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configForType(type);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer subtle pulse ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.outerRingColor,
            ),
          ),
          // Middle soft ring
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.middleRingColor,
              border: Border.all(
                color: config.borderColor,
                width: 1.5,
              ),
            ),
          ),
          // Inner badge container
          Container(
            width: size * 0.56,
            height: size * 0.56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: config.innerGradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: config.primaryColor.withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              config.icon,
              size: size * 0.28,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  _VisualConfig _configForType(PatientEmptyStateVisualType t) {
    switch (t) {
      case PatientEmptyStateVisualType.noActiveCases:
        return _VisualConfig(
          icon: Icons.health_and_safety_outlined,
          primaryColor: PatientColors.teal,
          outerRingColor: const Color(0xFFE0F2F1).withAlpha(120),
          middleRingColor: const Color(0xFFE0F2F1),
          borderColor: const Color(0xFFB2DFDB),
          innerGradientColors: const [Color(0xFF00796B), Color(0xFF004D40)],
        );
      case PatientEmptyStateVisualType.noCompletedCases:
        return _VisualConfig(
          icon: Icons.assignment_turned_in_outlined,
          primaryColor: PatientColors.tealDark,
          outerRingColor: const Color(0xFFE8F5E9).withAlpha(120),
          middleRingColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFC8E6C9),
          innerGradientColors: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        );
      case PatientEmptyStateVisualType.noSubmittedReports:
        return _VisualConfig(
          icon: Icons.description_outlined,
          primaryColor: PatientColors.teal,
          outerRingColor: const Color(0xFFE0F7FA).withAlpha(120),
          middleRingColor: const Color(0xFFE0F7FA),
          borderColor: const Color(0xFFB2EBF2),
          innerGradientColors: const [Color(0xFF00838F), Color(0xFF006064)],
        );
      case PatientEmptyStateVisualType.noPendingReports:
        return _VisualConfig(
          icon: Icons.task_alt_rounded,
          primaryColor: PatientColors.tealDark,
          outerRingColor: const Color(0xFFE8F5E9).withAlpha(120),
          middleRingColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFC8E6C9),
          innerGradientColors: const [Color(0xFF388E3C), Color(0xFF1B5E20)],
        );
      case PatientEmptyStateVisualType.noUpcomingVisits:
        return _VisualConfig(
          icon: Icons.event_available_outlined,
          primaryColor: PatientColors.teal,
          outerRingColor: const Color(0xFFF1F8E9).withAlpha(120),
          middleRingColor: const Color(0xFFF1F8E9),
          borderColor: const Color(0xFFDCEDC8),
          innerGradientColors: const [Color(0xFF558B2F), Color(0xFF33691E)],
        );
      case PatientEmptyStateVisualType.genericMedical:
        return _VisualConfig(
          icon: Icons.medical_information_outlined,
          primaryColor: PatientColors.teal,
          outerRingColor: const Color(0xFFE0F2F1).withAlpha(120),
          middleRingColor: const Color(0xFFE0F2F1),
          borderColor: const Color(0xFFB2DFDB),
          innerGradientColors: const [Color(0xFF00796B), Color(0xFF004D40)],
        );
    }
  }
}

class _VisualConfig {
  final IconData icon;
  final Color primaryColor;
  final Color outerRingColor;
  final Color middleRingColor;
  final Color borderColor;
  final List<Color> innerGradientColors;

  const _VisualConfig({
    required this.icon,
    required this.primaryColor,
    required this.outerRingColor,
    required this.middleRingColor,
    required this.borderColor,
    required this.innerGradientColors,
  });
}
