import 'package:flutter/material.dart';
import '../localization/doctor_localizations.dart';
import '../models/doctor_patient_request.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Clinical request card component for incoming OPD consultation queue requests.
///
/// STRICT PRIVACY COMPLIANCE:
/// Oromits all personally identifying patient details (name, Aadhaar, phone, address).
/// Shows only operational data: Queue Number, Age, Gender, Domain, Request Type, Vitals, and Status.
class DoctorPatientRequestCard extends StatelessWidget {
  final DoctorPatientRequest request;
  final bool isAcceptEnabled;
  final bool isLoading;
  final VoidCallback? onAccept;

  const DoctorPatientRequestCard({
    super.key,
    required this.request,
    this.isAcceptEnabled = true,
    this.isLoading = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.of(context);
    final vitals = request.vitals;
    final isPreviousDoctor = request.isPreviousDoctorRequested;
    final isTransfer = request.isTransferRequest;

    String requestTypeLabel;
    if (isTransfer) {
      requestTypeLabel = strings.transferRequestBadge;
    } else if (isPreviousDoctor) {
      requestTypeLabel = strings.previousDoctorRequestedLabel;
    } else {
      requestTypeLabel = strings.newVisitLabel;
    }

    return Container(
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        border: Border.all(
          color: (isTransfer || isPreviousDoctor)
              ? DoctorColors.brandOrange.withValues(alpha: 0.4)
              : DoctorColors.border,
          width: (isTransfer || isPreviousDoctor) ? 1.5 : 1.0,
        ),
        boxShadow: DoctorTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Queue Ticket Badge, Age/Gender, Request Type, Status
          Container(
            padding: const EdgeInsets.all(DoctorTheme.space16),
            decoration: BoxDecoration(
              color: (isTransfer || isPreviousDoctor)
                  ? DoctorColors.brandOrange.withValues(alpha: 0.04)
                  : DoctorColors.backgroundSecondary.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DoctorTheme.radius16),
                topRight: Radius.circular(DoctorTheme.radius16),
              ),
              border: const Border(
                bottom: BorderSide(color: DoctorColors.borderSubtle),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Queue Number Ticket
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DoctorTheme.space12,
                    vertical: DoctorTheme.space6,
                  ),
                  decoration: BoxDecoration(
                    color: DoctorColors.brandNavy,
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        request.queueNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DoctorTheme.space12),

                // Age & Gender
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${request.age} ${strings.ageLabel.toLowerCase()} • ${request.gender}',
                        style: DoctorTheme.bodyBold.copyWith(
                          color: DoctorColors.brandNavy,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            request.domain,
                            style: DoctorTheme.caption.copyWith(
                              color: DoctorColors.brandTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: DoctorColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            requestTypeLabel,
                            style: DoctorTheme.caption.copyWith(
                              color: (isTransfer || isPreviousDoctor)
                                  ? DoctorColors.brandOrange
                                  : DoctorColors.textSecondary,
                              fontWeight: (isTransfer || isPreviousDoctor)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge (Waiting)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DoctorTheme.space10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DoctorColors.statusAvailable.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                    border: Border.all(
                      color: DoctorColors.statusAvailable.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: DoctorColors.statusAvailable,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        strings.waitingStatusLabel.toUpperCase(),
                        style: DoctorTheme.badgeText.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: DoctorColors.statusAvailable,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Transfer Details Box (if transfer request)
          if (isTransfer) ...[
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space16,
                vertical: DoctorTheme.space8,
              ),
              padding: const EdgeInsets.all(DoctorTheme.space12),
              decoration: BoxDecoration(
                color: DoctorColors.brandOrange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(
                  color: DoctorColors.brandOrange.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 16,
                        color: DoctorColors.brandOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${strings.fromDepartmentLabel}: ${request.sourceDepartment ?? 'Other Department'}${request.sourceDoctorName != null && request.sourceDoctorName!.isNotEmpty ? ' (${request.sourceDoctorName})' : ''}',
                        style: DoctorTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DoctorColors.brandNavy,
                        ),
                      ),
                    ],
                  ),
                  if (request.transferReason != null &&
                      request.transferReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${strings.transferReasonCardLabel}: ${request.transferReason}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // 3. Vitals Telemetry Grid
          Padding(
            padding: const EdgeInsets.all(DoctorTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart_outlined,
                      size: 16,
                      color: DoctorColors.brandTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strings.vitalsLabel,
                      style: DoctorTheme.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DoctorColors.brandNavy,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DoctorTheme.space12),

                // 3-Channel Vitals Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 2 * DoctorTheme.space12) / 3;
                    return Wrap(
                      spacing: DoctorTheme.space12,
                      runSpacing: DoctorTheme.space8,
                      children: [
                        _buildVitalChip(
                          width: itemWidth,
                          label: strings.spo2Label,
                          value: vitals?.spo2 != null ? '${vitals!.spo2}%' : strings.notAvailableLabel,
                          icon: Icons.air_rounded,
                          valueColor: vitals?.spo2 != null ? DoctorColors.brandTeal : DoctorColors.textMuted,
                        ),
                        _buildVitalChip(
                          width: itemWidth,
                          label: strings.heartRateLabel,
                          value: vitals?.heartRate != null ? '${vitals!.heartRate} BPM' : strings.notAvailableLabel,
                          icon: Icons.favorite_rounded,
                          valueColor: vitals?.heartRate != null ? DoctorColors.brandNavy : DoctorColors.textMuted,
                        ),
                        _buildVitalChip(
                          width: itemWidth,
                          label: strings.temperatureLabel,
                          value: vitals?.temperature != null
                              ? '${vitals!.temperature!.toStringAsFixed(1)}°C'
                              : strings.notAvailableLabel,
                          icon: Icons.thermostat_rounded,
                          valueColor: vitals?.temperature != null
                              ? DoctorColors.brandNavy
                              : DoctorColors.textMuted,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: DoctorColors.borderSubtle),

          // 3. Action Row
          Padding(
            padding: const EdgeInsets.all(DoctorTheme.space12),
            child: SizedBox(
              width: double.infinity,
              child: DoctorPrimaryButton(
                label: isLoading ? strings.acceptingRequest : strings.acceptRequestButton,
                icon: isLoading ? null : Icons.check_circle_outline_rounded,
                isLoading: isLoading,
                height: 42,
                onPressed: (isAcceptEnabled && !isLoading) ? onAccept : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalChip({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space10,
        vertical: DoctorTheme.space8,
      ),
      decoration: BoxDecoration(
        color: DoctorColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DoctorColors.brandTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: DoctorColors.textMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
