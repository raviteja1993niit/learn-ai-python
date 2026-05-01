<#
.SYNOPSIS
    Report Analyzer Agent v4.0 - Analyzes ATF and Flow test reports

.DESCRIPTION
    Step 1: Parse Flow (MCTF) index.html and detail files for acquirer req/resp
    Step 2: Parse ATF index.html and txn files for acquirer req/resp
    Step 3: Compare and generate detailed field-by-field comparison report
#>

param(
    [string]$AtfReportPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice\elavon-integration-tests\target\atf\latest",
    [string]$FlowReportPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\lib-elavon-interface-integration-tests\target\mctf\latest",
    [string]$OutputPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\flow_reports"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  REPORT ANALYZER AGENT v4.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure output folder exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# ============================================================
# STEP 1: Parse Flow (MCTF) Test Cases
# ============================================================

Write-Host "STEP 1: Parsing Flow (MCTF) Test Cases..." -ForegroundColor Yellow

$flowIndexPath = "$FlowReportPath\index.html"
$flowTestCases = @()

if (Test-Path $flowIndexPath) {
    $flowContent = Get-Content -Path $flowIndexPath -Raw -Encoding UTF8

    # Extract JSON from: data = // START_JSON_DATA {...} // END_JSON_DATA
    if ($flowContent -match 'data\s*=\s*//\s*START_JSON_DATA\s*([\s\S]*?)//\s*END_JSON_DATA') {
        $flowJsonStr = $Matches[1].Trim()
        try {
            $flowData = $flowJsonStr | ConvertFrom-Json
            Write-Host "  Found $($flowData.entries.Count) entries in Flow index" -ForegroundColor Gray

            foreach ($entry in $flowData.entries) {
                $detailId = $entry.detail
                $detailPath = "$FlowReportPath\detail\$detailId.html"

                $acquirerRequest = ""
                $acquirerResponse = ""

                if (Test-Path $detailPath) {
                    $detailContent = Get-Content -Path $detailPath -Raw -Encoding UTF8

                    if ($detailContent -match 'data\s*=\s*//\s*START_JSON_DATA\s*([\s\S]*?)//\s*END_JSON_DATA') {
                        $detailJsonStr = $Matches[1].Trim()
                        try {
                            $detailData = $detailJsonStr | ConvertFrom-Json

                            # Navigate: root -> children[0] (CONNECTIVITY) -> children[0] (ACQUIRER)
                            if ($detailData.root -and $detailData.root.children -and $detailData.root.children.Count -gt 0) {
                                $connectivityLayer = $detailData.root.children[0]
                                if ($connectivityLayer.children -and $connectivityLayer.children.Count -gt 0) {
                                    $acquirerLayer = $connectivityLayer.children[0]

                                    # Get expected request
                                    if ($acquirerLayer.request.asserted.expect) {
                                        $acquirerRequest = $acquirerLayer.request.asserted.expect
                                    } elseif ($acquirerLayer.request.full.expect) {
                                        $acquirerRequest = $acquirerLayer.request.full.expect
                                    }

                                    # Get expected response
                                    if ($acquirerLayer.response.asserted.expect) {
                                        $acquirerResponse = $acquirerLayer.response.asserted.expect
                                    } elseif ($acquirerLayer.response.full.expect) {
                                        $acquirerResponse = $acquirerLayer.response.full.expect
                                    }
                                }
                            }
                        } catch {
                            Write-Host "    Warning: Failed to parse detail for $detailId : $_" -ForegroundColor Yellow
                        }
                    }
                }

                $flowTestCases += [PSCustomObject]@{
                    Description = $entry.description
                    DetailId = $detailId
                    Tags = ($entry.tags -join ",")
                    AcquirerRequest = $acquirerRequest
                    AcquirerResponse = $acquirerResponse
                }
            }
        } catch {
            Write-Host "  ERROR: Failed to parse Flow index: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  ERROR: Could not find JSON data in Flow index.html" -ForegroundColor Red
    }
} else {
    Write-Host "  ERROR: Flow index.html not found at $flowIndexPath" -ForegroundColor Red
}

Write-Host "  Parsed $($flowTestCases.Count) Flow test cases" -ForegroundColor Green
$flowWithReq = ($flowTestCases | Where-Object { $_.AcquirerRequest }).Count
$flowWithResp = ($flowTestCases | Where-Object { $_.AcquirerResponse }).Count
Write-Host "    - With Acquirer Request: $flowWithReq" -ForegroundColor Gray
Write-Host "    - With Acquirer Response: $flowWithResp" -ForegroundColor Gray

# ============================================================
# STEP 2: Parse ATF Test Cases
# ============================================================

Write-Host ""
Write-Host "STEP 2: Parsing ATF Test Cases..." -ForegroundColor Yellow

$atfIndexPath = "$AtfReportPath\index.html"
$atfTestCases = @()

if (Test-Path $atfIndexPath) {
    $atfContent = Get-Content -Path $atfIndexPath -Raw -Encoding UTF8

    # Extract JSON - handle the specific ATF format with tabs and newlines
    # Pattern: index = \n\t// DATA START \n {...} \n// DATA END
    if ($atfContent -match '(?s)index\s*=\s*[\r\n\t]*//\s*DATA\s+START\s*[\r\n]+(.*?)[\r\n]+//\s*DATA\s+END') {
        $atfJsonStr = $Matches[1].Trim()
        try {
            $atfData = $atfJsonStr | ConvertFrom-Json
            Write-Host "  Found $($atfData.entries.Count) entries in ATF index" -ForegroundColor Gray

            foreach ($entry in $atfData.entries) {
                $pathId = $entry.path
                $txnPath = "$AtfReportPath\txn\$pathId.html"

                $acquirerRequest = ""
                $acquirerResponse = ""

                if (Test-Path $txnPath) {
                    $txnContent = Get-Content -Path $txnPath -Raw -Encoding UTF8

                    # Use regex to extract transmissions since JSON has escape sequence issues
                    # Pattern for ACQUIRER_SERVICE -> ACQUIRER Request expected.full_text
                    $reqPattern = '(?s)"transmitter"\s*:\s*"ACQUIRER_SERVICE".*?"receiver"\s*:\s*"ACQUIRER".*?"type"\s*:\s*"Request".*?"full_text"\s*:\s*"((?:[^"\\]|\\.)*)"\s*,'
                    if ($txnContent -match $reqPattern) {
                        $acquirerRequest = $Matches[1] -replace '\\n', "`n" -replace '\\"', '"'
                    }

                    # Pattern for ACQUIRER -> ACQUIRER_SERVICE Response expected.full_text
                    $respPattern = '(?s)"transmitter"\s*:\s*"ACQUIRER".*?"receiver"\s*:\s*"ACQUIRER_SERVICE".*?"type"\s*:\s*"Response".*?"full_text"\s*:\s*"((?:[^"\\]|\\.)*)"\s*,'
                    if ($txnContent -match $respPattern) {
                        $acquirerResponse = $Matches[1] -replace '\\n', "`n" -replace '\\"', '"'
                    }
                } else {
                    Write-Host "    Warning: txn file not found: $txnPath" -ForegroundColor Yellow
                }

                $atfTestCases += [PSCustomObject]@{
                    Name = $entry.name
                    PathId = $pathId
                    Tags = ($entry.tags | ConvertTo-Json -Compress)
                    AcquirerRequest = $acquirerRequest
                    AcquirerResponse = $acquirerResponse
                }
            }
        } catch {
            Write-Host "  ERROR: Failed to parse ATF index: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  ERROR: Could not find DATA START/END in ATF index.html" -ForegroundColor Red
    }
} else {
    Write-Host "  ERROR: ATF index.html not found at $atfIndexPath" -ForegroundColor Red
}

Write-Host "  Parsed $($atfTestCases.Count) ATF test cases" -ForegroundColor Green
$atfWithReq = ($atfTestCases | Where-Object { $_.AcquirerRequest }).Count
$atfWithResp = ($atfTestCases | Where-Object { $_.AcquirerResponse }).Count
Write-Host "    - With Acquirer Request: $atfWithReq" -ForegroundColor Gray
Write-Host "    - With Acquirer Response: $atfWithResp" -ForegroundColor Gray

# ============================================================
# Save CSV Files
# ============================================================

Write-Host ""
Write-Host "Saving CSV files..." -ForegroundColor Yellow

# Save Flow test cases
$flowCsvPath = "$OutputPath\flow_testcases.csv"
$flowTestCases | Select-Object Description, DetailId, @{N='HasAcquirerRequest';E={if($_.AcquirerRequest){'YES'}else{'NO'}}}, @{N='HasAcquirerResponse';E={if($_.AcquirerResponse){'YES'}else{'NO'}}} | Export-Csv -Path $flowCsvPath -NoTypeInformation
Write-Host "  Saved: $flowCsvPath" -ForegroundColor Green

# Save ATF test cases
$atfCsvPath = "$OutputPath\atf_testcases.csv"
$atfTestCases | Select-Object Name, PathId, @{N='HasAcquirerRequest';E={if($_.AcquirerRequest){'YES'}else{'NO'}}}, @{N='HasAcquirerResponse';E={if($_.AcquirerResponse){'YES'}else{'NO'}}} | Export-Csv -Path $atfCsvPath -NoTypeInformation
Write-Host "  Saved: $atfCsvPath" -ForegroundColor Green

# ============================================================
# STEP 3: Match and Compare Test Cases
# ============================================================

Write-Host ""
Write-Host "STEP 3: Matching and Comparing Test Cases..." -ForegroundColor Yellow

# Normalize test name for matching
function Get-NormalizedName {
    param([string]$Name)
    $normalized = $Name.Trim()
    $normalized = $normalized -replace '\bMOTO\b', 'MAIL_ORDER'
    $normalized = $normalized -replace '\bTELEPHONE_ORDER\b', 'MAIL_ORDER'
    $normalized = $normalized -replace '\s+', ' '
    return $normalized
}

# Parse ISO8583 fields from message text
function Parse-Iso8583Fields {
    param([string]$MessageText)

    $fields = @{}
    if (-not $MessageText) { return $fields }

    # Try to extract Fields JSON section (ATF format: "Fields : {...}")
    # Or direct JSON format (Flow format: "{...}")
    $jsonStr = $null

    if ($MessageText -match 'Fields\s*:\s*(\{[\s\S]*\})') {
        $jsonStr = $Matches[1]
    } elseif ($MessageText -match '(\{\s*"messageType"[\s\S]*)') {
        # Flow format - JSON starts with { and contains messageType
        $jsonStr = $Matches[1]
    }

    if ($jsonStr) {
        try {
            $parsed = $jsonStr | ConvertFrom-Json

            # Extract messageType
            if ($parsed.messageType) {
                $fields['messageTypeId'] = $parsed.messageType.messageTypeId
            }

            # Extract messageBody fields
            if ($parsed.messageBody) {
                $parsed.messageBody.PSObject.Properties | ForEach-Object {
                    $key = $_.Name
                    $value = $_.Value

                    if ($value -is [PSCustomObject]) {
                        # Nested object (e.g., posDataCode, additionalPrivateData)
                        $value.PSObject.Properties | ForEach-Object {
                            $subKey = $_.Name
                            $subValue = $_.Value
                            $fields["$key.$subKey"] = $subValue
                        }
                    } else {
                        $fields[$key] = $value
                    }
                }
            }
        } catch {
            # Fallback: simple regex parsing
        }
    }

    return $fields
}

# Create lookup for ATF test cases
$atfByNormalizedName = @{}
foreach ($tc in $atfTestCases) {
    $normalizedName = Get-NormalizedName -Name $tc.Name
    $atfByNormalizedName[$normalizedName] = $tc
}

# Match Flow test cases to ATF
$matchedPairs = @()
$unmatchedFlow = @()

foreach ($flowTc in $flowTestCases) {
    $normalizedName = Get-NormalizedName -Name $flowTc.Description
    if ($atfByNormalizedName.ContainsKey($normalizedName)) {
        $matchedPairs += [PSCustomObject]@{
            FlowTest = $flowTc
            AtfTest = $atfByNormalizedName[$normalizedName]
            NormalizedName = $normalizedName
        }
    } else {
        $unmatchedFlow += $flowTc
    }
}

Write-Host "  Matched: $($matchedPairs.Count) test pairs" -ForegroundColor Green
Write-Host "  Unmatched Flow tests: $($unmatchedFlow.Count)" -ForegroundColor Yellow

# ============================================================
# Generate Detailed Comparison Report
# ============================================================

Write-Host ""
Write-Host "Generating Detailed Comparison Report..." -ForegroundColor Yellow

$reportLines = @()
$reportLines += "# ATF vs Flow - Detailed Field Comparison Report"
$reportLines += ""
$reportLines += "**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportLines += "**Report Version:** 4.0"
$reportLines += ""
$reportLines += "---"
$reportLines += ""
$reportLines += "## Summary"
$reportLines += ""
$reportLines += "| Metric | Count |"
$reportLines += "|--------|-------|"
$reportLines += "| Flow Test Cases | $($flowTestCases.Count) |"
$reportLines += "| ATF Test Cases | $($atfTestCases.Count) |"
$reportLines += "| Matched Test Pairs | $($matchedPairs.Count) |"
$reportLines += "| Unmatched Flow Tests | $($unmatchedFlow.Count) |"
$reportLines += ""
$reportLines += "---"
$reportLines += ""
$reportLines += "## All Matched Test Cases"
$reportLines += ""
$reportLines += "| # | Test Name | ATF Req | Flow Req | ATF Resp | Flow Resp |"
$reportLines += "|---|-----------|---------|----------|----------|-----------|"

$idx = 1
foreach ($pair in $matchedPairs) {
    $shortName = if ($pair.NormalizedName.Length -gt 60) { $pair.NormalizedName.Substring(0, 57) + "..." } else { $pair.NormalizedName }
    $atfReq = if ($pair.AtfTest.AcquirerRequest) { "[YES]" } else { "[NO]" }
    $flowReq = if ($pair.FlowTest.AcquirerRequest) { "[YES]" } else { "[NO]" }
    $atfResp = if ($pair.AtfTest.AcquirerResponse) { "[YES]" } else { "[NO]" }
    $flowResp = if ($pair.FlowTest.AcquirerResponse) { "[YES]" } else { "[NO]" }
    $reportLines += "| $idx | $shortName | $atfReq | $flowReq | $atfResp | $flowResp |"
    $idx++
}

$reportLines += ""
$reportLines += "---"
$reportLines += ""
$reportLines += "## Detailed Field Comparison for Each Test Case"

# Compare ALL matched pairs
$testIndex = 1
foreach ($pair in $matchedPairs) {
    $reportLines += ""
    $reportLines += "---"
    $reportLines += ""
    $reportLines += "## Test Case $testIndex : $($pair.NormalizedName)"
    $reportLines += ""
    $reportLines += "**ATF Test:** $($pair.AtfTest.Name)"
    $reportLines += ""
    $reportLines += "**Flow Test:** $($pair.FlowTest.Description)"
    $reportLines += ""

    # Parse fields
    $atfReqFields = Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerRequest
    $flowReqFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerRequest
    $atfRespFields = Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerResponse
    $flowRespFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerResponse

    # ACQUIRER REQUEST Comparison
    $reportLines += "### ACQUIRER REQUEST - Field Comparison"
    $reportLines += ""

    if ($atfReqFields.Count -eq 0 -and $flowReqFields.Count -eq 0) {
        $reportLines += "*No fields parsed - showing raw data*"
        $reportLines += ""
        $reportLines += "**ATF Request:**"
        $reportLines += '```'
        if ($pair.AtfTest.AcquirerRequest) {
            $reqLen = $pair.AtfTest.AcquirerRequest.Length
            $preview = $pair.AtfTest.AcquirerRequest.Substring(0, [Math]::Min(1000, $reqLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**Flow Request:**"
        $reportLines += '```'
        if ($pair.FlowTest.AcquirerRequest) {
            $reqLen = $pair.FlowTest.AcquirerRequest.Length
            $preview = $pair.FlowTest.AcquirerRequest.Substring(0, [Math]::Min(1000, $reqLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
    } else {
        $reportLines += "| Field | ATF Value | Flow Value | Status |"
        $reportLines += "|-------|-----------|------------|--------|"

        # Get all unique field names
        $allFields = @($atfReqFields.Keys) + @($flowReqFields.Keys) | Sort-Object -Unique

        foreach ($field in $allFields) {
            $atfVal = if ($atfReqFields.ContainsKey($field)) { "$($atfReqFields[$field])" } else { "-" }
            $flowVal = if ($flowReqFields.ContainsKey($field)) { "$($flowReqFields[$field])" } else { "-" }

            # Truncate long values
            $atfValDisplay = if ($atfVal.Length -gt 30) { $atfVal.Substring(0, 27) + "..." } else { $atfVal }
            $flowValDisplay = if ($flowVal.Length -gt 30) { $flowVal.Substring(0, 27) + "..." } else { $flowVal }

            # Determine status
            if ($atfVal -eq "-") {
                $status = "[MISSING IN ATF]"
            } elseif ($flowVal -eq "-") {
                $status = "[MISSING IN FLOW]"
            } elseif ($atfVal -eq $flowVal) {
                $status = "[MATCH]"
            } elseif ($field -match 'systemTrace|localDateTime|reconciliationDate|referenceNumber') {
                $status = "[DYNAMIC]"
            } else {
                $status = "[DIFFERENT]"
            }

            $reportLines += "| $field | $atfValDisplay | $flowValDisplay | $status |"
        }
    }

    $reportLines += ""

    # ACQUIRER RESPONSE Comparison
    $reportLines += "### ACQUIRER RESPONSE - Field Comparison"
    $reportLines += ""

    if ($atfRespFields.Count -eq 0 -and $flowRespFields.Count -eq 0) {
        $reportLines += "*No fields parsed - showing raw data*"
        $reportLines += ""
        $reportLines += "**ATF Response:**"
        $reportLines += '```'
        if ($pair.AtfTest.AcquirerResponse) {
            $respLen = $pair.AtfTest.AcquirerResponse.Length
            $preview = $pair.AtfTest.AcquirerResponse.Substring(0, [Math]::Min(1000, $respLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**Flow Response:**"
        $reportLines += '```'
        if ($pair.FlowTest.AcquirerResponse) {
            $respLen = $pair.FlowTest.AcquirerResponse.Length
            $preview = $pair.FlowTest.AcquirerResponse.Substring(0, [Math]::Min(1000, $respLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
    } else {
        $reportLines += "| Field | ATF Value | Flow Value | Status |"
        $reportLines += "|-------|-----------|------------|--------|"

        $allRespFields = @($atfRespFields.Keys) + @($flowRespFields.Keys) | Sort-Object -Unique

        foreach ($field in $allRespFields) {
            $atfVal = if ($atfRespFields.ContainsKey($field)) { "$($atfRespFields[$field])" } else { "-" }
            $flowVal = if ($flowRespFields.ContainsKey($field)) { "$($flowRespFields[$field])" } else { "-" }

            $atfValDisplay = if ($atfVal.Length -gt 30) { $atfVal.Substring(0, 27) + "..." } else { $atfVal }
            $flowValDisplay = if ($flowVal.Length -gt 30) { $flowVal.Substring(0, 27) + "..." } else { $flowVal }

            if ($atfVal -eq "-") {
                $status = "[MISSING IN ATF]"
            } elseif ($flowVal -eq "-") {
                $status = "[MISSING IN FLOW]"
            } elseif ($atfVal -eq $flowVal) {
                $status = "[MATCH]"
            } elseif ($field -match 'systemTrace|localDateTime|reconciliationDate|referenceNumber|cardSchemeData') {
                $status = "[DYNAMIC]"
            } else {
                $status = "[DIFFERENT]"
            }

            $reportLines += "| $field | $atfValDisplay | $flowValDisplay | $status |"
        }
    }

    $testIndex++
}

# Add unmatched Flow tests section
if ($unmatchedFlow.Count -gt 0) {
    $reportLines += ""
    $reportLines += "---"
    $reportLines += ""
    $reportLines += "## Unmatched Flow Tests (No ATF Equivalent)"
    $reportLines += ""
    $reportLines += "| # | Flow Test Name |"
    $reportLines += "|---|----------------|"
    $idx = 1
    foreach ($tc in $unmatchedFlow) {
        $reportLines += "| $idx | $($tc.Description) |"
        $idx++
    }
}

# Save report
$reportPath = "$OutputPath\comparison-report.md"
$reportLines -join "`n" | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "  Saved: $reportPath" -ForegroundColor Green

# ============================================================
# Generate JSON Gap Report
# ============================================================

Write-Host ""
Write-Host "Generating JSON Gap Report..." -ForegroundColor Yellow

$gapReport = @{
    reportVersion = "4.0"
    generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    summary = @{
        flowTestCases = $flowTestCases.Count
        atfTestCases = $atfTestCases.Count
        matchedPairs = $matchedPairs.Count
        unmatchedFlowTests = $unmatchedFlow.Count
    }
    matchedTestCases = @()
}

foreach ($pair in $matchedPairs) {
    $gapReport.matchedTestCases += @{
        flowTestName = $pair.FlowTest.Description
        flowDetailId = $pair.FlowTest.DetailId
        atfTestName = $pair.AtfTest.Name
        atfPathId = $pair.AtfTest.PathId
        flowAcquirerRequest = $pair.FlowTest.AcquirerRequest
        flowAcquirerResponse = $pair.FlowTest.AcquirerResponse
        atfAcquirerRequest = $pair.AtfTest.AcquirerRequest
        atfAcquirerResponse = $pair.AtfTest.AcquirerResponse
    }
}

$jsonPath = "$OutputPath\test-comparison-gaps.json"
$gapReport | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $jsonPath -Encoding UTF8
Write-Host "  Saved: $jsonPath" -ForegroundColor Green

# ============================================================
# Complete
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  REPORT ANALYZER AGENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output Files:" -ForegroundColor Yellow
Write-Host "  - $flowCsvPath" -ForegroundColor White
Write-Host "  - $atfCsvPath" -ForegroundColor White
Write-Host "  - $reportPath" -ForegroundColor White
Write-Host "  - $jsonPath" -ForegroundColor White
