<#
.SYNOPSIS
    ATF-to-Flow Migration Workflow Orchestrator

.DESCRIPTION
    This script orchestrates the complete migration workflow:
    1. Runs Report Analyzer Agent to generate gap analysis
    2. Runs Test Fixer Agent to apply fixes
    3. Optionally re-runs tests to validate

.PARAMETER AtfProjectPath
    Path to the ATF project root

.PARAMETER FlowProjectPath
    Path to the Flow project root

.PARAMETER SkipAnalysis
    Skip the analysis step (use existing gap report)

.PARAMETER SkipFix
    Skip the fix step (only analyze)

.PARAMETER DryRun
    Run in dry-run mode (no actual changes)

.PARAMETER RunTests
    Run Flow tests after applying fixes

.EXAMPLE
    .\run-migration-workflow.ps1
    .\run-migration-workflow.ps1 -DryRun
    .\run-migration-workflow.ps1 -SkipAnalysis
    .\run-migration-workflow.ps1 -RunTests
#>

param(
    [string]$AtfProjectPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice",
    [string]$FlowProjectPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service",
    [switch]$SkipAnalysis,
    [switch]$SkipFix,
    [switch]$DryRun,
    [switch]$RunTests
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        ATF-to-Flow Migration Workflow Orchestrator           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================
# PHASE 1: Report Analyzer Agent
# ============================================================

if (-not $SkipAnalysis) {
    Write-Host "┌──────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│  PHASE 1: REPORT ANALYZER AGENT                              │" -ForegroundColor Yellow
    Write-Host "└──────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""

    $analyzerScript = "$scriptDir\report-analyzer-agent.ps1"

    if (Test-Path $analyzerScript) {
        & $analyzerScript `
            -AtfReportPath "$AtfProjectPath\elavon-integration-tests\target\atf\latest" `
            -FlowReportPath "$FlowProjectPath\lib-elavon-interface-integration-tests\target\mctf\latest" `
            -OutputPath $FlowProjectPath
    } else {
        Write-Host "ERROR: Report Analyzer Agent script not found: $analyzerScript" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
} else {
    Write-Host "Skipping Phase 1: Report Analyzer Agent (using existing gap report)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================
# PHASE 2: Test Fixer Agent
# ============================================================

if (-not $SkipFix) {
    Write-Host "┌──────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│  PHASE 2: TEST FIXER AGENT                                   │" -ForegroundColor Yellow
    Write-Host "└──────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""

    $fixerScript = "$scriptDir\test-fixer-agent.ps1"

    if (Test-Path $fixerScript) {
        $fixerParams = @{
            GapReportPath = "$FlowProjectPath\test-comparison-gaps.json"
            ProjectPath = $FlowProjectPath
        }

        if ($DryRun) {
            & $fixerScript @fixerParams -DryRun
        } else {
            & $fixerScript @fixerParams
        }
    } else {
        Write-Host "ERROR: Test Fixer Agent script not found: $fixerScript" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
} else {
    Write-Host "Skipping Phase 2: Test Fixer Agent" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================
# PHASE 3: Validation (Optional)
# ============================================================

if ($RunTests -and -not $DryRun) {
    Write-Host "┌──────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│  PHASE 3: VALIDATION                                         │" -ForegroundColor Yellow
    Write-Host "└──────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Running Flow integration tests..." -ForegroundColor White

    Push-Location $FlowProjectPath
    & mvn verify -pl lib-elavon-interface-integration-tests
    $testResult = $LASTEXITCODE
    Pop-Location

    if ($testResult -eq 0) {
        Write-Host ""
        Write-Host "Tests: PASSED" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Tests: FAILED" -ForegroundColor Red
    }

    Write-Host ""
}

# ============================================================
# WORKFLOW COMPLETE
# ============================================================

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              MIGRATION WORKFLOW COMPLETE                      ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "Output Files:" -ForegroundColor White
Write-Host "  - Gap Report:      $FlowProjectPath\test-comparison-gaps.json" -ForegroundColor Gray
Write-Host "  - Detailed Report: $FlowProjectPath\detailed-test-comparison-report.md" -ForegroundColor Gray
Write-Host "  - Fix Summary:     $FlowProjectPath\test-fix-summary.md" -ForegroundColor Gray
Write-Host ""

Write-Host "Workflow Documentation:" -ForegroundColor White
Write-Host "  - $FlowProjectPath\.github\workflows\atf-to-flow-workflow.md" -ForegroundColor Gray
Write-Host "  - $FlowProjectPath\.github\agents\report-analyzer-agent.md" -ForegroundColor Gray
Write-Host "  - $FlowProjectPath\.github\agents\test-fixer-agent.md" -ForegroundColor Gray
Write-Host ""
