@echo off
rem Start FBNeo_LS.ps1 in the background (no window). Stop it with stop_FBNeo_LS.bat.
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0FBNeo_LS.ps1"
