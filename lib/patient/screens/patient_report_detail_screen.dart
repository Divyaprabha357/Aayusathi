import 'package:flutter/material.dart';
import '../../doctor/models/investigation_request.dart';
import '../localization/patient_localizations.dart';
import '../localization/patient_strings.dart';
import '../services/patient_session_service.dart';
import '../theme/patient_colors.dart';
import '../widgets/patient_error_state.dart';
import '../widgets/patient_top_bar.dart';

/// Senior-accessible Report Detail Screen (`/patient/reports/:reportId`).
class PatientReportDetailScreen extends StatelessWidget {
  final String reportId;
  final InvestigationRequest? preloadedReport;
  final String? caseTitle;
  final DateTime? visitDate;

  const PatientReportDetailScreen({
    super.key,
    required this.reportId,
    this.preloadedReport,
    this.caseTitle,
    this.visitDate,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final report = preloadedReport;

    // Strict patient authorization check
    final authId = PatientSessionService.instance.authenticatedPatientId;
    final isUnauthorized = report != null &&
        report.patientId != null &&
        report.patientId!.isNotEmpty &&
        authId != null &&
        authId.isNotEmpty &&
        report.patientId != authId;

    if (isUnauthorized) {
      return Scaffold(
        backgroundColor: PatientColors.background,
        appBar: PatientTopBar(
          title: strings.reportDetailTitle,
          showBackButton: true,
        ),
        body: Center(
          child: PatientErrorState(
            message: 'You do not have permission to access this medical report.',
            onRetry: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final isUploaded = report?.status == InvestigationStatus.uploaded;
    final isReviewed = report?.status == InvestigationStatus.reviewed;
    final isPending = report?.status == InvestigationStatus.pendingUpload;
    final effectiveVisitDate = visitDate ?? report?.requestedAt;

    return Scaffold(
      backgroundColor: PatientColors.background,
      appBar: PatientTopBar(
        title: strings.reportDetailTitle,
        showBackButton: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PatientColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: PatientColors.border, width: 1.5),
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
                      // Status Badge (No internal ID leakage)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(strings, isPending, isUploaded, isReviewed),
                          if (report?.isRequired ?? false) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE9E7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'REQUIRED',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD84315),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Investigation / Test Name
                      Text(
                        report?.name ?? 'Diagnostic Investigation Report',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PatientColors.navy,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Associated Details
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PatientColors.borderSubtle, width: 1),
                        ),
                        child: Column(
                          children: [
                            if (caseTitle != null && caseTitle!.isNotEmpty) ...[
                              _buildMetaRow(
                                icon: Icons.folder_outlined,
                                label: strings.reportCaseLabel,
                                value: caseTitle!,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (effectiveVisitDate != null) ...[
                              _buildMetaRow(
                                icon: Icons.calendar_today_rounded,
                                label: strings.reportRequestedDate,
                                value: _formatDate(effectiveVisitDate),
                              ),
                            ],
                            if (report?.uploadedAt != null) ...[
                              const SizedBox(height: 8),
                              _buildMetaRow(
                                icon: Icons.file_upload_outlined,
                                label: strings.reportSubmissionDate,
                                value: _formatDate(report!.uploadedAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Divider(color: PatientColors.borderSubtle, height: 1),
                      const SizedBox(height: 20),

                      // Guidance Information
                      Text(
                        'Report Information',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PatientColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isUploaded || isReviewed
                            ? 'Your diagnostic test result has been completed and attached to your clinical record.'
                            : 'This test was prescribed by your attending doctor. Please complete the diagnostic test at the hospital laboratory or collection center.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: PatientColors.navy,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (isPending) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                '/patient/reports/$reportId/upload',
                                arguments: {
                                  'investigation': report,
                                  'report': report,
                                  'caseTitle': caseTitle,
                                  'visitDate': effectiveVisitDate,
                                },
                              );
                            },
                            icon: const Icon(Icons.upload_file_rounded, size: 20),
                            label: Text(
                              strings.submitReportAction,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PatientColors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: PatientColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: PatientColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: PatientColors.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    PatientStrings strings,
    bool isPending,
    bool isUploaded,
    bool isReviewed,
  ) {
    if (isReviewed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 14, color: PatientColors.tealDark),
            const SizedBox(width: 4),
            Text(
              strings.reviewedStatus,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PatientColors.tealDark,
              ),
            ),
          ],
        ),
      );
    }

    if (isUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: PatientColors.statusSuccessLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: PatientColors.statusSuccess),
            const SizedBox(width: 4),
            Text(
              strings.reportStatusUploaded,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PatientColors.statusSuccess,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PatientColors.orangeLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.priority_high_rounded, size: 14, color: PatientColors.orange),
          const SizedBox(width: 4),
          Text(
            strings.reportRequiredStatus,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PatientColors.orange,
            ),
          ),
        ],
      ),
    );
  }


  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[(dt.month - 1).clamp(0, 11)];
    return '$day $month ${dt.year}';
  }
}
