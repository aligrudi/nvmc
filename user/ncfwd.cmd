@echo off

rem Default values
set "host=hpc.nit.ac.ir"
set "prot=vnc"
set "user="
set "vm="
set "addr="
set "port=5909"

rem Change to script directory
cd /d "%~dp0"

echo NVMC Client Connection
echo.

rem Read variables
set /p host="Server (%host%): "
set /p prot="Protocol (vnc, rdp, or ssh; default=%prot%): "
set /p user="User name (%user%): "
set /p vm="VM name (%vm%): "
set /p addr="VM IP address (%addr%): "
set /p port="Local port (%port%): "

rem SSH options
if "%prot%" equ "vnc" set "opts=-L %port%:/home/%user%/%vm%.vnc %user%@%host% ncuser vncs %vm%"
if "%prot%" equ "rdp" set "opts=-N -L %port%:%addr%:3389 %user%@%host%"
if "%prot%" equ "ssh" set "opts=-N -L %port%:%addr%:22 %user%@%host%"

echo Using OpenSSH to forward connections...
ssh %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win64\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win32\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "C:\Program Files\OpenSSH\ssh" %opts%
if "%ERRORLEVEL%" neq "0" echo OpenSSH failed!
echo /p ln="Press return to exit..."
