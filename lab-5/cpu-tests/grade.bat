@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PYTHON_EXE="

for %%P in (
    "C:\Xilinx\2025.2.1\tps\win64\python-3.13.0\python.exe"
    "C:\Users\29931\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
) do (
    if not defined PYTHON_EXE if exist %%~P set "PYTHON_EXE=%%~P"
)

if not defined PYTHON_EXE (
    for /f "delims=" %%P in ('where py 2^>nul') do (
        if not defined PYTHON_EXE set "PYTHON_EXE=%%P"
    )
)

if not defined PYTHON_EXE (
    for /f "delims=" %%P in ('where python 2^>nul') do (
        if not defined PYTHON_EXE set "PYTHON_EXE=%%P"
    )
)

if not defined PYTHON_EXE (
    echo [ERROR] Cannot find Python. Install Python or run grade_cpu_tests.py with a full python.exe path.
    exit /b 1
)

"%PYTHON_EXE%" -c "import sys" >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Found Python candidate but it cannot run: %PYTHON_EXE%
    echo Install Python, or edit grade.bat to point to a valid python.exe.
    exit /b 1
)

"%PYTHON_EXE%" "%SCRIPT_DIR%grade_cpu_tests.py" %*
exit /b %ERRORLEVEL%
