import 'package:flutter/foundation.dart';
import 'mock_pdf_output_service.dart';
import 'windows_pdf_output_service_stub.dart'
    if (dart.library.io) 'windows_pdf_output_service.dart';

/// Result wrapper for file save operations.
class FileSaveResult {
  final bool isSuccess;
  final String? savedPath;
  final String? fileName;
  final int? fileSizeBytes;
  final bool isCancelled;
  final String? errorMessage;

  const FileSaveResult({
    required this.isSuccess,
    this.savedPath,
    this.fileName,
    this.fileSizeBytes,
    this.isCancelled = false,
    this.errorMessage,
  });

  factory FileSaveResult.success({
    required String savedPath,
    required String fileName,
    required int fileSizeBytes,
  }) {
    return FileSaveResult(
      isSuccess: true,
      savedPath: savedPath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
    );
  }

  factory FileSaveResult.cancelled() {
    return const FileSaveResult(
      isSuccess: false,
      isCancelled: true,
    );
  }

  factory FileSaveResult.failure(String errorMessage) {
    return FileSaveResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Result wrapper for opening a file with the system viewer.
class FileOpenResult {
  final bool isSuccess;
  final String? errorMessage;

  const FileOpenResult({
    required this.isSuccess,
    this.errorMessage,
  });

  factory FileOpenResult.success() => const FileOpenResult(isSuccess: true);
  factory FileOpenResult.failure(String errorMessage) =>
      FileOpenResult(isSuccess: false, errorMessage: errorMessage);
}

/// Abstract contract for outputting, persisting, and opening generated PDF reports on the host platform.
abstract class PdfOutputService {
  static PdfOutputService? _instance;

  /// Returns the singleton instance based on environment / platform.
  static PdfOutputService get instance {
    if (_instance != null) return _instance!;

    const bool devMode = bool.fromEnvironment('DOCTOR_DEV_MODE', defaultValue: false);
    if (kIsWeb || kDebugMode && !devMode && !defaultTargetPlatform.name.contains('windows')) {
      _instance = MockPdfOutputService.instance;
    } else {
      _instance = WindowsPdfOutputService.instance;
    }
    return _instance!;
  }

  @visibleForTesting
  static set instance(PdfOutputService? service) {
    _instance = service;
  }

  /// Saves the generated PDF bytes to the default application-safe documents directory.
  Future<FileSaveResult> saveGeneratedPdf({
    required String fileName,
    required Uint8List bytes,
    String? customDirectory,
  });

  /// Opens the PDF file with the default OS registered PDF viewer application.
  Future<FileOpenResult> openPdf(String filePath);

  /// Saves the generated PDF to a target directory or chosen location (Save As).
  Future<FileSaveResult> savePdfAs({
    required String defaultFileName,
    required Uint8List bytes,
    String? sourceFilePath,
    String? destinationDirectory,
  });
}
