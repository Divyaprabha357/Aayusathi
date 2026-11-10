import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/supabase_initializer.dart';
import 'storage_service.dart';

/// Supabase Cloud Storage implementation of [StorageService].
///
/// Follows the canonical AAYUSATHI medical hierarchy:
///
/// Investigation reports:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{investigationId}/{fileName}`
///
/// Official Doctor Visit Report PDF:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}`
///
/// Patient Uploads:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/uploads/{reportId}.{extension}`
///
/// Bucket: `aayusathi-reports` (PRIVATE)
class SupabaseStorageService implements StorageService {
  final SupabaseClient? _customClient;
  final String _bucket;

  SupabaseStorageService({
    SupabaseClient? client,
    String? bucket,
  })  : _customClient = client,
        _bucket = bucket ?? SupabaseConfig.bucketName;

  SupabaseClient get _client {
    final custom = _customClient;
    if (custom != null) return custom;
    return Supabase.instance.client;
  }

  StorageFileApi get _storage => _client.storage.from(_bucket);

  bool get _isReady =>
      _customClient != null ||
      (SupabaseInitializer.isInitialized && SupabaseConfig.isLiveCloudReady);

  String _cleanId(String rawId) {
    var clean = rawId.trim().replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), '');
    clean = clean.replaceAll('..', '');
    clean = clean.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    clean = clean.replaceAll(RegExp(r'_+'), '_');
    return clean.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Canonical path normalizer for AAYUSATHI Supabase Storage.
  ///
  /// Guarantees:
  /// 1. Strips URL prefix if a full signed/authenticated/public URL is provided.
  /// 2. Strips query parameters (e.g. `?token=...`).
  /// 3. Decodes percent-encoded characters.
  /// 4. Strips leading slash and duplicate slashes.
  /// 5. Strips bucket name prefix (`aayusathi-reports/`) to avoid NoSuchBucket errors.
  /// 6. Strips path traversal sequences (`..`).
  /// 7. Preserves valid existing files and historical path variants.
  static String normalizeStoragePath(String rawPath) {
    var path = rawPath.trim();
    if (path.isEmpty) return '';

    // 1. If it's a full URL, extract the path component
    if (path.startsWith('http://') || path.startsWith('https://')) {
      try {
        final uri = Uri.parse(path);
        path = uri.path;
      } catch (_) {
        final queryIdx = path.indexOf('?');
        if (queryIdx != -1) path = path.substring(0, queryIdx);
      }
    } else {
      final queryIdx = path.indexOf('?');
      if (queryIdx != -1) path = path.substring(0, queryIdx);
    }

    // 2. Decode percent-encoding
    try {
      path = Uri.decodeComponent(path);
    } catch (_) {}

    // 3. Normalize slashes
    path = path.replaceAll('\\', '/');

    // 4. Strip known Supabase API path prefixes if present
    final bucket = SupabaseConfig.bucketName;
    final prefixesToRemove = [
      '/storage/v1/object/sign/$bucket/',
      'storage/v1/object/sign/$bucket/',
      '/storage/v1/object/authenticated/$bucket/',
      'storage/v1/object/authenticated/$bucket/',
      '/storage/v1/object/public/$bucket/',
      'storage/v1/object/public/$bucket/',
      '/storage/v1/object/$bucket/',
      'storage/v1/object/$bucket/',
      '/$bucket/',
      '$bucket/',
    ];

    for (final prefix in prefixesToRemove) {
      if (path.startsWith(prefix)) {
        path = path.substring(prefix.length);
        break;
      }
    }

    // 5. Strip leading slashes and collapse duplicate slashes
    path = path.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+'), '/');

    // 6. Prevent path traversal
    path = path.replaceAll('../', '').replaceAll('..', '');

    return path;
  }

  /// Generates the canonical, RLS-compliant storage path:
  /// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}`
  ///
  /// Guarantees:
  /// 1. patientId is the actual patient ID (no unauthorized prefixing).
  /// 2. caseId is the actual case ID.
  /// 3. visitId is the actual visit ID.
  /// 4. fileName is sanitized and strictly ends in `.pdf`.
  /// 5. No leading slash.
  /// 6. No duplicate slashes.
  /// 7. No path traversal (`..` stripped).
  /// 8. Exactly contains `/reports/` between visitId and fileName.
  static String generateCanonicalVisitPdfPath({
    required String patientId,
    required String caseId,
    required String visitId,
    required String fileName,
  }) {
    // 1. Sanitize patientId (actual patient ID, preserve prefix if already present, but never force one)
    var cleanPatientId = patientId.trim().replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), '');
    cleanPatientId = cleanPatientId.replaceAll('..', '');
    cleanPatientId = cleanPatientId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    cleanPatientId = cleanPatientId.replaceAll(RegExp(r'_+'), '_');
    cleanPatientId = cleanPatientId.replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleanPatientId.isEmpty) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'Invalid patient ID for storage path generation.',
      );
    }

    // 2. Sanitize caseId
    var cleanCaseId = caseId.trim().replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), '');
    cleanCaseId = cleanCaseId.replaceAll('..', '');
    cleanCaseId = cleanCaseId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    cleanCaseId = cleanCaseId.replaceAll(RegExp(r'_+'), '_');
    cleanCaseId = cleanCaseId.replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleanCaseId.isEmpty) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'Invalid case ID for storage path generation.',
      );
    }

    // 3. Sanitize visitId
    var cleanVisitId = visitId.trim().replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), '');
    cleanVisitId = cleanVisitId.replaceAll('..', '');
    cleanVisitId = cleanVisitId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    cleanVisitId = cleanVisitId.replaceAll(RegExp(r'_+'), '_');
    cleanVisitId = cleanVisitId.replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleanVisitId.isEmpty) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'Invalid visit ID for storage path generation.',
      );
    }

    // 4. Sanitize fileName and ensure ends with .pdf
    var cleanFileName = fileName.trim().replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), '');
    cleanFileName = cleanFileName.replaceAll('..', '');
    cleanFileName = cleanFileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '_');
    cleanFileName = cleanFileName.replaceAll(RegExp(r'_+'), '_');
    if (!cleanFileName.toLowerCase().endsWith('.pdf')) {
      cleanFileName = '$cleanFileName.pdf';
    }

    // 5. Construct canonical path
    final rawPath = 'patients/$cleanPatientId/cases/$cleanCaseId/visits/$cleanVisitId/reports/$cleanFileName';

    // 6. Ensure no leading slash and collapse any duplicate slashes
    final canonical = rawPath.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+'), '/');

    return canonical;
  }

  @override
  FileValidationResult validateFile({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  }) {
    if (bytes.isEmpty) {
      return FileValidationResult.failure(
        'File is empty. Please select a valid document.',
      );
    }

    if (bytes.length > StorageService.maxFileSizeBytes) {
      return FileValidationResult.failure(
        'File size exceeds the 15 MB limit. Please compress or select a smaller file.',
      );
    }

    final lowerName = fileName.toLowerCase().trim();
    final extIndex = lowerName.lastIndexOf('.');
    if (extIndex == -1) {
      return FileValidationResult.failure(
        'File must have an extension (.pdf, .jpg, .jpeg, .png).',
      );
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
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46; // %PDF
  }

  bool _isPng(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47; // \x89PNG
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
    final validation = validateFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: contentType,
    );
    if (!validation.isValid) {
      throw BackendException(
        code: BackendException.invalidData,
        message: validation.errorMessage ?? 'Invalid report file.',
      );
    }

    final cleanPatientId = _cleanId(patientId);
    final cleanCaseId = _cleanId(caseId);
    final cleanVisitId = _cleanId(visitId);
    final cleanInvId = _cleanId(investigationId);
    var cleanFileName = fileName.trim().replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), '').replaceAll('..', '').replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '_');

    // Canonical path: patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}
    // Safe distinct naming: embed investigationId if not already present so it never collides with Visit Report PDF
    if (cleanInvId.isNotEmpty && !cleanFileName.toLowerCase().contains(cleanInvId.toLowerCase()) && !cleanFileName.startsWith('AAYU_')) {
      cleanFileName = 'AAYU_${cleanPatientId}_INV_${cleanInvId}_$cleanFileName';
    }

    final rawPath = 'patients/$cleanPatientId/cases/$cleanCaseId/visits/$cleanVisitId/reports/$cleanFileName';
    final storagePath = normalizeStoragePath(rawPath);

    // Fast-fail if client is not configured with a valid anonymous key
    if (!_isReady) {
      debugPrint('[SupabaseStorageService] Upload aborted: Supabase client is not configured with a valid anonymous key.');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not upload report to Supabase Storage: Valid publishable key required. Configure --dart-define=SUPABASE_ANON_KEY=... at build time.',
      );
    }

    try {
      final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      await _storage.uploadBinary(
        storagePath,
        uint8Bytes,
        fileOptions: FileOptions(
          contentType: validation.detectedMimeType ?? contentType,
          upsert: true,
        ),
      );

      // Confirm persistence in storage
      final exists = await fileExists(storagePath);
      if (!exists) {
        debugPrint('[SupabaseStorageService] Warning: Report file existence could not be confirmed immediately after upload: $storagePath');
      }

      debugPrint('[SupabaseStorageService] Successfully uploaded report to $storagePath');
      return storagePath;
    } on StorageException catch (e) {
      final isAlreadyExists = e.statusCode == '409' ||
          e.message.toLowerCase().contains('already exists') ||
          e.message.toLowerCase().contains('duplicate');

      if (isAlreadyExists) {
        debugPrint('[SupabaseStorageService] Report object already exists (409): returning deterministic path $storagePath');
        return storagePath;
      }

      final isSignatureError = e.message.toLowerCase().contains('signature verification failed') ||
          (e.statusCode == '403' && e.message.toLowerCase().contains('signature'));
      final isAuthOrPermError = e.statusCode == '403' || e.statusCode == '401';
      final sanitizedCategory = isSignatureError
          ? 'Invalid API Key / JWT Signature Verification'
          : isAuthOrPermError
              ? 'Permission Denied / RLS Violation'
              : 'Storage Failure (${e.statusCode})';

      debugPrint('[SupabaseStorageService] Upload failed for $storagePath:');
      debugPrint('  - Status Code: ${e.statusCode}');
      debugPrint('  - Error Message: ${e.message}');
      debugPrint('  - Error Category: $sanitizedCategory');
      debugPrint('  - Project host: ${SupabaseConfig.projectHost}');
      debugPrint('  - Bucket: $_bucket');

      final errorMsg = isSignatureError
          ? 'signature verification failed'
          : e.message;

      throw BackendException(
        code: isAuthOrPermError
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not upload report to Supabase Storage: $errorMsg',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[SupabaseStorageService] Unexpected upload error: $e');
      if (e is BackendException) rethrow;
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to upload report file to cloud storage.',
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
    final validation = validateFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    if (!validation.isValid) {
      throw BackendException(
        code: BackendException.invalidData,
        message: validation.errorMessage ?? 'Invalid Visit PDF file.',
      );
    }

    final rawPath = generateCanonicalVisitPdfPath(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      fileName: fileName,
    );
    final storagePath = normalizeStoragePath(rawPath);

    // Fast-fail if client is not configured with a valid anonymous key
    if (!_isReady) {
      debugPrint('[SupabaseStorageService] Visit PDF upload aborted: Supabase client is not configured with a valid anonymous key.');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not upload visit PDF to Supabase Storage: Valid publishable key required. Configure --dart-define=SUPABASE_ANON_KEY=... at build time.',
      );
    }

    // Safe Development Diagnostics (Never logs secret/anon keys, tokens, or PII)
    final sessionPresent = _client.auth.currentSession != null;
    debugPrint('[SupabaseStorageService] Starting Visit PDF upload:');
    debugPrint('  - Supabase initialized: ${SupabaseInitializer.isInitialized}');
    debugPrint('  - Supabase host: ${SupabaseConfig.projectHost}');
    debugPrint('  - Supabase bucket: $_bucket (Private: ${SupabaseConfig.isPrivateBucket})');
    debugPrint('  - Supabase auth session present: $sessionPresent');
    debugPrint('  - Storage path: $storagePath');
    debugPrint('  - Content type: application/pdf');
    debugPrint('  - File size: ${bytes.length} bytes');
    debugPrint('  - Key status: ${SupabaseConfig.keyStatusDescription}');
    debugPrint('[SupabaseStorageService] Upload started for $storagePath');

    try {
      final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      await _storage.uploadBinary(
        storagePath,
        uint8Bytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: true, // Strict idempotent upload with upsert
        ),
      );

      // Best-effort existence confirmation
      try {
        await fileExists(storagePath);
      } catch (_) {}

      debugPrint('[SupabaseStorageService] Upload succeeded and confirmed in bucket: $storagePath');
      return storagePath;
    } on StorageException catch (e) {
      // Safe Duplicate / Retry Handling:
      final isAlreadyExists = e.statusCode == '409' ||
          e.message.toLowerCase().contains('already exists') ||
          e.message.toLowerCase().contains('duplicate');

      if (isAlreadyExists) {
        debugPrint('[SupabaseStorageService] Object already exists (409): returning deterministic path $storagePath');
        return storagePath;
      }

      final isSignatureError = e.message.toLowerCase().contains('signature verification failed') ||
          (e.statusCode == '403' && e.message.toLowerCase().contains('signature'));
      final isAuthOrPermError = e.statusCode == '403' || e.statusCode == '401';
      final sanitizedCategory = isSignatureError
          ? 'Invalid API Key / JWT Signature Verification'
          : isAuthOrPermError
              ? 'Permission Denied / RLS Violation'
              : 'Storage Failure (${e.statusCode})';

      debugPrint('[SupabaseStorageService] Upload failed for $storagePath:');
      debugPrint('  - Status Code: ${e.statusCode}');
      debugPrint('  - Error Message: ${e.message}');
      debugPrint('  - Error Category: $sanitizedCategory');
      debugPrint('  - Project host: ${SupabaseConfig.projectHost}');
      debugPrint('  - Bucket: $_bucket');

      final errorMsg = isSignatureError
          ? 'signature verification failed'
          : e.message;

      throw BackendException(
        code: isAuthOrPermError
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not upload visit PDF to Supabase Storage: $errorMsg',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[SupabaseStorageService] Unexpected visit PDF upload error: $e');
      if (e is BackendException) rethrow;
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to upload Visit PDF to cloud storage ($e).',
        originalError: e,
      );
    }
  }

  @override
  Future<Uint8List?> getFileBytes(String storagePath) async {
    final cleanPath = normalizeStoragePath(storagePath);
    if (cleanPath.isEmpty) return null;

    if (!_isReady) {
      debugPrint('[SupabaseStorageService] getFileBytes skipped: Supabase client is not configured with a valid key.');
      return null;
    }

    debugPrint('[SupabaseStorageService] Fetching file bytes: bucket=$_bucket, path=$cleanPath');

    // 1. Attempt direct download via client
    try {
      final bytes = await _storage.download(cleanPath);
      if (bytes.isNotEmpty) {
        debugPrint('[SupabaseStorageService] Direct SDK download success: $cleanPath (${bytes.length} bytes)');
        return bytes;
      }
    } on StorageException catch (e) {
      debugPrint('[SupabaseStorageService] Direct download StorageException (status: ${e.statusCode}): ${e.message}');
    } catch (e) {
      debugPrint('[SupabaseStorageService] Direct download error: $e');
    }

    // 2. Fallback: Download using signed URL via HTTP GET
    try {
      final signedUrl = await getSignedUrl(cleanPath, expiresIn: const Duration(minutes: 5));
      if (signedUrl != null && signedUrl.isNotEmpty) {
        debugPrint('[SupabaseStorageService] Attempting signed URL HTTP fallback download...');
        final bytes = await _downloadFromSignedUrl(signedUrl);
        if (bytes != null && bytes.isNotEmpty) {
          debugPrint('[SupabaseStorageService] Successfully downloaded bytes via signed URL fallback: $cleanPath (${bytes.length} bytes).');
          return bytes;
        }
      }
    } catch (e) {
      debugPrint('[SupabaseStorageService] Fallback signed URL download error: $e');
    }

    return null;
  }

  Future<Uint8List?> _downloadFromSignedUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      debugPrint('[SupabaseStorageService] Signed URL HTTP response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        debugPrint('[SupabaseStorageService] Signed URL HTTP download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SupabaseStorageService] Error downloading from signed URL: $e');
    }
    return null;
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    // Bucket is private. Always generate a short-lived signed URL.
    return getSignedUrl(storagePath);
  }

  @override
  Future<String?> getSignedUrl(
    String storagePath, {
    Duration? expiresIn,
  }) async {
    final cleanPath = normalizeStoragePath(storagePath);
    if (cleanPath.isEmpty) return null;

    if (!_isReady) {
      debugPrint('[SupabaseStorageService] getSignedUrl skipped: Supabase client is not configured with a valid key.');
      return null;
    }

    try {
      final duration = expiresIn ?? SupabaseConfig.signedUrlDuration;
      final signedUrl = await _storage.createSignedUrl(
        cleanPath,
        duration.inSeconds,
      );
      return signedUrl;
    } on StorageException catch (e) {
      debugPrint('[SupabaseStorageService] Signed URL StorageException (${e.statusCode}): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[SupabaseStorageService] Failed to generate signed URL: $e');
      return null;
    }
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    final cleanPath = normalizeStoragePath(storagePath);
    if (cleanPath.isEmpty) return;

    if (!_isReady) {
      return;
    }

    try {
      await _storage.remove([cleanPath]);
      debugPrint('[SupabaseStorageService] Deleted file from $cleanPath');
    } catch (e) {
      debugPrint('[SupabaseStorageService] Delete error: $e');
    }
  }

  @override
  Future<bool> fileExists(String storagePath) async {
    final cleanPath = normalizeStoragePath(storagePath);
    if (cleanPath.isEmpty) return false;

    if (!_isReady) {
      return false;
    }

    try {
      final idx = cleanPath.lastIndexOf('/');
      final parentDir = idx != -1 ? cleanPath.substring(0, idx) : '';
      final fileName = idx != -1 ? cleanPath.substring(idx + 1) : cleanPath;

      final files = await _storage.list(path: parentDir);
      if (files.any((f) => f.name == fileName)) {
        return true;
      }
    } catch (e) {
      debugPrint('[SupabaseStorageService] fileExists list check: $e');
    }

    try {
      final bytes = await _storage.download(cleanPath);
      if (bytes.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint('[SupabaseStorageService] fileExists download verification check: $e');
    }

    return false;
  }
}
