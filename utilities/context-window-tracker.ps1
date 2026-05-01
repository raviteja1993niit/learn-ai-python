#!/usr/bin/env pwsh
# ============================================================
# context-window-tracker.ps1
# Estimates token usage for files you plan to attach to an
# AI session (Claude / Copilot / GPT etc.)
#
# Rules of thumb (conservative estimates):
#   English prose   : 1 token ≈ 4 chars
#   Code / JSON     : 1 token ≈ 3.5 chars  (more punctuation/symbols)
#   Markdown        : 1 token ≈ 4 chars
#
# Usage:
#   .\context-window-tracker.ps1                         # scan current dir
#   .\context-window-tracker.ps1 -Path "C:\my\project"  # scan a folder
#   .\context-window-tracker.ps1 -Files "a.java","b.md"  # specific files
#   .\context-window-tracker.ps1 -Limit 200000           # set model limit
# ============================================================

param(
    [string]   $Path  = $PWD,
    [string[]] $Files = @(),
    [long]     $Limit = 200000,          # Claude 3.5 Sonnet / Opus context window
    [string[]] $Include = @("*.java","*.md","*.ps1","*.json","*.yaml","*.yml","*.xml","*.txt"),
    [switch]   $Verbose
)

# ── helpers ──────────────────────────────────────────────────
function Get-TokenEstimate {
    param([string]$FilePath)
    $ext  = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $text = Get-Content -Raw -Path $FilePath -ErrorAction SilentlyContinue
    if (-not $text) { return 0 }

    $charCount = $text.Length
    $charsPerToken = switch ($ext) {
        { $_ -in '.java','.ps1','.js','.ts','.py','.cs','.json' } { 3.5 }
        { $_ -in '.xml','.yaml','.yml' }                          { 3.8 }
        default                                                    { 4.0 }
    }
    return [math]::Ceiling($charCount / $charsPerToken)
}

function Format-Tokens { param([long]$n) "$("{0:N0}" -f $n)" }
function Format-Pct    { param([long]$n, [long]$limit) "$([math]::Round($n * 100.0 / $limit, 1))%" }

function Get-Bar {
    param([long]$used, [long]$limit, [int]$width = 40)
    $filled = [math]::Round($used * $width / $limit)
    $filled = [math]::Min($filled, $width)
    $bar    = '#' * $filled + '-' * ($width - $filled)
    $color  = if ($filled -ge $width * 0.9) { 'Red' }
              elseif ($filled -ge $width * 0.7) { 'Yellow' }
              else { 'Green' }
    return [PSCustomObject]@{ Bar = "[$bar]"; Color = $color }
}

# ── collect files ─────────────────────────────────────────────
$targetFiles = if ($Files.Count -gt 0) {
    $Files | Where-Object { Test-Path $_ } | ForEach-Object { Get-Item $_ }
} else {
    $Include | ForEach-Object { Get-ChildItem -Path $Path -Filter $_ -Recurse -ErrorAction SilentlyContinue }
}

if (-not $targetFiles) {
    Write-Host "No matching files found." -ForegroundColor Yellow
    exit 0
}

# ── analyse ───────────────────────────────────────────────────
$rows      = @()
$totalToks = 0

foreach ($f in $targetFiles) {
    $toks     = Get-TokenEstimate -FilePath $f.FullName
    $totalToks += $toks
    $rows += [PSCustomObject]@{
        File   = $f.FullName -replace [regex]::Escape($Path), '.'
        Chars  = (Get-Content -Raw $f.FullName -ErrorAction SilentlyContinue).Length
        Tokens = $toks
        Pct    = Format-Pct -n $toks -limit $Limit
    }
}

$rows = $rows | Sort-Object Tokens -Descending

# ── display ───────────────────────────────────────────────────
Write-Host ""
Write-Host "  Context Window Tracker" -ForegroundColor Cyan
Write-Host "  Model limit : $(Format-Tokens $Limit) tokens" -ForegroundColor Gray
Write-Host "  Scanned     : $($rows.Count) files" -ForegroundColor Gray
Write-Host ""

if ($Verbose) {
    $rows | Format-Table -AutoSize -Property @(
        @{Label="Tokens"; Expression={Format-Tokens $_.Tokens}; Align="Right"},
        @{Label="% of Limit"; Expression={$_.Pct}; Align="Right"},
        @{Label="File"; Expression={$_.File}}
    )
}

# ── summary bar ───────────────────────────────────────────────
$bar   = Get-Bar -used $totalToks -limit $Limit
$pct   = Format-Pct -n $totalToks -limit $Limit
$remaining = $Limit - $totalToks

Write-Host "  Total estimated tokens : $(Format-Tokens $totalToks)  ($pct of limit)" -ForegroundColor White
Write-Host "  Remaining              : $(Format-Tokens $remaining)" -ForegroundColor $(if ($remaining -lt 20000) {'Red'} elseif ($remaining -lt 60000) {'Yellow'} else {'Green'})
Write-Host ""
Write-Host -NoNewline "  Usage  "
Write-Host $bar.Bar -ForegroundColor $bar.Color
Write-Host ""

# ── risk rating ───────────────────────────────────────────────
$usedPct = $totalToks * 100.0 / $Limit
$rating  = switch ($usedPct) {
    { $_ -lt 30 }  { "🟢 LOW    — plenty of room" }
    { $_ -lt 60 }  { "🟡 MEDIUM — comfortable but plan ahead" }
    { $_ -lt 80 }  { "🟠 HIGH   — consider splitting the session" }
    { $_ -lt 95 }  { "🔴 CRITICAL — near limit, start new session soon" }
    default         { "💀 OVER LIMIT — context will be truncated" }
}
Write-Host "  Risk   : $rating" -ForegroundColor White
Write-Host ""

# ── top 5 heaviest files ──────────────────────────────────────
Write-Host "  Top 5 heaviest files:" -ForegroundColor Cyan
$rows | Select-Object -First 5 | ForEach-Object {
    Write-Host ("    {0,8} tokens  ({1,6})  {2}" -f (Format-Tokens $_.Tokens), $_.Pct, $_.File) -ForegroundColor Gray
}
Write-Host ""

# ── export CSV (optional) ─────────────────────────────────────
$csvPath = Join-Path $Path "context-token-report.csv"
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "  Report saved: $csvPath" -ForegroundColor DarkGray
Write-Host ""

