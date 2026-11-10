import 'package:flutter/material.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';

/// Senior-accessible loading indicator with message.
class PatientLoadingState extends StatelessWidget {
  final String? message;

  const PatientLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: PatientColors.teal,
              strokeWidth: 3.5,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? strings.loading,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: PatientColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
