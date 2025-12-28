@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: NAV DATABASE BACKUP - FETCH, ENCRYPT & DISTRIBUTE
:: 1. Fetches newest .bak from NAS to Local Disk
:: 2. Encrypts it locally
:: 3. Copies encrypted file to Portable HDD & OneDrive
:: ================================================================

:: --- [CONFIGURATION] ---
set "WINRAR_EXE=C:\Program Files\WinRAR\WinRAR.exe"
set "ENCRYPT_PASSWORD=XXXXXXXXX"

:: Source (NAS Share)
set "REMOTE_SOURCE_FOLDER=\\192.X.X.X\backupfolder\Full_Backup"

:: Local Staging (Must have ~20GB Free Space)
:: This is where we will do the work safely.
set "LOCAL_STAGING_DIR=C:\Temp_Encrypt_Staging"

:: Destinations
set "PORTABLE_HDD=E:\BACKUP"
set "ONEDRIVE_FOLDER=C:\Users\itadmin\XX\All_Storage\XXX\SQL Backup"
set "LOG_DIR=C:\Scripts\logs"

:: ----------------------------------------------------------------

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%LOCAL_STAGING_DIR%" mkdir "%LOCAL_STAGING_DIR%"

set "LOG_FILE=%LOG_DIR%\backup_log_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "LOG_FILE=%LOG_FILE: =0%"

call :log "--- STARTING BACKUP PROCESS ---"

:: 1. FIND NEWEST REMOTE FILE
call :log "Searching NAS for newest .bak file..."
set "REMOTE_FILE="
set "FILE_COUNT=0"

for /f "tokens=*" %%F in ('dir "%REMOTE_SOURCE_FOLDER%\*.bak" /b /o-d 2^>nul') do (
    if !FILE_COUNT! equ 0 (
        set "REMOTE_FILE=%REMOTE_SOURCE_FOLDER%\%%F"
        set "FILENAME_ONLY=%%~nF"
        set "EXTENSION_ONLY=%%~xF"
    )
    set /a FILE_COUNT+=1
)

if "%REMOTE_FILE%"=="" (
    call :log "ERROR: No .bak files found on NAS. Exiting."
    goto :error_exit
)

call :log "Found remote file: %REMOTE_FILE%"

:: Define Local Paths
set "LOCAL_RAW_FILE=%LOCAL_STAGING_DIR%\%FILENAME_ONLY%%EXTENSION_ONLY%"
set "LOCAL_RAR_FILE=%LOCAL_STAGING_DIR%\%FILENAME_ONLY%_%date:~-4,4%%date:~-10,2%%date:~-7,2%.rar"

:: 2. FETCH FILE (NAS -> LOCAL)
call :log "Step 1/3: Fetching file from NAS to Local Disk..."
echo Fetching file... please wait...

copy /Y "%REMOTE_FILE%" "%LOCAL_RAW_FILE%"
if !errorlevel! neq 0 (
    call :log "CRITICAL ERROR: Failed to copy file from NAS to Local Disk."
    goto :error_exit
) else (
    call :log "Fetch successful."
)

:: 3. ENCRYPT FILE (LOCAL -> LOCAL)
call :log "Step 2/3: Encrypting local file..."
echo Encrypting... this takes the most CPU...

:: -hp: Encrypts file names too
:: -m2: Fast compression
:: -df: Delete the SOURCE file (the local .bak) after successful archiving
"%WINRAR_EXE%" a -hp"%ENCRYPT_PASSWORD%" -m2 -ep -df -y "%LOCAL_RAR_FILE%" "%LOCAL_RAW_FILE%"

if !errorlevel! neq 0 (
    call :log "CRITICAL ERROR: Encryption failed."
    goto :error_exit
) else (
    call :log "Encryption successful. Original local .bak deleted by WinRAR."
)

:: 4. DISTRIBUTE (LOCAL RAR -> DESTINATIONS)
call :log "Step 3/3: Distributing encrypted file..."

:: Copy to Portable HDD
copy /Y "%LOCAL_RAR_FILE%" "%PORTABLE_HDD%\"
if !errorlevel! neq 0 (
    call :log "WARNING: Copy to Portable HDD failed."
    set "HDD_COPY_FAILED=1"
) else (
    call :log "SUCCESS: Copied to Portable HDD."
)

:: Copy to OneDrive
copy /Y "%LOCAL_RAR_FILE%" "%ONEDRIVE_FOLDER%\"
if !errorlevel! neq 0 (
    call :log "WARNING: Copy to OneDrive failed."
    set "ONEDRIVE_COPY_FAILED=1"
) else (
    call :log "SUCCESS: Copied to OneDrive."
)

:: 5. CLEANUP
call :log "Cleaning up local encrypted file..."
del "%LOCAL_RAR_FILE%"
call :log "Cleanup complete. Process Finished."

goto :eof

:error_exit
call :log "PROCESS FAILED"
exit /b 1

:log
echo %date% %time% - %~1 >> "%LOG_FILE%"

goto :eof
