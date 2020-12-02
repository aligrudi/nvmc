echo off

set /p user="User name: "
set /p addr="VM IP address: "
set /p lport="Local port (default: 2000): "
if "%lport%" equ "" set lport="2000"
set /p rport="VM port (default: 22): "
if "%rport%" equ "" set rport="22"

echo Using OpenSSH to forward connections...
ssh -N -L %lport%:%addr%:%rport% %user%@hpc.nit.ac.ir

if "%ERRORLEVEL%" neq "0" (
	"C:\Program Files\OpenSSH\ssh" -N -L %lport%:%addr%:%rport% %user%@hpc.nit.ac.ir
)
if "%ERRORLEVEL%" neq "0" (
	"C:\Program Files\OpenSSH-Win64\ssh" -N -L %lport%:%addr%:%rport% %user%@hpc.nit.ac.ir
)
if "%ERRORLEVEL%" neq "0" echo OpenSSH failed!
echo /p ln="Press return to exit..."
