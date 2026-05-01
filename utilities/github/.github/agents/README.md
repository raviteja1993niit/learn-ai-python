# ATF-to-Flow Migration Agents

This folder contains the agentic workflow for migrating tests from the legacy ATF (Acquirer Test Framework) to the modern Flow Framework.

## Workflow Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  ATF Reports    │────▶│ Report Analyzer │────▶│  Gap Report     │
│  Flow Reports   │     │     Agent       │     │  (JSON + MD)    │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │  Updated Tests  │◀────│   Test Fixer    │
                        │  (Java files)   │     │     Agent       │
                        └─────────────────┘     └─────────────────┘
```

## Agents

### 1. Report Analyzer Agent
**File:** `report-analyzer-agent.md`

Analyzes test reports from both frameworks and generates gap analysis:
- Parses ATF and Flow index.html files
- Matches test cases using semantic equivalence (MOTO ↔ MAIL_ORDER)
- Extracts ISO8583 acquirer request/response fields
- Compares fields and documents differences
- Generates `test-comparison-gaps.json` and `detailed-test-comparison-report.md`

### 2. Test Fixer Agent
**File:** `test-fixer-agent.md`

Applies fixes to Flow test files based on gap analysis:
- Reads gap report JSON
- Updates configuration values in `BaseElavon.java`
- Adds missing field assertions to test classes
- Validates changes compile correctly
- Generates `test-fix-summary.md`

## Scripts

Located in `scripts/` folder:

| Script | Description |
|--------|-------------|
| `run-migration-workflow.ps1` | Main orchestrator - runs both agents |
| `report-analyzer-agent.ps1` | Report Analyzer Agent implementation |
| `test-fixer-agent.ps1` | Test Fixer Agent implementation |

## Quick Start

### Run Complete Workflow
```powershell
cd .github\agents\scripts
.\run-migration-workflow.ps1
```

### Run in Dry-Run Mode (Preview Only)
```powershell
.\run-migration-workflow.ps1 -DryRun
```

### Run with Test Validation
```powershell
.\run-migration-workflow.ps1 -RunTests
```

### Run Only Analysis (No Fixes)
```powershell
.\run-migration-workflow.ps1 -SkipFix
```

### Run Only Fixes (Use Existing Gap Report)
```powershell
.\run-migration-workflow.ps1 -SkipAnalysis
```

## Output Files

| File | Description |
|------|-------------|
| `test-comparison-gaps.json` | Machine-readable gap analysis |
| `detailed-test-comparison-report.md` | Human-readable comparison report |
| `test-fix-summary.md` | Summary of applied fixes |

## Semantic Mappings

Test names are matched using these equivalences:

| ATF Term | Flow Equivalent |
|----------|-----------------|
| `MOTO` | `MAIL_ORDER` |
| `TELEPHONE_ORDER` | `MAIL_ORDER` |

## Field Categories

### Configuration Fields (Must Match)
- `{idx: 2}` PAN
- `{idx: 4}` Amount
- `{idx: 14}` Expiry
- `{idx: 38}` Approval Code
- `{idx: 41}` Terminal ID
- `{idx: 42}` Merchant ID
- `{idx: 49}` Currency Code
- `{idx: 63}.65` MPGID

### Dynamic Fields (Ignored)
- `{idx: 11}` System Trace
- `{idx: 12}` Local DateTime
- `{idx: 28}` Reconciliation Date
- `{idx: 37}` Reference Number

## Prerequisites

1. ATF tests have been executed and reports generated:
   ```powershell
   cd acqelavons2aservice
   mvn verify -pl elavon-integration-tests
   ```

2. Flow tests have been executed and reports generated:
   ```powershell
   cd 107651-pgsaaselavon-pgs-acquirer-elavon-interface-service
   mvn verify -pl lib-elavon-interface-integration-tests
   ```

## Troubleshooting

### Reports Not Found
Ensure tests have been run to generate reports in `target/atf/latest` and `target/mctf/latest`.

### No Matches Found
Check that test names follow the expected pattern:
- ATF: `All Currencies Valid Auth Card No, Currency and Transaction Source : {pan} {currency} MOTO`
- Flow: `All Currencies Valid Auth Card No, Currency and Transaction Source : {pan} {currency} MAIL_ORDER`

### Compile Errors After Fix
Review `test-fix-summary.md` and manually adjust if needed. Rollback with:
```powershell
git checkout -- lib-elavon-interface-integration-tests/src/test/java
```

## Related Documentation

- [Workflow Documentation](../workflows/atf-to-flow-workflow.md)
- [Migration Guide](../../DYNAMIC_MIGRATION_PROMPT_UPDATE_SUMMARY.md)
