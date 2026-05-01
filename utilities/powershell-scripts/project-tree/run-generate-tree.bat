@echo off
:: Simple wrapper to run generate-tree.ps1 with configurable repo path.
:: Usage: run-generate-tree.bat [RepoPath] [MaxDepth] [OutFile]
::
:: Arguments (all optional):
::   RepoPath  - Path to the repository (defaults to current directory if not provided)
::   MaxDepth  - Maximum recursion depth (numeric, e.g. 3)
::   OutFile   - Output file path (defaults to RepoPath\project-tree.txt if not provided)
::
:: Examples:
::   run-generate-tree.bat                           - Uses current directory
::   run-generate-tree.bat C:\path\to\repo          - Uses specified repo path
::   run-generate-tree.bat C:\path\to\repo 3        - Limits depth to 3
::   run-generate-tree.bat C:\path\to\repo 3 out.txt - Full specification
::
:: Note: Do not pass OutFile with escaped surrounding quotes (e.g. \"C:\path\file.txt\").
:: Pass a normal path (relative or absolute).

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%generate-tree.ps1"

:: Initialize defaults
set "REPOPATH=%CD%"
set "MAXDEPTH=%~1"
set "OUTFILE=%~2"

:: Smart argument detection: check if %~1 looks like a path
:: If it contains : (drive letter), \ or / (path separators), or exists as a directory, treat it as RepoPath
if not "%~1"=="" (
  :: Test 1: Contains colon (likely drive letter)
  echo %~1 | findstr /R ":" >nul && (
    set "REPOPATH=%~1"
    set "MAXDEPTH=%~2"
    set "OUTFILE=%~3"
  ) || (
    :: Test 2: Contains backslash or forward slash
    echo %~1 | findstr /R "[\\\/]" >nul && (
      set "REPOPATH=%~1"
      set "MAXDEPTH=%~2"
      set "OUTFILE=%~3"
    ) || (
      :: Test 3: Exists as a directory
      if exist "%~1" (
        set "REPOPATH=%~1"
        set "MAXDEPTH=%~2"
        set "OUTFILE=%~3"
      )
    )
  )
)

:: Validate that RepoPath exists
if not exist "!REPOPATH!" (
  echo Error: RepoPath does not exist: "!REPOPATH!"
  exit /b 1
)

:: Resolve to absolute path
for /f "tokens=*" %%A in ('cd /d "!REPOPATH!" ^& cd') do (
  set "REPOPATH=%%A"
)

:: Set default OutFile if not provided
if "!OUTFILE!"=="" (
  set "OUTFILE=!REPOPATH!\project-tree.txt"
)

:: Build MaxDepth argument
if not "!MAXDEPTH!"=="" (
  set "MAXDEPTH_ARG=-MaxDepth !MAXDEPTH!"
) else (
  set "MAXDEPTH_ARG="
)

echo Running: powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!" -TargetPath "!REPOPATH!" !MAXDEPTH_ARG! -OutFile "!OUTFILE!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!" -TargetPath "!REPOPATH!" !MAXDEPTH_ARG! -OutFile "!OUTFILE!"

endlocal
