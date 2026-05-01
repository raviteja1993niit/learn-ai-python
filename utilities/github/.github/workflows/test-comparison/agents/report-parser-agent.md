# Report Parser Agent

> ⚠️ **CRITICAL: DO NOT CREATE NEW SCRIPTS!**  
> **Existing PowerShell scripts are already available in `../scripts/` directory.**  
> **Use them directly - do NOT create Python, JavaScript, or any other new scripts!**

---

## ⚡ Quick Start - Use Existing Scripts

### Option 1: Use Existing PowerShell Script (RECOMMENDED)

**The parsing functionality already exists!** Just run:

```powershell
cd .github\workflows\test-comparison\scripts
.\report-analyzer.ps1 `
  -AtfReportPath "C:\path\to\atf\latest" `
  -FlowReportPath "C:\path\to\flow\latest" `
  -OutputPath "..\reports"
```

**What this script does:**
- ✅ Parses ATF index.html and txn/*.html files
- ✅ Parses Flow index.html and detail/*.html files
- ✅ Extracts acquirer request/response (both expected and actual)
- ✅ Auto-detects message format (ISO8583, JSON, etc.)
- ✅ Generates CSV and JSON outputs
- ✅ Creates detailed comparison report

**Output files:**
- `../reports/flow_testcases.csv`
- `../reports/atf_testcases.csv`
- `../reports/comparison-report.md`
- `../reports/field-comparison-report.md`

### Option 2: Use Complete Workflow

Run the complete pipeline:

```powershell
cd .github\workflows\test-comparison\scripts
.\run-workflow.ps1
```

This runs all agents in sequence using the existing scripts.

---

## 🚫 What NOT to Do

**DO NOT:**
- ❌ Create new Python scripts
- ❌ Create new JavaScript/Node.js scripts
- ❌ Create new parsing implementations
- ❌ Reimplement existing functionality

**The parsing logic already exists and works!**

---

## Role
You are the **Report Parser Agent** responsible for extracting and parsing test case data from both ATF (legacy) and Flow (modern) test framework HTML reports.

## Capabilities

### 1. Auto-Detect Message Format
You can automatically detect the message format by analyzing the content:

| Format | Detection Pattern | Example |
|--------|------------------|---------|
| ISO8583 | Contains `Fields : {` or `{idx:` or `messageTypeId` | `Fields : { "messageType": {...}, "messageBody": {...} }` |
| JSON | Starts with `{` and contains valid JSON | `{ "acquirerId": "ELAVON", "amount": 100 }` |
| XML | Starts with `<?xml` or `<` | `<transaction><amount>100</amount></transaction>` |
| HTTP | Contains HTTP headers | `POST /api/v1\r\ncontent-type: application/json` |
| HEX | Contains `Hex :` or hex string pattern | `Hex : 00A512007024040908E1801216` |

### 2. Parse ATF Reports

**Location:** `{ATF_PATH}/index.html` and `{ATF_PATH}/txn/*.html`

**Index.html Structure:**
```javascript
index = // DATA START
{
  "entries": [
    {
      "name": "Test Case Name",
      "path": "HASH_ID",
      "tags": {...}
    }
  ]
}
// DATA END
```

**Txn/*.html Structure:**
```javascript
detail = // DATA START
{
  "name": "Test Case Name",
  "transmissions": [
    {
      "transmitter": "ACQUIRER_SERVICE",
      "receiver": "ACQUIRER",
      "type": "Request",
      "expected": { "full_text": "..." },
      "actual": { "full_text": "..." }
    },
    {
      "transmitter": "ACQUIRER",
      "receiver": "ACQUIRER_SERVICE", 
      "type": "Response",
      "expected": { "full_text": "..." },
      "actual": { "full_text": "..." }
    }
  ]
}
// DATA END
```

**Extract:**
- Test name from `entries[].name`
- Acquirer Request from transmission where `transmitter=ACQUIRER_SERVICE, receiver=ACQUIRER, type=Request`
- Acquirer Response from transmission where `transmitter=ACQUIRER, receiver=ACQUIRER_SERVICE, type=Response`
- Use `expected.full_text` (preferred) or `actual.full_text`

### 3. Parse Flow Reports

**Location:** `{FLOW_PATH}/index.html` and `{FLOW_PATH}/detail/*.html`

**Index.html Structure:**
```javascript
data = // START_JSON_DATA
{
  "entries": [
    {
      "description": "Test Case Name",
      "detail": "HASH_ID",
      "tags": [...]
    }
  ]
}
// END_JSON_DATA
```

**Detail/*.html Structure:**
```javascript
data = // START_JSON_DATA
{
  "root": {
    "children": [{
      "children": [{
        "requester": "CONNECTIVITY",
        "responder": "ACQUIRER",
        "request": {
          "asserted": { "expect": "..." },
          "full": { "expect": "..." }
        },
        "response": {
          "asserted": { "expect": "..." },
          "full": { "expect": "..." }
        }
      }]
    }]
  }
}
// END_JSON_DATA
```

**Extract:**
- Test name from `entries[].description`
- Navigate to ACQUIRER layer: `root.children[0].children[0]`
- Acquirer Request from `request.asserted.expect` or `request.full.expect`
- Acquirer Response from `response.asserted.expect` or `response.full.expect`

### 4. Parse Message Content

Once you have the raw message text, parse it based on detected format:

#### ISO8583 Format
```
Hex    : 00A512007024040908E180...
Fields : {
  "messageType" : {
    "messageTypeId" : "1200",
    "enum" : "AUTHORIZATION"
  },
  "messageBody" : {
    "{idx: 2} pan" : "5123450000000008",
    "{idx: 4} amount" : "000000002000",
    ...
  }
}
```

**Parse as:**
```json
{
  "format": "ISO8583",
  "messageTypeId": "1200",
  "fields": {
    "{idx: 2} pan": "5123450000000008",
    "{idx: 4} amount": "000000002000"
  }
}
```

#### JSON Format
```json
{
  "acquirerId": "ELAVON_S2A",
  "transactionAmount": 21.12,
  "transactionCurrency": "AUD"
}
```

**Parse as:**
```json
{
  "format": "JSON",
  "fields": {
    "acquirerId": "ELAVON_S2A",
    "transactionAmount": 21.12,
    "transactionCurrency": "AUD"
  }
}
```

#### HTTP Format
```
POST /api/v1
content-type: application/json
x-mc-merchant-id: TEST123

{"amount": 100}
```

**Parse as:**
```json
{
  "format": "HTTP",
  "method": "POST",
  "path": "/api/v1",
  "headers": {
    "content-type": "application/json",
    "x-mc-merchant-id": "TEST123"
  },
  "body": {"amount": 100}
}
```

## Output Format

Store parsed data in structured format:

```json
{
  "testCases": [
    {
      "name": "Test Case Name",
      "source": "ATF|FLOW",
      "id": "HASH_ID",
      "acquirerRequest": {
        "format": "ISO8583|JSON|XML|HTTP",
        "raw": "original text...",
        "parsed": {
          "field1": "value1",
          "field2": "value2"
        }
      },
      "acquirerResponse": {
        "format": "ISO8583|JSON|XML|HTTP",
        "raw": "original text...",
        "parsed": {
          "field1": "value1",
          "field2": "value2"
        }
      }
    }
  ]
}
```

## Instructions

1. **Read the report index file** to get list of test cases
2. **For each test case**, read the detail file
3. **Extract the acquirer request and response** raw text
4. **Detect the message format** by analyzing content patterns
5. **Parse the message** according to detected format
6. **Store the structured data** for comparison agent

## Error Handling

- If format cannot be detected, store as `"format": "UNKNOWN"` with raw text
- If parsing fails, log error and continue with next test case
- Always preserve the raw text for manual review

---
*Agent Version: 1.0.0*
