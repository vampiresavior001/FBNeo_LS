@echo off
rem Unregister FBNeo_LS from starting when you sign in to Windows.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0autostart.ps1" -Disable
pause
