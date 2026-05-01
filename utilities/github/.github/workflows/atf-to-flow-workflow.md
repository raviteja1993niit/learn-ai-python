# ATF-to-Flow Test Migration Workflow

> **📖 Main Guide:** [test-comparison/README.md](test-comparison/README.md)

---

## Overview

This workflow has **TWO entry points** for migrating from ATF to Flow tests:

1. **Entry Point 1:** Compare ATF & Flow reports → Generate comparison report
2. **Entry Point 2:** Fix Flow tests → Apply fixes based on comparison report

---

## 🎯 Entry Point 1: Compare ATF & Flow Reports

### Quick Start

```powershell
# 1. Run both test suites first
cd C:\...\acqelavons2aservice
mvn verify -pl elavon-integration-tests

cd C:\...\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service  
mvn verify -pl lib-elavon-interface-integration-tests

# 2. Run comparison
cd .github\workflows\test-comparison\scripts
.\run-workflow.ps1
```

### Sample Prompt for AI

```
@workspace Compare ATF and Flow test reports:

ATF: C:\Users\e135408\IdeaProjects\MODERNIZATION\acqelavons2aservice\elavon-integration-tests\target\atf\latest

Flow: C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\lib-elavon-interface-integration-tests\target\mctf\latest

Use existing PowerShell script:
#file:.github/workflows/test-comparison/scripts/run-workflow.ps1

Generate detailed comparison report showing field differences.
```

### Expected Output

```
.github/workflows/test-comparison/reports/
├── comparison-report.md          ← Read this first!
├── comparison-report.csv         ← CSV for Excel filtering
├── comparison-report-summary.csv ← Status counts
├── test-comparison-gaps.json     ← Machine-readable (all Flow tests)
├── atf_testcases.csv
└── flow_testcases.csv
```

**New in v6.1:**
- ✅ CSV output for easy parsing and pivot tables
- ✅ All Flow test cases included (matched + unmatched)
- ✅ HasAtfMatch column shows ATF equivalence

---

## 🔧 Entry Point 2: Fix Flow Tests

### Prerequisites

✅ Comparison report generated  
✅ Identified specific test to fix  

### Sample Prompt for AI

```
@workspace Fix Flow test based on comparison report:

Report: #file:.github/workflows/test-comparison/reports/comparison-report.md

Test Case: "All Currencies Valid Auth : 5123450000000008 AUD MAIL_ORDER"

Follow instructions in:
#file:.github/workflows/test-comparison/agents/test-fixer-agent.md

Fix:
- Card number mismatches
- Amount differences
- Missing ISO8583 fields (MPGID, SCA indicator)
- Merchant/Terminal IDs

⚠️ Show me the changes before applying!
```

### Workflow

```
Review Report → Select Test → Apply Fix → Validate → Re-run Tests → Repeat
```

---

## 📊 Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   ATF-to-Flow Migration                      │
└─────────────────────────────────────────────────────────────┘

1️⃣ ENTRY POINT 1: COMPARE
   
   Run ATF Tests ──┐
                   ├──→ PowerShell Script ──→ Comparison Report
   Run Flow Tests ─┘     (run-workflow.ps1)      (reports/*.md)
   
   
2️⃣ ENTRY POINT 2: FIX

   Comparison Report ──→ AI Agent ──→ Updated Flow Tests
   (identify issues)    (test-fixer)   (*.java files)
   
   
3️⃣ VALIDATE

   Re-run Flow Tests ──→ Success? ──→ Done!
                            │ No
                            └──→ Back to Entry Point 1
```

---

## 🗂️ File Structure

```
.github/workflows/
├── atf-to-flow-workflow.md       ← This file (Overview)
└── test-comparison/
    ├── README.md                  ← Main guide (read this!)
    │
    ├── scripts/
    │   ├── run-workflow.ps1       ← Entry Point 1 script
    │   └── report-analyzer.ps1    ← Used internally
    │
    ├── agents/
    │   ├── test-fixer-agent.md    ← Entry Point 2 instructions
    │   ├── report-parser-agent.md
    │   ├── comparison-agent.md
    │   └── report-generator-agent.md
    │
    └── reports/                   ← Generated outputs
        ├── comparison-report.md       ← Main report
        ├── comparison-report.csv      ← CSV for parsing
        ├── comparison-report-summary.csv
        └── test-comparison-gaps.json
```

---

## 📋 Step-by-Step Guide

### Step 1: Generate Test Reports

```powershell
# ATF
cd acqelavons2aservice
mvn verify -pl elavon-integration-tests

# Flow
cd 107651-pgsaaselavon-pgs-acquirer-elavon-interface-service
mvn verify -pl lib-elavon-interface-integration-tests
```

### Step 2: Run Comparison (Entry Point 1)

```powershell
cd .github\workflows\test-comparison\scripts
.\run-workflow.ps1
```

**Output:** `reports/comparison-report.md`

### Step 3: Review Report

Open `comparison-report.md` (or `comparison-report.csv` for filtering) and identify:
- ❌ **[FLOW MISMATCH]** → Highest priority - fix first!
- ⚠️ **[MISSING IN FLOW]** → Need adding
- ✅ **[EXPECTED MATCH]** → ATF expected = Flow expected
- ⚠️ **[MISSING IN ATF]** → Flow-only field
- 🔄 **[DYNAMIC]** → Ignore (timestamps, traces)
- ✅ **[PERFECT MATCH]** → All values match

**CSV Filtering Tip:** Open `comparison-report.csv` in Excel and filter by `MatchStatus = "FLOW MISMATCH"` to see all issues.

### Step 4: Fix Tests (Entry Point 2)

For each high-priority issue:
1. Use AI agent with test name
2. Review proposed changes
3. Apply fixes
4. Validate compilation

### Step 5: Validate

```powershell
mvn verify -pl lib-elavon-interface-integration-tests
```

### Step 6: Iterate

Repeat Steps 2-5 until:
- ✅ Flow tests pass
- ✅ Field match rate > 95%
- ✅ No critical (P1) issues

---

## 🎯 Success Criteria

| Metric | Target | How to Check |
|--------|--------|--------------|
| FLOW MISMATCH count | 0 | CSV filter: MatchStatus = "FLOW MISMATCH" |
| Test match rate | >90% | Comparison report summary |
| Field match rate | >95% | comparison-report-summary.csv |
| Flow test pass rate | >95% | Maven test results |

---

## ⚠️ Important Notes

### For End Users

- Always run tests before comparison
- Review report before fixing
- Fix high-priority issues first
- Validate after each fix
- Use version control (git)

### For AI Agents

**Entry Point 1 (Compare):**
- Use existing `run-workflow.ps1` script
- DO NOT create new parsing scripts
- Follow [report-parser-agent.md](test-comparison/agents/report-parser-agent.md)

**Entry Point 2 (Fix):**
- Read comparison report first
- Auto-discover project structure
- Show changes before applying
- Follow [test-fixer-agent.md](test-comparison/agents/test-fixer-agent.md)

---

## 📚 Additional Resources

- [Test Comparison README](test-comparison/README.md) - Main guide
- [Report Parser Agent](test-comparison/agents/report-parser-agent.md) - How parsing works
- [Test Fixer Agent](test-comparison/agents/test-fixer-agent.md) - How fixing works
- [Configuration Guide](test-comparison/config/) - Field mappings

---

**Version:** 6.1  
**Last Updated:** January 22, 2026  
**What's New:** CSV output, all Flow test cases included, enhanced status codes
