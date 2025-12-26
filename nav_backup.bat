@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: NAV DATABASE BACKUP COPY AND DISTRIBUTION SCRIPT
:: Automatically finds the most recent .bak file and copies it
:: ================================================================

:: Configuration
set "SOURCE_FOLDER=\\XXXX"
set "PORTABLE_HDD=E:\XXXX"
set "ONEDRIVE_FOLDER=XXXX"
set "LOG_DIR=C:\Scripts\logs"

:: Create log directory if it doesn't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Create log file with timestamp
set "LOG_FILE=%LOG_DIR%\backup_log_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "LOG_FILE=%LOG_FILE: =0%"

:: Start logging
call :log "================================================================"
call :log "NAV DATABASE BACKUP COPY AND DISTRIBUTION"
call :log "================================================================"
call :log "Script started at: %date% %time%"
call :log "Source folder: %SOURCE_FOLDER%"
call :log "Portable HDD: %PORTABLE_HDD%"
call :log "OneDrive folder: %ONEDRIVE_FOLDER%"
call :log "Log directory: %LOG_DIR%"
call :log ""

:: Test network connectivity
call :log "Testing network connectivity to %SOURCE_FOLDER%"
ping -n 1 192.168.2.29 >nul 2>&1
if !errorlevel! neq 0 (
    call :log "WARNING: Cannot ping 192.168.2.29 - network may be unreachable"
) else (
    call :log "Network connectivity OK"
)

:: Check if source folder is accessible
if not exist "%SOURCE_FOLDER%" (
    call :log "ERROR: Source folder not accessible: %SOURCE_FOLDER%"
    echo ERROR: Source folder not accessible: %SOURCE_FOLDER%
    goto :error_exit
)

:: Find the most recent .bak file in the source folder
call :log "Searching for .bak files in: %SOURCE_FOLDER%"
set "SOURCE_BAK="
set "FILE_COUNT=0"

:: Use DIR command to get files sorted by date (most recent first)
for /f "tokens=*" %%F in ('dir "%SOURCE_FOLDER%\*.bak" /b /o-d 2^>nul') do (
    if !FILE_COUNT! equ 0 (
        set "SOURCE_BAK=%SOURCE_FOLDER%\%%F"
        call :log "Selected most recent .bak file: !SOURCE_BAK!"
    )
    set /a FILE_COUNT+=1
    call :log "Found .bak file: %SOURCE_FOLDER%\%%F"
)

call :log "Total .bak files found: !FILE_COUNT!"

if !FILE_COUNT! equ 0 (
    call :log "ERROR: No .bak files found in %SOURCE_FOLDER%"
    echo ERROR: No .bak files found in %SOURCE_FOLDER%
    goto :error_exit
)

if "%SOURCE_BAK%"=="" (
    call :log "ERROR: Failed to select a .bak file"
    echo ERROR: Failed to select a .bak file
    goto :error_exit
)

:: Get filename without extension for naming the backup
for %%F in ("%SOURCE_BAK%") do (
    set "FILENAME=%%~nF"
    set "FILEEXT=%%~xF"
)

set "BACKUP_NAME=%FILENAME%_%date:~-4,4%%date:~-10,2%%date:~-7,2%.bak"

echo Starting backup process for: %SOURCE_FOLDER%
echo Selected file: %SOURCE_BAK%
echo File will be copied as: %BACKUP_NAME%
echo Log file: %LOG_FILE%
echo.

call :log "Backup filename: %BACKUP_NAME%"

:: Create directories if they don't exist
if not exist "%PORTABLE_HDD%" (
    mkdir "%PORTABLE_HDD%"
    if !errorlevel! equ 0 (
        call :log "Created directory: %PORTABLE_HDD%"
    ) else (
        call :log "ERROR: Failed to create directory: %PORTABLE_HDD%"
        goto :error_exit
    )
) else (
    call :log "Directory exists: %PORTABLE_HDD%"
)

if not exist "%ONEDRIVE_FOLDER%" (
    mkdir "%ONEDRIVE_FOLDER%"
    if !errorlevel! equ 0 (
        call :log "Created directory: %ONEDRIVE_FOLDER%"
    ) else (
        call :log "ERROR: Failed to create directory: %ONEDRIVE_FOLDER%"
        goto :error_exit
    )
) else (
    call :log "Directory exists: %ONEDRIVE_FOLDER%"
)

:: Get original file size
if exist "%SOURCE_BAK%" (
    for %%A in ("%SOURCE_BAK%") do (
        set "ORIGINAL_SIZE=%%~zA"
        call :log "Original file size: %%~zA bytes"
        set /a "SIZE_GB=%%~zA / 1073741824"
        call :log "Original file size: !SIZE_GB! GB approximately"
    )
) else (
    call :log "ERROR: Source file not accessible for size check"
    goto :error_exit
)

echo File size: !SIZE_GB! GB - Starting direct copy operations...

:: Copy to portable HDD
echo.
echo Copying to portable HDD...
call :log "Starting copy to portable HDD at: %date% %time%"

copy "%SOURCE_BAK%" "%PORTABLE_HDD%\%BACKUP_NAME%"
if !errorlevel! neq 0 (
    call :log "ERROR: Copy to portable HDD failed with error code: !errorlevel!"
    echo WARNING: Copy to portable HDD failed!
    set "HDD_COPY_FAILED=1"
) else (
    call :log "SUCCESS: Copy to portable HDD completed at: %date% %time%"
    echo Successfully copied to portable HDD
    :: Verify the copy
    if exist "%PORTABLE_HDD%\%BACKUP_NAME%" (
        for %%A in ("%PORTABLE_HDD%\%BACKUP_NAME%") do (
            call :log "Verified: Portable HDD copy size: %%~zA bytes"
        )
    ) else (
        call :log "WARNING: Copy reported success but file not found at destination"
    )
)

:: Copy to OneDrive
echo.
echo Copying to OneDrive...
call :log "Starting copy to OneDrive at: %date% %time%"

copy "%SOURCE_BAK%" "%ONEDRIVE_FOLDER%\%BACKUP_NAME%"
if !errorlevel! neq 0 (
    call :log "ERROR: Copy to OneDrive failed with error code: !errorlevel!"
    echo WARNING: Copy to OneDrive failed!
    set "ONEDRIVE_COPY_FAILED=1"
) else (
    call :log "SUCCESS: Copy to OneDrive completed at: %date% %time%"
    echo Successfully copied to OneDrive
    :: Verify the copy
    if exist "%ONEDRIVE_FOLDER%\%BACKUP_NAME%" (
        for %%A in ("%ONEDRIVE_FOLDER%\%BACKUP_NAME%") do (
            call :log "Verified: OneDrive copy size: %%~zA bytes"
        )
    ) else (
        call :log "WARNING: Copy reported success but file not found at destination"
    )
)

:: Final status
call :log ""
call :log "================================================================"
call :log "BACKUP PROCESS COMPLETED SUCCESSFULLY"
call :log "================================================================"
call :log "Process finished at: %date% %time%"

echo.
echo ================================================================
echo BACKUP PROCESS COMPLETED
echo ================================================================
echo Log file saved to: %LOG_FILE%

:: Check for any copy failures
if defined HDD_COPY_FAILED (
    echo WARNING: Portable HDD copy failed - check log for details
)
if defined ONEDRIVE_COPY_FAILED (
    echo WARNING: OneDrive copy failed - check log for details
)

goto :cleanup

:error_exit
call :log ""
call :log "================================================================"
call :log "BACKUP PROCESS FAILED"
call :log "================================================================"
call :log "Process failed at: %date% %time%"
echo.
echo ================================================================
echo BACKUP PROCESS FAILED - CHECK LOG FILE
echo ================================================================
echo Log file: %LOG_FILE%
exit /b 1

:cleanup
exit /b 0

:: Logging function
:log
echo %date% %time% - %~1 >> "%LOG_FILE%"
goto :eof