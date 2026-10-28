# LayoutFixer for Windows (preview)

The Windows version of LayoutFixer: same idea, same rules, same Tab-to-fix popup, living in the
system tray instead of the menu bar.

## Install

Download the zip from the
[windows-preview release](https://github.com/sina-developer/LayoutFixer/releases/tag/windows-preview)
(`x64` for most PCs, `arm64` for Snapdragon/ARM laptops), unzip it anywhere and run `LayoutFixer.exe`.

- You need both an English and a Persian keyboard layout installed
  (**Settings → Time & language → Language & region**).
- No permissions to grant. Right-click the tray icon for **Enabled**, **Start with Windows** and **Quit**.
- The app isn't code-signed yet, so Windows may show *Windows protected your PC*:
  click **More info → Run anyway**.

## How it differs from the Mac version

| | Mac | Windows |
|---|---|---|
| Watches typing | event tap | low-level keyboard hook |
| Popup position | Accessibility API | Win32 caret, then UI Automation, then the mouse pointer |
| Switches layout | input source API | asks the active window to change its input language |
| Permission | Accessibility | none |

Known limits:

- Apps running **as administrator** can't be watched unless LayoutFixer also runs as administrator
  (a Windows security rule).
- Apps that don't report their text cursor get the popup at the mouse pointer.

## Build

Needs the .NET 10 SDK. It compiles on macOS and Linux too, but only runs on Windows.

```bash
dotnet publish windows/LayoutFixer.Windows.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

```bash
LayoutFixer.exe --test "صشدف لقشذ معدزا"
```

`data/words.txt` is Webster's Second International word list (public domain), the same list macOS
ships as `/usr/share/dict/words`. The other word lists are shared with the Mac app from `Resources/`.
