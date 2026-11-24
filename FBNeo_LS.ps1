# FBNeo_LS.ps1 - bring FBNeo to front, press Lossless Scaling hotkey (match only by default)
# Settings are in FBNeo_LS.ini (same folder). It is created with default values if missing.
# Log is written to FBNeo_LS.log (same folder).
# https://github.com/vampiresavior001/FBNeo_LS  (MIT License)

$version = '1.0.1'

# ---- default settings (used when FBNeo_LS.ini does not set them) ----
$cfg = [ordered]@{
    IncludeTraining   = $false            # also scale training mode
    DelayMs           = 3000              # time from window appearing to pressing LS hotkey
    AltEnterOnMatch   = $true             # match only: send Alt+Enter if FBNeo is not fullscreen
    AltEnterWaitMs    = 1000              # time from window appearing to sending Alt+Enter
    AltEnterRetryMs   = 800               # if still not fullscreen this long after Alt+Enter, send it again
    FallbackHotkey    = 'S'               # used only if LS Settings.xml cannot be read
    FallbackModifiers = 'Control Alt'
    SpectatePattern   = '*quark:stream*'  # FBNeo command line pattern for spectate
    MatchPattern      = '*quark:*'        # FBNeo command line pattern for match (checked after spectate)
    LogToFile         = $true
    LogMaxKB          = 1024              # when the log is bigger than this, it is renamed to .old
}

$baseDir        = $PSScriptRoot
$iniPath        = Join-Path $baseDir 'FBNeo_LS.ini'
$logPath        = Join-Path $baseDir 'FBNeo_LS.log'
$lsSettingsPath = Join-Path $env:LOCALAPPDATA 'Lossless Scaling\Settings.xml'
$lsProcessName  = 'LosslessScaling'

# ---- log ----
$startupMessages = New-Object System.Collections.ArrayList

function Write-Log([string]$msg) {
    Write-Host $msg
    if ($cfg.LogToFile) {
        try { Add-Content -LiteralPath $logPath -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $msg) -Encoding UTF8 } catch { }
    }
}

function Limit-LogSize {
    if (-not $cfg.LogToFile) { return }
    try {
        $fi = Get-Item -LiteralPath $logPath -ErrorAction SilentlyContinue
        if ($fi -and $fi.Length -gt ($cfg.LogMaxKB * 1KB)) {
            Move-Item -LiteralPath $logPath -Destination ($logPath + '.old') -Force
        }
    } catch { }
}

# ---- settings file ----
function Write-DefaultIni {
    $lines = @(
        '; FBNeo_LS settings. Lines starting with ; are comments.',
        '; Restart FBNeo_LS after changing this file.',
        '',
        '; Also scale training mode (true/false). Spectate is never scaled.',
        'IncludeTraining = false',
        '; Time from FBNeo window appearing to pressing the Lossless Scaling hotkey (ms).',
        'DelayMs = 3000',
        '; Match only: if FBNeo is not fullscreen, press Alt+Enter (true/false).',
        'AltEnterOnMatch = true',
        '; Time from FBNeo window appearing to pressing Alt+Enter (ms).',
        'AltEnterWaitMs = 1000',
        '; If FBNeo is still not fullscreen this long after Alt+Enter, press it again (ms).',
        'AltEnterRetryMs = 800',
        '',
        '; The Lossless Scaling hotkey is read from its Settings.xml.',
        '; These are used only if that file cannot be read.',
        'FallbackHotkey = S',
        'FallbackModifiers = Control Alt',
        '',
        '; How to tell spectate and match from the FBNeo command line (wildcards * and ?).',
        '; Spectate is checked first. Anything else is treated as training.',
        'SpectatePattern = *quark:stream*',
        'MatchPattern = *quark:*',
        '',
        '; Write FBNeo_LS.log (true/false), and its maximum size in KB.',
        'LogToFile = true',
        'LogMaxKB = 1024'
    )
    try {
        [IO.File]::WriteAllText($iniPath, (($lines -join "`r`n") + "`r`n"), (New-Object System.Text.ASCIIEncoding))
        [void]$startupMessages.Add("Created $iniPath with default settings.")
    } catch {
        [void]$startupMessages.Add("Cannot create ${iniPath}: $($_.Exception.Message)")
    }
}

function Read-Ini {
    if (-not (Test-Path -LiteralPath $iniPath)) { Write-DefaultIni; return }
    $n = 0
    foreach ($line in (Get-Content -LiteralPath $iniPath -Encoding UTF8)) {
        $n++
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith(';') -or $t.StartsWith('#') -or $t.StartsWith('[')) { continue }
        $i = $t.IndexOf('=')
        if ($i -lt 1) { [void]$startupMessages.Add("ini line ${n}: ignored (no '='): $t"); continue }
        $key = $t.Substring(0, $i).Trim()
        $val = $t.Substring($i + 1).Trim()
        $name = @($cfg.Keys | Where-Object { $_ -eq $key })   # case-insensitive match
        if ($name.Count -eq 0) { [void]$startupMessages.Add("ini line ${n}: unknown setting '$key' ignored"); continue }
        $name = $name[0]
        $old = $cfg[$name]
        if ($old -is [bool]) {
            if     ($val -match '^(true|1|yes|on)$')   { $cfg[$name] = $true }
            elseif ($val -match '^(false|0|no|off)$') { $cfg[$name] = $false }
            else { [void]$startupMessages.Add("ini line ${n}: '$val' is not true/false, using $old") }
        } elseif ($old -is [int]) {
            $num = 0
            if ([int]::TryParse($val, [ref]$num) -and $num -ge 0) { $cfg[$name] = $num }
            else { [void]$startupMessages.Add("ini line ${n}: '$val' is not a number, using $old") }
        } else {
            if ($val -ne '') { $cfg[$name] = $val }
        }
    }
    if ($cfg.AltEnterWaitMs -gt $cfg.DelayMs) {
        [void]$startupMessages.Add("AltEnterWaitMs is larger than DelayMs; Alt+Enter will be skipped.")
    }
}

Read-Ini
Limit-LogSize

# ---- allow only one instance ----
$createdNew = $false
$script:mutex = New-Object System.Threading.Mutex($true, 'Local\FBNeo_LS_single_instance', [ref]$createdNew)
if (-not $createdNew) {
    Write-Host "FBNeo_LS is already running. This copy will exit."
    Start-Sleep -Seconds 3
    exit 1
}

Add-Type -AssemblyName PresentationCore   # for System.Windows.Input.Key (LS key names)
Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }

    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] static extern bool AttachThreadInput(uint a, uint b, bool f);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr h, uint flags);
    [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr m, ref MONITORINFO mi);
    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr v);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();

    // Use real pixel coordinates even when Windows display scaling is not 100%.
    // Otherwise window and monitor sizes can be scaled and the fullscreen check can be wrong.
    public static string MakeDpiAware() {
        try { if (SetProcessDpiAwarenessContext(new IntPtr(-4))) return "per-monitor v2"; } catch { }
        try { if (SetProcessDPIAware()) return "system"; } catch { }
        return "unchanged";
    }

    public static bool Activate(IntPtr h) {
        if (IsIconic(h)) ShowWindow(h, 9);
        uint dummy;
        uint fgThread = GetWindowThreadProcessId(GetForegroundWindow(), out dummy);
        uint me = GetCurrentThreadId();
        bool attached = false;
        if (fgThread != 0 && fgThread != me) attached = AttachThreadInput(me, fgThread, true);
        BringWindowToTop(h);
        SetForegroundWindow(h);
        if (attached) AttachThreadInput(me, fgThread, false);
        System.Threading.Thread.Sleep(200);
        return GetForegroundWindow() == h;
    }

    // true if the window covers its whole monitor
    public static bool IsFullscreen(IntPtr h) {
        RECT r;
        if (!GetWindowRect(h, out r)) return false;
        MONITORINFO mi = new MONITORINFO();
        mi.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        if (!GetMonitorInfo(MonitorFromWindow(h, 2), ref mi)) return false;
        return r.Left <= mi.rcMonitor.Left && r.Top <= mi.rcMonitor.Top &&
               r.Right >= mi.rcMonitor.Right && r.Bottom >= mi.rcMonitor.Bottom;
    }

    // keys that need the "extended key" flag
    static bool IsExtended(int vk) {
        switch (vk) {
            case 0x21: case 0x22: case 0x23: case 0x24:             // PageUp PageDown End Home
            case 0x25: case 0x26: case 0x27: case 0x28:             // arrows
            case 0x2D: case 0x2E:                                   // Insert Delete
            case 0x5B: case 0x5C: case 0x5D:                        // LWin RWin Apps
            case 0x6F: case 0x90:                                   // Numpad / NumLock
            case 0xA3: case 0xA5:                                   // RCtrl RAlt
                return true;
        }
        return false;
    }

    static void Key(int vk, bool up) {
        byte sc = (byte)MapVirtualKey((uint)vk, 0);
        uint fl = (up ? 2u : 0u) | (IsExtended(vk) ? 1u : 0u);
        keybd_event((byte)vk, sc, fl, UIntPtr.Zero);
    }

    // Press keys in order, release in reverse order. Always with scan codes, like a real keyboard.
    // (With scan code 0, FBNeo opened its "Load State" dialog in training mode, which pauses the game.)
    public static void SendCombo(int[] vks) {
        for (int i = 0; i < vks.Length; i++) { Key(vks[i], false); System.Threading.Thread.Sleep(30); }
        System.Threading.Thread.Sleep(20);
        for (int i = vks.Length - 1; i >= 0; i--) { Key(vks[i], true); System.Threading.Thread.Sleep(30); }
    }

    // with scan codes and hold time so that DirectInput-based apps can see it
    public static void SendAltEnter() {
        keybd_event(0x12, 0x38, 0, UIntPtr.Zero);  // Alt down
        System.Threading.Thread.Sleep(50);
        keybd_event(0x0D, 0x1C, 0, UIntPtr.Zero);  // Enter down
        System.Threading.Thread.Sleep(100);
        keybd_event(0x0D, 0x1C, 2, UIntPtr.Zero);  // Enter up
        System.Threading.Thread.Sleep(50);
        keybd_event(0x12, 0x38, 2, UIntPtr.Zero);  // Alt up
    }

    public static string RectInfo(IntPtr h) {
        RECT r; GetWindowRect(h, out r);
        MONITORINFO mi = new MONITORINFO();
        mi.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        GetMonitorInfo(MonitorFromWindow(h, 2), ref mi);
        return "window=" + r.Left + "," + r.Top + "," + r.Right + "," + r.Bottom +
               " monitor=" + mi.rcMonitor.Left + "," + mi.rcMonitor.Top + "," + mi.rcMonitor.Right + "," + mi.rcMonitor.Bottom;
    }
}
"@

$dpiMode = [Win]::MakeDpiAware()

# ---- LS hotkey ----

# key name (as written in LS Settings.xml, e.g. "S", "F12", "D1") -> virtual-key code, or 0
function Get-KeyVk([string]$name) {
    try {
        $k = [System.Windows.Input.Key]$name
        $vk = [System.Windows.Input.KeyInterop]::VirtualKeyFromKey($k)
        if ($vk -gt 0) { return [int]$vk }
    } catch { }
    try { return [int]([System.Windows.Forms.Keys]$name) } catch { }
    return 0
}

# returns @{ Vks = int[]; Text = string }, or $null if the hotkey cannot be used
function Get-LsHotkey {
    $key = $cfg.FallbackHotkey; $mods = $cfg.FallbackModifiers; $src = 'fallback'
    try {
        if (Test-Path -LiteralPath $lsSettingsPath) {
            [xml]$x = Get-Content -LiteralPath $lsSettingsPath -Raw -Encoding UTF8
            $k = [string]$x.Settings.Hotkey
            if ($k.Trim() -ne '') {
                $key = $k.Trim(); $mods = [string]$x.Settings.HotkeyModifierKeys; $src = 'Settings.xml'
            }
        }
    } catch {
        Write-Log "  cannot read LS Settings.xml: $($_.Exception.Message)"
    }

    $vks = @()
    foreach ($m in ($mods -split '[\s,]+')) {
        switch ($m) {
            ''        { }
            'None'    { }
            'Control' { $vks += 0x11 }
            'Alt'     { $vks += 0x12 }
            'Shift'   { $vks += 0x10 }
            'Windows' { $vks += 0x5B }
            default   { Write-Log "  unknown LS modifier key: $m"; return $null }
        }
    }
    # press modifiers in a fixed order: Ctrl, Alt, Shift, Win
    $order = @{ 0x11 = 0; 0x12 = 1; 0x10 = 2; 0x5B = 3 }
    $vks = @($vks | Sort-Object -Unique | Sort-Object { $order[$_] })

    $vk = Get-KeyVk $key
    if ($vk -eq 0) { Write-Log "  unknown LS hotkey: $key"; return $null }
    $vks += $vk
    return @{ Vks = [int[]]$vks; Text = "$mods+$key ($src)" }
}

# ---- FBNeo windows ----

function Get-Hwnd($procId) {
    $pr = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($pr) { return $pr.MainWindowHandle }
    return [IntPtr]::Zero
}

function Bring-ToFront($procId) {
    for ($i = 0; $i -lt 5; $i++) {
        $h = Get-Hwnd $procId
        if ($h -eq [IntPtr]::Zero) { return $false }
        if ([Win]::Activate($h)) { return $true }
        Start-Sleep -Milliseconds 1000
    }
    return $false
}

function Handle-New($procId, $kind) {
    $deadline = (Get-Date).AddSeconds(15)
    while ((Get-Hwnd $procId) -eq [IntPtr]::Zero) {
        if ((Get-Date) -gt $deadline) { Write-Log "pid=$procId kind=$kind window did not appear"; return }
        if (-not (Get-Process -Id $procId -ErrorAction SilentlyContinue)) { return }
        Start-Sleep -Milliseconds 300
    }
    $t0 = Get-Date
    Write-Log "pid=$procId kind=$kind window appeared"
    [void](Bring-ToFront $procId)
    $delayMs = $cfg.DelayMs

    # match: make FBNeo fullscreen if it is not
    if ($kind -eq 'match' -and $cfg.AltEnterOnMatch) {
        Wait-Until $t0 $cfg.AltEnterWaitMs
        # The window can disappear for a moment while FBNeo re-creates it, so retry until the LS hotkey time.
        $h = Get-Hwnd $procId
        while ($h -eq [IntPtr]::Zero -and ((Get-Date) - $t0).TotalMilliseconds -lt ($delayMs - 300)) {
            if (-not (Get-Process -Id $procId -ErrorAction SilentlyContinue)) { return }
            Start-Sleep -Milliseconds 100
            $h = Get-Hwnd $procId
        }
        if ($h -eq [IntPtr]::Zero) { Write-Log "  Alt+Enter NOT sent (window not found)" }
        else {
            $full = [Win]::IsFullscreen($h)
            Write-Log "  fullscreen=$full $([Win]::RectInfo($h))"
            # Alt+Enter sent too early can be lost (FBNeo may still be setting up its window),
            # so check again and resend until shortly before the LS hotkey time.
            $lastSend = $null
            while (-not $full) {
                $ms = ((Get-Date) - $t0).TotalMilliseconds
                if ($ms -ge ($delayMs - 300)) { Write-Log "  still not fullscreen at $([int]$ms) ms"; break }
                if ($lastSend -eq $null -or ((Get-Date) - $lastSend).TotalMilliseconds -ge $cfg.AltEnterRetryMs) {
                    if (Bring-ToFront $procId) {
                        [Win]::SendAltEnter(); $lastSend = Get-Date
                        Write-Log "  Alt+Enter sent at $([int](((Get-Date) - $t0).TotalMilliseconds)) ms"
                    } else { Write-Log "  Alt+Enter NOT sent (could not bring to front)"; break }
                }
                Start-Sleep -Milliseconds 100
                $h = Get-Hwnd $procId
                if ($h -ne [IntPtr]::Zero) { $full = [Win]::IsFullscreen($h) }
            }
            if ($full -and $lastSend -ne $null) {
                Write-Log "  fullscreen=True at $([int](((Get-Date) - $t0).TotalMilliseconds)) ms $([Win]::RectInfo($h))"
            }
        }
    }

    $doScale = ($kind -eq 'match') -or ($kind -eq 'training' -and $cfg.IncludeTraining)
    if ($doScale) {
        Wait-Until $t0 $delayMs
        # If LS is not running, the keys would go to FBNeo itself, so do not send them.
        if (-not (Get-Process -Name $lsProcessName -ErrorAction SilentlyContinue)) {
            Write-Log "  LS hotkey NOT sent (Lossless Scaling is not running)"
            return
        }
        $hk = Get-LsHotkey
        if (-not $hk) { Write-Log "  LS hotkey NOT sent (hotkey unknown)"; return }
        if (Bring-ToFront $procId) { [Win]::SendCombo($hk.Vks); Write-Log "  LS hotkey sent: $($hk.Text)" }
        else { Write-Log "  LS hotkey NOT sent (could not bring to front)" }
    }
}

# sleep until $ms milliseconds have passed since $t0
function Wait-Until($t0, $ms) {
    $left = $ms - ((Get-Date) - $t0).TotalMilliseconds
    if ($left -gt 0) { Start-Sleep -Milliseconds ([int]$left) }
}

# ---- main loop ----

Write-Log "FBNeo_LS $version running. Close this window (or run stop_FBNeo_LS.bat) to stop."
foreach ($m in $startupMessages) { Write-Log $m }
Write-Log ("settings: " + (($cfg.Keys | ForEach-Object { "$_=$($cfg[$_])" }) -join ' '))
Write-Log "DPI awareness: $dpiMode"
$hk0 = Get-LsHotkey
if ($hk0) { Write-Log "LS hotkey: $($hk0.Text)" } else { Write-Log "LS hotkey: unknown (check Lossless Scaling settings)" }

$seen = @{}
while ($true) {
    $alive = @{}
    foreach ($p in @(Get-CimInstance Win32_Process -Filter "Name='fcadefbneo.exe'")) {
        $id = [int]$p.ProcessId
        $alive[$id] = $true
        if ($seen.ContainsKey($id)) { continue }
        $seen[$id] = $true
        $cmd = [string]$p.CommandLine
        if     ($cmd -like $cfg.SpectatePattern) { $kind = 'spectate' }
        elseif ($cmd -like $cfg.MatchPattern)    { $kind = 'match' }
        else                                     { $kind = 'training' }  # training etc.
        Limit-LogSize
        Handle-New $id $kind
    }
    foreach ($k in @($seen.Keys)) { if (-not $alive.ContainsKey($k)) { $seen.Remove($k) } }
    Start-Sleep -Seconds 1
}
