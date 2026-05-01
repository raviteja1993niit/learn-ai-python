# Change Report: G1198_16781_SUPPORT_VERIFY_OPS → develop

> **Generated:** 2026-04-07
> **Scope:** `src/main/resources` | **File Types:** `.yaml`
> **Files Changed:** 2 | **Total Lines Added:** 33 | **Total Lines Deleted:** 0

---

## Executive Summary

This change set extends the **Card Payment Connectivity API** to introduce support for **3D Secure (3DS) authentication flows** and enriches the **Authorization Void** submission model with new schema identifiers and required fields. New fields have been added to the Verification and Void submission schemas, the supported set of digital wallet providers and card schemes has been expanded, and two new transaction types have been formally introduced. The majority of changes are **additive and backward compatible**; however, `orderId` and `transactionType` have been added as **required fields** on `VerificationSubmission`, which requires consumer updates before upgrading.

---

## Changed Files Overview

| File | Status | Lines Added | Lines Deleted | Impact Level |
|------|--------|:-----------:|:-------------:|:------------:|
| `src/main/resources/acquirer-card-payment-connectivity-api.yaml` | MODIFIED | +4 | 0 | 🟡 Low |
| `src/main/resources/card-payment-connectivity-api.yaml` | MODIFIED | +29 | 0 | 🔴 Medium |

---

## Detailed Functional Changes

### 1. `acquirer-card-payment-connectivity-api.yaml`

**Purpose:** Defines the Acquirer-facing API contract that extends the core card payment domain API with acquirer-specific configuration and operational fields.

#### New Capabilities

- **`authorizationAmountIndicator`** *(optional, AcquirerVerificationSubmission)*
  Allows the acquirer to communicate the intended authorization amount type during an account verification request. This supports use cases where the downstream system needs to understand the amount context prior to a full authorization, enabling more accurate risk and routing decisions.

- **`partialAmountSupport`** *(optional, AcquirerVerificationSubmission)*
  Indicates whether the acquirer is capable of accepting partial authorization amounts. When set, this signals to the payment network that a partial approval response is acceptable, enabling flexible payment scenarios — particularly important for merchants in retail and hospitality sectors.

#### Schema / Contract Impact

| Aspect | Assessment |
|--------|------------|
| Backward Compatible | ✅ Yes — both fields are optional |
| Required Field Changes | None |
| Consumer Action Required | Optional — consumers may populate these fields to unlock extended verification behaviours |

---

### 2. `card-payment-connectivity-api.yaml`

**Purpose:** Defines the core domain API contract shared across all card payment operations — authorizations, captures, verifications, and voids. This file is the foundational schema reference for all downstream and upstream integrations.

#### New Capabilities

- **`VOID_AUTH` Transaction Type** *(TransactionType enum)*
  Formally introduces `VOID_AUTH` as a recognised transaction classification, representing the complete cancellation of a previously approved and unsettled authorization. This allows consumers and downstream systems to explicitly identify and route void-authorization transactions, improving auditability and reporting accuracy.

- **`VERIFICATION` Transaction Type** *(TransactionType enum)*
  Adds `VERIFICATION` to the `TransactionType` enum, enabling consumers to classify account verification requests as a distinct transaction category separate from standard authorization flows.

- **`authorizationCode`** *(added to AuthorizationVoid, Verification response schemas)*
  The upstream system's approval code is now returned in both the Authorization Void and Verification response payloads. This provides consumers with a direct reference to the authorizing system's confirmation code, which is essential for downstream reconciliation, audit trails, and dispute resolution workflows.

- **`JCB` Card Scheme** *(CardScheme enum)*
  Japan Credit Bureau (JCB) is now a supported card scheme, extending the API's international reach to include JCB-branded card transactions.

- **New Digital Wallet Providers** *(DigitalWalletType enum)*
  Three additional wallet providers are now supported:
  - `ANDROID_PAY` — Google's original Android Pay digital wallet
  - `MASTERPASS_ONLINE` — Mastercard's Masterpass online payment service
  - `VISA_CHECKOUT` — Visa's hosted checkout wallet solution

  This broadens the set of tokenized payment methods the API can classify and route, enabling merchants to accept a wider range of digital wallet transactions.

- **`AuthorizationVoidSubmissionAssociatedAuthorizationMerchant`** *(Schema title)*
  A formal schema title has been assigned to the merchant object embedded within the `AuthorizationVoidSubmission.associatedAuthorization` structure. This is a documentation and code-generation improvement that makes the schema hierarchy explicitly navigable in generated client SDKs and API documentation portals.

- **`AuthorizationVoidServiceProviderTransactionProcessing`** *(Schema title)*
  Similarly, the service provider transaction processing object within the Authorization Void schema now carries a formal title, improving schema discoverability and reducing ambiguity in generated code.

#### Modified Behaviour / Required Field Changes

- **`orderId` — now REQUIRED on `VerificationSubmission`**
  The order identifier must now be provided when submitting a verification request. This change ensures that all verification transactions are traceable to a specific merchant order, improving end-to-end payment traceability and enabling downstream reconciliation.
  > ⚠️ **Consumer Action Required:** Any client submitting `VerificationSubmission` requests must add `orderId` to the request payload.

- **`transactionType` — now REQUIRED on `VerificationSubmission`**
  Consumers must now explicitly specify the type of transaction being verified. This enables the receiving system to apply appropriate processing rules from the point of submission.
  > ⚠️ **Consumer Action Required:** Any client submitting `VerificationSubmission` requests must add `transactionType` to the request payload.

#### Schema / Contract Impact

| Aspect | Assessment |
|--------|------------|
| Backward Compatible | ⚠️ Partial |
| New Required Fields | `orderId`, `transactionType` on `VerificationSubmission` |
| Enum Additions | `VOID_AUTH`, `VERIFICATION` (TransactionType); `JCB` (CardScheme); `ANDROID_PAY`, `MASTERPASS_ONLINE`, `VISA_CHECKOUT` (DigitalWalletType) |
| Response Enhancements | `authorizationCode` added to Void and Verification responses (optional, no consumer changes required to receive) |

---

## Commit History

| Commit | Author Message | Functional Impact |
|--------|---------------|-------------------|
| `5c2b73d` | Merge branch 'develop' into G1198_16781_SUPPORT_VERIFY_OPS | Integration merge — no functional delta |
| `bdda7f8` | changes on AuthorizationVoidSubmissionAssociatedAuthorizationMerchant | Added formal schema title to merchant object in void submission; added `orderId` as required field |
| `6fd50bf` | G1198_16781_FLOW_THREE3DS_AUTH | Introduced 3DS auth flow support — new fields and schema titles |
| `145ef9b` | G1198_16781_FLOW_THREE3DS_AUTH | Continued 3DS schema additions — wallet types and card schemes |
| `cbba233` | Merge branch 'develop' into G1198_16781_SUPPORT_VERIFY_OPS | Integration merge — no functional delta |
| `9afd4a3` | G1198_16781_FLOW_THREE3DS_AUTH | Transaction type enum expansions (`VOID_AUTH`, `VERIFICATION`) |
| `454bfa5` | G1198_16781_FLOW_THREE3DS_AUTH | `transactionType` required field additions on Verification schemas |
| `564db3a` | G1198_16781_FLOW_THREE3DS_AUTH | Initial 3DS flow scaffolding — `authorizationCode` in responses |

---

## Impact Assessment

| Category | Assessment |
|----------|------------|
| **Backward Compatible** | ⚠️ Partial — additive changes are compatible; new required fields are breaking |
| **Breaking Changes** | `orderId` (required) on `VerificationSubmission`; `transactionType` (required) on `VerificationSubmission` |
| **Consumer Action Required** | Yes — update `VerificationSubmission` request payloads to include `orderId` and `transactionType` |
| **New Enum Values** | `VOID_AUTH`, `VERIFICATION`, `JCB`, `ANDROID_PAY`, `MASTERPASS_ONLINE`, `VISA_CHECKOUT` |
| **Response Enhancements** | `authorizationCode` now available in Void and Verification responses |
| **Test Coverage** | ⚠️ No test files detected in the diff scope — contract tests recommended |
| **API Version Impact** | Recommend a **minor version bump** (e.g. `13.4.0` → `13.5.0`) given new required fields |

---

## Recommendations

1. **Consumer Migration (High Priority)**
   All consumers of `VerificationSubmission` must update their request payloads to include both `orderId` and `transactionType` before this change is deployed to a shared environment. Failure to do so will result in request validation errors.

2. **Leverage `authorizationCode` in Response Handling**
   The newly available `authorizationCode` in Void and Verification responses should be captured and stored by consumers for reconciliation, dispute resolution, and audit trail purposes.

3. **Expand Wallet Support in Routing Logic**
   If your integration routes transactions based on `DigitalWalletType`, ensure your routing configuration is updated to handle `ANDROID_PAY`, `MASTERPASS_ONLINE`, and `VISA_CHECKOUT`.

4. **Add Contract Tests**
   No test files were detected in the diff scope. It is strongly recommended to add contract or integration tests covering:
   - `VerificationSubmission` with new required fields
   - `AuthorizationVoidSubmission` with `orderId`
   - Response parsing for `authorizationCode`

5. **API Version Bump**
   Given the introduction of new required fields (a non-additive change), consider incrementing the API minor version from `13.4.0` to `13.5.0` to signal to consumers that a payload update is required.

---

*Generated by git-assist v2.0.0 | 2026-04-07*

