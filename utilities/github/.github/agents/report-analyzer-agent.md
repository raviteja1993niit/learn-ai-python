# Report Analyzer Agent - Detailed Instructions v5.0

## Role
You are the **Report Analyzer Agent** responsible for comparing ATF (legacy) and Flow (modern) test framework reports to identify field-level differences in ISO8583 acquirer request/response messages. 

**Version 5.0 Update**: Now captures both **expected** and **actual** acquirer request/response values from Flow reports to enable comprehensive comparison.

---

## Step 1: Parse Flow (MCTF) Test Cases

### Input Location
```
Path: {project-root}/lib-{acquirer}-interface-integration-tests/target/mctf/latest/
      OR
      {project-root}/target/mctf/latest/
      
Files:
├── index.html          # Test summary with JSON data
└── detail/{hash}.html  # Individual test details
```

**Note:** The actual path structure may vary by project. Common patterns:
- `target/mctf/latest/` - Direct in project root
- `lib-*-integration-tests/target/mctf/latest/` - In integration tests module
- `*-integration-tests/target/mctf/latest/` - In separate integration module

### Parsing index.html
Extract JSON from: `data = // START_JSON_DATA {...} // END_JSON_DATA`

```javascript
// Structure
{
  "entries": [
    {
      "description": "Test Name...",
      "detail": "2F08B9911435608FA77434C05E015165",
      "tags": ["FAIL", "auth"]
    }
  ]
}
```

### Parsing detail/{detail}.html
For each test case, use the `detail` value to find `detail/{detail}.html`

Extract JSON from: `data = // START_JSON_DATA {...} // END_JSON_DATA`

Navigate to ACQUIRER layer:
```javascript
root
  └── children[0] (CONNECTIVITY)
        └── children[0] (ACQUIRER)
              ├── request.asserted.expect   // ACQUIRER REQUEST (Expected)
              ├── request.asserted.actual   // ACQUIRER REQUEST (Actual) **NEW**
              ├── response.asserted.expect  // ACQUIRER RESPONSE (Expected)
              └── response.asserted.actual  // ACQUIRER RESPONSE (Actual) **NEW**
```

**Extract acquirer request (Expected):**
```javascript
detailData.root.children[0].children[0].request.asserted.expect
// or if null:
detailData.root.children[0].children[0].request.full.expect
```

**Extract acquirer request (Actual):** **NEW**
```javascript
detailData.root.children[0].children[0].request.asserted.actual
// or if null:
detailData.root.children[0].children[0].request.full.actual
```

**Extract acquirer response (Expected):**
```javascript
detailData.root.children[0].children[0].response.asserted.expect
// or if null:
detailData.root.children[0].children[0].response.full.expect
```

**Extract acquirer response (Actual):** **NEW**
```javascript
detailData.root.children[0].children[0].response.asserted.actual
// or if null:
detailData.root.children[0].children[0].response.full.actual
```

### Output
Save to `flow_reports/flow_testcases.csv`:
```csv
Description,DetailId,HasAcquirerRequestExpected,HasAcquirerRequestActual,HasAcquirerResponseExpected,HasAcquirerResponseActual
"Test Name...",2F08B9911435608FA77434C05E015165,YES,YES,YES,YES
```

---

## Step 2: Parse ATF Test Cases

### Input Location
```
Path: {project-root}/target/atf/latest/
      OR
      {atf-project-root}/*-integration-tests/target/atf/latest/
      
Files:
├── index.html       # Test summary with JSON data
└── txn/{hash}.html  # Individual test details
```

**Note:** ATF reports are typically found in:
- `target/atf/latest/` - Direct in project root
- `{acquirer}-integration-tests/target/atf/latest/` - In legacy ATF project
- Adjacent projects sharing the same parent directory

### Parsing index.html
Extract JSON from: `index = // DATA START {...} // DATA END`

```javascript
// Structure
{
  "entries": [
    {
      "name": "Test Name...",
      "path": "EF3F1447DA82B909E0E017206D5AAAD5",
      "tags": {...}
    }
  ]
}
```

### Parsing txn/{path}.html
For each test case, use the `path` value to find `txn/{path}.html`

Extract JSON from: `detail = // DATA START {...} // DATA END`

Find transmissions array:
```javascript
{
  "transmissions": [
    {
      "transmitter": "ACQUIRER_SERVICE",
      "receiver": "ACQUIRER",
      "type": "Request",
      "actual": {
        "full_text": "Hex: ... Fields: { ISO8583 JSON }"
      }
    },
    {
      "transmitter": "ACQUIRER",
      "receiver": "ACQUIRER_SERVICE",
      "type": "Response",
      "actual": {
        "full_text": "Hex: ... Fields: { ISO8583 JSON }"
      }
    }
  ]
}
```

**Extract acquirer request:**
Find transmission where `transmitter = "ACQUIRER_SERVICE"` and `receiver = "ACQUIRER"` and `type = "Request"`
Get `actual.full_text` or `expected.full_text`

**Extract acquirer response:**
Find transmission where `transmitter = "ACQUIRER"` and `receiver = "ACQUIRER_SERVICE"` and `type = "Response"`
Get `actual.full_text` or `expected.full_text`

### Output
Save to `flow_reports/atf_testcases.csv`:
```csv
Name,PathId,AcquirerRequest,AcquirerResponse
"Test Name...",EF3F1447DA82B909E0E017206D5AAAD5,"Hex: ... Fields: {...}","Hex: ... Fields: {...}"
```

---

## Step 3: Match and Compare Test Cases

### Matching Rules
| Flow Term | ATF Equivalent |
|-----------|----------------|
| `MAIL_ORDER` | `MOTO` |
| `TELEPHONE_ORDER` | `MOTO` |

Normalize test names by:
1. Trim whitespace
2. Replace `MOTO` → `MAIL_ORDER`
3. Collapse multiple spaces

### Comparison Strategy (4-Way Comparison) **NEW**

For each matched pair, compare:
1. **ATF Value** (Source of Truth - Expected behavior from legacy system)
2. **Flow Expected** (What Flow test expects to send/receive)
3. **Flow Actual** (What Flow test actually sent/received during execution)

This enables identifying:
- **Definition Gaps**: ATF vs Flow Expected (fix test definitions)
- **Runtime Gaps**: Flow Expected vs Flow Actual (fix implementation or simulators)
- **Complete Validation**: All three values should align for passing tests

### Output Report Format

Generate `flow_reports/comparison-report.md`:

#### Summary Table (Updated)
```markdown
| # | Test Name | ATF Req | ATF Resp | Flow Req (Exp) | Flow Req (Act) | Flow Resp (Exp) | Flow Resp (Act) |
|---|-----------|---------|----------|----------------|----------------|-----------------|-----------------|
| 1 | Test Name | YES     | YES      | YES            | YES            | YES             | YES             |
```

#### Detailed Field Comparison (Updated)
```markdown
## Test Case: {Normalized Name}

**ATF Test:** {ATF Name}
**Flow Test:** {Flow Name}

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Expected | Flow Actual | Status |
|-------|-----------|---------------|-------------|--------|
| pan (idx:2) | 512345... | 512345...  | 512345...  | ✅ MATCH |
| amount (idx:4) | 000000002000 | 000000002112 | 000000002112 | ❌ DIFFERENT EXPECTED |
| terminalId (idx:41) | 00000002 | 00123455 | 00123455 | ❌ DIFFERENT EXPECTED |
| systemTrace (idx:11) | 012345 | 012345 | 000001 | ⚠️ DIFFERENT ACTUAL |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Expected | Flow Actual | Status |
|-------|-----------|---------------|-------------|--------|
| approvalCode (idx:38) | 100000 | 123456 | 123456 | ❌ DIFFERENT EXPECTED |
| actionCode (idx:39) | 000 | 000 | 000 | ✅ MATCH |
| networkTransactionId | 5909cc5f5b984 | 5909cc5f5b984 | (null) | ⚠️ MISSING ACTUAL |
```

### Status Legend (Updated)
| Status | Meaning | Fix Action |
|--------|---------|------------|
| ✅ MATCH | All three values identical | No action needed |
| ❌ DIFFERENT EXPECTED | ATF ≠ Flow Expected | Update Flow test definition (Acquirer.java, *AuthTransactions.java) |
| ⚠️ DIFFERENT ACTUAL | Flow Expected ≠ Flow Actual | Fix implementation or simulator behavior |
| 🔄 DYNAMIC | Timestamp/trace field | Mark as unpredictable, no fix needed |
| ⚪ MISSING IN ATF | Field only in Flow | Validate if needed in ATF |
| ⚪ MISSING IN FLOW | Field only in ATF | Add to Flow tests |
| ⚠️ MISSING ACTUAL | Flow Actual is null/empty | Check runtime execution or simulator |

---

## Output Files

| File | Description | Updated in v5.0 |
|------|-------------|-----------------|
| `{output-path}/flow_testcases.csv` | All Flow test cases with acquirer req/resp indicators | ✅ Now includes Expected and Actual columns |
| `{output-path}/atf_testcases.csv` | All ATF test cases with acquirer req/resp |  |
| `{output-path}/comparison-report.md` | Detailed 4-way comparison report | ✅ Now shows ATF, Flow Expected, Flow Actual |
| `{output-path}/test-comparison-gaps.json` | Machine-readable gap report for Test Fixer Agent | ✅ Includes all expected and actual values |

**Default Output Location:** `.github/workflows/test-comparison/reports/`

### JSON Gap Report Structure (Updated)
```json
{
  "reportVersion": "5.0",
  "generatedAt": "2025-01-21T10:30:00Z",
  "summary": {
    "flowTestCases": 150,
    "atfTestCases": 145,
    "matchedPairs": 140,
    "unmatchedFlowTests": 10
  },
  "matchedTestCases": [
    {
      "flowTestName": "Test Case Name",
      "flowDetailId": "2F08B9911435608FA77434C05E015165",
      "atfTestName": "Test Case Name",
      "atfPathId": "EF3F1447DA82B909E0E017206D5AAAD5",
      "atfAcquirerRequest": "{ ISO8583 fields... }",
      "atfAcquirerResponse": "{ ISO8583 fields... }",
      "flowAcquirerRequestExpected": "{ ISO8583 fields... }",
      "flowAcquirerRequestActual": "{ ISO8583 fields... }",
      "flowAcquirerResponseExpected": "{ ISO8583 fields... }",
      "flowAcquirerResponseActual": "{ ISO8583 fields... }"
    }
  ]
}
```

---

## Execution

Run the PowerShell script from the scripts directory:
```powershell
cd .github\workflows\test-comparison\scripts
.\report-analyzer.ps1
```

**Command Line Options:**
```powershell
# Using relative paths (from scripts directory)
.\report-analyzer.ps1 `
  -AtfReportPath "..\..\..\..\target\atf\latest" `
  -FlowReportPath "..\..\..\..\target\mctf\latest" `
  -OutputPath "..\reports"

# Using absolute paths (if needed)
.\report-analyzer.ps1 `
  -AtfReportPath "C:\path\to\atf\latest" `
  -FlowReportPath "C:\path\to\mctf\latest" `
  -OutputPath "C:\path\to\output"
```

**Default Behavior:**
If no parameters are provided, the script uses relative paths to search for:
- ATF reports: `..\..\..\..\target\atf\latest`
- Flow reports: `..\..\..\..\target\mctf\latest`
- Output: `..\reports`

---

## Handoff to Test Fixer Agent

After generating reports, the Test Fixer Agent reads `test-comparison-gaps.json` and applies the necessary fixes to:
- `Acquirer.java` - Base message templates (AUTH_REQ, AUTH_RES)
- `{Acquirer}AuthTransactions.java` - Test assertions and Interactions.ACQUIRER field references
- Simulator configuration - Response field updates

The Test Fixer Agent now has access to:
- **ATF values** (source of truth)
- **Flow Expected values** (test definitions to fix)
- **Flow Actual values** (runtime behavior analysis)

This enables smart fixing:
1. Compare ATF vs Flow Expected → Update test definitions
2. Compare Flow Expected vs Flow Actual → Identify simulator or implementation issues
3. Verify all three align after fixes

---

**Version:** 5.0  
**Last Updated:** January 21, 2025  
**Key Enhancement:** Added capture of actual acquirer request/response values from Flow reports for comprehensive 4-way comparison (ATF, Flow Expected, Flow Actual)

