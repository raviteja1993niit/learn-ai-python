<#
.SYNOPSIS
Install and configure git-diff utility scripts.

.DESCRIPTION
Sets up git-diff scripts, adds to PATH (optional), and validates installation.

.PARAMETER InstallPath
Installation directory (default: script's current location)

.PARAMETER AddToPath
Add scripts to system PATH (requires admin)

.EXAMPLE
.\Install-GitDiffScripts.ps1

.EXAMPLE
.\Install-GitDiffScripts.ps1 -InstallPath "C:\tools\git-diff" -AddToPath

.NOTES
Author: Mastercard PGS Connectivity
Version: 1.0.0
#>

param(
    [string]$InstallPath = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [switch]$AddToPath = $false
)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Git-Diff Scripts Installation" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Validate installation path
if (-not (Test-Path $InstallPath)) {
    Write-Error "Installation path does not exist: $InstallPath"
    exit 1
}

Write-Host "Installation path: $InstallPath" -ForegroundColor Green

# Check for required scripts
$requiredScripts = @(
    "Generate-GitDiff.ps1",
    "Batch-GenerateGitDiffs.ps1",
    "git-diff.ps1"
)

Write-Host ""
Write-Host "Validating scripts..." -ForegroundColor Cyan

$allFound = $true
foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $InstallPath $script
    if (Test-Path $scriptPath) {
        Write-Host "  ✓ $script" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $script - NOT FOUND" -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    Write-Host ""
    Write-Error "Some scripts are missing. Please ensure all files are in: $InstallPath"
    exit 1
}

# Test script execution
Write-Host ""
Write-Host "Testing script execution..." -ForegroundColor Cyan

try {
    $testScript = Join-Path $InstallPath "git-diff.ps1"
    $result = & powershell -NoProfile -ExecutionPolicy Bypass -File $testScript -RepoPath $PSScriptRoot -Quick 2>&1
    Write-Host "  ✓ Scripts are executable" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Script execution test failed: $_" -ForegroundColor Red
}

# Add to PATH if requested
if ($AddToPath) {
    Write-Host ""
    Write-Host "Adding to PATH..." -ForegroundColor Cyan

    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

    if (-not $isAdmin) {
        Write-Host "  ⚠ Requires administrator privileges. Skipping PATH modification." -ForegroundColor Yellow
    } else {
        try {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            if ($currentPath -notcontains $InstallPath) {
                $newPath = "$currentPath;$InstallPath"
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
                Write-Host "  ✓ Added to system PATH" -ForegroundColor Green
            } else {
                Write-Host "  ℹ Already in PATH" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  ✗ Failed to modify PATH: $_" -ForegroundColor Red
        }
    }
}

# Completion summary
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Quick Start:" -ForegroundColor Cyan
Write-Host "  .\git-diff.ps1 -RepoPath `"C:\path\to\repo`"" -ForegroundColor Yellow
Write-Host ""
Write-Host "For more information, see README.md in this directory" -ForegroundColor Cyan
Write-Host ""

