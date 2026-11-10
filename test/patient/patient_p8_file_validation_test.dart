import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/patient/services/patient_report_file_validator.dart';

void main() {
  group('Patient App P8: File Validation & Security Tests', () {
    // 1. JPG accepted
    test('1. Valid JPG with JPEG magic bytes is accepted', () {
      final validJpgBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46];
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'blood_test_report.jpg',
        bytes: validJpgBytes,
        declaredMimeType: 'image/jpeg',
      );

      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'image/jpeg');
      expect(res.errorMessage, isNull);
    });

    // 2. JPEG accepted
    test('2. Valid JPEG with JPEG magic bytes is accepted', () {
      final validJpegBytes = [0xFF, 0xD8, 0xFF, 0xDB, 0x00, 0x43];
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'mri_scan.jpeg',
        bytes: validJpegBytes,
      );

      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'image/jpeg');
    });

    // 3. PNG accepted
    test('3. Valid PNG with PNG magic bytes is accepted', () {
      final validPngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00];
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'ecg_graph.png',
        bytes: validPngBytes,
        declaredMimeType: 'image/png',
      );

      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'image/png');
    });

    // 4. PDF rejected if photo-only P8
    test('4. PDF file is explicitly rejected for photo upload with medical guidance', () {
      final pdfBytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]; // %PDF
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'lab_results.pdf',
        bytes: pdfBytes,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('PDF documents are not supported'));
      expect(res.errorMessage, contains('JPG or PNG'));
    });

    // Also test spoofed PDF renamed to .jpg
    test('4b. Spoofed PDF with .jpg extension is rejected by magic byte inspection', () {
      final pdfBytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]; // %PDF
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'spoofed_document.jpg',
        bytes: pdfBytes,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('PDF documents are not supported'));
    });

    // 5. Unsupported MIME rejected
    test('5. Unsupported declared MIME type is rejected', () {
      final validJpgBytes = [0xFF, 0xD8, 0xFF, 0xE0];
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'report.jpg',
        bytes: validJpgBytes,
        declaredMimeType: 'application/octet-stream',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Unsupported content type'));
    });

    // 6. Invalid magic bytes rejected
    test('6. Corrupted or invalid magic bytes for JPEG are rejected', () {
      final corruptBytes = [0x00, 0x01, 0x02, 0x03];
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'corrupt.jpg',
        bytes: corruptBytes,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('File header mismatch: Not a valid JPEG image'));
    });

    test('6b. Corrupted or invalid magic bytes for PNG are rejected', () {
      final corruptBytes = [0x89, 0x00, 0x00, 0x00];
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'corrupt.png',
        bytes: corruptBytes,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('File header mismatch: Not a valid PNG image'));
    });

    test('6c. Executable and ZIP binaries are rejected', () {
      final exeBytes = [0x4D, 0x5A, 0x90, 0x00]; // MZ
      final resExe = PatientReportFileValidator.validateReportPhoto(
        fileName: 'malicious.exe',
        bytes: exeBytes,
      );
      expect(resExe.isValid, isFalse);

      final zipBytes = [0x50, 0x4B, 0x03, 0x04]; // PK..
      final resZip = PatientReportFileValidator.validateReportPhoto(
        fileName: 'archive.zip',
        bytes: zipBytes,
      );
      expect(resZip.isValid, isFalse);
    });

    // 7. >15MB rejected
    test('7. File exceeding 15 MB limit is rejected', () {
      final largeBytes = Uint8List(15 * 1024 * 1024 + 1);
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'huge_photo.jpg',
        bytes: largeBytes,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('15 MB limit'));
    });

    test('7b. Empty file is rejected', () {
      final res = PatientReportFileValidator.validateReportPhoto(
        fileName: 'empty.jpg',
        bytes: [],
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('File is empty'));
    });

    // 8. Safe filename generation
    test('8. Safe filename generation creates sanitized, deterministic string', () {
      final safeName = PatientReportFileValidator.generateSafeFileName(
        patientId: 'PAT 001/evil',
        investigationId: 'INV-CBC 01',
        extension: '.jpeg',
        timestamp: 1726000000000,
        randomSuffix: 'a1b2',
      );

      expect(safeName, 'AAYU_PAT001EVIL_INV_INVCBC01_1726000000000_a1b2.jpg');
      expect(safeName.contains('/'), isFalse);
      expect(safeName.contains('\\'), isFalse);
      expect(safeName.contains(' '), isFalse);
    });

    // 9. Path traversal rejected
    test('9. Path traversal attempts in file names are detected and rejected', () {
      final validJpgBytes = [0xFF, 0xD8, 0xFF, 0xE0];
      final res1 = PatientReportFileValidator.validateReportPhoto(
        fileName: '../../etc/passwd.jpg',
        bytes: validJpgBytes,
      );
      expect(res1.isValid, isFalse);
      expect(res1.errorMessage, contains('Path traversal'));

      final res2 = PatientReportFileValidator.validateReportPhoto(
        fileName: '..\\..\\windows\\system32\\cmd.jpg',
        bytes: validJpgBytes,
      );
      expect(res2.isValid, isFalse);
      expect(res2.errorMessage, contains('Path traversal'));
    });

    test('9b. Canonical storage path is constructed securely', () {
      final path = PatientReportFileValidator.generateCanonicalStoragePath(
        patientId: 'pat-001',
        caseId: 'case-01',
        visitId: 'vis-01',
        investigationId: 'inv-ecg',
        safeFileName: 'AAYU_report.jpg',
      );

      expect(
        path,
        'patients/PAT-001/cases/case-01/visits/vis-01/reports/AAYU_report.jpg',
      );
    });
  });
}
