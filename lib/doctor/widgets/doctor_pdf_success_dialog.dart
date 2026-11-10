import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/visit_report_data.dart';
import '../models/visit_report_pdf_result.dart';
import '../services/pdf_output_service.dart';
import '../services/visit_report_pdf_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog presented to the Doctor immediately after a Visit Report PDF is successfully
/// generated and persisted to disk.
///
/// Provides direct actions to:
/// - [ OPEN PDF ]: Launches the generated file in the default Windows/System PDF application.
/// - [ SAVE AS ]: Saves a copy of the PDF to the user's chosen folder or Desktop.
/// - [ CLOSE ]: Dismisses the dialog.
class DoctorPdfSuccessDialog extends StatefulWidget {
  final VisitReportPdfResult result;
  final VisitReportData? reportData;
  final Future<VisitReportPdfResult> Function()? onRetryUpload;
  final KioskLocale locale;
  final PdfOutputService? pdfOutputService;

  const DoctorPdfSuccessDialog({
    super.key,
    required this.result,
    this.reportData,
    this.onRetryUpload,
    this.locale = KioskLocale.english,
    this.pdfOutputService,
  });

  @override
  State<DoctorPdfSuccessDialog> createState() => _DoctorPdfSuccessDialogState();
}

class _DoctorPdfSuccessDialogState extends State<DoctorPdfSuccessDialog> {
  late VisitReportPdfResult _currentResult;
  bool _isOpening = false;
  bool _isSavingAs = false;
  bool _isRetryingUpload = false;
  String? _statusBannerMessage;
  bool _isStatusError = false;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
  }

  PdfOutputService get _outputService =>
      widget.pdfOutputService ?? PdfOutputService.instance;

  Future<void> _handleRetryUpload() async {
    setState(() {
      _isRetryingUpload = true;
      _statusBannerMessage = null;
    });

    try {
      VisitReportPdfResult updated;
      if (widget.onRetryUpload != null) {
        updated = await widget.onRetryUpload!();
      } else if (widget.reportData != null) {
        updated = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: _currentResult,
          data: widget.reportData!,
        );
      } else {
        throw Exception('Report data is required for retry.');
      }

      if (mounted) {
        setState(() {
          _isRetryingUpload = false;
          _currentResult = updated;
          if (updated.isCloudUploaded) {
            _isStatusError = false;
            _statusBannerMessage = 'Cloud copy uploaded securely.';
          } else {
            _isStatusError = true;
            _statusBannerMessage = updated.cloudUploadError ?? 'Cloud upload failed. Your local PDF is still available.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRetryingUpload = false;
          _isStatusError = true;
          _statusBannerMessage = 'Upload retry failed: $e';
        });
      }
    }
  }

  Future<void> _handleOpenPdf() async {
    final filePath = _currentResult.filePath;
    if (filePath == null) return;

    final strings = DoctorLocalizations.forLocale(widget.locale);

    setState(() {
      _isOpening = true;
      _statusBannerMessage = null;
    });

    try {
      final openResult = await _outputService.openPdf(filePath);
      if (mounted) {
        setState(() {
          _isOpening = false;
          if (!openResult.isSuccess) {
            _isStatusError = true;
            _statusBannerMessage =
                openResult.errorMessage ?? strings.pdfOpenError;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOpening = false;
          _isStatusError = true;
          _statusBannerMessage = '${strings.pdfOpenError} ($e)';
        });
      }
    }
  }

  Future<void> _handleSaveAs() async {
    final bytes = _currentResult.pdfBytes;
    final defaultFileName = _currentResult.fileName ?? 'AAYUSATHI_Visit_Report.pdf';
    final strings = DoctorLocalizations.forLocale(widget.locale);

    setState(() {
      _isSavingAs = true;
      _statusBannerMessage = null;
    });

    try {
      final saveResult = await _outputService.savePdfAs(
        defaultFileName: defaultFileName,
        bytes: bytes ?? Uint8List(0),
        sourceFilePath: _currentResult.filePath,
      );

      if (mounted) {
        setState(() {
          _isSavingAs = false;
          if (saveResult.isSuccess) {
            _isStatusError = false;
            _statusBannerMessage =
                '${strings.pdfSaveAsSuccess}\n${saveResult.savedPath}';
          } else if (saveResult.isCancelled) {
            _isStatusError = false;
            _statusBannerMessage = strings.pdfSaveAsCancelled;
          } else {
            _isStatusError = true;
            _statusBannerMessage =
                saveResult.errorMessage ?? 'Failed to save copy.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingAs = false;
          _isStatusError = true;
          _statusBannerMessage = 'Error during Save-As: $e';
        });
      }
    }
  }

  void _copyPathToClipboard() {
    if (_currentResult.filePath != null) {
      Clipboard.setData(ClipboardData(text: _currentResult.filePath!));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path copied to clipboard.'),
          backgroundColor: DoctorColors.brandNavy,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final fileName = widget.result.fileName ?? 'AAYUSATHI_Visit_Report.pdf';
    final filePath = widget.result.filePath ?? 'Unknown path';
    final fileSize = widget.result.fileSizeKb;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 580,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(DoctorTheme.space24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Green Checkmark Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DoctorColors.statusNormal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: DoctorColors.statusNormal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.pdfCreatedSuccessTitle,
                          style: DoctorTheme.headline2.copyWith(
                            color: DoctorColors.brandNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Official AAYUSATHI clinical document is ready.',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DoctorTheme.space16),
              const Divider(color: DoctorColors.border),
              const SizedBox(height: DoctorTheme.space12),

              // File Metadata Card
              Container(
                padding: const EdgeInsets.all(DoctorTheme.space16),
                decoration: BoxDecoration(
                  color: DoctorColors.background,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(color: DoctorColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: DoctorColors.statusCritical,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fileName,
                            style: DoctorTheme.bodyBold.copyWith(
                              color: DoctorColors.brandNavy,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: DoctorColors.brandTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            fileSize,
                            style: const TextStyle(
                              color: DoctorColors.brandTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.pdfLocationLabel}: ',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            filePath,
                            style: DoctorTheme.caption.copyWith(
                              color: DoctorColors.brandNavy,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _copyPathToClipboard,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: DoctorColors.brandTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentResult.isCloudUploaded) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.cloud_done_rounded,
                            size: 14,
                            color: DoctorColors.brandTeal,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cloud Copy Synchronized',
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.brandTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: DoctorColors.statusCritical.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                          border: Border.all(
                            color: DoctorColors.statusCritical.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 16,
                              color: DoctorColors.statusCritical,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cloud upload failed. Your local PDF is still available.',
                                    style: DoctorTheme.caption.copyWith(
                                      color: DoctorColors.statusCritical,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cloud upload pending / offline (Local PDF ready)',
                                    style: DoctorTheme.caption.copyWith(
                                      color: DoctorColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (_currentResult.cloudUploadError != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentResult.cloudUploadError!,
                                      style: DoctorTheme.caption.copyWith(
                                        color: DoctorColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.reportData != null || widget.onRetryUpload != null) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 28,
                                child: OutlinedButton.icon(
                                  onPressed: _isRetryingUpload ? null : _handleRetryUpload,
                                  icon: _isRetryingUpload
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: DoctorColors.brandTeal,
                                          ),
                                        )
                                      : const Icon(Icons.refresh_rounded, size: 14),
                                  label: const Text(
                                    'Retry Upload',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: DoctorColors.brandTeal,
                                    side: const BorderSide(color: DoctorColors.brandTeal),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status / Error Banner (if triggered)
              if (_statusBannerMessage != null) ...[
                const SizedBox(height: DoctorTheme.space12),
                Container(
                  padding: const EdgeInsets.all(DoctorTheme.space10),
                  decoration: BoxDecoration(
                    color: _isStatusError
                        ? DoctorColors.statusCritical.withValues(alpha: 0.08)
                        : DoctorColors.brandTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                    border: Border.all(
                      color: _isStatusError
                          ? DoctorColors.statusCritical.withValues(alpha: 0.3)
                          : DoctorColors.brandTeal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isStatusError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: _isStatusError
                            ? DoctorColors.statusCritical
                            : DoctorColors.brandTeal,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusBannerMessage!,
                          style: TextStyle(
                            color: _isStatusError
                                ? DoctorColors.statusCritical
                                : DoctorColors.brandNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: DoctorTheme.space20),

              // Action Buttons: [ OPEN PDF ], [ SAVE AS ], [ CLOSE ]
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  DoctorOutlineButton(
                    label: strings.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: _isSavingAs
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DoctorColors.brandNavy,
                                ),
                              )
                            : const Icon(Icons.save_as_rounded, size: 16),
                        label: Text(strings.saveAsButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoctorColors.surface,
                          foregroundColor: DoctorColors.brandNavy,
                          elevation: 1,
                          side: const BorderSide(color: DoctorColors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DoctorTheme.radius8),
                          ),
                        ),
                        onPressed: _isSavingAs ? null : _handleSaveAs,
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: _isOpening
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(strings.openPdfButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoctorColors.brandTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DoctorTheme.radius8),
                          ),
                        ),
                        onPressed: _isOpening ? null : _handleOpenPdf,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
