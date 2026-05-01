# ATF vs Flow - Detailed Field Comparison Report

**Generated:** 2026-01-21 17:33:31
**Report Version:** 4.0

---

## Summary

| Metric | Count |
|--------|-------|
| Flow Test Cases | 70 |
| ATF Test Cases | 40 |
| Matched Test Pairs | 40 |
| Unmatched Flow Tests | 30 |

---

## All Matched Test Cases

| # | Test Name | ATF Req | Flow Req | ATF Resp | Flow Resp |
|---|-----------|---------|----------|----------|-----------|
| 1 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 2 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 3 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 4 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 5 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 6 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 7 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 8 | All Currencies Valid Auth Card No, Currency and Transacti... | [YES] | [YES] | [YES] | [YES] |
| 9 | Invalid Card number 135420001569134 | [YES] | [YES] | [YES] | [YES] |
| 10 | Invalid Card number 5028010000000097 | [YES] | [YES] | [YES] | [YES] |
| 11 | Invalid Card number 5063870000000009 | [YES] | [YES] | [YES] | [YES] |
| 12 | Invalid Card number 5796741302084617 | [YES] | [YES] | [YES] | [YES] |
| 13 | Invalid Card number 6035335024103224 | [YES] | [YES] | [YES] | [YES] |
| 14 | Valid Card No 2223000000000007 | [YES] | [YES] | [YES] | [YES] |
| 15 | Valid Card No 2223000000000023 | [YES] | [YES] | [YES] | [YES] |
| 16 | Valid Card No 371881245560002 | [YES] | [YES] | [YES] | [YES] |
| 17 | Valid Card No 371881911767006 | [YES] | [YES] | [YES] | [YES] |
| 18 | Valid Card No 373953192351004 | [YES] | [YES] | [YES] | [YES] |
| 19 | Valid Card No 5000000000000000005 | [YES] | [YES] | [YES] | [YES] |
| 20 | Valid Card No 5111111111111118 | [YES] | [YES] | [YES] | [YES] |
| 21 | Valid Card No 5123450000000008 | [YES] | [YES] | [YES] | [YES] |
| 22 | Valid Card No 5123456789012346 | [YES] | [YES] | [YES] | [YES] |
| 23 | Valid Card No 5123459999998170 | [YES] | [YES] | [YES] | [YES] |
| 24 | Valid Card No 5123459999998238 | [YES] | [YES] | [YES] | [YES] |
| 25 | Valid Card No 5149612222222229 | [YES] | [YES] | [YES] | [YES] |
| 26 | Valid Card No 5204242750270010 | [YES] | [YES] | [YES] | [YES] |
| 27 | Valid Card No 5413330056003511 | [YES] | [YES] | [YES] | [YES] |
| 28 | Valid Card No 5413330056003560 | [YES] | [YES] | [YES] | [YES] |
| 29 | Valid Card No 5413330089010012 | [YES] | [YES] | [YES] | [YES] |
| 30 | Valid Card No 5413330089601018 | [YES] | [YES] | [YES] | [YES] |
| 31 | Valid Card No 5413339981010012 | [YES] | [YES] | [YES] | [YES] |
| 32 | Valid Card No 5457210089020012 | [YES] | [YES] | [YES] | [YES] |
| 33 | Valid Card No 5473000000000015 | [YES] | [YES] | [YES] | [YES] |
| 34 | Valid Card No 5506900140100107 | [YES] | [YES] | [YES] | [YES] |
| 35 | Valid Card No 5666555544443333 | [YES] | [YES] | [YES] | [YES] |
| 36 | Valid Card No 6799998900000200010 | [YES] | [YES] | [YES] | [YES] |
| 37 | With Acquirer TransactionId Valid Card No 2223000000000007 | [YES] | [YES] | [YES] | [YES] |
| 38 | With Acquirer TransactionId Valid Card No 5123450000000008 | [YES] | [YES] | [YES] | [YES] |
| 39 | With Acquirer TransactionId Valid Card No 5204242750270010 | [YES] | [YES] | [YES] | [YES] |
| 40 | With Acquirer TransactionId Valid Card No 5413330089010012 | [YES] | [YES] | [YES] | [YES] |

---

## Detailed Field Comparison for Each Test Case

---

## Test Case 1 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 AUD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 AUD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 AUD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 036 | 036 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 036 | 036 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 2 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 CAD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 CAD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 CAD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 124 | 124 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 124 | 124 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 3 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 EUR MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 EUR MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 EUR MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 978 | 978 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 978 | 978 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 4 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 GBP MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 GBP MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 GBP MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 826 | 826 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 826 | 826 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 5 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 MXN MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 MXN MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 MXN MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 484 | 484 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 484 | 484 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 6 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 NZD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 NZD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 NZD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 554 | 554 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 554 | 554 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 7 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 SGD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 SGD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 SGD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 702 | 702 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 702 | 702 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 8 : All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 USD MAIL_ORDER

**ATF Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 USD MOTO

**Flow Test:** All Currencies Valid Auth Card No, Currency and Transaction Source : 5123450000000008 USD MAIL_ORDER

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 9 : Invalid Card number 135420001569134

**ATF Test:** Invalid Card number 135420001569134

**Flow Test:** Invalid Card number 135420001569134

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 10 : Invalid Card number 5028010000000097

**ATF Test:** Invalid Card number 5028010000000097

**Flow Test:** Invalid Card number 5028010000000097

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 11 : Invalid Card number 5063870000000009

**ATF Test:** Invalid Card number 5063870000000009

**Flow Test:** Invalid Card number 5063870000000009

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 12 : Invalid Card number 5796741302084617

**ATF Test:** Invalid Card number 5796741302084617

**Flow Test:** Invalid Card number 5796741302084617

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 13 : Invalid Card number 6035335024103224

**ATF Test:** Invalid Card number 6035335024103224

**Flow Test:** Invalid Card number 6035335024103224

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5212345678901234 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 14 : Valid Card No 2223000000000007

**ATF Test:** Valid Card No 2223000000000007

**Flow Test:** Valid Card No 2223000000000007

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 2223000000000007 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 2223000000000007 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 15 : Valid Card No 2223000000000023

**ATF Test:** Valid Card No 2223000000000023

**Flow Test:** Valid Card No 2223000000000023

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 2223000000000023 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 2223000000000023 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 16 : Valid Card No 371881245560002

**ATF Test:** Valid Card No 371881245560002

**Flow Test:** Valid Card No 371881245560002

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 371881245560002 | 371881245560002 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 371881245560002 | 371881245560002 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 17 : Valid Card No 371881911767006

**ATF Test:** Valid Card No 371881911767006

**Flow Test:** Valid Card No 371881911767006

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 371881245560002 | 371881911767006 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 371881245560002 | 371881911767006 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 18 : Valid Card No 373953192351004

**ATF Test:** Valid Card No 373953192351004

**Flow Test:** Valid Card No 373953192351004

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 371881245560002 | 373953192351004 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 371881245560002 | 373953192351004 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 19 : Valid Card No 5000000000000000005

**ATF Test:** Valid Card No 5000000000000000005

**Flow Test:** Valid Card No 5000000000000000005

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5000000000000000005 | 5000000000000000005 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5000000000000000005 | 5000000000000000005 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 20 : Valid Card No 5111111111111118

**ATF Test:** Valid Card No 5111111111111118

**Flow Test:** Valid Card No 5111111111111118

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5111111111111118 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5111111111111118 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 21 : Valid Card No 5123450000000008

**ATF Test:** Valid Card No 5123450000000008

**Flow Test:** Valid Card No 5123450000000008

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 22 : Valid Card No 5123456789012346

**ATF Test:** Valid Card No 5123456789012346

**Flow Test:** Valid Card No 5123456789012346

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5123456789012346 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5123456789012346 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 23 : Valid Card No 5123459999998170

**ATF Test:** Valid Card No 5123459999998170

**Flow Test:** Valid Card No 5123459999998170

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5123459999998170 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5123459999998170 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 24 : Valid Card No 5123459999998238

**ATF Test:** Valid Card No 5123459999998238

**Flow Test:** Valid Card No 5123459999998238

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5123459999998238 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5123459999998238 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 25 : Valid Card No 5149612222222229

**ATF Test:** Valid Card No 5149612222222229

**Flow Test:** Valid Card No 5149612222222229

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5149612222222229 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5149612222222229 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 26 : Valid Card No 5204242750270010

**ATF Test:** Valid Card No 5204242750270010

**Flow Test:** Valid Card No 5204242750270010

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5204242750270010 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5204242750270010 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 27 : Valid Card No 5413330056003511

**ATF Test:** Valid Card No 5413330056003511

**Flow Test:** Valid Card No 5413330056003511

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5413330056003511 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5413330056003511 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 28 : Valid Card No 5413330056003560

**ATF Test:** Valid Card No 5413330056003560

**Flow Test:** Valid Card No 5413330056003560

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5413330056003560 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5413330056003560 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 29 : Valid Card No 5413330089010012

**ATF Test:** Valid Card No 5413330089010012

**Flow Test:** Valid Card No 5413330089010012

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5413330089010012 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5413330089010012 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 30 : Valid Card No 5413330089601018

**ATF Test:** Valid Card No 5413330089601018

**Flow Test:** Valid Card No 5413330089601018

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5413330089601018 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5413330089601018 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 31 : Valid Card No 5413339981010012

**ATF Test:** Valid Card No 5413339981010012

**Flow Test:** Valid Card No 5413339981010012

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5413339981010012 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5413339981010012 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 32 : Valid Card No 5457210089020012

**ATF Test:** Valid Card No 5457210089020012

**Flow Test:** Valid Card No 5457210089020012

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5457210089020012 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5457210089020012 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 33 : Valid Card No 5473000000000015

**ATF Test:** Valid Card No 5473000000000015

**Flow Test:** Valid Card No 5473000000000015

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5473000000000015 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5473000000000015 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 34 : Valid Card No 5506900140100107

**ATF Test:** Valid Card No 5506900140100107

**Flow Test:** Valid Card No 5506900140100107

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5506900140100107 | [DIFFERENT] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5506900140100107 | [DIFFERENT] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 35 : Valid Card No 5666555544443333

**ATF Test:** Valid Card No 5666555544443333

**Flow Test:** Valid Card No 5666555544443333

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5666555544443333 | 5666555544443333 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5666555544443333 | 5666555544443333 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 36 : Valid Card No 6799998900000200010

**ATF Test:** Valid Card No 6799998900000200010

**Flow Test:** Valid Card No 6799998900000200010

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 6799998900000200010 | 6799998900000200010 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 6799998900000200010 | 6799998900000200010 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 37 : With Acquirer TransactionId Valid Card No 2223000000000007

**ATF Test:** With Acquirer TransactionId Valid Card No 2223000000000007

**Flow Test:** With Acquirer TransactionId Valid Card No 2223000000000007

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 2223000000000007 | 2223000000000007 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 2223000000000007 | 2223000000000007 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 38 : With Acquirer TransactionId Valid Card No 5123450000000008

**ATF Test:** With Acquirer TransactionId Valid Card No 5123450000000008

**Flow Test:** With Acquirer TransactionId Valid Card No 5123450000000008

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5123450000000008 | 5123450000000008 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 39 : With Acquirer TransactionId Valid Card No 5204242750270010

**ATF Test:** With Acquirer TransactionId Valid Card No 5204242750270010

**Flow Test:** With Acquirer TransactionId Valid Card No 5204242750270010

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5204242750270010 | 5204242750270010 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5204242750270010 | 5204242750270010 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Test Case 40 : With Acquirer TransactionId Valid Card No 5413330089010012

**ATF Test:** With Acquirer TransactionId Valid Card No 5413330089010012

**Flow Test:** With Acquirer TransactionId Valid Card No 5413330089010012

### ACQUIRER REQUEST - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 000001 | [DYNAMIC] |
| {idx: 12} localDateTime | - | 250524160515 | [MISSING IN ATF] |
| {idx: 14} expiry | 2105 | 9912 | [DIFFERENT] |
| {idx: 2} pan | 5413330089010012 | 5413330089010012 | [MATCH] |
| {idx: 22} posDataCode.authCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authEntity | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.authMethod | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.captureCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.cardDataOutputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.cardholderPresent | 2 | 5 | [DIFFERENT] |
| {idx: 22} posDataCode.cardPresent | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.inputCapability | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.inputMode | 1 | 1 | [MATCH] |
| {idx: 22} posDataCode.operatingEnvironment | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.pinCaptCapability | 0 | 0 | [MATCH] |
| {idx: 22} posDataCode.terminalOutputCapability | 0 | 0 | [MATCH] |
| {idx: 28} reconciliationDate | - | 250524 | [MISSING IN ATF] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 000005 | [DYNAMIC] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 43} cardAcceptor | nameOfMerchant        Brisbane | Retail Computers pvt limite... | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 60} reservedPrivateData.{tag: 01} applicationId | 3765WMTT | 3765WITT | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 04} moto | 1 | 7 | [DIFFERENT] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 44} scaStatusIndicator | 2 | - | [MISSING IN FLOW] |
| {idx: 63} reservedPrivateData3.{tag: 65} mastercardMerchantPaymentGatewayID | 00000237378 | - | [MISSING IN FLOW] |
| messageTypeId | 1200 | 1200 | [MATCH] |

### ACQUIRER RESPONSE - Field Comparison

| Field | ATF Value | Flow Value | Status |
|-------|-----------|------------|--------|
| {idx: 11} systemTrace | 000058 | 012345 | [DYNAMIC] |
| {idx: 12} localDateTime | 200103130631 | 250524160515 | [DYNAMIC] |
| {idx: 2} pan | 5413330089010012 | 5413330089010012 | [MATCH] |
| {idx: 28} reconciliationDate | 200103 | 250524 | [DYNAMIC] |
| {idx: 29} reconciliationNumber | 001 | 001 | [MATCH] |
| {idx: 3} processingCode | 000000 | - | [MISSING IN FLOW] |
| {idx: 32} acquiringInstitutionIdCode | 0100860099 | 0100860099 | [MATCH] |
| {idx: 37} referenceNumber | 0085000058 | 250524012345 | [DYNAMIC] |
| {idx: 38} approvalCode | 100000 | 123456 | [DIFFERENT] |
| {idx: 39} actionCode | 000 | 000 | [MATCH] |
| {idx: 4} amount | 000000002000 | 000000002112 | [DIFFERENT] |
| {idx: 41} terminalId | 00000002 | 00123455 | [DIFFERENT] |
| {idx: 42} merchantId | 12345678 | M12345 | [DIFFERENT] |
| {idx: 48} additionalPrivateData.{tag: 0001} itemNumber | 001 | 001 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0002} elavonStan | 654321 | 654321 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0003} elavonDateTime | 171213091512 | 171213091512 | [MATCH] |
| {idx: 48} additionalPrivateData.{tag: 0004} elavonRrn | 123456679012 | 123456679012 | [MATCH] |
| {idx: 49} currencyCode | 840 | 840 | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 15} acceptanceIndicatorCardSchemeData | Y | Y | [MATCH] |
| {idx: 63} reservedPrivateData3.{tag: 16} cardSchemeData | M2345678901234561712   | M2505241605151111712   | [DYNAMIC] |
| {idx: 63} reservedPrivateData3.{tag: 25} uniqueTransactionReferenceNumber | utrn1236325 | utrn1236325 | [MATCH] |
| messageTypeId | 1210 | 1210 | [MATCH] |

---

## Unmatched Flow Tests (No ATF Equivalent)

| # | Flow Test Name |
|---|----------------|
| 1 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 AUD MAIL_ORDER |
| 2 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 CAD MAIL_ORDER |
| 3 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 EUR MAIL_ORDER |
| 4 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 GBP MAIL_ORDER |
| 5 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 MXN MAIL_ORDER |
| 6 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 NZD MAIL_ORDER |
| 7 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 SGD MAIL_ORDER |
| 8 | All Currencies Valid Auth Card No, Currency and Transaction Source : 4508750015741019 USD MAIL_ORDER |
| 9 | Valid Card No 30123400000000 |
| 10 | Valid Card No 3528000000000007 |
| 11 | Valid Card No 3528000000000015 |
| 12 | Valid Card No 3528111100000001 |
| 13 | Valid Card No 36259600000012 |
| 14 | Valid Card No 39999699999999 |
| 15 | Valid Card No 4005550000000019 |
| 16 | Valid Card No 4012000033330026 |
| 17 | Valid Card No 4020050000000003 |
| 18 | Valid Card No 4440000042200014 |
| 19 | Valid Card No 4444333322221111 |
| 20 | Valid Card No 4484033322221118 |
| 21 | Valid Card No 4508750015741019 |
| 22 | Valid Card No 4532249999990204 |
| 23 | Valid Card No 4532249999994180 |
| 24 | Valid Card No 4532249999996961 |
| 25 | Valid Card No 4532249999997308 |
| 26 | Valid Card No 4761739001010010 |
| 27 | Valid Card No 4761739001010119 |
| 28 | Valid Card No 4777760000100000 |
| 29 | Valid Card No 6011000400000000 |
| 30 | Valid Card No 6011003179988686 |
