# LayoutFixer for Windows

The Windows version of LayoutFixer: same idea, same rules, same Tab-to-fix popup, living in the
system tray instead of the menu bar.

**Install:** see the [Windows install guide](../README.md#windows) in the main README.

## How it differs from the Mac version

| | Mac | Windows |
|---|---|---|
| Watches typing | event tap | low-level keyboard hook |
| Popup position | Accessibility API | Win32 caret, then UI Automation, then the mouse pointer |
| Switches layout | input source API | asks the focused window to change its input language |
| Permission | Accessibility | none |

## Code

```
src/Program.cs        entry point, tray icon, keyboard and mouse hooks, --test mode
src/Fixer.cs          tracks typing, decides when to suggest, retypes on Tab
src/Dictionaries.cs   the "real word" rules (same as the Mac app)
src/Layouts.cs        installed English/Persian layouts and key-to-character mapping
src/Popup.cs          the suggestion popup and caret lookup
src/Native.cs         Win32 calls
data/words.txt        Webster's word list (public domain); the other lists come from ../Resources
```

## Build

Needs the .NET 10 SDK. It compiles on macOS and Linux too, but only runs on Windows.

```bash
dotnet publish windows/LayoutFixer.Windows.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```
