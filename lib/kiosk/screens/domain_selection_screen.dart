import 'package:flutter/material.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/appointment_request.dart';
import '../../models/opd_domain.dart';
import '../models/kiosk_session.dart';
import '../models/patient_identity.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_domain_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_secondary_button.dart';

/// Phase 8: OPD Domain Selection Screen.
/// Displays 8 hospital clinical departments as large touchscreen cards.
/// Checks previous visit history upon domain selection and routes accordingly.
class DomainSelectionScreen extends StatefulWidget {
  final PatientIdentity patient;

  const DomainSelectionScreen({
    super.key,
    required this.patient,
  });

  @override
  State<DomainSelectionScreen> createState() => _DomainSelectionScreenState();
}

class _DomainSelectionScreenState extends State<DomainSelectionScreen> {
  OpdDomain? _selectedDomain;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedDomain = KioskService.instance.selectedDomain;
  }

  void _onDomainSelected(OpdDomain domain) {
    setState(() {
      _selectedDomain = domain;
    });
    KioskService.instance.setSelectedDomain(domain);
  }

  Future<void> _onContinue() async {
    if (_selectedDomain == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    final kioskService = KioskService.instance;
    final domain = _selectedDomain!;

    kioskService.setSelectedDomain(domain);

    try {
      if (kioskService.userType == UserType.newUser || widget.patient.isNewRegistration) {
        // FIRST-TIME PATIENT:
        // Completely skip PreviousVisitService.
        // Create normal appointment request atomically and persist.
        final appointment = await kioskService.bookAndPersistAppointment(
          patientId: widget.patient.patientId,
          domainId: domain.id,
          preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.queueConfirmation,
          arguments: appointment,
        );
      } else {
        // EXISTING PATIENT:
        // Check PreviousVisitService for this patient + selected domain.
        final hasPrevious = await kioskService.previousVisitService.hasPreviousVisit(
          patientId: widget.patient.patientId,
          domainId: domain.id,
        );

        if (!mounted) return;

        if (!hasPrevious) {
          // No previous visit: skip doctor preference and create queue ticket directly
          final appointment = await kioskService.bookAndPersistAppointment(
            patientId: widget.patient.patientId,
            domainId: domain.id,
            preferredDoctorMode: PreferredDoctorMode.anyDoctor,
          );

          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.queueConfirmation,
            arguments: appointment,
          );
        } else {
          // Previous visit exists: route to Doctor Preference Screen
          final previousRecord = await kioskService.previousVisitService.getPreviousVisit(
            patientId: widget.patient.patientId,
            domainId: domain.id,
          );

          kioskService.setPreviousVisitRecord(previousRecord);

          if (!mounted) return;
          Navigator.of(context).pushNamed(
            AppRoutes.doctorPreference,
            arguments: {
              'patient': widget.patient,
              'domain': domain,
              'previousVisit': previousRecord,
            },
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[DomainSelectionScreen] Appointment creation failed:');
      debugPrint('  error: $e');
      if (e is BackendException) {
        debugPrint('  BackendException code: ${e.code}');
        debugPrint('  BackendException message: ${e.message}');
        debugPrint('  originalError: ${e.originalError}');
      }
      debugPrint('  stackTrace: $stackTrace');
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
        setState(() => _isProcessing = false);
      }
    }
  }

  void _onCancel() {
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final KioskLocale activeLocale = KioskService.instance.activeLocale;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);
          final domains = OpdDomain.all;

          return AayusathiKioskScaffold(
            title: strings.domainSelectionTitle,
            subtitle: strings.domainSelectionSubtitle,
            activeLocale: activeLocale,
            onBack: _onBack,
            onCancel: _onCancel,
            body: Column(
              children: [
                // Scrollable Grid of 8 Domains
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 760;
                            final cardWidth = isWide
                                ? (constraints.maxWidth - 20) / 2
                                : constraints.maxWidth;

                            return Wrap(
                              spacing: 20,
                              runSpacing: 18,
                              children: domains.map((domain) {
                                final isSelected = _selectedDomain?.id == domain.id;
                                return SizedBox(
                                  width: cardWidth,
                                  child: AayusathiDomainCard(
                                    domain: domain,
                                    title: domain.title(strings),
                                    description: domain.description(strings),
                                    isSelected: isSelected,
                                    onTap: () => _onDomainSelected(domain),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Action Bar with Selection Status and Continue Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: Color(0xFFDCE5EC), width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Row(
                        children: [
                          // Back Button
                          AayusathiSecondaryButton(
                            text: strings.back,
                            icon: Icons.arrow_back_rounded,
                            onPressed: _onBack,
                            width: 140,
                          ),
                          const SizedBox(width: 20),

                          // Selected Domain Pill
                          Expanded(
                            child: _selectedDomain != null
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEBF5F3),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.brandTeal.withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _selectedDomain!.icon,
                                            size: 20,
                                            color: AppColors.brandTeal,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              '${strings.selectedDepartment}: ${_selectedDomain!.title(strings)}',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.brandNavy,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 20),

                          // Continue Button
                          AayusathiButton(
                            text: strings.continueText,
                            icon: Icons.arrow_forward_rounded,
                            isLoading: _isProcessing,
                            onPressed: _selectedDomain != null ? _onContinue : null,
                            width: 240,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
