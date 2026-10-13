@echo off
setlocal EnableExtensions
rem ============================================================
rem  MpcVR Plus - Installer
rem  MPC Video Renderer with frame generation and super resolution
rem
rem  RUN AS ADMINISTRATOR
rem  (right-click install.cmd -> "Run as administrator")
rem ============================================================
title MpcVR Plus - Install

set "SRC=%~dp0"
set "DST=%LOCALAPPDATA%\MpcVR-DLSS"

rem ---- 0. elevation ------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Administrator rights are required.
  echo         Right-click install.cmd and choose "Run as administrator".
  echo.
  pause
  exit /b 1
)

rem ---- 1. the player must be closed (it locks the renderer file)
call :check_player
if errorlevel 1 goto :player_running

rem ---- 2. the package must be complete ------------------------
echo Checking the package ...
call :preflight
if errorlevel 1 (
  echo.
  echo [ERROR] The package is incomplete - see the missing files listed above.
  echo         Re-extract the whole archive and run install.cmd again.
  echo.
  pause
  exit /b 1
)

echo.
echo Source : %SRC%
echo Target : %DST%
echo.

if not exist "%DST%" mkdir "%DST%"

echo [1/5] Copying the renderer ...
copy /y "%SRC%MpcVideoRenderer64.ax"          "%DST%\" >nul || goto :copy_failed
copy /y "%SRC%MpcVideoRenderer64.ax.manifest" "%DST%\" >nul || goto :copy_failed

echo [2/5] Copying shaders ...
xcopy /y /e /i /q "%SRC%shaders" "%DST%\shaders" >nul || goto :copy_failed

echo [3/5] Copying feature runtimes ...
set "COPYERR=0"
for %%D in (ngx amd intel nvidia-vfg) do (
  if exist "%SRC%%%D\" (
    xcopy /y /e /i /q "%SRC%%%D" "%DST%\%%D" >nul
    if errorlevel 1 set "COPYERR=1"
  )
)
if "%COPYERR%"=="1" goto :copy_failed

echo [4/5] Registering the renderer ...
regsvr32 /s "%DST%\MpcVideoRenderer64.ax"
if errorlevel 1 (
  echo.
  echo [ERROR] regsvr32 failed - the renderer could not be registered.
  echo.
  pause
  exit /b 1
)

rem A per-user CLSID key shadows the machine-wide registration, so drop any
rem stale one left behind by an earlier dev/user-level install.
for %%G in ("{71F080AA-8661-4093-B15E-4F6903E77D0A}" "{DA46D181-07D6-441D-B314-019AEB10148A}" "{D697132B-FCA4-4401-8869-D3B39D0750DB}") do reg delete "HKCU\Software\Classes\CLSID\%%~G" /f >nul 2>&1

rem Default renderer settings are applied on a FIRST install only, so that a
rem reinstall never overwrites settings you have already tuned yourself.
reg query "HKCU\Software\MPC-BE Filters\MPC Video Renderer" >nul 2>&1
if errorlevel 1 if exist "%SRC%settings.reg" (
  echo       applying default renderer settings ...
  reg import "%SRC%settings.reg" >nul 2>&1
)

echo [5/5] Pointing PotPlayer at MpcVR Plus ...
call :setpot PotPlayerMini64
call :setpot PotPlayerMini

echo.
echo [OK] MpcVR Plus is installed.
echo      Renderer : %DST%\MpcVideoRenderer64.ax
echo      Log file : %DST%\logs\fg.log
echo.
echo Next steps:
echo   1) Start PotPlayer and play a video.
echo   2) Open the settings: right-click on the picture -^> Filter -^>
echo      MPC Video Renderer  (the page is in Chinese).
echo   3) See the three .txt files in this folder for the full guide:
echo      README / install guide / usage guide.
echo.
pause
exit /b 0

rem ---------------------------------------------------------------
rem  Configure one player (only if that player is actually present).
rem  The previous renderer choice is remembered for uninstall.cmd.
rem ---------------------------------------------------------------
:setpot
reg query "HKCU\Software\DAUM\%~1\Settings" >nul 2>&1
if errorlevel 1 exit /b 0
set "PREV="
for /f "tokens=2,3" %%a in ('reg query "HKCU\Software\DAUM\%~1\Settings" /v VideoRen2 2^>nul') do if /i "%%a"=="REG_DWORD" set "PREV=%%b"
rem record the pre-install value once, so uninstall.cmd can put it back
if defined PREV if not exist "%DST%\potplayer-%~1.backup" >"%DST%\potplayer-%~1.backup" echo %PREV%
reg add "HKCU\Software\DAUM\%~1\Settings" /v VideoRen2  /t REG_DWORD /d 16 /f >nul 2>&1
reg add "HKCU\Software\DAUM\%~1\Settings" /v SkinUseOsc /t REG_DWORD /d 0  /f >nul 2>&1
exit /b 0

rem ---------------------------------------------------------------
rem  Preflight: every file a feature needs must be in the package.
rem ---------------------------------------------------------------
:preflight
set "MISS=0"
for %%F in (
  "MpcVideoRenderer64.ax"
  "MpcVideoRenderer64.ax.manifest"
  "shaders\FgNvofEncode.dxil"
  "shaders\NvofDensify.dxil"
  "shaders\GpuDisLuma.dxil"
  "shaders\GpuDisValidate.dxil"
  "shaders\SrToLinear.dxil"
  "shaders\SrToSrgb.dxil"
  "shaders\dis\dis_perfect_final.dxil"
  "ngx\nvngx_dlssg.dll"
  "ngx\nvngx_dlss.dll"
  "amd\fidelityfx\amd_fidelityfx_framegeneration_dx12.dll"
  "amd\fidelityfx\amd_fidelityfx_upscaler_dx12.dll"
  "intel\experimental\libxess_fg.dll"
  "nvidia-vfg\nvVFXVideoFrameGeneration.dll"
) do (
  if not exist "%SRC%%%~F" (
    echo   [missing] %%~F
    set "MISS=1"
  )
)
if "%MISS%"=="1" exit /b 1
echo   all required files are present.
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

rem ---------------------------------------------------------------
:player_running
echo.
echo [ERROR] A video player is running.
echo         Close PotPlayer / MPC-BE / MPC-HC completely and run the
echo         installer again.
echo.
pause
exit /b 1

:copy_failed
echo.
echo [ERROR] Copying files to "%DST%" failed.
echo         Close any running player and try again.
echo.
pause
exit /b 1
