<#
.SYNOPSIS
Generate comprehensive git diff report for any local repository.

.DESCRIPTION
Analyzes a git repository and writes all diff content directly to a
timestamped log file under the 'logs' subfolder of the script directory,
avoiding large in-memory buffering for performance on big repositories.

Outputs produced:
  logs/git-diff-<yyyyMMdd_HHmmss>.log  -- Full diff content (streamed)
  diff-summary.txt                     -- Lightweight quick-reference summary

Content captured in the full log:
  - Repository information (branch, commit, remote)
  - File status counts
  - Uncommitted working directory changes
  - Staged changes (index)
  - Stashed changes (all stashes, full patch)
  - Branch comparison (optional)
  - Commit history

.PARAMETER RepoPath
Path to the git repository to analyze (required).

.PARAMETER LogsDir
Directory where timestamped log files are written.
Default: <script-dir>\logs

.PARAMETER IncludeHistory
Include commit history in the full log (default: true).

.PARAMETER HistoryDepth
Number of commits to include in history (default: 20).

.PARAMETER IncludeStashed
Include stashed changes in the full log (default: true).

.PARAMETER BranchCompare
Compare current branch with this branch (e.g., 'origin/develop').

.PARAMETER VerboseOutput
Print section headers to console while writing (default: false).

.EXAMPLE
.\Generate-GitDiff.ps1 -RepoPath "C:\path\to\repo"

.EXAMPLE
.\Generate-GitDiff.ps1 -RepoPath "C:\path\to\repo" -BranchCompare "origin/develop" -VerboseOutput

.EXAMPLE
.\Generate-GitDiff.ps1 -RepoPath "C:\path\to\repo" -HistoryDepth 50 -LogsDir "C:\reports\logs"

.NOTES
Author:  Mastercard PGS Connectivity
Version: 2.0.0
Updated: 2026-04-13
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to git repository")]
    [ValidateScript({ Test-Path $_ })]
    [string]$RepoPath,

    [string]$LogsDir    = $null,
    [switch]$IncludeHistory  = $true,
    [int]$HistoryDepth       = 20,
    [switch]$IncludeStashed  = $true,
    [string]$BranchCompare   = $null,
    [switch]$VerboseOutput   = $false
)

# ---------------------------------------------------------------------------
# Guard: must be a git repository
# ---------------------------------------------------------------------------
if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    Write-Error "Not a git repository: $RepoPath"
    exit 1
}

# ---------------------------------------------------------------------------
# Resolve output paths
# ---------------------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([string]::IsNullOrEmpty($LogsDir)) {
    $LogsDir = Join-Path $scriptDir "logs"
}

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

$timestamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile       = Join-Path $LogsDir "git-diff-$timestamp.log"
$summaryFile   = Join-Path $scriptDir "diff-summary-$timestamp.txt"

# ---------------------------------------------------------------------------
# Helper: run a git command and return output lines
# ---------------------------------------------------------------------------
function Invoke-Git {
    param(
        [string[]]$Arguments,
        [bool]$ThrowOnError = $false
    )
    try {
        $result = & git -C $RepoPath @Arguments 2>&1
        return $result
    }
    catch {
        if ($ThrowOnError) { throw $_ }
        return $null
    }
}

# ---------------------------------------------------------------------------
# Helper: write a line to the log file (StreamWriter for performance)
# ---------------------------------------------------------------------------
$writer = [System.IO.StreamWriter]::new($logFile, $false, [System.Text.Encoding]::UTF8)

function Write-Log {
    param([string]$Text)
    $writer.WriteLine($Text)
    if ($VerboseOutput) { Write-Host $Text }
}

function Write-LogSection {
    param([string]$Title)
    $writer.WriteLine("")
    $writer.WriteLine("=" * 80)
    $writer.WriteLine($Title)
    $writer.WriteLine("=" * 80)
    $writer.WriteLine("")
    if ($VerboseOutput) { Write-Host "  >> $Title" -ForegroundColor Cyan }
}

function Write-LogLines {
    param($Lines)
    if ($null -eq $Lines) { return }
    foreach ($line in @($Lines)) {
        $writer.WriteLine($line)
    }
}

# ---------------------------------------------------------------------------
# Start logging
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Analyzing repository: $RepoPath" -ForegroundColor Cyan
Write-Host "Full log  : $logFile"   -ForegroundColor DarkCyan
Write-Host "Summary   : $summaryFile" -ForegroundColor DarkCyan
Write-Host ""

Write-Log ("=" * 80)
Write-Log "GIT REPOSITORY DIFF REPORT"
Write-Log ("=" * 80)
Write-Log "Generated  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "Repository : $RepoPath"
Write-Log ("=" * 80)

# ---------------------------------------------------------------------------
# Repository metadata
# ---------------------------------------------------------------------------
$currentBranch = Invoke-Git @("rev-parse", "--abbrev-ref", "HEAD")
$currentCommit = Invoke-Git @("rev-parse", "HEAD")
$remoteUrl     = Invoke-Git @("config", "--get", "remote.origin.url")

Write-LogSection "REPOSITORY INFORMATION"
Write-Log "  Branch  : $currentBranch"
Write-Log "  Commit  : $currentCommit"
Write-Log "  Remote  : $remoteUrl"

# ---------------------------------------------------------------------------
# Status counts (porcelain — fast, no diff content)
# ---------------------------------------------------------------------------
$status      = Invoke-Git @("status", "--porcelain")
$untracked   = @($status | Where-Object { $_ -match "^\?\?" }).Count
$modified    = @($status | Where-Object { $_ -match "^ M|^M " }).Count
$deleted     = @($status | Where-Object { $_ -match "^ D|^D " }).Count
$renamed     = @($status | Where-Object { $_ -match "^R " }).Count
$added       = @($status | Where-Object { $_ -match "^A " }).Count
$totalDirty  = $untracked + $modified + $deleted + $renamed + $added

Write-LogSection "FILE STATUS COUNTS"
Write-Log "  Untracked : $untracked"
Write-Log "  Modified  : $modified"
Write-Log "  Deleted   : $deleted"
Write-Log "  Renamed   : $renamed"
Write-Log "  Added     : $added"
Write-Log "  Total     : $totalDirty"

# ---------------------------------------------------------------------------
# File status details (porcelain listing — no patch)
# ---------------------------------------------------------------------------
Write-LogSection "FILE STATUS DETAILS"

if ($untracked -gt 0) {
    Write-Log "Untracked Files:"
    $status | Where-Object { $_ -match "^\?\?" } | ForEach-Object { Write-Log "  $_" }
    Write-Log ""
}
if ($modified -gt 0) {
    Write-Log "Modified Files:"
    $status | Where-Object { $_ -match "^ M|^M " } | ForEach-Object { Write-Log "  $_" }
    Write-Log ""
}
if ($deleted -gt 0) {
    Write-Log "Deleted Files:"
    $status | Where-Object { $_ -match "^ D|^D " } | ForEach-Object { Write-Log "  $_" }
    Write-Log ""
}
if ($renamed -gt 0) {
    Write-Log "Renamed Files:"
    $status | Where-Object { $_ -match "^R " } | ForEach-Object { Write-Log "  $_" }
    Write-Log ""
}
if ($added -gt 0) {
    Write-Log "Added Files:"
    $status | Where-Object { $_ -match "^A " } | ForEach-Object { Write-Log "  $_" }
    Write-Log ""
}

# ---------------------------------------------------------------------------
# Working directory changes — streamed directly to log
# ---------------------------------------------------------------------------
Write-LogSection "WORKING DIRECTORY CHANGES (Uncommitted)"
Write-Host "  Writing working directory diff..." -ForegroundColor Yellow

$diffWD = Invoke-Git @("diff", "--no-color")
if ($null -eq $diffWD -or @($diffWD).Count -eq 0) {
    Write-Log "No uncommitted changes in working directory."
} else {
    Write-LogLines $diffWD
}

# ---------------------------------------------------------------------------
# Staged changes — streamed directly to log
# ---------------------------------------------------------------------------
Write-LogSection "STAGED CHANGES (Index)"
Write-Host "  Writing staged diff..." -ForegroundColor Yellow

$diffStaged = Invoke-Git @("diff", "--cached", "--no-color")
if ($null -eq $diffStaged -or @($diffStaged).Count -eq 0) {
    Write-Log "No staged changes."
} else {
    Write-LogLines $diffStaged
}

# ---------------------------------------------------------------------------
# Stashed changes — streamed directly to log
# ---------------------------------------------------------------------------
if ($IncludeStashed) {
    Write-LogSection "STASHED CHANGES"
    Write-Host "  Writing stash diffs..." -ForegroundColor Yellow

    $stashList = Invoke-Git @("stash", "list")
    if ($null -eq $stashList -or @($stashList).Count -eq 0) {
        Write-Log "No stashed changes."
    } else {
        Write-Log "Stash List:"
        Write-LogLines $stashList
        Write-Log ""

        $stashLines = @($stashList)
        for ($i = 0; $i -lt $stashLines.Count; $i++) {
            if ($stashLines[$i]) {
                Write-Log ("-" * 60)
                Write-Log "Stash[$i]: $($stashLines[$i])"
                Write-Log ("-" * 60)
                # stat first for quick overview
                $stashStat = Invoke-Git @("stash", "show", "--stat", "--no-color", "stash@{$i}")
                Write-LogLines $stashStat
                Write-Log ""
                # full patch
                Write-Log "Full patch:"
                $stashPatch = Invoke-Git @("stash", "show", "-p", "--no-color", "stash@{$i}")
                Write-LogLines $stashPatch
                Write-Log ""
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Branch comparison (optional)
# ---------------------------------------------------------------------------
if (-not [string]::IsNullOrEmpty($BranchCompare)) {
    Write-LogSection "BRANCH COMPARISON: $currentBranch vs $BranchCompare"
    Write-Host "  Writing branch diff..." -ForegroundColor Yellow

    $aheadCount  = Invoke-Git @("rev-list", "--count", "$BranchCompare..$currentBranch")
    $behindCount = Invoke-Git @("rev-list", "--count", "$currentBranch..$BranchCompare")

    Write-Log "Commits ahead  of $BranchCompare : $aheadCount"
    Write-Log "Commits behind $BranchCompare : $behindCount"
    Write-Log ""

    if ([int]$aheadCount -gt 0) {
        Write-Log "Commits ahead:"
        Write-LogLines (Invoke-Git @("log", "$BranchCompare..$currentBranch", "--oneline"))
        Write-Log ""
    }

    Write-Log "Diff ($currentBranch vs $BranchCompare):"
    Write-Log ""
    Write-LogLines (Invoke-Git @("diff", $BranchCompare, "--no-color"))
}

# ---------------------------------------------------------------------------
# Commit history
# ---------------------------------------------------------------------------
if ($IncludeHistory) {
    Write-LogSection "COMMIT HISTORY (Last $HistoryDepth commits)"
    Write-Host "  Writing commit history..." -ForegroundColor Yellow

    Write-LogLines (Invoke-Git @("log", "-n", $HistoryDepth,
        "--oneline", "--graph", "--decorate", "--all"))
    Write-Log ""

    Write-Log "Detailed Commit Information:"
    Write-Log ""
    $logDetail = Invoke-Git @("log", "-n", $HistoryDepth,
        "--pretty=format:%H|%an|%ai|%s")
    foreach ($line in @($logDetail)) {
        if ($line) {
            $parts = $line -split "\|"
            if ($parts.Count -eq 4) {
                Write-Log "Commit  : $($parts[0].Substring(0, 7))"
                Write-Log "  Author  : $($parts[1])"
                Write-Log "  Date    : $($parts[2])"
                Write-Log "  Message : $($parts[3])"
                Write-Log ""
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Footer
# ---------------------------------------------------------------------------
$totalFiles = @(Invoke-Git @("ls-files", "--full-name")).Count

Write-LogSection "SUMMARY STATISTICS"
Write-Log "Total tracked files : $totalFiles"
Write-Log "Uncommitted changes : $totalDirty"
Write-Log "Report generated    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log ""
Write-Log ("=" * 80)
Write-Log "END OF REPORT"
Write-Log ("=" * 80)

# Flush and close the stream writer
$writer.Flush()
$writer.Close()

# ---------------------------------------------------------------------------
# Write lightweight diff-summary.txt
# ---------------------------------------------------------------------------
$stashListFresh = Invoke-Git @("stash", "list")
$stashCount     = if ($null -eq $stashListFresh) { 0 } else { @($stashListFresh).Count }

$summaryLines = @(
    "================================================================================"
    "GIT DIFF SUMMARY  --  Quick Reference"
    "================================================================================"
    "Generated   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Repository  : $RepoPath"
    "Branch      : $currentBranch"
    "Commit      : $currentCommit"
    "Remote      : $remoteUrl"
    ""
    "FILE STATUS:"
    "  Untracked : $untracked"
    "  Modified  : $modified"
    "  Deleted   : $deleted"
    "  Renamed   : $renamed"
    "  Added     : $added"
    "  Total     : $totalDirty"
    ""
    "STASHES ($stashCount found):"
)

if ($stashCount -gt 0) {
    foreach ($s in @($stashListFresh)) {
        $summaryLines += "  $s"
    }
} else {
    $summaryLines += "  (none)"
}

$summaryLines += ""
$summaryLines += "FULL LOG:"
$summaryLines += "  $logFile"
$summaryLines += ""
$summaryLines += "  To inspect the full patch open the log file above."
$summaryLines += "  To apply a stash: git -C <repo> stash apply stash@{N}"
$summaryLines += ""
$summaryLines += "================================================================================"
$summaryLines += "END OF SUMMARY"
$summaryLines += "================================================================================"

$summaryLines | Out-File -FilePath $summaryFile -Encoding UTF8 -Force

# ---------------------------------------------------------------------------
# Console completion banner
# ---------------------------------------------------------------------------
$logSize = [math]::Round((Get-Item $logFile).Length / 1KB, 1)

Write-Host ""
Write-Host "[OK] Done!" -ForegroundColor Green
Write-Host ("  Full log  : {0}  ({1} KB)" -f $logFile, $logSize) -ForegroundColor Green
Write-Host ("  Summary   : {0}" -f $summaryFile) -ForegroundColor Green
Write-Host ""
