import 'dart:typed_data';

/// Result of file upload validation check.
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? detectedMimeType;

  const FileValidationResult({
    required this.isValid,
    this.errorMessage,
    this.detectedMimeType,
  });

  factory FileValidationResult.success(String mimeType) => FileValidationResult(
        isValid: true,
        detectedMimeType: mimeType,
      );

  factory FileValidationResult.failure(String message) => FileValidationResult(
        isValid: false,
        errorMessage: message,
      );
}

/// Abstract storage service managing medical report file uploads, validation, and retrieval.
///
/// Storage logical structure:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{investigationId}/{fileName}`
/// or official PDF:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}`
abstract class StorageService {
  /// Maximum permitted report file size (15 MB).
  static const int maxFileSizeBytes = 15 * 1024 * 1024;

  /// Allowed MIME types
  static const Set<String> allowedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
  };

  /// Allowed extensions
  static const Set<String> allowedExtensions = {
    '.pdf',
    '.jpg',
    '.jpeg',
    '.png',
  };

  /// Magic bytes signatures
  static const List<int> pdfMagicBytes = [0x25, 0x50, 0x44, 0x46]; // %PDF
  static const List<int> jpegMagicBytes = [0xFF, 0xD8, 0xFF];
  static const List<int> pngMagicBytes = [0x89, 0x50, 0x4E, 0x47];

  /// Validates file name, size, and binary magic bytes.
  FileValidationResult validateFile({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  });

  /// Uploads report file to storage and returns logical storage path.
  Future<String> uploadReportFile({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  });

  /// Uploads official Doctor Visit Report PDF to cloud storage.
  Future<String> uploadVisitPdf({
    required String patientId,
    required String caseId,
    required String visitId,
    required String fileName,
    required List<int> bytes,
  });

  /// Retrieves file bytes from storage.
  Future<Uint8List?> getFileBytes(String storagePath);

  /// Retrieves public/authenticated download URL for a stored document.
  Future<String?> getDownloadUrl(String storagePath);

  /// Generates a secure, short-lived signed URL for time-limited private file access.
  Future<String?> getSignedUrl(String storagePath, {Duration? expiresIn});

  /// Deletes a file from storage.
  Future<void> deleteFile(String storagePath);

  /// Checks if a file exists in storage.
  Future<bool> fileExists(String storagePath);
}
