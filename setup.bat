@echo off
setlocal EnableDelayedExpansion

:: Re-launch in a persistent cmd window so it never flashes and closes
if "%~1"=="CHILD" goto :main
start "DOOM II Setup" cmd /k ""%~f0" CHILD"
exit /b

:main
title DOOM II - Setup and Launch
color 0C
cd /d "%~dp0"

echo.
echo ==========================================
echo   DOOM II: Hell on Earth - Browser Setup
echo ==========================================
echo.
echo Working directory: %CD%
echo.

:: Verify PowerShell
where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] powershell.exe not found.
    goto :fail
)
echo [OK] PowerShell found.

:: Check curl
where curl.exe >nul 2>&1
if errorlevel 1 (
    echo [WARN] curl.exe not on PATH - using PowerShell download fallback.
    set "USE_PS=1"
) else (
    echo [OK] curl found.
    set "USE_PS=0"
)

:: Create js-dos folder
if not exist "js-dos" mkdir "js-dos"
echo [OK] js-dos\ folder ready.
echo.

echo Downloading engine files (~5 MB). Please wait...
echo.

:: js-dos v7 engine files (confirmed URLs from js-dos.com official docs)
set "BASE=https://js-dos.com/v7/build/releases/latest/js-dos"
call :get "js-dos\js-dos.js"    "%BASE%/js-dos.js"
call :get "js-dos\js-dos.css"   "%BASE%/js-dos.css"
call :get "js-dos\wdosbox.js"   "%BASE%/wdosbox.js"
call :get "js-dos\wdosbox.wasm" "%BASE%/wdosbox.wasm"

:: fflate for in-browser ZIP manipulation
call :get "js-dos\fflate.min.js" "https://cdn.jsdelivr.net/npm/fflate@0.8.2/umd/index.js"

echo.
echo Downloading DOOM II base bundle (~3 MB).
echo This contains the DOS executable needed to run the game.
echo Your own DOOM2.WAD will be loaded on top of this.
echo.

:: doom2.jsdos = ZIP containing DOOM2.EXE + dosbox config (no copyrighted WAD data)
:: Hosted by dos.zone (the official js-dos community bundle repository)
call :get "js-dos\doom2.jsdos" "https://cdn.dos.zone/custom/dos/doom2.jsdos"

echo.
echo Verifying downloads...
echo.
set "ALLOK=1"
call :chk "js-dos\js-dos.js"
call :chk "js-dos\wdosbox.js"
call :chk "js-dos\wdosbox.wasm"
call :chk "js-dos\fflate.min.js"
call :chk "js-dos\doom2.jsdos"

if "!ALLOK!"=="0" (
    echo.
    echo [ERROR] One or more files failed. Check your internet and re-run.
    goto :fail
)

echo.
echo ==========================================
echo   Files OK. Starting server on port 8080
echo ==========================================
echo.
echo  ^> Browser will open automatically.
echo  ^> Drag DOOM2.WAD onto the page to play.
echo  ^> Close this window to stop the server.
echo.
timeout /t 3 /nobreak >nul

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"

echo.
echo Server has stopped.
goto :done

:fail
echo.
echo ------------------------------------------
echo  Setup did not complete. See errors above.
echo ------------------------------------------

:done
echo.
pause
endlocal
exit /b 0


:: =======================================================
:: :get  <dest>  <url>
:: Downloads only if file is missing or under 1 KB.
:: =======================================================
:get
set "_D=%~1"
set "_U=%~2"
set "_SKIP=0"

if exist "%_D%" (
    for %%F in ("%_D%") do if %%~zF GTR 1024 set "_SKIP=1"
)
if "!_SKIP!"=="1" (
    echo [SKIP]  %_D%
    goto :eof
)

echo [GET]   %_D%

if "%USE_PS%"=="0" (
    curl.exe -L --silent --show-error --ssl-no-revoke --output "%_D%" "%_U%"
    if not errorlevel 1 (
        echo [OK]    %_D%
        goto :eof
    )
    echo [WARN]  curl failed, trying PowerShell...
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }; try { Invoke-WebRequest -Uri '%_U%' -OutFile '%_D%' -UseBasicParsing } catch { Write-Host ('PS-FAIL: ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 (
    echo [FAIL]  %_D%
    set "ALLOK=0"
) else (
    echo [OK]    %_D%  (via PowerShell)
)
goto :eof


:: =======================================================
:: :chk  <file>
:: =======================================================
:chk
if not exist "%~1" (
    echo [MISSING]  %~1
    set "ALLOK=0"
    goto :eof
)
for %%F in ("%~1") do (
    if %%~zF LSS 1024 (
        echo [EMPTY]    %~1  -- download may have failed
        set "ALLOK=0"
    ) else (
        echo [OK]       %~1
    )
)
goto :eof
