@echo off
cd /d "%~dp0"
echo ============================================================
echo   Sign SCPclear.exe with a digital signature (Authenticode)
echo   - If a .pfx certificate is in this folder, it is used.
echo   - Otherwise a self-signed certificate for internal use is
echo     created and exported as SCPclear-cert.cer
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SIGN-EXE.ps1"
echo.
pause
