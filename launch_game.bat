@echo off
setlocal

REM Arreter toute instance Godot precedente pour eviter les blocages
taskkill /F /IM Godot* /T >nul 2>&1
timeout /t 1 /nobreak >nul

for %%I in ("%~dp0.") do set "BASE_DIR=%%~fI"

set "PROJECT_DIR=%BASE_DIR%"
if exist "%BASE_DIR%\project.godot" (
    set "PROJECT_DIR=%BASE_DIR%"
) else if exist "%BASE_DIR%\godot-hd2d-pipeline\project.godot" (
    set "PROJECT_DIR=%BASE_DIR%\godot-hd2d-pipeline"
)

set "GODOT_EXE=%PROJECT_DIR%\tools\Godot_v4.3-stable_win64.exe"

if not exist "%GODOT_EXE%" (
    echo [ERROR] Godot not found at: %GODOT_EXE%
    pause
    exit /b 1
)

cd /d "%PROJECT_DIR%"
start "" "%GODOT_EXE%" --path "%PROJECT_DIR%" "res://scenes/main_hd2d_scene.tscn"

endlocal
exit /b 0
