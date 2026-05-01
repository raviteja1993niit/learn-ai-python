#############################################################################
# MCP Server Setup Script
# Purpose: Automated setup for MCP servers with Node.js
# Usage: .\setup-mcp-server.ps1
# Prerequisites: Current user permissions, Internet connection
# No admin privileges required
#############################################################################

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Configuration
# Dynamic path: Parent directory of the scripts folder where this script is running
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ParentPath = Split-Path -Parent $ScriptPath
$MCP_ROOT = Join-Path $ParentPath "mcp-servers"
$SERVERS = @("mcp-confluence")
$SCRIPT_VERSION = "2.0.0"

#############################################################################
# Logging Functions
#############################################################################

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Text)
    Write-Host "⚠ $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ $Text" -ForegroundColor Cyan
}

#############################################################################
# Prerequisite Checks
#############################################################################

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"

    try {
        $nodeVersion = node --version
        Write-Success "Node.js found: $nodeVersion"
    } catch {
        Write-Error-Custom "Node.js not found. Please install from nodejs.org"
        exit 1
    }

    try {
        $npmVersion = npm --version
        Write-Success "npm found: $npmVersion"
    } catch {
        Write-Error-Custom "npm not found. Please reinstall Node.js"
        exit 1
    }

    try {
        $gitVersion = git --version
        Write-Success "Git found: $gitVersion"
    } catch {
        Write-Warning-Custom "Git not found. Install from git-scm.com if cloning is needed"
    }

    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Success "Running as user: $currentUser"
    Write-Info "npm packages will be installed to user directory (no admin required)"
}

#############################################################################
# Directory Setup
#############################################################################

function Initialize-Directories {
    Write-Header "Setting Up Directories"

    if (-not (Test-Path $MCP_ROOT)) {
        New-Item -ItemType Directory -Path $MCP_ROOT -Force | Out-Null
        Write-Success "Created directory: $MCP_ROOT"
    } else {
        Write-Info "Directory already exists: $MCP_ROOT"
    }

    foreach ($server in $SERVERS) {
        $serverPath = Join-Path $MCP_ROOT $server
        if (-not (Test-Path $serverPath)) {
            New-Item -ItemType Directory -Path $serverPath -Force | Out-Null
            Write-Success "Created server directory: $serverPath"
        } else {
            Write-Info "Server directory exists: $serverPath"
        }
    }

    Set-Location $MCP_ROOT
    Write-Success "Changed working directory to: $MCP_ROOT"
}

#############################################################################
# Dependency Installation
#############################################################################

function Install-Dependencies {
    Write-Header "Installing Dependencies"

    foreach ($server in $SERVERS) {
        $serverPath = Join-Path $MCP_ROOT $server
        $packageJson = Join-Path $serverPath "package.json"

        if (Test-Path $packageJson) {
            Write-Info "Installing dependencies for: $server"
            Set-Location $serverPath

            try {
                npm cache clean --force 2>$null | Out-Null
                npm install --no-optional 2>&1 | Out-Null

                Write-Success "Dependencies installed: $server"

                $nodeModulesPath = Join-Path $serverPath "node_modules"
                if (Test-Path $nodeModulesPath) {
                    $moduleCount = (Get-ChildItem -Path $nodeModulesPath -Directory | Measure-Object).Count
                    Write-Info "Modules installed: $moduleCount"
                } else {
                    Write-Error-Custom "node_modules not found after installation: $server"
                }
            } catch {
                Write-Error-Custom "Failed to install dependencies for: $server"
                Write-Error-Custom ("Error: " + $_.Exception.Message)
                Write-Info "Tip: Ensure you have write permissions to $serverPath"
            }
        } else {
            Write-Warning-Custom "package.json not found in: $server"
        }
    }
}

#############################################################################
# Environment Configuration
#############################################################################

function Setup-Environment {
    Write-Header "Setting Up Environment Files"

    foreach ($server in $SERVERS) {
        $serverPath = Join-Path $MCP_ROOT $server
        $envExample = Join-Path $serverPath ".env.example"
        $envFile = Join-Path $serverPath ".env"

        if (Test-Path $envExample) {
            if (-not (Test-Path $envFile)) {
                Copy-Item $envExample $envFile
                Write-Success "Created .env file: $server"
            } else {
                Write-Info ".env file already exists: $server"
            }
        } else {
            Write-Warning-Custom ".env.example not found: $server"
        }

        $mcpJson = Join-Path $serverPath "mcp.json"
        if (-not (Test-Path $mcpJson)) {
            Write-Info "Creating mcp.json template: $server"
            $mcpTemplate = @{
                "name" = $server
                "version" = "1.0.0"
                "description" = "MCP Server: $server"
                "tools" = @()
                "resources" = @()
                "prompts" = @()
            } | ConvertTo-Json -Depth 10

            Set-Content -Path $mcpJson -Value $mcpTemplate
            Write-Success "Created mcp.json: $server"
        } else {
            Write-Info "mcp.json already exists: $server"
        }
    }
}

#############################################################################
# Credential Validation
#############################################################################

function Validate-Credentials {
    Write-Header "Validating Credentials"

    foreach ($server in $SERVERS) {
        $serverPath = Join-Path $MCP_ROOT $server
        $envFile = Join-Path $serverPath ".env"

        if (-not (Test-Path $envFile)) {
            Write-Warning-Custom "Skipping credential validation for $server (.env not found)"
            continue
        }

        Write-Info "Validating credentials for: $server"

        $envContent = Get-Content $envFile | Where-Object { $_ -match "=" -and -not $_.StartsWith("#") }

        $hasUrl = $envContent | Where-Object { $_ -match "URL" }
        $hasToken = $envContent | Where-Object { $_ -match "TOKEN|API" }

        if (-not $hasUrl) {
            $msg = "$server - Missing URL configuration in .env"
            Write-Warning-Custom $msg
        }

        if (-not $hasToken) {
            $msg = "$server - Missing API token/credentials in .env"
            Write-Warning-Custom $msg
        }

        if ($hasUrl -and $hasToken) {
            $msg = "$server - Credentials configured"
            Write-Success $msg
        }
    }
}

#############################################################################
# Verification
#############################################################################

function Verify-Installation {
    Write-Header "Verifying Installation"

    $allGood = $true

    foreach ($server in $SERVERS) {
        $serverPath = Join-Path $MCP_ROOT $server

        if (Test-Path $serverPath) {
            Write-Success "Directory verified: $server"
        } else {
            Write-Error-Custom "Directory missing: $server"
            $allGood = $false
            continue
        }

        $packageJson = Join-Path $serverPath "package.json"
        if (Test-Path $packageJson) {
            Write-Success "package.json verified: $server"
        } else {
            Write-Warning-Custom "package.json missing: $server"
        }

        $nodeModules = Join-Path $serverPath "node_modules"
        if (Test-Path $nodeModules) {
            Write-Success "Dependencies verified: $server"
        } else {
            Write-Error-Custom "Dependencies not installed: $server"
            $allGood = $false
        }

        $envFile = Join-Path $serverPath ".env"
        if (Test-Path $envFile) {
            Write-Success ".env file verified: $server"
        } else {
            Write-Warning-Custom ".env file missing: $server"
        }

        $mcpJson = Join-Path $serverPath "mcp.json"
        if (Test-Path $mcpJson) {
            Write-Success "mcp.json verified: $server"
        } else {
            Write-Warning-Custom "mcp.json missing: $server"
        }
    }

    return $allGood
}

#############################################################################
# Summary & Next Steps
#############################################################################

function Show-Summary {
    param([bool]$Success)

    Write-Header "Setup Summary"

    if ($Success) {
        Write-Success "All checks passed! Setup completed successfully."
    } else {
        Write-Warning-Custom "Setup completed with warnings. Please review above."
    }

    Write-Host ""
    Write-Host "📁 Installation Location: $MCP_ROOT" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Server Status:" -ForegroundColor Yellow

    foreach ($server in $SERVERS) {
        $serverPath = Join-Path $MCP_ROOT $server

        $packageJson = Join-Path $serverPath "package.json"
        $nodeModules = Join-Path $serverPath "node_modules"
        $envFile = Join-Path $serverPath ".env"

        if ((Test-Path $packageJson) -and (Test-Path $nodeModules) -and (Test-Path $envFile)) {
            Write-Host "  ✓ $server - Ready to start" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $server - Incomplete setup" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Navigate to server directory:"
    Write-Host "   cd $MCP_ROOT\mcp-confluence" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Verify credentials in .env file:"
    Write-Host "   - Check CONFLUENCE_URL is correct" -ForegroundColor White
    Write-Host "   - Check CONFLUENCE_API_TOKEN is valid" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Update mcp.json with your paths:"
    Write-Host "   - Update tool definitions" -ForegroundColor White
    Write-Host "   - Configure resource mappings" -ForegroundColor White
    Write-Host "   - Update configuration paths for your environment" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Test the connection:"
    Write-Host "   npm test" -ForegroundColor White
    Write-Host ""
    Write-Host "5. Start the MCP server:"
    Write-Host "   npm start" -ForegroundColor White
    Write-Host ""
    Write-Host "Server Control:" -ForegroundColor Yellow
    Write-Host "  To stop a running server, press Ctrl+C in the terminal" -ForegroundColor Cyan
    Write-Host "  To restart, run: npm start again" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Documentation: Check Confluence for additional setup guides" -ForegroundColor Cyan
    Write-Host ""
}

#############################################################################
# Main Execution
#############################################################################

function Main {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     MCP Server Setup Script (v$SCRIPT_VERSION)          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    try {
        Test-Prerequisites
        Initialize-Directories
        Install-Dependencies
        Setup-Environment
        Validate-Credentials

        $success = Verify-Installation
        Show-Summary $success

        if ($success) {
            exit 0
        } else {
            exit 1
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Error-Custom ("Fatal error during setup: " + $errorMsg)
        exit 1
    }
}

Main

