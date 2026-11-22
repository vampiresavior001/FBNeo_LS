@echo off
rem Register FBNeo_LS to start when you sign in to Windows (shortcut in your Startup folder).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0autostart.ps1" -Enable
pause
