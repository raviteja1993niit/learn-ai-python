<#
.SYNOPSIS
Quick wrapper to generate git-diff reports with sensible defaults.

.DESCRIPTION
Simplified interface to Generate-GitDiff.ps1. Use this for quick diff generation
without worrying about all the parameters.

.PARAMETER RepoPath
Path to repository (default: current directory)

.PARAMETER Output
Output file (default: <repo>/git-diff.txt)

.PARAMETER Quick
Quick mode: exclude stashed changes and commit history

.PARAMETER Full
Full mode: include everything with 50-commit history

.EXAMPLE
git-diff                           # Current directory
git-diff -RepoPath "C:\projects\myrepo"
git-diff -Quick
git-diff -Full -Output "C:\reports\diff.txt"

.NOTES
Author: Mastercard PGS Connectivity
Version: 1.0.0
#>

param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$Output = $null,
    [switch]$Quick = $false,
    [switch]$Full = $false,
    [switch]$Verbose = $false
)

# Determine parameters based on mode
$includeStashed = -not $Quick
$includeHistory = -not $Quick
$historyDepth = if ($Full) { 50 } else { 20 }

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$generateScript = Join-Path $scriptDir "Generate-GitDiff.ps1"

# Verify Generate-GitDiff.ps1 exists
if (-not (Test-Path $generateScript)) {
    Write-Error "Generate-GitDiff.ps1 not found in: $scriptDir"
    exit 1
}

# Build parameters
$params = @{
    RepoPath = $RepoPath
    IncludeStashed = $includeStashed
    IncludeHistory = $includeHistory
    HistoryDepth = $historyDepth
}

if ($Output) {
    $params['OutputFile'] = $Output
}

if ($Verbose) {
    $params['VerboseOutput'] = $true
}

# Call main script
& $generateScript @params

