import 'dart:io';
import 'package:flutter/foundation.dart';
import 'pdf_output_service.dart';

/// Concrete Windows and cross-platform desktop implementation of [PdfOutputService].
///
/// Features:
/// - Persists generated PDFs to user-accessible documents directory without admin privileges.
/// - Validates file existence, non-zero size, and `%PDF` magic header.
/// - Opens PDFs using the Windows default system viewer via shell execution.
/// - Supports Save-As functionality allowing copying/saving to user-selected locations (e.g. Desktop).
class WindowsPdfOutputService implements PdfOutputService {
  static final WindowsPdfOutputService instance = WindowsPdfOutputService._();
  WindowsPdfOutputService._();
  factory WindowsPdfOutputService() => instance;

  /// Resolves the default safe application output directory.
  /// `%USERPROFILE%\Documents\AAYUSATHI\VisitReports` or `%TEMP%\AAYUSATHI\VisitReports`.
  Directory get defaultOutputDirectory {
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        final docsDir = Directory('$userProfile\\Documents\\AAYUSATHI\\VisitReports');
        return docsDir;
      }
    } catch (_) {}

    // Fallback to system temp directory
    return Directory('${Directory.systemTemp.path}\\AAYUSATHI\\VisitReports');
  }

  /// Resolves the user Desktop directory for Save As shortcuts.
  Directory get userDesktopDirectory {
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        final desktop = Directory('$userProfile\\Desktop');
        if (desktop.existsSync()) return desktop;
      }
    } catch (_) {}
    return defaultOutputDirectory;
  }

  @override
  Future<FileSaveResult> saveGeneratedPdf({
    required String fileName,
    required Uint8List bytes,
    String? customDirectory,
  }) async {
    if (bytes.isEmpty) {
      return FileSaveResult.failure('Cannot save empty PDF bytes.');
    }

    // Verify %PDF magic header
    if (!_isValidPdfBytes(bytes)) {
      return FileSaveResult.failure('Generated file does not contain valid PDF headers.');
    }

    try {
      final targetDir = customDirectory != null
          ? Directory(customDirectory)
          : defaultOutputDirectory;

      if (!targetDir.existsSync()) {
        await targetDir.create(recursive: true);
      }

      final sanitizedName = _sanitizeFileName(fileName);
      final filePath = '${targetDir.path}${Platform.pathSeparator}$sanitizedName';
      final file = File(filePath);

      await file.writeAsBytes(bytes, flush: true);

      // Verify file actually exists and is non-empty on disk
      if (!file.existsSync() || file.lengthSync() == 0) {
        return FileSaveResult.failure('Failed to verify written PDF file on disk.');
      }

      debugPrint('[WindowsPdfOutputService] PDF successfully written to $filePath (${file.lengthSync()} bytes)');

      return FileSaveResult.success(
        savedPath: file.path,
        fileName: sanitizedName,
        fileSizeBytes: file.lengthSync(),
      );
    } catch (e) {
      debugPrint('[WindowsPdfOutputService] File write error: $e');
      return FileSaveResult.failure('Error saving PDF to disk: $e');
    }
  }

  @override
  Future<FileOpenResult> openPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return FileOpenResult.failure('PDF file does not exist at path: $filePath');
      }

      debugPrint('[WindowsPdfOutputService] Opening PDF: $filePath');

      if (Platform.isWindows) {
        // Use cmd start to launch default registered PDF application
        final result = await Process.run(
          'cmd',
          ['/c', 'start', '""', filePath],
          runInShell: true,
        );

        if (result.exitCode != 0) {
          debugPrint('[WindowsPdfOutputService] cmd start returned exit code ${result.exitCode}: ${result.stderr}');
          // Fallback to powershell Start-Process
          final psResult = await Process.run(
            'powershell',
            ['-Command', 'Start-Process', '-FilePath', '"$filePath"'],
            runInShell: true,
          );
          if (psResult.exitCode != 0) {
            return FileOpenResult.failure(
              'PDF was created, but Windows could not open the file. Error code: ${psResult.exitCode}',
            );
          }
        }
        return FileOpenResult.success();
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
        return FileOpenResult.success();
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
        return FileOpenResult.success();
      } else {
        return FileOpenResult.failure('Unsupported operating system for automatic PDF opening.');
      }
    } catch (e) {
      debugPrint('[WindowsPdfOutputService] Error opening PDF: $e');
      return FileOpenResult.failure('PDF was created, but Windows could not open the file: $e');
    }
  }

  @override
  Future<FileSaveResult> savePdfAs({
    required String defaultFileName,
    required Uint8List bytes,
    String? sourceFilePath,
    String? destinationDirectory,
  }) async {
    try {
      final sanitizedName = _sanitizeFileName(defaultFileName);
      final destDir = destinationDirectory != null
          ? Directory(destinationDirectory)
          : userDesktopDirectory;

      if (!destDir.existsSync()) {
        await destDir.create(recursive: true);
      }

      final targetPath = '${destDir.path}${Platform.pathSeparator}$sanitizedName';

      // If source file already exists, copy it; otherwise write bytes
      if (sourceFilePath != null && File(sourceFilePath).existsSync()) {
        await File(sourceFilePath).copy(targetPath);
      } else {
        await File(targetPath).writeAsBytes(bytes, flush: true);
      }

      final savedFile = File(targetPath);
      if (!savedFile.existsSync() || savedFile.lengthSync() == 0) {
        return FileSaveResult.failure('Failed to verify saved copy on disk.');
      }

      debugPrint('[WindowsPdfOutputService] Save-As completed: $targetPath');
      return FileSaveResult.success(
        savedPath: savedFile.path,
        fileName: sanitizedName,
        fileSizeBytes: savedFile.lengthSync(),
      );
    } catch (e) {
      debugPrint('[WindowsPdfOutputService] Save-As error: $e');
      return FileSaveResult.failure('Could not save PDF to destination: $e');
    }
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
