@echo off

rem Set the working directory to the location of the script
cd /d "%~dp0" 

rem Check if a destination folder is provided as a command-line argument
if "%1"=="" (
    echo Error: Please provide the destination folder as a command-line argument.
    echo:
    echo Usage: %~nx0 "<Destination folder/path>"
    echo Example: %~nx0 "D:\Backup"
    echo.
    pause
    goto :eof
)

set LogPath="logs"
set SourcePathsFile="sources.txt"
set DestinationPath=%1

set Timestamp=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
set Timestamp=%Timestamp: =0%
set Timestamp=%Timestamp:~0,19%
set ErrorLogFile=%LogPath%\Backup_Error_Log_%Timestamp%.txt

mkdir %LogPath%

rem Iterate through each line in the input file
for /F "usebackq delims=" %%A in (%SourcePathsFile%) do (
    set SourcePath=%%A

    rem Generate a unique log file for each source path
    set LogFile=%LogPath%\Backup_Log_%Timestamp%_%%~nA.txt

    rem Run the robocopy command for each source path
    robocopy %%A %DestinationPath% /S /E /XO /NP /LOG:%LogFile% /TEE /R:3 /W:5

    if %errorlevel% gtr 7 (
        echo Error: Backup operation failed with error code %errorlevel% at %date% %time: =0% >> %ErrorLogFile%
    )
)
