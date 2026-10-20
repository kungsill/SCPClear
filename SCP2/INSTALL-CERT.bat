@echo off
cd /d "%~dp0"
net session >nul 2>&1
if errorlevel 1 (
  echo Please right-click INSTALL-CERT.bat and choose "Run as administrator".
  pause
  exit /b
)
if not exist "%~dp0SCPclear-cert.cer" (
  echo ERROR: SCPclear-cert.cer not found. Run SIGN-EXE.bat first, then copy the .cer here.
  pause
  exit /b
)
echo ============================================================
echo   Trust the SCPclear signing certificate on THIS computer
echo   Only do this on computers in your own organization.
echo ============================================================
certutil -addstore -f Root "%~dp0SCPclear-cert.cer"
certutil -addstore -f TrustedPublisher "%~dp0SCPclear-cert.cer"
echo.
echo Done. Signed SCPclear.exe will now show a valid signature here.
pause
