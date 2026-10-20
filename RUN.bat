@echo off
cd /d "%~dp0"
set "PS1=%~dp0SCPclear.ps1"
if not exist "%PS1%" (
  for %%F in ("%~dp0*.ps1") do set "PS1=%%F"
)
if not exist "%PS1%" (
  echo.
  echo ERROR: No .ps1 file found in this folder!
  echo.
  echo Fix: put SCPclear.ps1 in the SAME folder as this file.
  echo Also turn ON  View ^> Show ^> File name extensions
  echo and make sure the file is SCPclear.ps1  (NOT SCPclear.ps1.txt)
  echo.
  pause
  exit /b
)
echo Opening SCPclear...
echo Using: "%PS1%"
echo If a UAC window pops up, click YES. The program opens in a second window.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
echo.
echo ==============================================
echo  Done. If you see red text above, screenshot it.
echo ==============================================
pause
