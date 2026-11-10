import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/clinical_visit.dart';
import '../../doctor/models/report_document.dart';
import '../../models/patient.dart';
import '../localization/patient_localizations.dart';
import '../services/patient_official_visit_pdf_service.dart';
import '../services/patient_session_service.dart';
import '../theme/patient_colors.dart';

/// Full-screen or modal PDF viewer for official AAYUSATHI Visit Documentation PDF.
///
/// Features:
/// - Retrieves PDF via [PatientOfficialVisitPdfService] (Tier 1: Supabase, Tier 2: Firebase, Tier 3: On-demand synthesis).
/// - Sanitizes signed URL and diagnostics without credential leakage.
/// - Displays in-app [PdfPreview] with zoom and pagination.
/// - Handles loading state, network errors, and retry gracefully.
class PatientVisitReportPdfViewerDialog extends StatefulWidget {
  final ReportDocument? reportDoc;
  final ClinicalVisit? visit;
  final ClinicalCase? clinicalCase;
  final Patient? patient;
  final String? patientId;
  final String? caseId;
  final String? visitId;

  const PatientVisitReportPdfViewerDialog({
    super.key,
    this.reportDoc,
    this.visit,
    this.clinicalCase,
    this.patient,
    this.patientId,
    this.caseId,
    this.visitId,
  });

  static Future<void> show(
    BuildContext context, [
    ReportDocument? reportDoc,
    ClinicalVisit? visit,
    ClinicalCase? clinicalCase,
    Patient? patient,
    String? patientId,
    String? caseId,
    String? visitId,
  ]) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PatientVisitReportPdfViewerDialog(
        reportDoc: reportDoc,
        visit: visit,
        clinicalCase: clinicalCase,
        patient: patient,
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ),
    );
  }

  @override
  State<PatientVisitReportPdfViewerDialog> createState() =>
      _PatientVisitReportPdfViewerDialogState();
}

class _PatientVisitReportPdfViewerDialogState
    extends State<PatientVisitReportPdfViewerDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;
  String? _displayFileName;
  OfficialPdfSource? _retrievalSource;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final effectivePatientId = widget.patientId ??
        widget.reportDoc?.patientId ??
        widget.visit?.patientId ??
        widget.clinicalCase?.patientId ??
        widget.patient?.patientId ??
        PatientSessionService.instance.authenticatedPatientId;

    final effectiveCaseId = widget.caseId ??
        widget.reportDoc?.caseId ??
        widget.visit?.caseId ??
        widget.clinicalCase?.caseId;

    final effectiveVisitId = widget.visitId ??
        widget.reportDoc?.visitId ??
        widget.visit?.visitId;

    if (effectivePatientId == null ||
        effectivePatientId.trim().isEmpty ||
        effectiveCaseId == null ||
        effectiveCaseId.trim().isEmpty ||
        effectiveVisitId == null ||
        effectiveVisitId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Missing patient, case, or visit identification.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Optional check on signed URL for diagnostic without full URL logging
      if (widget.reportDoc != null && widget.reportDoc!.storagePath.isNotEmpty) {
        try {
          final storage = BackendProvider.instance.storageService;
          final signedUrl = await storage.getSignedUrl(
            widget.reportDoc!.storagePath,
            expiresIn: const Duration(minutes: 5),
          );
          debugPrint(
            '[PatientVisitReportPdfViewerDialog] Signed URL check: ${signedUrl != null ? "(present, sanitized)" : "(null)"}',
          );
        } catch (_) {}
      }

      // 3-Tier Multi-Recovery Retrieval
      final result = await PatientOfficialVisitPdfService.instance.retrieveOfficialVisitPdf(
        patientId: effectivePatientId,
        caseId: effectiveCaseId,
        visitId: effectiveVisitId,
        reportDoc: widget.reportDoc,
        visit: widget.visit,
        clinicalCase: widget.clinicalCase,
        patient: widget.patient,
      );

      if (result.isSuccess && result.pdfBytes != null && result.pdfBytes!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _pdfBytes = result.pdfBytes;
            _displayFileName = result.fileName ?? widget.reportDoc?.fileName ?? 'AAYUSATHI_Visit_Report.pdf';
            _retrievalSource = result.source;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          final strings = PatientLocalizations.of(context);
          setState(() {
            _errorMessage = result.errorMessage ?? strings.unableToLoadVisitPdf;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[PatientVisitReportPdfViewerDialog] Error loading PDF: $e');
      if (mounted) {
        final strings = PatientLocalizations.of(context);
        setState(() {
          _errorMessage = strings.unableToLoadVisitPdf;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final displayedName = _displayFileName ?? widget.reportDoc?.fileName ?? 'AAYUSATHI_Visit_Report.pdf';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 800,
        height: MediaQuery.of(context).size.height * 0.88,
        color: PatientColors.background,
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: PatientColors.surface,
                border: Border(
                  bottom: BorderSide(color: PatientColors.borderSubtle, width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PatientColors.tealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: PatientColors.tealDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.visitReportPdfViewerTitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PatientColors.navy,
                          ),
                        ),
                        Text(
                          _retrievalSource == OfficialPdfSource.onDemandSynthesis
                              ? '$displayedName • Approved Visit Synthesis'
                              : displayedName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: PatientColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: PatientColors.navy),
                    tooltip: strings.cancelAction,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: _buildContent(strings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(dynamic strings) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(PatientColors.teal),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              strings.loadingVisitReportPdf,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PatientColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PatientColors.navy,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  strings.retryButton,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes != null) {
      return PdfPreview(
        build: (format) => _pdfBytes!,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        maxPageWidth: 700,
        loadingWidget: Center(
          child: Text(
            strings.loadingVisitReportPdf,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: PatientColors.textMuted,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
