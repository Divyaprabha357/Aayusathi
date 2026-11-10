# AAYUSATHI — Cloud Storage Architecture (Phase D17.1)
**Tagline:** LIVE BETTER, TOGETHER.

---

## 1. Executive Summary

AAYUSATHI employs a hybrid dual-backend architecture:
1. **Firebase** (`aayusathi-a1199`, `asia-south1`): Authoritative database (Cloud Firestore), Authentication (Firebase Auth), Real-Time Queue & Appointments, Clinical Cases, Clinical Visits, and Audit Trail.
2. **Supabase Storage** (`xtgjpvejqzptjyrskuuk.supabase.co`): Authoritative Cloud File Storage provider managing binary medical assets in the private `aayusathi-reports` bucket.

```
AAYUSATHI Ecosystem
│
├── Firebase Backend (Authoritative State & Auth)
│   ├── Firebase Authentication (Kiosk, Doctors, Future Patients)
│   ├── Cloud Firestore (Asia-South1)
│   │   ├── patients/{patientId}
│   │   │   └── cases/{caseId}
│   │   │       └── visits/{visitId}
│   │   │           ├── investigations/{investigationId}
│   │   │           └── reports/{reportId} (Document Metadata)
│   │   ├── appointments
│   │   ├── doctors
│   │   └── audit_logs
│
├── Supabase Storage (Private Binary File Storage)
│   └── Bucket: aayusathi-reports (PRIVATE)
│       └── patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}
│
└── Flutter Client Application
    ├── Doctor Station / Portal
    ├── Kiosk Station
    └── Future Patient Mobile App
```

---

## 2. Storage Bucket & Security Model

- **Bucket Name**: `aayusathi-reports`
- **Visibility**: **PRIVATE** (Public read is strictly disabled).
- **Access Model**: Short-lived, time-limited signed URLs (`getSignedUrl` with 5-minute expiration) or direct authenticated streaming.
- **Client Security**: Flutter client embeds ONLY the publishable `anon` key. Secret and service-role keys are never placed in client code or source repositories.
- **Payload Constraints**:
  - Max file size: **15 MB**.
  - Whitelisted formats: `PDF`, `JPEG`, `PNG`.
  - Binary header / magic byte inspection enforced prior to cloud transmission.

---

## 3. Canonical Storage Path Hierarchy

Storage paths are deterministically structured and strictly scoped without exposing Aadhaar numbers or phone numbers:

### A. Official Physician Visit Report PDF
```
patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}
```
*Example:* `patients/PAT-102938/cases/CASE-001/visits/VIS-CASE-001-1/reports/AAYUSATHI_Visit_Report_PAT-102938_Visit_1.pdf`

### B. Diagnostic Investigation Reports
```
patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{investigationId}/{fileName}
```
*Example:* `patients/PAT-102938/cases/CASE-001/visits/VIS-CASE-001-1/reports/INV-ECG-01/ecg_lead_12.pdf`

### C. Patient-Uploaded Medical Documents
```
patients/{patientId}/cases/{caseId}/visits/{visitId}/uploads/{reportId}.{extension}
```

---

## 4. Dual-Path PDF Workflow & Local Fallback Resilience

The clinical workflow guarantees continuous availability regardless of internet connectivity:

```
[Doctor Workspace]
        │
        ▼
1. Complete Visit & Approve Summary
        │
        ▼
2. Generate Official 9-Section PDF
        │
        ▼
3. Write Local PDF to Disk (Documents/AAYUSATHI/VisitReports/)
        │
   ┌────┴────────────────────────┐
   ▼                             ▼
[Local PDF Ready]        [Non-Blocking Cloud Upload]
- "OPEN PDF" instant          - Upload to Supabase `aayusathi-reports`
- "SAVE AS" available         - Write `ReportDocument` metadata to Firestore
- Unaffected by network       - If fails: Local PDF preserved; status shows "Cloud upload pending"
```

---

## 5. Firestore Document Metadata Model

Firestore stores metadata references pointing to the Supabase storage path:

```json
{
  "reportId": "OFFICIAL-REPORT-VIS-CASE-001-1",
  "patientId": "AAYU-102938",
  "caseId": "CASE-001",
  "visitId": "VIS-CASE-001-1",
  "investigationId": "OFFICIAL_VISIT_REPORT",
  "fileName": "AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf",
  "contentType": "application/pdf",
  "fileSizeBytes": 218350,
  "storageProvider": "supabase",
  "storageBucket": "aayusathi-reports",
  "storagePath": "patients/AAYU-102938/cases/CASE-001/visits/VIS-CASE-001-1/reports/AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf",
  "uploadedAt": "2026-09-07T01:30:00.000Z",
  "uploadedByPatientId": "DOC-101",
  "reviewStatus": "reviewed",
  "reviewedAt": "2026-09-07T01:30:00.000Z",
  "reviewedByDoctorId": "DOC-101",
  "notes": "Official Physician Clinical Documentation PDF"
}
```

---

## 6. Future Patient App Integration Contract

The `PatientReportAccessService` abstraction prepares the future Patient Application:
- `getPatientReports(patientId)`: Retrieves medical documents across all cases and visits from Firestore.
- `getVisitReports(patientId, caseId, visitId)`: Scoped visit reports.
- `getReportAccessUrl(storagePath)`: Generates secure, short-lived signed URLs for temporary in-app PDF rendering.
