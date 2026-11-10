# AAYUSATHI — Firebase Foundation & Firestore Setup Guide

**Project**: AAYUSATHI  
**Tagline**: LIVE BETTER, TOGETHER  
**Phase**: Phase 9 (Firebase Foundation + Firestore Data Architecture)

---

## 1. Firebase Project Creation
The central Firebase project for the AAYUSATHI healthcare platform is provisioned in the Google Firebase Console:
- **Project Name**: AAYUSATHI
- **Project ID**: `aayusathi-eb341`
- **Project Number**: `618079186276`

The project acts as the single source of truth across all platforms (Kiosk, Patient mobile, Doctor web/tablet, and Admin dashboard).

---

## 2. FlutterFire CLI Requirement
The FlutterFire CLI is required to generate platform configurations and bindings for Flutter projects.
- **CLI Version**: 1.4.1 or higher
- **Installation**:
  ```bash
  dart pub global activate flutterfire_cli
  ```
- Ensure the Dart global pub cache `bin` directory is present in your system `PATH`.

---

## 3. FlutterFire Configuration (`flutterfire configure`)
Configuration was executed via:
```bash
flutterfire configure --project=aayusathi-eb341
```
> **Note**: Do not re-run `flutterfire configure` unless genuine configuration issues arise or new platform targets are added.

---

## 4. Required Platforms
Firebase apps are registered for:
- **Android**: `com.example.aayusathi`
- **iOS**: `com.example.aayusathi`
- **Web**: Registered web client
- **macOS**: `com.example.aayusathi`
- **Windows**: Desktop client configuration

---

## 5. Cloud Firestore Database Setup
- **Database Name**: `(default)`
- **Database Engine**: Cloud Firestore in Native mode.
- **Top-Level Collections**:
  1. `patients` — Patient master index (Document ID = `patientId`, e.g. `AAYU-102938`). Plain text Aadhaar is NEVER stored.
  2. `doctors` — Medical specialists, assigned clinical domains, and live availability.
  3. `appointments` — Patient consultation requests, sequential queue tokens (`A-XXXXX`), status lifecycle.
  4. `vitals` — Hardware sensor measurements (HR, SpO2, Temperature, BP) and clinical validation flags.
  5. `visits` — Historical consultation records by clinical domain.
  6. `cases` — Long-term patient clinical case files.
  7. `prescriptions` — Doctor prescriptions and medication instructions.
  8. `reports` — Diagnostic and laboratory report metadata.
  9. `notifications` — Real-time event notifications for patients and staff.
  10. `escalations` — Abnormal vital alerts and triage escalations.
  11. `auditLogs` — Append-only immutable governance and access trail.

---

## 6. Development & Testing Mode (Dual-Backend Strategy)
To ensure the AAYUSATHI Kiosk can be run anywhere (offline clinics, unit test runners, developer laptops without Google cloud credentials), the codebase uses a dual-backend architecture:
- **`BackendMode.mock`**: Fully in-memory deterministic repositories containing fictional patient data (Aarav Sharma, Priya Patil, Rajesh Kulkarni, Sunita Deshmukh). Ideal for fast local development and CI testing.
- **`BackendMode.firebase`**: Connects directly to Cloud Firestore.

If Firebase initialization fails or network is disconnected, the app gracefully falls back to `BackendMode.mock` without crashing the Kiosk.

---

## 7. Where `firebase_options.dart` Comes From
- Location: `lib/firebase_options.dart`
- Generated automatically by FlutterFire CLI.
- Contains platform-specific `FirebaseOptions` (`web`, `android`, `ios`, `macos`, `windows`).
- **Never edit this file manually.**

---

## 8. How `BackendMode` is Selected
Dependency resolution is centralized in `BackendProvider`:
```dart
import 'package:aayusathi/core/backend/backend_mode.dart';

// Switch mode globally
BackendProvider.instance.setMode(BackendMode.firebase); // or BackendMode.mock
```
Screens and widgets interact with `KioskService` and repository interfaces (`PatientRepository`, `AppointmentRepository`, `VitalRepository`, `DoctorRepository`, `AuditRepository`) instead of calling Firestore directly.

---

## 9. Future Authentication Phase (Phase 10)
In Phase 9:
- No `firebase_auth` dependency is added.
- Kiosk patient identification is managed via the controlled Aadhaar and Patient ID lookup services.

In Phase 10+:
- Firebase Authentication will be introduced for Doctor, Patient, and Admin identity management.
- Multi-factor SMS OTP authentication and custom JWT claims (`role: 'kiosk' | 'patient' | 'doctor' | 'admin'`).

---

## 10. Future Production Security Rules
Development rules are defined in `firestore.rules`.
In production:
- `allow read, write: if true;` is **strictly forbidden**.
- Rules will enforce:
  - Role-Based Access Control (RBAC) via Firebase Auth token claims.
  - Patients can only read their own records and appointments.
  - Doctors can only view assigned domain patients.
  - Kiosk can write new registrations, appointments, and vitals.
  - `auditLogs` remains strictly append-only (no update or delete).
  - Aadhaar plain-text validation: any document containing `aadhaarNumber` will be rejected by rule assertion.
