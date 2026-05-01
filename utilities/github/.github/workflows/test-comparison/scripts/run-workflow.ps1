<#
.SYNOPSIS
    Main Workflow Runner for Test Comparison

.DESCRIPTION
    Orchestrates the complete test comparison workflow:
    1. Parse ATF and Flow reports
    2. Match test cases
    3. Compare fields
    4. Generate comparison report

.PARAMETER AtfPath
    Path to ATF report folder (default from config)

.PARAMETER FlowPath
    Path to Flow report folder (default from config)

.PARAMETER OutputPath
    Path to output reports folder (default from config)

.EXAMPLE
    .\run-workflow.ps1
    .\run-workflow.ps1 -AtfPath "C:\path\to\atf" -FlowPath "C:\path\to\flow"
#>

param(
    [string]$AtfPath,
    [string]$FlowPath,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  TEST COMPARISON WORKFLOW v1.0.0" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Load configuration
$configPath = Join-Path $PSScriptRoot "..\config\workflow-config.yaml"
if (Test-Path $configPath) {
    Write-Host "Loading configuration from: $configPath" -ForegroundColor Gray
    # Note: For full YAML support, use powershell-yaml module
    # For now, use default paths
}

# Set default paths if not provided
# Note: These paths assume execution from .github/workflows/test-comparison/scripts/
# Adjust based on your project structure
if (-not $AtfPath) {
    # ATF reports are in the acqelavons2aservice project
    $AtfPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice\elavon-integration-tests\target\atf\latest"

    # Fallback: Try relative path from current project
    if (-not (Test-Path $AtfPath)) {
        $AtfPath = Join-Path $PSScriptRoot "..\..\..\..\target\atf\latest"
    }
}
if (-not $FlowPath) {
    # Flow reports are in lib-elavon-interface-integration-tests module within this project
    $FlowPath = Join-Path $PSScriptRoot "..\..\..\..\lib-elavon-interface-integration-tests\target\mctf\latest"

    # Resolve wildcard path
    $resolvedFlowPaths = Resolve-Path $FlowPath -ErrorAction SilentlyContinue
    if ($resolvedFlowPaths) {
        $FlowPath = $resolvedFlowPaths | Select-Object -First 1 -ExpandProperty Path
    } else {
        # Fallback: Use direct relative path
        $FlowPath = Join-Path $PSScriptRoot "..\..\..\..\target\mctf\latest"
    }
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $PSScriptRoot "..\reports"
}

Write-Host "ATF Path: $AtfPath" -ForegroundColor Yellow
Write-Host "Flow Path: $FlowPath" -ForegroundColor Yellow
Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Ensure output folder exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# ============================================================
# STEP 1: Run Report Analyzer
# ============================================================

Write-Host "STEP 1: Running Report Analyzer..." -ForegroundColor Green
$analyzerScript = Join-Path $PSScriptRoot "report-analyzer.ps1"

if (Test-Path $analyzerScript) {
    & $analyzerScript -AtfReportPath $AtfPath -FlowReportPath $FlowPath -OutputPath $OutputPath
} else {
    Write-Host "  ERROR: report-analyzer.ps1 not found at $analyzerScript" -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 2: Validate Output
# ============================================================

Write-Host ""
Write-Host "STEP 2: Validating Output..." -ForegroundColor Green

$expectedFiles = @(
    "comparison-report.md",
    "atf_testcases.csv",
    "flow_testcases.csv",
    "test-comparison-gaps.json"
)

$allFilesExist = $true
foreach ($file in $expectedFiles) {
    $filePath = Join-Path $OutputPath $file
    if (Test-Path $filePath) {
        $fileSize = (Get-Item $filePath).Length
        Write-Host "  [OK] $file ($fileSize bytes)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

# ============================================================
# STEP 3: Generate Summary
# ============================================================

Write-Host ""
Write-Host "STEP 3: Generating Summary..." -ForegroundColor Green

$summaryPath = Join-Path $OutputPath "summary.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$summary = @"
Test Comparison Workflow Summary
================================
Generated: $timestamp

Input Paths:
- ATF Report: $AtfPath
- Flow Report: $FlowPath

Output Files:
"@

foreach ($file in $expectedFiles) {
    $filePath = Join-Path $OutputPath $file
    if (Test-Path $filePath) {
        $fileSize = (Get-Item $filePath).Length
        $summary += "`n- $file ($fileSize bytes)"
    }
}

$summary += "`n`nWorkflow completed successfully."

$summary | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "  Saved: $summaryPath" -ForegroundColor Green

# ============================================================
# Complete
# ============================================================

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  WORKFLOW COMPLETE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output Location: $OutputPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Review comparison-report.md for detailed comparison" -ForegroundColor Gray
Write-Host "  2. Check test-comparison-gaps.json for machine-readable data" -ForegroundColor Gray
Write-Host "  3. Use AI agent to apply fixes based on comparison" -ForegroundColor Gray
