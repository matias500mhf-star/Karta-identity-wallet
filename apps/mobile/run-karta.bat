@echo off
setlocal
cd /d "%~dp0"

echo ========================================
echo KARTA - Flutter Launcher
echo ========================================

echo [1/4] Checking Flutter...
where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter was not found in PATH.
  echo Install Flutter SDK and add flutter\bin to PATH.
  exit /b 1
)

flutter --version
if errorlevel 1 exit /b 1

echo [2/4] Getting dependencies...
flutter pub get
if errorlevel 1 exit /b 1

echo [3/4] Checking devices...
flutter devices

echo [4/4] Starting KARTA...
flutter run
endlocal
