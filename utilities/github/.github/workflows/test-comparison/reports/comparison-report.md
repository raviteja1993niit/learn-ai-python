# ATF vs Flow - Detailed Field Comparison Report

**Generated:** 2026-01-22 20:08:02
**Report Version:** 6.0
**Enhancement:** Now includes BOTH expected and actual values from BOTH ATF and Flow test reports for complete 4-way comparison

---

## Summary

| Metric | Count |
|--------|-------|
| Flow Test Cases (Total) | 16 |
| ATF Test Cases | 40 |
| Matched Test Pairs | 8 |
| Unmatched Flow Tests (No ATF) | 8 |

---

## All Flow Test Cases

| # | Test Name | Has ATF Match | ATF Req (Exp) | ATF Req (Act) | ATF Resp (Exp) | ATF Resp (Act) | Flow Req (Exp) | Flow Req (Act) | Flow Resp (Exp) | Flow Resp (Act) |
|---|-----------|---------------|---------------|---------------|----------------|----------------|----------------|----------------|-----------------|-----------------|
| 1 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 2 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 3 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 4 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 5 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 6 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 7 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 8 | All Currencies Valid Auth Card No, Currency and Transacti... | NO | - | - | - | - | YES | YES | YES | YES |
| 9 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| 10 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| 11 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| 12 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| 13 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| 14 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| 15 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| 16 | All Currencies Valid Auth Card No, Currency and Transacti... | YES | YES | YES | YES | YES | YES | YES | YES | YES |

---

## Detailed Field Comparison for Each Test Case

---

## Test Case 1 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 AUD MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 AUD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 036 | 036 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 036 | 036 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 2 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 CAD MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 CAD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 124 | 124 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 124 | 124 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 3 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 EUR MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 EUR MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 978 | 978 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 978 | 978 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 4 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 GBP MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 GBP MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 826 | 826 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 826 | 826 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 5 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 MXN MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 MXN MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 484 | 484 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 484 | 484 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 6 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 NZD MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 NZD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 554 | 554 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 554 | 554 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 7 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 SGD MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 SGD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 702 | 702 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 702 | 702 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 8 : All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 USD MAIL_ORDER [NO ATF MATCH]

**ATF Test:** *(No matching ATF test found)*

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 USD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 000001 | 000001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 14} expiry | - | - | 9912 | 9912 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authEntity | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.authMethod | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.captureCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardDataOutputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardholderPresent | - | - | 2 | 2 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.cardPresent | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputCapability | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.inputMode | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.operatingEnvironment | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.pinCaptCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 22} posDataCode.terminalOutputCapability | - | - | 0 | 0 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 000005 | 000005 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 43} cardAcceptor | - | - | Retail Computers pvt limite... | Retail Computers pvt limite... | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 840 | 840 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | - | - | 3765WMTT | 3765WMTT | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | - | - | 1 | 1 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1200 | 1200 | [MISSING IN ATF] | Field not present in ATF |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | - | - | 012345 | 012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 12} localDateTime | - | - | 250524160515 | 250524160515 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 2} pan | - | - | 4508750015741019 | 4508750015741019 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 28} reconciliationDate | - | - | 250524 | 250524 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 29} reconciliationNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 32} acquiringInstitutionIdCode | - | - | 0100860099 | 0100860099 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 37} referenceNumber | - | - | 250524012345 | 250524012345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 38} approvalCode | - | - | 123456 | 123456 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 39} actionCode | - | - | 000 | 000 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 4} amount | - | - | 000000002112 | 000000002112 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 41} terminalId | - | - | 00123455 | 00123455 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 42} merchantId | - | - | M12345 | M12345 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | - | - | 001 | 001 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | - | - | 654321 | 654321 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | - | - | 171213091512 | 171213091512 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | - | - | 123456679012 | 123456679012 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 49} currencyCode | - | - | 840 | 840 | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | - | - | Y | Y | [MISSING IN ATF] | Field not present in ATF |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | - | - | V2505241605151111712   | D250524160515111789012 | [FLOW MISMATCH] | Flow expected != actual |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | - | - | utrn1236325 | utrn1236325 | [MISSING IN ATF] | Field not present in ATF |
| messageTypeId | - | - | 1210 | 1210 | [MISSING IN ATF] | Field not present in ATF |

---

## Test Case 9 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 AUD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 AUD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 AUD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 036 | 036 | 036 | 036 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 036 | 036 | 036 | 036 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |

---

## Test Case 10 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 CAD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 CAD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 CAD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 124 | 124 | 124 | 124 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 124 | 124 | 124 | 124 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |

---

## Test Case 11 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 EUR MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 EUR MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 EUR MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 978 | 978 | 978 | 978 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 978 | 978 | 978 | 978 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |

---

## Test Case 12 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 GBP MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 GBP MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 GBP MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 826 | 826 | 826 | 826 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 826 | 826 | 826 | 826 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |

---

## Test Case 13 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 MXN MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 MXN MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 MXN MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 484 | 484 | 484 | 484 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 484 | 484 | 484 | 484 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |

---

## Test Case 14 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 NZD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 NZD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 NZD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 554 | 554 | 554 | 554 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 554 | 554 | 554 | 554 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |

---

## Test Case 15 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 SGD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 SGD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 SGD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 702 | 702 | 702 | 702 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 702 | 702 | 702 | 702 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |

---

## Test Case 16 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 USD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 USD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 USD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 000001 | 000001 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | - | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 14} expiry | 2105 | 2105 | 9912 | 9912 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authEntity | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.authMethod | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardholderPresent | 2 | 2 | 2 | 2 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.inputMode | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | 0 | 0 | [PERFECT MATCH] | All 4 values match |
| {idx: 28} reconciliationDate | - | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [PERFECT MATCH] | All 4 values match |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 000005 | 000005 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | nameOfMerchant        Brisbane | Retail Computers pvt limite... | Retail Computers pvt limite... | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [PERFECT MATCH] | All 4 values match |
| {idx: 49} currencyCode | 840 | 840 | 840 | 840 | [PERFECT MATCH] | All 4 values match |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WMTT | 3765WMTT | 3765WMTT | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 1 | 1 | 1 | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [PERFECT MATCH] | All 4 values match |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | 2 | 2 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | 00000237378 | 00000237378 | - | [FLOW MISMATCH] | Field in Flow Expected but MISSING in Flow Actual |
| messageTypeId | 1200 | 1200 | 1200 | 1200 | [PERFECT MATCH] | All 4 values match |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Expected | ATF Actual | Flow Expected | Flow Actual | Match Status | Notes |
|-------|--------------|------------|---------------|-------------|--------------|-------|
| {idx: 11} systemTrace | 000058 | 000058 | 012345 | 012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 12} localDateTime | 200103130631 | 200103130631 | 250524160515 | 250524160515 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | 5123450000000008 | 5123450000000008 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 28} reconciliationDate | 200103 | 200103 | 250524 | 250524 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 29} reconciliationNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 3} processingCode | 000000 | 000000 | - | - | [MISSING IN FLOW] | Field not present in Flow |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | 0100860099 | 0100860099 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 37} referenceNumber | 0085000058 | 0085000058 | 250524012345 | 250524012345 | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 38} approvalCode | 100000 | 100000 | 123456 | 123456 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 39} actionCode | 000 | 000 | 000 | 000 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 4} amount | 000000002000 | 000000002000 | 000000002112 | 000000002112 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 41} terminalId | 00000002 | 00000002 | 00123455 | 00123455 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 42} merchantId | 12345678 | 12345678 | M12345 | M12345 | [DIFFERENT] | Values differ between ATF and Flow |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | 001 | 001 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | 654321 | 654321 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | 171213091512 | 171213091512 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | 123456679012 | 123456679012 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 49} currencyCode | 840 | 840 | 840 | 840 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | Y | Y | [EXPECTED MATCH] | Expected values match (actual may differ) |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2001031306311111712   | M2505241605151111712   | M2505241605151111712   | [DYNAMIC] | Dynamic field - differences expected |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | utrn1236325 | utrn1236325 | [EXPECTED MATCH] | Expected values match (actual may differ) |
| messageTypeId | 1210 | 1210 | 1210 | 1210 | [EXPECTED MATCH] | Expected values match (actual may differ) |
