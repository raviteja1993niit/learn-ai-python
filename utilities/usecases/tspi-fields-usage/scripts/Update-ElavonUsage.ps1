<#
.SYNOPSIS
    Agent that cross-references TSPI fields in input-data.csv against the
    Find-TSPIFieldUsages lookup CSV and updates ElavonUsage + UsageComments columns.

.DESCRIPTION
    For each row in InputCsv:
      1. Normalise Field Name to lowercase dot-notation (matches lookup CSV format).
      2. Exact match  – FieldName in lookup equals the normalised name.
      3. Prefix match – FieldName in lookup starts with the normalised name + '.'
                        (means a child field was accessed, implying the parent is used).
      4. Stamp ElavonUsage = "USED" / "NOT_USED".
      5. Add UsageComments = summary of matched rows (count, source classes, sample line).
      6. Write updated rows to OutputCsv (default: input-data.csv overwritten in-place).

.PARAMETER InputCsv
    Path to the input-data.csv file containing the TSPI field list.

.PARAMETER LookupCsv
    Path to the lookup CSV produced by Find-TSPIFieldUsages.ps1.
    Defaults to the most-recent file in the logs\ folder beside this script.

.PARAMETER OutputCsv
    Path for the updated CSV output.
    Defaults to overwriting InputCsv in-place.

.EXAMPLE
    .\Update-ElavonUsage.ps1

.EXAMPLE
    .\Update-ElavonUsage.ps1 `
        -InputCsv  "..\input-data.csv" `
        -LookupCsv "..\logs\acqelavons2aservice_20260417_111740.csv" `
        -OutputCsv "..\input-data-updated.csv"
#>

[CmdletBinding()]
param(
    [string] $InputCsv = (Join-Path $PSScriptRoot "..\input-data.csv"),

    [string] $LookupCsv = "",   # auto-resolved to latest log if empty

    [string] $OutputCsv = ""    # defaults to overwrite InputCsv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Phase { param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}
function Write-Ok   { param([string]$Msg) Write-Host "  [ OK ]  $Msg" -ForegroundColor Green }
function Write-Info { param([string]$Msg) Write-Host "  [INFO]  $Msg" -ForegroundColor White }
function Write-Warn { param([string]$Msg) Write-Host "  [WARN]  $Msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

if (-not (Test-Path $InputCsv)) {
    Write-Error "InputCsv not found: $InputCsv"
    exit 1
}

# Auto-pick latest lookup CSV from logs\ folder if not specified
if ($LookupCsv -eq "") {
    $logsDir = Join-Path $PSScriptRoot "..\logs"
    $latest  = Get-ChildItem $logsDir -Filter "*.csv" -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending |
                   Select-Object -First 1
    if ($null -eq $latest) {
        Write-Error "No CSV files found in $logsDir. Run Find-TSPIFieldUsages.ps1 first."
        exit 1
    }
    $LookupCsv = $latest.FullName
    Write-Info "Auto-selected latest lookup: $($latest.Name)"
}

if (-not (Test-Path $LookupCsv)) {
    Write-Error "LookupCsv not found: $LookupCsv"
    exit 1
}

if ($OutputCsv -eq "") { $OutputCsv = $InputCsv }

# ---------------------------------------------------------------------------
# Phase 1 – Load data
# ---------------------------------------------------------------------------
Write-Phase "Phase 1 : Loading input and lookup data"

[object[]] $inputRows  = Import-Csv $InputCsv
[object[]] $lookupRows = Import-Csv $LookupCsv

Write-Ok "Input rows    : $($inputRows.Count)  ($InputCsv)"
Write-Ok "Lookup rows   : $($lookupRows.Count)  ($LookupCsv)"

# ---------------------------------------------------------------------------
# Phase 2 – Build lookup index (normalised FieldName → list of rows)
# ---------------------------------------------------------------------------
Write-Phase "Phase 2 : Building lookup index"

$lookupIndex = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[pscustomobject]]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

foreach ($row in $lookupRows) {
    $fn = $row.FieldName.Trim().ToLower()
    if ($fn -eq '') { continue }
    if (-not $lookupIndex.ContainsKey($fn)) {
        $lookupIndex[$fn] = [System.Collections.Generic.List[pscustomobject]]::new()
    }
    $lookupIndex[$fn].Add($row)
}

Write-Ok "Unique FieldName keys in index: $($lookupIndex.Count)"

# ---------------------------------------------------------------------------
# Phase 3 – Normalise and match each input field
# ---------------------------------------------------------------------------
Write-Phase "Phase 3 : Matching input fields against lookup"

# Normalise: PascalCase.Dot.Notation -> lowercase.dot.notation
function Get-NormalisedFieldName {
    param([string] $FieldName)
    return $FieldName.Trim().ToLower()
}

# Summarise a list of matching lookup rows into a human-readable comment string
function Get-UsageComment {
    param([System.Collections.Generic.List[pscustomobject]] $Matches)

    $count        = $Matches.Count
    [string[]] $classes = @($Matches | ForEach-Object { $_.ClassName } | Sort-Object -Unique)
    $classStr     = $classes -join '; '

    # Build per-class concise summaries (max 2 sample lines per class)
    $samples = [System.Collections.Generic.List[string]]::new()
    foreach ($cls in $classes) {
        [object[]] $clsRows = @($Matches | Where-Object { $_.ClassName -eq $cls })
        $sample = $clsRows[0].LineContent.Trim() -replace '"', "'"
        $samples.Add("[$cls] L$($clsRows[0].LineNo): $sample")
        if ($clsRows.Count -gt 1) {
            $sample2 = $clsRows[1].LineContent.Trim() -replace '"', "'"
            $samples.Add("[$cls] L$($clsRows[1].LineNo): $sample2")
        }
    }

    $sampleStr = $samples -join ' | '
    return "count=$count classes=[$classStr] samples: $sampleStr"
}

$usedCount    = 0
$notUsedCount = 0
$results      = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($row in $inputRows) {
    $fieldName   = $row.'Field Name'
    $normName    = Get-NormalisedFieldName $fieldName

    # --- Exact match ---
    $matched = [System.Collections.Generic.List[pscustomobject]]::new()

    if ($lookupIndex.ContainsKey($normName)) {
        foreach ($m in $lookupIndex[$normName]) { $matched.Add($m) }
    }

    # --- Prefix match (child fields accessed → parent implicitly used) ---
    $prefix = $normName + '.'
    foreach ($key in $lookupIndex.Keys) {
        if ($key.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            foreach ($m in $lookupIndex[$key]) { $matched.Add($m) }
        }
    }

    # Deduplicate by FilePath+LineNo
    $seen    = [System.Collections.Generic.HashSet[string]]::new()
    $deduped = [System.Collections.Generic.List[pscustomobject]]::new()
    foreach ($m in $matched) {
        $key = "$($m.FilePath)|$($m.LineNo)"
        if ($seen.Add($key)) { $deduped.Add($m) }
    }

    if ($deduped.Count -gt 0) {
        $elavonUsage   = "USED"
        $usageComments = Get-UsageComment -Matches $deduped
        $usedCount++
    } else {
        $elavonUsage   = "NOT_USED"
        $usageComments = ""
        $notUsedCount++
    }

    # Build output row preserving all original columns
    $outRow = [ordered]@{}
    foreach ($prop in $row.PSObject.Properties) {
        $outRow[$prop.Name] = $prop.Value
    }
    $outRow['ElavonUsage']    = $elavonUsage
    $outRow['UsageComments']  = $usageComments

    $results.Add([pscustomobject]$outRow)
    Write-Verbose "  $fieldName → $elavonUsage  ($($deduped.Count) hits)"
}

Write-Ok "USED     : $usedCount"
Write-Ok "NOT_USED : $notUsedCount"

# ---------------------------------------------------------------------------
# Phase 4 – Write output CSV
# ---------------------------------------------------------------------------
Write-Phase "Phase 4 : Writing updated CSV"

$results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Ok "Output written: $OutputCsv"

# ---------------------------------------------------------------------------
# Summary table
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  TSPI Field Usage Summary" -ForegroundColor Cyan
Write-Host ("  " + "-" * 60) -ForegroundColor Cyan
Write-Host ("  {0,-55} {1}" -f "Field Name", "ElavonUsage") -ForegroundColor White
Write-Host ("  " + "-" * 60) -ForegroundColor Cyan

foreach ($r in $results) {
    $colour = if ($r.ElavonUsage -eq 'USED') { 'Green' } else { 'DarkGray' }
    Write-Host ("  {0,-55} {1}" -f $r.'Field Name', $r.ElavonUsage) -ForegroundColor $colour
}

Write-Host ""
Write-Ok "Done. $usedCount / $($inputRows.Count) TSPI fields are used in the elavon service."
