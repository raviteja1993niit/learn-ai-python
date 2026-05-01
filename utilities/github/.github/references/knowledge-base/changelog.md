# Changelog
> All changes made to YAML spec files by this agent

## Format
```
### [VERSION] - [DATE]
**File:** [filename]
**Schema:** [schema name]
**Changed:** [description]
**Reason:** [why]
**Before:** [previous state]
**After:** [new state]
**Rollback:** [how to undo]
```

---

## Change History

### v1.0.4 - 2026-02-25
**File:** `card-payment-connectivity-api.yaml`
**Schema:** `Verification.serviceProviderTransactionProcessing` (line ~5445)
**Changed:** Added `authorizationCode` property
**Reason:** The Verification response's `serviceProviderTransactionProcessing` block was missing `authorizationCode`, which is returned by the issuer on an approved verification. `Authorization.serviceProviderTransactionProcessing` carries it (line ~1050) — parity alignment.
**Added:**
```yaml
authorizationCode:
  $ref: '#/components/schemas/AuthorizationCode'
```
**`$ref` target:** `AuthorizationCode` — string, min 1, max 100, defined at line ~1193 in `card-payment-connectivity-api.yaml`
**Placement:** Alphabetical — between `authenticationTokenVerificationCode` and `avsCode`
**Optional:** Yes — response field, not in `required`
**Rollback:** Remove `authorizationCode` property from `Verification.serviceProviderTransactionProcessing`
**Cross-file impact:** `AcquirerVerification` in `acquirer-card-payment-connectivity-api.yaml` uses `allOf` referencing `Verification` — inherits the new field automatically. No additional changes needed.

---

### v1.0.3 - 2026-02-25
**File:** `acquirer-card-payment-connectivity-api.yaml`
**Schema:** `AcquirerVerificationSubmission` (line ~458)
**Changed:** Added `partialAmountSupport` property
**Reason:** Acquirer verification submission needs to signal whether partial amount processing is supported, consistent with how `AuthorizationSubmission` (line ~3168) carries this field.
**Added:**
```yaml
partialAmountSupport:
  $ref: './card-payment-connectivity-api.yaml#/components/schemas/PartialAmountSupport'
```
**`$ref` target:** `PartialAmountSupport` — boolean, `default: false`, defined at line ~4766 in `card-payment-connectivity-api.yaml`
**Optional:** Yes — `default: false` means it is not required; omitting it implies the transaction cannot be processed for partial amount.
**Rollback:** Remove `partialAmountSupport` property block from `AcquirerVerificationSubmission.properties`
**Cross-file impact:** None — base `VerificationSubmission` unchanged; acquirer overlay only

---

### v1.0.2 - 2026-02-25
**File:** `acquirer-card-payment-connectivity-api.yaml`
**Schema:** `AcquirerVerificationSubmission` (line ~456)
**Changed:** Added `authorizationAmountIndicator` property
**Reason:** Acquirer-layer verification submission needs to carry the authorization amount indicator to indicate whether the amount is final or pre-authorized, consistent with acquirer processing requirements.
**Before:** Schema had `acquirerConfigurations` and `systemTraceAuditNumber` only in properties
**After:** Added:
```yaml
authorizationAmountIndicator:
  $ref: './card-payment-connectivity-api.yaml#/components/schemas/AuthorizationAmountIndicator'
```
**`$ref` target:** `AuthorizationAmountIndicator` — string enum, `FINAL_AMOUNT` (default) | `PRE_AUTHORIZED_AMOUNT`, defined at line ~1182 in `card-payment-connectivity-api.yaml`
**Rollback:** Remove `authorizationAmountIndicator` property block from `AcquirerVerificationSubmission.properties`
**Cross-file impact:** None — field is optional (not added to `required`), base `VerificationSubmission` unchanged

---

### v1.0.1 - 2026-02-25
**File:** `card-payment-connectivity-api.yaml`
**Schema:** `VerificationSubmission` (~line 5507)
**Changed:** Added `transactionType` to the `required:` array
**Reason:** Verification payloads always include `transactionType: "VERIFICATION"`. The field existed in `properties` referencing `TransactionType` enum (which includes `VERIFICATION`), but was not enforced as required. Aligned with business contract and user payload example.
**Before required list:**
```yaml
required:
  - acquirerId
  - cardType
  - merchant
  - paymentInstrument
  - paymentSource
  - submissionTimestamp
  - transactionCurrency
  - transactionId
  - orderId
```
**After required list:**
```yaml
required:
  - acquirerId
  - cardType
  - merchant
  - paymentInstrument
  - paymentSource
  - submissionTimestamp
  - transactionCurrency
  - transactionId
  - orderId
  - transactionType
```
**Rollback:** Remove `- transactionType` from the `required:` list of `VerificationSubmission`
**Cross-file impact:** `AcquirerVerificationSubmission` in `acquirer-card-payment-connectivity-api.yaml` uses `allOf` referencing `VerificationSubmission` — inherits the updated required list automatically. No additional changes needed.

---

### v1.0.0 - 2026-02-25
**Changed:** Agent created by yaml-spec-agent builder
**Files:** All agent files created
**Rollback:** N/A

---

## Quick Stats
| Metric | Value |
|--------|-------|
| Total Changes | 4 |
| Files Modified | 2 |
| Last Updated | 2026-02-25 |
| Breaking Changes | 0 |

---
*Maintained automatically — max 100 entries*
