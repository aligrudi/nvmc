echo off

rem Default values
set "host=hpc.nit.ac.ir"
set "user="
set "addr="
set "lport=2000"
set "rport=3389"

rem Read variables
set /p user="User name (%user%): "
set /p addr="VM IP address (%addr%): "
set /p lport="Local port (%lport%): "
set /p rport="VM port (%rport%): "

rem Change to script directory
cd /d "%~dp0"

rem SSH options
set "opts=-N -L %lport%:%addr%:%rport% %user%@%host%"

echo Using OpenSSH to forward connections...
ssh %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win64\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win32\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "C:\Program Files\OpenSSH\ssh" %opts%
if "%ERRORLEVEL%" neq "0" echo OpenSSH failed!
echo /p ln="Press return to exit..."
