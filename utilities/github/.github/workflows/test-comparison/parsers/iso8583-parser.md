# ISO8583 Message Parser

This parser handles ISO 8583 financial transaction messages commonly used in card payment systems.

## Message Structure

ISO8583 messages in reports typically appear in this format:

```
Hex    : 00A512007024040908E180121651234500000000080000000000000020000000582105...
Fields : {
  "messageType" : {
    "messageTypeId" : "1200",
    "enum" : "AUTHORIZATION"
  },
  "messageBody" : {
    "{idx: 2} pan" : "5123450000000008",
    "{idx: 3} processingCode" : "000000",
    "{idx: 4} amount" : "000000002000",
    "{idx: 11} systemTrace" : "000058",
    "{idx: 14} expiry" : "2105",
    "{idx: 22} posDataCode" : {
      "inputCapability" : "1",
      "authCapability" : "0",
      ...
    },
    ...
  }
}
```

## Field Index Reference

| Index | Field Name | Description | Format |
|-------|-----------|-------------|--------|
| 2 | PAN | Primary Account Number | N..19 |
| 3 | Processing Code | Transaction type | N6 |
| 4 | Amount | Transaction amount | N12 |
| 11 | System Trace | Audit number | N6 |
| 12 | Local Date/Time | Transaction time | N12 (YYMMDDhhmmss) |
| 14 | Expiry | Card expiry | N4 (YYMM) |
| 22 | POS Data Code | Point of service info | AN12 |
| 28 | Reconciliation Date | Settlement date | N6 |
| 29 | Reconciliation Number | Batch number | N3 |
| 32 | Acquiring Institution | Acquirer ID | N..11 |
| 37 | Reference Number | Retrieval reference | AN12 |
| 38 | Approval Code | Authorization code | AN6 |
| 39 | Action Code | Response code | N3 |
| 41 | Terminal ID | Card acceptor terminal | AN8 |
| 42 | Merchant ID | Card acceptor ID | AN15 |
| 43 | Card Acceptor | Name and location | AN40 |
| 48 | Additional Private Data | TLV encoded data | ANS...999 |
| 49 | Currency Code | Transaction currency | N3 |
| 60 | Reserved Private Data | Custom data | ANS...999 |
| 63 | Reserved Private Data 3 | Custom data | ANS...999 |

## Parsing Algorithm

```python
def parse_iso8583(content):
    fields = {}
    
    # Extract Fields JSON section
    match = regex.search(r'Fields\s*:\s*(\{[\s\S]*\})', content)
    if not match:
        return None
    
    json_str = match.group(1)
    data = json.parse(json_str)
    
    # Extract message type
    if data.messageType:
        fields['messageTypeId'] = data.messageType.messageTypeId
    
    # Extract message body fields
    for key, value in data.messageBody:
        if is_nested_object(value):
            # Flatten nested fields
            for sub_key, sub_value in value:
                fields[f"{key}.{sub_key}"] = sub_value
        else:
            fields[key] = value
    
    return fields
```

## Nested Field Handling

Some fields contain nested objects that need flattening:

### POS Data Code (idx: 22)
```json
"{idx: 22} posDataCode" : {
  "inputCapability" : "1",
  "authCapability" : "0",
  "captureCapability" : "0",
  "operatingEnvironment" : "0",
  "cardholderPresent" : "2",
  "cardPresent" : "0",
  "inputMode" : "1",
  "authMethod" : "0",
  "authEntity" : "0",
  "cardDataOutputCapability" : "1",
  "terminalOutputCapability" : "0",
  "pinCaptCapability" : "0"
}
```

**Flattened to:**
```
{idx: 22} posDataCode.inputCapability = "1"
{idx: 22} posDataCode.authCapability = "0"
{idx: 22} posDataCode.captureCapability = "0"
...
```

### Additional Private Data (idx: 48)
```json
"{idx: 48} additionalPrivateData" : {
  "{tag: 0001} itemNumber" : "001",
  "{tag: 0002} elavonStan" : "654321",
  "{tag: 0003} elavonDateTime" : "171213091512",
  "{tag: 0004} elavonRrn" : "123456679012"
}
```

### Reserved Private Data 3 (idx: 63)
```json
"{idx: 63} reservedPrivateData3" : {
  "{tag: 04} moto" : "1",
  "{tag: 15} acceptanceIndicatorCardSchemeData" : "Y",
  "{tag: 44} scaStatusIndicator" : "2",
  "{tag: 65} mastercardMerchantPaymentGatewayID" : "00000237378"
}
```

## Message Types

| MTI | Type | Description |
|-----|------|-------------|
| 1200 | Authorization Request | Initial auth request |
| 1210 | Authorization Response | Auth response |
| 1220 | Financial Request | Capture request |
| 1230 | Financial Response | Capture response |
| 1420 | Reversal Request | Void/reversal |
| 1430 | Reversal Response | Reversal response |

## Output Format

```json
{
  "format": "ISO8583",
  "messageTypeId": "1200",
  "fields": {
    "{idx: 2} pan": "5123450000000008",
    "{idx: 4} amount": "000000002000",
    "{idx: 22} posDataCode.inputCapability": "1",
    "{idx: 22} posDataCode.cardholderPresent": "2",
    "{idx: 49} currencyCode": "036"
  }
}
```

---
*ISO8583 Parser Version: 1.0.0*
