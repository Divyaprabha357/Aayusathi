@echo off
echo ====================================================
echo Starting AAYUSATHI Hospital Admin Portal (Port 8083)
echo URL: http://localhost:8083/#/admin
echo Credentials: Username: admin01 | Password: aayusathi1226
echo ====================================================
cd /d "%~dp0\.."
flutter run -d web-server --web-port=8083 --dart-define=INITIAL_ROUTE=/admin
