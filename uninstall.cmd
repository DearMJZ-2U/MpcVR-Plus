@echo off
setlocal EnableExtensions
rem ============================================================
rem  MpcVR Plus - Uninstaller
rem
rem  RUN AS ADMINISTRATOR
rem  (right-click uninstall.cmd -> "Run as administrator")
rem
rem  Unregisters the renderer, restores the PotPlayer renderer choice
rem  that was in use before the install, and moves the install folder
rem  to the Recycle Bin (never a hard delete).
rem ============================================================
title MpcVR Plus - Uninstall

set "DST=%LOCALAPPDATA%\MpcVR-DLSS"

net session >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Administrator rights are required.
  echo         Right-click uninstall.cmd and choose "Run as administrator".
  echo.
  pause
  exit /b 1
)

call :check_player
if errorlevel 1 goto :player_running

rem ---- 1. put back the renderer PotPlayer used before the install ----
call :restore PotPlayerMini64
call :restore PotPlayerMini

rem ---- 2. unregister the filter ----
if exist "%DST%\MpcVideoRenderer64.ax" (
  echo Unregistering the renderer ...
  regsvr32 /s /u "%DST%\MpcVideoRenderer64.ax"
)

rem ---- 3. remove the install folder (Recycle Bin, not a hard delete) ----
if exist "%DST%" (
  echo Moving "%DST%" to the Recycle Bin ...
  powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('%DST%','OnlyErrorDialogs','SendToRecycleBin')" >nul 2>&1
)

echo.
if exist "%DST%" (
  echo [WARN] The folder could not be moved to the Recycle Bin and was left
  echo        in place:  %DST%
  echo        Delete it manually if you want.
) else (
  echo [OK] MpcVR Plus is uninstalled.
)
echo.
echo If PotPlayer still shows a black picture, open
echo   Options -^> Playback -^> Video renderer
echo and pick your previous renderer.
echo.
pause
exit /b 0

rem ---------------------------------------------------------------
rem  Restore VideoRen2 for one player from the recorded value.
rem ---------------------------------------------------------------
:restore
if not exist "%DST%\potplayer-%~1.backup" exit /b 0
set "V="
for /f "usebackq delims=" %%v in ("%DST%\potplayer-%~1.backup") do set "V=%%v"
if defined V (
  echo Restoring the previous renderer for %~1 ...
  reg add "HKCU\Software\DAUM\%~1\Settings" /v VideoRen2 /t REG_DWORD /d %V% /f >nul 2>&1
)
exit /b 0

rem ---------------------------------------------------------------
:check_player
rem findstr (System32) is used on purpose: a "find" on PATH can be shadowed by
rem a Unix find.exe (e.g. from Git), which would scan the whole disk instead.
for %%P in (PotPlayerMini64.exe PotPlayerMini.exe mpc-be64.exe mpc-hc64.exe) do (
  tasklist /fi "imagename eq %%P" /nh 2>nul | findstr /i /c:"%%P " >nul
  if not errorlevel 1 (
    echo   [running] %%P
    exit /b 1
  )
)
exit /b 0

:player_running
echo.
echo [ERROR] A video player is running.
echo         Close PotPlayer / MPC-BE / MPC-HC completely and run the
echo         uninstaller again.
echo.
pause
exit /b 1
