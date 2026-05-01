# JSON Message Parser

This parser handles JSON-formatted messages commonly used in modern REST APIs.

## Message Structure

JSON messages can be simple or deeply nested:

### Simple JSON
```json
{
  "acquirerId": "ELAVON_S2A",
  "transactionAmount": 21.12,
  "transactionCurrency": "AUD"
}
```

### Nested JSON
```json
{
  "acquirerId": "ELAVON_S2A",
  "merchant": {
    "acquirerMerchantId": "M12345",
    "name": "Retail Computers",
    "address": {
      "city": "New York",
      "country": "US"
    }
  },
  "paymentInstrument": {
    "card": {
      "number": "5123450000000008",
      "expiryMonth": 12,
      "expiryYear": 99
    }
  }
}
```

## Parsing Algorithm

```python
def parse_json(content):
    fields = {}
    
    # Parse JSON
    data = json.parse(content)
    
    # Flatten nested structure
    flatten(data, "", fields)
    
    return fields

def flatten(obj, prefix, fields):
    if is_primitive(obj):
        fields[prefix] = obj
    elif is_array(obj):
        for i, item in enumerate(obj):
            flatten(item, f"{prefix}[{i}]", fields)
    elif is_object(obj):
        for key, value in obj:
            new_prefix = f"{prefix}.{key}" if prefix else key
            flatten(value, new_prefix, fields)
```

## Flattening Examples

### Input
```json
{
  "merchant": {
    "name": "Test Shop",
    "address": {
      "city": "NYC"
    }
  },
  "items": [
    {"name": "Item1"},
    {"name": "Item2"}
  ]
}
```

### Output (Flattened)
```
merchant.name = "Test Shop"
merchant.address.city = "NYC"
items[0].name = "Item1"
items[1].name = "Item2"
```

## Common JSON Fields (Connectivity API)

| Field Path | Description | Example |
|------------|-------------|---------|
| acquirerId | Acquirer identifier | "ELAVON_S2A" |
| transactionAmount | Amount in decimal | 21.12 |
| transactionCurrency | Currency code | "AUD" |
| transactionType | Transaction type | "AUTHORIZATION" |
| paymentSource | Payment source | "MAIL_ORDER" |
| paymentInstrument.card.number | Card number | "5123450000000008" |
| paymentInstrument.card.expiryMonth | Expiry month | 12 |
| paymentInstrument.card.expiryYear | Expiry year | 99 |
| merchant.acquirerMerchantId | Merchant ID | "M12345" |
| merchant.name | Merchant name | "Retail Computers" |
| merchant.categoryCode | MCC | "5542" |
| pointOfService.terminalId | Terminal ID | "123455" |
| serviceProviderTransactionProcessing.responseCode | Response code | "000" |
| serviceProviderTransactionProcessing.authorizationCode | Auth code | "123456" |

## HTTP with JSON Body

When JSON is embedded in HTTP request/response:

```
POST /api/v1/authorize HTTP/1.1
content-type: application/json
x-mc-merchant-id: TEST123

{
  "amount": 100,
  "currency": "USD"
}
```

**Parsing:**
1. Extract headers (key: value pairs before blank line)
2. Extract body (content after blank line)
3. Parse body as JSON
4. Combine headers and body fields

```
headers.content-type = "application/json"
headers.x-mc-merchant-id = "TEST123"
body.amount = 100
body.currency = "USD"
```

## Array Handling

For arrays of objects with `id` fields, use ID as key:

```json
{
  "acquirerConfigurations": [
    {"id": "mpgId", "value": "123456"},
    {"id": "timezone", "value": "UTC"}
  ]
}
```

**Output:**
```
acquirerConfigurations[id=mpgId].value = "123456"
acquirerConfigurations[id=timezone].value = "UTC"
```

## Output Format

```json
{
  "format": "JSON",
  "fields": {
    "acquirerId": "ELAVON_S2A",
    "transactionAmount": 21.12,
    "merchant.name": "Test Shop",
    "paymentInstrument.card.number": "5123450000000008"
  }
}
```

---
*JSON Parser Version: 1.0.0*
