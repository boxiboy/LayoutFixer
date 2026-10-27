<p align="center">
  <img src="assets/cover.png" alt="LayoutFixer: typed in the wrong layout? Just press Tab. A popup suggests 'this instead' for the mistyped Persian text فاهس هدسفثشی.">
</p>

<p align="center">
  Typed a whole sentence with the wrong keyboard layout? Press <kbd>Tab</kbd>.<br>
  A tiny macOS menu bar app that fixes English ⇄ Persian layout mistakes as you type.
</p>

<p align="center">
  <a href="https://github.com/sina-developer/LayoutFixer/releases/latest"><b>Download for macOS</b></a>
</p>

## See it in action

<p align="center">
  <a href="https://github.com/sina-developer/LayoutFixer/releases/download/v0.1.0/layoutfixer-16x9.mp4">
    <img src="assets/demo.gif" width="800" alt="LayoutFixer demo: a message typed on the Persian layout is detected, a popup suggests 'want to grab lunch today', Tab fixes it and switches the keyboard to English.">
  </a>
</p>


---

You meant to write:

```
want to grab lunch today
```

but the keyboard was still on Persian, so you got:

```
صشدف فخ لقشذ معدزا فخیشغ
```

LayoutFixer notices, shows a small popup next to your cursor, and when you press <kbd>Tab</kbd> it
retypes the text in the right language **and switches your keyboard layout** for you. It works the
other way too: `sghl` → `سلام`.

## Features

- Works in every app: browsers, chat apps, editors, mail.
- Asks before changing anything. <kbd>Tab</kbd> fixes it, <kbd>Esc</kbd> (or just keep typing) ignores it.
- Fixes the whole run of wrong words, not just the last one.
- Switches the active input source so the next words come out right.
- Reads your real keyboard layouts (ABC, US, Persian, Persian-ISIRI 2901, …), so the key mapping
  always matches your keyboard.
- Fully offline. Nothing is stored or sent anywhere.

## Install

You need macOS 13 or later, and both an English and a Persian keyboard layout enabled in
**System Settings → Keyboard → Text Input**.

### Download

1. Download `LayoutFixer-x.y.z.zip` from the
   [latest release](https://github.com/sina-developer/LayoutFixer/releases/latest) and unzip it.
2. Move `LayoutFixer.app` to **Applications**.
3. The app isn't notarized by Apple yet, so macOS blocks the first launch. Either:
   - open it once, then go to **System Settings → Privacy & Security** and click **Open Anyway**, or
   - run this in Terminal:
     ```bash
     xattr -dr com.apple.quarantine /Applications/LayoutFixer.app
     ```

Runs on Apple silicon and Intel Macs.

### Build from source

```bash
git clone https://github.com/sina-developer/LayoutFixer.git
cd LayoutFixer
./scripts/build.sh
open build/LayoutFixer.app
```

Only the Xcode Command Line Tools are needed (`xcode-select --install`). Xcode itself isn't.

### First launch

LayoutFixer needs **Accessibility** permission to see what you type and to retype corrections.
macOS will ask on first launch. Turn on **LayoutFixer** in
**System Settings → Privacy & Security → Accessibility**. It starts working within a couple of
seconds, with no restart needed.

> The build is ad-hoc signed. After rebuilding, macOS may treat it as a new app: switch the
> Accessibility toggle off and on again.

To start it at login, add it in **System Settings → General → Login Items**.

## How it works

LayoutFixer only suggests a fix when the other reading is a **real word**:

| You're typing on… | It flags a word when… | Suggests |
|---|---|---|
| Persian layout | the same keys spell a common English word (`صشدف` → `want`) | English |
| English layout | it isn't an English word **and** the same keys spell a real Persian word (`sghl` → `سلام`) | Persian |

So names, brands and typos (`github`, `figma`, `teh`) are never touched: their Persian reading is
gibberish.

Details:

- Words are checked when you press <kbd>Space</kbd>.
- 2-letter words are ambiguous (the Persian word `شد` is `an` on English keys), so they're only
  included when the word next to them is clearly wrong too.
- The physical key codes are recorded and translated with the other layout through
  `UCKeyTranslate`, so the conversion is exact for whatever layouts you use.
- The word lists are 50k-word English and Persian frequency lists (bundled) plus `/usr/share/dict/words`.

Known limits:

- The popup is placed at the text cursor via the Accessibility API. Apps that don't report the
  cursor position (some Electron apps) get it at the mouse pointer instead.
- macOS blocks key monitoring in password fields (Secure Input), so it never runs there.

## Privacy

This is a keyboard monitor, so here is exactly what it does:

- It keeps only the last few words you typed, in memory, to check them and retype them.
- The buffer is cleared when you click, use arrow keys, use shortcuts, or switch apps.
- Nothing is written to disk, logged, or sent over the network. The app makes no network requests.

The whole app is one file, [`Sources/main.swift`](Sources/main.swift). You can read all of it.

## Development

```
Sources/main.swift      the app: event tap, detection, popup, menu bar
Resources/              word list, app icon, menu bar icon
icon/make_icon.swift    draws the icons (run scripts/make-icons.sh)
icon/make_cover.swift   draws assets/cover.png and social-preview.png
promo/                  the demo video: motion.html (scene), soundtrack.js, render.mjs
scripts/build.sh        builds build/LayoutFixer.app (--zip for a release zip)
```

You can test detection without the app running:

```bash
./build/LayoutFixer.app/Contents/MacOS/LayoutFixer --test "صشدف لقشذ معدزا"
# صشدف -> want  FIX
# لقشذ -> grab  FIX
# معدزا -> lunch  FIX
```

Ideas and pull requests are welcome, for example:

- More language pairs (Arabic, Russian, Hebrew, …)
- A settings window (auto-fix without asking, per-app exclusions)
- Learning from words you dismiss
- A signed and notarized release

## Credits

- English and Persian word frequencies: [FrequencyWords](https://github.com/hermitdave/FrequencyWords) by
  Hermit Dave, licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
  See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

[MIT](LICENSE)
