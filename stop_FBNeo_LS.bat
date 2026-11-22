@echo off
rem Stop FBNeo_LS.ps1 (started by start_FBNeo_LS.bat or start_FBNeo_LS_hidden.bat).
rem Only PowerShell processes running FBNeo_LS.ps1 are stopped.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$n = 0; Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*-File*FBNeo_LS.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force; $n++ }; Write-Host \"Stopped: $n\""
pause
