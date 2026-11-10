import 'package:flutter/material.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';

/// Senior-accessible error state with retry action.
class PatientErrorState extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback onRetry;

  const PatientErrorState({
    super.key,
    this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: PatientColors.statusCriticalLight,
                shape: BoxShape.circle,
                border: Border.all(color: PatientColors.statusCritical.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: PatientColors.statusCritical,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title ?? strings.errorTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PatientColors.navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: PatientColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(strings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
