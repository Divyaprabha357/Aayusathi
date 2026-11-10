import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/visit_report_data.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Interactive modal dialog displaying a complete draft preview of the
/// official 9-section AAYUSATHI Case & Visit Documentation before PDF export.
class DoctorVisitReportPreviewDialog extends StatelessWidget {
  final VisitReportData data;
  final VoidCallback onGeneratePdf;
  final KioskLocale locale;

  const DoctorVisitReportPreviewDialog({
    super.key,
    required this.data,
    required this.onGeneratePdf,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);
    final canGenerate = data.canGenerateReport;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        side: const BorderSide(color: DoctorColors.dialogBorder, width: 1.0),
      ),
      backgroundColor: DoctorColors.dialogBg,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 860,
          maxHeight: 720,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: DoctorColors.dialogBg,
            borderRadius: BorderRadius.circular(DoctorTheme.radius12),
          ),
          padding: const EdgeInsets.all(DoctorTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/aayusathi_logo.png',
                          height: 38,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.local_hospital_rounded,
                            color: DoctorColors.dialogPrimaryTeal,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AAYUSATHI',
                                style: DoctorTheme.headline2.copyWith(
                                  color: DoctorColors.dialogDarkTeal,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'LIVE BETTER, TOGETHER',
                                style: DoctorTheme.caption.copyWith(
                                  color: DoctorColors.dialogPrimaryText,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DoctorColors.pageTint,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: DoctorColors.dialogBorder),
                      ),
                      child: const Text(
                        'CASE & VISIT DOCUMENTATION — DRAFT PREVIEW',
                        style: TextStyle(
                          color: DoctorColors.dialogPrimaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DoctorTheme.space12),
              const Divider(color: DoctorColors.dialogBorder, thickness: 1.5),
              const SizedBox(height: DoctorTheme.space8),

            // Gating Warning Banner (if incomplete)
            if (!canGenerate) ...[
              Container(
                margin: const EdgeInsets.only(bottom: DoctorTheme.space12),
                padding: const EdgeInsets.all(DoctorTheme.space12),
                decoration: BoxDecoration(
                  color: DoctorColors.dialogWarningBg,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(
                    color: DoctorColors.dialogWarningBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: DoctorColors.dialogWarningText, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.pdfGatingWarning,
                            style: DoctorTheme.bodyBold.copyWith(
                              color: DoctorColors.dialogWarningText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Missing requirements: ${data.missingRequirements.join(", ")}',
                            style: DoctorTheme.caption.copyWith(
                              color: DoctorColors.dialogWarningText.withValues(alpha: 0.90),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Scrollable 9-Section Report Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(DoctorTheme.space16),
                decoration: BoxDecoration(
                  color: DoctorColors.pageTint,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(color: DoctorColors.dialogBorder),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: VISIT IDENTIFICATION
                      _buildSectionTitle('SECTION 1 — VISIT IDENTIFICATION'),
                      _buildGridContainer([
                        _buildFieldItem('Patient ID', data.patientId),
                        _buildFieldItem('Case ID', data.caseId),
                        _buildFieldItem('Visit', 'Visit ${data.visitNumber}'),
                        _buildFieldItem('Status', data.visitStatus),
                        _buildFieldItem('Department', data.department),
                        _buildFieldItem(
                            'Date / Time', _formatDateTime(data.dateTime)),
                      ]),
                      const SizedBox(height: DoctorTheme.space16),

                      // SECTION 2: PATIENT INFORMATION
                      _buildSectionTitle('SECTION 2 — PATIENT INFORMATION'),
                      _buildGridContainer([
                        _buildFieldItem('Name', data.patientName),
                        _buildFieldItem('Age', '${data.age} Yrs'),
                        _buildFieldItem('Gender', data.gender),
                        _buildFieldItem('Blood Group', data.bloodGroup),
                        _buildFieldItem('Patient Type', data.patientType),
                        _buildFieldItem('Doctor',
                            '${data.doctorName} (${data.doctorQualification})'),
                      ]),
                      const SizedBox(height: DoctorTheme.space16),

                      // SECTION 3: VITALS AT CONSULTATION
                      _buildSectionTitle('SECTION 3 — VITALS AT CONSULTATION'),
                      _buildGridContainer([
                        _buildFieldItem(
                            'SpO₂', data.spo2 ?? 'Not Recorded'),
                        _buildFieldItem(
                            'Heart Rate', data.heartRate ?? 'Not Recorded'),
                        _buildFieldItem('Temperature',
                            data.temperature ?? 'Not Recorded'),
                      ]),
                      const SizedBox(height: DoctorTheme.space16),

                      // SECTION 4: CASE INFORMATION
                      _buildSectionTitle('SECTION 4 — CASE INFORMATION'),
                      _buildGridContainer([
                        _buildFieldItem('Case Title', data.caseTitle),
                        _buildFieldItem('Case Type', data.caseType),
                        _buildFieldItem('Case Status', data.caseStatus),
                        _buildFieldItem(
                            'Previous Relevant History',
                            data.previousRelevantHistory?.isNotEmpty == true
                                ? data.previousRelevantHistory!
                                : 'None reported'),
                      ]),
                      const SizedBox(height: DoctorTheme.space16),

                      // SECTION 5: STRUCTURED CONSULTATION
                      _buildSectionTitle('SECTION 5 — STRUCTURED CONSULTATION'),
                      _buildCardContainer([
                        _buildBlockItem(
                            'Chief Complaint', data.chiefComplaint),
                        _buildBlockItem(
                            'Onset / Duration', data.onsetDuration),
                        _buildBlockItem('Associated Symptoms',
                            data.associatedSymptoms),
                        _buildBlockItem(
                            'Medical History', data.medicalHistory),
                        _buildBlockItem('Current Medication',
                            data.currentMedication),
                        _buildBlockItem('Clinical Observations',
                            data.clinicalObservations),
                        _buildBlockItem('Assessment', data.assessment),
                        _buildBlockItem('Plan', data.plan),
                      ]),
                      const SizedBox(height: DoctorTheme.space16),

                      // Prescriptions (if present)
                      if (data.prescriptions.isNotEmpty) ...[
                        _buildSectionTitle('PRESCRIPTIONS (RX)'),
                        _buildPrescriptionList(data),
                        const SizedBox(height: DoctorTheme.space16),
                      ],

                      // SECTION 6: DOCTOR-APPROVED VISIT SUMMARY
                      _buildSectionTitle(
                          'SECTION 6 — DOCTOR-APPROVED VISIT SUMMARY'),
                      Container(
                        padding: const EdgeInsets.all(DoctorTheme.space12),
                        decoration: BoxDecoration(
                          color: DoctorColors.dialogBg,
                          borderRadius:
                              BorderRadius.circular(DoctorTheme.radius8),
                          border: Border.all(
                              color: DoctorColors.dialogBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Clinical Summary',
                                  style: TextStyle(
                                    color: DoctorColors.dialogDarkTeal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: data.isSummaryApproved
                                        ? DoctorColors.statusNormal
                                        : DoctorColors.dialogWarningText,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    data.summaryStatus,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data.summary.isNotEmpty
                                  ? data.summary
                                  : 'No summary documented.',
                              style: DoctorTheme.bodyRegular.copyWith(
                                color: DoctorColors.dialogPrimaryText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DoctorTheme.space16),

                      // SECTION 7: REPORTS / INVESTIGATIONS REQUESTED
                      _buildSectionTitle(
                          'SECTION 7 — REPORTS / INVESTIGATIONS REQUESTED'),
                      _buildInvestigationsList(data),
                      const SizedBox(height: DoctorTheme.space16),

                      // SECTION 8: PLAN / FOLLOW-UP
                      _buildSectionTitle('SECTION 8 — PLAN / FOLLOW-UP'),
                      _buildGridContainer([
                        _buildFieldItem('Follow-up Advice',
                            data.followUp?.isNotEmpty == true
                                ? data.followUp!
                                : 'Routine review / SOS'),
                        _buildFieldItem(
                            'Patient Instructions',
                            data.patientInstructions?.isNotEmpty == true
                                ? data.patientInstructions!
                                : 'Take medications as prescribed.'),
                      ]),
                      const SizedBox(height: DoctorTheme.space16),

                      // SECTION 9: VISIT COMPLETION
                      _buildSectionTitle('SECTION 9 — VISIT COMPLETION'),
                      _buildGridContainer([
                        _buildFieldItem(
                            'Visit & Case', '${data.completionVisitNumber} • ${data.completionCaseId}'),
                        _buildFieldItem('Consulting Doctor',
                            '${data.consultingDoctor} (${data.consultingDoctorQualification})'),
                        _buildFieldItem(
                            'Summary Approval', data.summaryApprovalNotice),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: DoctorTheme.space16),

            // Dialog Actions
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'AAYUSATHI Clinical Workstation • Official PDF Preview',
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.dialogSecondaryText,
                    fontSize: 12,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DoctorOutlineButton(
                      label: strings.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(strings.generatePdfButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canGenerate
                            ? DoctorColors.dialogPrimaryTeal
                            : const Color(0xFFE2E8F0),
                        foregroundColor: canGenerate
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: canGenerate ? 2 : 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DoctorTheme.radius8),
                          side: BorderSide(
                            color: canGenerate
                                ? DoctorColors.dialogPrimaryTeal
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      onPressed: canGenerate
                          ? () {
                              Navigator.of(context).pop();
                              onGeneratePdf();
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const BoxDecoration(
        color: DoctorColors.dialogBg,
        border: Border(
          left: BorderSide(color: DoctorColors.dialogPrimaryTeal, width: 3),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: DoctorColors.dialogPrimaryText,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGridContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space12),
      decoration: BoxDecoration(
        color: DoctorColors.dialogBg,
        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
        border: Border.all(color: DoctorColors.dialogBorder),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: children,
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space12),
      decoration: BoxDecoration(
        color: DoctorColors.dialogBg,
        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
        border: Border.all(color: DoctorColors.dialogBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFieldItem(String label, String value) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.dialogSecondaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.dialogPrimaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.dialogSecondaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.dialogPrimaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionList(VisitReportData data) {
    return Container(
      decoration: BoxDecoration(
        color: DoctorColors.dialogBg,
        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
        border: Border.all(color: DoctorColors.dialogBorder),
      ),
      child: Column(
        children: data.prescriptions.map((p) {
          return ListTile(
            dense: true,
            title: Text(p.medicineName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: DoctorColors.dialogPrimaryText)),
            subtitle: Text(
                '${p.duration} • ${p.timesPerDay}${p.remarks.isNotEmpty ? " • ${p.remarks}" : ""}',
                style: const TextStyle(color: DoctorColors.dialogSecondaryText)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInvestigationsList(VisitReportData data) {
    if (data.investigations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DoctorTheme.space12),
        decoration: BoxDecoration(
          color: DoctorColors.dialogBg,
          borderRadius: BorderRadius.circular(DoctorTheme.radius6),
          border: Border.all(color: DoctorColors.dialogBorder),
        ),
        child: const Text(
          'No reports or investigations requested.',
          style: TextStyle(color: DoctorColors.dialogSecondaryText, fontSize: 12),
        ),
      );
    }

    return Column(
      children: data.investigations.map((inv) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DoctorColors.dialogBg,
            borderRadius: BorderRadius.circular(DoctorTheme.radius6),
            border: Border.all(color: DoctorColors.dialogBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(inv.name,
                  style: const TextStyle(
                      color: DoctorColors.dialogPrimaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Row(
                children: [
                  Text(inv.category.label,
                      style: const TextStyle(
                          color: DoctorColors.dialogPrimaryTeal, fontSize: 11)),
                  const SizedBox(width: 8),
                  Text('• ${inv.priority.label}',
                      style: const TextStyle(
                          color: DoctorColors.dialogSecondaryText, fontSize: 11)),
                  const SizedBox(width: 8),
                  Text('• ${inv.status.label}',
                      style: const TextStyle(
                          color: DoctorColors.dialogPrimaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
