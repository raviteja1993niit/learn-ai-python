# Test Comparison Agents

This folder contains the AI agent definitions for the test comparison workflow.

## Agent Overview

| Agent | File | Purpose |
|-------|------|---------|
| Report Parser Agent | `report-parser-agent.md` | Parse ATF and Flow test reports |
| Comparison Agent | `comparison-agent.md` | Match and compare test cases |
| Report Generator Agent | `report-generator-agent.md` | Generate comparison reports |
| Test Fixer Agent | `test-fixer-agent.md` | Apply fixes to Flow tests |

## Workflow Sequence

```
┌─────────────────────┐
│  Report Parser      │  ← Reads HTML reports
│  Agent              │  ← Auto-detects message format
│                     │  ← Extracts acquirer req/resp
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Comparison         │  ← Matches test cases by name
│  Agent              │  ← Compares fields
│                     │  ← Identifies differences
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Report Generator   │  ← Creates markdown report
│  Agent              │  ← Creates JSON/CSV output
│                     │  ← Generates fix recommendations
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Test Fixer         │  ← Reads recommendations
│  Agent (Optional)   │  ← Applies fixes to Flow tests
│                     │  ← Validates changes
└─────────────────────┘
```

## How to Use

### Option 1: Ask AI Agent Directly

Simply ask the AI to run the workflow:

```
Please analyze and compare the ATF and Flow test reports:
- ATF: C:\path\to\atf\latest
- Flow: C:\path\to\flow\latest

Generate a detailed comparison report showing differences in acquirer request and response fields.
```

### Option 2: Run Step by Step

1. **Parse Reports:**
   ```
   Parse the ATF and Flow test reports and extract all test cases with their acquirer request/response data.
   ```

2. **Compare Test Cases:**
   ```
   Match the ATF test cases with Flow test cases and compare their acquirer request/response fields.
   ```

3. **Generate Report:**
   ```
   Generate a detailed comparison report in markdown format.
   ```

4. **Apply Fixes (Optional):**
   ```
   Review the comparison report and apply high-priority fixes to the Flow test cases.
   ```

## Agent Capabilities

### Report Parser Agent
- Reads HTML report files (index.html, detail/*.html)
- Auto-detects message format (ISO8583, JSON, XML, HTTP)
- Extracts acquirer request and response data
- Handles embedded JSON with escape sequences
- Supports both ATF and Flow report formats

### Comparison Agent
- Matches test cases by normalized name
- Handles naming variations (MOTO ↔ MAIL_ORDER)
- Compares fields between ATF and Flow
- Classifies differences (MATCH, DIFFERENT, DYNAMIC, MISSING)
- Supports cross-format comparison (ISO8583 ↔ JSON)

### Report Generator Agent
- Creates detailed markdown tables
- Generates JSON for automation
- Creates CSV for spreadsheet analysis
- Produces actionable fix recommendations
- Prioritizes issues by severity

### Test Fixer Agent
- Locates Flow test files
- Applies field value fixes
- Updates simulator configurations
- Validates changes compile
- Creates audit trail of changes

## Configuration

Each agent uses configuration from `../config/`:
- `workflow-config.yaml` - Main settings
- `field-mappings.yaml` - Cross-format field mappings
- `ignore-fields.yaml` - Fields to skip in comparison

---
*Agents Version: 1.0.0*
