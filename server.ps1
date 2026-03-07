# ============================================================
#  DOOM II - Local HTTP Server  (PowerShell)
#  Serves the current directory on http://localhost:8080
# ============================================================

param(
    [int]$Port = 8080
)

# Robustly find the script's own folder even when called from a .bat
if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
    $Root = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $Root = Split-Path $MyInvocation.MyCommand.Path -Parent
} else {
    $Root = (Get-Location).Path
}

$url = "http://localhost:$Port/"

Write-Host ""
Write-Host "  DOOM II: Hell on Earth - Local Server" -ForegroundColor Red
Write-Host "  ======================================" -ForegroundColor DarkRed
Write-Host "  Port    : $Port"       -ForegroundColor Green
Write-Host "  Serving : $Root"       -ForegroundColor Cyan
Write-Host "  URL     : $url"        -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

# MIME types
$mimeMap = @{
    '.html' = 'text/html; charset=utf-8'
    '.htm'  = 'text/html; charset=utf-8'
    '.js'   = 'application/javascript'
    '.mjs'  = 'application/javascript'
    '.css'  = 'text/css'
    '.wasm' = 'application/wasm'
    '.wad'  = 'application/octet-stream'
    '.zip'  = 'application/zip'
    '.gz'   = 'application/gzip'
    '.json' = 'application/json'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.gif'  = 'image/gif'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.ttf'  = 'font/ttf'
    '.woff' = 'font/woff'
    '.woff2'= 'font/woff2'
    '.txt'  = 'text/plain'
    '.md'   = 'text/plain'
}

function Get-Mime($path) {
    $ext = [System.IO.Path]::GetExtension($path)
    if ($mimeMap.ContainsKey($ext)) { return $mimeMap[$ext] }
    return 'application/octet-stream'
}

# Start HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

try {
    $listener.Start()
} catch {
    Write-Host ""
    Write-Host "[ERROR] Could not start listener on $url" -ForegroundColor Red
    Write-Host "  Is another process already using port $Port?" -ForegroundColor Yellow
    Write-Host "  Run: netstat -ano | findstr :$Port" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    pause
    exit 1
}

# Open browser
Start-Process $url
Write-Host "  Opened browser. Waiting for requests..." -ForegroundColor DarkGray
Write-Host ""

# Request loop
try {
    while ($listener.IsListening) {
        $ctx  = $listener.GetContext()
        $req  = $ctx.Request
        $resp = $ctx.Response

        # Required for SharedArrayBuffer / WASM threads
        $resp.Headers.Add("Cross-Origin-Opener-Policy",   "same-origin")
        $resp.Headers.Add("Cross-Origin-Embedder-Policy", "require-corp")
        $resp.Headers.Add("Access-Control-Allow-Origin",  "*")
        $resp.Headers.Add("Cache-Control",                "no-cache")

        $rawPath = $req.Url.AbsolutePath
        $relPath = [System.Uri]::UnescapeDataString($rawPath).TrimStart('/')
        if ([string]::IsNullOrEmpty($relPath)) { $relPath = 'index.html' }

        # Guard against path traversal
        $filePath = [System.IO.Path]::GetFullPath((Join-Path $Root $relPath))
        if (-not $filePath.StartsWith($Root)) {
            $resp.StatusCode = 403
            $resp.OutputStream.Close()
            continue
        }

        if (Test-Path $filePath -PathType Leaf) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $mime  = Get-Mime $filePath
                $resp.StatusCode      = 200
                $resp.ContentType     = $mime
                $resp.ContentLength64 = $bytes.Length
                $resp.OutputStream.Write($bytes, 0, $bytes.Length)
                Write-Host "  200  $rawPath" -ForegroundColor DarkGray
            } catch {
                $resp.StatusCode = 500
                Write-Host "  500  $rawPath  -- $_" -ForegroundColor Red
            }
        } else {
            $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $relPath")
            $resp.StatusCode      = 404
            $resp.ContentType     = 'text/plain'
            $resp.ContentLength64 = $body.Length
            $resp.OutputStream.Write($body, 0, $body.Length)
            Write-Host "  404  $rawPath" -ForegroundColor Yellow
        }

        $resp.OutputStream.Close()
    }
} catch [System.Net.HttpListenerException] {
    # Normal shutdown via Ctrl+C
} catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
} finally {
    $listener.Stop()
    Write-Host ""
    Write-Host "  Server stopped." -ForegroundColor Yellow
    Write-Host ""
    pause
}
