@echo off
setlocal

cd /d "%~dp0"

set "OSS_CAD_ROOT=D:\oss-cad-suite\oss-cad-suite"
if exist "%OSS_CAD_ROOT%\bin\iverilog.exe" (
    set "PATH=%OSS_CAD_ROOT%\bin;%OSS_CAD_ROOT%\lib;%PATH%"
)

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=sim"

if /I "%ACTION%"=="sim" goto sim
if /I "%ACTION%"=="build" goto build
if /I "%ACTION%"=="run" goto run
if /I "%ACTION%"=="clean" goto clean
if /I "%ACTION%"=="vivado" goto vivado

echo [ERROR] Unknown action: %ACTION%
echo Usage: build.bat [sim^|build^|run^|clean^|vivado]
exit /b 1

:sim
call "%~f0" build
if errorlevel 1 exit /b 1
call "%~f0" run
exit /b %ERRORLEVEL%

:build
where iverilog >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot find iverilog.
    exit /b 1
)
iverilog -I src -s tb_board_number_demo -o board_number_demo_tb.out ^
    src\hex_to_7seg.v ^
    src\scan_7seg.v ^
    src\board_number_demo.v ^
    sim\tb_board_number_demo.v
exit /b %ERRORLEVEL%

:run
where vvp >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot find vvp.
    exit /b 1
)
vvp board_number_demo_tb.out
exit /b %ERRORLEVEL%

:vivado
where vivado >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot find vivado. Run this target on a machine with Vivado installed.
    exit /b 1
)
vivado -mode batch -source scripts\create_vivado_project.tcl
exit /b %ERRORLEVEL%

:clean
if exist board_number_demo_tb.out del /f /q board_number_demo_tb.out
if exist *.vcd del /f /q *.vcd
if exist *.log del /f /q *.log
echo [OK] Clean finished.
exit /b 0
