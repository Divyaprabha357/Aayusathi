import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Result of the developer-only Firestore read/write connection test.
class DevConnectionTestResult {
  final bool isWriteSuccess;
  final bool isReadSuccess;
  final String? testDocumentId;
  final String? errorCode;
  final String? errorMessage;

  const DevConnectionTestResult({
    required this.isWriteSuccess,
    required this.isReadSuccess,
    this.testDocumentId,
    this.errorCode,
    this.errorMessage,
  });

  bool get isFullSuccess => isWriteSuccess && isReadSuccess;

  @override
  String toString() {
    if (isFullSuccess) {
      return 'DevConnectionTestResult(WRITE SUCCESS, READ SUCCESS, doc: $testDocumentId)';
    }
    return 'DevConnectionTestResult(write: $isWriteSuccess, read: $isReadSuccess, error: $errorCode - $errorMessage)';
  }
}

/// Diagnostic service to safely verify live Cloud Firestore connectivity.
///
/// Executes a single controlled write and read back on the `dev_connection_tests` collection.
/// Strictly contains zero patient information, zero Aadhaar, zero OTP, and zero clinical data.
class DevFirestoreConnectionTestService {
  static const String testCollection = 'dev_connection_tests';

  /// Runs a controlled Firestore write followed by a read-back.
  static Future<DevConnectionTestResult> runTest({FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final testDocId = 'test_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('[AAYUSATHI] Dev connection test: Attempting write to $testCollection/$testDocId');

    // 1. Attempt Write
    try {
      await db.collection(testCollection).doc(testDocId).set({
        'testType': 'AAYUSATHI_FIRESTORE_CONNECTION_TEST',
        'application': 'AAYUSATHI',
        'environment': 'windows-development',
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[AAYUSATHI] Dev connection test: WRITE SUCCESS');
    } on FirebaseException catch (e) {
      debugPrint('[AAYUSATHI] Dev connection test: WRITE FAILED');
      debugPrint('[AAYUSATHI] Firestore write failed: ${e.code} - ${e.message}');
      return DevConnectionTestResult(
        isWriteSuccess: false,
        isReadSuccess: false,
        testDocumentId: testDocId,
        errorCode: e.code,
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('[AAYUSATHI] Dev connection test: WRITE FAILED with unexpected error: $e');
      return DevConnectionTestResult(
        isWriteSuccess: false,
        isReadSuccess: false,
        testDocumentId: testDocId,
        errorCode: 'UNKNOWN_ERROR',
        errorMessage: e.toString(),
      );
    }

    // 2. Attempt Read Back
    try {
      final snapshot = await db.collection(testCollection).doc(testDocId).get();
      if (snapshot.exists && snapshot.data() != null) {
        debugPrint('[AAYUSATHI] Dev connection test: READ SUCCESS');
        return DevConnectionTestResult(
          isWriteSuccess: true,
          isReadSuccess: true,
          testDocumentId: testDocId,
        );
      } else {
        debugPrint('[AAYUSATHI] Dev connection test: READ FAILED (document not found)');
        return DevConnectionTestResult(
          isWriteSuccess: true,
          isReadSuccess: false,
          testDocumentId: testDocId,
          errorCode: 'DOCUMENT_NOT_FOUND',
          errorMessage: 'Written test document was not found on read back.',
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('[AAYUSATHI] Dev connection test: READ FAILED: ${e.code} - ${e.message}');
      return DevConnectionTestResult(
        isWriteSuccess: true,
        isReadSuccess: false,
        testDocumentId: testDocId,
        errorCode: e.code,
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('[AAYUSATHI] Dev connection test: READ FAILED with unexpected error: $e');
      return DevConnectionTestResult(
        isWriteSuccess: true,
        isReadSuccess: false,
        testDocumentId: testDocId,
        errorCode: 'UNKNOWN_READ_ERROR',
        errorMessage: e.toString(),
      );
    }
  }
}
