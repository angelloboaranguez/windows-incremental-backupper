@echo off

rem Check if the script is being executed in PowerShell
setlocal
CALL :GETPARENT PARENT
IF /I "%PARENT%" == "powershell" GOTO :ISPOWERSHELL
IF /I "%PARENT%" == "pwsh" GOTO :ISPOWERSHELL
endlocal

rem Check if a destination folder is provided as a command-line argument
if "%1"=="" (
    echo Error: Please provide the destination folder as a command-line argument.
    echo:
    echo Usage: %~nx0 "<Destination folder/path>"
    echo Example: %~nx0 "D:\Backup"
    echo:
    pause
    goto :eof
)

rem Set the working directory to the location of the script
cd /d "%~dp0" 

set LogPath="logs"
set SourcePathsFile="sources.txt"
set DestinationPath="%~1"

set Timestamp="%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"
set Timestamp="%Timestamp: =0%"
set Timestamp="%Timestamp:~0,19%"
set ErrorLogFile="%LogPath%\Backup_Error_Log_%Timestamp%.txt"

mkdir "%LogPath%"

rem Iterate through each line in the input file
for /F "usebackq delims=" %%A in (%SourcePathsFile%) do (
    rem Ignore lines starting with common comment indicators (REM, rem, ::, ;)
    echo %%A | findstr /r /i /b /c:"^rem " /c:"^::" /c:"^;" >nul && (
        echo Ignoring comment: %%A
    ) || (
        set SourcePath="%%A"

        rem Check if the source folder exists before proceeding
        if not exist "%%A" (
            echo Warning: Source folder "%%A" does not exist. Skipping... >> "%ErrorLogFile%"
            echo Warning: Source folder "%%A" does not exist. Skipping...
        ) else (
            rem Generate a unique log file for each source path
            set LogFile="%LogPath%\Backup_Log_%Timestamp%_%%~nA.txt"

            rem Run the robocopy command for each valid source path
            robocopy "%%A" "%DestinationPath%" /S /E /XO /NP /LOG:"%LogFile%" /TEE /R:3 /W:5

            if %errorlevel% gtr 7 (
                echo Error: Backup operation failed with error code %errorlevel% at %date% %time: =0% >> "%ErrorLogFile%"
            )
        )
    )
)
echo Process finished.

GOTO :EOF

:GETPARENT
SET "PSCMD=$ppid=$pid;while($i++ -lt 3 -and ($ppid=(Get-CimInstance Win32_Process -Filter ('ProcessID='+$ppid)).ParentProcessId)) {}; (Get-Process -EA Ignore -ID $ppid).Name"

for /f "tokens=*" %%i in ('powershell -noprofile -command "%PSCMD%"') do SET %1=%%i

GOTO :EOF

:ISPOWERSHELL
echo. >&2
echo ERROR: This program cannot be run in PowerShell. Please use classic Windows CMD Command Promp. >&2
pause
echo. >&2
exit /b 1
