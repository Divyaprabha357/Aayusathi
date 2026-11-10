import 'dart:math';

/// Result object for report file validation.
class PatientFileValidationResult {
  final bool isValid;
  final String? detectedMimeType;
  final String? errorMessage;

  const PatientFileValidationResult._({
    required this.isValid,
    this.detectedMimeType,
    this.errorMessage,
  });

  factory PatientFileValidationResult.success(String mimeType) {
    return PatientFileValidationResult._(
      isValid: true,
      detectedMimeType: mimeType,
    );
  }

  factory PatientFileValidationResult.failure(String message) {
    return PatientFileValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }
}

/// Service enforcing medical photo file validation, magic-byte inspection,
/// and safe storage path generation for Patient App P8.
class PatientReportFileValidator {
  PatientReportFileValidator._();

  /// Maximum allowed file size: 15 MB (15 * 1024 * 1024 bytes).
  static const int maxFileSizeBytes = 15 * 1024 * 1024;

  /// Allowed photo file extensions for patient upload.
  static const Set<String> allowedPhotoExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
  };

  /// Allowed report document extensions (supports image photos and PDF files).
  static const Set<String> allowedFileExtensions = {
    '.pdf',
    '.jpg',
    '.jpeg',
    '.png',
  };

  /// Allowed declared MIME types for patient report files.
  static const Set<String> allowedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
  };

  /// Validates a patient photo upload. For backward compatibility, rejects PDF by default unless [allowPdf] is true.
  static PatientFileValidationResult validateReportPhoto({
    required String fileName,
    required List<int> bytes,
    String? declaredMimeType,
    bool allowPdf = false,
  }) {
    return validateReportFile(
      fileName: fileName,
      bytes: bytes,
      declaredMimeType: declaredMimeType,
      allowPdf: allowPdf,
    );
  }

  /// Validates both metadata and binary contents of a patient report file (PDF, JPG, JPEG, PNG).
  static PatientFileValidationResult validateReportFile({
    required String fileName,
    required List<int> bytes,
    String? declaredMimeType,
    bool allowPdf = true,
  }) {
    if (bytes.isEmpty) {
      return PatientFileValidationResult.failure(
        'File is empty. Please select a valid document or photo.',
      );
    }

    if (bytes.length > maxFileSizeBytes) {
      final sizeMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      return PatientFileValidationResult.failure(
        'File size ($sizeMb MB) exceeds the 15 MB limit. Please select a smaller file.',
      );
    }

    // Path traversal / malicious path validation
    if (hasPathTraversal(fileName)) {
      return PatientFileValidationResult.failure(
        'Invalid file name: Path traversal sequences are strictly prohibited.',
      );
    }

    final lowerName = fileName.toLowerCase().trim();
    final extIndex = lowerName.lastIndexOf('.');
    if (extIndex == -1) {
      return PatientFileValidationResult.failure(
        'File must have an extension (.pdf, .jpg, .jpeg, or .png).',
      );
    }

    final ext = lowerName.substring(extIndex);

    // If PDF is not allowed in this specific mode (e.g. photo-only acquisition)
    if (!allowPdf && (ext == '.pdf' || _isPdf(bytes))) {
      return PatientFileValidationResult.failure(
        'PDF documents are not supported for photo upload. Please select a JPG or PNG photo of your diagnostic report.',
      );
    }

    // Check declared extension against permitted file extensions
    final allowedExts = allowPdf ? allowedFileExtensions : allowedPhotoExtensions;
    if (!allowedExts.contains(ext)) {
      return PatientFileValidationResult.failure(
        'Unsupported file format ($ext). Only ${allowPdf ? "PDF, " : ""}JPG, JPEG, and PNG documents are supported.',
      );
    }

    // Check declared MIME type if provided
    if (declaredMimeType != null && declaredMimeType.trim().isNotEmpty) {
      final cleanMime = declaredMimeType.toLowerCase().trim();
      if (!allowedMimeTypes.contains(cleanMime)) {
        return PatientFileValidationResult.failure(
          'Unsupported content type ($cleanMime). Only PDF, JPEG, and PNG files are accepted.',
        );
      }
    }

    // Explicit check for malicious or non-image binary signatures
    if (_isExe(bytes)) {
      return PatientFileValidationResult.failure(
        'Executable files are strictly rejected.',
      );
    }

    if (_isZip(bytes)) {
      return PatientFileValidationResult.failure(
        'Archive files are not accepted.',
      );
    }

    if (_isHtmlOrSvg(bytes)) {
      return PatientFileValidationResult.failure(
        'HTML and SVG documents are not accepted for report upload.',
      );
    }

    // Binary Magic Byte Validation
    if (ext == '.pdf') {
      if (!_isPdf(bytes)) {
        return PatientFileValidationResult.failure(
          'File header mismatch: Not a valid PDF document.',
        );
      }
      return PatientFileValidationResult.success('application/pdf');
    } else if (ext == '.jpg' || ext == '.jpeg') {
      if (!_isJpeg(bytes)) {
        return PatientFileValidationResult.failure(
          'File header mismatch: Not a valid JPEG image.',
        );
      }
      return PatientFileValidationResult.success('image/jpeg');
    } else if (ext == '.png') {
      if (!_isPng(bytes)) {
        return PatientFileValidationResult.failure(
          'File header mismatch: Not a valid PNG image.',
        );
      }
      return PatientFileValidationResult.success('image/png');
    }

    return PatientFileValidationResult.failure('Unrecognized document format.');
  }

  /// Detects path traversal sequences like `../`, `..\`, leading slashes, etc.
  static bool hasPathTraversal(String path) {
    if (path.contains('../') ||
        path.contains('..\\') ||
        path.startsWith('/') ||
        path.startsWith('\\') ||
        path.contains('/../') ||
        path.contains('\\..\\')) {
      return true;
    }
    // Check for encoded traversal sequences
    if (path.contains('%2e%2e') || path.contains('%2f') || path.contains('%5c')) {
      return true;
    }
    return false;
  }

  /// Generates a sanitized, deterministic filename based on IDs and timestamp.
  ///
  /// Contains no slashes, no spaces, no path traversal characters.
  /// Format: `AAYU_{cleanPatientId}_INV_{cleanInvId}_{timestamp}_{randomSuffix}.{ext}`
  static String generateSafeFileName({
    required String patientId,
    required String investigationId,
    required String extension,
    int? timestamp,
    String? randomSuffix,
  }) {
    final cleanPatientId = patientId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final cleanInvId = investigationId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    var cleanExt = extension.toLowerCase().trim();
    if (!cleanExt.startsWith('.')) {
      cleanExt = '.$cleanExt';
    }
    if (cleanExt == '.jpeg') {
      cleanExt = '.jpg';
    }
    if (cleanExt != '.jpg' && cleanExt != '.png' && cleanExt != '.pdf') {
      cleanExt = '.jpg';
    }

    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final suffix = randomSuffix ?? _randomAlphaNumeric(4);

    return 'AAYU_${cleanPatientId}_INV_${cleanInvId}_${ts}_$suffix$cleanExt';
  }

  /// Generates canonical private storage path within `aayusathi-reports` bucket:
  /// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{safeFileName}`
  static String generateCanonicalStoragePath({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String safeFileName,
  }) {
    final cleanPatientId = patientId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '').toUpperCase();
    final cleanCaseId = caseId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');
    final cleanVisitId = visitId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');
    final cleanFileName = safeFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._\-]'), '_');

    return 'patients/$cleanPatientId/cases/$cleanCaseId/visits/$cleanVisitId/reports/$cleanFileName';
  }

  static bool _isJpeg(List<int> bytes) {
    if (bytes.length < 3) return false;
    return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  }

  static bool _isPng(List<int> bytes) {
    if (bytes.length < 8) return false;
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
  }

  static bool _isPdf(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46; // %PDF
  }

  static bool _isExe(List<int> bytes) {
    if (bytes.length < 2) return false;
    return bytes[0] == 0x4D && bytes[1] == 0x5A; // MZ
  }

  static bool _isZip(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04; // PK..
  }

  static bool _isHtmlOrSvg(List<int> bytes) {
    final lengthToCheck = min(bytes.length, 100);
    final headerStr = String.fromCharCodes(bytes.take(lengthToCheck)).toLowerCase();
    return headerStr.contains('<!doctype') ||
        headerStr.contains('<html') ||
        headerStr.contains('<svg') ||
        headerStr.contains('<?xml');
  }

  static String _randomAlphaNumeric(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
