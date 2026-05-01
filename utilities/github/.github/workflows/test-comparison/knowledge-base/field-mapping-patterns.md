# Field Mapping Patterns Knowledge Base

> **Auto-generated and maintained by Test Fixer Agent**
> Last Updated: 2026-01-22

This file stores discovered field mapping patterns from mapper classes.
When a new field mapping issue is found, the agent analyzes the mapper and stores the pattern here.

---

## Discovered Mapping Patterns

### 1. CardSchemeData (Field 63.16)

**Discovery Date:** 2026-01-22  
**Mapper Class:** `TspiToElavonMessageMapper.java`  
**Method:** `getCardSchemeData()`  
**Lines:** 868-907

#### Pattern Description
The `cardSchemeData` field value is constructed dynamically based on card type:

```java
switch ( t.cardType() ) {
    case AE:
        cardSchemeData = "A" + financialNetworkTransactionId;
        break;
    case DC:
        cardSchemeData = "D" + financialNetworkTransactionId;
        break;
    case MC:
    case MS:
        cardSchemeData = "M" + pad(financialNetworkTransactionId, 15) + pad(financialNetworkDate, 4);
        break;
    case VC:
    case VD:
        cardSchemeData = returnAci + pad(financialNetworkTransactionId, 15) + pad(validationCode, 4) + pad(cardLevelIndicator, 2);
        break;
}
```

#### Key Insight
- **Visa does NOT use fixed "V" prefix** - it uses `returnAci` from response
- Common `returnAci` values: `D`, `Y`, `N`, `A`, ` ` (space)

#### Test Value Patterns
| Card Type | Expected Format | Example |
|-----------|-----------------|---------|
| Mastercard | `M` + 15 chars + 4 chars | `M2505241605151111712  ` |
| Visa | `{returnAci}` + 15 chars + 4 chars + 2 chars | `D250524160515111789012` |
| Amex | `A` + transactionId | `A250524160515111789012` |
| Diners | `D` + transactionId | `D2505241605151111712  ` |

---

### 2. SCA Status Indicator (Field 63.44)

**Discovery Date:** 2026-01-22  
**Applicable Schemes:** Mastercard, Maestro only

#### Pattern Description
- Only included in request for Mastercard/Maestro schemes
- Must be DELETEd for Visa, Amex, Diners, Discover, JCB

#### Test Configuration
```java
// For Mastercard
rq("63.44", "2")  // Include

// For Visa, Diners, etc.
rq("63.44", DELETE)  // Remove
```

---

### 3. Mastercard Merchant Payment Gateway ID (Field 63.65)

**Discovery Date:** 2026-01-22  
**Applicable Schemes:** Mastercard, Maestro only

#### Pattern Description
- Only included in request for Mastercard/Maestro schemes
- Value: `00000237378` (11 digits)
- Must be DELETEd for other schemes

#### Test Configuration
```java
// For Mastercard
rq("63.65", "00000237378")  // Include

// For Visa, Diners, etc.
rq("63.65", DELETE)  // Remove
```

---

## Pattern Discovery Log

| Date | Field | Discovery | Source Method | Notes |
|------|-------|-----------|---------------|-------|
| 2026-01-22 | 63.16 | Visa uses returnAci prefix | `getCardSchemeData()` | Not fixed "V" prefix |
| 2026-01-22 | 63.44 | MC/Maestro only | N/A | DELETE for other schemes |
| 2026-01-22 | 63.65 | MC/Maestro only | N/A | DELETE for other schemes |

---

## How to Add New Patterns

When the agent discovers a new mapping pattern:

1. Analyze the mapper class for the field logic
2. Document the switch/case or conditional logic
3. Record the pattern with examples
4. Update test configurations accordingly
5. Add entry to Pattern Discovery Log
