@echo off
set "partfile=%TEMP%\diskparttmp.txt"
echo select disk 0 >%partfile%
echo select partition 2 >>%partfile%
echo extend >>%partfile%
diskpart /s %partfile%
del /q /f C:\Windows\System32\Sysprep\unattend.xml
del /q /f C:\Windows\Panther\unattend.xml
