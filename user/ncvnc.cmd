echo off

rem Default values
set "vm="
set "port=5909"
set "user="

rem Read variables
set /p vm="VM name (%vm%): "
set /p port="VNC local port (%port%): "
set /p user="User name (%user%): "

rem Change to script directory
cd /d "%~dp0"

rem SSH options
set "opts=-L %port%:/home/%user%/%vm%.vnc %user%@hpc.nit.ac.ir ncuser vncs %vm%"

echo Using OpenSSH to forward VNC connections...
ssh %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win64\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win32\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "C:\Program Files\OpenSSH\ssh" %opts%
if "%ERRORLEVEL%" neq "0" echo OpenSSH failed!
echo /p ln="Press return to exit..."
