import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'supabase_storage_service.dart';

/// In-memory mock storage service for development mode and testing.
class MockStorageService implements StorageService {
  static final MockStorageService instance = MockStorageService._();
  MockStorageService._();
  factory MockStorageService() => instance;

  final Map<String, Uint8List> _files = {};

  // Simulation controls
  bool simulateUploadFailure = false;
  String? failureErrorMessage;

  void reset() {
    _files.clear();
    simulateUploadFailure = false;
    failureErrorMessage = null;
  }

  @override
  FileValidationResult validateFile({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  }) {
    if (bytes.isEmpty) {
      return FileValidationResult.failure('File is empty. Please select a valid document.');
    }

    if (bytes.length > StorageService.maxFileSizeBytes) {
      return FileValidationResult.failure(
        'File size exceeds the 15 MB limit. Please compress or select a smaller file.',
      );
    }

    final lowerName = fileName.toLowerCase().trim();
    final extIndex = lowerName.lastIndexOf('.');
    if (extIndex == -1) {
      return FileValidationResult.failure('File must have an extension (.pdf, .jpg, .jpeg, .png).');
    }

    final ext = lowerName.substring(extIndex);
    if (!StorageService.allowedExtensions.contains(ext)) {
      return FileValidationResult.failure(
        'Unsupported file format ($ext). Only PDF, JPG, and PNG documents are supported.',
      );
    }

    // Binary Magic Byte Header Validation
    if (ext == '.pdf') {
      if (!_isPdf(bytes)) {
        return FileValidationResult.failure(
          'File header mismatch: Not a valid PDF document.',
        );
      }
      return FileValidationResult.success('application/pdf');
    } else if (ext == '.jpg' || ext == '.jpeg') {
      if (!_isJpeg(bytes)) {
        return FileValidationResult.failure(
          'File header mismatch: Not a valid JPEG image.',
        );
      }
      return FileValidationResult.success('image/jpeg');
    } else if (ext == '.png') {
      if (!_isPng(bytes)) {
        return FileValidationResult.failure(
          'File header mismatch: Not a valid PNG image.',
        );
      }
      return FileValidationResult.success('image/png');
    }

    return FileValidationResult.success(mimeType ?? 'application/octet-stream');
  }

  bool _isPdf(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46; // %PDF
  }

  bool _isPng(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47; // \x89PNG
  }

  bool _isJpeg(List<int> bytes) {
    if (bytes.length < 3) return false;
    return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF; // JPEG header
  }

  @override
  Future<String> uploadReportFile({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (simulateUploadFailure) {
      throw Exception(failureErrorMessage ?? 'Simulated storage upload failure.');
    }

    final validation = validateFile(fileName: fileName, bytes: bytes, mimeType: contentType);
    if (!validation.isValid) {
      throw ArgumentError(validation.errorMessage ?? 'Invalid report file.');
    }

    final storagePath =
        'patients/$patientId/cases/$caseId/visits/$visitId/reports/$fileName';

    final bytesList = Uint8List.fromList(bytes);
    _files[storagePath] = bytesList;
    if (investigationId.isNotEmpty) {
      final legacyPath =
          'patients/$patientId/cases/$caseId/visits/$visitId/reports/$investigationId/$fileName';
      _files[legacyPath] = bytesList;
    }
    debugPrint('[MockStorageService] Saved report to $storagePath (${bytes.length} bytes)');
    return storagePath;
  }

  @override
  Future<String> uploadVisitPdf({
    required String patientId,
    required String caseId,
    required String visitId,
    required String fileName,
    required List<int> bytes,
  }) async {
    if (simulateUploadFailure) {
      throw Exception(failureErrorMessage ?? 'Simulated storage upload failure.');
    }

    final validation = validateFile(fileName: fileName, bytes: bytes, mimeType: 'application/pdf');
    if (!validation.isValid) {
      throw ArgumentError(validation.errorMessage ?? 'Invalid Visit PDF file.');
    }

    final storagePath =
        'patients/$patientId/cases/$caseId/visits/$visitId/reports/$fileName';

    _files[storagePath] = Uint8List.fromList(bytes);
    debugPrint('[MockStorageService] Saved official Visit PDF to $storagePath (${bytes.length} bytes)');
    return storagePath;
  }

  @override
  Future<Uint8List?> getFileBytes(String storagePath) async {
    final clean = SupabaseStorageService.normalizeStoragePath(storagePath);
    return _files[clean] ?? _files[storagePath];
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    return getSignedUrl(storagePath);
  }

  @override
  Future<String?> getSignedUrl(
    String storagePath, {
    Duration? expiresIn,
  }) async {
    final clean = SupabaseStorageService.normalizeStoragePath(storagePath);
    if (_files.containsKey(clean) || _files.containsKey(storagePath)) {
      final token = DateTime.now().millisecondsSinceEpoch;
      final targetPath = _files.containsKey(clean) ? clean : storagePath;
      return 'https://xtgjpvejqzptjyrskuuk.supabase.co/storage/v1/object/sign/aayusathi-reports/${Uri.encodeComponent(targetPath)}?token=$token';
    }
    return null;
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    final clean = SupabaseStorageService.normalizeStoragePath(storagePath);
    _files.remove(clean);
    _files.remove(storagePath);
  }

  @override
  Future<bool> fileExists(String storagePath) async {
    final clean = SupabaseStorageService.normalizeStoragePath(storagePath);
    return _files.containsKey(clean) || _files.containsKey(storagePath);
  }
}
