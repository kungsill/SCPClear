@echo off
chcp 65001 >nul
rem ===== SCP Office: build the Thai edition of WordCraft (Word-like editor) =====
rem Needs Rust (cargo 1.95+). Output: dist\WordCraft-TH.exe
rem CRAFT_FONTS_DIR makes the build embed the open fonts of craft-fonts (Noto Sans Thai included).
set "HERE=%~dp0"
set "CRAFT_FONTS_DIR=%HERE%craft-fonts"
pushd "%HERE%wordcraft"
cargo build --release -p wordcraft
if errorlevel 1 (
  echo.
  echo Build failed.
  popd
  pause
  exit /b 1
)
popd
if not exist "%HERE%dist" mkdir "%HERE%dist"
copy /y "%HERE%wordcraft\target\release\wordcraft.exe" "%HERE%dist\WordCraft-TH.exe" >nul
echo.
echo Done: %HERE%dist\WordCraft-TH.exe
pause
