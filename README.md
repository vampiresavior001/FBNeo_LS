# FBNeo_LS

[日本語](README.ja.md)

Automatically applies [Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) to **Fightcade FBNeo** when you start a match.

- **Match**: makes FBNeo fullscreen (Alt+Enter) if it is windowed, then presses the Lossless Scaling hotkey.
- **Spectate**: does nothing.
- **Training mode**: does nothing (can be turned on in the settings).

It is a small PowerShell script. Nothing extra needs to be installed.

## Requirements

- Windows 10 / 11 (uses the built-in Windows PowerShell 5.1)
- [Fightcade](https://www.fightcade.com/) (FBNeo games)
- Lossless Scaling (paid, on Steam), running in the background
  - A hotkey set in Lossless Scaling (default: Ctrl+Alt+S). FBNeo_LS reads it from Lossless Scaling's settings, so you can change it.
  - **Auto Scale turned off** in the profile you use for FBNeo is recommended. Otherwise Lossless Scaling and FBNeo_LS may both try to start scaling.

## Install

1. Download this repository (**Code** > **Download ZIP**) and extract it anywhere, for example `C:\tools\FBNeo_LS`.
2. Double-click `start_FBNeo_LS.bat`.
3. Start a match in Fightcade. About 3 seconds after the FBNeo window appears, Lossless Scaling starts.

If that works, use one of these for everyday use:

| File | What it does |
|---|---|
| `start_FBNeo_LS.bat` | Start with a window that shows the log (good for checking) |
| `start_FBNeo_LS_hidden.bat` | Start without a window |
| `stop_FBNeo_LS.bat` | Stop FBNeo_LS |
| `enable_autostart.bat` | Start FBNeo_LS automatically when you sign in to Windows |
| `disable_autostart.bat` | Stop starting automatically |

- Only one copy runs at a time. Starting it again does nothing.
- `enable_autostart.bat` puts a shortcut in your Startup folder (no admin rights needed). Running it more than once is safe. If you move the folder, run it again.

## Settings

`FBNeo_LS.ini` is created next to the script the first time it runs. Edit it with Notepad and restart FBNeo_LS.

| Setting | Default | Meaning |
|---|---|---|
| `IncludeTraining` | `false` | Also scale training mode |
| `DelayMs` | `3000` | Time from the FBNeo window appearing to pressing the Lossless Scaling hotkey (ms) |
| `AltEnterOnMatch` | `true` | In a match, press Alt+Enter if FBNeo is not fullscreen |
| `AltEnterWaitMs` | `1000` | Time from the FBNeo window appearing to pressing Alt+Enter (ms) |
| `AltEnterRetryMs` | `800` | If still not fullscreen this long after Alt+Enter, press it again (ms) |
| `FallbackHotkey` / `FallbackModifiers` | `S` / `Control Alt` | Used only if Lossless Scaling's settings cannot be read |
| `SpectatePattern` / `MatchPattern` | `*quark:stream*` / `*quark:*` | How spectate and match are told apart from the FBNeo command line |
| `LogToFile` / `LogMaxKB` | `true` / `1024` | Write `FBNeo_LS.log`, and its maximum size |

## How it works

1. Every second, it looks for `fcadefbneo.exe` processes.
2. It decides the kind from the command line: `quark:stream` = spectate, other `quark:` = match, anything else = training.
3. For a match, it brings the FBNeo window to the front, presses Alt+Enter if needed, and then presses the Lossless Scaling hotkey.
4. The hotkey is read from `%LOCALAPPDATA%\Lossless Scaling\Settings.xml` each time. If Lossless Scaling is not running, no keys are sent.

Keys are sent with real scan codes. (Without them, FBNeo opened its "Load State" dialog and the game paused.)

## Troubleshooting

Look at `FBNeo_LS.log`, or start with `start_FBNeo_LS.bat` to see the log in a window.

| Log message | What to check |
|---|---|
| `LS hotkey NOT sent (Lossless Scaling is not running)` | Start Lossless Scaling first |
| `unknown LS hotkey` / `hotkey unknown` | Set the hotkey again in Lossless Scaling, or set `FallbackHotkey` |
| `still not fullscreen at ... ms` | Increase `AltEnterRetryMs` or `DelayMs` |
| `could not bring to front` | Another window kept the focus. Try again without clicking other windows |
| Scaling starts on spectate or does not start on a match | Fightcade may have changed its command line. Check `SpectatePattern` / `MatchPattern` |

- Windows may block scripts downloaded from the internet. The `.bat` files start PowerShell with `-ExecutionPolicy Bypass`, so normally this is not a problem. If it still does not start, right-click the ZIP > **Properties** > **Unblock** before extracting.
- Some antivirus software may warn about a hidden PowerShell window that sends key presses. That is what this script does. Read the script if you are not sure.

## Notes

- Tested with Vampire Savior (vsavj) on Fightcade FBNeo v0.2.97.44-55. Other games should work the same way, but they are not tested.
- This project is not affiliated with Fightcade, FBNeo, or Lossless Scaling.
- Use at your own risk.

## License

[MIT](LICENSE)
