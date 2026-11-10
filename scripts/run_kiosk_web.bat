@echo off
echo ====================================================
echo Starting AAYUSATHI Patient Kiosk Portal (Port 8081)
echo URL: http://localhost:8081/#/kiosk
echo ====================================================
cd /d "%~dp0\.."
flutter run -d web-server --web-port=8081 --dart-define=INITIAL_ROUTE=/kiosk
