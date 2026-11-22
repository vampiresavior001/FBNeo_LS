# autostart.ps1 - register / unregister FBNeo_LS to start when you sign in to Windows.
# It puts a shortcut "FBNeo_LS.lnk" in your Startup folder (no admin rights needed).
#   autostart.ps1 -Enable    register
#   autostart.ps1 -Disable   unregister
param(
    [switch]$Enable,
    [switch]$Disable,
    [string]$StartupDir = [Environment]::GetFolderPath('Startup')   # can be changed for testing
)

$lnkPath = Join-Path $StartupDir 'FBNeo_LS.lnk'
$ps1Path = Join-Path $PSScriptRoot 'FBNeo_LS.ps1'

if ($Enable -eq $Disable) {
    Write-Host "Use -Enable or -Disable."
    exit 2
}

if ($Enable) {
    if (-not (Test-Path -LiteralPath $ps1Path)) {
        Write-Host "FBNeo_LS.ps1 not found: $ps1Path"
        exit 1
    }
    try {
        $sh  = New-Object -ComObject WScript.Shell
        $lnk = $sh.CreateShortcut($lnkPath)
        $lnk.TargetPath       = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $lnk.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ps1Path`""
        $lnk.WorkingDirectory = $PSScriptRoot
        $lnk.WindowStyle      = 7   # minimized, so the window does not flash
        $lnk.Description      = 'FBNeo_LS (Lossless Scaling for Fightcade FBNeo)'
        $lnk.Save()
    } catch {
        Write-Host "Could not create the shortcut: $($_.Exception.Message)"
        exit 1
    }
    Write-Host "Registered. FBNeo_LS will start when you sign in to Windows."
    Write-Host "  shortcut: $lnkPath"
    Write-Host "  script:   $ps1Path"
    Write-Host "If you move the FBNeo_LS folder, run enable_autostart.bat again."
    Write-Host "To start it now without signing out, run start_FBNeo_LS_hidden.bat."
    exit 0
}

if ($Disable) {
    if (Test-Path -LiteralPath $lnkPath) {
        try { Remove-Item -LiteralPath $lnkPath -Force } catch {
            Write-Host "Could not remove the shortcut: $($_.Exception.Message)"
            exit 1
        }
        Write-Host "Unregistered. FBNeo_LS will no longer start when you sign in."
    } else {
        Write-Host "Not registered (no shortcut found in $StartupDir)."
    }
    Write-Host "If FBNeo_LS is running now, it keeps running. Use stop_FBNeo_LS.bat to stop it."
    exit 0
}
