import 'package:flutter/foundation.dart';
import 'mock_pdf_output_service.dart';
import 'pdf_output_service.dart';

/// Web/Non-IO stub implementation of [WindowsPdfOutputService].
class WindowsPdfOutputService implements PdfOutputService {
  static final WindowsPdfOutputService instance = WindowsPdfOutputService._();
  WindowsPdfOutputService._();
  factory WindowsPdfOutputService() => instance;

  @override
  Future<FileSaveResult> saveGeneratedPdf({
    required String fileName,
    required Uint8List bytes,
    String? customDirectory,
  }) {
    return MockPdfOutputService.instance.saveGeneratedPdf(
      fileName: fileName,
      bytes: bytes,
      customDirectory: customDirectory,
    );
  }

  @override
  Future<FileOpenResult> openPdf(String filePath) {
    return MockPdfOutputService.instance.openPdf(filePath);
  }

  @override
  Future<FileSaveResult> savePdfAs({
    required String defaultFileName,
    required Uint8List bytes,
    String? sourceFilePath,
    String? destinationDirectory,
  }) {
    return MockPdfOutputService.instance.savePdfAs(
      defaultFileName: defaultFileName,
      bytes: bytes,
      sourceFilePath: sourceFilePath,
      destinationDirectory: destinationDirectory,
    );
  }
}
