import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../doctor/models/higher_authority_assignment.dart';
import '../case_repository.dart';

/// Cloud Firestore implementation of [CaseRepository].
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}`
///
/// Security:
/// - Strictly authorized doctor access.
/// - Zero Aadhaar stored.
class FirebaseCaseRepository implements CaseRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseCaseRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  String _normalizePatientId(String rawId) {
    final clean = rawId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    if (clean.isEmpty) return clean;
    return clean.startsWith('AAYU-') ? clean : 'AAYU-$clean';
  }

  CollectionReference<Map<String, dynamic>> _getCasesCollection(String patientId) {
    final cleanPatientId = _normalizePatientId(patientId);
    return _firestore
        .collection(FirebaseConfig.patientsCollection)
        .doc(cleanPatientId)
        .collection('cases');
  }

  @override
  Future<List<ClinicalCase>> getCasesForPatient(String patientId) async {
    final cleanPatientId = _normalizePatientId(patientId);
    if (cleanPatientId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _getCasesCollection(cleanPatientId).get();
      final List<ClinicalCase> cases = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          cases.add(ClinicalCase.fromFirestore(data, doc.id));
        } catch (parseError) {
          debugPrint('[FirebaseCaseRepository] Warning: Failed to parse clinical case ${doc.id}: $parseError');
        }
      }

      // If no cases were found and original ID didn't start with AAYU-, also check raw ID if different
      final rawClean = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
      if (cases.isEmpty && rawClean != cleanPatientId && rawClean.isNotEmpty) {
        try {
          final rawSnapshot = await _firestore
              .collection(FirebaseConfig.patientsCollection)
              .doc(rawClean)
              .collection('cases')
              .get();
          for (final doc in rawSnapshot.docs) {
            try {
              cases.add(ClinicalCase.fromFirestore(doc.data(), doc.id));
            } catch (parseError) {
              debugPrint('[FirebaseCaseRepository] Warning: Failed to parse fallback case ${doc.id}: $parseError');
            }
          }
        } catch (_) {
          // Ignore secondary check failure
        }
      }

      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cases;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on getCasesForPatient: code=${e.code}, message=${e.message}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not retrieve patient clinical cases from Firestore.',
        originalError: e,
      );
    } catch (e, stack) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on getCasesForPatient: $e\n$stack');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to load clinical cases.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalCase?> getCaseById({
    required String patientId,
    required String caseId,
  }) async {
    try {
      var doc = await _getCasesCollection(patientId).doc(caseId).get();
      if (!doc.exists || doc.data() == null) {
        final clean = _normalizePatientId(patientId);
        final rawClean = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
        final fallbackId = rawClean.startsWith('AAYU-') ? rawClean.replaceFirst('AAYU-', '') : rawClean;
        if (fallbackId.isNotEmpty && fallbackId != clean) {
          try {
            final fallbackDoc = await _firestore
                .collection(FirebaseConfig.patientsCollection)
                .doc(fallbackId)
                .collection('cases')
                .doc(caseId)
                .get();
            if (fallbackDoc.exists && fallbackDoc.data() != null) {
              doc = fallbackDoc;
            }
          } catch (_) {}
        }
      }
      if (!doc.exists || doc.data() == null) return null;
      return ClinicalCase.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not fetch case from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalCase> createCase(ClinicalCase clinicalCase) async {
    final docId = clinicalCase.caseId.isNotEmpty
        ? clinicalCase.caseId
        : 'CASE-${clinicalCase.patientId}-${DateTime.now().millisecondsSinceEpoch}';

    final created = clinicalCase.copyWith(
      caseId: docId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: ClinicalCaseStatus.open,
    );

    try {
      await _getCasesCollection(created.patientId)
          .doc(docId)
          .set(created.toFirestore(), SetOptions(merge: true));
      return created;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not create clinical case in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateCase(ClinicalCase clinicalCase) async {
    final updated = clinicalCase.copyWith(updatedAt: DateTime.now());
    try {
      await _getCasesCollection(updated.patientId)
          .doc(updated.caseId)
          .set(updated.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not update clinical case in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalCase> closeCase({
    required String patientId,
    required String caseId,
    required String doctorId,
    String? doctorName,
    required String closureNote,
  }) async {
    final docRef = _getCasesCollection(patientId).doc(caseId);
    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw BackendException(
            code: BackendException.notFound,
            message: 'Clinical case not found.',
          );
        }
        final existing = ClinicalCase.fromFirestore(snapshot.data()!, snapshot.id);
        if (existing.isClosed) {
          throw BackendException(
            code: BackendException.invalidData,
            message: 'Clinical case is already closed.',
          );
        }
        if (closureNote.trim().isEmpty) {
          throw BackendException(
            code: BackendException.invalidData,
            message: 'Doctor closure note is required.',
          );
        }

        final now = DateTime.now();
        final closedCase = existing.copyWith(
          status: ClinicalCaseStatus.closed,
          closedAt: now,
          closedByDoctorId: doctorId,
          closedByDoctorName: doctorName ?? 'Attending Doctor',
          closureNote: closureNote.trim(),
          updatedAt: now,
        );

        transaction.set(docRef, closedCase.toFirestore(), SetOptions(merge: true));
        return closedCase;
      });
    } on BackendException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on closeCase: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not close clinical case in Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on closeCase: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to close clinical case.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ClinicalCase>> getAllCases() async {
    try {
      final snapshot = await _firestore.collectionGroup('cases').get();
      final cases = snapshot.docs
          .map((doc) => ClinicalCase.fromFirestore(doc.data(), doc.id))
          .toList();
      cases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return cases;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on getAllCases: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not retrieve all cases from Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on getAllCases: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to load clinical cases repository.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ClinicalCase>> getCasesForDoctor(String doctorId) async {
    final cleanDoctorId = doctorId.trim();
    if (cleanDoctorId.isEmpty) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Doctor ID cannot be empty.',
      );
    }

    try {
      final Map<String, ClinicalCase> casesMap = {};
      final Set<String> processedCaseKeys = {};

      void addCase(ClinicalCase c) {
        if (!casesMap.containsKey(c.caseId)) {
          casesMap[c.caseId] = c;
        }
      }

      // 1. Query visits where doctor conducted or completed the encounter
      final visitSnap = await _firestore
          .collectionGroup('visits')
          .where('doctorId', isEqualTo: cleanDoctorId)
          .get();

      // Pair of (patientId, caseId)
      final List<MapEntry<String, String>> patientCasePairs = [];

      for (final doc in visitSnap.docs) {
        final data = doc.data();
        String? pId = data['patientId'] as String?;
        String? cId = data['caseId'] as String?;

        // Fallback to path hierarchy: patients/{patientId}/cases/{caseId}/visits/{visitId}
        if ((pId == null || pId.isEmpty) || (cId == null || cId.isEmpty)) {
          final segments = doc.reference.path.split('/');
          if (segments.length >= 6 && segments[0] == 'patients' && segments[2] == 'cases') {
            pId ??= segments[1];
            cId ??= segments[3];
          }
        }

        if (pId != null && pId.isNotEmpty && cId != null && cId.isNotEmpty) {
          final key = '$pId::$cId';
          if (processedCaseKeys.add(key)) {
            patientCasePairs.add(MapEntry(pId, cId));
          }
        }
      }

      // 2. Query cases closed by this doctor
      final closedSnap = await _firestore
          .collectionGroup('cases')
          .where('closedByDoctorId', isEqualTo: cleanDoctorId)
          .get();

      for (final doc in closedSnap.docs) {
        final c = ClinicalCase.fromFirestore(doc.data(), doc.id);
        addCase(c);
        processedCaseKeys.add('${c.patientId}::${c.caseId}');
      }

      // 3. Query cases assigned to this doctor under higher authority
      final assignedSnap = await _firestore
          .collectionGroup('cases')
          .where('higherAuthorityDoctorId', isEqualTo: cleanDoctorId)
          .get();

      for (final doc in assignedSnap.docs) {
        final c = ClinicalCase.fromFirestore(doc.data(), doc.id);
        addCase(c);
        processedCaseKeys.add('${c.patientId}::${c.caseId}');
      }

      // 4. Query cases escalated by this doctor
      try {
        final escalatedSnap = await _firestore
            .collectionGroup('cases')
            .where('escalatedByDoctorId', isEqualTo: cleanDoctorId)
            .get();

        for (final doc in escalatedSnap.docs) {
          final c = ClinicalCase.fromFirestore(doc.data(), doc.id);
          addCase(c);
          processedCaseKeys.add('${c.patientId}::${c.caseId}');
        }
      } catch (e) {
        debugPrint('[FirebaseCaseRepository] Non-fatal: escalated cases query skipped: $e');
      }

      // 5. Query transfers where this doctor is source or destination doctor
      try {
        final sourceTransfersSnap = await _firestore
            .collection('transfers')
            .where('sourceDoctorId', isEqualTo: cleanDoctorId)
            .get();
        for (final doc in sourceTransfersSnap.docs) {
          final pId = doc.data()['patientId'] as String?;
          final cId = doc.data()['caseId'] as String?;
          if (pId != null && pId.isNotEmpty && cId != null && cId.isNotEmpty) {
            final key = '$pId::$cId';
            if (processedCaseKeys.add(key)) {
              patientCasePairs.add(MapEntry(pId, cId));
            }
          }
        }

        final destTransfersSnap = await _firestore
            .collection('transfers')
            .where('destinationDoctorId', isEqualTo: cleanDoctorId)
            .get();
        for (final doc in destTransfersSnap.docs) {
          final pId = doc.data()['patientId'] as String?;
          final cId = doc.data()['caseId'] as String?;
          if (pId != null && pId.isNotEmpty && cId != null && cId.isNotEmpty) {
            final key = '$pId::$cId';
            if (processedCaseKeys.add(key)) {
              patientCasePairs.add(MapEntry(pId, cId));
            }
          }
        }
      } catch (e) {
        debugPrint('[FirebaseCaseRepository] Non-fatal: transfers query skipped: $e');
      }

      // 6. Fetch specifically authorized cases discovered from visits & transfers
      for (final pair in patientCasePairs) {
        if (casesMap.containsKey(pair.value)) continue;
        try {
          final caseDoc = await _firestore
              .collection('patients')
              .doc(pair.key)
              .collection('cases')
              .doc(pair.value)
              .get();
          if (caseDoc.exists && caseDoc.data() != null) {
            addCase(ClinicalCase.fromFirestore(caseDoc.data()!, caseDoc.id));
          }
        } catch (err) {
          debugPrint('[FirebaseCaseRepository] Error fetching case ${pair.value} for patient ${pair.key}: $err');
        }
      }

      final cases = casesMap.values.toList();
      cases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return cases;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on getCasesForDoctor (${e.code}): ${e.message}');
      String mappedCode;
      String userMessage;

      switch (e.code) {
        case 'permission-denied':
          mappedCode = BackendException.permissionDenied;
          userMessage = 'Firestore permission denied. Doctor is not authorized to read clinical cases.';
          break;
        case 'unauthenticated':
          mappedCode = BackendException.permissionDenied;
          userMessage = 'Doctor authentication session expired. Please log in again.';
          break;
        case 'failed-precondition':
          mappedCode = BackendException.unavailable;
          final msg = (e.message ?? '').toLowerCase();
          if (msg.contains('index')) {
            userMessage = 'Clinical records query requires a Firestore index. Index provisioning in progress.';
          } else {
            userMessage = 'Firestore precondition failed: ${e.message ?? e.code}';
          }
          break;
        case 'unavailable':
        case 'network-request-failed':
          mappedCode = BackendException.networkError;
          userMessage = 'Network unavailable. Please check your connection and retry.';
          break;
        case 'not-found':
          mappedCode = BackendException.notFound;
          userMessage = 'Clinical records not found.';
          break;
        case 'invalid-argument':
          mappedCode = BackendException.invalidData;
          userMessage = 'Invalid clinical records query parameter.';
          break;
        default:
          mappedCode = BackendException.unavailable;
          userMessage = 'Could not retrieve doctor clinical cases: ${e.message ?? e.code}';
      }

      throw BackendException(
        code: mappedCode,
        message: userMessage,
        originalError: e,
      );
    } catch (e) {
      if (e is BackendException) rethrow;
      debugPrint('[FirebaseCaseRepository] Unexpected error on getCasesForDoctor: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to load doctor clinical cases repository: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isDoctorAuthorizedForCase({
    required String doctorId,
    required String caseId,
    required String patientId,
  }) async {
    final cleanDoctorId = doctorId.trim();
    if (cleanDoctorId.isEmpty) return false;
    final cleanDocUpper = cleanDoctorId.toUpperCase();

    try {
      final c = await getCaseById(patientId: patientId, caseId: caseId);
      if (c == null) return false;
      if (c.closedByDoctorId?.toUpperCase() == cleanDocUpper) return true;
      if (c.higherAuthorityDoctorId?.toUpperCase() == cleanDocUpper) return true;
      if (c.escalatedByDoctorId?.toUpperCase() == cleanDocUpper) return true;

      // Check visits under this case via clinicalVisitRepository (handles patient ID normalization & fallbacks)
      try {
        final caseVisits = await BackendProvider.instance.clinicalVisitRepository
            .getVisitsForCase(patientId: patientId, caseId: caseId);
        for (final v in caseVisits) {
          if (v.doctorId.toUpperCase() == cleanDocUpper ||
              v.completedByDoctorId?.toUpperCase() == cleanDocUpper ||
              v.approvedByDoctorId?.toUpperCase() == cleanDocUpper) {
            return true;
          }
        }
      } catch (_) {}

      // Fallback direct visits check
      try {
        final visitsCollection = _getCasesCollection(patientId).doc(caseId).collection('visits');
        final doctorVisitsSnap = await visitsCollection
            .where('doctorId', isEqualTo: cleanDoctorId)
            .limit(1)
            .get();
        if (doctorVisitsSnap.docs.isNotEmpty) return true;

        final completedVisitsSnap = await visitsCollection
            .where('completedByDoctorId', isEqualTo: cleanDoctorId)
            .limit(1)
            .get();
        if (completedVisitsSnap.docs.isNotEmpty) return true;

        final approvedVisitsSnap = await visitsCollection
            .where('approvedByDoctorId', isEqualTo: cleanDoctorId)
            .limit(1)
            .get();
        if (approvedVisitsSnap.docs.isNotEmpty) return true;
      } catch (_) {}

      // Check transfers under this case
      try {
        final transferSnap = await _firestore
            .collection('transfers')
            .where('caseId', isEqualTo: caseId)
            .get();

        for (final doc in transferSnap.docs) {
          final data = doc.data();
          final sourceDoc = (data['sourceDoctorId'] as String?)?.toUpperCase();
          final destDoc = (data['destinationDoctorId'] as String?)?.toUpperCase();
          if (sourceDoc == cleanDocUpper || destDoc == cleanDocUpper) {
            return true;
          }
        }
      } catch (_) {}

      return false;
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] isDoctorAuthorizedForCase error: $e');
      return false;
    }
  }

  @override
  Future<ClinicalCase> escalateCase({
    required String patientId,
    required String caseId,
    required String visitId,
    required String doctorId,
    String? doctorName,
    required CaseEscalationReason reason,
    String? note,
  }) async {
    if (reason == CaseEscalationReason.other &&
        (note == null || note.trim().isEmpty)) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'An explanation is required when selecting "Other" escalation reason.',
      );
    }

    final docRef = _getCasesCollection(patientId).doc(caseId);
    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw const BackendException(
            code: BackendException.notFound,
            message: 'Clinical case not found.',
          );
        }
        final existing = ClinicalCase.fromFirestore(snapshot.data()!, snapshot.id);
        if (existing.isClosed) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'Closed cases cannot be escalated.',
          );
        }
        if (existing.isEscalated) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'This case is already escalated for Admin review.',
          );
        }

        final now = DateTime.now();
        final escalatedCase = existing.copyWith(
          escalationStatus: CaseEscalationStatus.escalated,
          escalationReason: reason,
          escalationNote: note?.trim(),
          escalatedAt: now,
          escalatedByDoctorId: doctorId,
          escalatedByDoctorName: doctorName ?? 'Attending Doctor',
          escalationSourceVisitId: visitId,
          updatedAt: now,
        );

        transaction.set(docRef, escalatedCase.toFirestore(), SetOptions(merge: true));

        // Create audit log document within transaction
        final auditRef = _firestore
            .collection(FirebaseConfig.auditLogsCollection)
            .doc('AUD-ESC-${now.millisecondsSinceEpoch}');
        transaction.set(auditRef, {
          'auditId': 'AUD-ESC-${now.millisecondsSinceEpoch}',
          'actorType': 'DOCTOR',
          'actorId': doctorId,
          'action': 'CASE_ESCALATED',
          'entityType': 'CLINICAL_CASE',
          'entityId': caseId,
          'timestamp': Timestamp.fromDate(now),
          'metadata': {
            'caseId': caseId,
            'patientId': patientId,
            'sourceVisitId': visitId,
            'reason': reason.name,
            'department': existing.domain,
            'oldEscalationStatus': existing.escalationStatus.name,
            'newEscalationStatus': CaseEscalationStatus.escalated.name,
          },
        });

        return escalatedCase;
      });
    } on BackendException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on escalateCase: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not escalate clinical case in Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on escalateCase: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to escalate clinical case.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalCase> startAdminCaseReview({
    required String patientId,
    required String caseId,
    required String adminId,
  }) async {
    final docRef = _getCasesCollection(patientId).doc(caseId);
    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw const BackendException(
            code: BackendException.notFound,
            message: 'Clinical case not found.',
          );
        }
        final existing = ClinicalCase.fromFirestore(snapshot.data()!, snapshot.id);
        if (existing.escalationStatus != CaseEscalationStatus.escalated) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'Only pending escalated cases can be placed under review.',
          );
        }

        final now = DateTime.now();
        final underReviewCase = existing.copyWith(
          escalationStatus: CaseEscalationStatus.underReview,
          adminReviewStartedAt: now,
          adminReviewStartedBy: adminId,
          updatedAt: now,
        );

        transaction.set(docRef, underReviewCase.toFirestore(), SetOptions(merge: true));

        // Create audit log document within transaction
        final auditRef = _firestore
            .collection(FirebaseConfig.auditLogsCollection)
            .doc('AUD-REV-${now.millisecondsSinceEpoch}');
        transaction.set(auditRef, {
          'auditId': 'AUD-REV-${now.millisecondsSinceEpoch}',
          'actorType': 'ADMIN',
          'actorId': adminId,
          'action': 'CASE_ESCALATION_REVIEW_STARTED',
          'entityType': 'CLINICAL_CASE',
          'entityId': caseId,
          'timestamp': Timestamp.fromDate(now),
          'metadata': {
            'caseId': caseId,
            'patientId': patientId,
            'department': existing.domain,
            'oldEscalationStatus': existing.escalationStatus.name,
            'newEscalationStatus': CaseEscalationStatus.underReview.name,
          },
        });

        return underReviewCase;
      });
    } on BackendException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on startAdminCaseReview: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not update escalation review state in Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on startAdminCaseReview: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to start escalation review.',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<ClinicalCase>> watchEscalatedCases() {
    if (kDebugMode) {
      try {
        final fbUser = fb.FirebaseAuth.instance.currentUser;
        debugPrint(
            '[FirebaseCaseRepository] watchEscalatedCases: authUserExists=${fbUser != null}, authUid=${fbUser?.uid}, email=${fbUser?.email}, query=collectionGroup(cases).where(escalationStatus in [escalated, underReview])');
      } catch (_) {}
    }

    return _firestore
        .collectionGroup('cases')
        .where('escalationStatus', whereIn: ['escalated', 'underReview'])
        .snapshots()
        .map((snapshot) {
      final cases = snapshot.docs
          .map((doc) => ClinicalCase.fromFirestore(doc.data(), doc.id))
          .toList();
      cases.sort((a, b) =>
          (b.escalatedAt ?? b.updatedAt).compareTo(a.escalatedAt ?? a.updatedAt));
      return cases;
    }).handleError((error) {
      debugPrint('[FirebaseCaseRepository] watchEscalatedCases stream error: $error');
      throw error;
    });
  }

  @override
  Future<List<ClinicalCase>> getEscalatedCases() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('cases')
          .where('escalationStatus', whereIn: ['escalated', 'underReview'])
          .get();
      final cases = snapshot.docs
          .map((doc) => ClinicalCase.fromFirestore(doc.data(), doc.id))
          .toList();
      cases.sort((a, b) =>
          (b.escalatedAt ?? b.updatedAt).compareTo(a.escalatedAt ?? a.updatedAt));
      return cases;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on getEscalatedCases: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not retrieve escalated cases from Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on getEscalatedCases: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to load escalated cases.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalCase> assignHigherAuthorityDoctor({
    required String patientId,
    required String caseId,
    required String targetDoctorId,
    required String targetDoctorName,
    required String targetDepartment,
    required String assignedByAdminId,
    String? crossDepartmentReason,
  }) async {
    final caseRef = _getCasesCollection(patientId).doc(caseId);
    final targetDocRef = _firestore.collection(FirebaseConfig.doctorsCollection).doc(targetDoctorId);

    try {
      return await _firestore.runTransaction<ClinicalCase>((tx) async {
        final caseSnap = await tx.get(caseRef);
        if (!caseSnap.exists || caseSnap.data() == null) {
          throw const BackendException(
            code: BackendException.notFound,
            message: 'Clinical Case not found.',
          );
        }

        final existing = ClinicalCase.fromFirestore(caseSnap.data()!, caseSnap.id);
        if (!existing.isOpen) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'Cannot assign a closed clinical case.',
          );
        }

        if (existing.escalationStatus == CaseEscalationStatus.none) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'Only escalated clinical cases can be assigned to higher authority.',
          );
        }

        if (existing.isAssignedToHigherAuthority) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'This case has already been assigned to a higher-authority doctor.',
          );
        }

        final targetDocSnap = await tx.get(targetDocRef);
        if (!targetDocSnap.exists || targetDocSnap.data() == null) {
          throw const BackendException(
            code: BackendException.notFound,
            message: 'Selected doctor profile does not exist.',
          );
        }

        final targetDoc = DoctorProfile.fromFirestore(targetDocSnap.data()!, targetDocSnap.id);
        if (!targetDoc.isActive) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'Selected doctor account is inactive.',
          );
        }

        if (targetDoc.availabilityStatus != DoctorAvailabilityStatus.available) {
          throw BackendException(
            code: BackendException.unavailable,
            message: targetDoc.availabilityStatus == DoctorAvailabilityStatus.inConsultation
                ? 'Doctor is currently in an active consultation.'
                : 'Doctor is currently offline and unavailable.',
          );
        }

        // Check source doctor authority level
        int sourceAuthorityLevel = 1;
        final sourceDocId = existing.escalatedByDoctorId;
        if (sourceDocId != null && sourceDocId.isNotEmpty) {
          final sourceDocRef = _firestore.collection(FirebaseConfig.doctorsCollection).doc(sourceDocId);
          final sourceDocSnap = await tx.get(sourceDocRef);
          if (sourceDocSnap.exists && sourceDocSnap.data() != null) {
            final sourceDoc = DoctorProfile.fromFirestore(sourceDocSnap.data()!, sourceDocSnap.id);
            sourceAuthorityLevel = sourceDoc.clinicalAuthorityLevel;
          }
        }

        if (targetDoc.clinicalAuthorityLevel <= sourceAuthorityLevel) {
          throw const BackendException(
            code: BackendException.permissionDenied,
            message: 'Selected doctor authority level must be strictly higher than the source doctor authority level.',
          );
        }

        if (targetDoc.doctorId == sourceDocId) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'Cannot assign the case back to the source doctor who escalated it.',
          );
        }

        final caseDomain = existing.domain.replaceAll('_', ' ').trim().toLowerCase();
        final targetDept = targetDepartment.replaceAll('_', ' ').trim().toLowerCase();
        final isCrossDept = caseDomain != targetDept;
        if (isCrossDept && (crossDepartmentReason == null || crossDepartmentReason.trim().isEmpty)) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'A reason is required when assigning across different medical departments.',
          );
        }

        final now = DateTime.now();
        final assignedCase = existing.copyWith(
          higherAuthorityDoctorId: targetDoctorId,
          higherAuthorityDoctorName: targetDoctorName,
          higherAuthorityDepartment: targetDepartment,
          higherAuthorityAssignedAt: now,
          higherAuthorityAssignedBy: assignedByAdminId,
          higherAuthorityAssignmentStatus: HigherAuthorityAssignmentStatus.assigned,
          higherAuthorityAssignmentReason: crossDepartmentReason,
          updatedAt: now,
        );

        tx.update(caseRef, assignedCase.toFirestore());

        // Audit log
        final auditRef = _firestore.collection(FirebaseConfig.auditLogsCollection).doc();
        tx.set(auditRef, {
          'auditId': auditRef.id,
          'actorType': 'ADMIN',
          'actorId': assignedByAdminId,
          'action': 'HIGHER_AUTHORITY_ASSIGNED',
          'entityType': 'CLINICAL_CASE',
          'entityId': caseId,
          'timestamp': Timestamp.fromDate(now),
          'metadata': {
            'caseId': caseId,
            'patientId': patientId,
            'sourceDoctorId': sourceDocId,
            'sourceAuthorityLevel': sourceAuthorityLevel,
            'targetDoctorId': targetDoctorId,
            'targetDoctorName': targetDoctorName,
            'targetDepartment': targetDepartment,
            'targetAuthorityLevel': targetDoc.clinicalAuthorityLevel,
            'isCrossDepartment': isCrossDept,
            'reason': crossDepartmentReason,
          },
        });

        return assignedCase;
      });
    } on BackendException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on assignHigherAuthorityDoctor: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not commit higher-authority doctor assignment to Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on assignHigherAuthorityDoctor: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to assign higher-authority doctor.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalCase> acceptHigherAuthorityAssignment({
    required String patientId,
    required String caseId,
    required String doctorId,
  }) async {
    final caseRef = _getCasesCollection(patientId).doc(caseId);

    try {
      return await _firestore.runTransaction<ClinicalCase>((tx) async {
        final caseSnap = await tx.get(caseRef);
        if (!caseSnap.exists || caseSnap.data() == null) {
          throw const BackendException(
            code: BackendException.notFound,
            message: 'Clinical Case not found.',
          );
        }

        final existing = ClinicalCase.fromFirestore(caseSnap.data()!, caseSnap.id);
        if (!existing.isOpen) {
          throw const BackendException(
            code: BackendException.invalidData,
            message: 'Cannot accept assignment for a closed clinical case.',
          );
        }

        if (existing.higherAuthorityDoctorId != doctorId) {
          throw const BackendException(
            code: BackendException.permissionDenied,
            message: 'Only the assigned higher-authority doctor can accept this case.',
          );
        }

        final now = DateTime.now();
        final acceptedCase = existing.copyWith(
          higherAuthorityAssignmentStatus: HigherAuthorityAssignmentStatus.accepted,
          higherAuthorityAcceptedAt: now,
          updatedAt: now,
        );

        tx.update(caseRef, acceptedCase.toFirestore());

        final auditRef = _firestore.collection(FirebaseConfig.auditLogsCollection).doc();
        tx.set(auditRef, {
          'auditId': auditRef.id,
          'actorType': 'DOCTOR',
          'actorId': doctorId,
          'action': 'HIGHER_AUTHORITY_ASSIGNMENT_ACCEPTED',
          'entityType': 'CLINICAL_CASE',
          'entityId': caseId,
          'timestamp': Timestamp.fromDate(now),
          'metadata': {
            'caseId': caseId,
            'patientId': patientId,
            'doctorId': doctorId,
          },
        });

        return acceptedCase;
      });
    } on BackendException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseCaseRepository] FirebaseException on acceptHigherAuthorityAssignment: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not accept higher-authority assignment in Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseCaseRepository] Unexpected error on acceptHigherAuthorityAssignment: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to accept higher-authority assignment.',
        originalError: e,
      );
    }
  }
}

