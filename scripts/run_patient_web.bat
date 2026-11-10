@echo off
echo ====================================================
echo Starting AAYUSATHI Patient Health Portal (Port 8084)
echo URL: http://localhost:8084/#/patient
echo Credentials: Patient ID: AAYU-102938 | OTP: 123456
echo ====================================================
cd /d "%~dp0\.."
flutter run -d web-server --web-port=8084 --dart-define=INITIAL_ROUTE=/patient --dart-define-from-file=supabase.env
