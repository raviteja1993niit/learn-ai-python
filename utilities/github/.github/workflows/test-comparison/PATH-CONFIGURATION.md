# Path Configuration Guide

This document explains how the test comparison workflow resolves paths and how to configure them for your environment.

---

## Default Path Structure

The scripts use **relative paths** to work across different systems and users. Default paths assume the following project structure:

```
{workspace-root}/
├── {flow-project}/                              # Your Flow test project
│   ├── .github/
│   │   └── workflows/
│   │       └── test-comparison/
│   │           ├── scripts/
│   │           │   ├── report-analyzer.ps1     ← Scripts run from here
│   │           │   └── run-workflow.ps1
│   │           └── reports/                     ← Default output location
│   ├── lib-{acquirer}-interface-integration-tests/
│   │   └── target/
│   │       └── mctf/
│   │           └── latest/                      ← Flow test reports
│   │               ├── index.html
│   │               └── detail/
│   └── target/                                  ← Alternative Flow report location
│       └── mctf/
│           └── latest/
└── {atf-project}/                               # Legacy ATF project (optional)
    └── target/
        └── atf/
            └── latest/                          ← ATF test reports
                ├── index.html
                └── txn/
```

---

## Default Relative Paths

When executed from `.github/workflows/test-comparison/scripts/`:

| Report Type | Default Relative Path | Resolves To |
|-------------|----------------------|-------------|
| ATF Reports | `..\..\..\..\target\atf\latest` | `{project-root}/target/atf/latest` |
| Flow Reports | `..\..\..\..\target\mctf\latest` | `{project-root}/target/mctf/latest` |
| Output | `..\reports` | `{project-root}/.github/workflows/test-comparison/reports` |

---

## Customizing Paths

### Option 1: Command Line Parameters

Override default paths when running the scripts:

```powershell
# From scripts directory
cd .github\workflows\test-comparison\scripts

# Specify custom paths
.\report-analyzer.ps1 `
  -AtfReportPath "..\..\..\..\..\..\legacy-project\target\atf\latest" `
  -FlowReportPath "..\..\..\..\lib-*-integration-tests\target\mctf\latest" `
  -OutputPath "..\reports"
```

### Option 2: Environment Variables

Set paths via environment variables before running:

```powershell
$env:ATF_REPORT_PATH = "C:\path\to\atf\latest"
$env:FLOW_REPORT_PATH = "C:\path\to\mctf\latest"
$env:OUTPUT_PATH = "C:\path\to\output"

.\run-workflow.ps1
```

### Option 3: Edit Script Defaults

Modify the default parameter values in `report-analyzer.ps1`:

```powershell
param(
    [string]$AtfReportPath = "your\custom\path\to\atf\latest",
    [string]$FlowReportPath = "your\custom\path\to\mctf\latest",
    [string]$OutputPath = "your\custom\output\path"
)
```

---

## Path Resolution Examples

### Example 1: Standard Project Structure
```
Project: 107651-pgsaaselavon-pgs-acquirer-elavon-interface-service
ATF: In sibling project (acqelavons2aservice)
Flow: In lib-elavon-interface-integration-tests module
```

**Command:**
```powershell
.\report-analyzer.ps1 `
  -AtfReportPath "..\..\..\..\..\acqelavons2aservice\elavon-integration-tests\target\atf\latest" `
  -FlowReportPath "..\..\..\..\lib-elavon-interface-integration-tests\target\mctf\latest"
```

### Example 2: Consolidated Structure
```
Project: All in one repository
ATF: {project-root}/target/atf/latest
Flow: {project-root}/target/mctf/latest
```

**Command:**
```powershell
.\report-analyzer.ps1
# Uses defaults: ..\..\..\..\target\atf\latest and ..\..\..\..\target\mctf\latest
```

### Example 3: Using Wildcards (run-workflow.ps1)
```
Project: Multiple integration test modules
Flow: Could be in any lib-*-integration-tests module
```

**Automatic resolution in run-workflow.ps1:**
```powershell
$FlowPath = Join-Path $PSScriptRoot "..\..\..\..\lib-*-integration-tests\target\mctf\latest"
$resolvedFlowPaths = Resolve-Path $FlowPath -ErrorAction SilentlyContinue
if ($resolvedFlowPaths) {
    $FlowPath = $resolvedFlowPaths | Select-Object -First 1 -ExpandProperty Path
}
```

---

## Troubleshooting Path Issues

### Issue: "Path not found" error

**Solution 1:** Verify the directory structure
```powershell
# Check if ATF reports exist
Test-Path "..\..\..\..\target\atf\latest"

# Check if Flow reports exist
Test-Path "..\..\..\..\target\mctf\latest"
```

**Solution 2:** Use absolute paths temporarily
```powershell
.\report-analyzer.ps1 `
  -AtfReportPath "C:\full\path\to\atf\latest" `
  -FlowReportPath "C:\full\path\to\mctf\latest"
```

**Solution 3:** Navigate to the correct directory
```powershell
# Ensure you're in the scripts directory
Get-Location
# Should show: ...\test-comparison\scripts
```

### Issue: Reports found but in wrong location

**Check the actual report paths:**
```powershell
# Find all ATF report directories
Get-ChildItem -Path "..\..\..\.." -Recurse -Filter "atf" -Directory | 
  Where-Object { $_.Parent.Name -eq "target" } | 
  Select-Object FullName

# Find all MCTF report directories
Get-ChildItem -Path "..\..\..\.." -Recurse -Filter "mctf" -Directory | 
  Where-Object { $_.Parent.Name -eq "target" } | 
  Select-Object FullName
```

### Issue: Wildcard paths not resolving

**Use explicit module name:**
```powershell
# Instead of: lib-*-integration-tests
# Use specific: lib-elavon-interface-integration-tests
.\report-analyzer.ps1 `
  -FlowReportPath "..\..\..\..\lib-elavon-interface-integration-tests\target\mctf\latest"
```

---

## Best Practices

1. **Use Relative Paths** - Makes scripts portable across users and systems
2. **Avoid Hardcoded User Paths** - Don't use paths like `C:\Users\{username}\...`
3. **Avoid Hardcoded Acquirer Names** - Use generic patterns like `lib-*-integration-tests`
4. **Document Custom Paths** - If you modify defaults, document why and where
5. **Use `$PSScriptRoot`** - Always resolve paths relative to script location
6. **Test Path Resolution** - Verify paths exist before running full workflow

---

## Path Patterns by Acquirer

Different acquirers may have different project structures. Here are common patterns:

### Elavon
```
Flow: lib-elavon-interface-integration-tests/target/mctf/latest
ATF: acqelavons2aservice/elavon-integration-tests/target/atf/latest
```

### Chase Paymentech
```
Flow: lib-paymentech-interface-integration-tests/target/mctf/latest
ATF: acqchasepaymentech/target/atf/latest
```

### Worldpay
```
Flow: lib-worldpay-interface-integration-tests/target/mctf/latest
ATF: {worldpay-atf-project}/target/atf/latest
```

### Generic Pattern
```
Flow: lib-{acquirer}-interface-integration-tests/target/mctf/latest
      OR target/mctf/latest
ATF: target/atf/latest
     OR {atf-project}/target/atf/latest
```

---

## Configuration File Support (Future)

A YAML configuration file is planned for v6.0:

```yaml
# .github/workflows/test-comparison/config/workflow-config.yaml
paths:
  atf:
    default: "../../../../target/atf/latest"
    alternatives:
      - "../../../../../{atf-project}/target/atf/latest"
  flow:
    default: "../../../../target/mctf/latest"
    alternatives:
      - "../../../../lib-*-integration-tests/target/mctf/latest"
  output:
    default: "../reports"
```

---

**Last Updated:** January 21, 2025  
**Version:** 5.0
