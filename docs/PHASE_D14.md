# AAYUSATHI — PHASE D14: DOCTOR CASE CONTINUATION & FOLLOW-UP WORKFLOW
**Tagline**: LIVE BETTER, TOGETHER  
**Module**: Doctor Clinical Workstation & Multi-Visit Case Continuation Subsystem  
**Date**: September 2026  

---

## 1. Executive Summary

Phase D14 establishes the **Doctor Case Continuation & Follow-Up Workflow** for the AAYUSATHI healthcare platform. This phase provides physicians with a seamless, robust workflow for managing an existing patient's ongoing clinical care across multiple visits under a single medical case.

```
PATIENT
   ↓
CASE (Status: OPEN)
   ↓
VISIT 1 (Status: Completed)
   ↓
VISIT 2 (Status: Completed)
   ↓
VISIT 3 (Status: Active / Follow-up)
   ↓
...
```

### Core Architectural Principles
1. **Case Hierarchy & Continuation**: When continuing care for an existing medical problem, a **NEW VISIT** is created under the **EXISTING CASE**. It does not create duplicate Patients or duplicate Cases.
2. **Case Lifecycle Integrity**: The parent `ClinicalCase` strictly remains **`OPEN`** (`ClinicalCaseStatus.open`) when visits are completed or continued. It is never auto-closed.
3. **Sequential Visit Numbering**: Every new visit under a case is assigned an atomically calculated sequential visit number (`maxNumber + 1`), starting at 1.
4. **Duplicate Active Visit Protection**: A case cannot have more than one active consultation simultaneously. If an active visit already exists for the case, creating a new visit is blocked and the doctor is presented with an option to **`[RETURN TO CONSULTATION]`**.
5. **Historical Visit Immutability**: Completed and transferred visits are strictly immutable (read-only).
6. **Doctor Presence Management**: Starting a new visit sets the doctor's workstation presence to **`IN_CONSULTATION`** (`DoctorPresenceState.inConsultation`).
7. **Strict Boundary Enforcement**: Phase D14 strictly pertains to the Doctor Workstation. No Patient App interfaces, patient logins, or mobile patient UIs were created.
8. **Zero-PII & Privacy Architecture**: Zero Aadhaar numbers, OTP codes, session tokens, passwords, or Gemini API keys are ever stored, displayed, or logged.

---

## 2. Architecture & Data Models

### 2.1 CaseTimelineEvent Model
Location: [`lib/doctor/models/case_timeline_event.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/models/case_timeline_event.dart)

The `CaseTimelineEvent` model represents chronological milestones within a clinical case.

```dart
enum CaseTimelineEventType {
  visitCreated,
  consultationCompleted,
  referralInitiated,
  referralAccepted,
  prescriptionGenerated,
  testOrdered,
  vitalRecorded,
  caseStatusChanged,
}

class CaseTimelineEvent {
  final String eventId;
  final String caseId;
  final String? visitId;
  final CaseTimelineEventType eventType;
  final String title;
  final String description;
  final String actorDoctorId;
  final String actorDoctorName;
  final String department;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  // Factory constructors:
  // - fromClinicalVisit(ClinicalVisit visit, {String? defaultDepartment})
  // - fromTransferRequest(PatientTransferRequest request, {bool isInitiation = true})
  // - fromMap(Map<String, dynamic> map)
  // - toMap()
}
```

---

## 3. Repositories & Backend Architecture

### 3.1 ClinicalVisitRepository Contract Updates
Location: [`lib/repositories/clinical_visit_repository.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/repositories/clinical_visit_repository.dart)

Extended with two core methods:
- `getActiveVisitForCase(String caseId)`: Returns the current active `ClinicalVisit` for a case if one exists, or `null`.
- `createNextVisit({caseId, patientId, doctorId, doctorName, department, reasonForVisit, vitals})`: Atomically creates the next sequential visit for an existing case.

### 3.2 MockClinicalVisitRepository
Location: [`lib/repositories/mock/mock_clinical_visit_repository.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/repositories/mock/mock_clinical_visit_repository.dart)

- In-memory thread-safe implementation.
- Validates that no active visit already exists for the case before creating a new visit (throws `StateError` on duplicate active visit attempts).
- Computes `visitNumber` as `(highest existing visitNumber for case) + 1`.
- Populates vitals, doctor credentials, and generates a deterministic `visitId`.

### 3.3 FirebaseClinicalVisitRepository
Location: [`lib/repositories/firebase/firebase_clinical_visit_repository.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/repositories/firebase/firebase_clinical_visit_repository.dart)

- Queries `/visits` collection where `caseId == caseId` and `status == 'active'` for active visit detection.
- Computes the next visit number atomically.
- Persists new visit document in `/visits/{visitId}` and increments `visitCount` on the parent case in `/cases/{caseId}`.
- Dev-mode protection: throws `StateError` if write is attempted when `DOCTOR_DEV_MODE=true`.

---

## 4. UI Components & Dialogs

### 4.1 DoctorStartNewVisitDialog
Location: [`lib/doctor/widgets/doctor_start_new_visit_dialog.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/widgets/doctor_start_new_visit_dialog.dart)

- Modal dialog presented when initiating a new consultation under an open case.
- Displays:
  - Patient Name, Age, Gender, and ID.
  - Parent Case ID badge.
  - Calculated Next Visit Number (e.g. `Visit #3`).
  - Doctor Name and Department.
- Configurable `Reason for Visit` text input with realtime validation.
- Responsive layout with `Wrap` action buttons to prevent layout overflow on narrow workstation viewports.

### 4.2 DoctorActiveVisitExistsDialog
Location: [`lib/doctor/widgets/doctor_active_visit_exists_dialog.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/widgets/doctor_active_visit_exists_dialog.dart)

- Guard dialog presented when a doctor attempts to create a new visit for a case that already has an in-progress active visit.
- Displays active visit details (Visit ID, Visit Number, Attending Doctor, Start Time).
- Provides actionable buttons:
  - **`[RETURN TO CONSULTATION]`**: Selects and navigates directly to the active visit in the workspace.
  - **`[DISMISS / CANCEL]`**: Closes the modal.

### 4.3 DoctorCaseTimelineView
Location: [`lib/doctor/widgets/doctor_case_timeline_view.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/widgets/doctor_case_timeline_view.dart)

- Chronological vertical timeline rendering all visits and transfers for the active case.
- Filter chips: `All`, `Completed`, `Transferred`, `Active`.
- Interactive cards displaying visit number, status chip, attending doctor, department, timestamp, chief complaint, diagnosis summary, and prescription counts.
- `VIEW VISIT DETAILS` callback for inspecting historical visits in read-only mode.

### 4.4 DoctorClinicalRecordsSection Integration
Location: [`lib/doctor/widgets/doctor_patient_workspace_widgets.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/widgets/doctor_patient_workspace_widgets.dart)

- Updated to a stateful widget with a Tab Bar switching between **`VISIT HISTORY`** and **`CASE TIMELINE`**.
- Integrated **Case Information Card** displaying Case ID, Total Visits count, and Case Status (`OPEN` vs `CLOSED`).
- Dynamic Action Button:
  - Displays **`CONTINUE CASE`** (`+ NEW VISIT`) when the case is `OPEN`.
  - Displays **`VIEW HISTORY`** when the case is `CLOSED`.
- Renders individual historical visit cards with sequential visit numbers (`Visit #1`, `Visit #2`), status badges (`COMPLETED`, `TRANSFERRED`, `ACTIVE`), doctor name, date, and chief complaints.

### 4.5 DoctorPatientWorkspaceScreen Flow
Location: [`lib/doctor/screens/doctor_patient_workspace_screen.dart`](file:///c:/DEVELOPEMENT/aayusathi/lib/doctor/screens/doctor_patient_workspace_screen.dart)

- Wired `_onAddVisit`, `_onSelectVisit`, and `_executeStartNewVisit`.
- Verifies existing active visits via `getActiveVisitForCase`. If found, displays `DoctorActiveVisitExistsDialog`.
- Shows `DoctorStartNewVisitDialog` to collect consultation details.
- Transitions doctor presence to `IN_CONSULTATION` upon starting the visit.
- Records audit log events (`CASE_CONTINUED`, `VISIT_CREATED`).

---

## 5. Security, Privacy & Audit Logging

### 5.1 Audit Log Events
| Event Action | Actor | Entity Type | Logged Metadata |
|---|---|---|---|
| `CASE_CONTINUED` | Consulting Doctor | `CLINICAL_CASE` | `caseId`, `patientId`, `visitId`, `visitNumber`, `department` |
| `VISIT_CREATED` | Consulting Doctor | `CLINICAL_VISIT` | `visitId`, `caseId`, `patientId`, `visitNumber`, `doctorId`, `department` |

### 5.2 Zero-PII Enforcement
- Zero Aadhaar numbers, OTP codes, auth passwords, doctor session tokens, or Gemini API keys stored or transmitted in case payloads, timeline events, or audit records.

---

## 6. Multi-Language Localization

Comprehensive trilingual support for English, Hindi, and Marathi across all Phase D14 strings:

| Key | English | Hindi (हिंदी) | Marathi (मराठी) |
|---|---|---|---|
| `continueCaseButton` | CONTINUE CASE | केस जारी रखें | केस सुरू ठेवा |
| `viewHistoryButton` | VIEW HISTORY | इतिहास देखें | इतिहास पहा |
| `caseTimelineTab` | CASE TIMELINE | केस टाइमलाइन | केस टाइमलाइन |
| `visitHistoryTab` | VISIT HISTORY | विज़िट इतिहास | भेट इतिहास |
| `startNewVisitTitle` | Start New Visit | नई विज़िट शुरू करें | नवीन भेट सुरू करा |
| `activeVisitExistsTitle` | Active Visit In Progress | सक्रिय विज़िट जारी है | सक्रिय भेट सुरू आहे |
| `returnToActiveVisitButton` | RETURN TO CONSULTATION | परामर्श पर वापस जाएं | सल्लामसलतीवर परत जा |
| `caseInformationLabel` | Case Information | केस जानकारी | केस माहिती |
| `totalVisitsLabel` | Total Visits | कुल विज़िट्स | एकूण भेटी |

---

## 7. Verification & Quality Assurance

### 7.1 Automated Test Suite
- **D14 Dedicated Suite**: [`test/doctor/doctor_d14_test.dart`](file:///c:/DEVELOPEMENT/aayusathi/test/doctor/doctor_d14_test.dart) — **48 / 48 Tests Passed (100%)**
  - Group 1: Case Hierarchy & Multi-Visit Continuation (5 tests)
  - Group 2: Sequential Visit Numbering (4 tests)
  - Group 3: Active Visit Concurrency Protection (4 tests)
  - Group 4: Case Timeline Event Model (6 tests)
  - Group 5: UI Dialogs (6 tests)
  - Group 6: Case Timeline UI View (5 tests)
  - Group 7: Doctor Workspace & Records Section Integration (6 tests)
  - Group 8: Presence, Audit & Security (6 tests)
  - Group 9: Trilingual Localization (6 tests)
- **Full Application Test Suite**: `flutter test` — All tests passing across the entire project.
- **Static Analysis**: `flutter analyze` — **0 issues, 0 warnings, 0 errors**.
