<#
.SYNOPSIS
    Report Analyzer Agent v6.0 - Analyzes ATF and Flow test reports

.DESCRIPTION
    Step 1: Parse Flow (MCTF) index.html and detail files for acquirer req/resp (both expected and actual)
    Step 2: Parse ATF index.html and txn files for acquirer req/resp (both expected and actual)
    Step 3: Compare and generate detailed 6-column field-by-field comparison report

.NOTES
    Version: 6.0
    Enhanced: Now captures both expected and actual acquirer request/response from BOTH ATF and Flow reports
#>

param(
    [string]$AtfReportPath = "..\..\..\..\target\atf\latest",
    [string]$FlowReportPath = "..\..\..\..\target\mctf\latest",
    [string]$OutputPath = "..\reports"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  REPORT ANALYZER AGENT v6.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure output folder exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Load configuration
$configPath = "$PSScriptRoot\..\config\workflow-config.yaml"
$config = @{}
$ignoreFields = @("Hex", "bytes", "expectBytes", "actualBytes", "header.*")  # Default ignore patterns

if (Test-Path $configPath) {
    try {
        # Try to load YAML if module is available
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $configContent = Get-Content -Path $configPath -Raw -Encoding UTF8
            $config = $configContent | ConvertFrom-Yaml
            Write-Host "  Loaded configuration from: $configPath" -ForegroundColor Gray
        } else {
            Write-Host "  PowerShell-YAML module not available, using default ignore patterns" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Warning: Could not load config from $configPath - $_" -ForegroundColor Yellow
        Write-Host "  Using default ignore patterns" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Config file not found at $configPath, using default ignore patterns" -ForegroundColor Yellow
}

# Extract ignore fields from config or use defaults
if ($config.comparison -and $config.comparison.ignore_fields) {
    $ignoreFields = $config.comparison.ignore_fields
}

Write-Host "  Will ignore $($ignoreFields.Count) field patterns: $($ignoreFields -join ', ')" -ForegroundColor Gray

# Function to check if field should be ignored
function ShouldIgnoreField {
    param([string]$fieldName)

    foreach ($pattern in $ignoreFields) {
        if ($fieldName -like $pattern) {
            return $true
        }
    }
    return $false
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
                $acquirerRequestActual = ""
                $acquirerResponseActual = ""

                if (Test-Path $detailPath) {
                    $detailContent = Get-Content -Path $detailPath -Raw -Encoding UTF8

                    if ($detailContent -match 'data\s*=\s*//\s*START_JSON_DATA\s*([\s\S]*?)//\s*END_JSON_DATA') {
                        $detailJsonStr = $Matches[1].Trim()
                        try {
                            $detailData = $detailJsonStr | ConvertFrom-Json

                            # Recursively find the deepest leaf layer (ACQUIRER node)
                            # Chase Paymentech: root -> CARD_PAYMENT_CONNECTIVITY -> CONNECTIVITY -> ACQUIRER (3 levels)
                            # Elavon:           root -> CONNECTIVITY -> ACQUIRER (2 levels)
                            function Find-AcquirerLayer {
                                param($Node)
                                if ($Node -eq $null) { return $null }
                                if ($Node.children -and $Node.children.Count -gt 0) {
                                    foreach ($child in $Node.children) {
                                        # Leaf node with request/response = ACQUIRER layer
                                        if ($child.PSObject.Properties.Name -contains "request" -and
                                            $child.PSObject.Properties.Name -contains "response" -and
                                            ($child.children -eq $null -or $child.children.Count -eq 0)) {
                                            return $child
                                        }
                                        $found = Find-AcquirerLayer -Node $child
                                        if ($found) { return $found }
                                    }
                                }
                                return $null
                            }

                            $acquirerLayer = $null
                            if ($detailData.root) {
                                $acquirerLayer = Find-AcquirerLayer -Node $detailData.root
                            }

                            if ($acquirerLayer) {
                                # IMPORTANT: Use full.expect/full.actual as PRIMARY source - it has ALL fields.
                                # The asserted section only contains the subset of fields the test explicitly
                                # asserts against, so many fields (expDate, date, merchantOrderNumber,
                                # accountNumber in response etc.) appear "MISSING IN FLOW" if we use asserted.
                                # Fall back to asserted only when full is not available.

                                # Get expected request - prefer full over asserted
                                if ($acquirerLayer.request.full.expect) {
                                    $acquirerRequest = $acquirerLayer.request.full.expect
                                } elseif ($acquirerLayer.request.asserted.expect) {
                                    $acquirerRequest = $acquirerLayer.request.asserted.expect
                                }

                                # Get actual request - prefer full over asserted
                                if ($acquirerLayer.request.full.actual) {
                                    $acquirerRequestActual = $acquirerLayer.request.full.actual
                                } elseif ($acquirerLayer.request.asserted.actual) {
                                    $acquirerRequestActual = $acquirerLayer.request.asserted.actual
                                }

                                # Get expected response - prefer full over asserted
                                if ($acquirerLayer.response.full.expect) {
                                    $acquirerResponse = $acquirerLayer.response.full.expect
                                } elseif ($acquirerLayer.response.asserted.expect) {
                                    $acquirerResponse = $acquirerLayer.response.asserted.expect
                                }

                                # Get actual response - prefer full over asserted
                                if ($acquirerLayer.response.full.actual) {
                                    $acquirerResponseActual = $acquirerLayer.response.full.actual
                                } elseif ($acquirerLayer.response.asserted.actual) {
                                    $acquirerResponseActual = $acquirerLayer.response.asserted.actual
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
                    AcquirerRequestExpected = $acquirerRequest
                    AcquirerRequestActual = $acquirerRequestActual
                    AcquirerResponseExpected = $acquirerResponse
                    AcquirerResponseActual = $acquirerResponseActual
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
$flowWithReqExpected = ($flowTestCases | Where-Object { $_.AcquirerRequestExpected }).Count
$flowWithReqActual = ($flowTestCases | Where-Object { $_.AcquirerRequestActual }).Count
$flowWithRespExpected = ($flowTestCases | Where-Object { $_.AcquirerResponseExpected }).Count
$flowWithRespActual = ($flowTestCases | Where-Object { $_.AcquirerResponseActual }).Count
Write-Host "    - With Acquirer Request (Expected): $flowWithReqExpected" -ForegroundColor Gray
Write-Host "    - With Acquirer Request (Actual): $flowWithReqActual" -ForegroundColor Gray
Write-Host "    - With Acquirer Response (Expected): $flowWithRespExpected" -ForegroundColor Gray
Write-Host "    - With Acquirer Response (Actual): $flowWithRespActual" -ForegroundColor Gray

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

                $acquirerRequestExpected = ""
                $acquirerRequestActual = ""
                $acquirerResponseExpected = ""
                $acquirerResponseActual = ""

                if (Test-Path $txnPath) {
                    $txnContent = Get-Content -Path $txnPath -Raw -Encoding UTF8

                    # ATF txn format uses a "transmissions" array with entries like:
                    #   { "transmitter": "ACQUIRER_SERVICE", "receiver": "ACQUIRER", "type": "Request",
                    #     "expected": { "full_text": "...", "actual": { "full_text": "..." } }
                    # The full_text field ends the JSON string with }" so NO trailing comma is required.
                    # We extract the JSON block from within the detail = // DATA START ... // DATA END section.

                    # Extract the full detail JSON from the txn file
                    $txnJson = $null
                    if ($txnContent -match '(?s)detail\s*=\s*[\r\n\t]*//\s*DATA\s+START\s*[\r\n]+(.*?)[\r\n]+//\s*DATA\s+END') {
                        $txnJson = $Matches[1].Trim()
                    }

                    if ($txnJson) {
                        try {
                            # ATF txn HTML files embed raw HTML inside JSON string values (e.g. the
                            # "Test Log" addenda field). The ATF framework escapes HTML comment openers
                            # as `\!` (i.e. "<\!--") to prevent browser interpretation, but `\!` is
                            # NOT a valid JSON escape sequence — only \\ \/ \" \n \r \t \b \f \uXXXX
                            # are legal. PowerShell's ConvertFrom-Json therefore throws
                            # "Unrecognized escape sequence" on these files.
                            # Fix: strip the invalid backslash so `\!` becomes `!` before parsing.
                            $txnJson = $txnJson -replace '\\!', '!'
                            $txnData = $txnJson | ConvertFrom-Json

                            # Find the ACQUIRER_SERVICE -> ACQUIRER Request transmission
                            # NOTE: Do NOT use `| Select-Object -First 1` here — when PowerShell
                            # terminates a pipeline early via Select-Object -First 1, the remaining
                            # unselected items from Where-Object are flushed to stdout, printing the
                            # full raw acquirer gateway interaction JSON (with HTML, base64 bytes, etc.)
                            # to the console. Collect ALL matches into an array first, then take [0].
                            $acqReqMatches = @($txnData.transmissions | Where-Object {
                                $_.transmitter -eq "ACQUIRER_SERVICE" -and $_.receiver -eq "ACQUIRER" -and $_.type -eq "Request"
                            })
                            $acqReqTx = if ($acqReqMatches.Count -gt 0) { $acqReqMatches[0] } else { $null }

                            # Find the ACQUIRER -> ACQUIRER_SERVICE Response transmission
                            # Same array-collect pattern to suppress pipeline stdout leakage.
                            $acqRespMatches = @($txnData.transmissions | Where-Object {
                                $_.transmitter -eq "ACQUIRER" -and $_.receiver -eq "ACQUIRER_SERVICE" -and $_.type -eq "Response"
                            })
                            $acqRespTx = if ($acqRespMatches.Count -gt 0) { $acqRespMatches[0] } else { $null }

                            # Extract request expected (full_text has complete wire message)
                            if ($acqReqTx -and $acqReqTx.expected.full_text) {
                                $acquirerRequestExpected = $acqReqTx.expected.full_text -replace "`r`n","`n" -replace "`r",""
                            }
                            # Extract request actual
                            if ($acqReqTx -and $acqReqTx.actual.full_text) {
                                $acquirerRequestActual = $acqReqTx.actual.full_text -replace "`r`n","`n" -replace "`r",""
                            }
                            # Extract response expected
                            if ($acqRespTx -and $acqRespTx.expected.full_text) {
                                $acquirerResponseExpected = $acqRespTx.expected.full_text -replace "`r`n","`n" -replace "`r",""
                            }
                            # Extract response actual
                            if ($acqRespTx -and $acqRespTx.actual.full_text) {
                                $acquirerResponseActual = $acqRespTx.actual.full_text -replace "`r`n","`n" -replace "`r",""
                            }
                        } catch {
                            # Truncate the exception message to the first line only.
                            # $_ (the full ErrorRecord) embeds the raw ATF txn JSON content
                            # (including embedded HTML, stack traces, test logs) inside the
                            # "Unrecognized escape sequence" parse error — printing $_ raw
                            # floods the console with thousands of lines of noise.
                            $errMsg = $_.Exception.Message -split "`n" | Select-Object -First 1
                            Write-Host "    Warning: Failed to parse txn JSON for $pathId : $errMsg (using regex fallback)" -ForegroundColor Yellow

                            # Fallback: use regex on raw content if JSON parse fails
                            # Pattern without requiring trailing comma - full_text ends JSON string at closing "
                            $reqExpectedPattern = '(?s)"transmitter"\s*:\s*"ACQUIRER_SERVICE"[^}]*?"receiver"\s*:\s*"ACQUIRER"[^}]*?"type"\s*:\s*"Request".*?"expected"\s*:.*?"full_text"\s*:\s*"((?:[^"\\]|\\.)*)"'
                            if ($txnContent -match $reqExpectedPattern) {
                                $acquirerRequestExpected = $Matches[1] -replace '\\r\\n', "`n" -replace '\\r', '' -replace '\\n', "`n" -replace '\\"', '"'
                            }
                            $reqActualPattern = '(?s)"transmitter"\s*:\s*"ACQUIRER_SERVICE"[^}]*?"receiver"\s*:\s*"ACQUIRER"[^}]*?"type"\s*:\s*"Request".*?"actual"\s*:.*?"full_text"\s*:\s*"((?:[^"\\]|\\.)*)"'
                            if ($txnContent -match $reqActualPattern) {
                                $acquirerRequestActual = $Matches[1] -replace '\\r\\n', "`n" -replace '\\r', '' -replace '\\n', "`n" -replace '\\"', '"'
                            }
                            $respExpectedPattern = '(?s)"transmitter"\s*:\s*"ACQUIRER"[^}]*?"receiver"\s*:\s*"ACQUIRER_SERVICE"[^}]*?"type"\s*:\s*"Response".*?"expected"\s*:.*?"full_text"\s*:\s*"((?:[^"\\]|\\.)*)"'
                            if ($txnContent -match $respExpectedPattern) {
                                $acquirerResponseExpected = $Matches[1] -replace '\\r\\n', "`n" -replace '\\r', '' -replace '\\n', "`n" -replace '\\"', '"'
                            }
                            $respActualPattern = '(?s)"transmitter"\s*:\s*"ACQUIRER"[^}]*?"receiver"\s*:\s*"ACQUIRER_SERVICE"[^}]*?"type"\s*:\s*"Response".*?"actual"\s*:.*?"full_text"\s*:\s*"((?:[^"\\]|\\.)*)"'
                            if ($txnContent -match $respActualPattern) {
                                $acquirerResponseActual = $Matches[1] -replace '\\r\\n', "`n" -replace '\\r', '' -replace '\\n', "`n" -replace '\\"', '"'
                            }
                        }
                    } else {
                        Write-Host "    Warning: Could not find DATA START/END in txn file: $txnPath" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "    Warning: txn file not found: $txnPath" -ForegroundColor Yellow
                }

                $atfTestCases += [PSCustomObject]@{
                    Name = $entry.name
                    PathId = $pathId
                    Tags = ($entry.tags | ConvertTo-Json -Compress)
                    AcquirerRequestExpected = $acquirerRequestExpected
                    AcquirerRequestActual = $acquirerRequestActual
                    AcquirerResponseExpected = $acquirerResponseExpected
                    AcquirerResponseActual = $acquirerResponseActual
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
$atfWithReqExpected = ($atfTestCases | Where-Object { $_.AcquirerRequestExpected }).Count
$atfWithReqActual = ($atfTestCases | Where-Object { $_.AcquirerRequestActual }).Count
$atfWithRespExpected = ($atfTestCases | Where-Object { $_.AcquirerResponseExpected }).Count
$atfWithRespActual = ($atfTestCases | Where-Object { $_.AcquirerResponseActual }).Count
Write-Host "    - With Acquirer Request (Expected): $atfWithReqExpected" -ForegroundColor Gray
Write-Host "    - With Acquirer Request (Actual): $atfWithReqActual" -ForegroundColor Gray
Write-Host "    - With Acquirer Response (Expected): $atfWithRespExpected" -ForegroundColor Gray
Write-Host "    - With Acquirer Response (Actual): $atfWithRespActual" -ForegroundColor Gray

# ============================================================
# Save CSV Files
# ============================================================

Write-Host ""
Write-Host "Saving CSV files..." -ForegroundColor Yellow

# Save Flow test cases
$flowCsvPath = "$OutputPath\flow_testcases.csv"
$flowTestCases | Select-Object Description, DetailId, `
    @{N='HasAcquirerRequestExpected';E={if($_.AcquirerRequestExpected){'YES'}else{'NO'}}}, `
    @{N='HasAcquirerRequestActual';E={if($_.AcquirerRequestActual){'YES'}else{'NO'}}}, `
    @{N='HasAcquirerResponseExpected';E={if($_.AcquirerResponseExpected){'YES'}else{'NO'}}}, `
    @{N='HasAcquirerResponseActual';E={if($_.AcquirerResponseActual){'YES'}else{'NO'}}} | Export-Csv -Path $flowCsvPath -NoTypeInformation
Write-Host "  Saved: $flowCsvPath" -ForegroundColor Green

# Save ATF test cases
$atfCsvPath = "$OutputPath\atf_testcases.csv"
$atfTestCases | Select-Object Name, PathId, `
    @{N='HasAcquirerRequestExpected';E={if($_.AcquirerRequestExpected){'YES'}else{'NO'}}}, `
    @{N='HasAcquirerRequestActual';E={if($_.AcquirerRequestActual){'YES'}else{'NO'}}}, `
    @{N='HasAcquirerResponseExpected';E={if($_.AcquirerResponseExpected){'YES'}else{'NO'}}}, `
    @{N='HasAcquirerResponseActual';E={if($_.AcquirerResponseActual){'YES'}else{'NO'}}} | Export-Csv -Path $atfCsvPath -NoTypeInformation
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

# Field alias mapping: ATF field names that were renamed in the Flow implementation.
# Key = ATF field name, Value = equivalent Flow field name.
# When an ATF field is MISSING IN FLOW, we check if it has an alias and re-evaluate.
$fieldAliasMap = @{
    # merchantPaymentGatewayID sub-field renamed between ATF and Flow
    "merchantPaymentGatewayID.merchantPaymentGatewayID" = "merchantPaymentGatewayID.paymentGatewayId"
}

# Resolve field name: given an ATF field, return the Flow equivalent (alias) if one exists
function Get-FlowFieldAlias {
    param([string]$AtfFieldName)
    if ($fieldAliasMap.ContainsKey($AtfFieldName)) {
        return $fieldAliasMap[$AtfFieldName]
    }
    return $AtfFieldName
}

# Detect message format
function Get-MessageFormat {
    param([string]$MessageText)

    if (-not $MessageText) { return "UNKNOWN" }

    # Normalize CRLF to LF for reliable format detection
    # Chase Paymentech ATF uses \r\n which can cause false UNKNOWN detection
    $text = $MessageText -replace "`r`n", "`n" -replace "`r", "`n"

    # ISO8583 format detection
    if ($text -match 'Fields\s*:\s*\{' -or $text -match '\{idx:') {
        return "ISO8583"
    }

    # ISO8583 in pure JSON format (no "Fields :" prefix)
    if ($text -match '"messageType"\s*:\s*\{' -and $text -match '"messageBody"\s*:\s*\{') {
        return "ISO8583"
    }

    # HTTP format detection
    if ($text -match '^(POST|GET|PUT|DELETE|PATCH)\s+' -or $text -match 'HTTP/\d') {
        return "HTTP"
    }

    # XML format detection
    if ($text -match '^\s*<\?xml' -or $text -match '^\s*<[a-zA-Z]') {
        return "XML"
    }

    # JSON format detection (starts with { and is valid-ish JSON)
    # Also handles CRLF-prefixed JSON e.g. Chase Paymentech: {\r\n  "key" : "value"...}
    if ($text -match '^\s*\{') {
        return "JSON"
    }

    return "UNKNOWN"
}

# Parse message fields based on format
function Parse-MessageFields {
    param(
        [string]$MessageText,
        [string]$Format = $null
    )

    $result = @{
        Format = "UNKNOWN"
        Fields = @{}
        Raw = $MessageText
    }

    if (-not $MessageText) { return $result }

    # Auto-detect format if not specified
    if (-not $Format) {
        $Format = Get-MessageFormat -MessageText $MessageText
    }
    $result.Format = $Format

    switch ($Format) {
        "ISO8583" {
            $result.Fields = Parse-Iso8583Message -MessageText $MessageText
        }
        "JSON" {
            $result.Fields = Parse-JsonMessage -MessageText $MessageText
        }
        "HTTP" {
            $result.Fields = Parse-HttpMessage -MessageText $MessageText
        }
        "XML" {
            $result.Fields = Parse-XmlMessage -MessageText $MessageText
        }
        default {
            # Store raw text if format unknown
            $result.Fields = @{ "_raw" = $MessageText.Substring(0, [Math]::Min(500, $MessageText.Length)) }
        }
    }

    return $result
}

# Parse ISO8583 message
function Parse-Iso8583Message {
    param([string]$MessageText)

    $fields = @{}

    # Try to extract Fields JSON section (ATF format: "Fields : {...}")
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
            # Fallback: store error
            $fields["_parseError"] = $_.Exception.Message
        }
    }

    return $fields
}

# Parse JSON message
function Parse-JsonMessage {
    param([string]$MessageText)

    $fields = @{}

    try {
        # Normalize CRLF to LF first - Chase Paymentech ATF messages use \r\n line endings
        # which cause ConvertFrom-Json to fail with "Invalid object passed in, ':' or '}' expected"
        $normalizedText = $MessageText -replace "`r`n", "`n" -replace "`r", "`n"

        # Extract JSON portion (handles HTTP messages and raw JSON bodies)
        if ($normalizedText -match '(?s)(\{.*\})') {
            $jsonStr = $Matches[1].Trim() -replace "`r", ""
            $parsed = $jsonStr | ConvertFrom-Json

            # Flatten nested JSON structure
            Flatten-JsonObject -Obj $parsed -Prefix "" -Fields ([ref]$fields)
        }
    } catch {
        $fields["_parseError"] = $_.Exception.Message
    }

    return $fields
}

# Flatten nested JSON object
function Flatten-JsonObject {
    param(
        $Obj,
        [string]$Prefix,
        [ref]$Fields
    )

    if ($Obj -is [PSCustomObject]) {
        $Obj.PSObject.Properties | ForEach-Object {
            $newPrefix = if ($Prefix) { "$Prefix.$($_.Name)" } else { $_.Name }
            Flatten-JsonObject -Obj $_.Value -Prefix $newPrefix -Fields $Fields
        }
    } elseif ($Obj -is [System.Array]) {
        for ($i = 0; $i -lt $Obj.Count; $i++) {
            $newPrefix = "$Prefix[$i]"
            Flatten-JsonObject -Obj $Obj[$i] -Prefix $newPrefix -Fields $Fields
        }
    } else {
        $Fields.Value[$Prefix] = $Obj
    }
}

# Parse HTTP message (headers + body)
function Parse-HttpMessage {
    param([string]$MessageText)

    $fields = @{}

    # Split headers and body
    $parts = $MessageText -split '\r?\n\r?\n', 2
    $headerSection = $parts[0]
    $bodySection = if ($parts.Count -gt 1) { $parts[1] } else { "" }

    # Parse first line (method/status)
    $lines = $headerSection -split '\r?\n'
    if ($lines.Count -gt 0) {
        $firstLine = $lines[0]
        if ($firstLine -match '^(POST|GET|PUT|DELETE|PATCH)\s+(\S+)') {
            $fields['http.method'] = $Matches[1]
            $fields['http.path'] = $Matches[2]
        } elseif ($firstLine -match 'HTTP/[\d.]+\s+(\d+)') {
            $fields['http.status'] = $Matches[1]
        }
    }

    # Parse headers
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^([^:]+):\s*(.*)') {
            $headerName = $Matches[1].ToLower() -replace '-', '_'
            $fields["header.$headerName"] = $Matches[2]
        }
    }

    # Parse body if JSON
    if ($bodySection -match '^\s*\{') {
        $bodyFields = Parse-JsonMessage -MessageText $bodySection
        foreach ($key in $bodyFields.Keys) {
            $fields["body.$key"] = $bodyFields[$key]
        }
    } else {
        $fields['body._raw'] = $bodySection.Substring(0, [Math]::Min(200, $bodySection.Length))
    }

    return $fields
}

# Parse XML message
function Parse-XmlMessage {
    param([string]$MessageText)

    $fields = @{}

    try {
        [xml]$xmlDoc = $MessageText
        Flatten-XmlNode -Node $xmlDoc.DocumentElement -Prefix "" -Fields ([ref]$fields)
    } catch {
        $fields["_parseError"] = $_.Exception.Message
    }

    return $fields
}

# Flatten XML node
function Flatten-XmlNode {
    param(
        $Node,
        [string]$Prefix,
        [ref]$Fields
    )

    if ($Node -eq $null) { return }

    $currentPrefix = if ($Prefix) { "$Prefix.$($Node.LocalName)" } else { $Node.LocalName }

    # Add attributes
    foreach ($attr in $Node.Attributes) {
        $Fields.Value["$currentPrefix.@$($attr.Name)"] = $attr.Value
    }

    # Check for child elements
    $childElements = $Node.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }

    if ($childElements.Count -gt 0) {
        foreach ($child in $childElements) {
            Flatten-XmlNode -Node $child -Prefix $currentPrefix -Fields $Fields
        }
    } else {
        # Leaf node - add text content
        $textContent = $Node.InnerText
        if ($textContent) {
            $Fields.Value[$currentPrefix] = $textContent
        }
    }
}

# Wrapper function for backward compatibility
function Parse-Iso8583Fields {
    param([string]$MessageText)

    $result = Parse-MessageFields -MessageText $MessageText
    return $result.Fields
}

# Create lookup for ATF test cases
$atfByNormalizedName = @{}
foreach ($tc in $atfTestCases) {
    $normalizedName = Get-NormalizedName -Name $tc.Name
    $atfByNormalizedName[$normalizedName] = $tc
}

# Create pairs for ALL Flow test cases (matched or unmatched)
$allFlowPairs = @()
$matchedPairs = @()
$unmatchedFlow = @()

foreach ($flowTc in $flowTestCases) {
    $normalizedName = Get-NormalizedName -Name $flowTc.Description
    if ($atfByNormalizedName.ContainsKey($normalizedName)) {
        $pair = [PSCustomObject]@{
            FlowTest = $flowTc
            AtfTest = $atfByNormalizedName[$normalizedName]
            NormalizedName = $normalizedName
            HasAtfMatch = $true
        }
        $matchedPairs += $pair
        $allFlowPairs += $pair
    } else {
        $pair = [PSCustomObject]@{
            FlowTest = $flowTc
            AtfTest = $null
            NormalizedName = $normalizedName
            HasAtfMatch = $false
        }
        $unmatchedFlow += $flowTc
        $allFlowPairs += $pair
    }
}

Write-Host "  Matched: $($matchedPairs.Count) test pairs" -ForegroundColor Green
Write-Host "  Unmatched Flow tests: $($unmatchedFlow.Count)" -ForegroundColor Yellow
Write-Host "  Total Flow test cases for comparison: $($allFlowPairs.Count)" -ForegroundColor Cyan

# ============================================================
# Generate Detailed Comparison Report
# ============================================================

Write-Host ""
Write-Host "Generating Detailed Comparison Report..." -ForegroundColor Yellow

$reportLines = @()
$reportLines += "# ATF vs Flow - Detailed Field Comparison Report"
$reportLines += ""
$reportLines += "**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportLines += "**Report Version:** 6.0"
$reportLines += "**Enhancement:** Now includes BOTH expected and actual values from BOTH ATF and Flow test reports for complete 4-way comparison"
$reportLines += ""
$reportLines += "---"
$reportLines += ""
$reportLines += "## Summary"
$reportLines += ""
$reportLines += "| Metric | Count |"
$reportLines += "|--------|-------|"
$reportLines += "| Flow Test Cases (Total) | $($flowTestCases.Count) |"
$reportLines += "| ATF Test Cases | $($atfTestCases.Count) |"
$reportLines += "| Matched Test Pairs | $($matchedPairs.Count) |"
$reportLines += "| Unmatched Flow Tests (No ATF) | $($unmatchedFlow.Count) |"
$reportLines += ""
$reportLines += "---"
$reportLines += ""
$reportLines += "## All Flow Test Cases"
$reportLines += ""
$reportLines += "| # | Test Name | Has ATF Match | ATF Req (Exp) | ATF Req (Act) | ATF Resp (Exp) | ATF Resp (Act) | Flow Req (Exp) | Flow Req (Act) | Flow Resp (Exp) | Flow Resp (Act) |"
$reportLines += "|---|-----------|---------------|---------------|---------------|----------------|----------------|----------------|----------------|-----------------|-----------------|"

$idx = 1
foreach ($pair in $allFlowPairs) {
    $shortName = if ($pair.NormalizedName.Length -gt 60) { $pair.NormalizedName.Substring(0, 57) + "..." } else { $pair.NormalizedName }
    $hasAtfMatch = if ($pair.HasAtfMatch) { "YES" } else { "NO" }
    $atfReqExp = if ($pair.AtfTest -and $pair.AtfTest.AcquirerRequestExpected) { "YES" } else { "-" }
    $atfReqAct = if ($pair.AtfTest -and $pair.AtfTest.AcquirerRequestActual) { "YES" } else { "-" }
    $atfRespExp = if ($pair.AtfTest -and $pair.AtfTest.AcquirerResponseExpected) { "YES" } else { "-" }
    $atfRespAct = if ($pair.AtfTest -and $pair.AtfTest.AcquirerResponseActual) { "YES" } else { "-" }
    $flowReqExp = if ($pair.FlowTest.AcquirerRequestExpected) { "YES" } else { "NO" }
    $flowReqAct = if ($pair.FlowTest.AcquirerRequestActual) { "YES" } else { "NO" }
    $flowRespExp = if ($pair.FlowTest.AcquirerResponseExpected) { "YES" } else { "NO" }
    $flowRespAct = if ($pair.FlowTest.AcquirerResponseActual) { "YES" } else { "NO" }
    $reportLines += "| $idx | $shortName | $hasAtfMatch | $atfReqExp | $atfReqAct | $atfRespExp | $atfRespAct | $flowReqExp | $flowReqAct | $flowRespExp | $flowRespAct |"
    $idx++
}

$reportLines += ""
$reportLines += "---"
$reportLines += ""
$reportLines += "## Detailed Field Comparison for Each Test Case"

# Compare ALL Flow test cases (matched and unmatched)
$testIndex = 1
foreach ($pair in $allFlowPairs) {
    $reportLines += ""
    $reportLines += "---"
    $reportLines += ""
    $atfMatchStatus = if ($pair.HasAtfMatch) { "" } else { " [NO ATF MATCH]" }
    $reportLines += "## Test Case $testIndex : $($pair.NormalizedName)$atfMatchStatus"
    $reportLines += ""
    if ($pair.HasAtfMatch) {
        $reportLines += "**ATF Test:** $($pair.AtfTest.Name)"
    } else {
        $reportLines += "**ATF Test:** *(No matching ATF test found)*"
    }
    $reportLines += ""
    $reportLines += "**Flow Test:** $($pair.FlowTest.Description)"
    $reportLines += ""

    # Parse fields - both expected and actual (handle null AtfTest)
    $atfReqExpectedFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerRequestExpected } else { @{} }
    $atfReqActualFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerRequestActual } else { @{} }
    $flowReqExpectedFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerRequestExpected
    $flowReqActualFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerRequestActual
    $atfRespExpectedFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerResponseExpected } else { @{} }
    $atfRespActualFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerResponseActual } else { @{} }
    $flowRespExpectedFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerResponseExpected
    $flowRespActualFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerResponseActual

    # ACQUIRER REQUEST Comparison
    $reportLines += "### ACQUIRER REQUEST - Field Comparison"
    $reportLines += ""

    if ($atfReqExpectedFields.Count -eq 0 -and $atfReqActualFields.Count -eq 0 -and $flowReqExpectedFields.Count -eq 0 -and $flowReqActualFields.Count -eq 0) {
        $reportLines += "*No fields parsed - showing raw data*"
        $reportLines += ""
        $reportLines += "**ATF Request (Expected):**"
        $reportLines += '```'
        if ($pair.AtfTest -and $pair.AtfTest.AcquirerRequestExpected) {
            $reqLen = $pair.AtfTest.AcquirerRequestExpected.Length
            $preview = $pair.AtfTest.AcquirerRequestExpected.Substring(0, [Math]::Min(1000, $reqLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty or no ATF match)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**ATF Request (Actual):**"
        $reportLines += '```'
        if ($pair.AtfTest -and $pair.AtfTest.AcquirerRequestActual) {
            $reqLen = $pair.AtfTest.AcquirerRequestActual.Length
            $preview = $pair.AtfTest.AcquirerRequestActual.Substring(0, [Math]::Min(1000, $reqLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty or no ATF match)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**Flow Request (Expected):**"
        $reportLines += '```'
        if ($pair.FlowTest.AcquirerRequestExpected) {
            $reqLen = $pair.FlowTest.AcquirerRequestExpected.Length
            $preview = $pair.FlowTest.AcquirerRequestExpected.Substring(0, [Math]::Min(1000, $reqLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**Flow Request (Actual):**"
        $reportLines += '```'
        if ($pair.FlowTest.AcquirerRequestActual) {
            $reqLen = $pair.FlowTest.AcquirerRequestActual.Length
            $preview = $pair.FlowTest.AcquirerRequestActual.Substring(0, [Math]::Min(1000, $reqLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
    } else {
        $reportLines += "| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |"
        $reportLines += "|-------|--------------|------------|---------------|-------------|--------------|-------|"

        # Get all unique field names from all sources
        $allFields = @($atfReqExpectedFields.Keys) + @($atfReqActualFields.Keys) + @($flowReqExpectedFields.Keys) + @($flowReqActualFields.Keys) | Sort-Object -Unique

        foreach ($field in $allFields) {
            if (ShouldIgnoreField -fieldName $field) {
                # Skip ignored fields
                continue
            }

            $atfExpVal = if ($atfReqExpectedFields.ContainsKey($field)) { "$($atfReqExpectedFields[$field])" } else { "-" }
            $atfActVal = if ($atfReqActualFields.ContainsKey($field)) { "$($atfReqActualFields[$field])" } else { "-" }
            $flowExpVal = if ($flowReqExpectedFields.ContainsKey($field)) { "$($flowReqExpectedFields[$field])" } else { "-" }
            $flowActVal = if ($flowReqActualFields.ContainsKey($field)) { "$($flowReqActualFields[$field])" } else { "-" }

            # If Flow is missing this field, check if it exists under an alias (field renamed between ATF and Flow)
            if ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
                $aliasField = Get-FlowFieldAlias -AtfFieldName $field
                if ($aliasField -ne $field) {
                    $aliasFlowExp = if ($flowReqExpectedFields.ContainsKey($aliasField)) { "$($flowReqExpectedFields[$aliasField])" } else { "-" }
                    $aliasFlowAct = if ($flowReqActualFields.ContainsKey($aliasField)) { "$($flowReqActualFields[$aliasField])" } else { "-" }
                    if ($aliasFlowExp -ne "-" -or $aliasFlowAct -ne "-") {
                        $flowExpVal = $aliasFlowExp
                        $flowActVal = $aliasFlowAct
                    }
                }
            }

            # Truncate long values
            $atfExpValDisplay = if ($atfExpVal.Length -gt 30) { $atfExpVal.Substring(0, 27) + "..." } else { $atfExpVal }
            $atfActValDisplay = if ($atfActVal.Length -gt 30) { $atfActVal.Substring(0, 27) + "..." } else { $atfActVal }
            $flowExpValDisplay = if ($flowExpVal.Length -gt 30) { $flowExpVal.Substring(0, 27) + "..." } else { $flowExpVal }
            $flowActValDisplay = if ($flowActVal.Length -gt 30) { $flowActVal.Substring(0, 27) + "..." } else { $flowActVal }

            # Determine match status and notes
            $status = ""
            $notes = ""

            # FLOW MISMATCH: Flow expected != Flow actual (including missing in one but present in other)
            if ($flowExpVal -ne "-" -and $flowActVal -eq "-") {
                $status = "[FLOW MISMATCH]"
                $notes = "Field in Flow Expected but MISSING in Flow Actual"
            } elseif ($flowExpVal -eq "-" -and $flowActVal -ne "-") {
                $status = "[FLOW MISMATCH]"
                $notes = "Field MISSING in Flow Expected but present in Flow Actual"
            } elseif ($flowExpVal -ne $flowActVal -and $flowExpVal -ne "-" -and $flowActVal -ne "-") {
                $status = "[FLOW MISMATCH]"
                $notes = "Flow expected != actual"
            } elseif ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
                $status = "[MISSING IN FLOW]"
                $notes = "Field not present in Flow"
            } elseif ($atfExpVal -eq $atfActVal -and $atfActVal -eq $flowExpVal -and $flowExpVal -eq $flowActVal) {
                $status = "[PERFECT MATCH]"
                $notes = "All 4 values match"
            } elseif ($atfActVal -eq $flowActVal -and $atfActVal -ne "-") {
                $status = "[ACTUAL MATCH]"
                $notes = "Actual values match (expected may differ)"
            } elseif ($atfExpVal -eq $flowExpVal -and $atfExpVal -ne "-") {
                $status = "[EXPECTED MATCH]"
                $notes = "Expected values match (actual may differ)"
            } elseif ($atfExpVal -ne $atfActVal -and $atfExpVal -ne "-" -and $atfActVal -ne "-") {
                $status = "[ATF MISMATCH]"
                $notes = "ATF expected != actual"
            } else {
                $status = "[DIFFERENT]"
                $notes = "Values differ between ATF and Flow"
            }

            $reportLines += "| $field | $atfExpValDisplay | $atfActValDisplay | $flowExpValDisplay | $flowActValDisplay | $status | $notes |"
        }
    }

    $reportLines += ""

    # ACQUIRER RESPONSE Comparison
    $reportLines += "### ACQUIRER RESPONSE - Field Comparison"
    $reportLines += ""

    if ($atfRespExpectedFields.Count -eq 0 -and $atfRespActualFields.Count -eq 0 -and $flowRespExpectedFields.Count -eq 0 -and $flowRespActualFields.Count -eq 0) {
        $reportLines += "*No fields parsed - showing raw data*"
        $reportLines += ""
        $reportLines += "**ATF Response (Expected):**"
        $reportLines += '```'
        if ($pair.AtfTest -and $pair.AtfTest.AcquirerResponseExpected) {
            $respLen = $pair.AtfTest.AcquirerResponseExpected.Length
            $preview = $pair.AtfTest.AcquirerResponseExpected.Substring(0, [Math]::Min(1000, $respLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty or no ATF match)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**ATF Response (Actual):**"
        $reportLines += '```'
        if ($pair.AtfTest -and $pair.AtfTest.AcquirerResponseActual) {
            $respLen = $pair.AtfTest.AcquirerResponseActual.Length
            $preview = $pair.AtfTest.AcquirerResponseActual.Substring(0, [Math]::Min(1000, $respLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty or no ATF match)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**Flow Response (Expected):**"
        $reportLines += '```'
        if ($pair.FlowTest.AcquirerResponseExpected) {
            $respLen = $pair.FlowTest.AcquirerResponseExpected.Length
            $preview = $pair.FlowTest.AcquirerResponseExpected.Substring(0, [Math]::Min(1000, $respLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
        $reportLines += ""
        $reportLines += "**Flow Response (Actual):**"
        $reportLines += '```'
        if ($pair.FlowTest.AcquirerResponseActual) {
            $respLen = $pair.FlowTest.AcquirerResponseActual.Length
            $preview = $pair.FlowTest.AcquirerResponseActual.Substring(0, [Math]::Min(1000, $respLen))
            $reportLines += $preview
        } else {
            $reportLines += "(empty)"
        }
        $reportLines += '```'
    } else {
        $reportLines += "| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |"
        $reportLines += "|-------|--------------|------------|---------------|-------------|--------------|-------|"

        $allRespFields = @($atfRespExpectedFields.Keys) + @($atfRespActualFields.Keys) + @($flowRespExpectedFields.Keys) + @($flowRespActualFields.Keys) | Sort-Object -Unique

        foreach ($field in $allRespFields) {
            if (ShouldIgnoreField -fieldName $field) {
                # Skip ignored fields
                continue
            }
            $atfExpVal = if ($atfRespExpectedFields.ContainsKey($field)) { "$($atfRespExpectedFields[$field])" } else { "-" }
            $atfActVal = if ($atfRespActualFields.ContainsKey($field)) { "$($atfRespActualFields[$field])" } else { "-" }
            $flowExpVal = if ($flowRespExpectedFields.ContainsKey($field)) { "$($flowRespExpectedFields[$field])" } else { "-" }
            $flowActVal = if ($flowRespActualFields.ContainsKey($field)) { "$($flowRespActualFields[$field])" } else { "-" }

            # If Flow is missing this field, check if it exists under an alias (field renamed between ATF and Flow)
            if ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
                $aliasField = Get-FlowFieldAlias -AtfFieldName $field
                if ($aliasField -ne $field) {
                    $aliasFlowExp = if ($flowRespExpectedFields.ContainsKey($aliasField)) { "$($flowRespExpectedFields[$aliasField])" } else { "-" }
                    $aliasFlowAct = if ($flowRespActualFields.ContainsKey($aliasField)) { "$($flowRespActualFields[$aliasField])" } else { "-" }
                    if ($aliasFlowExp -ne "-" -or $aliasFlowAct -ne "-") {
                        $flowExpVal = $aliasFlowExp
                        $flowActVal = $aliasFlowAct
                    }
                }
            }

            # Truncate long values for display
            $atfExpValDisplay = if ($atfExpVal.Length -gt 30) { $atfExpVal.Substring(0, 27) + "..." } else { $atfExpVal }
            $atfActValDisplay = if ($atfActVal.Length -gt 30) { $atfActVal.Substring(0, 27) + "..." } else { $atfActVal }
            $flowExpValDisplay = if ($flowExpVal.Length -gt 30) { $flowExpVal.Substring(0, 27) + "..." } else { $flowExpVal }
            $flowActValDisplay = if ($flowActVal.Length -gt 30) { $flowActVal.Substring(0, 27) + "..." } else { $flowActVal }

            # Determine match status and notes (in priority order)
            $status = ""
            $notes = ""

            # FLOW MISMATCH: Flow expected != Flow actual (including missing in one but present in other)
            if ($flowExpVal -ne "-" -and $flowActVal -eq "-") {
                $status = "[FLOW MISMATCH]"
                $notes = "Field in Flow Expected but MISSING in Flow Actual"
            }
            elseif ($flowExpVal -eq "-" -and $flowActVal -ne "-") {
                $status = "[FLOW MISMATCH]"
                $notes = "Field MISSING in Flow Expected but present in Flow Actual"
            }
            elseif ($flowExpVal -ne $flowActVal -and $flowExpVal -ne "-" -and $flowActVal -ne "-") {
                $status = "[FLOW MISMATCH]"
                $notes = "Flow expected != actual"
            }
            elseif ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
                $status = "[MISSING IN FLOW]"
                $notes = "Field not present in Flow"
            }
            elseif ($atfExpVal -eq $atfActVal -and $atfActVal -eq $flowExpVal -and $flowExpVal -eq $flowActVal) {
                $status = "[PERFECT MATCH]"
                $notes = "All 4 values match"
            }
            elseif ($atfActVal -eq $flowActVal -and $atfActVal -ne "-") {
                $status = "[ACTUAL MATCH]"
                $notes = "Actual values match (expected may differ)"
            }
            elseif ($atfExpVal -eq $flowExpVal -and $atfExpVal -ne "-") {
                $status = "[EXPECTED MATCH]"
                $notes = "Expected values match (actual may differ)"
            }
            elseif ($atfExpVal -ne $atfActVal -and $atfExpVal -ne "-" -and $atfActVal -ne "-") {
                $status = "[ATF MISMATCH]"
                $notes = "ATF expected != actual"
            }
            else {
                $status = "[DIFFERENT]"
                $notes = "Values differ between ATF and Flow"
            }

            $reportLines += "| $field | $atfExpValDisplay | $atfActValDisplay | $flowExpValDisplay | $flowActValDisplay | $status | $notes |"
        }
    }

    $testIndex++
}

# Note: Unmatched Flow tests are now included in the main comparison above with [NO ATF MATCH] label

# Save report
$reportPath = "$OutputPath\comparison-report.md"
$reportLines -join "`n" | Set-Content -Path $reportPath -Encoding ASCII
Write-Host "  Saved: $reportPath" -ForegroundColor Green

# ============================================================
# Generate CSV Comparison Report
# ============================================================

Write-Host ""
Write-Host "Generating CSV Comparison Report..." -ForegroundColor Yellow

$csvRows = @()

# Process ALL Flow test cases (matched and unmatched)
foreach ($pair in $allFlowPairs) {
    $testName = $pair.NormalizedName
    $hasAtfMatch = $pair.HasAtfMatch

    # Parse fields - both expected and actual (handle null AtfTest)
    $atfReqExpectedFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerRequestExpected } else { @{} }
    $atfReqActualFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerRequestActual } else { @{} }
    $flowReqExpectedFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerRequestExpected
    $flowReqActualFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerRequestActual
    $atfRespExpectedFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerResponseExpected } else { @{} }
    $atfRespActualFields = if ($pair.AtfTest) { Parse-Iso8583Fields -MessageText $pair.AtfTest.AcquirerResponseActual } else { @{} }
    $flowRespExpectedFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerResponseExpected
    $flowRespActualFields = Parse-Iso8583Fields -MessageText $pair.FlowTest.AcquirerResponseActual

    # Process ACQUIRER REQUEST fields
    $allReqFields = @($atfReqExpectedFields.Keys) + @($atfReqActualFields.Keys) + @($flowReqExpectedFields.Keys) + @($flowReqActualFields.Keys) | Sort-Object -Unique

    foreach ($field in $allReqFields) {
        if (ShouldIgnoreField -fieldName $field) {
            # Skip ignored fields
            continue
        }

        $atfExpVal = if ($atfReqExpectedFields.ContainsKey($field)) { "$($atfReqExpectedFields[$field])" } else { "-" }
        $atfActVal = if ($atfReqActualFields.ContainsKey($field)) { "$($atfReqActualFields[$field])" } else { "-" }
        $flowExpVal = if ($flowReqExpectedFields.ContainsKey($field)) { "$($flowReqExpectedFields[$field])" } else { "-" }
        $flowActVal = if ($flowReqActualFields.ContainsKey($field)) { "$($flowReqActualFields[$field])" } else { "-" }

        # Alias resolution: check if this ATF field was renamed in Flow
        if ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
            $aliasField = Get-FlowFieldAlias -AtfFieldName $field
            if ($aliasField -ne $field) {
                $af = if ($flowReqExpectedFields.ContainsKey($aliasField)) { "$($flowReqExpectedFields[$aliasField])" } else { "-" }
                $aa = if ($flowReqActualFields.ContainsKey($aliasField)) { "$($flowReqActualFields[$aliasField])" } else { "-" }
                if ($af -ne "-" -or $aa -ne "-") { $flowExpVal = $af; $flowActVal = $aa }
            }
        }

        # Determine match status
        $status = ""
        # FLOW MISMATCH: Flow expected != Flow actual (including missing in one but present in other)
        if ($flowExpVal -ne "-" -and $flowActVal -eq "-") {
            $status = "FLOW MISMATCH"
        }
        elseif ($flowExpVal -eq "-" -and $flowActVal -ne "-") {
            $status = "FLOW MISMATCH"
        }
        elseif ($flowExpVal -ne $flowActVal -and $flowExpVal -ne "-" -and $flowActVal -ne "-") {
            $status = "FLOW MISMATCH"
        }
        elseif ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
            $status = "MISSING IN FLOW"
        }
        elseif ($atfExpVal -eq $flowExpVal -and $atfExpVal -ne "-") {
            $status = "EXPECTED MATCH"
        }
        elseif ($atfExpVal -eq "-" -and $atfActVal -eq "-") {
            $status = "MISSING IN ATF"
        }
        elseif ($field -match 'systemTrace|localDateTime|reconciliationDate|referenceNumber|cardSchemeData') {
            $status = "DYNAMIC"
        }
        elseif ($atfExpVal -ne $atfActVal -and $atfExpVal -ne "-" -and $atfActVal -ne "-") {
            $status = "ATF MISMATCH"
        }
        elseif ($atfExpVal -eq $atfActVal -and $atfActVal -eq $flowExpVal -and $flowExpVal -eq $flowActVal) {
            $status = "PERFECT MATCH"
        }
        elseif ($atfActVal -eq $flowActVal -and $atfActVal -ne "-") {
            $status = "ACTUAL MATCH"
        }
        else {
            $status = "DIFFERENT"
        }

        $csvRows += [PSCustomObject]@{
            TestName = $testName
            HasAtfMatch = if ($hasAtfMatch) { "YES" } else { "NO" }
            AtfTestName = if ($pair.AtfTest) { $pair.AtfTest.Name } else { "" }
            FlowTestName = $pair.FlowTest.Description
            MessageType = "ACQUIRER_REQUEST"
            FieldName = $field
            AtfExpected = $atfExpVal
            AtfActual = $atfActVal
            FlowExpected = $flowExpVal
            FlowActual = $flowActVal
            MatchStatus = $status
        }
    }

    # Process ACQUIRER RESPONSE fields
    $allRespFields = @($atfRespExpectedFields.Keys) + @($atfRespActualFields.Keys) + @($flowRespExpectedFields.Keys) + @($flowRespActualFields.Keys) | Sort-Object -Unique

    foreach ($field in $allRespFields) {
        if (ShouldIgnoreField -fieldName $field) {
            # Skip ignored fields
            continue
        }
        $atfExpVal = if ($atfRespExpectedFields.ContainsKey($field)) { "$($atfRespExpectedFields[$field])" } else { "-" }
        $atfActVal = if ($atfRespActualFields.ContainsKey($field)) { "$($atfRespActualFields[$field])" } else { "-" }
        $flowExpVal = if ($flowRespExpectedFields.ContainsKey($field)) { "$($flowRespExpectedFields[$field])" } else { "-" }
        $flowActVal = if ($flowRespActualFields.ContainsKey($field)) { "$($flowRespActualFields[$field])" } else { "-" }

        # Alias resolution: check if this ATF field was renamed in Flow
        if ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
            $aliasField = Get-FlowFieldAlias -AtfFieldName $field
            if ($aliasField -ne $field) {
                $af = if ($flowRespExpectedFields.ContainsKey($aliasField)) { "$($flowRespExpectedFields[$aliasField])" } else { "-" }
                $aa = if ($flowRespActualFields.ContainsKey($aliasField)) { "$($flowRespActualFields[$aliasField])" } else { "-" }
                if ($af -ne "-" -or $aa -ne "-") { $flowExpVal = $af; $flowActVal = $aa }
            }
        }

        # Determine match status (in priority order)
        $status = ""
        # FLOW MISMATCH: Flow expected != Flow actual (including missing in one but present in other)
        if ($flowExpVal -ne "-" -and $flowActVal -eq "-") {
            $status = "FLOW MISMATCH"
        }
        elseif ($flowExpVal -eq "-" -and $flowActVal -ne "-") {
            $status = "FLOW MISMATCH"
        }
        elseif ($flowExpVal -ne $flowActVal -and $flowExpVal -ne "-" -and $flowActVal -ne "-") {
            $status = "FLOW MISMATCH"
        }
        elseif ($flowExpVal -eq "-" -and $flowActVal -eq "-") {
            $status = "MISSING IN FLOW"
        }
        elseif ($atfExpVal -eq $flowExpVal -and $atfExpVal -ne "-") {
            $status = "EXPECTED MATCH"
        }
        elseif ($atfExpVal -eq "-" -and $atfActVal -eq "-") {
            $status = "MISSING IN ATF"
        }
        elseif ($field -match 'systemTrace|localDateTime|reconciliationDate|referenceNumber|cardSchemeData') {
            $status = "DYNAMIC"
        }
        elseif ($atfExpVal -ne $atfActVal -and $atfExpVal -ne "-" -and $atfActVal -ne "-") {
            $status = "ATF MISMATCH"
        }
        elseif ($atfExpVal -eq $atfActVal -and $atfActVal -eq $flowExpVal -and $flowExpVal -eq $flowActVal) {
            $status = "PERFECT MATCH"
        }
        elseif ($atfActVal -eq $flowActVal -and $atfActVal -ne "-") {
            $status = "ACTUAL MATCH"
        }
        else {
            $status = "DIFFERENT"
        }

        $csvRows += [PSCustomObject]@{
            TestName = $testName
            HasAtfMatch = if ($hasAtfMatch) { "YES" } else { "NO" }
            AtfTestName = if ($pair.AtfTest) { $pair.AtfTest.Name } else { "" }
            FlowTestName = $pair.FlowTest.Description
            MessageType = "ACQUIRER_RESPONSE"
            FieldName = $field
            AtfExpected = $atfExpVal
            AtfActual = $atfActVal
            FlowExpected = $flowExpVal
            FlowActual = $flowActVal
            MatchStatus = $status
        }
    }
}

# Export CSV
$csvPath = "$OutputPath\comparison-report.csv"
$csvRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "  Saved: $csvPath" -ForegroundColor Green

# Generate summary CSV
$summaryCsvRows = @()
$statusCounts = $csvRows | Group-Object -Property MatchStatus

foreach ($group in $statusCounts) {
    $summaryCsvRows += [PSCustomObject]@{
        MatchStatus = $group.Name
        Count = $group.Count
    }
}

$summaryCsvRows += [PSCustomObject]@{
    MatchStatus = "TOTAL_FIELDS"
    Count = $csvRows.Count
}

$summaryCsvRows += [PSCustomObject]@{
    MatchStatus = "TOTAL_MATCHED_PAIRS"
    Count = $matchedPairs.Count
}

$summaryCsvRows += [PSCustomObject]@{
    MatchStatus = "TOTAL_FLOW_TEST_CASES"
    Count = $allFlowPairs.Count
}

$summaryCsvPath = "$OutputPath\comparison-report-summary.csv"
$summaryCsvRows | Export-Csv -Path $summaryCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "  Saved: $summaryCsvPath" -ForegroundColor Green

# ============================================================
# Generate JSON Gap Report
# ============================================================

Write-Host ""
Write-Host "Generating JSON Gap Report..." -ForegroundColor Yellow

$gapReport = @{
    reportVersion = "6.1"
    generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    summary = @{
        flowTestCases = $flowTestCases.Count
        atfTestCases = $atfTestCases.Count
        matchedPairs = $matchedPairs.Count
        unmatchedFlowTests = $unmatchedFlow.Count
    }
    allFlowTestCases = @()
}

# Include ALL Flow test cases in JSON report
foreach ($pair in $allFlowPairs) {
    $gapReport.allFlowTestCases += @{
        flowTestName = $pair.FlowTest.Description
        flowDetailId = $pair.FlowTest.DetailId
        hasAtfMatch = $pair.HasAtfMatch
        atfTestName = if ($pair.AtfTest) { $pair.AtfTest.Name } else { $null }
        atfPathId = if ($pair.AtfTest) { $pair.AtfTest.PathId } else { $null }
        atfAcquirerRequestExpected = if ($pair.AtfTest) { $pair.AtfTest.AcquirerRequestExpected } else { $null }
        atfAcquirerRequestActual = if ($pair.AtfTest) { $pair.AtfTest.AcquirerRequestActual } else { $null }
        atfAcquirerResponseExpected = if ($pair.AtfTest) { $pair.AtfTest.AcquirerResponseExpected } else { $null }
        atfAcquirerResponseActual = if ($pair.AtfTest) { $pair.AtfTest.AcquirerResponseActual } else { $null }
        flowAcquirerRequestExpected = $pair.FlowTest.AcquirerRequestExpected
        flowAcquirerRequestActual = $pair.FlowTest.AcquirerRequestActual
        flowAcquirerResponseExpected = $pair.FlowTest.AcquirerResponseExpected
        flowAcquirerResponseActual = $pair.FlowTest.AcquirerResponseActual
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
Write-Host "  - $csvPath" -ForegroundColor White
Write-Host "  - $summaryCsvPath" -ForegroundColor White
Write-Host "  - $jsonPath" -ForegroundColor White
