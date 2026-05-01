# PowerShell Script to Compare Modernization vs Target Environment Logs
# Detailed analysis of TSPI and ISO 8583 requests for Auth, Void Auth, and Verify operations
# Updated to include DYNAMIC ISO 8583 field extraction from log files

param(
    [string]$OutputPath = "$PSScriptRoot\environment-logs-iso8583-comparison.csv"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Environment Logs Comparison Analysis" -ForegroundColor Cyan
Write-Host "With Dynamic ISO 8583 Extraction" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results = @()

# Function to extract ISO 8583 fields from log content
function Get-ISO8583Fields {
    param(
        [string]$LogContent,
        [string]$Operation
    )

    $fields = @()

    # Find the ISO 8583 Message section for the specific operation
    $operationPattern = switch($Operation) {
        "AUTHORIZATION" { "Authorization.*?ISO 8583 Request:" }
        "VOID_AUTHORIZATION" { "Void Authorization.*?ISO 8583 Request:" }
        "VERIFICATION" { "Verify.*?ISO 8583 Request:|Verification.*?ISO 8583 Request:" }
    }

    # Extract entire ISO8583 Message block
    $iso8583Match = [regex]::Match($LogContent, $operationPattern + "\s*(ISO8583 Message:.*?)(?=\n\n|\Z)", [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($iso8583Match.Success) {
        $iso8583Text = $iso8583Match.Groups[1].Value

        # Extract all field patterns: [NNN (fieldName) = 'value']
        $fieldMatches = [regex]::Matches($iso8583Text, '\[(\d{2,4})\s*\(([^\)]+)\)')

        foreach ($match in $fieldMatches) {
            $fieldCode = $match.Groups[1].Value
            $fieldName = $match.Groups[2].Value
            $fields += "$fieldCode ($fieldName)"
        }
    }

    return $fields | Select-Object -Unique | Sort-Object
}

# Read the log files
Write-Host "Reading environment log files..." -ForegroundColor Cyan
$modernizationLog = Get-Content -Path "$PSScriptRoot\docs\modernization-environment.log" -Raw -ErrorAction SilentlyContinue
$targetLog = Get-Content -Path "$PSScriptRoot\docs\target-environment.log" -Raw -ErrorAction SilentlyContinue

if (-not $modernizationLog -or -not $targetLog) {
    Write-Host "Error: Could not read log files from docs directory." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Log files loaded successfully`n" -ForegroundColor Green

# Extract ISO 8583 fields from both environments
Write-Host "Extracting ISO 8583 fields..." -ForegroundColor Cyan

Write-Host "  Analyzing AUTHORIZATION..." -ForegroundColor Gray
$modernAuthISO = Get-ISO8583Fields $modernizationLog "AUTHORIZATION"
$targetAuthISO = Get-ISO8583Fields $targetLog "AUTHORIZATION"

Write-Host "  Analyzing VOID_AUTHORIZATION..." -ForegroundColor Gray
$modernVoidISO = Get-ISO8583Fields $modernizationLog "VOID_AUTHORIZATION"
$targetVoidISO = Get-ISO8583Fields $targetLog "VOID_AUTHORIZATION"

Write-Host "  Analyzing VERIFICATION..." -ForegroundColor Gray
$modernVerifyISO = Get-ISO8583Fields $modernizationLog "VERIFICATION"
$targetVerifyISO = Get-ISO8583Fields $targetLog "VERIFICATION"

Write-Host "`n✓ ISO 8583 fields extracted`n" -ForegroundColor Green

# Compare and find missing/extra fields
Write-Host "Comparing fields between environments..." -ForegroundColor Cyan

$iso8583MissingAuth = $targetAuthISO | Where-Object { $_ -notin $modernAuthISO }
$iso8583ExtraAuth = $modernAuthISO | Where-Object { $_ -notin $targetAuthISO }

$iso8583MissingVoid = $targetVoidISO | Where-Object { $_ -notin $modernVoidISO }
$iso8583ExtraVoid = $modernVoidISO | Where-Object { $_ -notin $targetVoidISO }

$iso8583MissingVerify = $targetVerifyISO | Where-Object { $_ -notin $modernVerifyISO }
$iso8583ExtraVerify = $modernVerifyISO | Where-Object { $_ -notin $targetVerifyISO }

Write-Host "  AUTHORIZATION: Modern=$($modernAuthISO.Count), Target=$($targetAuthISO.Count)" -ForegroundColor Green
Write-Host "  VOID_AUTHORIZATION: Modern=$($modernVoidISO.Count), Target=$($targetVoidISO.Count)" -ForegroundColor Green
Write-Host "  VERIFICATION: Modern=$($modernVerifyISO.Count), Target=$($targetVerifyISO.Count)" -ForegroundColor Green
Write-Host "`n✓ Comparison complete`n" -ForegroundColor Green

# Add ISO 8583 comparison results
Write-Host "Compiling ISO 8583 comparison results..." -ForegroundColor Cyan

if ($iso8583MissingAuth.Count -gt 0) {
    $severityAuth = if ($iso8583MissingAuth.Count -gt 5) { "HIGH" } else { "MEDIUM" }
    $results += [PSCustomObject]@{
        Operation = "AUTHORIZATION"
        RequestType = "ISO 8583"
        Category = "Missing in Modernization"
        Fields = ($iso8583MissingAuth -join "; ")
        FieldCount = $iso8583MissingAuth.Count
        Severity = $severityAuth
    }
}

if ($iso8583ExtraAuth.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "AUTHORIZATION"
        RequestType = "ISO 8583"
        Category = "Extra in Modernization"
        Fields = ($iso8583ExtraAuth -join "; ")
        FieldCount = $iso8583ExtraAuth.Count
        Severity = "LOW"
    }
}

if ($iso8583MissingVoid.Count -gt 0) {
    $severityVoid = if ($iso8583MissingVoid.Count -gt 5) { "HIGH" } else { "MEDIUM" }
    $results += [PSCustomObject]@{
        Operation = "VOID_AUTHORIZATION"
        RequestType = "ISO 8583"
        Category = "Missing in Modernization"
        Fields = ($iso8583MissingVoid -join "; ")
        FieldCount = $iso8583MissingVoid.Count
        Severity = $severityVoid
    }
}

if ($iso8583ExtraVoid.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VOID_AUTHORIZATION"
        RequestType = "ISO 8583"
        Category = "Extra in Modernization"
        Fields = ($iso8583ExtraVoid -join "; ")
        FieldCount = $iso8583ExtraVoid.Count
        Severity = "LOW"
    }
}

if ($iso8583MissingVerify.Count -gt 0) {
    $severityVerify = if ($iso8583MissingVerify.Count -gt 5) { "HIGH" } else { "MEDIUM" }
    $results += [PSCustomObject]@{
        Operation = "VERIFICATION"
        RequestType = "ISO 8583"
        Category = "Missing in Modernization"
        Fields = ($iso8583MissingVerify -join "; ")
        FieldCount = $iso8583MissingVerify.Count
        Severity = $severityVerify
    }
}

if ($iso8583ExtraVerify.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VERIFICATION"
        RequestType = "ISO 8583"
        Category = "Extra in Modernization"
        Fields = ($iso8583ExtraVerify -join "; ")
        FieldCount = $iso8583ExtraVerify.Count
        Severity = "LOW"
    }
}

# Export to CSV
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "✓ Analysis complete!" -ForegroundColor Green
    Write-Host "✓ CSV file created: $OutputPath" -ForegroundColor Green

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total ISO 8583 Differences Found: $($results.Count)" -ForegroundColor Yellow

    # Count by operation
    $authDiff = @($results | Where-Object {$_.Operation -eq 'AUTHORIZATION'}).Count
    $voidDiff = @($results | Where-Object {$_.Operation -eq 'VOID_AUTHORIZATION'}).Count
    $verifyDiff = @($results | Where-Object {$_.Operation -eq 'VERIFICATION'}).Count

    Write-Host "`n=== BY OPERATION ===" -ForegroundColor Cyan
    Write-Host "  AUTHORIZATION: $authDiff issue(s)" -ForegroundColor Yellow
    Write-Host "  VOID_AUTHORIZATION: $voidDiff issue(s)" -ForegroundColor Yellow
    Write-Host "  VERIFICATION: $verifyDiff issue(s)" -ForegroundColor Yellow

    # Count by category
    $missingCount = @($results | Where-Object {$_.Category -eq 'Missing in Modernization'}).Count
    $extraCount = @($results | Where-Object {$_.Category -eq 'Extra in Modernization'}).Count

    Write-Host "`n=== BY CATEGORY ===" -ForegroundColor Cyan
    Write-Host "  Missing in Modernization: $missingCount issue(s)" -ForegroundColor Red
    Write-Host "  Extra in Modernization: $extraCount issue(s)" -ForegroundColor Yellow

    # Count by severity
    $highSev = @($results | Where-Object {$_.Severity -eq 'HIGH'}).Count
    $medSev = @($results | Where-Object {$_.Severity -eq 'MEDIUM'}).Count
    $lowSev = @($results | Where-Object {$_.Severity -eq 'LOW'}).Count

    Write-Host "`n=== BY SEVERITY ===" -ForegroundColor Cyan
    Write-Host "  HIGH: $highSev issue(s)" -ForegroundColor Red
    Write-Host "  MEDIUM: $medSev issue(s)" -ForegroundColor Magenta
    Write-Host "  LOW: $lowSev issue(s)" -ForegroundColor Yellow

    # Field statistics
    $totalFields = ($results | Measure-Object -Property FieldCount -Sum).Sum
    Write-Host "`n=== FIELD STATISTICS ===" -ForegroundColor Cyan
    Write-Host "  Total Fields Affected: $totalFields" -ForegroundColor Yellow

    # Detailed results - ISO 8583 only
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "DETAILED ISO 8583 RESULTS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    $results | Format-Table -AutoSize -Wrap -Property Operation, Category, Fields, FieldCount, Severity

} else {
    Write-Host "`n✓ No ISO 8583 differences found between environments." -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Analysis Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

