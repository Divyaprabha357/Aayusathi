import 'package:flutter/foundation.dart';
import 'pdf_output_service.dart';

/// In-memory mock implementation of [PdfOutputService] for testing and simulation.
class MockPdfOutputService implements PdfOutputService {
  static final MockPdfOutputService instance = MockPdfOutputService._();
  MockPdfOutputService._();
  factory MockPdfOutputService() => instance;

  final Map<String, Uint8List> savedFiles = {};
  final List<String> openedFiles = [];
  final Map<String, Uint8List> savedAsFiles = {};

  // Simulation controls
  bool simulateWriteFailure = false;
  String? writeErrorMessage;
  bool simulateOpenFailure = false;
  String? openErrorMessage;
  bool simulateSaveAsCancelled = false;
  bool simulateSaveAsFailure = false;
  String? saveAsErrorMessage;

  void reset() {
    savedFiles.clear();
    openedFiles.clear();
    savedAsFiles.clear();
    simulateWriteFailure = false;
    writeErrorMessage = null;
    simulateOpenFailure = false;
    openErrorMessage = null;
    simulateSaveAsCancelled = false;
    simulateSaveAsFailure = false;
    saveAsErrorMessage = null;
  }

  @override
  Future<FileSaveResult> saveGeneratedPdf({
    required String fileName,
    required Uint8List bytes,
    String? customDirectory,
  }) async {
    if (simulateWriteFailure) {
      return FileSaveResult.failure(
        writeErrorMessage ?? 'Simulated disk write failure.',
      );
    }

    if (bytes.isEmpty) {
      return FileSaveResult.failure('Cannot save empty PDF bytes.');
    }

    if (!_isValidPdfBytes(bytes)) {
      return FileSaveResult.failure('Generated file does not contain valid PDF headers.');
    }

    final sanitizedName = _sanitizeFileName(fileName);
    final mockPath = 'C:\\Users\\MockUser\\Documents\\AAYUSATHI\\VisitReports\\$sanitizedName';

    savedFiles[mockPath] = bytes;
    debugPrint('[MockPdfOutputService] Saved mock PDF to $mockPath (${bytes.length} bytes)');

    return FileSaveResult.success(
      savedPath: mockPath,
      fileName: sanitizedName,
      fileSizeBytes: bytes.length,
    );
  }

  @override
  Future<FileOpenResult> openPdf(String filePath) async {
    if (simulateOpenFailure) {
      return FileOpenResult.failure(
        openErrorMessage ?? 'PDF was created, but Windows could not open the file.',
      );
    }

    if (!savedFiles.containsKey(filePath)) {
      return FileOpenResult.failure('PDF file does not exist at path: $filePath');
    }

    openedFiles.add(filePath);
    debugPrint('[MockPdfOutputService] Opened mock PDF: $filePath');
    return FileOpenResult.success();
  }

  @override
  Future<FileSaveResult> savePdfAs({
    required String defaultFileName,
    required Uint8List bytes,
    String? sourceFilePath,
    String? destinationDirectory,
  }) async {
    if (simulateSaveAsCancelled) {
      return FileSaveResult.cancelled();
    }

    if (simulateSaveAsFailure) {
      return FileSaveResult.failure(
        saveAsErrorMessage ?? 'Simulated Save-As write error.',
      );
    }

    final sanitizedName = _sanitizeFileName(defaultFileName);
    final targetPath = 'C:\\Users\\MockUser\\Desktop\\$sanitizedName';

    savedAsFiles[targetPath] = bytes;
    debugPrint('[MockPdfOutputService] Mock Save-As to $targetPath (${bytes.length} bytes)');

    return FileSaveResult.success(
      savedPath: targetPath,
      fileName: sanitizedName,
      fileSizeBytes: bytes.length,
    );
  }

  bool _isValidPdfBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46; // %PDF
  }

  String _sanitizeFileName(String name) {
    var sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (!sanitized.toLowerCase().endsWith('.pdf')) {
      sanitized = '$sanitized.pdf';
    }
    return sanitized;
  }
}
