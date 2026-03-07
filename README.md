# DOOM II: Hell on Earth — Browser Edition

Play Doom II locally in your browser using js-dos (DOSBox in WebAssembly).

---

## Quick Start (Windows)

1. Place `DOOM2.WAD` in this folder (same folder as `setup.bat`)
2. Double-click **`setup.bat`**
   - Downloads all required engine files (~9 MB total, one time only)
   - Starts the local HTTP server on port 8080
   - Opens `http://localhost:8080` in your browser automatically
3. Drag & drop your `DOOM2.WAD` onto the browser page (or click to browse)
4. Click **▶ LAUNCH GAME**

To play again later, just double-click `setup.bat` again — it skips already-downloaded files and goes straight to starting the server.

---

## Quick Start (Linux / macOS)

```bash
# Make the server script executable (first time only)
chmod +x server.sh

# Download engine files first (requires curl):
mkdir -p js-dos
BASE=https://js-dos.com/v7/build/releases/latest/js-dos
curl -L --ssl-no-revoke "${BASE}/js-dos.js"    -o js-dos/js-dos.js
curl -L --ssl-no-revoke "${BASE}/js-dos.css"   -o js-dos/js-dos.css
curl -L --ssl-no-revoke "${BASE}/wdosbox.js"   -o js-dos/wdosbox.js
curl -L --ssl-no-revoke "${BASE}/wdosbox.wasm" -o js-dos/wdosbox.wasm
curl -L "https://cdn.jsdelivr.net/npm/fflate@0.8.2/umd/index.js" -o js-dos/fflate.min.js
curl -L "https://cdn.dos.zone/custom/dos/doom2.jsdos" -o js-dos/doom2.jsdos

# Start the server
./server.sh
```

Then open `http://localhost:8080` and drop in your WAD file.

---

## File Structure

```
📁 doom-browser/
├── index.html        <- Main game launcher (open via the server, not directly)
├── server.ps1        <- PowerShell HTTP server (Windows)
├── server.sh         <- Bash HTTP server (Linux / macOS)
├── setup.bat         <- One-click download + server launcher (Windows)
├── README.md         <- This file
└── 📁 js-dos/        <- Created by setup.bat
    ├── js-dos.js
    ├── js-dos.css
    ├── wdosbox.js
    ├── wdosbox.wasm
    ├── fflate.min.js
    └── doom2.jsdos   <- Base bundle (contains DOOM2.EXE, no WAD data)
```

Your `DOOM2.WAD` stays on your machine — it is read directly by your browser and never uploaded anywhere. The `doom2.jsdos` bundle contains only the DOS executable and DOSBox config, not any copyrighted game data.

---

## Why a local server?

Modern browsers block `SharedArrayBuffer` (required by WebAssembly threads) on
`file://` URLs. The server adds the required HTTP headers:

```
Cross-Origin-Opener-Policy:   same-origin
Cross-Origin-Embedder-Policy: require-corp
```

---

## Controls

These are the original vanilla Doom default keyboard controls, exactly as shipped with the game in 1993.

### Movement

| Key                        | Action                        |
|----------------------------|-------------------------------|
| Up Arrow                   | Move forward                  |
| Down Arrow                 | Move backward                 |
| Left Arrow                 | Turn left                     |
| Right Arrow                | Turn right                    |
| Alt + Left / Right Arrow   | Strafe left / right           |
| , (comma)                  | Strafe left                   |
| . (period)                 | Strafe right                  |
| Shift (hold)               | Run                           |
| Right Alt / Strafe On key  | Hold to strafe with turn keys |

### Combat & Interaction

| Key       | Action              |
|-----------|---------------------|
| Ctrl      | Fire weapon         |
| Space     | Use / Open door     |
| 1 – 7     | Select weapon       |

### Menu & HUD

| Key         | Action                  |
|-------------|-------------------------|
| Escape      | Open / close menu       |
| Enter       | Confirm menu selection  |
| Tab         | Toggle automap          |
| F1          | Help screen             |
| F2          | Save game               |
| F3          | Load game               |
| F4          | Sound volume            |
| F6          | Quicksave               |
| F7          | End game                |
| F9          | Quickload               |
| F10         | Quit                    |
| F11         | Gamma correction        |
| Pause       | Pause game              |
| - / +       | Decrease / increase screen size |

### DOSBox-specific

| Key           | Action                        |
|---------------|-------------------------------|
| Alt + Enter   | Toggle fullscreen             |
| Ctrl+F10      | Capture / release mouse       |

---

## Credits

### Tools & Engine

- **js-dos v7** by [@caiiiycuk](https://github.com/caiiiycuk)
  DOSBox compiled to WebAssembly, running in the browser.
  MIT License — https://js-dos.com

- **DOSBox**
  The DOS emulator that js-dos is built on.
  GPL v2 — https://www.dosbox.com

- **fflate** by [@101arrowz](https://github.com/101arrowz)
  Fast in-browser ZIP compression/decompression, used to patch the WAD into the bundle.
  MIT License — https://github.com/101arrowz/fflate

- **doom2.jsdos base bundle** hosted by [dos.zone](https://dos.zone)
  The official js-dos community game repository. Provides the DOS executable
  and DOSBox configuration. Does not contain copyrighted WAD data.
  https://cdn.dos.zone/custom/dos/doom2.jsdos

### Game

- **DOOM II: Hell on Earth** © 1994 id Software
  You must own a legitimate copy of the game to use your `DOOM2.WAD`.
  https://www.idsoftware.com

### This Project

- **Browser launcher, server scripts, and setup tooling**
  Built with assistance from [Claude](https://claude.ai) (Anthropic).
  Iteratively debugged and assembled across multiple sessions.

---

## Legal

You must own a legitimate copy of DOOM II to use this launcher. The `doom2.jsdos`
bundle downloaded by `setup.bat` contains only the game executable — your own
`DOOM2.WAD` provides all copyrighted game content and never leaves your machine.
This project does not have ownership or copyright over Doom II and is not endorsed by, affiliated with, or in any way connected id software or Bathesda softworks.
This project was made using readily avilible and free resources. If I am infringing on any sort of copyright laws, I'm doing so without knowing.
