@echo off
SetLocal EnableDelayedExpansion

REM Psexec.exe, FixAK.bat and IsAKRunning.bat all need to be in the same folder on the file server. This script will take care of the rest :)
echo ===============
echo Thank you for running FixAK.bat.
echo ===============
echo Make sure to read the ReadMe before running this script!
echo If the script fails, make sure to read the logfile (FixAK_log.log)
timeout /t 10


REM Defining needed variables
:DEFINITIONS
if not exist "D:\Staging\AKLog_Backup" mkdir D:\Staging\AKLog_Backup
cd /D "%~dp0"
set date=%date /t%
set time=%time /t%
set LOGFILE=FixAK_LOG.log
If Exist %LOGFILE% (
forfiles /M %LOGFILE% /C "cmd /c if @fsize GEQ 50000 del /F %LOGFILE%"
Echo %date% %time% - Logfile exists, appending log... >> %LOGFILE%
goto FIX_LIST
) Else (
Echo No Current LOGFILE, will create a new one. 
Echo %date% %time% - Starting log... >> %LOGFILE%
goto FIX_LIST
)

REM Reordering AKList to confirm the controllers are fixed in the correct order.
:FIX_LIST
set AKList=D:\Staging\AKList.txt
powershell -Command "& {gc %AKList% | sort -Unique > AKList2.txt;}" >> %LOGFILE%
iconv\iconv -f UTF-16LE -t UTF-8 AKList2.txt > AKList3.txt" 
move /y AKList3.txt %AKList% >> %LOGFILE%
del /f /q AKList2.txt
echo %date% %time% - Script Started >> %LOGFILE%
echo %date% %time% - The current user is %username% >> %LOGFILE%
set "cmd=findstr /R /N "^^" %AKLIST% | find /C ":""
for /f %%g in ('!cmd!') do set AKamt=%%g
goto SetAK81

REM The following FOR Loops grab IPs from AKList and assign them to variables. 
:SetAK81
set count=2
for /f "tokens=*" %%a in (%AKList%) do (
if !count! equ 2 (set AK81_IP=%%a)
set /a count+=1
if "!count!" equ "3" goto SetAK82
)

:SetAK82
if %AKamt% LEQ 1 set AK82_IP=0 & goto SetAK83
set count=3
for /f "skip=1 tokens=*" %%b in (%AKList%) do (
if !count! equ 3 (set AK82_IP=%%b)
set /a count+=1
if !count! equ 4 goto SetAK83
)

:SetAK83
if %AKamt% LEQ 2 set AK83_IP=0 & goto SetAK84
set count=4
for /f "skip=2 tokens=*" %%c in (%AKList%) do (
if !count! equ 4 (set AK83_IP=%%c)
set /a count+=1
if !count! equ 5 goto SetAK84
)

:SetAK84
if %AKamt% LEQ 3 set AK84_IP=0 & goto SetAK85
set count=5
for /f "skip=3 tokens=*" %%d in (%AKList%) do (
if !count! equ 5 (set AK84_IP=%%d)
set /a count+=1
if !count! equ 6 goto SetAK85
)

:SetAK85
if %AKamt% LEQ 4 set AK85_IP=0 & goto Check81
set count=6
for /f "skip=4 tokens=*" %%e in (%AKList%) do (
if !count! equ 6 (set AK85_IP=%%e)
set /a count+=1
if !count! equ 7 goto SetAK86
)

:SetAK86
if %AKamt% LEQ 5 set AK86_IP=0 & goto Check81
set count=7
for /f "skip=5 tokens=*" %%e in (%AKList%) do (
if !count! equ 7 (set AK86_IP=%%e)
set /a count+=1
if !count! equ 8 goto Check81
)

:Check81
ping -n 1 %AK81_IP% | find /i "TTL"
if not errorlevel 1 goto DEL_LOGS
if errorlevel 1 (
echo Checking AK IPs...
echo %date% %time% - Had to correct AK81's IP, was blank or not correct in AKList >> %LOGFILE%
set AK81_IP=%AK82_IP%
set AK82_IP=%AK83_IP%
set AK83_IP=%AK84_IP%
set AK84_IP=%AK85_IP%
set AK85_IP=%AK86_IP%
set AK86_IP=0
)
goto DEL_LOGS


REM Deleting Aloha Kitchen logs from the KPS controllers and server. This step requires the user be logged in as an Aloha Admin. 
:DEL_LOGS
echo AK81 is: %AK81_IP% >> %LOGFILE%
echo AK82 is: %AK82_IP% >> %LOGFILE%
echo AK83 is: %AK83_IP% >> %LOGFILE%
echo AK84 is: %AK84_IP% >> %LOGFILE%
echo AK85 is: %AK85_IP% >> %LOGFILE%
cls
net STOP AlohaKitchenService >> %LOGFILE%
echo Deleting logs, please wait...
echo %date% %time% - Deleting logs... >> %LOGFILE%
echo %date% %time% - Deleting log on server
goto DEL_SVR_LOG
:DEL_SVR_LOG
If exist "D:\POS\AlohaKitchen\Data\*.log" (
xcopy /c /q /y D:\POS\AlohaKitchen\Data\*.log D:\Staging\AKLog_Backup\AK_Svr.log >> %LOGFILE%
del /q D:\POS\AlohaKitchen\Data\*.log & echo Detected abnormal pathing for IBERDIR, used D:\POS >> %LOGFILE% 
) Else (
xcopy /c /q /y D:\bootdrv\AlohaKitchen\Data\*.log D:\Staging\AKLog_Backup >> %LOGFILE%
del /q D:\bootdrv\AlohaKitchen\Data\*.log & echo Using normal pathing for IBERDIR - D:\Bootdrv >> %LOGFILE%
)
cls
goto DEL_KPS_LOGS

:DEL_KPS_LOGS
echo %date% %time% - Deleting log on AK81
echo %date% %time% - Deleting log on AK81 >> %LOGFILE%
xcopy /c /q /y \\%AK81_IP%\c$\bootdrv\AlohaKitchen\Data\*.log D:\Staging\AKLog_Backup >> %LOGFILE%
del /q \\%AK81_IP%\c$\bootdrv\AlohaKitchen\Data\*.log >> %LOGFILE% 2>&1
cls
echo %date% %time% - Deleting log on AK82
echo %date% %time% - Deleting log on AK82 >> %LOGFILE%
xcopy /c /q /y \\%AK82_IP%\c$\bootdrv\AlohaKitchen\Data\*.log D:\Staging\AKLog_Backup >> %LOGFILE%
del /q \\%AK82_IP%\c$\bootdrv\AlohaKitchen\Data\*.log >> %LOGFILE% 2>&1
cls
echo %date% %time% - Deleting log on AK83
echo %date% %time% - Deleting log on AK83 >> %LOGFILE%
xcopy /c /q /y \\%AK83_IP%\c$\bootdrv\AlohaKitchen\Data\*.log D:\Staging\AKLog_Backup %LOGFILE%
del /q \\%AK83_IP%\c$\bootdrv\AlohaKitchen\Data\*.log >> %LOGFILE% 2>&1
cls
goto Check84

:Check84
ping -n 1 %AK84_IP% | find /i "TTL"
if not errorlevel 1 goto Continue
if errorlevel 1 (
set AK84_IP=0
goto Fin85
)

:Continue
echo %date% %time% - Deleting log on AK84
echo %date% %time% - Deleting log on AK84 >> %LOGFILE%
xcopy /c /q /y \\%AK84_IP%\c$\bootdrv\AlohaKitchen\Data\*.log D:\Staging\AKLog_Backup >> %LOGFILE%
del /q \\%AK84_IP%\c$\bootdrv\AlohaKitchen\Data\*.log >> %LOGFILE% 2>&1
cls
goto Fin85

:Fin85
ping -n 1 %AK85_IP% | find /i "TTL"
if not errorlevel 1 goto Del_85
if errorlevel 1 goto StartSvc

:Del_85
If %AK85_IP%==0 (
echo There is no AK85 at this location, skipping AK85
echo %date% %time% - There is no AK85 at this location, skipping AK85 >> %LOGFILE%
goto StartSvc
) Else (
echo %date% %time% - Deleting log on AK85
echo %date% %time% - Deleting log on AK85 >> %LOGFILE%
xcopy /c /q /y \\%AK85_IP%\c$\bootdrv\AlohaKitchen\Data\*.log D:\Staging\AKLog_Backup >> %LOGFILE%
del /q \\%AK85_IP%\c$\bootdrv\AlohaKitchen\Data\*.log >> %LOGFILE% 2>&1
goto StartSvc
)

:StartSvc
cls
echo Logs have been deleted. Moving to copying IsAKRunning to each screen. 
echo %date% %time% - Logs have been deleted. Moving to copying IsAKRunning to each screen. >> %LOGFILE%
echo %date% %time% - If errors are present above, be sure to verify you can path to the controllers from the Server>> %LOGFILE%
Timeout /t 10
net START AlohaKitchenService >> %LOGFILE%
cls
goto AK81

REM Copying IsAKRunning to each KPS controller. 
:AK81
echo %date% %time% - AK81 is %AK81_IP%
If Exist "\\%AK81_IP%\c$\Scripts\IsAkRunning.bat" (
Echo %date% %time% - IsAkRunning exists on AK81 >> %LOGFILE%
) Else (
xcopy /c /q /y IsAkRunning.bat \\%AK81_IP%\c$\Scripts\
Echo %date% %time% - IsAkRunning was not on AK81, copied. >> %LOGFILE%
)
goto AK82

:AK82
echo %date% %time% - AK82 is %AK82_IP%
If Exist "\\%AK82_IP%\c$\Scripts\IsAkRunning.bat" (
Echo %date% %time% - IsAkRunning exists on AK82 >> %LOGFILE%
) Else (
xcopy /c /q /y IsAkRunning.bat \\%AK82_IP%\c$\Scripts\
Echo %date% %time% - IsAkRunning was not on AK82, copied. >> %LOGFILE%
)
goto AK83

:AK83
echo %date% %time% - AK83 is %AK83_IP%
If Exist "\\%AK83_IP%\c$\Scripts\IsAkRunning.bat" (
Echo %date% %time% - IsAkRunning exists on AK83 >> %LOGFILE%
) Else (
xcopy /c /q /y IsAkRunning.bat \\%AK83_IP%\c$\Scripts\
Echo %date% %time% - IsAkRunning was not on AK83, copied. >> %LOGFILE%
)
goto AK84

:AK84
echo %date% %time% - AK84 is %AK84_IP%
If Exist "\\%AK84_IP%\c$\Scripts\IsAkRunning.bat" (
Echo %date% %time% - IsAkRunning exists on AK84 >> %LOGFILE%
) Else (
xcopy /c /q /y IsAkRunning.bat \\%AK84_IP%\c$\Scripts\
Echo %date% %time% - IsAkRunning was not on AK84, copied. >> %LOGFILE%
)
goto AK85

:AK85
echo %date% %time% - AK85 is %AK85_IP%
If Exist "\\%AK85_IP%\c$\Scripts\IsAkRunning.bat" (
Echo %date% %time% - IsAkRunning exists on AK85 >> %LOGFILE%
) Else (
xcopy /c /q /y IsAkRunning.bat \\%AK85_IP%\c$\Scripts\
)
goto START_AK

REM Starting IsAKRunning on each KPS, if AK is not running it will start. If it is already running, the controller may reboot. 
:START_AK
cls
echo Starting IsAKRunning.bat on each KPS.
echo %date% %time% - Starting IsAKRunning.bat on each KPS. >> %LOGFILE%
Set AKDIR=%cd%
"%AKDIR%\psexec" \\%AK81_IP% -s -d -i "C:\Scripts\IsAkRunning.bat"
echo AK Attempted to start on AK81
"%AKDIR%\psexec" \\%AK82_IP% -s -d -i "C:\Scripts\IsAkRunning.bat"
echo AK Attempted to start on AK82
"%AKDIR%\psexec" \\%AK83_IP% -s -d -i "C:\Scripts\IsAkRunning.bat"
echo AK Attempted to start on AK83
"%AKDIR%\psexec" \\%AK84_IP% -s -d -i "C:\Scripts\IsAkRunning.bat"
echo AK Attempted to start on AK84
"%AKDIR%\psexec" \\%AK85_IP% -s -d -i "C:\Scripts\IsAkRunning.bat"
echo AK Attempted to start on AK85

echo %date% %time% - Complete. Make sure to check the controllers. StartAK.bat may need to be manually started. >> %LOGFILE%
echo %date% %time% - If the script failed, make sure the current user (%username%) can path to the controllers from the File Server >> %LOGFILE%

Timeout /t 10
exit


