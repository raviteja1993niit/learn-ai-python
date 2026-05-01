# Acquirer Configuration Knowledge Base

> **Auto-generated and maintained by Test Fixer Agent**
> Last Updated: 2026-01-22

This file stores discovered acquirer configurations to avoid repeated analysis.
The agent will read from this file first before asking the user.

---

## Elavon S2A Acquirer

### Basic Information
| Property | Value |
|----------|-------|
| Acquirer Name | Elavon |
| Acquirer ID | `ELAVON_S2A` |
| Protocol | ISO 8583 |
| Project Pattern | `*-elavon-*` or `acqelavon*` |

### Key File Locations

#### Test Data Module
```
Module: lib-elavon-interface-test-data
Path: lib-elavon-interface-test-data/src/main/java/com/mastercard/pgs/connectivity/acquirer/flow/
```

| File Type | Path | Purpose |
|-----------|------|---------|
| Base Messages | `msg/Acquirer.java` | AUTH_REQ, AUTH_RES base templates |
| Test Message | `msg/ElavonTestMessage.java` | Test message wrapper |
| Auth Tests | `model/ElavonAuthTransactions.java` | Authorization test flows |
| Card Data | `utility/CardData.java` | Card number definitions by scheme |

#### Message Module
```
Module: lib-elavon-interface-message
Path: lib-elavon-interface-message/src/main/java/com/mastercard/pgs/connectivity/acquirer/elavon/message/
```

| File Type | Path | Purpose |
|-----------|------|---------|
| Message Envelope | `ElavonMessage.java` | Main message container |
| Message Body | `ElavonMessageBody.java` | Field definitions (ISO 8583) |
| Reserved Data 3 | `ReservedPrivateData3.java` | Field 63 sub-fields |
| Additional Data | `AdditionalPrivateData.java` | Field 48 sub-fields |
| POS Data | `PosDataCode.java` | Field 22 sub-fields |

#### Mapping Module
```
Module: lib-elavon-interface-mapping
Path: lib-elavon-interface-mapping/src/main/java/com/mastercard/pgs/connectivity/acquirer/elavon/mapping/
```

| File Type | Path | Purpose |
|-----------|------|---------|
| TSPI to Elavon | `TspiToElavonMessageMapper.java` | Maps TSPI → Elavon ISO 8583 |
| Elavon to TSPI | `ElavonToTspiMessageMapper.java` | Maps Elavon → TSPI response |

---

## Field Mapping Reference

### ISO 8583 Field Index to ElavonMessageBody Method

| Field Index | Field Name | Setter Method | Getter Method |
|-------------|------------|---------------|---------------|
| 2 | PAN | `setPan(String)` | `getPan()` |
| 3 | Processing Code | `setProcessingCode(String)` | `getProcessingCode()` |
| 4 | Amount | `setAmount(String)` | `getAmount()` |
| 11 | System Trace | `setSystemTrace(String)` | `getSystemTrace()` |
| 12 | Local Date Time | `setLocalDateTime(String)` | `getLocalDateTime()` |
| 14 | Expiry | `setExpiry(String)` | `getExpiry()` |
| 22 | POS Data Code | `setPosDataCode(PosDataCode)` | `getPosDataCode()` |
| 28 | Reconciliation Date | `setReconciliationDate(String)` | `getReconciliationDate()` |
| 29 | Reconciliation Number | `setReconciliationNumber(String)` | `getReconciliationNumber()` |
| 32 | Acquiring Institution ID | `setAcquiringInstitutionIdCode(String)` | `getAcquiringInstitutionIdCode()` |
| 37 | Reference Number (RRN) | `setReferenceNumber(String)` | `getReferenceNumber()` |
| 38 | Approval Code | `setApprovalCode(String)` | `getApprovalCode()` |
| 39 | Action Code | `setActionCode(String)` | `getActionCode()` |
| 41 | Terminal ID | `setTerminalId(String)` | `getTerminalId()` |
| 42 | Merchant ID | `setMerchantId(String)` | `getMerchantId()` |
| 43 | Card Acceptor | `setCardAcceptor(String)` | `getCardAcceptor()` |
| 48 | Additional Private Data | `setAdditionalPrivateData(AdditionalPrivateData)` | `getAdditionalPrivateData()` |
| 49 | Currency Code | `setCurrencyCode(String)` | `getCurrencyCode()` |
| 60 | Reserved Private Data | `setReservedPrivateData(ReservedPrivateData)` | `getReservedPrivateData()` |
| 63 | Reserved Private Data 3 | `setReservedPrivateData3(ReservedPrivateData3)` | `getReservedPrivateData3()` |

### Field 63 (ReservedPrivateData3) Sub-fields

| Tag | Field Name | Setter Method | Notes |
|-----|------------|---------------|-------|
| 04 | MOTO | `setMoto(String)` | Mail Order / Telephone Order indicator |
| 15 | Acceptance Indicator | `setAcceptanceIndicatorCardSchemeData(String)` | Card scheme data indicator |
| 16 | Card Scheme Data | `setCardSchemeData(String)` | **Complex mapping - see below** |
| 25 | UTRN | `setUniqueTransactionReferenceNumber(String)` | Unique transaction reference |
| 44 | SCA Status Indicator | `setScaStatusIndicator(String)` | Mastercard only |
| 65 | MC Merchant Payment Gateway ID | `setMastercardMerchantPaymentGatewayID(String)` | Mastercard only |

### Field 48 (AdditionalPrivateData) Sub-fields

| Tag | Field Name | Setter Method | Request/Response |
|-----|------------|---------------|------------------|
| 0001 | Item Number | `setItemNumber(String)` | Both |
| 0002 | Elavon STAN | `setElavonStan(String)` | Response only |
| 0003 | Elavon DateTime | `setElavonDateTime(String)` | Response only |
| 0004 | Elavon RRN | `setElavonRrn(String)` | Response only |

---

## Complex Field Mappings

### CardSchemeData (Field 63.16) - Mapping Logic

**Location:** `TspiToElavonMessageMapper.java` → `getCardSchemeData()` method

The `cardSchemeData` format depends on the **card type**:

| Card Type | Prefix | Format | Total Length |
|-----------|--------|--------|--------------|
| **AE** (American Express) | `A` | `A` + financialNetworkTransactionId | Variable |
| **DC** (Diners Club) | `D` | `D` + financialNetworkTransactionId | Variable |
| **MC/MS** (Mastercard/Maestro) | `M` | `M` + pad(financialNetworkTransactionId, 15) + pad(financialNetworkDate, 4) | 20 |
| **VC/VD** (Visa Credit/Debit) | returnAci | returnAci + pad(financialNetworkTransactionId, 15) + pad(validationCode, 4) + pad(cardLevelIndicator, 2) | 22 |

**Important:** Visa does NOT use a fixed `V` prefix! It uses the `returnAci` value from the response.

**Example Values:**
```
Mastercard: M2505241605151111712  
Visa:       D250524160515111789012  (where D is returnAci)
Diners:     D2505241605151111712  
Amex:       A250524160515111789012
```

---

## Scheme-Specific Field Requirements

### Fields by Card Scheme

| Field | Mastercard | Visa | Amex | Diners | Discover | JCB | Maestro |
|-------|------------|------|------|--------|----------|-----|---------|
| 63.44 (scaStatusIndicator) | ✅ Required | ❌ Delete | ❌ Delete | ❌ Delete | ❌ Delete | ❌ Delete | ✅ Required |
| 63.65 (MPGID) | ✅ Required | ❌ Delete | ❌ Delete | ❌ Delete | ❌ Delete | ❌ Delete | ✅ Required |
| 63.16 (cardSchemeData) | M prefix | returnAci prefix | A prefix | D prefix | D prefix | - | M prefix |

---

## Test Flow Methods

### ElavonAuthTransactions.java - Key Methods

| Method | Purpose | Schemes |
|--------|---------|---------|
| `createCardWhitelistingFlow()` | Standard card whitelisting | MC, Visa, Amex, JCB |
| `createDinersCardWhitelistingFlow()` | Diners-specific flow | Diners |
| `createDiscoverCardWhitelistingFlow()` | Discover-specific flow | Discover |
| `createMaestroCardWhitelistingFlow()` | Maestro-specific flow | Maestro |
| `createMultiCurrencyFlow()` | Multi-currency tests | MC, Visa |

---

## Version History

| Date | Change | Agent |
|------|--------|-------|
| 2026-01-22 | Initial knowledge base created | Test Fixer Agent |
