@echo off
rem Start FBNeo_LS.ps1 in the background (no window). Stop it with stop_FBNeo_LS.bat.
rem conhost.exe is used so that the window can be hidden even when Windows Terminal is the default terminal.
start "" "%SystemRoot%\System32\conhost.exe" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0FBNeo_LS.ps1"
