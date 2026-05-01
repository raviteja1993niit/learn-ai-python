#############################################################################
# Git Diff Capture Script
# Purpose: Generate git diffs between two branches and save to file
# Usage: .\git-diff-capture.ps1 -SourceBranch "feature/branch" -TargetBranch "develop" -OutputFile "diff-report.txt" -FileFilter "*.yaml"
#############################################################################

param(
    [Parameter(Mandatory=$true, HelpMessage="Source branch to compare from")]
    [string]$SourceBranch,

    [Parameter(Mandatory=$true, HelpMessage="Target branch to compare against")]
    [string]$TargetBranch,

    [Parameter(Mandatory=$false, HelpMessage="Output file path (default: ./git-diffs-{timestamp}.txt)")]
    [string]$OutputFile,

    [Parameter(Mandatory=$false, HelpMessage="File pattern filter (e.g., '*.yaml', '*.ts', optional)")]
    [string]$FileFilter,

    [Parameter(Mandatory=$false, HelpMessage="Directory filter (e.g., 'src/main/resources', optional)")]
    [string]$DirectoryFilter,

    [Parameter(Mandatory=$false, HelpMessage="Include statistics summary")]
    [bool]$IncludeStats = $true,

    [Parameter(Mandatory=$false, HelpMessage="Show file list only without full diffs")]
    [bool]$FilesOnly = $false,

    [Parameter(Mandatory=$false, HelpMessage="Verbose output to console")]
    [switch]$Verbose
)

#############################################################################
# Functions
#############################################################################

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    if ($Verbose) {
        Write-Host $logMessage
    }

    return $logMessage
}

function Test-GitRepository {
    try {
        $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
        if ($isGitRepo -eq "true") {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

function Get-BranchExists {
    param([string]$BranchName)

    $branch = git branch -a 2>$null | Where-Object { $_.Trim() -match $BranchName }
    return ($null -ne $branch)
}

function Get-FileChanges {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Filter,
        [string]$DirFilter
    )

    # Build git diff command
    $diffCommand = "git diff $Source...$Target --name-status"

    $files = Invoke-Expression $diffCommand 2>$null | Where-Object { $_ -ne "" }

    # Apply filters
    if ($Filter) {
        $files = $files | Where-Object { $_ -match $Filter }
    }

    if ($DirFilter) {
        $files = $files | Where-Object { $_ -match $DirFilter }
    }

    return $files
}

function Get-DiffStatistics {
    param(
        [string]$Source,
        [string]$Target
    )

    $stats = git diff $Source...$Target --stat 2>$null
    return $stats
}

function Get-FileDiff {
    param(
        [string]$Source,
        [string]$Target,
        [string]$FilePath
    )

    $diff = git diff $Source...$Target -- $FilePath 2>$null
    return $diff
}

function Generate-DiffReport {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Filter,
        [string]$DirFilter,
        [bool]$StatsOnly,
        [bool]$ShowFilesOnly
    )

    $report = @()
    $report += "=" * 80
    $report += "GIT DIFF REPORT"
    $report += "=" * 80
    $report += ""
    $report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Source Branch: $Source"
    $report += "Target Branch: $Target"
    $report += "File Filter: $(if ($Filter) { $Filter } else { 'none' })"
    $report += "Directory Filter: $(if ($DirFilter) { $DirFilter } else { 'none' })"
    $report += ""

    # Get changed files
    Write-Log "Fetching file changes..." | Out-Null
    $changedFiles = Get-FileChanges -Source $Source -Target $Target -Filter $Filter -DirFilter $DirFilter

    if ($null -eq $changedFiles -or $changedFiles.Count -eq 0) {
        $report += "No files changed between branches."
        return $report
    }

    $report += "FILES CHANGED: $($changedFiles.Count)"
    $report += "-" * 80
    $report += ""

    # Parse and display file changes
    $fileList = @()
    foreach ($file in $changedFiles) {
        $parts = $file -split '\s+', 2
        $status = $parts[0]
        $path = $parts[1]

        $statusIcon = switch ($status) {
            "A" { "[ADDED]" }
            "M" { "[MODIFIED]" }
            "D" { "[DELETED]" }
            "R" { "[RENAMED]" }
            "C" { "[COPIED]" }
            default { $status }
        }

        $fileList += [PSCustomObject]@{
            Status = $status
            StatusIcon = $statusIcon
            Path = $path
        }
    }

    # Display file list
    foreach ($file in $fileList) {
        $report += "$($file.StatusIcon) | $($file.Path)"
    }

    $report += ""

    # Show full diffs if not files-only mode
    if (-not $ShowFilesOnly) {
        $report += "-" * 80
        $report += "DETAILED DIFFS"
        $report += "-" * 80
        $report += ""

        foreach ($file in $fileList) {
            $report += ""
            $report += "FILE: $($file.Path)"
            $report += "STATUS: $($file.StatusIcon)"
            $report += "-" * 80

            $fileDiff = Get-FileDiff -Source $Source -Target $Target -FilePath $file.Path
            if ($fileDiff) {
                $report += $fileDiff
            } else {
                $report += "(Binary file or no differences)"
            }
            $report += ""
        }
    }

    # Add statistics if requested
    if ($IncludeStats) {
        $report += ""
        $report += "=" * 80
        $report += "STATISTICS"
        $report += "=" * 80
        $report += ""

        $stats = Get-DiffStatistics -Source $Source -Target $Target
        if ($stats) {
            $report += $stats
        }
    }

    $report += ""
    $report += "=" * 80
    $report += "End of Report"
    $report += "=" * 80

    return $report
}

#############################################################################
# Main Script Execution
#############################################################################

# Validate git repository
if (-not (Test-GitRepository)) {
    Write-Error "ERROR: Not a git repository. Please run this script from within a git repository."
    exit 1
}

Write-Log "Git repository validated." | Out-Null

# Validate branches exist
Write-Log "Validating branches..." | Out-Null

if (-not (Get-BranchExists -BranchName $SourceBranch)) {
    Write-Error "ERROR: Source branch '$SourceBranch' not found in local repository."
    Write-Host "Available branches:"
    git branch -a | ForEach-Object { Write-Host "  $_" }
    exit 1
}

if (-not (Get-BranchExists -BranchName $TargetBranch)) {
    Write-Error "ERROR: Target branch '$TargetBranch' not found in local repository."
    Write-Host "Available branches:"
    git branch -a | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Log "Branches validated successfully." | Out-Null

# Generate output file path if not provided
if (-not $OutputFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = "./git-diffs-{0}_{1}_{2}.txt" -f $SourceBranch.Replace("/", "_"), $TargetBranch.Replace("/", "_"), $timestamp
}

Write-Log "Generating diff report..." | Out-Null

# Generate report
$report = Generate-DiffReport -Source $SourceBranch -Target $TargetBranch -Filter $FileFilter -DirFilter $DirectoryFilter -StatsOnly $false -ShowFilesOnly $FilesOnly

# Write to file
try {
    $report | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
    Write-Log "Diff report successfully written to: $OutputFile" | Out-Null
    Write-Host ""
    Write-Host "✓ SUCCESS: Diff report generated at: $OutputFile"
    Write-Host "  Branches: $SourceBranch -> $TargetBranch"
    Write-Host "  Total lines in report: $($report.Count)"
    Write-Host ""

    # Display summary to console
    if ($Verbose) {
        Write-Host "Preview (first 50 lines):"
        $report[0..49] | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Error "ERROR: Failed to write output file: $_"
    exit 1
}

exit 0

