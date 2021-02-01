@echo off

rem Default values
set "host=hpc.nit.ac.ir"
set "user="
set "vm="
set "addr="
set "port=5907"
set "rdpport=5908"
set "sshport=5909"

rem Change to script directory
cd /d "%~dp0"

rem Load saved input variables
set "conf=nitcnf.cmd"
if exist %conf% call %conf%

echo NVMC Client Connection
echo.

rem Read input variables
set /p host="Server address (%host%): "
set /p user="User name (%user%): "
set /p vm="VM name (%vm%): "
set /p addr="VM IP address (%addr%): "
set /p port="Local VNC port (%port%): "
set /p rdpport="Local RDP port (%rdpport%): "
set /p sshport="Local SSH port (%sshport%): "
echo.

rem Save input variables
echo set "host=%host%" >%conf%
echo set "user=%user%" >>%conf%
echo set "vm=%vm%" >>%conf%
echo set "addr=%addr%" >>%conf%
echo set "port=%port%" >>%conf%
echo set "rdpport=%rdpport%" >>%conf%
echo set "sshport=%sshport%" >>%conf%

rem SSH options
if "%port%" neq "0" set "vncopts=-L %port%:/home/%user%/%vm%.vnc"
if "%rdpport%" neq "0" set "rdpopts=-L %rdpport%:%addr%:3389"
if "%sshport%" neq "0" set "sshopts=-L %sshport%:%addr%:22"
set "opts=%vncopts% %rdpopts% %sshopts% %user%@%host% ncuser vncs %vm%"

echo Using OpenSSH to forward connections...
echo.
ssh %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win64\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "OpenSSH-Win32\ssh" %opts%
if "%ERRORLEVEL%" neq "0" "C:\Program Files\OpenSSH\ssh" %opts%
if "%ERRORLEVEL%" neq "0" echo OpenSSH failed!
echo /p ln="Press return to exit..."
