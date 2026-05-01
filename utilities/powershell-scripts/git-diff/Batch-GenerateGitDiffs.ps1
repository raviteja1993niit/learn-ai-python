<#
.SYNOPSIS
Batch generate git-diff reports for multiple repositories.

.DESCRIPTION
Scans a parent directory for git repositories and generates git-diff reports for each one.
Results are saved to a reports directory with organized folder structure.

.PARAMETER ParentPath
Parent directory containing multiple git repositories

.PARAMETER ReportsDir
Directory to save all diff reports (default: ./git-diff-reports)

.PARAMETER Recursive
Recursively search for git repositories (default: false)

.PARAMETER HistoryDepth
Number of commits to include in each report (default: 20)

.EXAMPLE
.\Batch-GenerateGitDiffs.ps1 -ParentPath "C:\projects" -ReportsDir "C:\reports\diffs"

.EXAMPLE
.\Batch-GenerateGitDiffs.ps1 -ParentPath "C:\projects" -Recursive -HistoryDepth 50

.NOTES
Author: Mastercard PGS Connectivity
Version: 1.0.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$ParentPath,

    [string]$ReportsDir = ".\git-diff-reports",
    [switch]$Recursive = $false,
    [int]$HistoryDepth = 20
)

# Create reports directory
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
    Write-Host "Created reports directory: $ReportsDir" -ForegroundColor Green
}

# Find all git repositories
Write-Host "Scanning for git repositories..." -ForegroundColor Cyan

if ($Recursive) {
    $repos = Get-ChildItem -Path $ParentPath -Recurse -Filter ".git" -Directory |
             ForEach-Object { Split-Path -Parent $_.FullName }
} else {
    $repos = Get-ChildItem -Path $ParentPath -Directory |
             Where-Object { Test-Path (Join-Path $_.FullName ".git") } |
             ForEach-Object { $_.FullName }
}

$repoCount = @($repos).Count
Write-Host "Found $repoCount git repository(ies)" -ForegroundColor Green
Write-Host ""

if ($repoCount -eq 0) {
    Write-Host "No git repositories found in $ParentPath" -ForegroundColor Yellow
    exit 0
}

# Process each repository
$successCount = 0
$failureCount = 0

foreach ($repo in $repos) {
    $repoName = Split-Path -Leaf $repo
    $reportDir = Join-Path $ReportsDir $repoName

    # Create repo-specific directory
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $outputFile = Join-Path $reportDir "git-diff.txt"

    Write-Host "Processing: $repoName" -ForegroundColor Yellow

    try {
        # Call Generate-GitDiff.ps1
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $generateScript = Join-Path $scriptPath "Generate-GitDiff.ps1"

        if (Test-Path $generateScript) {
            & $generateScript -RepoPath $repo -OutputFile $outputFile -HistoryDepth $HistoryDepth
            $successCount++
            Write-Host "  ✓ Report saved: $outputFile" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Generate-GitDiff.ps1 not found at: $generateScript" -ForegroundColor Red
            $failureCount++
        }
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        $failureCount++
    }

    Write-Host ""
}

# Summary
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "BATCH PROCESSING COMPLETE" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })
Write-Host "Reports location: $ReportsDir" -ForegroundColor Green
Write-Host ""

