---
name: flow-test-fixer
description: >
  Fixes Flow test acquirer-interaction mismatches by updating FlowExpected values
  to match FlowActual in the minimum number of file touches. Zero ambiguity,
  zero back-and-forth, single-pass execution. Covers TimeOutExpiry, Void, Auth,
  Verify, Wallet, COF, CVV, ThreeDS, and Settlement scenario files.
triggers:
  - onCommand fix-flow-mismatches
---

# Skill: Flow Test Fixer

## 1. Purpose

Resolve `FLOW MISMATCH` rows from a comparison report in **one deterministic pass**,
touching only the files strictly required. Every decision is made from the mismatch
JSON alone — no exploratory file reading unless a constant value cannot be resolved
from the already-open files.

---

## 2. Context Budget Rules  ← COST CONTROL

| Rule | Detail |
|------|--------|
| **Max files open simultaneously** | 4 |
| **Read only what is needed** | Open a file only when a constant value in it cannot be inferred from the mismatch data or from already-open files |
| **No re-reads** | If a file was already read this session, use the cached content |
| **Targeted line ranges** | When reading, request only the relevant line range (±10 lines around the symbol) |
| **Batch all edits per file** | Collect every change for a file, then write once with a single `replace_string_in_file` or `insert_edit_into_file` call |
| **Stop reading when confident** | If the constant name clearly maps to the actual value (e.g. `VERIFY_LOCAL_DATE_TIME = "250524120515"`), do not open the constants file to confirm |

---

## 3. File Ownership Map

Use this map to route each mismatch to the correct file **without searching**:

| Scenario Class | Owns ACQUIRER rq/rs overrides |
|---|---|
| `TimeOutExpiryScenarios.java` | AUTH & VERIFY bank-timeout acquirer fields |
| `VoidScenarios.java` | VOID_AUTH acquirer fields |
| `ElavonAuthTransactions.java` (model) | Auth per-card acquirer overrides |
| `ElavonVerifyTransactions.java` (model) | Verify per-card acquirer overrides |
| `WalletTransactionScenarios.java` | Wallet acquirer fields |
| `CofScenarios.java` | COF acquirer fields |
| `CVVScenarios.java` | CVV acquirer fields |
| `ThreeDSecureScenarios.java` | 3DS acquirer fields |

Base defaults (affect ALL tests) live in:

| File | Owns |
|------|------|
| `msg/Acquirer.java` | `AUTH_REQ`, `AUTH_RES`, `voidRequest()`, `voidResponse()` |
| `constant/TestConstants.java` | Named constants for field values |

---

## 4. Constant Resolution Cheat-Sheet

Resolve values **without opening files** using this lookup:

| Actual Value | Constant | File |
|---|---|---|
| `250524120515` | `VERIFY_LOCAL_DATE_TIME` | TestConstants |
| `250524160515` | embedded in `AUTH_REQ.setLocalDateTime` | Acquirer.java |
| `250524170515` | void datetime in `voidRequest()` | Acquirer.java |
| `000000000000` | `ACQ_AMOUNT_ZERO` | TestConstants |
| `000000002112` | default auth amount in `AUTH_REQ` | Acquirer.java |
| `5212345678901234` | base PAN in `AUTH_REQ` / `WALLET_FPAN` | Acquirer.java / TestConstants |
| `5123450000000008` | `MC_PAN` | TestConstants |
| `091` | ISO bank-timeout action code (literal) | — |
| `000` | approved action code (literal / `DEFAULT_RESPONSE_CODE_SUCCESS`) | — |
| `9912` | `ACQ_VOID_EXPIRY` | TestConstants |
| `3012` | `CARD_EXPIRY` | TestConstants |
| `100000` | `AMEX_APPROVAL_CODE` / `ACQ_VOID_AUTH_CODE` | TestConstants |
| `123456` | `DEFAULT_APPROVAL_CODE` | TestConstants |
| `3765WMTT` | `APPLICATION_ID_FOR_OTHER_TRANSACTION_SOURCES` | ElavonAcquirerConstants |
| `3765WITT` | `APPLICATION_ID_FOR_INTERNET_TRANSACTION_SOURCES` | ElavonAcquirerConstants |
| `nameOfMerchant        Brisbane` | `CARD_ACCEPTOR` | TestConstants |
| `M2505241605151111712  ` | `CARD_SCHEME_DATA_MC_AUTH` | TestConstants |
| `M2505241205151111712  ` | `CARD_SCHEME_DATA_MC_VERIFY` | TestConstants |
| `M2505241705151111712  ` | `ACQ_VOID_CARD_SCHEME_DATA_RESPONSE` | TestConstants |
| `Y` | literal or `RESERVED_PRIVATE_DATA_3_ACCEPTANCE_IND_CARD_SCHME_DATA` | Fields |
| `2.2.0` | `PROTOCOL_VERSION_2_0_0` / `THREE_DS_CAP_INDICATOR` | TestConstants |
| `2` | `SCA_STATUS_PRESENT` or `POS_CARDHOLDER_PRESENT_DATA` value | TestConstants |
| `1` | MOTO indicator literal | — |
| `5` | `CARDHOLDER_PRESENT_ECOMMERCE` | TestConstants |
| `7` | `COF_ACQ_MOTO_DEFAULT` | TestConstants |

---

## 5. Field Index → Constant Map

Resolve ISO field indices to constant names **without opening files**:

| ISO Field | Constant Name | File |
|---|---|---|
| `2` | `ACQ_FIELD_PAN` | TestConstants |
| `3` | `ACQ_FIELD_PROCESSING_CODE` | TestConstants |
| `4` | `ACQ_FIELD_AMOUNT` | TestConstants |
| `12` | `ACQ_FIELD_LOCAL_DATE_TIME` | TestConstants |
| `14` | `ACQ_FIELD_EXPIRY` | TestConstants |
| `22` | `ACQ_FIELD_POS_ENTRY_MODE` | TestConstants |
| `22.05` | `POS_CARDHOLDER_PRESENT_DATA` | Fields |
| `24` | `ACQ_FIELD_NII` | TestConstants |
| `25` | `ACQ_FIELD_CONDITION_CODE` | TestConstants |
| `28` | `ACQ_FIELD_RECONCILIATION_DATE` | TestConstants |
| `38` | `ACQ_FIELD_APPROVAL_CODE` | TestConstants |
| `39` | `ACQ_FIELD_ACTION_CODE` | TestConstants |
| `43` | `ACQ_FIELD_CARD_ACCEPTOR` | TestConstants |
| `48.2` | `ACQ_FIELD_RRN_48_2` | TestConstants |
| `48.4` | `ACQ_FIELD_RRN_48_4` | TestConstants |
| `54` | `ACQ_FIELD_ADDITIONAL_AMOUNTS` | TestConstants |
| `60.01` | `RESERVED_PRIVATE_DATA_APPLICATION_ID` | Fields |
| `63.04` | `RESERVED_PRIVATE_DATA_3_MOTO` | Fields |
| `63.15` | `RESERVED_PRIVATE_DATA_3_ACCEPTANCE_IND_CARD_SCHME_DATA` | Fields |
| `63.16` | `ACQ_FIELD_CARD_SCHEME_DATA` | TestConstants |
| `63.25` | `ACQ_FIELD_UNIQUE_TXN_REF` | TestConstants |
| `63.44` | `ACQ_FIELD_SCA_STATUS` | TestConstants |
| `63.50` | `SIXTY_THREE_FIFTY` | Fields |
| `63.65` | `ACQ_FIELD_MC_MPGID` | TestConstants |
| `48.0002` | `ACQ_FIELD_ELAVON_STAN` | TestConstants |
| `48.0003` | `ACQ_FIELD_ELAVON_DATETIME` | TestConstants |
| `48.0004` | `ACQ_FIELD_ELAVON_RRN` | TestConstants |

---

## 6. Decision Rules — Where to Apply Each Fix

Apply in this priority order. Stop at first match.

```
1. FlowExpected = X  AND  FlowActual = Y  AND  X ≠ Y
   └─ Is the field in Acquirer.java base templates (AUTH_REQ / AUTH_RES /
      voidRequest / voidResponse)?
      YES → Fix in Acquirer.java   (affects ALL tests — change base value)
      NO  → Fix in the Scenario/Model file for that test name

2. FlowExpected = "-"  AND  FlowActual = <value>
   └─ Field is present in actual but absent in expected
      → Add the field with its actual value to the scenario rq() or rs()

3. FlowExpected = <value>  AND  FlowActual = "-"
   └─ Field is absent in actual but expected has a value
      → Add DELETE for the field in the scenario rq() or rs()

4. A named constant in TestConstants.java has the wrong hardcoded value
   → Update only that constant; all referencing tests are fixed automatically
```

### Base-vs-Scenario Decision

| Condition | Fix location |
|---|---|
| Same wrong value appears in **>1 test** for the same field | `Acquirer.java` base |
| Wrong value appears in **exactly 1 test** | Scenario/Model file |
| Constant name is correct but literal value is stale | `TestConstants.java` |

---

## 7. Execution Protocol — Single Pass

```
STEP 1 — Parse
  Read the mismatch JSON.
  Group rows by: FlowTestName → MessageType → list of (field, expected, actual).

STEP 2 — Route
  For each group, apply Section 6 rules to decide: which file gets the fix.
  Build a change plan: Map<File, List<Change>>.
  Do NOT open any file yet.

STEP 3 — Resolve unknowns (only if needed)
  For each Change where the constant name cannot be resolved from Section 4/5:
    Open the ONE file that owns that constant (targeted line range only).
    Extract the value. Close mentally (do not re-read).

STEP 4 — Execute
  For each file in the change plan:
    Open the file ONCE.
    Apply ALL changes for that file in one edit call.
    Validate with get_errors.

STEP 5 — Report
  Output a compact summary table: File | Field | Was | Now | Status
```

---

## 8. MCP Server Integration

These MCP servers eliminate file reads and reduce token cost:

| MCP Server | Purpose | Replaces |
|---|---|---|
| `filesystem` | Read targeted line ranges; write files | Manual file open/close loops |
| `grep` / `ripgrep` | Find a constant definition in 1 call | Opening entire constants file |
| `git` | Check last commit for a constant value | Opening history manually |
| `jvm-tools` (if available) | Resolve fully-qualified class members | Reading message/mapper classes |

### Optimal MCP Call Pattern

```
# Instead of: open TestConstants.java (550 lines) → find constant
# Do this:
grep --include="*.java" -n "ACQ_VOID_CARD_SCHEME_DATA_RESPONSE" .
# Returns: TestConstants.java:273:  "M2505250205151111712  "
# Cost: 1 grep call vs ~550 tokens for full file read
```

---

## 9. Anti-Patterns — Never Do These

| Anti-Pattern | Why Costly | Better Approach |
|---|---|---|
| Open `TestConstants.java` to confirm a constant you already know | Wastes 550 tokens | Trust Section 4 cheat-sheet |
| Open `Acquirer.java` to check what `AUTH_REQ` sets | Wastes 220 tokens | Trust Section 5 field map |
| Open mapper classes to understand field construction | Wastes 500+ tokens | Not needed for value-only fixes |
| Read `BaseElavon.java` to understand interaction setup | Wastes 414 tokens | Not needed for scenario-level fixes |
| Ask user "which constant should I use?" | Wastes a round trip | Look up Section 4 cheat-sheet |
| Fix one field per edit call | Multiplies API calls | Batch all changes per file |
| Re-read a file already read this session | Doubles token cost | Cache content in working memory |
| Open the parent flow model (`AuthFPAN`, `AuthVoid`) | Wastes tokens | Irrelevant for expected-value fixes |

---

## 10. Compact Output Format

After all fixes are applied, report once:

```
┌─────────────────────────────────────────────────────────────────┐
│  FLOW TEST FIXER — RESULTS                                      │
├──────────────────────────┬───────────┬──────────────┬──────────┤
│ File                     │ Field     │ Was          │ Now      │
├──────────────────────────┼───────────┼──────────────┼──────────┤
│ TimeOutExpiryScenarios   │ 39 (rsp)  │ 000          │ 091      │
│ TimeOutExpiryScenarios   │ 12 (rq)   │ 160515       │ 120515   │
│ VoidScenarios            │ 14 (rq)   │ 9912         │ 3012     │
│ Acquirer.java            │ void dt   │ 250525020515 │ 250524.. │
│ TestConstants            │ VOID_CSD  │ M2505250..   │ M250524. │
└──────────────────────────┴───────────┴──────────────┴──────────┘
Files touched: 4  |  Edits: 8  |  Compile errors: 0
```

No narrative. No intermediate status messages. Just the table.

---

## 11. Import Management

When adding a new constant reference to a scenario file:

1. Check the existing import block (already in context from Step 4 file open).
2. Add missing static import in the correct alphabetical group.
3. Remove any import that is no longer referenced after the change.
4. Do this in the same single edit call — never a separate import-only edit.

---

## 12. Quality Gate

Before closing:

- [ ] `get_errors` shows zero compile errors on every touched file
- [ ] Warnings are pre-existing (not introduced by this change)
- [ ] No `import *` added
- [ ] `ACQ_VOID_EXPIRY`, `WALLET_FPAN` not left as dead imports after removal
- [ ] Every mismatch row from input JSON is addressed

---

## 13. Example — Minimal Fix Trace

**Input mismatch:**
```json
{ "FlowTestName": "VERIFY BANK TIMEOUT - Expiry 2808",
  "MessageType": "ACQUIRER_REQUEST",
  "FlowExpected": "250524160515", "FlowActual": "250524120515" }
```

**Trace (internal, not shown to user):**
```
Field 12 → ACQ_FIELD_LOCAL_DATE_TIME
Actual "250524120515" → VERIFY_LOCAL_DATE_TIME  (Section 4 cheat-sheet)
Owner: TimeOutExpiryScenarios.java → buildAcquirerRequest(isVerify=true)
Action: add  ACQ_FIELD_LOCAL_DATE_TIME, VERIFY_LOCAL_DATE_TIME  to verify branch rq()
File open needed: YES (to locate exact rq() block for edit)
```

**Result:** 1 targeted replace in `TimeOutExpiryScenarios.java`. Zero extra file reads.
