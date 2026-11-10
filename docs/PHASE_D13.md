# AAYUSATHI — PHASE D13: DOCTOR TRANSFER & INTER-DEPARTMENT REFERRAL
**Tagline**: LIVE BETTER, TOGETHER  
**Module**: Doctor Clinical Workstation & Patient Referral Subsystem  
**Date**: September 2026  

---

## 1. Executive Summary

Phase D13 introduces controlled **Doctor-Initiated Inter-Department Transfers and Referrals** to the AAYUSATHI healthcare platform. This feature enables a consulting physician to refer an active patient to another specialized medical department (e.g., *Cardiology $\rightarrow$ Neurology*) when further specialized evaluation is clinically indicated.

### Core Architectural Principles
1. **Transfer $\neq$ Diagnosis $\neq$ Visit Completion**: Transferring a patient is an administrative and clinical handover mechanism. It does not complete the case or declare a diagnosis.
2. **Case Lifecycle Integrity**: The parent `ClinicalCase` strictly remains **`OPEN`** (`ClinicalCaseStatus.open`). It is never auto-closed.
3. **Visit Status Transition**: The current active consultation visit transitionally completes with status **`ClinicalVisitStatus.transferred`**.
4. **First-Doctor-Wins Semantics**: The destination department queue utilizes atomic first-doctor-wins claiming. If multiple doctors in the destination department attempt to accept the transferred patient simultaneously, exactly one doctor succeeds while others receive an atomic conflict rejection.
5. **Doctor Presence Restoration**: The source doctor transitions from `IN_CONSULTATION` to `AVAILABLE` **only after** the transfer request is successfully created and persisted in the backend.
6. **Zero-PII & Privacy Architecture**: Transfer metadata conforms to strict privacy guarantees. Zero Aadhaar numbers, OTPs, session tokens, passwords, or Gemini API keys are ever stored, transferred, or logged.

---

## 2. Architecture & Data Models

### 2.1 PatientTransferRequest Model
Location: [`lib/doctor/models/patient_transfer_request.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/models/patient_transfer_request.dart)

```dart
class PatientTransferRequest {
  final String transferId;
  final String patientId;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final String caseId;
  final String sourceVisitId;
  final String sourceDoctorId;
  final String sourceDoctorName;
  final String sourceDepartment;
  final String destinationDepartment;
  final String? destinationDoctorId;
  final String? destinationDoctorName;
  final String reason;
  final TransferStatus status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;
  final String? cancelledByDoctorId;
  final String? queueNumber;
  final VitalReading? vitals;
}
```

#### Transfer Status Lifecycle:
- `pending`: Transfer created by source doctor; placed in destination department OPD queue.
- `accepted`: Claimed by a destination doctor via atomic first-doctor-wins transaction.
- `cancelled`: Revoked by the initiating source doctor before acceptance.
- `expired`: Timed out due to department queue lifecycle rules.

#### Key Validation Rules:
- **Reason Length**: Must be between 1 and 1000 characters (`reason.trim().isNotEmpty && reason.trim().length <= 1000`).
- **Destination Department**: Must differ from the active source department (`destinationDepartment.trim().toLowerCase() != sourceDepartment.trim().toLowerCase()`).
- **Cancellation Authorization**: A transfer can only be cancelled by the initiating source doctor (`cancelledBy == sourceDoctorId`) and only while in `pending` status.

---

### 2.2 ClinicalVisit & Case Lifecycle Integrity

| Entity | Previous State | Post-Transfer State | Remarks |
|---|---|---|---|
| **ClinicalCase** | `open` | `open` | Strictly maintained as `open`; retains all historical visits without duplication. |
| **Active ClinicalVisit** | `active` | `transferred` | Status set to `ClinicalVisitStatus.transferred`; recorded in historical visit logs. |
| **Source Doctor Presence** | `inConsultation` | `available` | Released to `available` immediately upon successful backend transfer creation. |
| **Destination Doctor Presence**| `available` | `inConsultation`| Transitions to `inConsultation` immediately upon successfully claiming the transfer. |

---

## 3. Repositories & Backend Architecture

### 3.1 TransferRepository Contract
Location: [`lib/repositories/transfer_repository.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/repositories/transfer_repository.dart)

- `createTransfer(PatientTransferRequest request)`: Persists transfer request and places it into the destination department queue.
- `getPendingTransfersForDepartment(String department)`: Fetches active `pending` transfers filtered by department.
- `acceptTransfer({transferId, doctorId, doctorName, doctorDepartment})`: Atomic claim operation with `DoctorAssignmentResult`.
- `cancelTransfer({transferId, doctorId})`: Authorizes source doctor cancellation of pending transfers.
- `getTransferById(String transferId)`: Retrieves full transfer details and telemetry.

### 3.2 FirebaseTransferRepository
Location: [`lib/repositories/firebase/firebase_transfer_repository.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/repositories/firebase/firebase_transfer_repository.dart)

- Executes atomic Firestore transactions on `/transfers/{transferId}`.
- Enforces first-doctor-wins claiming: verifies `status == 'pending'` inside transaction before setting `status = 'accepted'`.
- Dev-mode protection: throws `StateError` if Firestore write is attempted when `DOCTOR_DEV_MODE=true`.

### 3.3 MockTransferRepository
Location: [`lib/repositories/mock/mock_transfer_repository.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/repositories/mock/mock_transfer_repository.dart)

- In-memory thread-safe mock repository with deterministic fixtures for Cardiology, Neurology, Orthopedics, and Dermatology.
- Supports synchronous atomic claiming, simulated network latency, and fixture resets (`resetToDefaults()`).

---

## 4. UI Components & Doctor Workstation

### 4.1 DoctorTransferPatientDialog
Location: [`lib/doctor/widgets/doctor_transfer_patient_dialog.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/widgets/doctor_transfer_patient_dialog.dart)

- **Step 1: Department & Reason**:
  - Excludes the current department from destination dropdown.
  - Character counter with realtime validation (1–1000 characters).
  - Clean error states for empty or invalid inputs.
- **Step 2: Review & Confirmation**:
  - Displays patient identifier, active case ID, source $\rightarrow$ destination routing, and full transfer reason.
  - Explicit `CONFIRM TRANSFER` action triggers backend execution.

### 4.2 DoctorTransferContextBanner
Location: [`lib/doctor/widgets/doctor_transfer_context_banner.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/widgets/doctor_transfer_context_banner.dart)

- Rendered at the top of the destination doctor's patient workspace.
- Highlights:
  - Source department (e.g. *Transferred from: Cardiology*).
  - Referring physician name (e.g. *Dr. Rajesh Sharma*).
  - Full referral justification note.
- Responsive design with `Wrap` layout to prevent horizontal `RenderFlex` overflow on narrow displays.

### 4.3 DoctorPatientRequestCard (Queue Integration)
Location: [`lib/doctor/widgets/doctor_patient_request_card.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/widgets/doctor_patient_request_card.dart)

- Renders distinct `TRANSFER REQUEST` teal badge for incoming inter-department referrals.
- Displays source department, referring doctor name, and referral reason snippet alongside vitals telemetry.

---

## 5. Security & Audit Logging

### 5.1 Audit Log Events
| Event Action | Actor | Entity Type | Logged Metadata |
|---|---|---|---|
| `TRANSFER_REQUESTED` | Source Doctor | `PATIENT_TRANSFER` | `transferId`, `patientId`, `caseId`, `sourceVisitId`, `sourceDepartment`, `destinationDepartment` |
| `TRANSFER_CONFIRMED` | Source Doctor | `PATIENT_TRANSFER` | `transferId`, `destinationDepartment`, `reasonLength` |
| `TRANSFER_ACCEPTED` | Destination Doctor | `PATIENT_TRANSFER` | `transferId`, `destinationDepartment`, `destinationDoctorId` |
| `TRANSFER_CANCELLED` | Source Doctor | `PATIENT_TRANSFER` | `transferId`, `cancelledBy` |

### 5.2 Zero-PII Enforcement
- Zero Aadhaar numbers, OTP codes, auth passwords, doctor session tokens, or Gemini API keys stored or transmitted in transfer payloads or audit records.

---

## 6. Multi-Language Localization

Full trilingual support for English, Hindi, and Marathi:

| Key | English | Hindi (हिंदी) | Marathi (मराठी) |
|---|---|---|---|
| `transferPatientButton` | TRANSFER PATIENT | मरीज स्थानांतरित करें | रुग्ण हस्तांतरित करा |
| `transferPatientTitle` | Transfer Patient | मरीज स्थानांतरण | रुग्ण हस्तांतरण |
| `destinationDepartmentLabel`| Destination Department | गंतव्य विभाग | गंतव्य विभाग |
| `transferReasonLabel` | Transfer Reason | स्थानांतरण / रेफरल का कारण | हस्तांतरण / रेफरलचे कारण |
| `reviewTransferButton` | REVIEW TRANSFER | स्थानांतरण की समीक्षा करें | हस्तांतरणाचे पुनरावलोकन करा |
| `confirmTransferButton` | CONFIRM TRANSFER | स्थानांतरण की पुष्टि करें | हस्तांतरणाची पुष्टी करा |
| `transferredFromBanner` | Transferred from | से स्थानांतरित | येथून हस्तांतरित |
| `transferRequestBadge` | TRANSFER REQUEST | स्थानांतरण अनुरोध | हस्तांतरण विनंती |
| `cancelTransferButton` | CANCEL TRANSFER | स्थानांतरण रद्द करें | हस्तांतरण रद्द करा |

---

## 7. Verification & Quality Assurance

### 7.1 Automated Test Suite
- **D13 Dedicated Suite**: [`test/doctor/doctor_d13_test.dart`](file:///c:/DEVELOPEMENT/aayusathi/test/doctor/doctor_d13_test.dart) — **26 / 26 Passed (100%)**
  - Transfer Model & Validation rules (reason length, department checks, cancellation auth).
  - First-Doctor-Wins atomic acceptance and race condition rejection.
  - Case status preservation (`OPEN`) and historical visit integrity.
  - Source and destination Doctor Presence state machine transitions.
  - Dialog and Context Banner UI rendering.
  - Audit logging & credential protection verification.
  - English, Hindi, and Marathi localization coverage.
- **Full Application Suite**: `flutter test` — **570 / 570 Tests Passed (100%)**.
- **Static Analysis**: `flutter analyze` — **0 errors, 0 warnings, 0 lints**.
