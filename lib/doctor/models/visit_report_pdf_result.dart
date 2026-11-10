import 'dart:typed_data';

/// Immutable result model representing the outcome of a Visit Report PDF generation and save operation.
class VisitReportPdfResult {
  final bool isSuccess;
  final String? filePath;
  final String? fileName;
  final int? fileSizeBytes;
  final Uint8List? pdfBytes;
  final String? errorCode;
  final String? errorMessage;
  final bool isDevelopmentMock;

  // Cloud Storage Metadata (Phase D17)
  final String? cloudStoragePath;
  final bool isCloudUploaded;
  final String? cloudUploadError;

  const VisitReportPdfResult({
    required this.isSuccess,
    this.filePath,
    this.fileName,
    this.fileSizeBytes,
    this.pdfBytes,
    this.errorCode,
    this.errorMessage,
    this.isDevelopmentMock = false,
    this.cloudStoragePath,
    this.isCloudUploaded = false,
    this.cloudUploadError,
  });

  /// Factory constructor for a successful PDF generation and file write.
  factory VisitReportPdfResult.success({
    required String filePath,
    required String fileName,
    required int fileSizeBytes,
    required Uint8List pdfBytes,
    bool isDevelopmentMock = false,
    String? cloudStoragePath,
    bool isCloudUploaded = false,
    String? cloudUploadError,
  }) {
    return VisitReportPdfResult(
      isSuccess: true,
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      pdfBytes: pdfBytes,
      isDevelopmentMock: isDevelopmentMock,
      cloudStoragePath: cloudStoragePath,
      isCloudUploaded: isCloudUploaded,
      cloudUploadError: cloudUploadError,
    );
  }

  /// Factory constructor for a failed PDF generation or file write.
  factory VisitReportPdfResult.failure({
    required String errorMessage,
    String? errorCode,
    String? fileName,
  }) {
    return VisitReportPdfResult(
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode ?? 'PDF_GENERATION_FAILED',
      fileName: fileName,
    );
  }

  VisitReportPdfResult copyWith({
    bool? isSuccess,
    String? filePath,
    String? fileName,
    int? fileSizeBytes,
    Uint8List? pdfBytes,
    String? errorCode,
    String? errorMessage,
    bool? isDevelopmentMock,
    String? cloudStoragePath,
    bool? isCloudUploaded,
    String? cloudUploadError,
  }) {
    return VisitReportPdfResult(
      isSuccess: isSuccess ?? this.isSuccess,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      isDevelopmentMock: isDevelopmentMock ?? this.isDevelopmentMock,
      cloudStoragePath: cloudStoragePath ?? this.cloudStoragePath,
      isCloudUploaded: isCloudUploaded ?? this.isCloudUploaded,
      cloudUploadError: cloudUploadError ?? this.cloudUploadError,
    );
  }

  /// Helper to return human-readable file size in KB.
  String get fileSizeKb {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return '0 KB';
    return '${(fileSizeBytes! / 1024).round()} KB';
  }

  @override
  String toString() {
    return 'VisitReportPdfResult(isSuccess: $isSuccess, fileName: $fileName, filePath: $filePath, size: $fileSizeBytes bytes, cloudUploaded: $isCloudUploaded, cloudPath: $cloudStoragePath, error: $errorMessage)';
  }
}
