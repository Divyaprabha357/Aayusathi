import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/investigation_request.dart';
import '../models/report_document.dart';
import '../services/doctor_ai_report_summarization_service.dart';
import '../services/doctor_report_authorization_service.dart';
import '../services/supabase_storage_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Secure in-app viewer for patient-uploaded diagnostic reports and official visit documents.
///
/// Features:
/// 1. Enforces doctor authorization via [DoctorReportAuthorizationService].
/// 2. Generates time-limited (5-minute) signed URLs from private Supabase bucket `aayusathi-reports`.
/// 3. In-memory binary retrieval via [StorageService.getFileBytes] — zero uncontrolled permanent disk leakage.
/// 4. Handles PDF (via [PdfPreview]) and Images (via [InteractiveViewer]).
/// 5. Displays sanitized clinical metadata without leaking internal UUIDs, Firestore paths, or credentials.
/// 6. Integrated extension point for [DoctorAiReportSummaryDialog].
class DoctorReportViewerDialog extends StatefulWidget {
  final ReportDocument reportDoc;
  final InvestigationRequest? investigation;
  final KioskLocale locale;
  final String? currentPatientId;
  final String? currentCaseId;
  final String? currentVisitId;

  const DoctorReportViewerDialog({
    super.key,
    required this.reportDoc,
    this.investigation,
    this.locale = KioskLocale.english,
    this.currentPatientId,
    this.currentCaseId,
    this.currentVisitId,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportDocument reportDoc,
    InvestigationRequest? investigation,
    KioskLocale locale = KioskLocale.english,
    String? currentPatientId,
    String? currentCaseId,
    String? currentVisitId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DoctorReportViewerDialog(
        reportDoc: reportDoc,
        investigation: investigation,
        locale: locale,
        currentPatientId: currentPatientId,
        currentCaseId: currentCaseId,
        currentVisitId: currentVisitId,
      ),
    );
  }

  @override
  State<DoctorReportViewerDialog> createState() =>
      _DoctorReportViewerDialogState();
}

class _DoctorReportViewerDialogState extends State<DoctorReportViewerDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _fileBytes;
  bool _isUnauthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUnauthorized = false;
    });

    // 1. Authoritative Clinical Access Verification
    final authResult =
        await DoctorReportAuthorizationService.instance.verifyReportAccess(
      report: widget.reportDoc,
      expectedPatientId: widget.currentPatientId,
      expectedCaseId: widget.currentCaseId,
      expectedVisitId: widget.currentVisitId,
    );

    if (!authResult.isAuthorized) {
      if (mounted) {
        setState(() {
          _isUnauthorized = true;
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Storage Retrieval (separated from authorization failure)
    try {
      final storage = BackendProvider.instance.storageService;
      final rawPath = widget.reportDoc.storagePath.trim().isNotEmpty
          ? widget.reportDoc.storagePath
          : 'patients/${widget.reportDoc.patientId}/cases/${widget.reportDoc.caseId}/visits/${widget.reportDoc.visitId}/reports/${widget.reportDoc.fileName}';
      final normalizedPath =
          SupabaseStorageService.normalizeStoragePath(rawPath);
      final resolvedBucket = widget.reportDoc.storageBucket.trim().isNotEmpty
          ? widget.reportDoc.storageBucket
          : SupabaseConfig.bucketName;

      debugPrint('[DoctorReportViewerDialog] Storage Diagnostics:');
      debugPrint('  - Resolved Bucket: $resolvedBucket (Private: ${SupabaseConfig.isPrivateBucket})');
      debugPrint('  - Normalized Storage Path: $normalizedPath');

      // Check whether object exists in private storage bucket
      final objectExists = await storage.fileExists(normalizedPath);
      debugPrint('  - Object Exists in Private Bucket: $objectExists');

      // Request short-lived 5-minute signed URL from private bucket (sanitized logging)
      final signedUrl = await storage.getSignedUrl(
        normalizedPath,
        expiresIn: const Duration(minutes: 5),
      );
      final hasSignedUrl = signedUrl != null && signedUrl.isNotEmpty;
      debugPrint(
        '  - Signed URL Generation: ${hasSignedUrl ? "SUCCESS (valid, sanitized)" : "FAILED (null/empty)"}',
      );

      // Fetch in-memory bytes for secure viewer display
      final bytes = await storage.getFileBytes(normalizedPath);

      if (bytes != null && bytes.isNotEmpty) {
        final isValidSignature = _validateFileContent(bytes, widget.reportDoc);
        final detectedHeader = _detectFileHeader(bytes);
        debugPrint('  - Downloaded Bytes: ${bytes.length} bytes');
        debugPrint('  - File Header Signature: $detectedHeader (Valid: $isValidSignature)');

        // Validate file bytes to prevent rendering HTML error responses or corrupt files
        if (!isValidSignature) {
          debugPrint(
            '[DoctorReportViewerDialog] Invalid or corrupted document payload rejected (Header: $detectedHeader).',
          );
          DoctorReportAuthorizationService.logDiagnostic(
            isAuthorized: true,
            outcome: DoctorReportAuthOutcome.authorizedStorageDownloadFailed,
            doctorId: authResult.doctorId,
            patientMatched: true,
            caseMatched: true,
            visitMatched: true,
            extra: 'CORRUPTED_DOCUMENT_PAYLOAD ($detectedHeader)',
          );
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Downloaded file content is invalid or corrupted. Please verify connection and retry.';
              _isLoading = false;
            });
          }
          return;
        }

        DoctorReportAuthorizationService.logDiagnostic(
          isAuthorized: true,
          outcome: DoctorReportAuthOutcome.reportOpenSuccess,
          doctorId: authResult.doctorId,
          patientMatched: true,
          caseMatched: true,
          visitMatched: true,
          extra: 'REPORT_OPENED_SUCCESSFULLY (${bytes.length} bytes, $detectedHeader)',
        );

        if (mounted) {
          setState(() {
            _fileBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        final failureStage = hasSignedUrl
            ? 'AFTER_SIGNED_URL_GENERATION'
            : 'BEFORE_SIGNED_URL_GENERATION';
        final existenceDetail = objectExists
            ? 'OBJECT_EXISTS_BUT_DOWNLOAD_RETURNED_NULL'
            : 'OBJECT_NOT_FOUND_IN_STORAGE';
        debugPrint(
            '[DoctorReportViewerDialog] Download failed. Stage: $failureStage, Detail: $existenceDetail');

        DoctorReportAuthorizationService.logDiagnostic(
          isAuthorized: true,
          outcome: DoctorReportAuthOutcome.authorizedStorageDownloadFailed,
          doctorId: authResult.doctorId,
          patientMatched: true,
          caseMatched: true,
          visitMatched: true,
          extra: '$failureStage | $existenceDetail',
        );
        if (mounted) {
          setState(() {
            _errorMessage =
                'Could not load document from secure private storage. Please verify connection and retry.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[DoctorReportViewerDialog] Error loading report: $e');
      DoctorReportAuthorizationService.logDiagnostic(
        isAuthorized: true,
        outcome: DoctorReportAuthOutcome.authorizedStorageDownloadFailed,
        doctorId: authResult.doctorId,
        patientMatched: true,
        caseMatched: true,
        visitMatched: true,
        extra: 'STORAGE_RETRIEVAL_EXCEPTION: $e',
      );
      if (mounted) {
        setState(() {
          _errorMessage =
              'An unexpected error occurred while loading this report document: $e';
          _isLoading = false;
        });
      }
    }
  }

  bool _validateFileContent(Uint8List bytes, ReportDocument doc) {
    if (bytes.isEmpty) return false;

    // Check for HTTP/API HTML/JSON error payloads
    if (bytes.length >= 6) {
      final prefix = String.fromCharCodes(bytes.take(30)).toLowerCase();
      if (prefix.contains('<html') ||
          prefix.contains('<!doctype') ||
          prefix.contains('{"error"') ||
          prefix.contains('{"statuscode"')) {
        return false;
      }
    }

    final lower = doc.fileName.toLowerCase();
    if (doc.isPdf || lower.endsWith('.pdf')) {
      if (bytes.length < 4) return false;
      return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46; // %PDF
    }

    if (lower.endsWith('.png')) {
      if (bytes.length < 4) return false;
      return bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
    }

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      if (bytes.length < 3) return false;
      return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    }

    return true;
  }

  String _detectFileHeader(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'PDF (%PDF)';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'JPEG (0xFFD8FF)';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'PNG (0x89PNG)';
    }
    if (bytes.length >= 6) {
      final prefix = String.fromCharCodes(bytes.take(30)).toLowerCase();
      if (prefix.contains('<html') || prefix.contains('<!doctype')) {
        return 'HTML_DOCUMENT';
      }
      if (prefix.contains('{"error"') || prefix.contains('{"statuscode"')) {
        return 'JSON_ERROR_RESPONSE';
      }
    }
    return 'UNKNOWN_SIGNATURE';
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final doc = widget.reportDoc;
    final invName = widget.investigation?.name ??
        (doc.investigationId.isNotEmpty ? doc.investigationId : 'Investigation Report');
    final formattedDate =
        '${doc.uploadedAt.day.toString().padLeft(2, '0')}/${doc.uploadedAt.month.toString().padLeft(2, '0')}/${doc.uploadedAt.year} '
        '${doc.uploadedAt.hour.toString().padLeft(2, '0')}:${doc.uploadedAt.minute.toString().padLeft(2, '0')}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space20,
                vertical: DoctorTheme.space12,
              ),
              decoration: const BoxDecoration(
                color: DoctorColors.brandNavy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(DoctorTheme.radius16),
                  topRight: Radius.circular(DoctorTheme.radius16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DoctorColors.brandTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    ),
                    child: Icon(
                      doc.isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: DoctorColors.brandTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.fileName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          invName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // AI Summarize Report Button
                  DoctorSecondaryButton(
                    label: strings.aiSummarizeReportButton,
                    icon: Icons.auto_awesome_rounded,
                    onPressed: (_fileBytes == null || _fileBytes!.isEmpty)
                        ? null
                        : () {
                            DoctorAiReportSummaryDialog.show(
                              context,
                              doc,
                              currentPatientId: widget.currentPatientId ?? doc.patientId,
                              currentCaseId: widget.currentCaseId ?? doc.caseId,
                              currentVisitId: widget.currentVisitId ?? doc.visitId,
                              preloadedFileBytes: _fileBytes,
                            );
                          },
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Sanitized Clinical Metadata Strip (Zero internal IDs / secrets leaked)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space20,
                vertical: 10,
              ),
              color: DoctorColors.background,
              child: Row(
                children: [
                  _buildMetaBadge(
                    label: 'STATUS',
                    value: doc.reviewStatus.name.toUpperCase(),
                    isHighlight: doc.isReviewed,
                  ),
                  const SizedBox(width: 12),
                  _buildMetaBadge(
                    label: 'UPLOADED',
                    value: formattedDate,
                  ),
                  const SizedBox(width: 12),
                  _buildMetaBadge(
                    label: 'SIZE',
                    value: '${(doc.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                  ),
                  if (doc.notes != null && doc.notes!.trim().isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: ${doc.notes}',
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: DoctorColors.border),

            // Viewer Content Area
            Expanded(
              child: _buildViewerContent(strings),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space20,
                vertical: DoctorTheme.space12,
              ),
              decoration: const BoxDecoration(
                color: DoctorColors.background,
                border: Border(top: BorderSide(color: DoctorColors.border)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DoctorTheme.radius16),
                  bottomRight: Radius.circular(DoctorTheme.radius16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: DoctorColors.brandTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Private Secure Document • In-Memory Stream',
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  DoctorPrimaryButton(
                    label: strings.close,
                    onPressed: () => Navigator.of(context).pop(),
                    height: 36,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBadge({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? DoctorColors.statusAvailable.withValues(alpha: 0.12)
            : DoctorColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isHighlight
              ? DoctorColors.statusAvailable.withValues(alpha: 0.4)
              : DoctorColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: DoctorColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isHighlight
                  ? DoctorColors.statusAvailable
                  : DoctorColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerContent(dynamic strings) {
    if (_isUnauthorized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: DoctorColors.statusCritical,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                strings.unauthorizedReportAccess,
                textAlign: TextAlign.center,
                style: DoctorTheme.headline2.copyWith(
                  color: DoctorColors.brandNavy,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading secure report document...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DoctorColors.textSecondary,
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
                color: DoctorColors.brandOrange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: DoctorTheme.body.copyWith(color: DoctorColors.brandNavy),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _checkAuthAndLoad,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorColors.brandTeal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_fileBytes != null) {
      if (widget.reportDoc.isPdf) {
        return PdfPreview(
          build: (format) => _fileBytes!,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          maxPageWidth: 800,
          loadingWidget: const Center(
            child: Text(
              'Rendering PDF...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: DoctorColors.textMuted,
              ),
            ),
          ),
        );
      } else {
        // Image Viewer (JPG, JPEG, PNG)
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.memory(
                _fileBytes!,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => Center(
                  child: Text(
                    'Failed to display image format.',
                    style: DoctorTheme.bodyMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}
