# AAYUSATHI — Firebase Authentication & Security Setup Guide

**Project**: AAYUSATHI  
**Tagline**: LIVE BETTER, TOGETHER  
**Phase**: Phase 10 (Firebase Authentication + Role-Based Security Foundation)

---

## 1. Firebase Authentication Setup
The Firebase project is configured in Google Cloud / Firebase Console:
- **Project Name**: AAYUSATHI
- **Project ID**: `aayusathi-eb341`
- **Location**: `asia-south1`

---

## 2. Enabled Authentication Providers
- **Anonymous Provider**: **ENABLED** in Firebase Console.
  - Used for physical terminal authorization (Kiosk devices).
- **Email/Password**: Prepared for Doctor & Administrative credentials.
- **Phone Authentication**: Deliberately disabled for prototype; patient OTP flow currently operates via controlled mock verification and will be connected in a future phase.

---

## 3. Kiosk Authentication Approach
Physical Kiosks run in public or hospital environments where embedding administrative credentials, service accounts, or hardcoded passwords is an extreme security hazard.

### Kiosk Authentication Lifecycle:
1. **Device Initialization**: When the Kiosk application starts, `FirebaseAuthService.signInAnonymously()` authenticates the terminal session with Firebase.
2. **Session Persistence**: The anonymous identity remains active on the terminal device across multiple patient visits.
3. **Session Reset Boundary**:
   - When a patient check-in completes or times out, `KioskService.instance.resetSession()` wipes:
     - User registration type
     - Patient identity data
     - Entered Aadhaar digits
     - Patient ID input
     - OTP verification state
     - Temporary sensor vitals
     - Selected clinical OPD domain
     - Previous visit records
     - Appointment tickets
     - Session locale (resets to English)
   - **Crucially**, the authenticated device session (`BackendProvider.instance.authService.currentUser`) is **NOT** signed out, ensuring the terminal is immediately ready to serve the next patient without unauthenticated latency.

---

## 4. Role Architecture & Model

The system defines four distinct actor roles in `UserRole`:
```
                     UserRole
          ┌─────────────┼─────────────┬─────────────┐
          ▼             ▼             ▼             ▼
        kiosk        patient        doctor        admin
    (Terminal)     (Consumer)    (Clinician)    (Governance)
```

- **`kiosk`**: Physical check-in terminal. Can create new patient records, write vitals telemetry, create appointments, query doctor domain availability, and record append-only audit entries. Cannot browse/list the entire patient directory or delete records.
- **`patient`**: Individual consumer. Can only read and update their own patient profile (`authUid == request.auth.uid`), their own appointments, and their own vitals.
- **`doctor`**: Licensed physician. Can access clinical domain records, assigned consultations, diagnostic observations, and patient cases.
- **`admin`**: System administrator. Possesses collection list queries, user management, and escalation handling capabilities.

---

## 5. Cloud Firestore Security Model

Defined in `firestore.rules`:
1. **Unauthenticated Denial**:
   `request.auth != null` is enforced across all operations. Unauthenticated requests are immediately blocked.
2. **No Wildcard Permissions**:
   `allow read, write: if true;` is strictly forbidden.
3. **Plain-Text Aadhaar Prohibition**:
   The `patients` collection explicitly verifies:
   `!('aadhaarNumber' in request.resource.data) && !('aadhaar' in request.resource.data)`
4. **List/Query Protection**:
   `allow list` on `patients/` is restricted strictly to `isRole('admin')`. Kiosks and patients cannot enumerate or scrape the patient database.
5. **Append-Only Audit Logs**:
   The `auditLogs` collection permits creation but enforces `allow update, delete: if false;` to maintain an immutable compliance trail.

---

## 6. How Roles are Provisioned (Development vs. Production)

- **Development**:
  - The Kiosk authenticates as an anonymous user (`sign_in_provider == 'anonymous'`) and is recognized as a valid kiosk terminal.
  - Mock services (`MockAuthService`) allow unit testing all four roles deterministically.
- **Production**:
  - Roles will be assigned via **Firebase Custom Claims** using Firebase Admin SDK on a trusted backend:
    ```javascript
    admin.auth().setCustomUserClaims(uid, { role: 'kiosk' });
    ```
  - Firestore security rules inspect `request.auth.token.role` to verify claims without relying on client-supplied data.

---

## 7. How to Deploy Security Rules
Deploy the updated `firestore.rules` using the Firebase CLI:
```bash
firebase deploy --only firestore:rules
```
Ensure `firebase.json` links the rules:
```json
{
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

---

## 8. How to Test Authentication & Authorization
- Run automated unit tests:
  ```bash
  flutter test test/phase10/
  ```
- Run full regression suite:
  ```bash
  flutter test
  ```
- Run live diagnostic connection test:
  Launch the app and observe the `DevFirestoreConnectionTestService` log trace for `AUTHENTICATION SUCCESS`, `WRITE SUCCESS`, and `READ SUCCESS`.
