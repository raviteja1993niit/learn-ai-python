# Test Comparison Workflow

**Two Simple Entry Points:**
1. **Compare ATF & Flow** → Generate comparison report
2. **Fix Flow Tests** → Apply fixes based on comparison report

---

## 🎯 Entry Point 1: Compare ATF & Flow Reports

**Purpose:** Generate detailed comparison report showing differences between ATF and Flow test results.

### How to Run

**Option A: PowerShell Script (Recommended)**

```powershell
cd .github\workflows\test-comparison\scripts
.\run-workflow.ps1 `
  -AtfPath "C:\path\to\atf\latest" `
  -FlowPath "C:\path\to\flow\latest"
```

**Option B: Ask AI Agent**

```
@workspace Compare ATF and Flow test reports:

ATF: C:\...\acqelavons2aservice\elavon-integration-tests\target\atf\latest
Flow: C:\...\lib-elavon-interface-integration-tests\target\mctf\latest

Use existing script: .github\workflows\test-comparison\scripts\run-workflow.ps1
Generate comparison report.
```

### What It Does

1. ✅ Parses ATF test reports (index.html + txn/*.html)
2. ✅ Parses Flow test reports (index.html + detail/*.html)
3. ✅ Extracts acquirer request/response messages
4. ✅ Compares fields between ATF and Flow
5. ✅ Generates comparison report with differences

### Output

```
reports/
├── comparison-report.md          ← Main report (read this!)
├── comparison-report.csv         ← CSV for easy parsing/filtering
├── comparison-report-summary.csv ← Status counts summary
├── test-comparison-gaps.json     ← Machine-readable data
├── atf_testcases.csv             ← ATF test list
└── flow_testcases.csv            ← Flow test list
```

**What to look for in comparison report:**
- ❌ **[FLOW MISMATCH]** - Flow expected ≠ actual (highest priority - fix first!)
- ⚠️ **[MISSING IN FLOW]** - Field in ATF but not in Flow
- ✅ **[EXPECTED MATCH]** - ATF expected = Flow expected
- ⚠️ **[MISSING IN ATF]** - Field in Flow but not in ATF
- 🔄 **[DYNAMIC]** - Dynamic fields (timestamps, traces - ignore)
- ✅ **[PERFECT MATCH]** - All 4 values match
- ✅ **[ACTUAL MATCH]** - Actual values match
- ⚠️ **[ATF MISMATCH]** - ATF expected ≠ actual
- ❓ **[DIFFERENT]** - Values differ

**New in v6.1:**
- ✅ **All Flow test cases included** (matched + unmatched with ATF)
- ✅ **CSV output** for easy Excel filtering and pivot tables
- ✅ **HasAtfMatch column** shows if ATF equivalent exists

---

## 🔧 Entry Point 2: Fix Flow Tests

**Purpose:** Apply fixes to Flow test code based on comparison report findings.

### Prerequisites

1. ✅ Comparison report generated (Entry Point 1)
2. ✅ Reviewed comparison report and identified issues
3. ✅ Decided which test cases to fix

### How to Run

**Ask AI Agent:**

```
@workspace Fix Flow test case based on comparison report:

Report: #file:.github/workflows/test-comparison/reports/comparison-report.md
Test: "All Currencies Valid Auth : 5123450000000008 AUD MAIL_ORDER"

Follow: #file:.github/workflows/test-comparison/agents/test-fixer-agent.md

Apply fixes for:
- Card number mismatches
- Amount differences  
- Missing ISO8583 fields
- Merchant/Terminal ID updates

Show me changes before applying!
```

### What It Does

1. ✅ Reads comparison report
2. ✅ Locates Flow test files (auto-discovers structure)
3. ✅ Applies fixes to test data
4. ✅ Updates simulator configurations
5. ✅ Validates compilation

### Workflow

```
Review Report → Identify Issues → Fix Test → Validate → Re-run Tests
```

---

## 📋 Complete Workflow Example

### Step 1: Run Both Test Suites

```powershell
# ATF
cd C:\...\acqelavons2aservice
mvn verify -pl elavon-integration-tests

# Flow  
cd C:\...\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service
mvn verify -pl lib-elavon-interface-integration-tests
```

### Step 2: Compare (Entry Point 1)

```powershell
cd .github\workflows\test-comparison\scripts
.\run-workflow.ps1
```

Review: `reports/comparison-report.md`

### Step 3: Fix Issues (Entry Point 2)

For each failing test:
1. Read issue from comparison report
2. Use Test Fixer Agent (ask AI)
3. Validate fix compiles
4. Re-run Flow tests

### Step 4: Iterate

Repeat until match rate > 95%

---

## 🗂️ Directory Structure

```
test-comparison/
├── README.md                 ← You are here
├── scripts/
│   ├── run-workflow.ps1      ← Entry Point 1 (Compare)
│   └── report-analyzer.ps1   ← Used by run-workflow.ps1
├── agents/
│   ├── report-parser-agent.md     ← How parsing works
│   ├── comparison-agent.md        ← How comparison works
│   ├── report-generator-agent.md  ← How reports are generated
│   └── test-fixer-agent.md        ← Entry Point 2 (Fix)
├── parsers/                  ← Message format parsers
├── config/                   ← Field mappings & ignore rules
└── reports/                  ← Generated outputs
```

---

## ⚠️ Important Notes

### For Users
- Always run tests first to generate reports
- Review comparison report before fixing
- Fix high-priority issues first (marked in report)
- Re-run tests after fixes to validate

### For AI Agents
- **DO NOT create new Python/JavaScript scripts**
- **USE existing PowerShell scripts** in `scripts/` directory
- Follow agent instructions in `agents/` directory
- Maintain context between entry points

---

## 📚 Detailed Agent Instructions

For AI agents handling user requests:

**Entry Point 1 (Compare):** Read [report-parser-agent.md](agents/report-parser-agent.md)  
**Entry Point 2 (Fix):** Read [test-fixer-agent.md](agents/test-fixer-agent.md)

---

## 📞 Quick Reference

| Task | Command |
|------|---------|
| Compare reports | `.\scripts\run-workflow.ps1` |
| Fix test | Ask AI with test name + report |
| Check outputs | Look in `reports/` folder |
| Re-run tests | `mvn verify -pl {module}` |

---

**Version:** 6.1  
**Last Updated:** January 22, 2026

**What's New in v6.1:**
- CSV report generation (`comparison-report.csv`) for easy parsing
- All Flow test cases included (matched + unmatched with ATF)
- Enhanced status priority ordering
- HasAtfMatch column in outputs

The workflow consists of multiple agents working together:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    TEST COMPARISON WORKFLOW                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │  ATF Report  │    │ Flow Report  │    │   Config     │              │
│  │  (HTML/JSON) │    │  (HTML/JSON) │    │   (YAML)     │              │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘              │
│         │                   │                   │                       │
│         ▼                   ▼                   ▼                       │
│  ┌─────────────────────────────────────────────────────┐               │
│  │            REPORT PARSER AGENT                       │               │
│  │  • Auto-detect message format (ISO8583, JSON, XML)  │               │
│  │  • Extract test cases from HTML reports             │               │
│  │  • Parse acquirer request/response                  │               │
│  └─────────────────────────┬───────────────────────────┘               │
│                            │                                            │
│                            ▼                                            │
│  ┌─────────────────────────────────────────────────────┐               │
│  │            COMPARISON AGENT                          │               │
│  │  • Match test cases by name (semantic matching)     │               │
│  │  • Compare fields between ATF and Flow              │               │
│  │  • Identify differences, matches, and gaps          │               │
│  └─────────────────────────┬───────────────────────────┘               │
│                            │                                            │
│                            ▼                                            │
│  ┌─────────────────────────────────────────────────────┐               │
│  │            REPORT GENERATOR AGENT                    │               │
│  │  • Generate detailed comparison reports             │               │
│  │  • Create actionable fix recommendations            │               │
│  │  • Output in Markdown, JSON, and CSV formats        │               │
│  └─────────────────────────┬───────────────────────────┘               │
│                            │                                            │
│                            ▼                                            │
│  ┌─────────────────────────────────────────────────────┐               │
│  │            TEST FIXER AGENT (Optional)               │               │
│  │  • Apply fixes to Flow test cases                   │               │
│  │  • Update simulator configurations                  │               │
│  │  • Validate changes                                 │               │
│  └─────────────────────────────────────────────────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Folder Structure

```
test-comparison/
├── README.md                    # This file
├── agents/                      # Agent definitions and prompts
│   ├── report-parser-agent.md   # Report parsing agent instructions
│   ├── comparison-agent.md      # Comparison logic agent
│   ├── report-generator-agent.md# Report generation agent
│   └── test-fixer-agent.md      # Test fixing agent
├── scripts/                     # Executable scripts
│   ├── run-workflow.ps1         # Main workflow runner
│   ├── parse-reports.ps1        # Report parsing script
│   └── generate-comparison.ps1  # Comparison generation script
├── parsers/                     # Message format parsers
│   ├── iso8583-parser.md        # ISO8583 message parser guide
│   ├── json-parser.md           # JSON message parser guide
│   ├── xml-parser.md            # XML message parser guide
│   └── auto-detect.md           # Auto-detection logic
├── instructions/                # Step-by-step instructions
│   ├── quick-start.md           # Quick start guide
│   ├── configuration.md         # Configuration guide
│   └── troubleshooting.md       # Common issues and solutions
├── config/                      # Configuration files
│   ├── workflow-config.yaml     # Main workflow configuration
│   ├── field-mappings.yaml      # Field name mappings
│   └── ignore-fields.yaml       # Fields to ignore in comparison
└── reports/                     # Generated reports output
    └── .gitkeep
```

## Quick Start

1. **Configure the workflow** - Edit `config/workflow-config.yaml`
2. **Run the parser agent** - Execute report parsing
3. **Run the comparison agent** - Generate comparison
4. **Review the report** - Check `reports/` folder

## Supported Message Formats

| Format | Description | Auto-Detect Pattern |
|--------|-------------|---------------------|
| ISO8583 | ISO 8583 financial messages | `Fields : {`, `messageType`, `{idx:` |
| JSON | Standard JSON format | `{` at start, valid JSON structure |
| XML | XML messages | `<?xml` or `<` at start |
| HTTP | HTTP request/response | `HTTP/`, `POST`, `GET` headers |
| Custom | Custom formats | Configurable patterns |

## Usage

### Using the AI Agent (Recommended)

Ask the AI agent to:
```
Analyze the ATF and Flow test reports and generate a comparison report.
ATF Report: C:\path\to\atf\latest
Flow Report: C:\path\to\flow\latest
```

### Using PowerShell Script

```powershell
cd .github\workflows\test-comparison\scripts
.\run-workflow.ps1 -AtfPath "C:\path\to\atf" -FlowPath "C:\path\to\flow"
```

## Configuration

See `config/workflow-config.yaml` for all configuration options.

## Output

The workflow generates:
- `comparison-report.md` - Human-readable comparison report
- `comparison-report.csv` - CSV for Excel/programmatic parsing
- `comparison-report-summary.csv` - Status counts summary
- `test-comparison-gaps.json` - Machine-readable data (all Flow tests)
- `atf_testcases.csv` - ATF test case list
- `flow_testcases.csv` - Flow test case list

### CSV Columns

| Column | Description |
|--------|-------------|
| TestName | Normalized test name |
| HasAtfMatch | YES/NO - whether ATF equivalent exists |
| AtfTestName | Original ATF test name (empty if no match) |
| FlowTestName | Flow test description |
| MessageType | ACQUIRER_REQUEST or ACQUIRER_RESPONSE |
| FieldName | Field being compared |
| AtfExpected | ATF expected value |
| AtfActual | ATF actual value |
| FlowExpected | Flow expected value |
| FlowActual | Flow actual value |
| MatchStatus | Status code (FLOW MISMATCH, EXPECTED MATCH, etc.) |

---
*Version: 6.1 | Last Updated: 2026-01-22*
