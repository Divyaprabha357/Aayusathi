import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/backend/backend_exception.dart';
import '../../doctor/models/investigation_request.dart';
import '../../doctor/models/report_document.dart';
import '../services/patient_report_file_validator.dart';
import '../services/patient_report_upload_service.dart';
import '../services/patient_session_service.dart';

enum UploadStep {
  initial,
  photoSelected,
  confirming,
  uploading,
  success,
  error,
}

/// Controller managing image acquisition (Camera & Gallery), preview, validation,
/// and submission states for the Patient Report Photo Upload screen.
class PatientReportUploadController extends ChangeNotifier {
  final InvestigationRequest investigation;
  final String? caseTitle;
  final DateTime? visitDate;
  final ImagePicker _picker;
  final PatientReportUploadService _uploadService;
  final PatientSessionService _sessionService;

  PatientReportUploadController({
    required this.investigation,
    this.caseTitle,
    this.visitDate,
    ImagePicker? picker,
    PatientReportUploadService? uploadService,
    PatientSessionService? sessionService,
  })  : _picker = picker ?? ImagePicker(),
        _uploadService = uploadService ?? PatientReportUploadService.instance,
        _sessionService = sessionService ?? PatientSessionService.instance;

  UploadStep _step = UploadStep.initial;
  final List<ReportPhotoItem> _photos = [];
  int _selectedPreviewIndex = 0;
  bool _isProcessing = false;
  bool _isUploading = false;
  String? _errorMessage;
  ReportDocument? _submittedReport;

  UploadStep get step => _step;
  List<ReportPhotoItem> get photos => List.unmodifiable(_photos);
  bool get hasPhotos => _photos.isNotEmpty;
  int get selectedPreviewIndex => _selectedPreviewIndex;
  ReportPhotoItem? get currentPreviewPhoto =>
      _photos.isNotEmpty && _selectedPreviewIndex < _photos.length
          ? _photos[_selectedPreviewIndex]
          : null;

  bool get isProcessing => _isProcessing;
  bool get isUploading => _isUploading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _step == UploadStep.success;
  ReportDocument? get submittedReport => _submittedReport;

  String get patientId =>
      investigation.patientId ??
      _sessionService.authenticatedPatientId ??
      '';

  String get caseId => investigation.caseId ?? '';
  String get visitId => investigation.visitId ?? '';
  String get investigationId => investigation.requestId;

  void selectPreviewIndex(int index) {
    if (index >= 0 && index < _photos.length) {
      _selectedPreviewIndex = index;
      notifyListeners();
    }
  }

  /// Acquires a report image using device Camera.
  Future<bool> takePhoto() async {
    return _pickImage(ImageSource.camera);
  }

  /// Acquires a report image from device Gallery / Photo Library.
  Future<bool> chooseFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  Future<bool> _pickImage(ImageSource source) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 92, // Preserves medical readability without aggressive distortion
        maxWidth: 2400,
        maxHeight: 2400,
      );

      if (picked == null) {
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      final bytes = await picked.readAsBytes();
      final originalName = picked.name.isNotEmpty ? picked.name : 'report_photo.jpg';

      // Validate immediately upon acquisition
      final validation = PatientReportFileValidator.validateReportPhoto(
        fileName: originalName,
        bytes: bytes,
        declaredMimeType: picked.mimeType,
      );

      if (!validation.isValid) {
        _isProcessing = false;
        _errorMessage = validation.errorMessage ?? 'Invalid photo file.';
        notifyListeners();
        return false;
      }

      final newItem = ReportPhotoItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_photos.length}',
        originalName: originalName,
        bytes: bytes,
        mimeType: validation.detectedMimeType ?? picked.mimeType,
        pageNumber: _photos.length + 1,
      );

      _photos.add(newItem);
      _selectedPreviewIndex = _photos.length - 1;
      _step = UploadStep.photoSelected;
      _isProcessing = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[PatientReportUploadController] Image pick error: $e');
      _isProcessing = false;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || errorStr.contains('denied')) {
        _errorMessage = source == ImageSource.camera
            ? 'Camera permission is required to take a report photo.'
            : 'Photo access is required to choose a report.';
      } else {
        _errorMessage = 'Unable to select photo. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }

  /// Adds an in-memory photo directly (useful for tests or programmatic workflows).
  void addPhotoBytes({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  }) {
    final validation = PatientReportFileValidator.validateReportFile(
      fileName: fileName,
      bytes: bytes,
      declaredMimeType: mimeType,
      allowPdf: true,
    );

    if (!validation.isValid) {
      _errorMessage = validation.errorMessage;
      notifyListeners();
      return;
    }

    final newItem = ReportPhotoItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_photos.length}',
      originalName: fileName,
      bytes: bytes,
      mimeType: validation.detectedMimeType ?? mimeType,
      pageNumber: _photos.length + 1,
    );

    _photos.add(newItem);
    _selectedPreviewIndex = _photos.length - 1;
    _step = UploadStep.photoSelected;
    _errorMessage = null;
    notifyListeners();
  }

  /// Replaces the currently selected photo page.
  Future<bool> retakeCurrentPhoto(ImageSource source) async {
    if (_photos.isEmpty) return false;
    final currentIndex = _selectedPreviewIndex;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
        maxHeight: 2400,
      );

      if (picked == null) return false;

      final bytes = await picked.readAsBytes();
      final originalName = picked.name.isNotEmpty ? picked.name : 'report_photo.jpg';

      final validation = PatientReportFileValidator.validateReportPhoto(
        fileName: originalName,
        bytes: bytes,
        declaredMimeType: picked.mimeType,
      );

      if (!validation.isValid) {
        _errorMessage = validation.errorMessage ?? 'Invalid photo file.';
        notifyListeners();
        return false;
      }

      _photos[currentIndex] = ReportPhotoItem(
        id: _photos[currentIndex].id,
        originalName: originalName,
        bytes: bytes,
        mimeType: validation.detectedMimeType ?? picked.mimeType,
        pageNumber: currentIndex + 1,
      );

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not retake photo. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Removes a photo page from the selection.
  void removePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      _photos.removeAt(index);
      if (_photos.isEmpty) {
        _step = UploadStep.initial;
        _selectedPreviewIndex = 0;
      } else {
        _selectedPreviewIndex = (_selectedPreviewIndex - 1).clamp(0, _photos.length - 1);
      }
      notifyListeners();
    }
  }

  /// Initiates the final submission to Supabase and Cloud Firestore.
  Future<bool> submit() async {
    if (_isUploading) return false; // Prevent double-tap / concurrent submission
    if (_photos.isEmpty) {
      _errorMessage = 'Please select or take at least one report photo.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _step = UploadStep.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedDoc = await _uploadService.submitReport(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
        investigationId: investigationId,
        photos: _photos,
      );

      _submittedReport = savedDoc;
      _isUploading = false;
      _step = UploadStep.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on BackendException catch (e) {
      debugPrint('[PatientReportUploadController] BackendException: ${e.code} - ${e.message}');
      _isUploading = false;
      _step = UploadStep.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[PatientReportUploadController] Unexpected error: $e');
      _isUploading = false;
      _step = UploadStep.error;
      _errorMessage = 'Upload failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Retries submission using existing selected photos.
  Future<bool> retry() => submit();

  void clearError() {
    _errorMessage = null;
    if (_step == UploadStep.error) {
      _step = _photos.isNotEmpty ? UploadStep.photoSelected : UploadStep.initial;
    }
    notifyListeners();
  }

  void reset() {
    _step = UploadStep.initial;
    _photos.clear();
    _selectedPreviewIndex = 0;
    _isProcessing = false;
    _isUploading = false;
    _errorMessage = null;
    _submittedReport = null;
    notifyListeners();
  }
}
