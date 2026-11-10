# AAYUSATHI — PHASE D12 DOCUMENTATION
## Visit Completion, Case Lifecycle & Doctor Workflow Finalization

**Project**: AAYUSATHI — Live Better, Together  
**Phase**: D12  
**Status**: Completed & Verified  

---

### 1. Architectural Principles

#### 1.1 Visit Completion $\neq$ Case Closure
A fundamental clinical distinction is enforced:
- **Visit**: Represents a single clinical consultation encounter (`ACTIVE` $\rightarrow$ `COMPLETED`).
- **Case**: Represents an ongoing medical episode (`OPEN` or `CLOSED`).
- Completing an active visit changes its status to `COMPLETED`, records `completedAt` and `completedByDoctorId`, and **strictly keeps the parent Case status as `OPEN`**.
- This ensures ongoing chronic management, follow-ups, and serial investigations remain scoped to the existing Case.

```
Patient (PAT-001)
 └── Case (CASE-001) — OPEN (ONGOING)
      ├── Visit 1 — COMPLETED (Dr. Rajesh Sharma)
      │    ├── Consultation Data (8 Structured Fields)
      │    ├── Prescriptions
      │    └── Ordered Investigations (Pending / Reviewed)
      └── Visit 2 — ACTIVE (In-Progress or Follow-Up)
```

---

### 2. Doctor-Controlled Visit Completion & Declaration

#### 2.1 Completion Gating & Prerequisites
A visit cannot be completed until the following conditions are met:
1. **Mandatory Consultation Fields**: All 8 structured clinical fields (Chief Complaint, Onset/Duration, Associated Symptoms, Medical History, Current Medication, Clinical Observations, Assessment, Plan) are filled.
2. **Prescription Integrity**: Any entered prescription rows must have complete mandatory parameters.
3. **Approved Summary**: Visit summary must be entered and have `SummaryApprovalStatus.approvedByDoctor`.
4. **Independent Investigations**: Investigations can remain in `pendingUpload` or `reviewed` status without blocking visit completion.
5. **Optional PDF**: PDF generation can occur before or after completion.

#### 2.2 Doctor Completion Declaration Modal
- `DoctorCompleteVisitDialog` renders:
  - Live 4-point prerequisite checklist with status indicators.
  - Explanatory banner confirming that Case status remains `OPEN`.
  - Required checkbox for the explicit Doctor Declaration.
  - Formal declaration text:
    > *"I confirm that I have reviewed the consultation notes, prescriptions, and advice for this clinical visit. Completing this visit finalizes the current consultation session while keeping the clinical case active for ongoing care."*

---

### 3. State Transitions & Availability Restoration

#### 3.1 Presence Machine Synchronization
- The attending doctor's presence status is held at `IN_CONSULTATION` throughout active consultation.
- Transition `IN_CONSULTATION` $\rightarrow$ `AVAILABLE` occurs **only after** backend visit completion succeeds atomically.
- If a network error or validation failure occurs during completion, the doctor remains locked in `IN_CONSULTATION`, consultation drafts are preserved, and a retryable error message is shown.

#### 3.2 Completion Confirmation & Safe Exit
- Upon successful backend write, `DoctorVisitCompletedDialog` displays:
  - Success badge with Visit Number and Case ID.
  - Attending doctor details and timestamp.
  - Case Status badge: `OPEN (ONGOING)`.
  - Action button: `RETURN TO DASHBOARD` (navigating back to `/doctor/dashboard`).

---

### 4. Multi-Visit Scoped Sequencing

- Sequential numbering is strictly scoped per Case (`getNextVisitNumber`):
  - `Case 1`: Visit 1, Visit 2, Visit 3...
  - `Case 2`: Visit 1, Visit 2...
- In `DoctorClinicalRecordsSection`:
  - Doctors can inspect historical visits via `DoctorVisitDetailDialog` (read-only modal).
  - Doctors can start a new sequential visit within an existing open case using `+ NEW VISIT`.

---

### 5. Patient Module Representation

- `PatientClinicalRecordsService` aggregates clinical cases, visits, and linked investigation reports into `PatientCaseRecordBundle`.
- `PatientCaseOverviewCard` presents:
  - Domain and Case title.
  - Status badge: `OPEN (ONGOING)`.
  - Chronological visit list with attending doctor name and linked report counts.

---

### 6. Audit Logging & Zero Secrets Policy

- Structured audit events recorded:
  - `VISIT_COMPLETION_DECLARATION_CONFIRMED`
  - `VISIT_COMPLETED`
  - `CASE_CONTINUED`
  - `VISIT_CREATED`
- Strict compliance: Zero Aadhaar numbers, OTPs, auth tokens, passwords, or Gemini API keys are ever included in metadata or logged.

---

### 7. Dual Persistence & Dev Mode Safety

- **Firebase / Firestore**: `FirebaseClinicalVisitRepository` persists `completedAt` server timestamps and case metadata.
- **Mock Mode**: `MockClinicalVisitRepository` with full state reset, deterministic data fixtures, and error simulation toggle `simulateCompletionError`.
- **Zero Cloud Writes in Dev Mode**: When `DOCTOR_DEV_MODE=true` or `backendMode == mock`, all operations run locally in memory.

---

### 8. Verification & Quality Metrics

- **Unit & Integration Tests**: 544 tests passing repository-wide (100% pass rate).
- **Dedicated D12 Test Suite**: 23 comprehensive tests in `test/doctor/doctor_d12_test.dart`.
- **Static Analysis**: `flutter analyze` completed with **0 issues**.
- **Windows Binary**: `flutter build windows` built successfully (`build\windows\x64\runner\Release\aayusathi.exe`).
