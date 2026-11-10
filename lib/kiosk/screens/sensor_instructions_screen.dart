import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/patient_identity.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';

/// Dedicated Sensor Instructions Screen displayed after patient identity verification
/// and before opening the Vital Collection Screen.
///
/// Guides patients (especially elderly individuals) through simple visual,
/// native animated vector steps for SpO₂ / Heart Rate and Temperature sensors.
class SensorInstructionsScreen extends StatefulWidget {
  final PatientIdentity patient;

  const SensorInstructionsScreen({
    super.key,
    required this.patient,
  });

  @override
  State<SensorInstructionsScreen> createState() => _SensorInstructionsScreenState();
}

class _SensorInstructionsScreenState extends State<SensorInstructionsScreen> {
  late KioskLocale _currentLocale;
  bool _isStartingMeasurement = false;

  @override
  void initState() {
    super.initState();
    _currentLocale = KioskService.instance.activeLocale;
  }

  void _onLanguageSelected(KioskLocale locale) {
    setState(() {
      _currentLocale = locale;
    });
    KioskService.instance.setLocale(locale);
  }

  Future<void> _onTakeVitals() async {
    if (_isStartingMeasurement) return;

    SystemSound.play(SystemSoundType.alert);

    setState(() {
      _isStartingMeasurement = true;
    });

    final arduino = KioskService.instance.arduinoService;

    // Trigger hardware measurement:
    // 1. Verifies serial connection is available (or connects).
    // 2. Sends START\n command exactly once.
    // 3. Starts 15-second timeout.
    // 4. Sets _isHardwareMeasuring = true and begins reading stream.
    await arduino.triggerHardwareMeasurement(
      patientId: widget.patient.patientId,
    );

    if (!mounted) return;

    // Navigate to Vital Collection Screen in Arduino Hardware mode
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.vitals,
      arguments: widget.patient,
    );
  }

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onCancel(BuildContext context) {
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return KioskLocalizations.provider(
      locale: _currentLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);

          return AayusathiKioskScaffold(
            title: strings.sensorInstructionsTitle,
            subtitle: strings.sensorInstructionsSubtitle,
            activeLocale: _currentLocale,
            onBack: () => _onBack(context),
            onCancel: () => _onCancel(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Patient Info & Quick Language Switcher Bar
                      _buildPatientAndLanguageHeader(context),
                      const SizedBox(height: 16),

                      // Steps 1 & 2 Cards (SpO₂ & Temperature)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 780;
                          final step1Card = _buildStepCard(
                            context: context,
                            stepNumber: '1',
                            stepTitle: strings.step1Title,
                            instruction: strings.step1Instruction,
                            subInstruction: strings.step1SubInstruction,
                            badgeColor: AppColors.brandTeal,
                            animationWidget: const FingerSensorAnimationWidget(),
                          );

                          final step2Card = _buildStepCard(
                            context: context,
                            stepNumber: '2',
                            stepTitle: strings.step2Title,
                            instruction: strings.step2Instruction,
                            subInstruction: strings.step2SubInstruction,
                            badgeColor: AppColors.brandOrange,
                            animationWidget: const TemperatureSensorAnimationWidget(),
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: step1Card),
                                const SizedBox(width: 20),
                                Expanded(child: step2Card),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                step1Card,
                                const SizedBox(height: 16),
                                step2Card,
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Step 3 CTA Card: Take Vitals
                      AayusathiGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.statusNormal,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '3',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    strings.step3Instruction,
                                    style: AppTextStyles.headlineMedium.copyWith(
                                      color: AppColors.brandNavy,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AayusathiButton(
                              text: strings.takeVitals,
                              icon: Icons.play_arrow_rounded,
                              isLoading: _isStartingMeasurement,
                              onPressed: _isStartingMeasurement ? null : _onTakeVitals,
                              width: 320,
                              height: 60,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientAndLanguageHeader(BuildContext context) {
    return AayusathiGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Patient Identity Summary
          Row(
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
              Column(
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
                  Text(
                    '${widget.patient.patientId} • ${widget.patient.gender} • ${widget.patient.dobWithAge}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Interactive Language Selector Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: KioskLocale.values.map((locale) {
                final isSelected = _currentLocale == locale;
                return InkWell(
                  onTap: () => _onLanguageSelected(locale),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandTeal : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.brandTeal.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      locale.nativeName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.brandNavy,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required String stepNumber,
    required String stepTitle,
    required String instruction,
    required String subInstruction,
    required Color badgeColor,
    required Widget animationWidget,
  }) {
    return AayusathiGlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stepTitle,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.brandNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Native Animation Area
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: animationWidget,
            ),
          ),
          const SizedBox(height: 16),

          // Primary Instruction
          Text(
            instruction,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),

          // Sub Instruction (Relaxed / Still notice)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: AppColors.brandTeal,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subInstruction,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom-drawn vector animation for Step 1:
/// Finger gently moving into the designated SpO2 / Heart Rate clip sensor.
class FingerSensorAnimationWidget extends StatefulWidget {
  const FingerSensorAnimationWidget({super.key});

  @override
  State<FingerSensorAnimationWidget> createState() => _FingerSensorAnimationWidgetState();
}

class _FingerSensorAnimationWidgetState extends State<FingerSensorAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubic,
        ).value;

        return CustomPaint(
          painter: _FingerSensorPainter(progress: progress),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FingerSensorPainter extends CustomPainter {
  final double progress;

  _FingerSensorPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // 1. Draw subtle background target grid
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 70, gridPaint);
    canvas.drawCircle(center, 45, gridPaint);

    // 2. Pulse oximeter clip sensor body (drawn on the right side)
    final sensorCenter = Offset(size.width * 0.65, size.height * 0.5);
    final sensorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: sensorCenter, width: 85, height: 60),
      const Radius.circular(12),
    );

    // Sensor shadow & body
    final sensorPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(sensorRect, sensorPaint);

    // Sensor top clip jaw
    final jawTop = RRect.fromRectAndRadius(
      Rect.fromCenter(center: sensorCenter.translate(0, -18), width: 75, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(jawTop, Paint()..color = AppColors.brandNavy);

    // Sensor bottom jaw
    final jawBottom = RRect.fromRectAndRadius(
      Rect.fromCenter(center: sensorCenter.translate(0, 18), width: 75, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(jawBottom, Paint()..color = AppColors.brandNavy);

    // Sensor finger aperture slot
    final slotRect = Rect.fromCenter(center: sensorCenter.translate(-25, 0), width: 30, height: 20);
    canvas.drawRect(slotRect, Paint()..color = const Color(0xFF0F172A));

    // LED Sensor Light Indicator (Infrared / Red optical emitter)
    final pulseAlpha = (0.4 + 0.6 * math.sin(progress * math.pi)).clamp(0.0, 1.0);
    final ledPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: pulseAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(sensorCenter.translate(0, -6), 6, ledPaint);
    canvas.drawCircle(sensorCenter.translate(0, -6), 3, Paint()..color = Colors.white);

    // Sensor label text on clip
    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'SpO₂ / HR',
        style: TextStyle(
          color: Color(0xFF38BDF8),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, sensorCenter.translate(8, -5));

    // 3. Animated Finger moving gently into the sensor slot
    // fingerStartX moves from left into the slot
    final fingerStartX = size.width * 0.15 + (progress * 70);
    final fingerY = size.height * 0.5;

    // Finger shaft and fingertip
    final fingerPath = Path();
    fingerPath.moveTo(fingerStartX - 80, fingerY - 14);
    fingerPath.lineTo(fingerStartX, fingerY - 14);
    // Fingertip curve
    fingerPath.quadraticBezierTo(fingerStartX + 18, fingerY - 14, fingerStartX + 20, fingerY);
    fingerPath.quadraticBezierTo(fingerStartX + 18, fingerY + 14, fingerStartX, fingerY + 14);
    fingerPath.lineTo(fingerStartX - 80, fingerY + 14);
    fingerPath.close();

    // Finger gradient
    final fingerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFED7AA), Color(0xFFFDBA74)],
      ).createShader(Rect.fromLTWH(fingerStartX - 80, fingerY - 14, 100, 28));
    canvas.drawPath(fingerPath, fingerPaint);

    // Fingernail
    final nailPath = Path();
    nailPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(fingerStartX + 2, fingerY - 10, 12, 10),
        const Radius.circular(3),
      ),
    );
    canvas.drawPath(nailPath, Paint()..color = const Color(0xFFFFEDD5));

    // Motion arrow indicator
    final arrowAlpha = (1.0 - progress).clamp(0.0, 1.0);
    if (arrowAlpha > 0.1) {
      final arrowPaint = Paint()
        ..color = AppColors.brandTeal.withValues(alpha: arrowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(fingerStartX - 25, fingerY - 26),
        Offset(fingerStartX + 5, fingerY - 26),
        arrowPaint,
      );
      // Arrowhead
      canvas.drawLine(
        Offset(fingerStartX - 2, fingerY - 32),
        Offset(fingerStartX + 5, fingerY - 26),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(fingerStartX - 2, fingerY - 20),
        Offset(fingerStartX + 5, fingerY - 26),
        arrowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FingerSensorPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom-drawn vector animation for Step 2:
/// Thermometer / Temperature sensor moving smoothly to the approved measurement position near the elbow.
class TemperatureSensorAnimationWidget extends StatefulWidget {
  const TemperatureSensorAnimationWidget({super.key});

  @override
  State<TemperatureSensorAnimationWidget> createState() =>
      _TemperatureSensorAnimationWidgetState();
}

class _TemperatureSensorAnimationWidgetState
    extends State<TemperatureSensorAnimationWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubic,
        ).value;

        return CustomPaint(
          painter: _TemperatureSensorPainter(progress: progress),
          size: Size.infinite,
        );
      },
    );
  }
}

class _TemperatureSensorPainter extends CustomPainter {
  final double progress;

  _TemperatureSensorPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw stylized arm outline near elbow region
    final armPaint = Paint()
      ..color = const Color(0xFFFDBA74).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final armPath = Path();
    armPath.moveTo(size.width * 0.15, size.height * 0.25);
    armPath.quadraticBezierTo(
      size.width * 0.38,
      size.height * 0.5,
      size.width * 0.15,
      size.height * 0.75,
    );
    canvas.drawPath(armPath, armPaint);

    // Inner elbow target zone
    final targetCenter = Offset(size.width * 0.36, size.height * 0.5);

    // Radiating target waves
    final waveAlpha = (0.2 + 0.6 * math.sin(progress * math.pi)).clamp(0.0, 1.0);
    final targetWavePaint = Paint()
      ..color = AppColors.brandOrange.withValues(alpha: waveAlpha * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(targetCenter, 20 + 8 * progress, targetWavePaint);
    canvas.drawCircle(targetCenter, 10, Paint()..color = AppColors.brandOrange.withValues(alpha: 0.25));
    canvas.drawCircle(targetCenter, 4, Paint()..color = AppColors.brandOrange);

    // Target label: "ELBOW SENSOR POSITION"
    final targetLabel = TextPainter(
      text: const TextSpan(
        text: 'ELBOW POSITION',
        style: TextStyle(
          color: AppColors.brandOrange,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    targetLabel.paint(canvas, Offset(targetCenter.dx - 40, targetCenter.dy + 26));

    // 2. Animated medical thermometer moving into position
    // Wand moves from right towards the target near the elbow
    final wandX = size.width * 0.85 - (progress * (size.width * 0.40));
    final wandY = size.height * 0.5;

    // Thermometer sensor probe tip
    final probeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(wandX - 20, wandY - 3, 22, 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(probeRect, Paint()..color = const Color(0xFF94A3B8));

    // Thermometer body
    final bodyPath = Path();
    bodyPath.moveTo(wandX, wandY - 12);
    bodyPath.lineTo(wandX + 65, wandY - 16);
    bodyPath.lineTo(wandX + 65, wandY + 16);
    bodyPath.lineTo(wandX, wandY + 12);
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
      ).createShader(Rect.fromLTWH(wandX, wandY - 16, 65, 32));
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Digital readout screen on thermometer
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(wandX + 16, wandY - 8, 30, 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(screenRect, Paint()..color = const Color(0xFF0F172A));

    final tempDisplay = TextPainter(
      text: TextSpan(
        text: '${(36.4 + 0.3 * progress).toStringAsFixed(1)}°C',
        style: const TextStyle(
          color: Color(0xFF34D399),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tempDisplay.paint(canvas, Offset(wandX + 18, wandY - 5));

    // Power/Status LED on wand
    canvas.drawCircle(
      Offset(wandX + 54, wandY),
      3,
      Paint()..color = const Color(0xFF38BDF8),
    );
  }

  @override
  bool shouldRepaint(covariant _TemperatureSensorPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
