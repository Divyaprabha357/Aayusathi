import 'package:flutter/material.dart';
import '../theme/patient_colors.dart';
import 'patient_empty_state_visual.dart';

/// Calm, friendly, senior-accessible empty state widget for zero-data screens.
///
/// Features:
/// - Soothing healthcare-themed concentric visual badge (no generic folder icons)
/// - Bold, readable typography (18sp title, 14sp supporting message)
/// - Optional prominent action button with minimum 48dp touch target
/// - Fully responsive across 360–430dp Android devices
class PatientEmptyState extends StatelessWidget {
  final IconData? icon;
  final PatientEmptyStateVisualType? visualType;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Widget? customVisual;

  const PatientEmptyState({
    super.key,
    this.icon,
    this.visualType,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionTap,
    this.customVisual,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PatientColors.border, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: PatientColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customVisual != null)
                customVisual!
              else if (visualType != null)
                PatientEmptyStateVisual(type: visualType!)
              else if (icon != null)
                _buildLegacyIconBadge(icon!)
              else
                const PatientEmptyStateVisual(
                  type: PatientEmptyStateVisualType.genericMedical,
                ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PatientColors.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PatientColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionText != null && onActionTap != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onActionTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PatientColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      actionText!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyIconBadge(IconData ic) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0F2F1).withAlpha(120),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0F2F1),
              border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00796B), Color(0xFF004D40)],
              ),
            ),
            child: Icon(
              ic,
              size: 26,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
