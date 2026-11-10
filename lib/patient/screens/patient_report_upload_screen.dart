import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../doctor/models/investigation_request.dart';
import '../controllers/patient_report_upload_controller.dart';
import '../localization/patient_localizations.dart';
import '../localization/patient_strings.dart';
import '../theme/patient_colors.dart';
import '../widgets/patient_top_bar.dart';

/// Senior-accessible Medical Report Photo Upload Screen (`/patient/reports/:reportId/upload`).
class PatientReportUploadScreen extends StatefulWidget {
  final InvestigationRequest investigation;
  final String? caseTitle;
  final DateTime? visitDate;
  final PatientReportUploadController? controller;

  const PatientReportUploadScreen({
    super.key,
    required this.investigation,
    this.caseTitle,
    this.visitDate,
    this.controller,
  });

  @override
  State<PatientReportUploadScreen> createState() => _PatientReportUploadScreenState();
}

class _PatientReportUploadScreenState extends State<PatientReportUploadScreen> {
  late final PatientReportUploadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        PatientReportUploadController(
          investigation: widget.investigation,
          caseTitle: widget.caseTitle,
          visitDate: widget.visitDate,
        );
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final inv = widget.investigation;
    final effectiveVisitDate = widget.visitDate ?? inv.requestedAt;

    return Scaffold(
      backgroundColor: PatientColors.background,
      appBar: PatientTopBar(
        title: strings.uploadReportTitle,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Context Card: Investigation, Case, Visit Date
                    _buildContextCard(strings, inv, effectiveVisitDate),
                    const SizedBox(height: 20),

                    // Error Alert (if any)
                    if (_controller.hasError) ...[
                      _buildErrorBanner(strings),
                      const SizedBox(height: 16),
                    ],

                    // Main Content: Image Picker or Preview Card
                    if (!_controller.hasPhotos) ...[
                      _buildInitialSelectionCard(strings),
                    ] else ...[
                      _buildPreviewCard(strings),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Uploading Overlay (Prevents double submission)
          if (_controller.isUploading)
            _buildUploadingOverlay(strings),
        ],
      ),
    );
  }

  Widget _buildContextCard(
    PatientStrings strings,
    InvestigationRequest inv,
    DateTime visitDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.surface,
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
              ),
              if (inv.isRequired) ...[
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
          const SizedBox(height: 12),
          Text(
            inv.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: PatientColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PatientColors.borderSubtle, width: 1),
            ),
            child: Column(
              children: [
                if (widget.caseTitle != null && widget.caseTitle!.isNotEmpty) ...[
                  _buildMetaRow(
                    icon: Icons.folder_outlined,
                    label: strings.reportCaseLabel,
                    value: widget.caseTitle!,
                  ),
                  const SizedBox(height: 6),
                ],
                _buildMetaRow(
                  icon: Icons.calendar_today_rounded,
                  label: strings.reportRequestedDate,
                  value: _formatDate(visitDate),
                ),
              ],
            ),
          ),
        ],
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
        Icon(icon, size: 14, color: PatientColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: PatientColors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
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

  Widget _buildInitialSelectionCard(PatientStrings strings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientColors.surface,
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PatientColors.tealLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: PatientColors.tealDark,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload Diagnostic Report',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PatientColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take a clear photo of your printed lab test report or select an image from your device gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: PatientColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Action Button 1: Take Photo (52dp+ senior-friendly)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _controller.isProcessing ? null : () => _controller.takePhoto(),
              icon: const Icon(Icons.photo_camera_rounded, size: 22),
              label: Text(
                strings.takePhotoAction,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
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
          const SizedBox(height: 14),

          // Action Button 2: Choose from Gallery (52dp+ senior-friendly)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _controller.isProcessing ? null : () => _controller.chooseFromGallery(),
              icon: const Icon(Icons.photo_library_rounded, size: 22),
              label: Text(
                strings.chooseFromGalleryAction,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: PatientColors.tealDark,
                side: const BorderSide(color: PatientColors.teal, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Guidance Note
          const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: PatientColors.textMuted),
              SizedBox(width: 6),
              Text(
                'Supports JPG, JPEG, PNG • Up to 15 MB',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: PatientColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(PatientStrings strings) {
    final currentPhoto = _controller.currentPreviewPhoto;
    final totalPhotos = _controller.photos.length;
    final currentIndex = _controller.selectedPreviewIndex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.surface,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.image_outlined, color: PatientColors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    strings.previewTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.navy,
                    ),
                  ),
                ],
              ),
              if (totalPhotos > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: PatientColors.tealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    strings.pageNumberLabel(currentIndex + 1, totalPhotos),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.tealDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Main Image Preview Box
          if (currentPhoto != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 280,
                color: const Color(0xFF1E2630),
                child: Image.memory(
                  Uint8List.fromList(currentPhoto.bytes),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Size: ${(currentPhoto.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: PatientColors.textMuted,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _controller.removePhoto(currentIndex),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                  label: Text(
                    strings.removePhotoAction,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Multi-page selector thumbnails (if > 1)
          if (totalPhotos > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: totalPhotos,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final isSel = idx == currentIndex;
                  final photo = _controller.photos[idx];
                  return InkWell(
                    onTap: () => _controller.selectPreviewIndex(idx),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? PatientColors.teal : PatientColors.border,
                          width: isSel ? 2.5 : 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(
                        Uint8List.fromList(photo.bytes),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.black38, size: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Secondary Actions: Retake / Add Another Photo
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final retakeBtn = SizedBox(
                width: isNarrow ? double.infinity : null,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showRetakeOptions(context, strings),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    strings.retakeAction,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PatientColors.navy,
                    side: const BorderSide(color: PatientColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );

              final addBtn = SizedBox(
                width: isNarrow ? double.infinity : null,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddOptions(context, strings),
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(
                    strings.addAnotherPhotoAction,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PatientColors.tealDark,
                    side: const BorderSide(color: PatientColors.teal, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    retakeBtn,
                    const SizedBox(height: 10),
                    addBtn,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: retakeBtn),
                  const SizedBox(width: 10),
                  Expanded(child: addBtn),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Primary Submission CTA (52dp+ height)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _controller.isUploading
                  ? null
                  : () => _showSubmitConfirmationDialog(context, strings),
              icon: const Icon(Icons.cloud_upload_rounded, size: 22),
              label: Text(
                strings.submitReportAction,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
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
      ),
    );
  }

  void _showRetakeOptions(BuildContext context, PatientStrings strings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: PatientColors.teal),
                title: Text(strings.takePhotoAction, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bContext);
                  _controller.retakeCurrentPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: PatientColors.teal),
                title: Text(strings.chooseFromGalleryAction, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bContext);
                  _controller.retakeCurrentPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context, PatientStrings strings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: PatientColors.teal),
                title: Text(strings.takePhotoAction, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bContext);
                  _controller.takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: PatientColors.teal),
                title: Text(strings.chooseFromGalleryAction, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bContext);
                  _controller.chooseFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitConfirmationDialog(BuildContext context, PatientStrings strings) {
    final inv = widget.investigation;
    final photo = _controller.currentPreviewPhoto;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: PatientColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_rounded, color: PatientColors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.submitReportConfirmTitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.navy,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.submitReportConfirmDesc,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: PatientColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PatientColors.borderSubtle, width: 1),
              ),
              child: Row(
                children: [
                  if (photo != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Image.memory(
                          Uint8List.fromList(photo.bytes),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.description, color: PatientColors.teal, size: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: PatientColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_controller.photos.length} photo page(s)',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            color: PatientColors.tealDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              strings.cancelAction,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: PatientColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_submit_button'),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final ok = await _controller.submit();
              if (ok && mounted) {
                _showSuccessDialog(this.context, strings);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PatientColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              strings.submitReportAction,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, PatientStrings strings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: PatientColors.statusSuccessLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: PatientColors.statusSuccess,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.reportSubmittedSuccessTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: PatientColors.navy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Investigation: ${widget.investigation.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PatientColors.tealDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.reportSubmittedSuccessDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: PatientColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                // Pop back to reports screen
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pushReplacementNamed('/patient/reports');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                strings.doneAction,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(PatientStrings strings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF5350), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.uploadFailedTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _controller.errorMessage ?? strings.uploadFailedDesc,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFFB71C1C),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFB71C1C)),
            onPressed: () => _controller.clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingOverlay(PatientStrings strings) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: PatientColors.teal,
                strokeWidth: 3.5,
              ),
              const SizedBox(height: 18),
              Text(
                strings.uploadingReportProgress,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.navy,
                ),
              ),
            ],
          ),
        ),
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
