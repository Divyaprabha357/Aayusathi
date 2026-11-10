@echo off
echo ====================================================
echo Starting AAYUSATHI Doctor Clinical Portal (Port 8082)
echo URL: http://localhost:8082/#/doctor
echo Credentials: Code: DOC-101 | Password: any | OTP: 123456
echo ====================================================
cd /d "%~dp0\.."
flutter run -d web-server --web-port=8082 --dart-define=INITIAL_ROUTE=/doctor --dart-define-from-file=supabase.env
