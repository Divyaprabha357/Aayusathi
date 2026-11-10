import 'package:flutter/material.dart';
import '../../doctor/models/clinical_visit.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';

/// Senior-accessible Card representing a clinical visit encounter in the Case timeline.
class PatientVisitCard extends StatelessWidget {
  final ClinicalVisit visit;
  final String? department;
  final VoidCallback onTap;

  const PatientVisitCard({
    super.key,
    required this.visit,
    this.department,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final isCompleted = visit.isCompleted;

    return Material(
      color: PatientColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientColors.borderSubtle, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: PatientColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Visit # & Date + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: PatientColors.tealLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            strings.visitNumberLabel(visit.visitNumber),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PatientColors.tealDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatDate(visit.startedAt),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PatientColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCompleted ? strings.caseStatusClosed : strings.caseStatusOngoing,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? const Color(0xFF2E7D32)
                            : PatientColors.tealDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Department & Doctor Row
              if (department != null && department!.trim().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 16, color: PatientColors.teal),
                    const SizedBox(width: 6),
                    Text(
                      department!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              if (visit.doctorName != null && visit.doctorName!.trim().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 16, color: PatientColors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        visit.doctorName!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PatientColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Chief complaint or assessment snippet
              Text(
                (visit.chiefComplaint != null && visit.chiefComplaint!.trim().isNotEmpty)
                    ? visit.chiefComplaint!
                    : (visit.assessment != null && visit.assessment!.trim().isNotEmpty)
                        ? visit.assessment!
                        : 'Consultation encounter recorded.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: PatientColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Action Indicator Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    strings.visitDetailTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.teal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: PatientColors.teal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;
    return '$day $month $year';
  }
}
