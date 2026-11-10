import 'package:flutter/material.dart';
import '../../doctor/models/clinical_case.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';

/// Prominent card displaying the next upcoming appointment or clean senior-friendly empty state.
class PatientNextVisitCard extends StatelessWidget {
  final DateTime? appointmentDate;
  final String? department;
  final String? doctorName;
  final String? tokenNumber;
  final String? status;
  final VoidCallback? onTap;
  final bool hasError;
  final VoidCallback? onRetry;

  const PatientNextVisitCard({
    super.key,
    this.appointmentDate,
    this.department,
    this.doctorName,
    this.tokenNumber,
    this.status,
    this.onTap,
    this.hasError = false,
    this.onRetry,
  });

  bool get hasUpcomingVisit => appointmentDate != null;

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Material(
      color: PatientColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUpcomingVisit ? PatientColors.teal : PatientColors.border,
              width: hasUpcomingVisit ? 1.8 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: PatientColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: hasUpcomingVisit ? PatientColors.tealLight : const Color(0xFFF1F6F3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 20,
                      color: hasUpcomingVisit ? PatientColors.tealDark : PatientColors.navy,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.nextVisitTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: hasUpcomingVisit ? PatientColors.tealDark : PatientColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (status != null && status!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusBgColor(status!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusTextColor(status!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (tokenNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PatientColors.teal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tokenNumber!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Card Body
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: hasError
                    ? Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: PatientColors.statusCriticalLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.sync_problem_rounded,
                              color: PatientColors.statusCritical,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.unableToLoadAppointments,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PatientColors.navy,
                                  ),
                                ),
                                if (onRetry != null) ...[
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: onRetry,
                                    child: Text(
                                      strings.retry,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: PatientColors.teal,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : (hasUpcomingVisit
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ClinicalCase.normalizeDepartment(department),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: PatientColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (doctorName != null)
                                      Text(
                                        doctorName!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: PatientColors.textSecondary,
                                        ),
                                      )
                                    else
                                      Text(
                                        _formatDate(appointmentDate!),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: PatientColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: PatientColors.tealLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${appointmentDate!.day}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: PatientColors.teal,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      _getMonthAbbr(appointmentDate!.month),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: PatientColors.tealDark,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F5F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: PatientColors.textMuted,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.nextVisitEmpty,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: PatientColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      strings.nextVisitEmptySubtitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: PatientColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusBgColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('follow') || s == 'accepted' || s == 'waiting') {
      return PatientColors.tealLight;
    } else if (s == 'pending') {
      return PatientColors.orangeLight;
    }
    return const Color(0xFFE8ECE9);
  }

  Color _statusTextColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('follow') || s == 'accepted' || s == 'waiting') {
      return PatientColors.tealDark;
    } else if (s == 'pending') {
      return PatientColors.orange;
    }
    return PatientColors.textSecondary;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_getMonthAbbr(dt.month)} ${dt.year}';
  }

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[(month - 1).clamp(0, 11)];
  }
}
