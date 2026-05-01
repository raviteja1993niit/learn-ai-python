# Quick Start Guide
# Test Comparison Workflow

## Prerequisites

- PowerShell 5.1+ or PowerShell Core 7+
- Access to ATF and Flow test report directories
- AI agent with file system access

## Step 1: Configure Paths

Edit `config/workflow-config.yaml` and set your report paths:

```yaml
paths:
  atf_report: "C:\\path\\to\\atf\\latest"
  flow_report: "C:\\path\\to\\flow\\latest"
  output_dir: "C:\\path\\to\\output"
```

## Step 2: Run the Workflow

### Option A: Ask the AI Agent

Simply ask the AI agent:

```
Please run the test comparison workflow to compare ATF and Flow test reports.

ATF Report Path: C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice\elavon-integration-tests\target\atf\latest

Flow Report Path: C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\lib-elavon-interface-integration-tests\target\mctf\latest
```

The agent will:
1. Parse both reports
2. Match test cases
3. Compare acquirer request/response fields
4. Generate comparison report

### Option B: Run PowerShell Script

```powershell
cd .github\workflows\test-comparison\scripts
.\run-workflow.ps1
```

## Step 3: Review Results

Check the `reports/` folder for:

- `comparison-report.md` - Detailed comparison
- `comparison-data.json` - Machine-readable data
- `fix-recommendations.md` - Suggested fixes

## Step 4: Apply Fixes (Optional)

Ask the AI agent to apply fixes:

```
Please review the fix recommendations and apply the high-priority fixes to the Flow test cases.
```

## Common Tasks

### Compare Specific Test Cases

```
Compare only the test cases that contain "Auth" in their names.
```

### Re-run After Fixes

```
Re-run the comparison workflow to verify the fixes were applied correctly.
```

### Export to Excel

```
Export the comparison data to an Excel-compatible CSV format.
```

## Troubleshooting

See `instructions/troubleshooting.md` for common issues.

---
*Quick Start Version: 1.0.0*
