echo off
set /p vm="VM name: "

set /p port="VNC local port (default: 5909): "
if "%port%" equ "" set port="5909"

set /p user="User name: "

echo Using OpenSSH to forward VNC connections...
ssh -L %port%:/home/%user%/%vm%.vnc %user%@hpc.nit.ac.ir ncuser vncs %vm%

if "%ERRORLEVEL%" neq "0" (
	"C:\Program Files\OpenSSH\ssh" -L %port%:/home/%user%/%vm%.vnc %user%@hpc.nit.ac.ir ncuser vncs %vm%
)
if "%ERRORLEVEL%" neq "0" (
	"C:\Program Files\OpenSSH-Win64\ssh" -L %port%:/home/%user%/%vm%.vnc %user%@hpc.nit.ac.ir ncuser vncs %vm%
)
if "%ERRORLEVEL%" neq "0" echo OpenSSH failed!
echo /p ln="Press return to exit..."
