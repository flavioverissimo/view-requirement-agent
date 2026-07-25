@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>nul
if errorlevel 1 (
    echo Windows PowerShell was not found on this computer.
    echo Run setup.ps1 manually if PowerShell is available under a different command.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup.ps1"
exit /b %ERRORLEVEL%
