# AAYUSATHI — PHASE D15: DOCTOR CASE CLOSURE, FINAL WORKFLOW & DOCTOR MODULE POLISH
**Tagline**: LIVE BETTER, TOGETHER  
**Module**: Doctor Clinical Workstation Finalization & Case Closure Subsystem  
**Phase**: D15 (Final Doctor Module Phase)  
**Date**: September 2026  

---

## 1. Executive Summary

Phase D15 is the **FINAL DOCTOR MODULE PHASE** of the AAYUSATHI healthcare system. It solidifies the clinical workstation lifecycle by implementing the explicit **Case Closure Workflow**, standalone navigation desks (**Cases & Clinical Visits** and **Diagnostic Reports & Investigations**), resolves clinical workspace tab stability, establishes complete audit logging for case closure, and provides a polished, production-ready workstation experience across all doctor flows.

```
PATIENT
   ↓
CLINICAL CASE (Status: OPEN)
   ↓
VISIT 1 (Status: Completed)
   ↓
VISIT 2 (Status: Completed)
   ↓
[EXPLICIT DOCTOR CASE CLOSURE]
   ├── 1. Active Visit Precondition Check (must be none active)
   ├── 2. Pending Transfer Precondition Check (must be none pending)
   ├── 3. Doctor Mandatory Declaration Checkbox
   ├── 4. Doctor Clinical Closure Note (1-1000 chars, no AI generation)
   ├── 5. Atomic Firestore / Mock State Transition
   └── 6. Audit Logging (CASE_CLOSURE_DECLARATION_CONFIRMED, CASE_CLOSED)
   ↓
CLINICAL CASE (Status: CLOSED)
   └── Read-only historical access, closed case milestone in timeline, no new visits allowed
```

---

## 2. Key Capabilities Implemented in Phase D15

### 2.1 Complete Case Closure Workflow
1. **Explicit Doctor-Initiated Closure**:
   - Cases are **never automatically closed** by completing a visit or by timeout.
   - Closure is explicitly triggered by an authenticated doctor clicking `[CLOSE CASE]`.
2. **Precondition Gating**:
   - **Active Visit Protection**: If an active consultation encounter (`ClinicalVisitStatus.active`) exists for the case, closure is blocked with an error banner: `"Complete or transfer the active Visit before closing this Case."`.
   - **Transfer Protection**: If a pending inter-department transfer request exists for the case, closure is blocked with: `"A pending inter-department transfer must be resolved before closing this Case."`.
3. **Mandatory Doctor Declaration**:
   - Checkbox: `"I confirm that I am closing this Case because the clinical problem associated with this Case has been resolved / appropriately concluded."`.
   - The dialog prevents submission until this declaration is confirmed.
4. **Mandatory Doctor Closure Note**:
   - Text field for clinical outcome / conclusion (1 to 1000 characters).
   - Real-time character counter (`0 / 1000`).
   - Strictly human/doctor authored — **no AI auto-generation permitted**.
5. **Atomic State Transition**:
   - Case status updates to `ClinicalCaseStatus.closed`.
   - Metadata recorded: `closedAt`, `closedByDoctorId`, `closedByDoctorName`, `closureNote`.
6. **Case Closed Confirmation Dialog (`DoctorCaseClosedDialog`)**:
   - Displays closed status badge, doctor name, timestamp, domain, case ID, and closure note.
   - Quick actions: `[VIEW CASE HISTORY]` and `[RETURN TO DASHBOARD]`.
7. **Read-Only Preservation of Closed Cases**:
   - Case info cards display `CLOSED` status banner in muted navy styling.
   - `+ NEW VISIT` and `CLOSE CASE` buttons are hidden / blocked for closed cases.
   - All historical visits, transcripts, prescriptions, and reports remain 100% readable.
8. **Case Timeline Milestone**:
   - Added milestone event `CaseTimelineEventType.caseClosed` (`'CASE_CLOSED'`) displayed with distinct lock icon, date, doctor details, and closure note.

---

### 2.2 Standalone Cases & Visits Desk (`DoctorCaseScreen`)
- **Route**: `AppRoutes.doctorCases` (`/doctor/cases`).
- **Sidebar Navigation**: Dedicated **Cases & Visits** item (`Icons.folder_outlined` / `Icons.folder_rounded`).
- **Filter Tabs**:
  - `All Cases (N)`
  - `Open Cases (N)`
  - `Closed Cases (N)`
- **Dynamic Search**: Filter by `patientId`, `caseId`, or medical `domain`.
- **Direct Workspace Transition**: Seamlessly opens any selected case in the `DoctorPatientWorkspaceScreen`.

---

### 2.3 Standalone Diagnostic Reports & Investigations Desk (`DoctorReportsScreen`)
- **Route**: `AppRoutes.doctorReports` (`/doctor/reports`).
- **Sidebar Navigation**: Dedicated **Reports & Diagnostics** item (`Icons.description_outlined` / `Icons.description_rounded`).
- **4 Operational Tabs**:
  - `Requested (N)`: Pending lab/radiology requests awaiting upload.
  - `Uploaded (N)`: Patient/lab-uploaded documents pending review with `[VIEW REPORT]` and `[MARK AS REVIEWED]` actions.
  - `Reviewed (N)`: Completed diagnostic reports reviewed by attending doctors.
  - `Visit Reports (N)`: Generated official AAYUSATHI Consultation Visit PDF documentation.
- **System PDF Integration**: Launches Windows default PDF viewer (`PdfOutputService.instance.openPdf`) with direct fallbacks.

---

### 2.4 Clinical Workspace Tab Stability & Anti-Shake Fix
- Replaced conditional single-child switching with `IndexedStack` inside `DoctorClinicalRecordsSection`.
- Preserves child subtree states (`Visit History` and `Case Timeline`), eliminating rendering jump, reflow flicker, and scroll reset during tab changes.

---

### 2.5 Trilingual Localization
Full localized string sets implemented across English, Hindi, and Marathi in [`lib/doctor/localization/doctor_strings.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/localization/doctor_strings.dart):
- `DoctorStrings` (English)
- `DoctorStringsHindi` (Hindi - हिन्दी)
- `DoctorStringsMarathi` (Marathi - मराठी)

---

## 3. Architecture & Data Model Updates

### 3.1 `ClinicalCase` Model Updates
```dart
class ClinicalCase {
  final String caseId;
  final String patientId;
  final String domain;
  final String title;
  final ClinicalCaseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int visitCount;
  final String? relevantHistory;
  
  // Phase D15 Closure Metadata
  final DateTime? closedAt;
  final String? closedByDoctorId;
  final String? closedByDoctorName;
  final String? closureNote;

  bool get isOpen => status == ClinicalCaseStatus.open;
  bool get isClosed => status == ClinicalCaseStatus.closed;
}
```

### 3.2 Case Timeline Event Types
```dart
enum CaseTimelineEventType {
  visitCreated,
  visitCompleted,
  transferRequested,
  transferAccepted,
  transferCancelled,
  caseClosed, // Phase D15
}
```

---

## 4. Repository & Backend Implementation

### 4.1 `CaseRepository` Interface
```dart
abstract class CaseRepository {
  Future<List<ClinicalCase>> getCasesForPatient(String patientId);
  Future<ClinicalCase?> getCaseById({required String patientId, required String caseId});
  Future<ClinicalCase> createCase(ClinicalCase clinicalCase);
  Future<void> updateCase(ClinicalCase clinicalCase);
  Future<ClinicalCase> closeCase({
    required String patientId,
    required String caseId,
    required String doctorId,
    String? doctorName,
    required String closureNote,
  });
  Future<List<ClinicalCase>> getAllCases();
}
```

### 4.2 `FirebaseCaseRepository`
- Implements atomic Firestore transaction:
  1. Validates document existence.
  2. Ensures case is currently `open`.
  3. Validates non-empty doctor closure note.
  4. Updates status to `closed` along with `closedAt`, `closedByDoctorId`, `closedByDoctorName`, and `closureNote`.
- Queries cross-patient cases via collectionGroup query for Cases & Visits desk.

### 4.3 `MockCaseRepository`
- Deterministic in-memory implementation with default fixtures for automated tests and offline preview.

---

## 5. Security, Audit & Safety Standards

| Action | Actor | Entity | Audit Action Code | Metadata |
|---|---|---|---|---|
| Checkbox Declaration Confirmed | DOCTOR | CLINICAL_CASE | `CASE_CLOSURE_DECLARATION_CONFIRMED` | `{patientId, caseId}` |
| Case Closure Finalized | DOCTOR | CLINICAL_CASE | `CASE_CLOSED` | `{patientId, caseId, closedByDoctorId, closedByDoctorName, closureNote}` |

---

## 6. Verification & Test Coverage

- **New Test Suite**: `test/doctor/doctor_d15_test.dart` (34 tests, 100% passing).
- **Full Project Regression**: `flutter test` (652 tests, 0 failures, 100% passing).
- **Static Analysis**: `flutter analyze` (0 issues found).
- **Windows Production Release Build**: `flutter build windows --release` built successfully into `build\windows\x64\runner\Release\aayusathi.exe`.

---

## 7. Doctor Module Status

**DOCTOR MODULE COMPLETE — READY FOR PATIENT APP**
