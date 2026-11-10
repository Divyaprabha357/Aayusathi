import 'package:flutter/material.dart';
import '../../doctor/models/clinical_case.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';

/// Reusable Card representing a patient's clinical case in the Patient App.
class PatientCaseCard extends StatelessWidget {
  final ClinicalCase clinicalCase;
  final VoidCallback onTap;

  const PatientCaseCard({
    super.key,
    required this.clinicalCase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final isOpen = clinicalCase.isOpen;
    final isEscalated = clinicalCase.isEscalated;

    return Material(
      color: PatientColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
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
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Department & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: PatientColors.tealLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        clinicalCase.displayDepartment,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PatientColors.tealDark,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(strings, isOpen, isEscalated),
                ],
              ),
              const SizedBox(height: 12),

              // Case Title
              Text(
                clinicalCase.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.navy,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Optional Relevant History Preview
              if (clinicalCase.relevantHistory != null &&
                  clinicalCase.relevantHistory!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  clinicalCase.relevantHistory!.trim(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: PatientColors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),

              // Metadata Row: Date, Visit Count & Forward Chevron
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: PatientColors.textMuted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            clinicalCase.isClosed && clinicalCase.closedAt != null
                                ? '${strings.caseCompletedDate}: ${_formatDate(clinicalCase.closedAt!)}'
                                : '${strings.caseStartedDate}: ${_formatDate(clinicalCase.createdAt)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: PatientColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6F3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          size: 13,
                          color: PatientColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.formatVisits(clinicalCase.visitCount),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PatientColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: PatientColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic strings, bool isOpen, bool isEscalated) {
    if (!isOpen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEBEFF2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          strings.caseStatusClosed,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: PatientColors.textSecondary,
          ),
        ),
      );
    }

    if (isEscalated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: PatientColors.orangeLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          strings.caseStatusEscalated,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: PatientColors.orange,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: PatientColors.statusSuccessLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        strings.caseStatusOngoing,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: PatientColors.statusSuccess,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }
}
