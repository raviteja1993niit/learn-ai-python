@echo off
REM #############################################################################
REM  setup-mcp-server.bat
REM  Wrapper script to invoke PowerShell setup script
REM  Purpose: One-click MCP server setup with automatic dependency installation
REM  Usage: Double-click this file or run: setup-mcp-server.bat
REM  Location: scripts\setup-mcp-server.bat
REM #############################################################################

SETLOCAL EnableDelayedExpansion

REM Set console title
title MCP Server Setup - Automated Configuration

REM Display banner
cls
echo.
echo.
echo   ========================================================================
echo   =                                                                      =
echo   =          MCP SERVER SETUP - AUTOMATED INSTALLATION                  =
echo   =          Model Context Protocol Server Configuration                 =
echo   =                                                                      =
echo   =          No administrator privileges required                        =
echo   =          Current user permissions only                              =
echo   =                                                                      =
echo   ========================================================================
echo.
echo.

REM Determine script location - use current directory
SET SCRIPT_DIR=%~dp0
SET PS1_SCRIPT=%SCRIPT_DIR%setup-mcp-server.ps1

REM Verify the script exists in the scripts folder
if not exist "%PS1_SCRIPT%" (
    echo.
    echo   [ERROR] PowerShell script not found at: %PS1_SCRIPT%
    echo   ---------------------------------------------------------------
    echo   This batch file must be run from the scripts directory.
    echo.
    echo   Expected: %SCRIPT_DIR%
    echo.
    echo   Solution:
    echo   1. Navigate to scripts folder
    echo   2. Double-click setup-mcp-server.bat
    echo   3. OR run from command line: %SCRIPT_DIR%setup-mcp-server.bat
    echo.
    pause
    exit /b 1
)

REM Verify PowerShell is available
powershell -NoProfile -Command "Exit 0" >nul 2>&1
if errorlevel 1 (
    echo.
    echo   [ERROR] PowerShell is not available
    echo   ---------------------------------------------------------------
    echo   Windows PowerShell 5.0 or higher is required.
    echo.
    pause
    exit /b 1
)

REM Determine installation target dynamically (parent of scripts folder)
FOR /D %%I IN ("%SCRIPT_DIR%..") DO SET MCP_ROOT=%%~fI

REM Display system info
echo   System Information:
echo   ---------------------------------------------------------------
echo   Script Location: %SCRIPT_DIR%
echo   Installation Target: %MCP_ROOT%\mcp-servers\
echo   PowerShell: %PS1_SCRIPT%
echo.
echo.

REM Display countdown
echo   Starting setup process in...
echo.
timeout /t 3 /nobreak >nul
cls

REM Execute PowerShell script (no admin privileges needed)
echo   Executing MCP Server Setup Script...
echo   ---------------------------------------------------------------
echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%PS1_SCRIPT%"

REM Capture exit code
SET EXIT_CODE=%ERRORLEVEL%

REM Display results
cls
echo.
echo.
echo   ========================================================================
echo   =                         SETUP COMPLETE                             =
echo   ========================================================================
echo.

if %EXIT_CODE% equ 0 (
    echo   Status: SUCCESS (^o^)
    echo.
    echo   All checks passed! Your MCP server is ready to configure.
    echo.
    echo   Next Steps:
    echo   ---------------------------------------------------------------
    echo   1. Navigate to: %MCP_ROOT%\mcp-servers\mcp-confluence
    echo   2. Update .env file with your Confluence credentials
    echo   3. Update mcp.json with your configuration paths
    echo   4. Run: npm test (to validate connection)
    echo   5. Run: npm start (to launch the server)
    echo.
) else (
    echo   Status: FAILED (x_x)
    echo.
    echo   Setup encountered errors. Please review the output above.
    echo.
    echo   Common Issues and Solutions:
    echo   ---------------------------------------------------------------
    echo   ERROR: Node.js not found
    echo   SOLUTION: Install from https://nodejs.org/
    echo            OR run: choco install nodejs
    echo.
    echo   ERROR: npm permission denied
    echo   SOLUTION: Ensure you have write permissions to: %MCP_ROOT%
    echo            OR create directory first: mkdir "%MCP_ROOT%\mcp-servers"
    echo.
    echo   ERROR: Variable reference is not valid
    echo   SOLUTION: This batch file must be run from the scripts folder
    echo            Location: [downloaded-folder]\scripts\setup-mcp-server.bat
    echo.
    echo   ERROR: PowerShell not available
    echo   SOLUTION: Windows PowerShell 5.0+ is required
    echo            Check: powershell -Version
    echo.
    echo   For more help:
    echo   - Check the PowerShell output above for detailed error messages
    echo   - Review installation folder for incomplete setup
    echo.
)

echo   Exit Code: %EXIT_CODE%
echo.
echo   ========================================================================
echo.
echo   Press any key to close this window...
echo.
pause >nul

ENDLOCAL
exit /b %EXIT_CODE%

