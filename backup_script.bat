@echo off
set source=E:XXX
set destination=\\XXX
set logFile=backup_log.txt
set timestamp=%date% %time%
set errorFlag=0

echo %timestamp% - Moving files from %source% to %destination%... >> %logFile%
xcopy /s /i /y %source%\* %destination% >> %logFile%
if errorlevel 1 (
    echo %timestamp% - Error occurred during the copy operation. >> %logFile%
    set errorFlag=1
) else (
    echo %timestamp% - Copy operation completed successfully. >> %logFile%
)

if %errorFlag%==1 (
    echo %timestamp% - Script encountered an error. Exiting... >> %logFile%
    exit /b 1
)

echo %timestamp% - Removing copied files from %source%... >> %logFile%
del /q /s %source%\* >> %logFile%

exit /b 0
