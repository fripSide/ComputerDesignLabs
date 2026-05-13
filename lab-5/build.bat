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
if /I "%ACTION%"=="synth" goto synth
if /I "%ACTION%"=="bitstream" goto bitstream

echo [ERROR] Unknown action: %ACTION%
echo Usage: build.bat [sim^|build^|run^|clean^|vivado^|synth^|bitstream]
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
if not errorlevel 1 (
    vivado -mode batch -source scripts\create_vivado_project.tcl
    if exist vivado\number_demo\number_demo.xpr exit /b 0
    exit /b %ERRORLEVEL%
)

set "VIVADO_BAT="
for %%V in (
    "C:\Xilinx\2025.2.1\Vivado\bin\vivado.bat"
    "C:\Xilinx\2025.2\Vivado\bin\vivado.bat"
    "C:\Xilinx\Vivado\2024.2\bin\vivado.bat"
    "C:\Xilinx\Vivado\2024.1\bin\vivado.bat"
    "C:\Xilinx\Vivado\2023.2\bin\vivado.bat"
    "C:\Xilinx\Vivado\2023.1\bin\vivado.bat"
    "D:\Xilinx\2025.2.1\Vivado\bin\vivado.bat"
    "D:\Xilinx\2025.2\Vivado\bin\vivado.bat"
    "D:\Xilinx\Vivado\2024.2\bin\vivado.bat"
    "D:\Xilinx\Vivado\2024.1\bin\vivado.bat"
    "D:\Xilinx\Vivado\2023.2\bin\vivado.bat"
    "D:\Xilinx\Vivado\2023.1\bin\vivado.bat"
) do (
    if exist %%~V set "VIVADO_BAT=%%~V"
)

if defined VIVADO_BAT (
    call "%VIVADO_BAT%" -mode batch -source scripts\create_vivado_project.tcl
    if exist vivado\number_demo\number_demo.xpr exit /b 0
    exit /b %ERRORLEVEL%
)

echo [ERROR] Cannot find Vivado.
echo Install Vivado, or run this command from "Vivado Tcl Shell".
echo If Vivado is installed in another path, add its bin directory to PATH first.
exit /b %ERRORLEVEL%

:synth
where vivado >nul 2>nul
if not errorlevel 1 (
    vivado -mode batch -source scripts\run_synthesis_check.tcl
    if exist vivado\number_demo\number_demo.runs\synth_1\board_number_demo.dcp exit /b 0
    exit /b %ERRORLEVEL%
)

set "VIVADO_BAT="
for %%V in (
    "C:\Xilinx\2025.2.1\Vivado\bin\vivado.bat"
    "C:\Xilinx\2025.2\Vivado\bin\vivado.bat"
    "C:\Xilinx\Vivado\2024.2\bin\vivado.bat"
    "C:\Xilinx\Vivado\2024.1\bin\vivado.bat"
    "C:\Xilinx\Vivado\2023.2\bin\vivado.bat"
    "C:\Xilinx\Vivado\2023.1\bin\vivado.bat"
    "D:\Xilinx\2025.2.1\Vivado\bin\vivado.bat"
    "D:\Xilinx\2025.2\Vivado\bin\vivado.bat"
    "D:\Xilinx\Vivado\2024.2\bin\vivado.bat"
    "D:\Xilinx\Vivado\2024.1\bin\vivado.bat"
    "D:\Xilinx\Vivado\2023.2\bin\vivado.bat"
    "D:\Xilinx\Vivado\2023.1\bin\vivado.bat"
) do (
    if exist %%~V set "VIVADO_BAT=%%~V"
)

if defined VIVADO_BAT (
    call "%VIVADO_BAT%" -mode batch -source scripts\run_synthesis_check.tcl
    if exist vivado\number_demo\number_demo.runs\synth_1\board_number_demo.dcp exit /b 0
    exit /b %ERRORLEVEL%
)

echo [ERROR] Cannot find Vivado.
exit /b 1

:bitstream
where vivado >nul 2>nul
if not errorlevel 1 (
    vivado -mode batch -source scripts\run_bitstream_check.tcl
    if exist vivado\bitstream_check\board_number_demo.bit exit /b 0
    exit /b %ERRORLEVEL%
)

set "VIVADO_BAT="
for %%V in (
    "C:\Xilinx\2025.2.1\Vivado\bin\vivado.bat"
    "C:\Xilinx\2025.2\Vivado\bin\vivado.bat"
    "C:\Xilinx\Vivado\2024.2\bin\vivado.bat"
    "C:\Xilinx\Vivado\2024.1\bin\vivado.bat"
    "C:\Xilinx\Vivado\2023.2\bin\vivado.bat"
    "C:\Xilinx\Vivado\2023.1\bin\vivado.bat"
    "D:\Xilinx\2025.2.1\Vivado\bin\vivado.bat"
    "D:\Xilinx\2025.2\Vivado\bin\vivado.bat"
    "D:\Xilinx\Vivado\2024.2\bin\vivado.bat"
    "D:\Xilinx\Vivado\2024.1\bin\vivado.bat"
    "D:\Xilinx\Vivado\2023.2\bin\vivado.bat"
    "D:\Xilinx\Vivado\2023.1\bin\vivado.bat"
) do (
    if exist %%~V set "VIVADO_BAT=%%~V"
)

if defined VIVADO_BAT (
    call "%VIVADO_BAT%" -mode batch -source scripts\run_bitstream_check.tcl
    if exist vivado\bitstream_check\board_number_demo.bit exit /b 0
    exit /b %ERRORLEVEL%
)

echo [ERROR] Cannot find Vivado.
exit /b 1

:clean
if exist board_number_demo_tb.out del /f /q board_number_demo_tb.out
if exist *.vcd del /f /q *.vcd
if exist *.log del /f /q *.log
if exist *.jou del /f /q *.jou
if exist dfx_runtime.txt del /f /q dfx_runtime.txt
echo [OK] Clean finished.
exit /b 0
