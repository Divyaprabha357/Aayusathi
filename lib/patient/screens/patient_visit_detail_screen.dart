import 'package:flutter/material.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/clinical_visit.dart';
import '../../doctor/models/investigation_request.dart';
import '../../doctor/models/prescription_item.dart';
import '../../doctor/models/report_document.dart';
import '../../models/vital_reading.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_app_state.dart';
import '../services/patient_session_service.dart';
import '../theme/patient_colors.dart';
import '../widgets/patient_empty_state.dart';
import '../widgets/patient_loading_state.dart';
import '../widgets/patient_top_bar.dart';
import '../widgets/patient_visit_report_pdf_viewer.dart';

/// Senior-accessible Read-Only Visit Detail Screen (`/patient/cases/:caseId/visits/:visitId`).
///
/// Features:
/// - Authenticated Patient-scoped clinical data retrieval.
/// - Visit Header with Visit #, Department, Doctor, Date, Status (Zero PII/internal IDs).
/// - Vitals Card (SpO₂, Heart Rate, Temp) with graceful "Not recorded" fallback.
/// - Doctor-Approved Consultation Summary only (zero raw AI or draft leakage).
/// - Structured Clinical Details (Chief Complaint, History, Findings, Assessment, Plan).
/// - Doctor-recorded Prescriptions & Follow-up Instructions.
/// - Diagnostic Investigations with dynamic "Report Required" action and navigation.
/// - 100% Read-Only: zero editing controls for patients.
class PatientVisitDetailScreen extends StatefulWidget {
  final String caseId;
  final String visitId;
  final ClinicalVisit? preloadedVisit;

  const PatientVisitDetailScreen({
    super.key,
    required this.caseId,
    required this.visitId,
    this.preloadedVisit,
  });

  @override
  State<PatientVisitDetailScreen> createState() => _PatientVisitDetailScreenState();
}

class _PatientVisitDetailScreenState extends State<PatientVisitDetailScreen> {
  ClinicalVisit? _visit;
  ClinicalCase? _case;
  VitalReading? _vitals;
  List<InvestigationRequest> _investigations = [];
  ReportDocument? _officialReportDoc;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _visit = widget.preloadedVisit;
    _loadVisitDetails();
  }

  Future<void> _loadVisitDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final patientId = PatientSessionService.instance.authenticatedPatientId;
    if (patientId == null || patientId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    try {
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;
      final caseRepo = BackendProvider.instance.caseRepository;
      final vitalRepo = BackendProvider.instance.vitalRepository;
      final investigationRepo = BackendProvider.instance.investigationRepository;

      bool isSamePatient(String a, String b) {
        final cleanA = a.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '').replaceFirst('AAYU-', '');
        final cleanB = b.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '').replaceFirst('AAYU-', '');
        return cleanA.isNotEmpty && cleanA == cleanB;
      }

      var fetchedCase = await caseRepo.getCaseById(
        patientId: patientId,
        caseId: widget.caseId,
      );

      if (fetchedCase == null) {
        try {
          final allCases = await caseRepo.getCasesForPatient(patientId);
          for (final c in allCases) {
            if (c.caseId == widget.caseId) {
              fetchedCase = c;
              break;
            }
          }
        } catch (e) {
          debugPrint('[PatientVisitDetailScreen] Fallback case fetch error: $e');
        }
      }

      var fetchedVisit = _visit;
      if (fetchedVisit == null) {
        fetchedVisit = await visitRepo.getVisitById(
          patientId: patientId,
          caseId: widget.caseId,
          visitId: widget.visitId,
        );
        if (fetchedVisit == null) {
          try {
            final allVisits = await visitRepo.getVisitsForCase(
              patientId: patientId,
              caseId: widget.caseId,
            );
            for (final v in allVisits) {
              if (v.visitId == widget.visitId) {
                fetchedVisit = v;
                break;
              }
            }
          } catch (e) {
            debugPrint('[PatientVisitDetailScreen] Fallback visits fetch error: $e');
          }
        }
      }

      // Ownership and containment check: case and visit must belong to this patient
      if (fetchedCase == null ||
          !isSamePatient(fetchedCase.patientId, patientId) ||
          fetchedVisit == null ||
          !isSamePatient(fetchedVisit.patientId, patientId) ||
          fetchedVisit.caseId != widget.caseId) {
        debugPrint('[PatientVisitDetailScreen] Ownership check failed: '
            'case=${fetchedCase?.caseId} patient=${fetchedCase?.patientId}, '
            'visit=${fetchedVisit?.visitId} patient=${fetchedVisit?.patientId}, '
            'sessionPatientId=$patientId');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      VitalReading? fetchedVitals = fetchedVisit.vitals;
      try {
        if (fetchedVitals == null &&
            fetchedVisit.appointmentId != null &&
            fetchedVisit.appointmentId!.isNotEmpty) {
          fetchedVitals = await vitalRepo.getVitalsForAppointment(
            fetchedVisit.appointmentId!,
          );
        }
        if (fetchedVitals == null) {
          final allVitals = await vitalRepo.getVitalsForPatient(patientId);
          if (allVitals.isNotEmpty) {
            fetchedVitals = allVitals.first;
          }
        }
      } catch (vitalError) {
        debugPrint('[PatientVisitDetailScreen] Non-fatal vitals fetch error: $vitalError');
        // Vitals grid gracefully displays "Not recorded"
      }

      List<InvestigationRequest> fetchedInvestigations = [];
      try {
        fetchedInvestigations = await investigationRepo.getInvestigationRequests(
          patientId: patientId,
          caseId: widget.caseId,
          visitId: widget.visitId,
        );
      } catch (e) {
        debugPrint('[PatientVisitDetailScreen] Error fetching investigations: $e');
      }

      if (fetchedInvestigations.isEmpty && fetchedVisit.investigationRequests.isNotEmpty) {
        fetchedInvestigations = fetchedVisit.investigationRequests;
      }

      ReportDocument? fetchedOfficialPdf;
      try {
        final reports = await BackendProvider.instance.reportRepository.getReportsForVisit(
          patientId: patientId,
          caseId: widget.caseId,
          visitId: widget.visitId,
        );
        for (final r in reports) {
          final isSupabase = r.storageProvider.toLowerCase() == 'supabase' &&
              (r.storageBucket.isEmpty || r.storageBucket == 'aayusathi-reports');
          final hasPath = r.storagePath.isNotEmpty;
          final isPdf = r.isPdf || r.fileName.toLowerCase().endsWith('.pdf');
          final isOfficial = r.investigationId == 'OFFICIAL_VISIT_REPORT' ||
              r.reviewStatus == ReportReviewStatus.reviewed ||
              r.reportId.startsWith('OFFICIAL-REPORT-');

          if (isSupabase && hasPath && isPdf && isOfficial) {
            fetchedOfficialPdf = r;
            break;
          }
        }
        if (fetchedOfficialPdf == null) {
          for (final r in reports) {
            if (r.storageProvider.toLowerCase() == 'supabase' &&
                r.storagePath.isNotEmpty &&
                (r.isPdf || r.fileName.toLowerCase().endsWith('.pdf'))) {
              fetchedOfficialPdf = r;
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('[PatientVisitDetailScreen] Error querying official report PDF: $e');
      }

      if (mounted) {
        setState(() {
          _visit = fetchedVisit;
          _case = fetchedCase;
          _vitals = fetchedVitals;
          _investigations = fetchedInvestigations;
          _officialReportDoc = fetchedOfficialPdf;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[PatientVisitDetailScreen] Error loading visit details: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _navigateToReports(String investigationId) {
    PatientAppState.instance.navigateToReportsWithInvestigation(investigationId);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      try {
        Navigator.of(context).pushReplacementNamed('/patient/reports');
      } catch (e) {
        debugPrint('[PatientVisitDetailScreen] Navigation fallback: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Scaffold(
      backgroundColor: PatientColors.background,
      appBar: PatientTopBar(
        title: strings.visitDetailTitle,
        showBackButton: true,
      ),
      body: _isLoading
          ? const PatientLoadingState()
          : _hasError
              ? _buildErrorView(strings)
              : _visit == null
                  ? PatientEmptyState(
                      icon: Icons.event_busy_outlined,
                      title: strings.noData,
                      message: 'Visit #${widget.visitId} could not be found.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVisitDetails,
                      color: PatientColors.teal,
                      backgroundColor: PatientColors.surface,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildVisitHeaderCard(strings),
                                const SizedBox(height: 18),
                                _buildOfficialReportPdfCard(strings),
                                const SizedBox(height: 18),
                                _buildVitalsCard(strings),
                                const SizedBox(height: 18),
                                _buildSummaryCard(strings),
                                const SizedBox(height: 18),
                                _buildClinicalDetailsCard(strings),
                                if (_visit!.prescriptions.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  _buildPrescriptionsCard(strings),
                                ],
                                if ((_visit!.followUp != null && _visit!.followUp!.trim().isNotEmpty) ||
                                    (_visit!.patientInstructions != null && _visit!.patientInstructions!.trim().isNotEmpty)) ...[
                                  const SizedBox(height: 18),
                                  _buildFollowUpCard(strings),
                                ],
                                const SizedBox(height: 18),
                                _buildInvestigationsCard(strings),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildVisitHeaderCard(dynamic strings) {
    final visit = _visit!;
    final isCompleted = visit.isCompleted;
    final departmentName = (_visit?.displayDepartment.isNotEmpty == true &&
            _visit!.displayDepartment != 'Department not available')
        ? _visit!.displayDepartment
        : (_case?.displayDepartment.isNotEmpty == true
            ? _case!.displayDepartment
            : 'Department not available');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: PatientColors.tealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    strings.visitNumberLabel(visit.visitNumber),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.tealDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : PatientColors.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            departmentName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: PatientColors.teal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _case?.title ?? 'OPD Consultation',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PatientColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: PatientColors.borderSubtle, height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: PatientColors.tealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: PatientColors.tealDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.visitDoctor,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: PatientColors.textMuted,
                      ),
                    ),
                    Text(
                      visit.doctorName ?? 'Consulting Doctor',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (visit.doctorQualification != null &&
                        visit.doctorQualification!.trim().isNotEmpty) ...[
                      Text(
                        visit.doctorQualification!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: PatientColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: PatientColors.teal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${strings.visitDate}: ${_formatDateTime(visit.completedAt ?? visit.startedAt)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PatientColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialReportPdfCard(dynamic strings) {
    final reportDoc = _officialReportDoc;
    final isAvailable = reportDoc != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable
              ? PatientColors.teal.withValues(alpha: 0.35)
              : PatientColors.borderSubtle,
          width: 1.2,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? PatientColors.tealLight
                      : const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: isAvailable
                      ? PatientColors.tealDark
                      : PatientColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.officialVisitReportTitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PatientColors.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isAvailable) ...[
                      Text(
                        '${reportDoc.fileName} • ${(reportDoc.fileSizeBytes / 1024).toStringAsFixed(0)} KB',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: PatientColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isAvailable) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OFFICIAL',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (isAvailable) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('patient_view_visit_report_pdf_button'),
                onPressed: () => PatientVisitReportPdfViewerDialog.show(
                  context,
                  reportDoc,
                  _visit,
                  _case,
                ),
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: Text(
                  strings.viewVisitReportPdfButton,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PatientColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: PatientColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.visitReportPdfNotAvailable,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PatientColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.visitReportPdfNotAvailableDesc,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: PatientColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalsCard(dynamic strings) {
    final v = _visit?.vitals ?? _vitals;
    final spo2Text = v?.spo2 != null ? '${v!.spo2}%' : strings.notRecorded;
    final hrText = v?.heartRate != null ? '${v!.heartRate} bpm' : strings.notRecorded;
    final temp = v?.temperature;
    final tempText = temp != null
        ? '${temp.toStringAsFixed(1)} ${temp > 50 ? "°F" : "°C"}'
        : strings.notRecorded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined, color: PatientColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.vitalsTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PatientColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final items = [
                _buildVitalItem(
                  label: strings.spo2Label,
                  value: spo2Text,
                  icon: Icons.air_rounded,
                ),
                _buildVitalItem(
                  label: strings.heartRateLabel,
                  value: hrText,
                  icon: Icons.favorite_border_rounded,
                ),
                _buildVitalItem(
                  label: strings.temperatureLabel,
                  value: tempText,
                  icon: Icons.thermostat_outlined,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    items[0],
                    const SizedBox(height: 10),
                    items[1],
                    const SizedBox(height: 10),
                    items[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 10),
                  Expanded(child: items[1]),
                  const SizedBox(width: 10),
                  Expanded(child: items[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: PatientColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PatientColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: PatientColors.teal),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: PatientColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.navy,
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

  Widget _buildSummaryCard(dynamic strings) {
    final visit = _visit!;
    final isApproved = visit.isSummaryApproved;
    final hasSummary = isApproved && visit.effectiveSummary.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.consultationSummaryTitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PatientColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.doctorApprovedSummaryTitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PatientColors.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isApproved
                      ? strings.doctorApprovedNotice
                      : strings.pendingDoctorApprovalNotice,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isApproved
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasSummary ? visit.effectiveSummary : strings.summaryNotAvailable,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontStyle: hasSummary ? FontStyle.normal : FontStyle.italic,
              color: hasSummary ? PatientColors.navy : PatientColors.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalDetailsCard(dynamic strings) {
    final visit = _visit!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              const Icon(Icons.medical_information_outlined, color: PatientColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.consultationDetailsTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PatientColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (visit.chiefComplaint != null && visit.chiefComplaint!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.chiefComplaintLabel, visit.chiefComplaint!),
            const SizedBox(height: 10),
          ],
          if (visit.onsetDuration != null && visit.onsetDuration!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.onsetDurationLabel, visit.onsetDuration!),
            const SizedBox(height: 10),
          ],
          if (visit.associatedSymptoms != null && visit.associatedSymptoms!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.associatedSymptomsLabel, visit.associatedSymptoms!),
            const SizedBox(height: 10),
          ],
          if (visit.medicalHistory != null && visit.medicalHistory!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.medicalHistoryLabel, visit.medicalHistory!),
            const SizedBox(height: 10),
          ],
          if (visit.currentMedication != null && visit.currentMedication!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.currentMedicationLabel, visit.currentMedication!),
            const SizedBox(height: 10),
          ],
          if (visit.clinicalObservations != null && visit.clinicalObservations!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.clinicalObservationsLabel, visit.clinicalObservations!),
            const SizedBox(height: 10),
          ],
          if (visit.assessment != null && visit.assessment!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.assessmentLabel, visit.assessment!),
            const SizedBox(height: 10),
          ],
          if (visit.plan != null && visit.plan!.trim().isNotEmpty) ...[
            _buildFieldBlock(strings.planLabel, visit.plan!),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: PatientColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: PatientColors.navy,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsCard(dynamic strings) {
    final prescriptions = _visit!.prescriptions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              const Icon(Icons.medication_outlined, color: PatientColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.prescriptionsTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PatientColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: prescriptions.length,
            separatorBuilder: (_, _) => const Divider(color: PatientColors.borderSubtle, height: 14),
            itemBuilder: (context, index) {
              final p = prescriptions[index];
              return _buildPrescriptionItem(p, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionItem(PrescriptionItem item, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: PatientColors.tealLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PatientColors.tealDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicineName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.timesPerDay} • ${item.duration}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: PatientColors.textSecondary,
                ),
              ),
              if (item.remarks.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.remarks,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: PatientColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpCard(dynamic strings) {
    final visit = _visit!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              const Icon(Icons.schedule_outlined, color: PatientColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.followUpTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PatientColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visit.followUp != null && visit.followUp!.trim().isNotEmpty) ...[
            Text(
              visit.followUp!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: PatientColors.navy,
                height: 1.35,
              ),
            ),
          ],
          if (visit.patientInstructions != null && visit.patientInstructions!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${strings.patientInstructionsTitle}: ${visit.patientInstructions!}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: PatientColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvestigationsCard(dynamic strings) {
    final requests = _investigations.isNotEmpty ? _investigations : _visit!.investigationRequests;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              const Icon(Icons.biotech_outlined, color: PatientColors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.requestedInvestigationsTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PatientColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (requests.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PatientColors.tealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${requests.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.tealDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No diagnostic investigations requested for this visit.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: PatientColors.textMuted,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildInvestigationItem(req, strings);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInvestigationItem(InvestigationRequest req, dynamic strings) {
    final isPending = req.isPendingUpload;
    final isUploaded = req.isUploaded;
    final isReviewed = req.isReviewed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PatientColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? const Color(0xFFFFCC80) : PatientColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.navy,
                      ),
                    ),
                    if (req.isRequired) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE9E7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REQUIRED',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD84315),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildInvestigationStatusBadge(strings, isPending, isUploaded, isReviewed),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToReports(req.requestId),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  strings.reportRequiredAction,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvestigationStatusBadge(
    dynamic strings,
    bool isPending,
    bool isUploaded,
    bool isReviewed,
  ) {
    if (isReviewed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          strings.reportReviewedStatus,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: PatientColors.tealDark,
          ),
        ),
      );
    }

    if (isUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          strings.reportSubmittedStatus,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        strings.pendingUploadStatus,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE65100),
        ),
      ),
    );
  }

  Widget _buildErrorView(dynamic strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientColors.borderSubtle, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: PatientColors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                strings.unableToLoadVisitHistory,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: PatientColors.navy,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loadVisitDetails,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    strings.retry,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PatientColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
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

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }
}
