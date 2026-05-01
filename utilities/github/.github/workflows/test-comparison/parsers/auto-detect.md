# Message Format Auto-Detection

The Report Parser Agent automatically detects message formats by analyzing content patterns.

## Detection Algorithm

```
function detectMessageFormat(content):
    IF content contains "Fields : {" AND contains "{idx:"
        RETURN "ISO8583"
    
    ELSE IF content starts with "<?xml" OR content starts with "<"
        RETURN "XML"
    
    ELSE IF content contains "HTTP/" OR starts with "POST " OR starts with "GET "
        RETURN "HTTP"
    
    ELSE IF content starts with "{" AND is valid JSON
        IF contains "messageType" AND contains "messageBody"
            RETURN "ISO8583"  # ISO8583 in JSON format
        ELSE
            RETURN "JSON"
    
    ELSE
        RETURN "UNKNOWN"
```

## Format Patterns

### ISO8583 Format

**Detection Patterns:**
- Contains `Fields : {`
- Contains `{idx:` field markers
- Contains `messageTypeId` with 4-digit value (1200, 1210, etc.)

**Example:**
```
Hex    : 00A512007024040908E180...
Fields : {
  "messageType" : {
    "messageTypeId" : "1200",
    "enum" : "AUTHORIZATION"
  },
  "messageBody" : {
    "{idx: 2} pan" : "5123450000000008",
    "{idx: 4} amount" : "000000002000"
  }
}
```

### JSON Format

**Detection Patterns:**
- Starts with `{`
- Valid JSON structure
- Does NOT contain ISO8583 markers

**Example:**
```json
{
  "acquirerId": "ELAVON_S2A",
  "transactionAmount": 21.12,
  "transactionCurrency": "AUD",
  "paymentInstrument": {
    "card": {
      "number": "5123450000000008"
    }
  }
}
```

### HTTP Format

**Detection Patterns:**
- Contains `HTTP/1.1` or `HTTP/2`
- Starts with HTTP method: `POST`, `GET`, `PUT`, `DELETE`
- Contains headers with `:` separator

**Example:**
```
POST /api/v1/authorize HTTP/1.1
content-type: application/json
x-mc-merchant-id: TEST123

{"amount": 100}
```

### XML Format

**Detection Patterns:**
- Starts with `<?xml`
- Starts with `<` followed by tag name

**Example:**
```xml
<?xml version="1.0"?>
<transaction>
  <amount>100.00</amount>
  <currency>USD</currency>
</transaction>
```

## Parsing Strategy

Once format is detected, apply appropriate parser:

| Format | Parser | Output |
|--------|--------|--------|
| ISO8583 | Extract from `messageBody` | Flat field map |
| JSON | Flatten nested structure | Flat field map |
| HTTP | Split headers and body | Headers + Body fields |
| XML | Convert to JSON then flatten | Flat field map |

## Handling Unknown Formats

If format cannot be detected:
1. Store raw content as-is
2. Mark format as "UNKNOWN"
3. Log warning for manual review
4. Continue processing other test cases

```json
{
  "format": "UNKNOWN",
  "raw": "original content here",
  "parsed": null,
  "warning": "Could not detect message format"
}
```

## Customizing Detection

Add custom patterns in `config/workflow-config.yaml`:

```yaml
parser:
  custom_patterns:
    - name: "CUSTOM_FORMAT"
      pattern: "CUSTOM_HEADER:"
      parser: "custom_parser_function"
```

---
*Auto-Detection Version: 1.0.0*
