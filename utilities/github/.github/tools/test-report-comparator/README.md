# ATF vs Flow Framework Test Report Comparator

## Overview

This tool compares test reports from the old ATF (Acquirer Test Framework) with the new Flow Framework to identify:
- Test cases that have been migrated
- Test cases pending migration
- Status mismatches (PASS/FAIL differences)
- Acquirer ISO8583 message differences

## Quick Start

```powershell
cd .github\tools\test-report-comparator
powershell -ExecutionPolicy Bypass -File compare-test-reports.ps1
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-AtfReportPath` | `C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice\elavon-integration-tests\target\atf\latest` | Path to ATF test report |
| `-FlowReportPath` | `C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\lib-elavon-interface-integration-tests\target\mctf\latest` | Path to Flow test report |
| `-OutputPath` | `test-comparison-report.md` | Output report file path |

## Custom Paths

```powershell
.\compare-test-reports.ps1 `
    -AtfReportPath "C:\custom\atf\latest" `
    -FlowReportPath "C:\custom\flow\latest" `
    -OutputPath "C:\output\my-report.md"
```

## Report Structure

The generated markdown report includes:

### 1. Summary
- Total test cases in each framework
- Number of matched tests
- Tests only in ATF (not migrated)
- Tests only in Flow (new/renamed)
- Status mismatches

### 2. Status Mismatches
Table showing tests that pass in one framework but fail in another.

### 3. Migration Status
- **Only in ATF**: Tests pending migration
- **Only in Flow**: New tests or tests with different naming conventions

### 4. ISO8583 Analysis
Comparison of acquirer request/response fields including:
- PAN (idx: 2)
- Amount (idx: 4)
- Currency Code (idx: 49)
- MOTO Indicator (idx: 63.04)
- MPGID (idx: 63.65)

### 5. Recommendations
Actionable items for completing the migration.

## Key Differences Between Frameworks

### Layer Naming
| ATF | Flow |
|-----|------|
| MERCHANT | UPSTREAM_SYSTEM |
| GATEWAY | CARD_PAYMENT_CONNECTIVITY |
| ACQUIRER_SERVICE | CONNECTIVITY |
| ACQUIRER | ACQUIRER |

### Test Description Format
| ATF | Flow |
|-----|------|
| Uses `MOTO` | Uses `MAIL_ORDER` |
| Transaction source in description | Payment source in description |

## Common Migration Issues

1. **Naming Convention Changes**
   - ATF: `MOTO` → Flow: `MAIL_ORDER`
   - Test descriptions may differ slightly

2. **ISO8583 Field Mapping**
   - Application ID: `3765WMTT` vs `3765WITT`
   - Cardholder Present indicator differences

3. **New Test Data**
   - Flow includes additional card types (Visa, AMEX, etc.)
   - Flow has more currency test variations

## Troubleshooting

### JSON Parsing Errors
If you encounter JSON parsing errors, ensure:
- Test reports have been generated (run tests first)
- HTML files contain valid JSON data blocks

### Missing Tests
If tests appear only in one framework:
- Check for naming convention differences
- Verify test has been migrated with correct description

## Files

| File | Description |
|------|-------------|
| `compare-test-reports.ps1` | Main PowerShell comparison script |
| `test-report-comparator.chatmode.md` | Agent instructions for AI assistants |
| `README.md` | This documentation file |

## Related Documentation

- [ATF-to-Flow Migration Framework](../../agents/atf-to-flow/README.md)
- [Dynamic Migration Prompt](../../../DYNAMIC_MIGRATION_PROMPT_UPDATE_SUMMARY.md)
- [Elavon Integration Tests](../../../lib-elavon-interface-integration-tests/README.md)
