import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/supabase/supabase_config.dart';
import 'package:aayusathi/core/supabase/supabase_initializer.dart';
import 'package:aayusathi/doctor/services/supabase_storage_service.dart';

// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AAYUSATHI Live Supabase Storage Verification', () {
    const livePatientId = 'AAYU-102938';
    const liveCaseId = 'CASE-1792347755951';
    const liveVisitId = 'VIS-CASE-1792347755951-1-1792347767790';
    const liveReportFileName = 'AAYU_AAYU102938_INV_REQINV1792372462336_1792372602692_kxmm.jpg';
    const liveCanonicalPath =
        'patients/$livePatientId/cases/$liveCaseId/visits/$liveVisitId/reports/$liveReportFileName';

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      HttpOverrides.global = null;
      final initResult = await SupabaseInitializer.initialize();
      expect(initResult.isInitialized, isTrue);
    });

    test('1. SupabaseConfig contains genuine publishable key and is live cloud ready', () {
      expect(SupabaseConfig.isConfigValid, isTrue);
      expect(SupabaseConfig.isPlaceholderKey, isFalse);
      expect(SupabaseConfig.isLiveCloudReady, isTrue);
      expect(SupabaseConfig.bucketName, equals('aayusathi-reports'));
      expect(SupabaseConfig.isPrivateBucket, isTrue);
      expect(SupabaseConfig.supabaseUrl, equals('https://xtgjpvejqzptjyrskuuk.supabase.co'));
    });

    test('2. Live storage confirms existence of patient-uploaded report in private bucket', () async {
      final service = SupabaseStorageService();
      final exists = await service.fileExists(liveCanonicalPath);
      expect(exists, isTrue, reason: 'Report file must physically exist in private bucket');
    });

    test('3. Doctor generates time-limited signed URL for authorized private report', () async {
      final service = SupabaseStorageService();
      final signedUrl = await service.getSignedUrl(liveCanonicalPath, expiresIn: const Duration(minutes: 5));
      expect(signedUrl, isNotNull);
      expect(signedUrl, startsWith('https://xtgjpvejqzptjyrskuuk.supabase.co/storage/v1/object/sign/aayusathi-reports/'));
      expect(signedUrl, contains('token='));
    });

    test('4. Doctor downloads exact 528642 bytes and validates JPEG magic header', () async {
      final service = SupabaseStorageService();
      final bytes = await service.getFileBytes(liveCanonicalPath);
      expect(bytes, isNotNull);
      expect(bytes!.length, equals(528642));
      // Validate JPEG header: 0xFF, 0xD8, 0xFF
      expect(bytes[0], equals(0xFF));
      expect(bytes[1], equals(0xD8));
      expect(bytes[2], equals(0xFF));
    });

    test('5. Non-existent path returns fileExists false and getFileBytes null gracefully', () async {
      final service = SupabaseStorageService();
      const nonExistentPath = 'patients/$livePatientId/cases/$liveCaseId/visits/$liveVisitId/reports/non_existent_file_99999.pdf';
      final exists = await service.fileExists(nonExistentPath);
      expect(exists, isFalse);

      final bytes = await service.getFileBytes(nonExistentPath);
      expect(bytes, isNull);
    });

    test('6. Real upload, confirmation, and retrieval cycle for new report document', () async {
      final service = SupabaseStorageService();
      final sampleTimestamp = DateTime.now().millisecondsSinceEpoch;
      final testUploadFileName = 'AAYU_AAYU102938_INV_TEST_$sampleTimestamp.jpg';
      final testUploadPath = 'patients/$livePatientId/cases/$liveCaseId/visits/$liveVisitId/reports/$testUploadFileName';

      // Minimal valid JPEG binary
      final sampleJpgBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
        0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09,
        0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x7F, 0x00,
        0xFF, 0xD9
      ]);

      // Step 1: Upload
      final uploadedPath = await service.uploadReportFile(
        patientId: livePatientId,
        caseId: liveCaseId,
        visitId: liveVisitId,
        investigationId: 'TEST',
        fileName: testUploadFileName,
        bytes: sampleJpgBytes,
        contentType: 'image/jpeg',
      );
      expect(uploadedPath, equals(testUploadPath));

      // Step 2: Confirm physical persistence
      final exists = await service.fileExists(uploadedPath);
      expect(exists, isTrue);

      // Step 3: Download and verify exact bytes
      final downloadedBytes = await service.getFileBytes(uploadedPath);
      expect(downloadedBytes, isNotNull);
      expect(downloadedBytes!.length, equals(sampleJpgBytes.length));
      expect(downloadedBytes, equals(sampleJpgBytes));

      // Step 4: Cleanup
      await service.deleteFile(uploadedPath);
    });
  });
}
