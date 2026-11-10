import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/supabase/supabase_config.dart';
import '../../repositories/report_repository.dart';
import '../models/report_document.dart';
import '../models/visit_report_data.dart';
import '../models/visit_report_pdf_result.dart';
import 'mock_pdf_output_service.dart';
import 'pdf_output_service.dart';
import 'storage_service.dart';

/// Service responsible for generating the official AAYUSATHI Case & Visit Documentation PDF.
///
/// Features:
/// - Embeds official AAYUSATHI logo asset (`assets/images/aayusathi_logo.png`).
/// - Standardized 9-section clinical documentation structure.
/// - Professional greenish-white medical styling.
/// - Multi-page flow with automatic table wrapping and page numbering.
/// - Gating validation ensuring unapproved drafts cannot produce final reports.
class VisitReportPdfService {
  static final VisitReportPdfService instance = VisitReportPdfService._();
  VisitReportPdfService._();
  factory VisitReportPdfService() => instance;

  // Official Theme Colors
  static const PdfColor colorTeal = PdfColor.fromInt(0xFF00897B);
  static const PdfColor colorNavy = PdfColor.fromInt(0xFF1A2C38);
  static const PdfColor colorLightTeal = PdfColor.fromInt(0xFFE6F7F5);
  static const PdfColor colorMutedGrey = PdfColor.fromInt(0xFF64748B);
  static const PdfColor colorBorder = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor colorBackgroundCard = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor colorStatusGreen = PdfColor.fromInt(0xFF15803D);

  /// Generates a standardized, safe filename for the Visit Report PDF.
  /// Format: `AAYUSATHI_Visit_Report_<patientId>_Visit_<visitNumber>.pdf`
  /// Sanitizes any path traversal or invalid characters.
  String generateSafeFileName({
    required String patientId,
    required int visitNumber,
  }) {
    var sanitized = patientId.trim();
    // Allow only alphanumeric, dash, and underscore; replace all others with underscore
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
    final cleanId = sanitized.isNotEmpty ? sanitized : 'Patient';
    return 'AAYUSATHI_Visit_Report_${cleanId}_Visit_$visitNumber.pdf';
  }

  /// Generates the PDF bytes and persists the document to local disk via [PdfOutputService].
  Future<VisitReportPdfResult> generateAndSaveVisitPdf(
    VisitReportData data, {
    Uint8List? logoBytes,
    PdfOutputService? outputService,
    String? customDirectory,
  }) async {
    if (!data.canGenerateReport) {
      return VisitReportPdfResult.failure(
        errorMessage:
            'Cannot generate report. Missing requirements: ${data.missingRequirements.join(", ")}',
        errorCode: 'GATING_REQUIREMENTS_NOT_MET',
      );
    }

    try {
      final pdfBytes = await generateVisitPdf(data, logoBytes: logoBytes);
      if (pdfBytes.isEmpty) {
        return VisitReportPdfResult.failure(
          errorMessage: 'Generated PDF bytes are empty.',
          errorCode: 'EMPTY_PDF_BYTES',
        );
      }

      final fileName = generateSafeFileName(
        patientId: data.patientId,
        visitNumber: data.visitNumber,
      );

      final service = outputService ?? PdfOutputService.instance;
      final saveResult = await service.saveGeneratedPdf(
        fileName: fileName,
        bytes: pdfBytes,
        customDirectory: customDirectory,
      );

      if (!saveResult.isSuccess || saveResult.savedPath == null) {
        return VisitReportPdfResult.failure(
          errorMessage:
              saveResult.errorMessage ?? 'Failed to write PDF file to disk.',
          errorCode: 'FILE_WRITE_FAILED',
          fileName: fileName,
        );
      }

      return VisitReportPdfResult.success(
        filePath: saveResult.savedPath!,
        fileName: saveResult.fileName ?? fileName,
        fileSizeBytes: saveResult.fileSizeBytes ?? pdfBytes.length,
        pdfBytes: pdfBytes,
        isDevelopmentMock: service is MockPdfOutputService,
      );
    } catch (e) {
      return VisitReportPdfResult.failure(
        errorMessage: 'An unexpected error occurred while generating PDF: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Uploads generated Visit Report PDF to Firebase Cloud Storage and records metadata in Firestore.
  ///
  /// CRITICAL RESILIENCE MANDATE (D17):
  /// This method is called in addition to local PDF persistence.
  /// If cloud upload fails or encounters network errors, it MUST NOT affect or invalidate the local PDF.
  Future<VisitReportPdfResult> uploadVisitReportPdfToCloud({
    required VisitReportPdfResult localResult,
    required VisitReportData data,
    StorageService? storageService,
    ReportRepository? reportRepository,
  }) async {
    if (!localResult.isSuccess || localResult.pdfBytes == null) {
      return localResult;
    }

    if (!data.isSummaryApproved) {
      return localResult.copyWith(
        isCloudUploaded: false,
        cloudUploadError: 'Visit summary must be approved by the doctor before uploading.',
      );
    }

    final bytes = localResult.pdfBytes!;
    if (bytes.isEmpty) {
      return localResult.copyWith(
        isCloudUploaded: false,
        cloudUploadError: 'PDF bytes are empty.',
      );
    }
    if (bytes.length < 4 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46) {
      return localResult.copyWith(
        isCloudUploaded: false,
        cloudUploadError: 'PDF bytes do not contain a valid %PDF header.',
      );
    }
    if (bytes.length > StorageService.maxFileSizeBytes) {
      return localResult.copyWith(
        isCloudUploaded: false,
        cloudUploadError: 'PDF size exceeds maximum 15 MB limit.',
      );
    }

    final storage = storageService ?? BackendProvider.instance.storageService;
    final repRepo = reportRepository ?? BackendProvider.instance.reportRepository;

    try {
      final fileName = localResult.fileName ??
          generateSafeFileName(
            patientId: data.patientId,
            visitNumber: data.visitNumber,
          );

      // Use actual visitId from data if present, otherwise fallback
      final visitId = data.visitId.isNotEmpty
          ? data.visitId
          : 'VIS-${data.caseId}-${data.visitNumber}';
      final doctorId = data.approvedDoctorId ?? 'DOC-101';

      // 1. Upload PDF binary to Supabase Cloud Storage (Private Bucket)
      final cloudPath = await storage.uploadVisitPdf(
        patientId: data.patientId,
        caseId: data.caseId,
        visitId: visitId,
        fileName: fileName,
        bytes: bytes,
      );

      // 2. Verify physical cloud existence in private bucket before registering Firestore metadata (Mandate 19)
      final exists = await storage.fileExists(cloudPath);
      if (!exists) {
        throw BackendException(
          code: BackendException.unavailable,
          message: 'Cloud upload verification failed: Object was not confirmed in storage at $cloudPath',
        );
      }

      // 3. Register ReportDocument metadata in Firestore only upon confirmed upload
      final reportDoc = ReportDocument(
        reportId: 'OFFICIAL-REPORT-$visitId',
        patientId: data.patientId,
        caseId: data.caseId,
        visitId: visitId,
        investigationId: 'OFFICIAL_VISIT_REPORT',
        fileName: fileName,
        contentType: 'application/pdf',
        fileSizeBytes: localResult.fileSizeBytes ?? bytes.length,
        storagePath: cloudPath,
        storageProvider: 'supabase',
        storageBucket: SupabaseConfig.bucketName,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: doctorId,
        reviewStatus: ReportReviewStatus.reviewed,
        reviewedAt: DateTime.now(),
        reviewedByDoctorId: doctorId,
        notes: 'Official Physician Clinical Documentation PDF',
      );

      await repRepo.saveReportDocument(reportDoc);

      debugPrint('[VisitReportPdfService] Dual-path PDF success: Local saved at ${localResult.filePath}, Cloud uploaded at $cloudPath');

      return localResult.copyWith(
        cloudStoragePath: cloudPath,
        isCloudUploaded: true,
        cloudUploadError: null,
      );
    } catch (e) {
      debugPrint('[VisitReportPdfService] Cloud upload failed (local PDF preserved): $e');
      final err = e is BackendException ? e.message : e.toString();
      return localResult.copyWith(
        isCloudUploaded: false,
        cloudUploadError: err,
      );
    }
  }

  /// Generates the official AAYUSATHI Visit Documentation PDF bytes.
  ///
  /// If [logoBytes] is null, attempts to load `assets/images/aayusathi_logo.png` from rootBundle.
  Future<Uint8List> generateVisitPdf(
    VisitReportData data, {
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document(
      title: 'AAYUSATHI_Visit_${data.patientId}_${data.visitNumber}',
      author: data.doctorName,
      creator: 'AAYUSATHI Clinical Workstation',
    );

    // Load Logo image
    pw.MemoryImage? logoImage;
    if (logoBytes != null) {
      logoImage = pw.MemoryImage(logoBytes);
    } else {
      try {
        final byteData = await rootBundle.load('assets/images/aayusathi_logo.png');
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (_) {
        // Continue gracefully if asset bundle is unavailable in unit test runner
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => _buildPdfHeader(logoImage),
        footer: (pw.Context context) => _buildPdfFooter(context),
        build: (pw.Context context) => [
          _buildDocumentTitleBadge(),
          pw.SizedBox(height: 12),

          // SECTION 1: VISIT IDENTIFICATION
          _buildSectionHeader('SECTION 1 - VISIT IDENTIFICATION'),
          _buildGridCard([
            _buildField('Patient ID', data.patientId),
            _buildField('Case ID', data.caseId),
            _buildField('Visit', 'Visit ${data.visitNumber}'),
            _buildField('Status', data.visitStatus),
            _buildField('Department', data.department),
            _buildField('Date / Time', _formatDateTime(data.dateTime)),
          ]),
          pw.SizedBox(height: 12),

          // SECTION 2: PATIENT INFORMATION
          _buildSectionHeader('SECTION 2 - PATIENT INFORMATION'),
          _buildGridCard([
            _buildField('Name', data.patientName),
            _buildField('Age', '${data.age} Yrs'),
            _buildField('Gender', data.gender),
            _buildField('Blood Group', data.bloodGroup),
            _buildField('Patient Type', data.patientType),
            _buildField('Attending Doctor', '${data.doctorName} (${data.doctorQualification})'),
          ]),
          pw.SizedBox(height: 12),

          // SECTION 3: VITALS AT CONSULTATION
          _buildSectionHeader('SECTION 3 - VITALS AT CONSULTATION'),
          _buildGridCard([
            _buildField('SpO2', data.spo2 ?? 'Not Recorded'),
            _buildField('Heart Rate', data.heartRate ?? 'Not Recorded'),
            _buildField('Temperature', data.temperature ?? 'Not Recorded'),
          ]),
          pw.SizedBox(height: 12),

          // SECTION 4: CASE INFORMATION
          _buildSectionHeader('SECTION 4 - CASE INFORMATION'),
          _buildGridCard([
            _buildField('Case Title', data.caseTitle),
            _buildField('Case Type', data.caseType),
            _buildField('Case Status', data.caseStatus),
            _buildField('Previous Relevant History',
                data.previousRelevantHistory?.isNotEmpty == true
                    ? data.previousRelevantHistory!
                    : 'None reported'),
          ]),
          pw.SizedBox(height: 12),

          // SECTION 5: STRUCTURED CONSULTATION
          _buildSectionHeader('SECTION 5 - STRUCTURED CONSULTATION'),
          _buildCard([
            _buildBlockField('Chief Complaint', data.chiefComplaint),
            _buildBlockField('Onset / Duration', data.onsetDuration),
            _buildBlockField('Associated Symptoms', data.associatedSymptoms),
            _buildBlockField('Medical History', data.medicalHistory),
            _buildBlockField('Current Medication', data.currentMedication),
            _buildBlockField('Clinical Observations', data.clinicalObservations),
            _buildBlockField('Assessment', data.assessment),
            _buildBlockField('Plan', data.plan),
          ]),
          pw.SizedBox(height: 12),

          // Prescriptions Table (if present)
          if (data.prescriptions.isNotEmpty) ...[
            _buildSectionHeader('MEDICATIONS / PRESCRIPTION (RX)'),
            _buildPrescriptionsTable(data),
            pw.SizedBox(height: 12),
          ],

          // SECTION 6: DOCTOR-APPROVED VISIT SUMMARY
          _buildSectionHeader('SECTION 6 - DOCTOR-APPROVED VISIT SUMMARY'),
          _buildSummaryCard(data),
          pw.SizedBox(height: 12),

          // SECTION 7: REPORTS / INVESTIGATIONS REQUESTED
          _buildSectionHeader('SECTION 7 - REPORTS / INVESTIGATIONS REQUESTED'),
          _buildInvestigationsTable(data),
          pw.SizedBox(height: 12),

          // SECTION 8: PLAN / FOLLOW-UP
          _buildSectionHeader('SECTION 8 - PLAN / FOLLOW-UP'),
          _buildGridCard([
            _buildField('Follow-up Advice',
                data.followUp?.isNotEmpty == true ? data.followUp! : 'As needed / Routine review'),
            _buildField('Patient Instructions',
                data.patientInstructions?.isNotEmpty == true
                    ? data.patientInstructions!
                    : 'Take medications as prescribed. Return if symptoms worsen.'),
          ]),
          pw.SizedBox(height: 12),

          // SECTION 9: VISIT COMPLETION
          _buildSectionHeader('SECTION 9 - VISIT COMPLETION'),
          _buildCompletionCard(data),
        ],
      ),
    );

    return pdf.save();
  }

  // --- WIDGET BUILDERS ---

  pw.Widget _buildPdfHeader(pw.MemoryImage? logoImage) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: colorTeal, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 48,
                  height: 48,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(logoImage),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AAYUSATHI',
                    style: pw.TextStyle(
                      color: colorTeal,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.Text(
                    'LIVE BETTER, TOGETHER',
                    style: pw.TextStyle(
                      color: colorNavy,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'OPD CLINICAL CONSULTATION',
                style: pw.TextStyle(
                  color: colorNavy,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Electronic Health Record',
                style: const pw.TextStyle(
                  color: colorMutedGrey,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: colorBorder, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'AAYUSATHI OPD System | Confidential Medical Record | Case Remains Ongoing',
            style: const pw.TextStyle(
              color: colorMutedGrey,
              fontSize: 7,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              color: colorNavy,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDocumentTitleBadge() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: colorLightTeal,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: colorTeal, width: 1),
      ),
      child: pw.Center(
        child: pw.Text(
          'CASE & VISIT DOCUMENTATION',
          style: pw.TextStyle(
            color: colorTeal,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4, top: 4),
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: const pw.BoxDecoration(
        color: colorBackgroundCard,
        border: pw.Border(left: pw.BorderSide(color: colorTeal, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: colorNavy,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _buildGridCard(List<pw.Widget> fields) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: colorBorder, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 6,
        children: fields,
      ),
    );
  }

  pw.Widget _buildCard(List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: colorBorder, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  pw.Widget _buildField(String label, String value) {
    return pw.Container(
      width: 230,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                color: colorMutedGrey,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: colorNavy,
                fontSize: 8,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBlockField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                color: colorMutedGrey,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isNotEmpty ? value : '-',
              style: pw.TextStyle(
                color: colorNavy,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(VisitReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: colorLightTeal,
        border: pw.Border.all(color: colorTeal, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Clinical Summary',
                style: pw.TextStyle(
                  color: colorTeal,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const pw.BoxDecoration(
                  color: colorStatusGreen,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Text(
                  data.summaryStatus,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            data.summary,
            style: pw.TextStyle(
              color: colorNavy,
              fontSize: 8.5,
              lineSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPrescriptionsTable(VisitReportData data) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: colorBorder, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: colorBackgroundCard),
      headerHeight: 20,
      cellHeight: 18,
      headerStyle: pw.TextStyle(color: colorNavy, fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(color: colorNavy, fontSize: 7.5),
      headers: ['Medicine Name', 'Duration', 'Frequency', 'Instructions / Remarks'],
      data: data.prescriptions
          .map((p) => [
                p.medicineName,
                p.duration,
                p.timesPerDay,
                p.remarks.isNotEmpty ? p.remarks : '-',
              ])
          .toList(),
    );
  }

  pw.Widget _buildInvestigationsTable(VisitReportData data) {
    if (data.investigations.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: colorBorder, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          'No diagnostic investigations or laboratory reports requested for this visit.',
          style: const pw.TextStyle(color: colorMutedGrey, fontSize: 8),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: colorBorder, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: colorBackgroundCard),
      headerHeight: 20,
      cellHeight: 18,
      headerStyle: pw.TextStyle(color: colorNavy, fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(color: colorNavy, fontSize: 7.5),
      headers: ['Report / Investigation', 'Category', 'Priority', 'Status'],
      data: data.investigations
          .map((inv) => [
                inv.name,
                inv.category.label,
                inv.priority.label,
                inv.status.label,
              ])
          .toList(),
    );
  }

  pw.Widget _buildCompletionCard(VisitReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: colorBorder, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Visit: ${data.completionVisitNumber} | Case: ${data.completionCaseId}',
                style: pw.TextStyle(
                  color: colorNavy,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Consulting Doctor: ${data.consultingDoctor}',
                style: const pw.TextStyle(color: colorNavy, fontSize: 8),
              ),
              pw.Text(
                'Qualification: ${data.consultingDoctorQualification}',
                style: const pw.TextStyle(color: colorMutedGrey, fontSize: 7.5),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Summary Approval:',
                style: const pw.TextStyle(color: colorMutedGrey, fontSize: 7.5),
              ),
              pw.Text(
                data.summaryApprovalNotice,
                style: pw.TextStyle(
                  color: data.isSummaryApproved ? colorStatusGreen : colorNavy,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
