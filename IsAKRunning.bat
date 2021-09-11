@echo off

REM This is meant to be run from a Kitchen screen. If placed in the same directory as FixAK.bat on the File Server, FixAK will deploy the script to the KPS automatically. 
REM The function of this script is to check if Aloha Kitchen is running, if it is, the script restarts AK. If AK is not running, it just starts AK on the device you run it from. 

Set LOGFILE=C:\Scripts\IsAKrunninglog.txt
forfiles /M %LOGFILE% /C "cmd /c if @fsize GEQ 20000 del /F %LOGFILE%"

TITLE IsAKRunning.bat
tasklist /nh /fi "imagename eq AlohaKitchen.exe" | find /i "AlohaKitchen.exe" >nul && (
Taskkill /IM AlohaKitchen.exe /f
taskkill /IM AlhAdm.exe /f
taskkill /IM cmd.exe /fi "windowtitle ne Administrator:  IsAKRunning*" /f
start C:\BootDrv\AlohaKitchen\StartAk.Bat param1
echo Aloha Kitchen was running, Killed it and restarted AK >> %LOGFILE%
exit
) || (
TITLE IsAKRunning.bat
taskkill /IM AlohaKitchen.exe /f
Taskkill /IM AlhAdm.exe /f
taskkill /IM cmd.exe /fi "windowtitle ne Administrator:  IsAKRunning*" /f
C:\BootDrv\AlohaKitchen\StartAk.Bat param1
echo Aloha Kitchen was not running, started it >> %LOGFILE%
exit
)
exit
