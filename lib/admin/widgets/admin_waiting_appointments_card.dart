import 'package:flutter/material.dart';
import '../models/admin_waiting_appointment_summary.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import 'admin_card.dart';

/// Compact card displaying incoming waiting OPD appointments with strict privacy protection.
class AdminWaitingAppointmentsCard extends StatelessWidget {
  final List<AdminWaitingAppointmentSummary> appointments;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const AdminWaitingAppointmentsCard({
    super.key,
    required this.appointments,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      title: 'WAITING APPOINTMENTS',
      subtitle: 'Live OPD consultation queue telemetry',
      trailing: appointments.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AdminTheme.space10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AdminColors.brandOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
              ),
              child: Text(
                '${appointments.length} in Queue',
                style: AdminTheme.badgeText.copyWith(
                  color: AdminColors.brandOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AdminTheme.space24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AdminColors.brandTeal),
                  ),
                ),
              ),
            )
          else if (appointments.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AdminTheme.space24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.hourglass_empty_rounded,
                    color: AdminColors.statusAvailable,
                    size: 32,
                  ),
                  const SizedBox(height: AdminTheme.space8),
                  Text(
                    'No patients currently waiting',
                    style: AdminTheme.bodyBold.copyWith(
                      color: AdminColors.brandNavy,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AdminTheme.space4),
                  Text(
                    'All patient requests are currently attended or allocated.',
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: AdminColors.borderSubtle,
              ),
              itemBuilder: (context, index) {
                final apt = appointments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AdminTheme.space12,
                    horizontal: AdminTheme.space8,
                  ),
                  child: Row(
                    children: [
                      // 1. Queue Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AdminTheme.space10,
                          vertical: AdminTheme.space6,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.backgroundSecondary,
                          borderRadius:
                              BorderRadius.circular(AdminTheme.radius8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Text(
                          apt.queueNumber,
                          style: AdminTheme.bodyBold.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space12),

                      // 2. Demographics & Specialty Domain
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apt.domain,
                              style: AdminTheme.bodyBold.copyWith(
                                fontSize: 13,
                                color: AdminColors.brandNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${apt.demographicsFormatted} • ${apt.requestType}',
                              style: AdminTheme.caption.copyWith(
                                color: AdminColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space8),

                      // 3. Waiting Duration & Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: AdminColors.brandOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                apt.waitingDurationFormatted,
                                style: AdminTheme.caption.copyWith(
                                  color: AdminColors.brandOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AdminTheme.space6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AdminColors.brandTeal.withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(AdminTheme.radius4),
                            ),
                            child: Text(
                              apt.status,
                              style: AdminTheme.badgeText.copyWith(
                                fontSize: 9.5,
                                color: AdminColors.brandTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
