@echo off
REM #############################################################################
REM  run-git-diff.bat
REM  Wrapper to invoke git-diff-capture-simple.ps1
REM
REM  HOW TO USE:
REM    1. Edit the USER CONFIGURATION section below
REM    2. Save the file
REM    3. Double-click or run: scripts\run-git-diff.bat
REM #############################################################################

SETLOCAL

REM =============================================================================
REM  USER CONFIGURATION — Edit these values before running
REM =============================================================================

REM [REQUIRED] Source branch (the feature/topic branch you want to inspect)
SET SOURCE_BRANCH=feature/G1198_5772_5773_ELAVON_CHASE_FLOW_MIGRATION

REM [REQUIRED] Target branch (the base branch to compare against)
SET TARGET_BRANCH=develop

REM [OPTIONAL] File extension filter — leave blank to include all files
REM  Examples: .yaml   .ts   .java   .json
SET FILE_FILTER=.json

REM [OPTIONAL] Directory filter — leave blank to scan whole repo
REM  Supports BOTH relative and absolute paths:
REM    Relative: src/main/resources       (matches any path containing this segment)
REM    Relative: resources                (matches any path containing 'resources')
REM    Absolute: C:\myproject\src\main    (matches files under this exact folder)
REM  Note: Use forward slashes or backslashes — both are handled automatically.
SET DIR_FILTER=src/main/resources

REM [OPTIONAL] Output filename — leave blank to auto-generate with timestamp
REM  Example: my-diff-report.txt
SET OUTPUT_FILE=

REM =============================================================================
REM  END OF USER CONFIGURATION — Do not edit below this line
REM =============================================================================

REM ── Validate required values are set ─────────────────────────────────────────
IF "%SOURCE_BRANCH%"=="" (
    echo.
    echo  ERROR: SOURCE_BRANCH is not set. Please edit this .bat file.
    echo.
    pause
    exit /b 1
)

IF "%TARGET_BRANCH%"=="" (
    echo.
    echo  ERROR: TARGET_BRANCH is not set. Please edit this .bat file.
    echo.
    pause
    exit /b 1
)

REM ── Resolve script location and repo root ────────────────────────────────────
SET SCRIPT_DIR=%~dp0
SET PS1_SCRIPT=%SCRIPT_DIR%git-diff-capture-simple.ps1

REM Change working directory to repo root (one level above scripts/)
cd /d "%SCRIPT_DIR%.."

REM ── Check PS1 script exists ───────────────────────────────────────────────────
IF NOT EXIST "%PS1_SCRIPT%" (
    echo.
    echo  ERROR: PowerShell script not found: %PS1_SCRIPT%
    echo.
    exit /b 1
)

REM ── Build PowerShell argument string dynamically ──────────────────────────────
SET PS_ARGS=-ExecutionPolicy Bypass -File "%PS1_SCRIPT%" -SourceBranch "%SOURCE_BRANCH%" -TargetBranch "%TARGET_BRANCH%"

IF NOT "%FILE_FILTER%"==""  SET PS_ARGS=%PS_ARGS% -FileFilter "%FILE_FILTER%"
IF NOT "%DIR_FILTER%"==""   SET PS_ARGS=%PS_ARGS% -DirectoryFilter "%DIR_FILTER%"
IF NOT "%OUTPUT_FILE%"==""  SET PS_ARGS=%PS_ARGS% -OutputFile "%OUTPUT_FILE%"

REM ── Display run config ────────────────────────────────────────────────────────
echo.
echo  ============================================================
echo   Git Diff Capture
echo  ============================================================
echo   Source Branch  : %SOURCE_BRANCH%
echo   Target Branch  : %TARGET_BRANCH%
IF NOT "%FILE_FILTER%"==""  echo   File Filter    : %FILE_FILTER%
IF NOT "%DIR_FILTER%"==""   echo   Directory      : %DIR_FILTER%
IF NOT "%OUTPUT_FILE%"==""  echo   Output File    : %OUTPUT_FILE%
echo  ============================================================
echo.

REM ── Execute PowerShell script ─────────────────────────────────────────────────
powershell %PS_ARGS%

REM ── Capture and report exit code ─────────────────────────────────────────────
SET EXIT_CODE=%ERRORLEVEL%

echo.
IF %EXIT_CODE%==0 (
    echo  [SUCCESS] Git diff report generated successfully.
) ELSE (
    echo  [FAILED]  Script exited with error code: %EXIT_CODE%
)
echo.

ENDLOCAL
exit /b %EXIT_CODE%

