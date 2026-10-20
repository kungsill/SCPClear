@echo off
cd /d "%~dp0"
set "PS1=%~dp0SCPclear.ps1"
if not exist "%PS1%" ( for %%F in ("%~dp0*.ps1") do set "PS1=%%F" )
if not exist "%PS1%" (
  echo ERROR: No .ps1 file found in this folder! Put SCPclear.ps1 here first.
  pause
  exit /b
)
set "ICO=%~dp0SCPclear.ico"
set "ICOARG="
if exist "%ICO%" set "ICOARG=-iconFile '%ICO%'"
echo ============================================================
echo   Building SCPclear.exe 2.3  (single file, portable)
echo   Using script: "%PS1%"
echo   Fonts / PdfSharp / icon are embedded inside the script.
echo   Needs internet only the first time (to install ps2exe).
echo ============================================================
echo.
powershell -NoProfile -Sta -ExecutionPolicy Bypass -Command ^
  "try { if (-not (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue)) { Write-Host 'Installing ps2exe...'; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue; Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber }; Import-Module ps2exe; Write-Host 'Compiling...'; Invoke-ps2exe -inputFile '%PS1%' -outputFile '%~dp0SCPclear.exe' %ICOARG% -requireAdmin -noConsole -STA -title 'SCPclear' -description 'SCPclear - PC care toolkit' -product 'SCPclear' -company 'SCPclear' -copyright 'Copyright (c) 2026 SCPclear' -version '2.3.0.0'; Write-Host ''; Write-Host 'SUCCESS: SCPclear.exe created!' } catch { Write-Host ('ERROR: ' + $_.Exception.Message) }"
echo.
if exist "%ProgramFiles%\Windows Defender\MpCmdRun.exe" if exist "%~dp0SCPclear.exe" (
  echo Checking SCPclear.exe with Windows Defender...
  "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 3 -File "%~dp0SCPclear.exe" -DisableRemediation
  echo.
)
echo ============================================================
echo  Done. SCPclear.exe is a single file - copy only this file.
echo  Optional: run SIGN-EXE.bat to add a digital signature.
echo ============================================================
pause
