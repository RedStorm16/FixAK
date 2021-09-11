@echo off

REM This script must be run as a user that has read access to the BootDrv of the KPS. 

:Set_Var
cd /D "%~dp0"
if not exist "D:\Staging" mkdir D:\Staging
Set IPList=D:\Staging\IPList.txt
Set AKList=D:\Staging\AKList.txt
goto Check_Connect

:Check_Connect
del /f %IPList%
@For /F Tokens^=2* %%G In ('^""%SystemRoot%\System32\reg.exe" Query ^
 "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /S ^
 /F IPAddress /C /E /V 2^> NUL ^| "%SystemRoot%\System32\find.exe" ^
 "IPAddress "^"') Do @For /L %%I In (1 1 255) Do @ping -n 1 %%~nH.%%I | find /i "TTL" ^
 & If not errorlevel 1 echo %%~nH.%%I>>%IPList%
REM goto GetAKList

:GETAKList
del /f %AKList%
for /f %%K in (%IPList%) do @Echo Checking %%K & If Exist "\\%%K\C$\BootDrv\AlohaKitchen\*.*" (
echo %%K>> %AKList%
) Else (
Echo File does not exist on %%K
)
del /f %IPList%
exit
