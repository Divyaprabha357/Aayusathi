import 'package:flutter/material.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/appointment_request.dart';
import '../../models/opd_domain.dart';
import '../../models/previous_visit_record.dart';
import '../models/patient_identity.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_secondary_button.dart';

/// Phase 8: Doctor Preference Screen.
/// Inquires if the patient wishes to consult the same doctor from their prior visit.
/// Manages doctor availability, alternative doctor allocation, or safe session reset.
class DoctorPreferenceScreen extends StatefulWidget {
  final PatientIdentity patient;
  final OpdDomain domain;
  final PreviousVisitRecord? previousVisit;

  const DoctorPreferenceScreen({
    super.key,
    required this.patient,
    required this.domain,
    this.previousVisit,
  });

  @override
  State<DoctorPreferenceScreen> createState() => _DoctorPreferenceScreenState();
}

class _DoctorPreferenceScreenState extends State<DoctorPreferenceScreen> {
  bool _isChecking = false;
  bool _showUnavailableDialog = false;

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _onCancel() {
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Patient selects YES to visiting the same doctor.
  Future<void> _onChooseSameDoctor() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final kioskService = KioskService.instance;
    final doctorId = widget.previousVisit?.previousDoctorId ?? '';

    try {
      final isAvailable =
          await kioskService.doctorAvailabilityService.isDoctorAvailable(doctorId);

      if (!mounted) return;

      if (isAvailable) {
        // Same doctor is available: atomically create and persist appointment, then route to queue confirmation
        final appointment = await kioskService.bookAndPersistAppointment(
          patientId: widget.patient.patientId,
          domainId: widget.domain.id,
          previousDoctorId: doctorId,
          preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.queueConfirmation,
          arguments: appointment,
        );
      } else {
        // Previous doctor unavailable: show alternative doctor prompt
        setState(() {
          _showUnavailableDialog = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is BackendException
          ? e.getLocalizedMessage(kioskService.activeLocale)
          : 'Could not create appointment. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.statusCritical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  /// Patient selects NO to visiting the same doctor, or YES to an alternative doctor.
  Future<void> _onChooseAlternativeDoctor() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final kioskService = KioskService.instance;
    final doctorId = widget.previousVisit?.previousDoctorId;

    try {
      final appointment = await kioskService.bookAndPersistAppointment(
        patientId: widget.patient.patientId,
        domainId: widget.domain.id,
        previousDoctorId: doctorId,
        preferredDoctorMode: PreferredDoctorMode.alternativeDoctor,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.queueConfirmation,
        arguments: appointment,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is BackendException
          ? e.getLocalizedMessage(kioskService.activeLocale)
          : 'Could not create appointment. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.statusCritical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  /// Patient declines alternative doctor: routes to ThankYouScreen without creating appointment.
  void _onDeclineAlternativeDoctor() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.thankYou);
  }

  @override
  Widget build(BuildContext context) {
    final KioskLocale activeLocale = KioskService.instance.activeLocale;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);

          return AayusathiKioskScaffold(
            title: strings.doctorPreferenceTitle,
            subtitle: widget.domain.title(strings),
            activeLocale: activeLocale,
            onBack: _onBack,
            onCancel: _onCancel,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _showUnavailableDialog
                        ? _buildUnavailableCard(strings)
                        : _buildPreferenceCard(strings),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Standard Doctor Preference inquiry card (Part 5).
  Widget _buildPreferenceCard(dynamic strings) {
    return AayusathiGlassCard(
      key: const ValueKey('preference_card'),
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Department Badge & Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.35),
                width: 2.0,
              ),
            ),
            child: Icon(
              widget.domain.icon,
              size: 40,
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(height: 24),

          // Department Name
          Text(
            widget.domain.title(strings),
            style: AppTextStyles.headlineLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Core Question: "You have previously visited this department. Would you like to visit the same doctor?"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F9F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6EAE6), width: 1.5),
            ),
            child: Text(
              strings.previousVisitQuestion,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 18,
                height: 1.45,
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 38),

          // Action Buttons: YES / NO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NO Button
              AayusathiSecondaryButton(
                text: strings.no,
                height: 60,
                width: 200,
                onPressed: _isChecking ? null : _onChooseAlternativeDoctor,
              ),
              const SizedBox(width: 24),

              // YES Button
              AayusathiButton(
                text: strings.yes,
                icon: Icons.check_rounded,
                height: 60,
                width: 200,
                isLoading: _isChecking,
                onPressed: _isChecking ? null : _onChooseSameDoctor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Doctor Unavailable inquiry card (Part 7).
  Widget _buildUnavailableCard(dynamic strings) {
    return AayusathiGlassCard(
      key: const ValueKey('unavailable_card'),
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attention Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandOrange.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: 0.4),
                width: 2.0,
              ),
            ),
            child: const Icon(
              Icons.person_off_rounded,
              size: 40,
              color: AppColors.brandOrange,
            ),
          ),
          const SizedBox(height: 24),

          // Title: Doctor Not Available
          Text(
            strings.doctorUnavailableTitle,
            style: AppTextStyles.headlineLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Message: "Doctor not available. Do you want to visit another doctor?"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              strings.doctorUnavailableMessage,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 18,
                height: 1.45,
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 38),

          // Buttons: YES / NO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NO Button -> Resets session to Standby
              AayusathiSecondaryButton(
                text: strings.no,
                height: 60,
                width: 200,
                color: AppColors.brandOrange,
                onPressed: _isChecking ? null : _onDeclineAlternativeDoctor,
              ),
              const SizedBox(width: 24),

              // YES Button -> Assigns another eligible doctor
              AayusathiButton(
                text: strings.yes,
                icon: Icons.check_rounded,
                height: 60,
                width: 200,
                isLoading: _isChecking,
                onPressed: _isChecking ? null : _onChooseAlternativeDoctor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
