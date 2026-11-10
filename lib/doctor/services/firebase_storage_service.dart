import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import 'storage_service.dart';

/// Firebase Cloud Storage implementation of [StorageService].
///
/// Follows logical hierarchy:
/// Investigation reports:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{investigationId}/{fileName}`
///
/// Official Doctor Visit Report PDF:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}`
class FirebaseStorageService implements StorageService {
  final FirebaseStorage? _customStorage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _customStorage = storage;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

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
      if (bytes.length < 4 ||
          bytes[0] != 0x25 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x44 ||
          bytes[3] != 0x46) {
        return FileValidationResult.failure(
          'File header mismatch: Not a valid PDF document.',
        );
      }
      return FileValidationResult.success('application/pdf');
    } else if (ext == '.jpg' || ext == '.jpeg') {
      if (bytes.length < 3 ||
          bytes[0] != 0xFF ||
          bytes[1] != 0xD8 ||
          bytes[2] != 0xFF) {
        return FileValidationResult.failure(
          'File header mismatch: Not a valid JPEG image.',
        );
      }
      return FileValidationResult.success('image/jpeg');
    } else if (ext == '.png') {
      if (bytes.length < 4 ||
          bytes[0] != 0x89 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x4E ||
          bytes[3] != 0x47) {
        return FileValidationResult.failure(
          'File header mismatch: Not a valid PNG image.',
        );
      }
      return FileValidationResult.success('image/png');
    }

    return FileValidationResult.success(mimeType ?? 'application/octet-stream');
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
    final validation = validateFile(fileName: fileName, bytes: bytes, mimeType: contentType);
    if (!validation.isValid) {
      throw BackendException(
        code: BackendException.invalidData,
        message: validation.errorMessage ?? 'Invalid report file.',
      );
    }

    final cleanPatientId = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final storagePath =
        'patients/$cleanPatientId/cases/$caseId/visits/$visitId/reports/$investigationId/$fileName';

    try {
      debugPrint('[FirebaseStorageService] Uploading report to $storagePath (${bytes.length} bytes)');
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: validation.detectedMimeType ?? contentType,
        customMetadata: {
          'patientId': cleanPatientId,
          'caseId': caseId,
          'visitId': visitId,
          'investigationId': investigationId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(Uint8List.fromList(bytes), metadata);
      debugPrint('[FirebaseStorageService] Report upload SUCCESS: $storagePath');
      return storagePath;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseStorageService] FirebaseException on upload: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied' || e.code == 'unauthorized'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not upload report to Cloud Storage (${e.message ?? e.code}).',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseStorageService] Storage upload error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not upload report to cloud storage: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<String> uploadVisitPdf({
    required String patientId,
    required String caseId,
    required String visitId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final validation = validateFile(fileName: fileName, bytes: bytes, mimeType: 'application/pdf');
    if (!validation.isValid) {
      throw BackendException(
        code: BackendException.invalidData,
        message: validation.errorMessage ?? 'Invalid Visit PDF file.',
      );
    }

    final cleanPatientId = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final storagePath =
        'patients/$cleanPatientId/cases/$caseId/visits/$visitId/reports/$fileName';

    try {
      debugPrint('[FirebaseStorageService] Uploading official Visit PDF to $storagePath (${bytes.length} bytes)');
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'patientId': cleanPatientId,
          'caseId': caseId,
          'visitId': visitId,
          'isOfficialReport': 'true',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(Uint8List.fromList(bytes), metadata);
      debugPrint('[FirebaseStorageService] Official Visit PDF upload SUCCESS: $storagePath');
      return storagePath;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseStorageService] FirebaseException on PDF upload: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied' || e.code == 'unauthorized'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not upload Visit PDF to Cloud Storage (${e.message ?? e.code}).',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseStorageService] Storage upload error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not upload Visit PDF to cloud storage: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<Uint8List?> getFileBytes(String storagePath) async {
    try {
      debugPrint('[FirebaseStorageService] Fetching file bytes from $storagePath');
      final ref = _storage.ref(storagePath);
      return await ref.getData(StorageService.maxFileSizeBytes);
    } catch (e) {
      debugPrint('[FirebaseStorageService] Error reading file: $e');
      return null;
    }
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[FirebaseStorageService] Error getting download URL: $e');
      return null;
    }
  }

  @override
  Future<String?> getSignedUrl(String storagePath, {Duration? expiresIn}) async {
    return getDownloadUrl(storagePath);
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      await ref.delete();
    } catch (e) {
      debugPrint('[FirebaseStorageService] Error deleting file: $e');
    }
  }

  @override
  Future<bool> fileExists(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      final meta = await ref.getMetadata();
      return meta.size != null;
    } catch (e) {
      return false;
    }
  }
}
