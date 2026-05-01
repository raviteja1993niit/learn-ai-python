# Compare-ISO8583-PerTransaction.ps1
# Per-transaction ISO 8583 field comparison between Target and Modernization environments
# Source: logs\target-modernization-logs.txt

param(
    [string]$LogFile  = "$PSScriptRoot\..\logs\target-modernization-logs.txt",
    [string]$HtmlOut  = "$PSScriptRoot\..\reports\ISO8583-Comparison-Report.html",
    [string]$CsvOut   = "$PSScriptRoot\..\reports\ISO8583-Comparison-Report.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── Helpers ─────────────────────────────────────────────────────────────────

function Parse-ISO8583Line {
    <#
    .SYNOPSIS
    Converts one ISO8583 log line into an ordered dictionary of flat field paths → values.
    e.g.  "022(posDataCode).1(inputCapability)" => "1"
          "063(reservedPrivateDataIII).04(moto)"  => "5"
    #>
    param([string]$Line)

    $fields = [ordered]@{}

    # Extract MTI from Header block  [1 (messageTypeId) = 'VALUE']
    if ($Line -match "Header\s*=\s*\[1\s*\(messageTypeId\)\s*=\s*'([^']+)'") {
        $fields["Header.1(messageTypeId)"] = $Matches[1]
    }

    # Strip everything up to "Fields = [" then grab the remaining content
    if ($Line -notmatch "Fields\s*=\s*\[(.+)\]\s*$") { return $fields }
    $body = $Matches[1]

    # Parse the top-level comma-separated tokens.
    # Challenge: values can themselves be nested [...] blocks.
    # Strategy: walk character-by-character tracking bracket depth.
    $tokens = Split-ISO8583Tokens $body

    foreach ($tok in $tokens) {
        # Each token looks like:   NNN (name) = 'value'
        #                    or:   NNN (name) = [sub1 (n) = 'v', ...]
        if ($tok -match "^(\w+)\s*\(([^)]+)\)\s*=\s*(.+)$") {
            $code  = $Matches[1].Trim()
            $name  = $Matches[2].Trim()
            $value = $Matches[3].Trim()
            $key   = "$code($name)"

            if ($value -match "^\[(.+)\]$") {
                # Nested sub-fields
                $subBody   = $Matches[1]
                $subTokens = Split-ISO8583Tokens $subBody
                foreach ($st in $subTokens) {
                    if ($st -match "^(\w+)\s*\(([^)]+)\)\s*=\s*'([^']*)'") {
                        $sc = $Matches[1].Trim()
                        $sn = $Matches[2].Trim()
                        $sv = $Matches[3]
                        $fields["$key.$sc($sn)"] = $sv
                    }
                }
            } elseif ($value -match "^'([^']*)'$") {
                $fields[$key] = $Matches[1]
            } else {
                $fields[$key] = $value
            }
        }
    }
    return $fields
}

function Split-ISO8583Tokens {
    <#
    .SYNOPSIS
    Splits a comma-delimited ISO8583 field list respecting nested [ ] brackets.
    #>
    param([string]$Text)
    $tokens = @()
    $depth  = 0
    $start  = 0
    for ($i = 0; $i -lt $Text.Length; $i++) {
        switch ($Text[$i]) {
            '[' { $depth++ }
            ']' { $depth-- }
            ',' {
                if ($depth -eq 0) {
                    $tokens += $Text.Substring($start, $i - $start).Trim()
                    $start = $i + 1
                }
            }
        }
    }
    $tail = $Text.Substring($start).Trim()
    if ($tail) { $tokens += $tail }
    return $tokens
}

function Get-TransactionSections {
    <#
    .SYNOPSIS
    Splits an environment block into a hashtable keyed by normalised transaction type.
    Handles "Verify"/"Verification", "Authorization", "Void Authorization".
    #>
    param([string]$Content)

    # Ordered so longer headings are checked first (avoids "Authorization" matching inside "Void Authorization")
    $headings = [ordered]@{
        "VOID_AUTHORIZATION" = "Void Authorization"
        "AUTHORIZATION"      = "Authorization"
        "VERIFICATION"       = @("Verify", "Verification")
    }

    $sections = @{}

    # Collect match positions for every heading variant
    $positions = @()
    foreach ($txKey in $headings.Keys) {
        $variants = $headings[$txKey]
        if ($variants -is [string]) { $variants = @($variants) }
        foreach ($v in $variants) {
            $pat = "(?m)^$([regex]::Escape($v))\s*$"
            $m   = [regex]::Match($Content, $pat)
            if ($m.Success) {
                $positions += [PSCustomObject]@{ TxKey = $txKey; Index = $m.Index; Length = $m.Length }
            }
        }
    }
    $positions = $positions | Sort-Object Index

    for ($i = 0; $i -lt $positions.Count; $i++) {
        $start   = $positions[$i].Index + $positions[$i].Length
        $end     = if ($i + 1 -lt $positions.Count) { $positions[$i+1].Index } else { $Content.Length }
        $sections[$positions[$i].TxKey] = $Content.Substring($start, $end - $start)
    }
    return $sections
}

function Extract-ISO8583 {
    <#
    .SYNOPSIS
    Finds the ISO8583 request line within a bounded section string.
    #>
    param([string]$SectionContent)
    if ($SectionContent -match "ISO 8583 Request:\s*\r?\n\s*(ISO8583 Message:[^\r\n]+)") {
        return $Matches[1]
    }
    return $null
}

# ─── Load log ────────────────────────────────────────────────────────────────

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " ISO 8583 Per-Transaction Comparison" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if (-not (Test-Path $LogFile)) {
    Write-Host "ERROR: Log file not found: $LogFile" -ForegroundColor Red
    exit 1
}

$log = Get-Content $LogFile -Raw
Write-Host "Loaded: $LogFile" -ForegroundColor Green

# ─── Split into Target / Modernization halves ────────────────────────────────

if ($log -notmatch "(?s)(Target Environment.+?)(Modernization Environment.+)$") {
    Write-Host "ERROR: Could not split log into Target / Modernization sections." -ForegroundColor Red
    exit 1
}
$targetSection = $Matches[1]
$modernSection = $Matches[2]

# ─── Extract ISO 8583 lines per transaction ───────────────────────────────────

$txOrder = @("AUTHORIZATION", "VOID_AUTHORIZATION", "VERIFICATION")

$targetSections = Get-TransactionSections $targetSection
$modernSections = Get-TransactionSections $modernSection

Write-Host "  Target transactions found    : $($targetSections.Keys -join ', ')" -ForegroundColor Gray
Write-Host "  Modernization transactions   : $($modernSections.Keys  -join ', ')" -ForegroundColor Gray

$allRows = @()   # for CSV
$txResults = @() # per-transaction comparison objects

foreach ($txName in $txOrder) {
    $targetLine = if ($targetSections.ContainsKey($txName)) { Extract-ISO8583 $targetSections[$txName] } else { $null }
    $modernLine = if ($modernSections.ContainsKey($txName)) { Extract-ISO8583 $modernSections[$txName] } else { $null }

    if (-not $targetLine) {
        Write-Host "  WARN: No ISO 8583 found for $txName in Target section" -ForegroundColor Yellow
    }
    if (-not $modernLine) {
        Write-Host "  WARN: No ISO 8583 found for $txName in Modernization section" -ForegroundColor Yellow
    }

    $targetFields = if ($targetLine) { Parse-ISO8583Line $targetLine } else { [ordered]@{} }
    $modernFields = if ($modernLine) { Parse-ISO8583Line $modernLine } else { [ordered]@{} }

    # Union of all field paths
    $allKeys = @($targetFields.Keys) + @($modernFields.Keys) | Sort-Object -Unique

    $rows = foreach ($key in $allKeys) {
        $tVal = if ($targetFields.Contains($key)) { $targetFields[$key] } else { $null }
        $mVal = if ($modernFields.Contains($key)) { $modernFields[$key] } else { $null }

        $status = switch ($true) {
            { $null -eq $tVal }              { "EXTRA_IN_MOD";    break }
            { $null -eq $mVal }              { "MISSING_IN_MOD";  break }
            { $tVal -eq $mVal }              { "MATCH";           break }
            default                           { "VALUE_DIFF" }
        }

        [PSCustomObject]@{
            Transaction    = $txName
            FieldPath      = $key
            TargetValue    = if ($null -ne $tVal) { $tVal } else { "" }
            ModernValue    = if ($null -ne $mVal) { $mVal } else { "" }
            Status         = $status
        }
    }

    $txResults += [PSCustomObject]@{
        Name         = $txName
        Rows         = $rows
        TargetMTI    = if ($targetFields.Contains("Header.1(messageTypeId)")) { $targetFields["Header.1(messageTypeId)"] } else { "N/A" }
        ModernMTI    = if ($modernFields.Contains("Header.1(messageTypeId)")) { $modernFields["Header.1(messageTypeId)"] } else { "N/A" }
    }

    $allRows += $rows

    # Console summary
    $match   = @($rows | Where-Object Status -eq "MATCH").Count
    $diff    = @($rows | Where-Object Status -eq "VALUE_DIFF").Count
    $missing = @($rows | Where-Object Status -eq "MISSING_IN_MOD").Count
    $extra   = @($rows | Where-Object Status -eq "EXTRA_IN_MOD").Count
    Write-Host "  $txName  →  MATCH:$match  DIFF:$diff  MISSING_IN_MOD:$missing  EXTRA_IN_MOD:$extra" -ForegroundColor White
}

# ─── CSV export ──────────────────────────────────────────────────────────────

$reportsDir = Split-Path $CsvOut -Parent
if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir | Out-Null }

$allRows | Export-Csv -Path $CsvOut -NoTypeInformation -Encoding UTF8
Write-Host "`nCSV  : $CsvOut" -ForegroundColor Green

# ─── HTML Report ─────────────────────────────────────────────────────────────

function Status-Badge {
    param([string]$s)
    switch ($s) {
        "MATCH"          { return '<span class="badge match">MATCH</span>' }
        "VALUE_DIFF"     { return '<span class="badge diff">VALUE DIFF</span>' }
        "MISSING_IN_MOD" { return '<span class="badge missing">MISSING IN MOD</span>' }
        "EXTRA_IN_MOD"   { return '<span class="badge extra">EXTRA IN MOD</span>' }
        default          { return "<span class='badge'>$s</span>" }
    }
}

function Row-Class {
    param([string]$s)
    switch ($s) {
        "MATCH"          { return "row-match" }
        "VALUE_DIFF"     { return "row-diff" }
        "MISSING_IN_MOD" { return "row-missing" }
        "EXTRA_IN_MOD"   { return "row-extra" }
        default          { return "" }
    }
}

$generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# Build per-transaction HTML sections
$txSections = foreach ($tx in $txResults) {
    $txName  = $tx.Name
    $rows    = $tx.Rows
    $tMTI    = $tx.TargetMTI
    $mMTI    = $tx.ModernMTI

    $match   = @($rows | Where-Object Status -eq "MATCH").Count
    $diff    = @($rows | Where-Object Status -eq "VALUE_DIFF").Count
    $missing = @($rows | Where-Object Status -eq "MISSING_IN_MOD").Count
    $extra   = @($rows | Where-Object Status -eq "EXTRA_IN_MOD").Count

    $mtiClass = if ($tMTI -ne $mMTI) { "mti-diff" } else { "mti-match" }

    $tableRows = foreach ($r in $rows) {
        $badge = Status-Badge $r.Status
        $rc    = Row-Class $r.Status
        $tv    = [System.Web.HttpUtility]::HtmlEncode($r.TargetValue)
        $mv    = [System.Web.HttpUtility]::HtmlEncode($r.ModernValue)
        "<tr class='$rc'><td class='fp'>$($r.FieldPath)</td><td class='tv'>$tv</td><td class='mv'>$mv</td><td>$badge</td></tr>"
    }

    @"
<section id="$txName">
  <h2>$txName</h2>
  <div class="mti-bar $mtiClass">
    <span>Target MTI: <strong>$tMTI</strong></span>
    <span class="sep">|</span>
    <span>Modernization MTI: <strong>$mMTI</strong></span>
    $(if ($tMTI -ne $mMTI) { '<span class="mti-warn">⚠ MTI MISMATCH</span>' })
  </div>
  <div class="stats">
    <div class="stat s-match"><div class="snum">$match</div><div class="slbl">Match</div></div>
    <div class="stat s-diff"><div class="snum">$diff</div><div class="slbl">Value Diff</div></div>
    <div class="stat s-missing"><div class="snum">$missing</div><div class="slbl">Missing in Mod</div></div>
    <div class="stat s-extra"><div class="snum">$extra</div><div class="slbl">Extra in Mod</div></div>
  </div>
  <table>
    <thead>
      <tr><th>Field Path</th><th>Target Value</th><th>Modernization Value</th><th>Status</th></tr>
    </thead>
    <tbody>
      $($tableRows -join "`n      ")
    </tbody>
  </table>
</section>
"@
}

# Overall totals
$totalMatch   = @($allRows | Where-Object Status -eq "MATCH").Count
$totalDiff    = @($allRows | Where-Object Status -eq "VALUE_DIFF").Count
$totalMissing = @($allRows | Where-Object Status -eq "MISSING_IN_MOD").Count
$totalExtra   = @($allRows | Where-Object Status -eq "EXTRA_IN_MOD").Count

$navLinks = ($txOrder | ForEach-Object { "<a href='#$_'>$_</a>" }) -join " | "

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>ISO 8583 Comparison — Target vs Modernization</title>
<style>
  *, *::before, *::after { box-sizing: border-box; }
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #f0f2f5; margin: 0; padding: 0; color: #222; }
  header { background: #003366; color: #fff; padding: 18px 32px; }
  header h1 { margin: 0; font-size: 1.5rem; }
  header p  { margin: 4px 0 0; font-size: .85rem; opacity: .8; }
  nav { background: #004080; padding: 10px 32px; }
  nav a { color: #a8d4ff; text-decoration: none; font-size: .9rem; margin-right: 12px; }
  nav a:hover { color: #fff; }

  .summary-bar { display: flex; gap: 16px; padding: 18px 32px; background: #fff; border-bottom: 1px solid #dde; flex-wrap: wrap; align-items: center; }
  .summary-bar h3 { margin: 0 8px 0 0; font-size: 1rem; color: #555; }
  .sum-chip { padding: 5px 14px; border-radius: 20px; font-weight: 600; font-size: .85rem; }
  .sum-match   { background:#d4edda; color:#155724; }
  .sum-diff    { background:#fff3cd; color:#856404; }
  .sum-missing { background:#f8d7da; color:#721c24; }
  .sum-extra   { background:#d1ecf1; color:#0c5460; }

  main { padding: 24px 32px; }

  section { background: #fff; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,.1); margin-bottom: 32px; overflow: hidden; }
  section h2 { margin: 0; padding: 16px 20px; background: #003366; color: #fff; font-size: 1.1rem; letter-spacing: .04em; }

  .mti-bar { display: flex; align-items: center; gap: 12px; padding: 10px 20px; font-size: .9rem; flex-wrap: wrap; }
  .mti-match  { background: #e8f5e9; border-left: 4px solid #4caf50; }
  .mti-diff   { background: #fff3e0; border-left: 4px solid #ff9800; }
  .mti-warn   { font-weight: 700; color: #e65100; margin-left: auto; }
  .sep { color: #aaa; }

  .stats { display: flex; gap: 0; border-bottom: 1px solid #eee; }
  .stat { flex: 1; text-align: center; padding: 14px 8px; border-right: 1px solid #eee; }
  .stat:last-child { border-right: none; }
  .snum { font-size: 1.7rem; font-weight: 700; line-height: 1; }
  .slbl { font-size: .72rem; text-transform: uppercase; letter-spacing: .06em; color: #777; margin-top: 4px; }
  .s-match   .snum { color: #28a745; }
  .s-diff    .snum { color: #ffc107; }
  .s-missing .snum { color: #dc3545; }
  .s-extra   .snum { color: #17a2b8; }

  table { width: 100%; border-collapse: collapse; font-size: .82rem; }
  thead tr { background: #f8f9fa; }
  th { padding: 10px 14px; text-align: left; font-weight: 600; border-bottom: 2px solid #dee2e6; white-space: nowrap; }
  td { padding: 7px 14px; border-bottom: 1px solid #f0f0f0; vertical-align: top; word-break: break-all; }
  tr:hover td { background: #fafafa; }
  .fp { font-family: 'Consolas','Courier New',monospace; font-size: .8rem; color: #333; min-width: 260px; }
  .tv, .mv { font-family: 'Consolas','Courier New',monospace; font-size: .8rem; min-width: 160px; }

  .row-match   td { }
  .row-diff    td { background: #fffde7; }
  .row-missing td { background: #fff5f5; }
  .row-extra   td { background: #f0faff; }

  .badge { display: inline-block; padding: 2px 9px; border-radius: 12px; font-size: .72rem; font-weight: 700; white-space: nowrap; }
  .match   { background:#d4edda; color:#155724; }
  .diff    { background:#fff3cd; color:#856404; }
  .missing { background:#f8d7da; color:#721c24; }
  .extra   { background:#d1ecf1; color:#0c5460; }

  footer { text-align: center; padding: 16px; font-size: .78rem; color: #999; }
</style>
</head>
<body>
<header>
  <h1>ISO 8583 Request Comparison — Target vs Modernization</h1>
  <p>Generated: $generatedAt &nbsp;|&nbsp; Source: target-modernization-logs.txt</p>
</header>
<nav>$navLinks</nav>

<div class="summary-bar">
  <h3>Overall Totals:</h3>
  <span class="sum-chip sum-match">&#10003; Match: $totalMatch</span>
  <span class="sum-chip sum-diff">&#9432; Value Diff: $totalDiff</span>
  <span class="sum-chip sum-missing">&#10007; Missing in Mod: $totalMissing</span>
  <span class="sum-chip sum-extra">&#43; Extra in Mod: $totalExtra</span>
</div>

<main>
$($txSections -join "`n")
</main>
<footer>ISO 8583 Comparison Tool &mdash; Elavon S2A Modernization Project</footer>
</body>
</html>
"@

# System.Web may not be available — encode manually
$html = $html -replace '&amp;', '&'   # avoid double-encode artefacts (none expected)
$html | Set-Content -Path $HtmlOut -Encoding UTF8

Write-Host "HTML : $HtmlOut" -ForegroundColor Green

# ─── Console detail for non-MATCH rows ───────────────────────────────────────

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " DIFFERENCES SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($tx in $txResults) {
    $issues = @($tx.Rows | Where-Object { $_.Status -ne "MATCH" })
    if ($issues.Count -eq 0) { continue }

    Write-Host "`n[ $($tx.Name) ]  Target MTI=$($tx.TargetMTI)  Mod MTI=$($tx.ModernMTI)" -ForegroundColor Yellow

    $issues | ForEach-Object {
        $colour = switch ($_.Status) {
            "VALUE_DIFF"     { "Magenta" }
            "MISSING_IN_MOD" { "Red"     }
            "EXTRA_IN_MOD"   { "Cyan"    }
        }
        $pad = $_.FieldPath.PadRight(55)
        Write-Host ("  $pad  [$($_.Status)]  Target='$($_.TargetValue)'  Mod='$($_.ModernValue)'") -ForegroundColor $colour
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Done" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
