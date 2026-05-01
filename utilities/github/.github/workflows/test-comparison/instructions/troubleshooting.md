# Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: Report Files Not Found

**Symptom:**
```
ERROR: ATF index.html not found
ERROR: Flow index.html not found
```

**Solution:**
1. Verify the report paths in `config/workflow-config.yaml`
2. Ensure tests have been run and reports generated
3. Check the `latest` symlink points to actual report folder

```powershell
# Verify ATF report exists
Test-Path "C:\path\to\atf\latest\index.html"

# Verify Flow report exists
Test-Path "C:\path\to\flow\latest\index.html"
```

---

### Issue 2: No Test Cases Matched

**Symptom:**
```
Matched: 0 test pairs
Unmatched Flow tests: 70
```

**Solution:**
1. Check test case naming conventions
2. Review normalization rules in config
3. Manually inspect test names in both reports

```yaml
# Adjust matching in config/workflow-config.yaml
matching:
  normalize:
    - pattern: "\\bMOTO\\b"
      replacement: "MAIL_ORDER"
```

---

### Issue 3: JSON Parse Error

**Symptom:**
```
ERROR: Unrecognized escape sequence
ERROR: Failed to parse JSON
```

**Solution:**
1. The report may contain embedded HTML/special characters
2. Use regex-based extraction instead of JSON parsing
3. Agent will automatically handle escape sequences

---

### Issue 4: Empty Acquirer Request/Response

**Symptom:**
```
HasAcquirerRequest: NO
HasAcquirerResponse: NO
```

**Solution:**
1. Check the transmission filter settings
2. Verify the report structure matches expected format
3. For ATF: Check `transmitter`, `receiver`, `type` filters
4. For Flow: Check navigation path to ACQUIRER layer

```yaml
# ATF filter settings
atf:
  acquirer_request:
    transmitter: "ACQUIRER_SERVICE"
    receiver: "ACQUIRER"
    type: "Request"
```

---

### Issue 5: Different Message Formats

**Symptom:**
```
ATF uses ISO8583, Flow uses JSON
Fields don't match
```

**Solution:**
1. Enable cross-format field mapping
2. Review `config/field-mappings.yaml`
3. Add custom mappings as needed

```yaml
# Add mapping
"{idx: 2} pan":
  json_path: "paymentInstrument.card.number"
```

---

### Issue 6: Too Many Dynamic Fields Marked as Different

**Symptom:**
```
systemTrace: DIFFERENT
localDateTime: DIFFERENT
referenceNumber: DIFFERENT
```

**Solution:**
1. Add fields to dynamic_fields list in config
2. These fields change on each test run

```yaml
comparison:
  dynamic_fields:
    - "{idx: 11} systemTrace"
    - "{idx: 12} localDateTime"
```

---

### Issue 7: PowerShell Script Encoding Issues

**Symptom:**
```
Special characters appear garbled
Unicode errors
```

**Solution:**
1. Ensure files are saved as UTF-8
2. Use `-Encoding UTF8` parameter

```powershell
Get-Content -Path $file -Encoding UTF8
Set-Content -Path $file -Encoding UTF8
```

---

### Issue 8: Large Report Performance

**Symptom:**
```
Script takes too long
Memory issues with large reports
```

**Solution:**
1. Process reports in batches
2. Use streaming for large files
3. Increase PowerShell memory limit

```powershell
# Increase memory
$MaximumHistoryCount = 32767
```

---

## Debug Mode

Enable debug logging:

```yaml
# In config/workflow-config.yaml
logging:
  level: "DEBUG"
```

This will output detailed parsing information.

---

## Getting Help

1. Check agent documentation in `agents/` folder
2. Review configuration options in `config/` folder
3. Ask the AI agent for specific help:

```
I'm getting error X when running the test comparison workflow. 
Here's the error message: [paste error]
```

---
*Troubleshooting Guide Version: 1.0.0*
