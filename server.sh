#!/usr/bin/env bash
# ============================================================
#  DOOM II – Local HTTP Server  (Bash / Linux & macOS)
#  Serves the current directory on http://localhost:8080
#  Mirrors server.ps1 functionality exactly.
# ============================================================

PORT="${1:-8080}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colour helpers ───────────────────────────────────────────
RED='\033[0;31m'
DRED='\033[0;31m'
YLW='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
DGY='\033[0;90m'
NC='\033[0m'

# ── MIME type lookup ─────────────────────────────────────────
mime_type() {
  case "${1,,}" in
    *.html|*.htm) echo "text/html; charset=utf-8" ;;
    *.js|*.mjs)   echo "application/javascript" ;;
    *.css)        echo "text/css" ;;
    *.wasm)       echo "application/wasm" ;;
    *.wad)        echo "application/octet-stream" ;;
    *.zip)        echo "application/zip" ;;
    *.gz)         echo "application/gzip" ;;
    *.json)       echo "application/json" ;;
    *.png)        echo "image/png" ;;
    *.jpg|*.jpeg) echo "image/jpeg" ;;
    *.gif)        echo "image/gif" ;;
    *.svg)        echo "image/svg+xml" ;;
    *.ico)        echo "image/x-icon" ;;
    *.ttf)        echo "font/ttf" ;;
    *.woff)       echo "font/woff" ;;
    *.woff2)      echo "font/woff2" ;;
    *)            echo "application/octet-stream" ;;
  esac
}

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${RED}  ██████╗  ██████╗  ██████╗ ███╗   ███╗${NC}"
echo -e "${RED}  ██╔══██╗██╔═══██╗██╔═══██╗████╗ ████║${NC}"
echo -e "${RED}  ██║  ██║██║   ██║██║   ██║██╔████╔██║${NC}"
echo -e "${DRED}  ██║  ██║██║   ██║██║   ██║██║╚██╔╝██║${NC}"
echo -e "${DRED}  ██████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║${NC}"
echo -e "${DRED}  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝${NC}"
echo ""
echo -e "${YLW}  DOOM II: Hell on Earth - Local Server${NC}"
echo -e "${DGY}  ─────────────────────────────────────${NC}"
echo -e "${GRN}  Listening : http://localhost:${PORT}/${NC}"
echo -e "${CYN}  Root dir  : ${ROOT}${NC}"
echo -e "${DGY}  Press Ctrl+C to stop.${NC}"
echo ""

# ── Check for Python (preferred) or fallback ────────────────
PYTHON=""
for cmd in python3 python; do
  if command -v "$cmd" &>/dev/null; then
    PYTHON="$cmd"
    break
  fi
done

# ── Try netcat-based server for full header control ──────────
# We need Cross-Origin-Opener-Policy + Cross-Origin-Embedder-Policy
# for SharedArrayBuffer. Python's http.server doesn't support custom
# headers without a wrapper, so we use a Python wrapper script.

if [ -n "$PYTHON" ]; then
  echo -e "${DGY}  Using Python HTTP server with COOP/COEP headers.${NC}"
  echo ""

  # Open browser in background
  URL="http://localhost:${PORT}/"
  (sleep 1 && (
    xdg-open "$URL" 2>/dev/null ||
    open     "$URL" 2>/dev/null ||
    true
  )) &

  # Inline Python server with required security headers
  "$PYTHON" - "$PORT" "$ROOT" <<'PYEOF'
import sys, os, mimetypes
from http.server import HTTPServer, SimpleHTTPRequestHandler

port = int(sys.argv[1])
root = sys.argv[2]
os.chdir(root)

class DoomHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy",   "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin",  "*")
        self.send_header("Cache-Control",                "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):
        code = args[1] if len(args) > 1 else "???"
        color = "\033[0;32m" if str(code).startswith("2") else "\033[0;31m"
        reset = "\033[0m"
        print(f"  {args[0]}  {color}{code}{reset}")

server = HTTPServer(("localhost", port), DoomHandler)
try:
    server.serve_forever()
except KeyboardInterrupt:
    print("\n  Server stopped.")
    server.server_close()
PYEOF

# ── Fallback: check for npx/http-server ─────────────────────
elif command -v npx &>/dev/null; then
  echo -e "${DGY}  Python not found. Using npx http-server.${NC}"
  echo -e "${YLW}  Note: COOP/COEP headers may not be set — WASM threads may fail.${NC}"
  echo ""
  (sleep 1 && (xdg-open "http://localhost:${PORT}/" 2>/dev/null || open "http://localhost:${PORT}/" 2>/dev/null || true)) &
  npx --yes http-server "$ROOT" -p "$PORT" \
    --cors \
    -H "Cross-Origin-Opener-Policy: same-origin" \
    -H "Cross-Origin-Embedder-Policy: require-corp"

# ── Last resort: PHP ─────────────────────────────────────────
elif command -v php &>/dev/null; then
  echo -e "${DGY}  Python/Node not found. Using PHP built-in server.${NC}"
  echo -e "${YLW}  Note: COOP/COEP headers will not be set — SharedArrayBuffer disabled.${NC}"
  echo ""
  (sleep 1 && (xdg-open "http://localhost:${PORT}/" 2>/dev/null || open "http://localhost:${PORT}/" 2>/dev/null || true)) &
  php -S "localhost:${PORT}" -t "$ROOT"

else
  echo -e "${RED}  ERROR: No suitable HTTP server found.${NC}"
  echo -e "  Please install Python 3:  sudo apt install python3"
  echo -e "  Or Node.js:               https://nodejs.org"
  exit 1
fi
