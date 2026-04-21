@echo off
setlocal

rem Lab-2 CPU simulation script for Windows.
rem source is the run directory. Run this script in plcpu_sim\source.
rem Usage:
rem   build.bat        Build and run simulation
rem   build.bat build  Build only
rem   build.bat run    Build and run simulation
rem   build.bat wave   Build, run, and open GTKWave
rem   build.bat clean  Remove generated simulation files

cd /d "%~dp0"

set "TOP=plcomp_tb"
set "OUT=plcpu_sim.out"
set "VCD=plcpu_sim.vcd"
set "ACTION=%~1"

if "%ACTION%"=="" set "ACTION=run"

if /I "%ACTION%"=="clean" goto clean
if /I "%ACTION%"=="build" goto check_tools
if /I "%ACTION%"=="run" goto check_tools
if /I "%ACTION%"=="wave" goto check_tools

echo [ERROR] Unknown action: %ACTION%
echo Usage: build.bat [build^|run^|wave^|clean]
exit /b 1

:check_tools
where iverilog >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot find iverilog. Please install OSS CAD Suite or add Icarus Verilog to PATH.
    exit /b 1
)

where vvp >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot find vvp. Please install OSS CAD Suite or add Icarus Verilog to PATH.
    exit /b 1
)

where gtkwave >nul 2>nul
if errorlevel 1 (
    echo [WARN] Cannot find gtkwave. Simulation can still run, but waveform opening is unavailable.
    set "HAS_GTKWAVE=0"
) else (
    set "HAS_GTKWAVE=1"
)

goto build

:build
echo [INFO] Building %OUT% ...
iverilog -I . -s %TOP% -o %OUT% ^
    alu.v ^
    ctrl.v ^
    dm.v ^
    EXT.v ^
    im.v ^
    NPC.v ^
    PC.v ^
    plcomp.v ^
    plcomp_tb.v ^
    PLCPU.v ^
    pl_reg.v ^
    RF.v

if errorlevel 1 (
    echo [ERROR] Build failed.
    exit /b 1
)

if /I "%ACTION%"=="build" (
    echo [OK] Build finished: %OUT%
    exit /b 0
)

goto run

:run
echo [INFO] Running simulation ...
vvp %OUT%
if errorlevel 1 (
    echo [ERROR] Simulation failed.
    exit /b 1
)

if exist "%VCD%" (
    echo [OK] Waveform generated: %VCD%
) else (
    echo [WARN] Simulation finished, but %VCD% was not found.
)

if /I "%ACTION%"=="wave" goto wave

echo [OK] Done.
exit /b 0

:wave
if not exist "%VCD%" (
    echo [ERROR] Cannot find %VCD%. Please run build.bat run first.
    exit /b 1
)

if "%HAS_GTKWAVE%"=="1" (
    echo [INFO] Opening GTKWave ...
    start "" gtkwave "%VCD%"
    echo [OK] Done.
    exit /b 0
)

echo [ERROR] Cannot open GTKWave because gtkwave was not found in PATH.
exit /b 1

:clean
if exist "%OUT%" del /f /q "%OUT%"
if exist "%VCD%" del /f /q "%VCD%"
if exist "*.log" del /f /q "*.log"
echo [OK] Clean finished.
exit /b 0
