# AAYUSATHI Phase D11: Reports, Investigations, Patient Uploads & Doctor Visit PDF

## 1. Overview & Objectives
Phase D11 establishes the end-to-end investigation request, patient upload, clinical document review, and official 9-section AAYUSATHI Visit Documentation PDF generation workflow.

Key principles enforced in this phase:
- **Zero AI Diagnosis / Interpretation**: Medical reports are uploaded and reviewed purely by qualified doctors; AI does not interpret or diagnose uploaded findings.
- **Hierarchy Preservation**: Follows the official hierarchy: `Patient -> Case -> Visit -> Investigations / Reports`.
- **Case Lifecycle Invariant**: Completing a consultation visit marks the visit as `COMPLETED` and sets doctor presence to `AVAILABLE`, but **strictly leaves the parent Clinical Case as `OPEN / ONGOING`**.
- **Report PDF Gating**: Final Visit Report PDF export requires all 8 structured consultation fields to be completed and the clinical summary to be marked `APPROVED BY DOCTOR`.
- **Zero Sensitive Data Exposure**: No plain-text Aadhaar, passwords, OTPs, or auth credentials are stored in investigation records, report metadata, PDF documents, or audit logs.

---

## 2. Architecture & Data Model

### A. Data Models
1. **`InvestigationRequest`** (`lib/doctor/models/investigation_request.dart`):
   - `investigationId` / `requestId`: Unique identifier
   - `patientId`, `caseId`, `visitId`: Hierarchy references
   - `requestedByDoctorId`, `department`: Attending physician metadata
   - `name`: Clinical investigation title (e.g. *12-Lead ECG*, *Complete Blood Count (CBC)*)
   - `category`: `InvestigationCategory` (`lab`, `radiology`, `diagnostic`, `other`)
   - `priority`: `InvestigationPriority` (`required`, `asAdvised`)
   - `status`: `InvestigationStatus` (`pendingUpload`, `uploaded`, `reviewed`, `cancelled`)
   - `requestedAt`, `uploadedAt`, `reviewedAt`, `reviewedByDoctorId`, `uploadedReportId`, `notes`

2. **`ReportDocument`** (`lib/doctor/models/report_document.dart`):
   - `reportId`, `patientId`, `caseId`, `visitId`, `investigationId`
   - `fileName`, `contentType`, `fileSizeBytes`, `storagePath`
   - `uploadedAt`, `uploadedByPatientId`
   - `reviewStatus`: `ReportReviewStatus` (`uploaded`, `reviewed`)
   - `reviewedAt`, `reviewedByDoctorId`, `downloadUrl`, `notes`

3. **`VisitReportData`** (`lib/doctor/models/visit_report_data.dart`):
   - Aggregate DTO holding all data required for the official 9-section AAYUSATHI Visit Documentation.

---

## 3. Firestore & Storage Paths

### Cloud Firestore
- Investigations Subcollection:
  `patients/{patientId}/cases/{caseId}/visits/{visitId}/investigations/{investigationId}`
- Report Metadata Subcollection:
  `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{reportId}`

### Firebase Cloud Storage
- Binary Documents Path:
  `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{investigationId}/{fileName}`

---

## 4. Official 9-Section AAYUSATHI Visit PDF Structure

The generated PDF strictly conforms to the official layout:

```text
------------------------------------------------
AAYUSATHI
LIVE BETTER, TOGETHER
CASE & VISIT DOCUMENTATION
------------------------------------------------

SECTION 1 — VISIT IDENTIFICATION
Patient ID | Case ID | Visit | Status | Department | Date / Time

SECTION 2 — PATIENT INFORMATION
Name | Age | Gender | Blood Group | Patient Type | Doctor

SECTION 3 — VITALS AT CONSULTATION
SpO₂ | Blood Pressure | Heart Rate | Temperature

SECTION 4 — CASE INFORMATION
Case Title | Case Type | Case Status | Previous Relevant History

SECTION 5 — STRUCTURED CONSULTATION
Chief Complaint | Onset / Duration | Associated Symptoms | Medical History |
Current Medication | Clinical Observations | Assessment | Plan

(Prescription Table RX)

SECTION 6 — DOCTOR-APPROVED VISIT SUMMARY
Summary Text | Status: APPROVED BY DOCTOR

SECTION 7 — REPORTS / INVESTIGATIONS REQUESTED
Investigation Name | Category | Priority | Status

SECTION 8 — PLAN / FOLLOW-UP
Follow-up Advice | Patient Instructions

SECTION 9 — VISIT COMPLETION
Visit | Case | Consulting Doctor | Doctor Qualification | Summary Approval Status
------------------------------------------------
```

---

## 5. Development & Test Mode

When `DOCTOR_DEV_MODE=true` is enabled:
- `BackendProvider` routes repository calls to `MockInvestigationRepository`, `MockReportRepository`, and `MockStorageService`.
- Zero writes are sent to Google Cloud Firestore or Firebase Storage.
- Full offline testing and CI validation can run deterministically with pre-seeded demo records.

---

## 6. Security Guarantees
- Unauthenticated access is denied across all endpoints.
- Role-based access control enforces doctor consultation boundaries.
- Storage validation rejects unauthorized file extensions, oversized files (> 15 MB), and mismatched MIME/magic byte headers.
- Audit logging logs minimal operational metadata (`INVESTIGATION_REQUESTED`, `REPORT_UPLOADED`, `REPORT_REVIEWED`, `VISIT_REPORT_PREVIEWED`, `VISIT_REPORT_GENERATED`) with zero sensitive patient PII.
