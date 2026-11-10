import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/vital_reading.dart';
import '../../services/arduino/arduino_adapter.dart';
import '../../services/arduino/arduino_service.dart';
import '../models/patient_identity.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_vital_card.dart';

/// Available vital input acquisition options in the Kiosk terminal.
enum VitalSourceOption {
  normalVitals,
  abnormalVitals,
  arduinoHardware,
}

/// Phase 7: Clinical Vitals Collection Screen.
/// Displays live sensor telemetry from the Arduino terminal across 3 vital channels:
/// 1. Blood Oxygen (SpO₂ %)
/// 2. Heart Rate (BPM)
/// 3. Body Temperature (°C)
///
/// Blood pressure has been completely removed from the AAYUSATHI system.
///
/// Arduino Hardware mode is selected by default for every session.
/// Two existing simulation options remain fully available and functional.
class VitalsScreen extends StatefulWidget {
  final PatientIdentity patient;

  const VitalsScreen({
    super.key,
    required this.patient,
  });

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  bool _isValidating = false;
  String? _validationError;

  // Arduino Hardware is strictly the default selection for a new vital collection session
  VitalSourceOption _selectedSourceOption = VitalSourceOption.arduinoHardware;
  bool _lastReadingCompleted = false;

  @override
  void initState() {
    super.initState();
    _selectedSourceOption = VitalSourceOption.arduinoHardware;
  }

  @override
  void dispose() {
    KioskService.instance.arduinoService.stopReading();
    KioskService.instance.arduinoService.disconnect();
    super.dispose();
  }

  Future<void> _handleRetakeVitals() async {
    final arduino = KioskService.instance.arduinoService;
    // Prevent duplicate measurement sessions
    if (arduino.isHardwareMeasuring) return;

    SystemSound.play(SystemSoundType.alert);
    _lastReadingCompleted = false;

    setState(() {
      _selectedSourceOption = VitalSourceOption.arduinoHardware;
      _validationError = null;
    });

    await arduino.triggerHardwareMeasurement(
      patientId: widget.patient.patientId,
    );
  }

  Future<void> _selectSourceOption(VitalSourceOption option) async {
    setState(() {
      _selectedSourceOption = option;
      _validationError = null;
    });

    final arduino = KioskService.instance.arduinoService;

    switch (option) {
      case VitalSourceOption.normalVitals:
        await arduino.stopReading();
        arduino.injectReading(
          VitalReading(
            patientId: widget.patient.patientId,
            heartRate: 74,
            spo2: 98,
            temperature: 36.8,
            timestamp: DateTime.now(),
            source: VitalSource.simulated,
            status: VitalStatus.valid,
          ),
        );
        break;

      case VitalSourceOption.abnormalVitals:
        await arduino.stopReading();
        arduino.injectReading(
          VitalReading(
            patientId: widget.patient.patientId,
            heartRate: 125,
            spo2: 89,
            temperature: 38.9,
            timestamp: DateTime.now(),
            source: VitalSource.simulated,
            status: VitalStatus.valid,
          ),
        );
        break;

      case VitalSourceOption.arduinoHardware:
        // Clear previous readings and prepare hardware state
        arduino.reset();
        break;
    }
  }

  Future<void> _handleValidateVitals(BuildContext context, VitalReading reading) async {
    if (_isValidating) return;

    final navigator = Navigator.of(context);

    if (!reading.isComplete) {
      setState(() {
        _validationError = 'Please wait for all vital sensors to complete measurement.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    final validator = KioskService.instance.vitalValidationService;
    final result = validator.validate(reading);

    KioskService.instance.setVitalReading(reading);
    KioskService.instance.setVitalValidationResult(result);

    if (!mounted) return;

    setState(() {
      _isValidating = false;
    });

    if (result.isNormal) {
      // Normal vitals -> Navigate to OPD Domain Selection
      navigator.pushNamed(
        AppRoutes.domainSelection,
        arguments: widget.patient,
      );
    } else {
      // Abnormal vitals -> Navigate to IPD Referral
      navigator.pushNamed(
        AppRoutes.ipdReferral,
        arguments: widget.patient,
      );
    }
  }

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onCancel(BuildContext context) {
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String? _getSourceLabel(VitalReading reading, ArduinoService service) {
    if (service.isHardwareFallback || reading.errorMessage == 'SIMULATED — HARDWARE TIMEOUT') {
      return null;
    }
    if (reading.source == VitalSource.arduino) {
      return 'ARDUINO';
    }
    if (_selectedSourceOption == VitalSourceOption.normalVitals) {
      return 'SIMULATED NORMAL';
    }
    if (_selectedSourceOption == VitalSourceOption.abnormalVitals) {
      return 'SIMULATED ABNORMAL';
    }
    return 'SIMULATED';
  }

  @override
  Widget build(BuildContext context) {
    final KioskLocale activeLocale = KioskService.instance.activeLocale;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);

          return ListenableBuilder(
            listenable: KioskService.instance.arduinoService,
            builder: (context, _) {
              final arduinoService = KioskService.instance.arduinoService;
              final reading = arduinoService.currentReading;
              final connectionState = arduinoService.connectionState;
              final isMeasuring = arduinoService.isHardwareMeasuring;
              final isComplete = reading.isComplete;
              if (isComplete && !_lastReadingCompleted) {
                _lastReadingCompleted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  SystemSound.play(SystemSoundType.alert);
                });
              } else if (!isComplete && _lastReadingCompleted) {
                _lastReadingCompleted = false;
              }
              final isArduinoMode = _selectedSourceOption == VitalSourceOption.arduinoHardware;
              final sourceLabel = _getSourceLabel(reading, arduinoService);

              return AayusathiKioskScaffold(
                title: strings.vitalsCollectionTitle,
                subtitle: strings.vitalsCollectionSubtitle,
                activeLocale: activeLocale,
                onBack: () => _onBack(context),
                onCancel: () => _onCancel(context),
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1060),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Patient Header Card
                          AayusathiGlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandTeal.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: AppColors.brandTeal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.patient.fullName,
                                        style: AppTextStyles.headlineMedium.copyWith(
                                          color: AppColors.brandNavy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${widget.patient.patientId} • ${widget.patient.gender} • ${widget.patient.dobWithAge}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDEF7EC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF84E1BC)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppColors.statusNormal,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'OTP VERIFIED',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.statusNormal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Vital Source Selector (1. Normal Vitals, 2. Abnormal Vitals, 3. Arduino Hardware)
                          _buildVitalSourceSelector(context),

                          const SizedBox(height: 8),

                          // Clear status indicator for selected source: ARDUINO HARDWARE / SIMULATED NORMAL / SIMULATED ABNORMAL
                          _buildSourceStatusIndicator(context),

                          // Live Arduino Connection & Freshness Banner
                          if (isArduinoMode) ...[
                            const SizedBox(height: 8),
                            _buildArduinoStatusBanner(context, arduinoService, connectionState),
                          ],

                          // Active Measuring Progress Banner
                          if (isMeasuring) ...[
                            const SizedBox(height: 8),
                            _buildMeasuringBanner(context, strings),
                          ],

                          const SizedBox(height: 12),

                          // 3 Vital Measurement Cards (SpO₂, Heart Rate, Temperature)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 700;

                              final cardSpo2 = AayusathiVitalCard(
                                title: strings.bloodOxygen,
                                valueDisplay: reading.spo2Display,
                                unit: '%',
                                icon: Icons.air_rounded,
                                iconColor: AppColors.brandTeal,
                                status: isMeasuring
                                    ? VitalStatus.reading
                                    : (reading.hasSpo2 ? VitalStatus.valid : reading.status),
                                sourceLabel: isComplete ? sourceLabel : null,
                              );

                              final cardHeartRate = AayusathiVitalCard(
                                title: strings.heartRate,
                                valueDisplay: reading.heartRateDisplay,
                                unit: 'BPM',
                                icon: Icons.favorite_rounded,
                                iconColor: const Color(0xFFE02424),
                                status: isMeasuring
                                    ? VitalStatus.reading
                                    : (reading.hasHeartRate ? VitalStatus.valid : reading.status),
                                sourceLabel: isComplete ? sourceLabel : null,
                              );

                              final cardTemperature = AayusathiVitalCard(
                                title: strings.bodyTemperature,
                                valueDisplay: reading.temperatureDisplay,
                                unit: '°C',
                                icon: Icons.thermostat_rounded,
                                iconColor: AppColors.brandOrange,
                                status: isMeasuring
                                    ? VitalStatus.reading
                                    : (reading.hasTemperature ? VitalStatus.valid : reading.status),
                                sourceLabel: isComplete ? sourceLabel : null,
                              );

                              if (isWide) {
                                return Row(
                                  children: [
                                    Expanded(child: cardSpo2),
                                    const SizedBox(width: 16),
                                    Expanded(child: cardHeartRate),
                                    const SizedBox(width: 16),
                                    Expanded(child: cardTemperature),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    cardSpo2,
                                    const SizedBox(height: 12),
                                    cardHeartRate,
                                    const SizedBox(height: 12),
                                    cardTemperature,
                                  ],
                                );
                              }
                            },
                          ),

                          if (_validationError != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.statusCritical.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.statusCritical,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _validationError!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.statusCritical,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Primary Action Button:
                          // If in Arduino mode and not complete and not measuring -> TAKE VITALS
                          // If complete -> VALIDATE VITALS
                          _buildPrimaryActionButtons(context, reading, arduinoService, strings),

                          const SizedBox(height: 12),

                          // Simulation / Hardware Toolbar (Maintains exact backwards compatibility with tests)
                          _buildDevSimulationToolbar(context),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Primary Action Area:
  /// - If measuring: shows disabled loading state.
  /// - If readings are complete: shows VALIDATE VITALS and an optional RETAKE VITALS button.
  /// - If readings not complete: shows TAKE VITALS button to trigger software measurement.
  Widget _buildPrimaryActionButtons(
    BuildContext context,
    VitalReading reading,
    ArduinoService arduinoService,
    dynamic strings,
  ) {
    final isMeasuring = arduinoService.isHardwareMeasuring;
    final isComplete = reading.isComplete;

    if (isComplete) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AayusathiButton(
            text: strings.validateVitals,
            isLoading: _isValidating,
            icon: Icons.check_circle_outline_rounded,
            onPressed: !_isValidating ? () => _handleValidateVitals(context, reading) : null,
            width: 280,
          ),
          if (_selectedSourceOption == VitalSourceOption.arduinoHardware) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: !isMeasuring ? _handleRetakeVitals : null,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                strings.retakeVitals,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Readings not complete / collecting measurements:
    // Display clear progress indicator with "Collecting measurements..."
    // (NO duplicate TAKE VITALS button on the vital collection screen!)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.brandNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandNavy),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            strings.collectingMeasurements,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }

  /// Clear status indicator showing:
  /// - `ARDUINO HARDWARE`
  /// - `SIMULATED NORMAL`
  /// - `SIMULATED ABNORMAL`
  Widget _buildSourceStatusIndicator(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    switch (_selectedSourceOption) {
      case VitalSourceOption.arduinoHardware:
        label = 'ARDUINO HARDWARE';
        color = AppColors.brandTeal;
        icon = Icons.memory_rounded;
        break;
      case VitalSourceOption.normalVitals:
        label = 'SIMULATED NORMAL';
        color = AppColors.statusNormal;
        icon = Icons.check_circle_outline_rounded;
        break;
      case VitalSourceOption.abnormalVitals:
        label = 'SIMULATED ABNORMAL';
        color = AppColors.statusCritical;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner indicating active software-triggered acquisition loop.
  Widget _buildMeasuringBanner(BuildContext context, dynamic strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.collectingMeasurements,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vital Source Selector allowing explicit selection of:
  /// 1. Normal Vitals
  /// 2. Abnormal Vitals
  /// 3. Arduino Hardware (Default)
  Widget _buildVitalSourceSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final items = [
            _buildSourceOptionTab(
              title: 'Normal Vitals',
              subtitle: 'Simulated Normal',
              icon: Icons.check_circle_outline_rounded,
              isSelected: _selectedSourceOption == VitalSourceOption.normalVitals,
              activeColor: AppColors.statusNormal,
              onTap: () => _selectSourceOption(VitalSourceOption.normalVitals),
            ),
            _buildSourceOptionTab(
              title: 'Abnormal Vitals',
              subtitle: 'Simulated Abnormal',
              icon: Icons.warning_amber_rounded,
              isSelected: _selectedSourceOption == VitalSourceOption.abnormalVitals,
              activeColor: AppColors.statusCritical,
              onTap: () => _selectSourceOption(VitalSourceOption.abnormalVitals),
            ),
            _buildSourceOptionTab(
              title: 'Arduino Hardware',
              subtitle: 'COM7 @ 9600 baud',
              icon: Icons.memory_rounded,
              isSelected: _selectedSourceOption == VitalSourceOption.arduinoHardware,
              activeColor: AppColors.brandTeal,
              onTap: () => _selectSourceOption(VitalSourceOption.arduinoHardware),
            ),
          ];

          if (isNarrow) {
            return Column(
              children: items
                  .map((w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: w,
                      ))
                  .toList(),
            );
          }

          return Row(
            children: [
              Expanded(child: items[0]),
              const SizedBox(width: 8),
              Expanded(child: items[1]),
              const SizedBox(width: 8),
              Expanded(child: items[2]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSourceOptionTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.brandNavy : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: isSelected ? activeColor : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live connection state and freshness banner for Arduino Hardware mode.
  Widget _buildArduinoStatusBanner(
    BuildContext context,
    ArduinoService service,
    ArduinoConnectionState state,
  ) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String message;
    bool showRetry = false;

    if (service.isStale && !service.isHardwareMeasuring) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      textColor = const Color(0xFFB45309);
      icon = Icons.hourglass_top_rounded;
      message = 'Waiting for fresh reading...';
    } else if (!service.lastCommandSentSuccessfully &&
        service.currentReading.errorMessage != null &&
        service.currentReading.errorMessage != 'SIMULATED — HARDWARE TIMEOUT') {
      bg = const Color(0xFFFDE8E8);
      border = const Color(0xFFF8B4B4);
      textColor = AppColors.statusCritical;
      icon = Icons.error_outline_rounded;
      message = service.currentReading.errorMessage!;
      showRetry = true;
    } else {
      switch (state) {
        case ArduinoConnectionState.connecting:
          bg = const Color(0xFFEFF6FF);
          border = const Color(0xFFBFDBFE);
          textColor = const Color(0xFF1D4ED8);
          icon = Icons.sync_rounded;
          message = 'Connecting to Arduino...';
          break;

        case ArduinoConnectionState.connected:
          bg = const Color(0xFFDEF7EC);
          border = const Color(0xFF84E1BC);
          textColor = AppColors.statusNormal;
          icon = Icons.check_circle_rounded;
          message = 'Arduino Connected (COM7 @ 9600 baud)';
          break;

        case ArduinoConnectionState.error:
          bg = const Color(0xFFFDE8E8);
          border = const Color(0xFFF8B4B4);
          textColor = AppColors.statusCritical;
          icon = Icons.error_outline_rounded;
          message = 'Arduino Error: Could not connect to COM7';
          showRetry = true;
          break;

        case ArduinoConnectionState.disconnected:
          bg = const Color(0xFFFFF8F1);
          border = const Color(0xFFFFD8B2);
          textColor = AppColors.brandOrange;
          icon = Icons.link_off_rounded;
          message = 'Arduino Ready / Disconnected';
          showRetry = true;
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (showRetry)
            TextButton.icon(
              onPressed: () => service.reconnect(),
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDevSimulationToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.developer_mode_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          const Text(
            'Hardware Fixture:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              _selectSourceOption(VitalSourceOption.normalVitals);
            },
            child: const Text(
              'Simulate Normal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () {
              _selectSourceOption(VitalSourceOption.abnormalVitals);
            },
            child: const Text(
              'Simulate Abnormal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.statusCritical,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Reset sensor readings to waiting',
            icon: const Icon(Icons.refresh_rounded, size: 16),
            onPressed: () {
              KioskService.instance.arduinoService.reset();
              setState(() {
                _validationError = null;
                _selectedSourceOption = VitalSourceOption.arduinoHardware;
              });
            },
          ),
        ],
      ),
    );
  }
}
