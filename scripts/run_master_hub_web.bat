@echo off
echo ====================================================
echo Starting AAYUSATHI Master Gateway Hub (Port 8080)
echo URL: http://localhost:8080/
echo Access all 4 portals with 1-click from http://localhost:8080
echo ====================================================
cd /d "%~dp0\.."
flutter run -d web-server --web-port=8080
