# AAYUSATHI — Cloud-Backed Kiosk OPD Workflow (Phase 11)

**Project**: AAYUSATHI  
**Tagline**: LIVE BETTER, TOGETHER  
**Firebase Project**: `aayusathi-eb341` (Project #618079186276)  
**Firestore Database**: `(default)` | Region: `asia-south1`  

---

## 1. Overview & Objectives

Phase 11 transitions the AAYUSATHI Kiosk OPD terminal from in-memory mock storage to live Cloud Firestore persistence for all patient check-in workflows, with deterministic transactional safety, strict duplicate prevention, and zero exposure of sensitive identifiers.

### Key Capabilities Implemented:
1. **Cloud Collections Integration**:
   - `patients`: Persists patient demographic profiles keyed by `patientId` (e.g. `AAYU-102938`). Plain-text Aadhaar is strictly barred at both model and Firestore rule levels.
   - `appointments`: Persists consultation requests with strictly validated queue tokens (`^A-[0-9]{5}$`), domain IDs, and anonymized patient references.
   - `vitals`: Persists sensor telemetry tied to patient sessions without exposing patient identities to unauthorized actors.
   - `visits`: Persists consultation history records for recurring doctor/domain continuity checks.
   - `auditLogs`: Append-only audit logging tracking patient registrations, verification events, queue allocations, and appointment creation.
   - `system/queueCounter`: Centralized transactional document maintaining the atomic queue ticket sequence.
2. **Transaction-Safe Queue Allocation**:
   - Atomic Firestore transaction on `system/queueCounter`.
   - Strictly validates current ticket count `< 99999` (capacity limit).
   - Generates sequential zero-padded tokens matching `^A-[0-9]{5}$` (e.g. `A-00001`, `A-00027`).
   - Commits counter increment and `appointments/{requestId}` document in the **same atomic transaction**, eliminating collisions and lost tickets under concurrent check-ins.
3. **Patient Duplicate Protection**:
   - `PatientRepository.createPatient(Patient)` verifies that `patientId` does not already exist before creating the document.
   - Throws `BackendException.duplicatePatient` if an identity collision is detected.
4. **Cloud Patient Lookup**:
   - `RepositoryPatientLookupService` dynamically resolves patient identities from `BackendProvider.instance.patientRepository`.
   - Supports normalized queries with or without the `AAYU-` prefix.
5. **Previous Visit History & Composite Index Avoidance**:
   - `FirebaseVisitRepository` retrieves the latest consultation for a patient and domain by querying strictly on `patientId` (`where('patientId', isEqualTo: patientId)`) and sorting/filtering in client memory.
   - Prevents missing composite index errors on Firestore for `(patientId, domainId, visitDate)`.
6. **Patient-Safe Error Localization**:
   - `BackendException` provides user-safe localized explanations across English, Hindi, and Marathi (`KioskLocale.english`, `KioskLocale.hindi`, `KioskLocale.marathi`).
   - UI gracefully displays floating SnackBars and halts progression without showing fake queue tickets or crashing.
7. **Session Boundaries**:
   - `resetSession()` purges transient patient inputs while preserving the Kiosk terminal's authenticated Firebase identity.

---

## 2. Cloud Data Architecture

```
                          Physical AAYUSATHI Kiosk
                                    |
                    (Firebase Anonymous Authentication)
                                    |
                       +------------v------------+
                       |     BackendProvider     |
                       +------------+------------+
                                    |
     +-----------------+------------+------------+-----------------+
     |                 |            |            |                 |
     v                 v            v            v                 v
[patients]      [appointments]   [visits]     [vitals]        [auditLogs]
(Demographics)  (Queue Tickets)  (History)   (Telemetry)     (Append-Only)
     |                 |
     |         (Transaction)
     |                 |
     +-----> [system/queueCounter]
```

### 2.1 Collection Schemas

#### `patients/{patientId}`
```json
{
  "patientId": "AAYU-102938",
  "name": "Aarav Sharma",
  "dateOfBirth": "14 May 1990",
  "age": 34,
  "gender": "Male",
  "phone": "+91 98765 43210",
  "bloodGroup": "O+",
  "address": "104, Green Meadows, Pune, Maharashtra 411001",
  "createdAt": "2026-09-05T02:00:00.000Z",
  "updatedAt": "2026-09-05T02:00:00.000Z",
  "isActive": true
}
```
*Note: Aadhaar numbers are never present.*

#### `appointments/{requestId}`
```json
{
  "requestId": "REQ-1788551234567",
  "patientId": "AAYU-102938",
  "domainId": "cardiology",
  "previousDoctorId": "DOC-CARD-01",
  "assignedDoctorId": "DOC-CARD-01",
  "preferredDoctorMode": "sameDoctor",
  "status": "waiting",
  "queueNumber": "A-00001",
  "createdAt": "2026-09-05T02:05:00.000Z",
  "updatedAt": "2026-09-05T02:05:00.000Z",
  "source": "KIOSK",
  "sessionId": "SESS-1788551200000"
}
```

#### `visits/{visitId}`
```json
{
  "visitId": "VIS-1788551234567-AAYU-102938",
  "patientId": "AAYU-102938",
  "domainId": "cardiology",
  "previousDoctorId": "DOC-CARD-01",
  "lastVisitDate": "2026-09-05T02:05:00.000Z",
  "appointmentId": "REQ-1788551234567",
  "status": "queued"
}
```

#### `system/queueCounter`
```json
{
  "currentNumber": 1,
  "lastQueueNumber": 1,
  "updatedAt": "2026-09-05T02:05:00.000Z"
}
```

#### `auditLogs/{auditId}`
```json
{
  "auditId": "AUD-1788551234567-APPT",
  "actorType": "KIOSK",
  "actorId": "KIOSK-01",
  "action": "APPOINTMENT_CREATED",
  "entityType": "APPOINTMENT",
  "entityId": "REQ-1788551234567",
  "timestamp": "2026-09-05T02:05:00.000Z",
  "metadata": {
    "queueNumber": "A-00001",
    "domainId": "cardiology",
    "status": "waiting",
    "patientId": "AAYU-102938"
  }
}
```

---

## 3. Atomic Transaction & Concurrency Control

In `FirebaseAppointmentRepository.saveAppointmentWithAtomicQueue`:
```dart
final finalAppointment = await _firestore.runTransaction<AppointmentRequest>((transaction) async {
  final counterSnapshot = await transaction.get(_counterDoc);
  int current = 0;
  if (counterSnapshot.exists && counterSnapshot.data() != null) {
    final data = counterSnapshot.data()!;
    current = (data['currentNumber'] ?? data['lastQueueNumber'] as num?)?.toInt() ?? 0;
  }

  if (current >= 99999) {
    throw const BackendException(
      code: BackendException.queueCapacityReached,
      message: 'Queue capacity limit of 99,999 tickets has been reached.',
    );
  }

  final next = current + 1;
  final formattedQueue = 'A-${next.toString().padLeft(5, '0')}';

  // 1. Commit incremented counter
  transaction.set(
    _counterDoc,
    {
      'currentNumber': next,
      'lastQueueNumber': next,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );

  // 2. Commit appointment with allocated queue in SAME transaction
  final updatedRequest = request.copyWith(queueNumber: formattedQueue);
  final apptDocRef = _collection.doc(updatedRequest.requestId);
  transaction.set(
    apptDocRef,
    updatedRequest.toFirestore(),
    SetOptions(merge: true),
  );

  return updatedRequest;
});
```

### Guarantees:
- **Zero Collision**: Firestore guarantees optimistic locking and transactional re-tries if multiple terminals attempt simultaneous queue requests.
- **Zero Orphaned Numbers**: An appointment request document is only committed if the queue number was successfully allocated.
- **Hard Capacity Ceiling**: Exactly at 99,999 tickets, further requests are rejected with `BackendException.queueCapacityReached`.

---

## 4. Error Handling & Multi-Language Localization

`BackendException.getLocalizedMessage(KioskLocale)` maps system error codes to patient-friendly localized text:

| Error Code | English | Hindi | Marathi |
|---|---|---|---|
| `duplicatePatient` | A registration for this patient already exists. | इस मरीज का पंजीकरण पहले से मौजूद है। | या रुग्णाची नोंदणी आधीच अस्तित्वात आहे. |
| `queueCapacityReached` | Daily OPD queue is full for today. Please visit the help desk. | आज के लिए ओपीडी कतार पूरी हो चुकी है। कृपया सहायता केंद्र से संपर्क करें। | आजची ओपीडी रांग पूर्ण झाली आहे. कृपया मदत केंद्राशी संपर्क साधा. |
| `queueAllocationFailed` | Could not assign a queue number. Please try again or ask staff. | टोकन नंबर आवंटित नहीं किया जा सका। कृपया पुनः प्रयास करें। | टोकन क्रमांक मिळू शकला नाही. कृपया पुन्हा प्रयत्न करा. |
| `persistenceFailed` | Unable to save your consultation request. Please ask for assistance. | आपका परामर्श अनुरोध सहेजा नहीं जा सका। कृपया कर्मचारी से संपर्क करें। | तुमची तपासणी विनंती नोंदवता आली नाही. कृपया कर्मचाऱ्यांची मदत घ्या. |

---

## 5. Security Rules Verification

The deployed `firestore.rules` guarantees:
- **`system/queueCounter`**: Accessible only by authenticated identities (`isAuthenticated()`).
- **`visits/{visitId}`**: Anonymous Kiosk can read and write patient visit history (`isAnonymousKiosk()`).
- **`appointments/{appointmentId}`**: Enforces regular expression `queueNumber.matches('^A-[0-9]{5}$')`.
- **`patients/{patientId}`**: Strictly rejects any document containing `'aadhaarNumber'` or `'aadhaar'`.
