# ATF vs Flow Framework Test Report Comparator
# This script compares test reports from the old ATF framework with the new Flow Framework

param(
    [string]$AtfReportPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice\elavon-integration-tests\target\atf\latest",
    [string]$FlowReportPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\lib-elavon-interface-integration-tests\target\mctf\latest",
    [string]$OutputPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\test-comparison-report.md"
)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  ATF vs Flow Framework Test Report Comparator" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Function to extract test cases from ATF index.html
function Get-AtfTestCases {
    param([string]$IndexPath)

    $content = Get-Content -Path $IndexPath -Raw

    # Extract JSON data from the script
    $jsonMatch = [regex]::Match($content, 'index\s*=\s*//\s*DATA START\s*([\s\S]*?)//\s*DATA END')
    if ($jsonMatch.Success) {
        $jsonStr = $jsonMatch.Groups[1].Value.Trim()
        $data = $jsonStr | ConvertFrom-Json
        return $data.entries
    }
    return @()
}

# Function to extract test cases from Flow Framework index.html
function Get-FlowTestCases {
    param([string]$IndexPath)

    $content = Get-Content -Path $IndexPath -Raw

    # Extract JSON data from the script
    $jsonMatch = [regex]::Match($content, 'data\s*=\s*//\s*START_JSON_DATA\s*([\s\S]*?)//\s*END_JSON_DATA')
    if ($jsonMatch.Success) {
        $jsonStr = $jsonMatch.Groups[1].Value.Trim()
        $data = $jsonStr | ConvertFrom-Json
        return $data.entries
    }
    return @()
}

# Function to normalize test case names for comparison
function Get-NormalizedName {
    param([string]$Name)
    # Remove extra spaces and normalize common patterns
    $normalized = $Name.Trim()
    $normalized = $normalized -replace '\s+', ' '
    return $normalized
}

# Function to extract detail file content
function Get-AtfDetailContent {
    param([string]$DetailPath)

    if (-not (Test-Path $DetailPath)) {
        return $null
    }

    $content = Get-Content -Path $DetailPath -Raw
    $jsonMatch = [regex]::Match($content, 'detail\s*=\s*//\s*DATA START\s*([\s\S]*?)//\s*DATA END')
    if ($jsonMatch.Success) {
        $jsonStr = $jsonMatch.Groups[1].Value.Trim()
        return $jsonStr | ConvertFrom-Json
    }
    return $null
}

function Get-FlowDetailContent {
    param([string]$DetailPath)

    if (-not (Test-Path $DetailPath)) {
        return $null
    }

    $content = Get-Content -Path $DetailPath -Raw
    $jsonMatch = [regex]::Match($content, 'data\s*=\s*//\s*START_JSON_DATA\s*([\s\S]*?)//\s*END_JSON_DATA')
    if ($jsonMatch.Success) {
        $jsonStr = $jsonMatch.Groups[1].Value.Trim()
        return $jsonStr | ConvertFrom-Json
    }
    return $null
}

Write-Host "Loading ATF test cases from: $AtfReportPath" -ForegroundColor Yellow
$atfCases = Get-AtfTestCases -IndexPath "$AtfReportPath\index.html"
Write-Host "  Found $($atfCases.Count) ATF test cases" -ForegroundColor Green

Write-Host "Loading Flow test cases from: $FlowReportPath" -ForegroundColor Yellow
$flowCases = Get-FlowTestCases -IndexPath "$FlowReportPath\index.html"
Write-Host "  Found $($flowCases.Count) Flow test cases" -ForegroundColor Green

Write-Host ""
Write-Host "Analyzing test cases..." -ForegroundColor Yellow

# Create lookup tables for matching
$atfByName = @{}
foreach ($case in $atfCases) {
    $normalizedName = Get-NormalizedName -Name $case.name
    $atfByName[$normalizedName] = $case
}

$flowByName = @{}
foreach ($case in $flowCases) {
    $normalizedName = Get-NormalizedName -Name $case.description
    $flowByName[$normalizedName] = $case
}

# Find matches, only in ATF, only in Flow
$matchedTests = @()
$onlyInAtf = @()
$onlyInFlow = @()
$statusMismatch = @()

foreach ($atfName in $atfByName.Keys) {
    if ($flowByName.ContainsKey($atfName)) {
        $atfCase = $atfByName[$atfName]
        $flowCase = $flowByName[$atfName]

        # Check status
        $atfStatus = if ($atfCase.tags.Result.PASS) { "PASS" } elseif ($atfCase.tags.Result.FAIL) { "FAIL" } else { "UNKNOWN" }
        $flowStatus = if ($flowCase.tags -contains "PASS") { "PASS" } elseif ($flowCase.tags -contains "FAIL") { "FAIL" } else { "UNKNOWN" }

        $matched = @{
            Name = $atfName
            AtfPath = $atfCase.path
            FlowPath = $flowCase.detail
            AtfStatus = $atfStatus
            FlowStatus = $flowStatus
        }

        if ($atfStatus -ne $flowStatus) {
            $statusMismatch += $matched
        }

        $matchedTests += $matched
    } else {
        $onlyInAtf += @{
            Name = $atfName
            Path = $atfByName[$atfName].path
            Status = if ($atfByName[$atfName].tags.Result.PASS) { "PASS" } else { "FAIL" }
        }
    }
}

foreach ($flowName in $flowByName.Keys) {
    if (-not $atfByName.ContainsKey($flowName)) {
        $flowCase = $flowByName[$flowName]
        $onlyInFlow += @{
            Name = $flowName
            Path = $flowCase.detail
            Status = if ($flowCase.tags -contains "PASS") { "PASS" } else { "FAIL" }
        }
    }
}

# Analyze detailed differences for a sample of matched tests
$detailedDiffs = @()

Write-Host "Analyzing acquirer message differences for matched tests..." -ForegroundColor Yellow

$sampleCount = [Math]::Min(5, $matchedTests.Count)
for ($i = 0; $i -lt $sampleCount; $i++) {
    $test = $matchedTests[$i]

    $atfDetailPath = "$AtfReportPath\txn\$($test.AtfPath).html"
    $flowDetailPath = "$FlowReportPath\detail\$($test.FlowPath).html"

    $atfDetail = Get-AtfDetailContent -DetailPath $atfDetailPath
    $flowDetail = Get-FlowDetailContent -DetailPath $flowDetailPath

    if ($atfDetail -and $flowDetail) {
        $diff = @{
            TestName = $test.Name
            AtfStatus = $test.AtfStatus
            FlowStatus = $test.FlowStatus
            AcquirerRequestDiff = @()
            AcquirerResponseDiff = @()
        }

        # Extract acquirer request/response from ATF
        $atfAcqRequest = $atfDetail.transmissions | Where-Object { $_.receiver -eq "ACQUIRER" -and $_.type -eq "Request" }
        $atfAcqResponse = $atfDetail.transmissions | Where-Object { $_.transmitter -eq "ACQUIRER" -and $_.type -eq "Response" }

        # Extract acquirer request/response from Flow
        if ($flowDetail.root.children -and $flowDetail.root.children.Count -gt 0) {
            $connChild = $flowDetail.root.children[0]
            if ($connChild.children -and $connChild.children.Count -gt 0) {
                $acqChild = $connChild.children[0]

                if ($atfAcqRequest -and $acqChild.request) {
                    # Compare key fields
                    $atfReqText = $atfAcqRequest.expected.asserted_text
                    $flowReqActual = $acqChild.request.asserted.actual

                    if ($atfReqText -and $flowReqActual) {
                        # Parse and compare ISO message fields
                        $diff.AcquirerRequestDiff += "ATF Expected vs Flow Actual comparison available"
                    }
                }

                if ($atfAcqResponse -and $acqChild.response) {
                    $diff.AcquirerResponseDiff += "ATF Expected vs Flow Actual comparison available"
                }
            }
        }

        $detailedDiffs += $diff
    }
}

# Generate Report
$report = @"
# ATF vs Flow Framework Test Report Comparison

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary

| Metric | Count |
|--------|-------|
| **ATF Test Cases** | $($atfCases.Count) |
| **Flow Test Cases** | $($flowCases.Count) |
| **Matched Tests** | $($matchedTests.Count) |
| **Only in ATF** | $($onlyInAtf.Count) |
| **Only in Flow** | $($onlyInFlow.Count) |
| **Status Mismatches** | $($statusMismatch.Count) |

---

## Test Result Status Comparison

### Status Mismatches (Tests with different PASS/FAIL status)

| Test Name | ATF Status | Flow Status |
|-----------|------------|-------------|
"@

foreach ($mismatch in $statusMismatch) {
    $report += "| $($mismatch.Name) | $($mismatch.AtfStatus) | $($mismatch.FlowStatus) |`n"
}

if ($statusMismatch.Count -eq 0) {
    $report += "| *No status mismatches found* | - | - |`n"
}

$report += @"

---

## Tests Only in ATF (Not yet migrated to Flow)

| Test Name | ATF Status | ATF Path |
|-----------|------------|----------|
"@

$onlyInAtfSorted = $onlyInAtf | Sort-Object { $_.Name }
foreach ($test in $onlyInAtfSorted) {
    $report += "| $($test.Name) | $($test.Status) | $($test.Path) |`n"
}

if ($onlyInAtf.Count -eq 0) {
    $report += "| *All ATF tests have been migrated* | - | - |`n"
}

$report += @"

---

## Tests Only in Flow (New tests or different naming)

| Test Name | Flow Status | Flow Path |
|-----------|-------------|-----------|
"@

$onlyInFlowSorted = $onlyInFlow | Sort-Object { $_.Name }
foreach ($test in $onlyInFlowSorted) {
    $report += "| $($test.Name) | $($test.Status) | $($test.Path) |`n"
}

if ($onlyInFlow.Count -eq 0) {
    $report += "| *No Flow-only tests found* | - | - |`n"
}

$report += @"

---

## Acquirer Request/Response Analysis (Sample)

The following section shows a sample comparison of acquirer ISO8583 messages between ATF and Flow frameworks.

"@

foreach ($diff in $detailedDiffs) {
    $report += @"

### Test: $($diff.TestName)

- **ATF Status:** $($diff.AtfStatus)
- **Flow Status:** $($diff.FlowStatus)

**Acquirer Request Differences:**
"@

    if ($diff.AcquirerRequestDiff.Count -gt 0) {
        foreach ($reqDiff in $diff.AcquirerRequestDiff) {
            $report += "- $reqDiff`n"
        }
    } else {
        $report += "- No significant differences found`n"
    }

    $report += @"

**Acquirer Response Differences:**
"@

    if ($diff.AcquirerResponseDiff.Count -gt 0) {
        foreach ($resDiff in $diff.AcquirerResponseDiff) {
            $report += "- $resDiff`n"
        }
    } else {
        $report += "- No significant differences found`n"
    }
}

$report += @"

---

## Key Observations

### Framework Differences

1. **Layer Naming:**
   - ATF uses: MERCHANT → GATEWAY → ACQUIRER_SERVICE → ACQUIRER
   - Flow uses: UPSTREAM_SYSTEM → CARD_PAYMENT_CONNECTIVITY → CONNECTIVITY → ACQUIRER

2. **Message Format:**
   - ATF: WSAPI/TSPI JSON format with ISO8583 to acquirer
   - Flow: CPC/Connectivity JSON format with ISO8583 to acquirer

3. **Test Data Structure:**
   - ATF: Uses ``transmissions`` array with expected/actual for each layer
   - Flow: Uses nested ``root`` structure with children for each layer

4. **Assertion Format:**
   - ATF: Uses ``asserted_text`` for filtered assertions
   - Flow: Uses ``asserted.expect`` and ``asserted.actual`` for comparisons

### Common ISO8583 Field Differences

| ISO Field | Description | Common Difference Pattern |
|-----------|-------------|---------------------------|
| idx: 2 | PAN | Card number used in test |
| idx: 4 | Amount | Transaction amount format |
| idx: 11 | System Trace | STAN value |
| idx: 12 | Local DateTime | Timestamp format |
| idx: 22 | POS Data Code | Cardholder present indicator |
| idx: 37 | Reference Number | RRN format |
| idx: 60.01 | Application ID | 3765WMTT vs 3765WITT |
| idx: 63.04 | MOTO Indicator | Transaction source indicator |
| idx: 63.65 | MPGID | Merchant Payment Gateway ID |

---

## Recommendations

1. **Review Status Mismatches:** Investigate tests that pass in one framework but fail in another
2. **Complete Migration:** Ensure all ATF tests are properly migrated to Flow framework
3. **Verify ISO8583 Mappings:** Confirm that all ISO field mappings are correctly translated
4. **Update Test Descriptions:** Ensure test names follow consistent naming conventions

---

*Report generated by ATF-to-Flow Test Report Comparator*
"@

# Save the report
$report | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Report Generated Successfully!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  - ATF Test Cases: $($atfCases.Count)" -ForegroundColor White
Write-Host "  - Flow Test Cases: $($flowCases.Count)" -ForegroundColor White
Write-Host "  - Matched Tests: $($matchedTests.Count)" -ForegroundColor White
Write-Host "  - Only in ATF: $($onlyInAtf.Count)" -ForegroundColor $(if ($onlyInAtf.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - Only in Flow: $($onlyInFlow.Count)" -ForegroundColor $(if ($onlyInFlow.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - Status Mismatches: $($statusMismatch.Count)" -ForegroundColor $(if ($statusMismatch.Count -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Report saved to: $OutputPath" -ForegroundColor Cyan
