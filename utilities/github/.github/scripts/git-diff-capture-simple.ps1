#############################################################################
# Git Diff Capture Script
# Purpose : Generate git diffs between two branches, LLM-parsable output
# Usage   : .\git-diff-capture-simple.ps1 -SourceBranch "b1" -TargetBranch "b2"
# PS Ver  : PowerShell 5.1+ compatible (ASCII-only comments)
#############################################################################

param(
    [Parameter(Mandatory=$true)]  [string]$SourceBranch,
    [Parameter(Mandatory=$true)]  [string]$TargetBranch,
    [Parameter(Mandatory=$false)] [string]$OutputFile,
    [Parameter(Mandatory=$false)] [string]$FileFilter,
    [Parameter(Mandatory=$false)] [string]$DirectoryFilter
)

#-----------------------------------------------------------------------------
# HELPERS
#-----------------------------------------------------------------------------

function Get-Separator {
    param([string]$Char = "-", [int]$Len = 80)
    return $Char * $Len
}

function Get-StatusLabel {
    param([string]$Status)
    switch ($Status) {
        "A"     { return "ADDED"    }
        "M"     { return "MODIFIED" }
        "D"     { return "DELETED"  }
        "R"     { return "RENAMED"  }
        "C"     { return "COPIED"   }
        default { return $Status    }
    }
}

function Get-DiffLineStats {
    param([string[]]$DiffLines)
    $added   = ($DiffLines | Where-Object { $_ -match '^\+[^+]' }).Count
    $deleted = ($DiffLines | Where-Object { $_ -match '^-[^-]'  }).Count
    return @{ Added = $added; Deleted = $deleted }
}

#-----------------------------------------------------------------------------
# VALIDATE GIT REPO AND CHANGE TO REPO ROOT
# Critical: all git diff commands must run from the repo root so that
# relative file paths (e.g. src/main/resources/foo.yaml) resolve correctly.
#-----------------------------------------------------------------------------

try {
    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($isGitRepo -ne "true") { Write-Error "Not a git repository"; exit 1 }
} catch {
    Write-Error "Not a git repository"
    exit 1
}

# Always cd to repo root so relative paths in git diff work correctly
$repoRootPath = git rev-parse --show-toplevel 2>$null
if (-not $repoRootPath) {
    Write-Error "Could not resolve git repo root."
    exit 1
}
Set-Location $repoRootPath
Write-Host "Working directory set to repo root: $repoRootPath"

#-----------------------------------------------------------------------------
# VALIDATE BRANCHES
#-----------------------------------------------------------------------------

$allBranches = git branch -a 2>$null

$sourceBranchExists = $allBranches | Where-Object { $_ -match [regex]::Escape($SourceBranch) }
if (-not $sourceBranchExists) {
    Write-Error "Source branch '$SourceBranch' not found."
    Write-Host "Available branches:"
    $allBranches | ForEach-Object { Write-Host "  $_" }
    exit 1
}

$targetBranchExists = $allBranches | Where-Object { $_ -match [regex]::Escape($TargetBranch) }
if (-not $targetBranchExists) {
    Write-Error "Target branch '$TargetBranch' not found."
    Write-Host "Available branches:"
    $allBranches | ForEach-Object { Write-Host "  $_" }
    exit 1
}

#-----------------------------------------------------------------------------
# OUTPUT FILENAME
#-----------------------------------------------------------------------------

if (-not $OutputFile) {
    $timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
    $source_safe = $SourceBranch.Replace("/", "_").Replace(" ", "_")
    $target_safe = $TargetBranch.Replace("/", "_").Replace(" ", "_")
    $OutputFile  = "git-diffs-${source_safe}-vs-${target_safe}-${timestamp}.txt"
}

#-----------------------------------------------------------------------------
# NORMALIZE DIRECTORY FILTER (relative OR absolute path)
#-----------------------------------------------------------------------------

$normalizedDir = ""
if ($DirectoryFilter) {
    $normalizedDir = $DirectoryFilter.Replace("\", "/").TrimEnd("/")
    # Strip repo root prefix if an absolute path was provided
    $normalizedRepoRoot = $repoRootPath.Replace("\", "/").TrimEnd("/")
    if ($normalizedDir.StartsWith($normalizedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $normalizedDir = $normalizedDir.Substring($normalizedRepoRoot.Length).TrimStart("/")
    }
    Write-Host "Directory filter: '$DirectoryFilter' -> normalized: '$normalizedDir'"
}

Write-Host "Generating diff report: $SourceBranch -> $TargetBranch"
Write-Host "Output: $OutputFile"
Write-Host ""

#-----------------------------------------------------------------------------
# FETCH CHANGED FILES
#-----------------------------------------------------------------------------

Write-Host "Fetching changed files..."
$changedFiles = git diff "$TargetBranch..$SourceBranch" --name-status 2>$null

if ($FileFilter) {
    $changedFiles = $changedFiles | Where-Object { $_ -match $FileFilter }
}
if ($normalizedDir) {
    $dirPattern   = [regex]::Escape($normalizedDir)
    $changedFiles = $changedFiles | Where-Object { $_ -match $dirPattern }
}

#-----------------------------------------------------------------------------
# PARSE FILE LIST
#-----------------------------------------------------------------------------

$fileList = @()
foreach ($file in $changedFiles) {
    if (-not $file) { continue }
    $parts  = $file -split '\s+', 2
    $status = $parts[0]
    $path   = $parts[1]
    $fileList += [PSCustomObject]@{
        Status = $status
        Label  = Get-StatusLabel $status
        Path   = $path
    }
}

#-----------------------------------------------------------------------------
# BUILD LLM-FRIENDLY REPORT
#-----------------------------------------------------------------------------

$report = [System.Collections.Generic.List[string]]::new()

# REPORT HEADER
$report.Add("########################################")
$report.Add("# SECTION: REPORT_HEADER")
$report.Add("########################################")
$report.Add("REPORT_TYPE      : GIT_DIFF_ANALYSIS")
$report.Add("GENERATED_AT     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$report.Add("SOURCE_BRANCH    : $SourceBranch")
$report.Add("TARGET_BRANCH    : $TargetBranch")
$report.Add("COMPARISON       : $TargetBranch..$SourceBranch  (changes in SOURCE not yet in TARGET)")
if ($FileFilter)    { $report.Add("FILE_FILTER      : $FileFilter") }
if ($normalizedDir) { $report.Add("DIR_FILTER_INPUT : $DirectoryFilter") }
if ($normalizedDir) { $report.Add("DIR_FILTER_NORM  : $normalizedDir") }
$report.Add("TOTAL_FILES      : $($fileList.Count)")
$report.Add("")

# FILE CHANGE SUMMARY
$report.Add("########################################")
$report.Add("# SECTION: FILE_CHANGE_SUMMARY")
$report.Add("########################################")

if ($fileList.Count -eq 0) {
    $report.Add("STATUS : NO_CHANGES_FOUND")
    $report.Add("INFO   : No files changed between '$SourceBranch' and '$TargetBranch'.")
} else {
    foreach ($f in $fileList) {
        $report.Add("FILE_CHANGE | STATUS=$($f.Label) | PATH=$($f.Path)")
    }
}
$report.Add("")

# DETAILED DIFFS
if ($fileList.Count -gt 0) {

    $report.Add("########################################")
    $report.Add("# SECTION: DETAILED_DIFFS")
    $report.Add("########################################")
    $report.Add("")

    $fileIndex = 0
    foreach ($f in $fileList) {
        $fileIndex++
        $diffLines = git diff "$TargetBranch..$SourceBranch" -- $f.Path 2>$null
        $stats     = Get-DiffLineStats -DiffLines $diffLines

        # Per-file header
        $report.Add($(Get-Separator "-" 80))
        $report.Add("## FILE_DIFF [$fileIndex / $($fileList.Count)]")
        $report.Add("   PATH   : $($f.Path)")
        $report.Add("   STATUS : $($f.Label)")
        $report.Add("   LINES  : +$($stats.Added) added  /  -$($stats.Deleted) deleted")
        $report.Add($(Get-Separator "-" 80))
        $report.Add("")

        if (-not $diffLines) {
            $report.Add("  (Binary file or no text differences)")
        } else {
            # Fenced diff block - LLM parses +/- lines directly
            $report.Add('```diff')
            foreach ($line in $diffLines) {
                if     ($line -match '^\+\+\+') { $report.Add("+++ NEW_FILE   : $($line.Substring(3).Trim())") }
                elseif ($line -match '^---')     { $report.Add("--- OLD_FILE   : $($line.Substring(3).Trim())") }
                elseif ($line -match '^@@')      { $report.Add("@@ HUNK       : $($line -replace '^@@\s*','' -replace '\s*@@.*','')") }
                elseif ($line -match '^\+')      { $report.Add("+ $($line.Substring(1))") }
                elseif ($line -match '^-')       { $report.Add("- $($line.Substring(1))") }
                else                             { $report.Add("  $line") }
            }
            $report.Add('```')
        }
        $report.Add("")
    }

    # STATISTICS
    $report.Add("########################################")
    $report.Add("# SECTION: STATISTICS")
    $report.Add("########################################")

    $totalAdded   = 0
    $totalDeleted = 0
    foreach ($f in $fileList) {
        $dl = git diff "$TargetBranch..$SourceBranch" -- $f.Path 2>$null
        $s  = Get-DiffLineStats -DiffLines $dl
        $totalAdded   += $s.Added
        $totalDeleted += $s.Deleted
        $report.Add("STAT | FILE=$($f.Path) | ADDED=$($s.Added) | DELETED=$($s.Deleted) | NET=$($s.Added - $s.Deleted)")
    }
    $report.Add("")
    $report.Add("TOTAL_LINES_ADDED   : $totalAdded")
    $report.Add("TOTAL_LINES_DELETED : $totalDeleted")
    $report.Add("NET_CHANGE          : $($totalAdded - $totalDeleted)")
    $report.Add("")

    # Raw git stat
    $report.Add($(Get-Separator "-" 80))
    $report.Add("GIT_STAT_RAW:")
    $gitStat = git diff "$TargetBranch..$SourceBranch" --stat 2>$null
    if ($gitStat) { foreach ($l in $gitStat) { $report.Add("  $l") } }
    $report.Add("")
}

# COMMIT LOG
$report.Add("########################################")
$report.Add("# SECTION: COMMIT_LOG")
$report.Add("# Commits in SOURCE_BRANCH not yet in TARGET_BRANCH")
$report.Add("########################################")

$commits = git log "$TargetBranch..$SourceBranch" --oneline 2>$null
if ($commits) {
    foreach ($c in $commits) {
        $report.Add("COMMIT | $c")
    }
} else {
    $report.Add("INFO: No unique commits found in source branch.")
}
$report.Add("")

# REPORT FOOTER
$report.Add("########################################")
$report.Add("# SECTION: REPORT_FOOTER")
$report.Add("########################################")
$report.Add("END_REPORT    : GIT_DIFF_ANALYSIS")
$report.Add("SOURCE_BRANCH : $SourceBranch")
$report.Add("TARGET_BRANCH : $TargetBranch")
$report.Add("TOTAL_FILES   : $($fileList.Count)")
$report.Add("GENERATED_AT  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$report.Add("########################################")

#-----------------------------------------------------------------------------
# WRITE TO FILE
#-----------------------------------------------------------------------------

try {
    $report | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
    Write-Host ""
    Write-Host "SUCCESS: Report written to: $OutputFile"
    Write-Host "  Total lines : $($report.Count)"
    Write-Host "  Files diff'd: $($fileList.Count)"
    Write-Host ""
    Write-Host "--- Preview (first 40 lines) ---"
    Write-Host ""
    $report | Select-Object -First 40 | ForEach-Object { Write-Host $_ }
} catch {
    Write-Error "Failed to write output file: $($_.Exception.Message)"
    exit 1
}

exit 0

