# =============================================================================
# Clean-M2Repository.ps1
# -----------------------------------------------------------------------------
# Purpose : Remove older artifact version folders from a local Maven .m2
#           repository, retaining only the single highest-versioned folder
#           under each artifactId directory.
#
# Usage   :
#   .\Clean-M2Repository.ps1                          # dry-run (safe preview)
#   .\Clean-M2Repository.ps1 -DryRun                  # explicit dry-run
#   .\Clean-M2Repository.ps1 -Force                   # live run, no prompt
#   .\Clean-M2Repository.ps1 -KeepSnapshots           # also keep latest SNAPSHOT
#   .\Clean-M2Repository.ps1 -M2RepoPath "D:\repo"    # custom repo path
#   .\Clean-M2Repository.ps1 -LogFile "C:\logs\m2.log"
#
# Parameters:
#   -M2RepoPath      Path to the local Maven repository.
#                    Default: $env:USERPROFILE\.m2\repository
#   -DryRun          Preview deletions WITHOUT removing anything.
#                    STRONGLY recommended for the first run.
#   -Force           Skip the interactive confirmation prompt.
#   -KeepSnapshots   Also retain the latest SNAPSHOT version alongside
#                    the latest release version when both exist.
#   -LogFile         Path to write the operation log.
#                    Default: <script dir>\m2-cleanup-<timestamp>.log
#
# Safety notes:
#   * Always run with -DryRun first; review the log before a live run.
#   * Artifact folders containing only ONE version directory are never touched.
#   * Version comparison is SEMANTIC: 1.10.0 > 1.9.0 (not lexicographic).
#   * SNAPSHOT < release of the same numeric base (2.1.0 > 2.1.0-SNAPSHOT).
#   * Non-parseable version strings fall back to lexicographic ordering.
# =============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $M2RepoPath    = "$env:USERPROFILE\.m2\repository",
    [switch] $DryRun,
    [switch] $Force,
    [switch] $KeepSnapshots,
    [string] $LogFile       = ""
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($LogFile -eq "") {
    $LogFile = Join-Path $PSScriptRoot `
        ("m2-cleanup-" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".log")
}
# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Level, [string]$Message)
    $ts   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    switch ($Level) {
        'INFO'  { Write-Host $line -ForegroundColor Cyan    }
        'WARN'  { Write-Host $line -ForegroundColor Yellow  }
        'ERROR' { Write-Host $line -ForegroundColor Red     }
        'DRY'   { Write-Host $line -ForegroundColor Magenta }
        'DEL'   { Write-Host $line -ForegroundColor Red     }
        'KEEP'  { Write-Host $line -ForegroundColor Green   }
        default { Write-Host $line                          }
    }
    Add-Content -Path $LogFile -Value $line
}
# ---------------------------------------------------------------------------
# Returns $true when the directory name looks like a Maven version folder.
# Patterns accepted: 1.0.0 | 2.3.1-SNAPSHOT | 5e0db14-SNAPSHOT | 21.0
# ---------------------------------------------------------------------------
function Test-IsVersionDirectory {
    param([System.IO.DirectoryInfo] $Dir)
    return ($Dir.Name -match '^\d') -or ($Dir.Name -match '^[0-9a-f]{7,}-')
}
# ---------------------------------------------------------------------------
# Convert a Maven version string into a structured comparison object.
# ---------------------------------------------------------------------------
function ConvertTo-VersionInfo {
    param([string] $VersionString)
    $isSnapshot  = $VersionString -match '-SNAPSHOT$'
    $base        = $VersionString -replace '-SNAPSHOT$', ''
    $qualifier   = ''
    $numericPart = $base
    if ($base -match '^(\d[\d.]*)[\.\-]([A-Za-z].*)$') {
        $numericPart = $Matches[1]
        $qualifier   = $Matches[2]
    }
    $numeric = $null
    try   { $numeric = [System.Version]::Parse($numericPart) }
    catch { $numeric = $null }
    return [PSCustomObject]@{
        Original    = $VersionString
        IsSnapshot  = $isSnapshot
        Numeric     = $numeric
        NumericPart = $numericPart
        Qualifier   = $qualifier
    }
}
# ---------------------------------------------------------------------------
# Semantic version comparator.
# Returns: >0 when $a is newer, <0 when $a is older, 0 when equal.
# ---------------------------------------------------------------------------
function Compare-VersionInfo {
    param([PSCustomObject] $VersionA, [PSCustomObject] $VersionB)
    if (($null -ne $VersionA.Numeric) -and ($null -ne $VersionB.Numeric)) {
        $cmp = $VersionA.Numeric.CompareTo($VersionB.Numeric)
        if ($cmp -ne 0) { return $cmp }
        $aHasQ = ($VersionA.Qualifier -ne '')
        $bHasQ = ($VersionB.Qualifier -ne '')
        if ((-not $aHasQ) -and $bHasQ)  { return  1 }
        if ($aHasQ -and (-not $bHasQ))  { return -1 }
        if ($VersionA.Qualifier -ne $VersionB.Qualifier) {
            return [string]::Compare($VersionA.Qualifier, $VersionB.Qualifier,
                [System.StringComparison]::OrdinalIgnoreCase)
        }
        if ((-not $VersionA.IsSnapshot) -and $VersionB.IsSnapshot) { return  1 }
        if ($VersionA.IsSnapshot -and (-not $VersionB.IsSnapshot))  { return -1 }
        return 0
    }
    return [string]::Compare($VersionA.Original, $VersionB.Original,
        [System.StringComparison]::OrdinalIgnoreCase)
}
# ---------------------------------------------------------------------------
# Given a list of version strings, return the subset to keep.
# Policy:
#   - Always keep the single latest release version.
#   - Also keep the single latest SNAPSHOT when -KeepSnapshots is set,
#     or when no release version exists at all.
# ---------------------------------------------------------------------------
function Get-VersionsToKeep {
    param([string[]] $Versions, [bool] $RetainSnapshots)
    $infos     = @($Versions | ForEach-Object { ConvertTo-VersionInfo $_ })
    $releases  = @($infos | Where-Object { -not $_.IsSnapshot })
    $snapshots = @($infos | Where-Object {       $_.IsSnapshot })
    $toKeep    = [System.Collections.Generic.List[string]]::new()
    $latestRelease = $null
    foreach ($v in $releases) {
        if ($null -eq $latestRelease) { $latestRelease = $v }
        elseif ((Compare-VersionInfo $v $latestRelease) -gt 0) { $latestRelease = $v }
    }
    if ($null -ne $latestRelease) { $toKeep.Add($latestRelease.Original) }
    $latestSnapshot = $null
    foreach ($v in $snapshots) {
        if ($null -eq $latestSnapshot) { $latestSnapshot = $v }
        elseif ((Compare-VersionInfo $v $latestSnapshot) -gt 0) { $latestSnapshot = $v }
    }
    if ($null -ne $latestSnapshot) {
        if (($null -eq $latestRelease) -or $RetainSnapshots) {
            $toKeep.Add($latestSnapshot.Original)
        }
    }
    return $toKeep.ToArray()
}
# ---------------------------------------------------------------------------
# Human-readable byte formatter
# ---------------------------------------------------------------------------
function Format-Bytes {
    param([long] $Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}
# ---------------------------------------------------------------------------
# Core cleanup: walk the tree, identify artifact dirs, prune old versions.
# ---------------------------------------------------------------------------
function Invoke-M2Cleanup {
    param([string] $RepoPath)
    Write-Log 'INFO' "Scanning repository: $RepoPath"
    $artifactDirsProcessed = 0
    $versionsScheduled     = 0
    $spaceBytes            = [long] 0
    $errorCount            = 0
    $allDirs   = Get-ChildItem -Path $RepoPath -Directory -Recurse -ErrorAction SilentlyContinue
    $parentMap = @{}
    foreach ($dir in $allDirs) {
        $key = $dir.Parent.FullName
        if (-not $parentMap.ContainsKey($key)) {
            $parentMap[$key] = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
        }
        $parentMap[$key].Add($dir)
    }
    foreach ($artifactPath in $parentMap.Keys) {
        $children       = $parentMap[$artifactPath]
        $versionDirs    = @($children | Where-Object { Test-IsVersionDirectory $_ })
        if ($versionDirs.Count -lt 2) { continue }
        # If ANY sibling is NOT a version-like directory the parent is a
        # group/package dir, not an artifactId dir -- skip it for safety.
        $nonVersionDirs = @($children | Where-Object { -not (Test-IsVersionDirectory $_) })
        if ($nonVersionDirs.Count -gt 0) { continue }
        $artifactDirsProcessed++
        $versionNames   = $versionDirs | Select-Object -ExpandProperty Name
        $versionsToKeep = Get-VersionsToKeep -Versions $versionNames `
            -RetainSnapshots $KeepSnapshots.IsPresent
        Write-Log 'INFO' "--- Artifact : $artifactPath"
        Write-Log 'INFO' "    Versions  : $($versionNames -join ', ')"
        Write-Log 'INFO' "    Keeping   : $($versionsToKeep -join ', ')"
        foreach ($vDir in $versionDirs) {
            if ($versionsToKeep -contains $vDir.Name) {
                Write-Log 'KEEP' "  KEEP   $($vDir.FullName)"
                continue
            }
            try {
                $sum      = (Get-ChildItem -Path $vDir.FullName -Recurse -File `
                    -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $dirBytes = [long] $(if ($null -ne $sum) { $sum } else { 0 })
                if ($DryRun) {
                    Write-Log 'DRY' "  DRY-RUN  would delete: $($vDir.FullName)  ($(Format-Bytes $dirBytes))"
                } else {
                    Write-Log 'DEL' "  DELETE   $($vDir.FullName)  ($(Format-Bytes $dirBytes))"
                    Remove-Item -Path $vDir.FullName -Recurse -Force
                }
                $versionsScheduled++
                $spaceBytes += $dirBytes
            } catch {
                $errorCount++
                Write-Log 'ERROR' "  Failed to process $($vDir.FullName): $_"
            }
        }
    }
    return [PSCustomObject]@{
        ArtifactDirsProcessed = $artifactDirsProcessed
        VersionsScheduled     = $versionsScheduled
        SpaceBytes            = $spaceBytes
        Errors                = $errorCount
    }
}
# ===========================================================================
# Entry point
# ===========================================================================
$logDir = Split-Path $LogFile -Parent
if (($logDir -ne '') -and (-not (Test-Path $logDir))) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$modeLabel = if ($DryRun.IsPresent) { "DRY-RUN  (no files will be deleted)" } `
             else                   { "LIVE     (files WILL be deleted)"    }
Write-Log 'INFO' '============================================================'
Write-Log 'INFO' '  Maven .m2 Repository Cleanup Script'
Write-Log 'INFO' "  Date          : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log 'INFO' "  Repo path     : $M2RepoPath"
Write-Log 'INFO' "  Mode          : $modeLabel"
Write-Log 'INFO' "  KeepSnapshots : $($KeepSnapshots.IsPresent)"
Write-Log 'INFO' "  Log file      : $LogFile"
Write-Log 'INFO' '============================================================'
if (-not (Test-Path $M2RepoPath -PathType Container)) {
    Write-Log 'ERROR' "Repository path not found: $M2RepoPath"
    exit 1
}
if ((-not $DryRun.IsPresent) -and (-not $Force.IsPresent)) {
    Write-Host ''
    Write-Host '  !! WARNING: LIVE MODE SELECTED !!' -ForegroundColor Red
    Write-Host "  Repository : $M2RepoPath" -ForegroundColor Yellow
    Write-Host '  Older version folders will be PERMANENTLY DELETED.' -ForegroundColor Yellow
    Write-Host '  Tip: re-run with -DryRun to preview before committing.' -ForegroundColor Yellow
    Write-Host ''
    $answer = Read-Host "  Type 'YES' (uppercase) to continue"
    if ($answer -ne 'YES') {
        Write-Log 'WARN' 'Operation cancelled by user.'
        exit 0
    }
    Write-Host ''
}
$result = Invoke-M2Cleanup -RepoPath $M2RepoPath
$actionWord = if ($DryRun.IsPresent) { 'Would remove' } else { 'Removed     ' }
$spaceWord  = if ($DryRun.IsPresent) { 'Reclaimable ' } else { 'Freed       ' }
Write-Log 'INFO' '============================================================'
Write-Log 'INFO' '  SUMMARY'
Write-Log 'INFO' "  Artifact dirs scanned    : $($result.ArtifactDirsProcessed)"
Write-Log 'INFO' "  Version folders $actionWord : $($result.VersionsScheduled)"
Write-Log 'INFO' "  Space $spaceWord         : $(Format-Bytes $result.SpaceBytes)"
if ($result.Errors -gt 0) {
    Write-Log 'WARN' "  Errors encountered       : $($result.Errors)"
}
Write-Log 'INFO' '============================================================'
Write-Log 'INFO' "Full log written to: $LogFile"
if ($DryRun.IsPresent) {
    Write-Host ''
    Write-Host '  DRY-RUN complete -- no files were modified.' -ForegroundColor Magenta
    Write-Host '  Review the log, then re-run without -DryRun to apply changes.'
    Write-Host ''
}
if ($result.Errors -gt 0) { exit 1 } else { exit 0 }
