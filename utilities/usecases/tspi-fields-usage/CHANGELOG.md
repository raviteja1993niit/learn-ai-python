# CHANGELOG — TSPI Field Usage Scanner

All notable changes to the TSPI field usage scanning pipeline are documented here.
Entries are in reverse-chronological order.

---

## [2026-04-17] — Import Line False Positive Fix & Sub-field Reporting

### Problem
Import statements were being falsely matched by the egrep scanner.  
Example: `import com.mastercard.gateway.acquiring.megajson.transactionrequest.transaction.AssociatedTransaction;`  
contains `transaction.` in the package path, which triggered the `transaction\.` egrep pattern.
This inflated usage counts and caused `Transaction.AgreementData.FirstTransactionOfAgreement` to be
wrongly stamped `USED` (it was only an import, not actual field access).

### Fixed (`find-tspi-field-usages.sh`)
- Added awk-level filters before extraction:
  - `if (content ~ /^import /) next` — skip Java import declarations
  - `if (content ~ /^package /) next` — skip package declarations
- Result: **459 → 447 rows** (12 false import/package matches removed)
- `Transaction.AgreementData.FirstTransactionOfAgreement` correctly changed USED → **NOT_USED**
- `Transaction.AssociatedTransaction` count corrected: **8 → 5** real usages

### Improved (`update-elavon-usage.sh`)
- `find_matches()` now tracks specific sub-fields accessed when a prefix match is found.
  When `Transaction.AssociatedTransaction` is USED via child fields, `UsageComments` now includes
  `sub-fields=[country; id; categorycode; ...]` showing exactly which leaf fields are accessed.
- This enables precise nested class analysis without manual code inspection.

### Example improvement
**Before:**
```
Transaction.AssociatedTransaction, USED, count=8 classes=[...MegaJsonToElavonMessageMapper...] samples: [MegaJsonToElavonMessageMapper] L46: import com.mastercard...AssociatedTransaction;
```
**After:**
```
Transaction.AssociatedTransaction, USED, count=5 classes=[MegaJsonToElavonMessageMapper; VoidOrReversalValidationRule; ...] samples: [MegaJsonToElavonMessageMapper] L470: AssociatedTransaction at = transactionContext.request().transaction().associatedTransaction();
MerchantContext.Merchant.SubMerchant, USED, count=11 sub-fields=[country; id; categorycode; postcode; city; email; street; phone; tradingname; stateprovince] ...
```

### Agent Updated
- `tspi-field-usage-scanner.agent.md`: documented `import`/`package` filter and `sub-fields` reporting.

### Results (latest run — `acqelavons2aservice_20260417_130616.csv`)
| Metric | Count |
|--------|-------|
| Total rows | 447 |
| VALID | 260 |
| NOT_IN_CONVENTIONS | 173 |
| EMPTY/UNKNOWN | 14 |
| ElavonUsage = USED | 9 |
| ElavonUsage = NOT_USED | 66 |

---

## [2026-04-17] — Dot Notation Coverage Audit & SupportedEMV3DSSchemes Fix

### Fixed
- `SupportedEMV3DSSchemes` was missing from the awk `ROOTS` array in `find-tspi-field-usages.sh`.
  Lines containing standalone `supportedEMV3DSSchemes(...)` calls now resolve correctly.
- `SupportedEMV3DSSchemes` was missing from the awk `CLASSES` array.
  `SupportedEMV3DSSchemes::VALUE` static references now extracted via Attempt 3.
- egrep `MERCHANT_PATTERN` for `SupportedEMV3DSSchemes` expanded to full 3-variation form:
  `SupportedEMV3DSSchemes::` · `supportedEMV3DSSchemes().` · `supportedEMV3DSSchemes.`
  · bare `SupportedEMV3DSSchemes` · `supportedEMV3DSSchemes(`.

### Verified
- `merchantcontext.merchant.supportedemv3dsschemes` resolves as `VALID` (2 usages).
- All 36 TSPI classes from `problem-stmt.txt` confirmed covered with 3 egrep variations each.

### Agent Updated
- Added `SupportedEMV3DSSchemes` row to the TSPI Field Patterns table.

---

## [2026-04-17] — Shell Script Pipeline Complete

### Added
- **`scripts/find-tspi-field-usages.sh`** — Bash replacement for `Find-TSPIFieldUsages.ps1`.
  - Uses `egrep -rn --include="*.java"` with combined pattern for all TSPI classes.
  - awk program with `walk_chain()` and `extract_field()` functions to normalise matched
    accessor chains to lowercase dot-notation FieldNames.
  - Three extraction attempts per line:
    1. `camelName()` method-call chain
    2. `camelName.` direct-field access
    3. `ClassName::` static/enum reference
  - Validates FieldName against `field-naming-conventions.txt` → `VALID` / `NOT_IN_CONVENTIONS` / `EMPTY`.
  - Deduplicates consecutive identical segments.
  - Noise-method filter stops chain walk at `toString`, `equals`, `trim`, `contains`, etc.
  - Longest-first ROOTS ordering prevents prefix-match false positives.

- **`scripts/update-elavon-usage.sh`** — Bash replacement for `Update-ElavonUsage.ps1`.
  - Loads lookup CSV; exact match + prefix match logic.
  - Stamps `ElavonUsage` and `UsageComments`.
  - Three bugs fixed during development (next→continue, column alignment, blank-header strip).

- **`.github/agents/tspi-field-usage-scanner.agent.md`** — GitHub Copilot agent definition.
  - Orchestrates both scripts end-to-end; includes pre-checks, key paths, TSPI pattern table.

---

## [2026-04-17] — PowerShell Scripts Refactored

### Changed (`Find-TSPIFieldUsages.ps1`)
- `ClassName` = source file class name (not model class).
- `LineContent` = exact matched line content.
- `@Property` lines excluded.
- Output: `{reponame}_{yyyymmdd_hhmmss}.csv` naming.
- `ValidationStatus` column: `VALID` / `NOT_IN_CONVENTIONS` / `EMPTY`.
- Word-boundary fix (`\b`) for SubMerchant vs Merchant disambiguation.

---

## [2026-04-17] — Test Exclusion & Single CSV Output

### Changed (`Find-TSPIFieldUsages.ps1`)
- Three-tier test exclusion: module-level, directory-level (`src\test`, `src\it`), filename-level (`*Test`, `*IT`, `*Mock`, `*Stub`).
- Single consolidated CSV per run.
- `-RepoPath` parameter.

---

## [2026-04-17] — Initial Script Creation

### Added (`Find-TSPIFieldUsages.ps1`)
- 5-phase PowerShell scanner; 613 rows on first run against `acqelavons2aservice`.
- Columns: `FieldName, ValidationStatus, ClassName, ModelClass, LineContent, LineNo, FilePath, RepoName`.

---

## Files Reference

| File | Purpose |
|------|---------|
| `scripts/find-tspi-field-usages.sh` | **Primary** — bash scanner; egrep + awk; produces lookup CSV |
| `scripts/update-elavon-usage.sh` | **Primary** — bash updater; joins lookup → stamps input-data.csv |
| `scripts/Find-TSPIFieldUsages.ps1` | Legacy — original PowerShell scanner (retained for reference) |
| `scripts/Update-ElavonUsage.ps1` | Legacy — original PowerShell updater (retained for reference) |
| `scripts/field-naming-conventions.txt` | 746 canonical TSPI field names in lowercase dot-notation |
| `input-data.csv` | 75 TSPI fields with ElavonUsage stamps |
| `logs/acqelavons2aservice_*.csv` | Timestamped lookup CSVs from each script run |
| `problem-stmt.txt` | Original requirements and reference egrep patterns |
| `CHANGELOG.md` | This file |

---

## Agent

**Location:** `C:\Users\e135408\Downloads\mcp-servers\.github\agents\tspi-field-usage-scanner.agent.md`

The GitHub Copilot agent `tspi-field-usage-scanner` orchestrates the full two-step pipeline.
Invoke with a `REPO_PATH` argument pointing to any Java repo to scan for TSPI field usages.


All notable changes to the TSPI field usage scanning pipeline are documented here.
Entries are in reverse-chronological order.

---

## [2026-04-17] — Dot Notation Coverage Audit & SupportedEMV3DSSchemes Fix

### Fixed
- `SupportedEMV3DSSchemes` was missing from the awk `ROOTS` array in `find-tspi-field-usages.sh`.
  Lines containing standalone `supportedEMV3DSSchemes(...)` calls now resolve correctly.
- `SupportedEMV3DSSchemes` was missing from the awk `CLASSES` array.
  `SupportedEMV3DSSchemes::VALUE` static references now extracted via Attempt 3.
- egrep `MERCHANT_PATTERN` for `SupportedEMV3DSSchemes` expanded to full 3-variation form:
  `SupportedEMV3DSSchemes::` · `supportedEMV3DSSchemes().` · `supportedEMV3DSSchemes.`
  · bare `SupportedEMV3DSSchemes` · `supportedEMV3DSSchemes(`.

### Verified
- `merchantcontext.merchant.supportedemv3dsschemes` now resolves as `VALID` (2 usages in `MegaJsonToElavonMessageMapper` and `TspiToElavonMessageMapper`).
- Confirmed all 36 TSPI classes from `problem-stmt.txt` covered with 3 egrep variations each.

### Agent Updated
- `tspi-field-usage-scanner.agent.md`: Added `SupportedEMV3DSSchemes` row to the TSPI Field Patterns table.

---

## [2026-04-17] — Shell Script Pipeline Complete (Shell Run: 459 rows)

### Added
- **`scripts/find-tspi-field-usages.sh`** — Bash replacement for `Find-TSPIFieldUsages.ps1`.
  - Uses `egrep -rn --include="*.java"` with combined pattern for all TSPI classes.
  - awk program with `walk_chain()` and `extract_field()` functions to normalise matched
    accessor chains to lowercase dot-notation FieldNames.
  - Three extraction attempts per line:
    1. `camelName()` method-call chain
    2. `camelName.` direct-field access
    3. `ClassName::` static/enum reference
  - Validates FieldName against `field-naming-conventions.txt` → `VALID` / `NOT_IN_CONVENTIONS` / `EMPTY`.
  - Deduplicates consecutive identical segments (e.g. `transactionresponse.transactionresponse.x` → `transactionresponse.x`).
  - Strips `transactionrequest.` prefix artefact.
  - Noise-method filter: stops chain walk at `toString`, `equals`, `trim`, `contains`, etc.
  - Longest-first ROOTS ordering prevents prefix-match false positives (e.g. `merchant` inside `merchantContext`).

- **`scripts/update-elavon-usage.sh`** — Bash replacement for `Update-ElavonUsage.ps1`.
  - Loads lookup CSV into awk; exact match + prefix match logic.
  - Stamps `ElavonUsage = USED / NOT_USED` and `UsageComments = count=N classes=[...] samples: ...`.
  - Three bugs fixed during development:
    1. `next` in `BEGIN` block replaced with `continue` inside while-loop.
    2. Column misalignment: `ElavonUsage` / `UsageComments` now always appended fresh at end (column-index-based output).
    3. Leftover empty-header column from prior PowerShell run stripped by tracking `blank_col[]`.

- **`.github/agents/tspi-field-usage-scanner.agent.md`** — GitHub Copilot agent definition (126 lines).
  - Orchestrates `find-tspi-field-usages.sh` → `update-elavon-usage.sh` end-to-end.
  - Includes pre-checks, key paths, step-by-step instructions, TSPI pattern reference table, and sub-task checklist.

### Results (latest run)
| Metric | Count |
|--------|-------|
| Total rows | 459 |
| VALID | 261 |
| NOT_IN_CONVENTIONS | 184 |
| EMPTY/UNKNOWN | 14 |
| ElavonUsage = USED | 10 |
| ElavonUsage = NOT_USED | 65 |

### USED fields (10)
- `Transaction.AssociatedTransaction`
- `Transaction.AuthenticationVersion`
- `Transaction.AgreementData.FirstTransactionOfAgreement`
- `MerchantContext.Merchant.SubMerchant`
- `MerchantContext.Merchant.SupportedEMV3DSSchemes`
- `Transaction.AgreementType`
- `Transaction.PaymentType`
- `Transaction.FinancialNetworkDate`
- `Transaction.FinancialNetworkTransactionId`
- `Transaction.MerchantPaymentGatewayID`

---

## [2026-04-17] — PowerShell Scripts Refactored & Field Extraction Improved

### Changed (`Find-TSPIFieldUsages.ps1`)
- `ClassName` column changed from TSPI model class name → **source Java file class name** (basename of matched `.java` file).
- `LineContent` column changed from matched method name → **exact content of the matched line**.
- `ModelClass` column retained as the TSPI model class name from pattern match.
- Added `@Property` line filter — annotation lines excluded from results.
- Output filename pattern changed to `{reponame}_{yyyymmdd_hhmmss}.csv` (lowercase, underscore separator).
- `ValidationStatus` column added with values `VALID` / `NOT_IN_CONVENTIONS` / `EMPTY`.
- Word-boundary fix (`\b`) added to prevent `SubMerchant` pattern matching inside `Merchant` results.
- Constructor chain detection added for `new TransactionResponse().method()` patterns.

### Changed (`Update-ElavonUsage.ps1`)
- Created to cross-reference lookup CSV against `input-data.csv`.
- Stamped `ElavonUsage` (USED/NOT_USED) and `UsageComments` columns.
- Exact match + prefix match logic.

---

## [2026-04-17] — Test Exclusion & Single CSV Output

### Changed (`Find-TSPIFieldUsages.ps1`)
- Three-tier test exclusion implemented:
  1. **Module-level**: auto-detect directories matching `test-data`, `integration-test`, `integration_test` patterns.
  2. **Directory-level**: skip `src\test\` and `src\it\` paths.
  3. **Filename-level**: skip files ending in `Test`, `Tests`, `IT`, `ITest`, `Mock`, `Stub`, `Fake`.
- Single consolidated CSV output per run (removed per-class split files).
- `-RepoPath` parameter replaces hardcoded path.

---

## [2026-04-17] — Initial Script Creation

### Added (`Find-TSPIFieldUsages.ps1`)
- Initial 5-phase PowerShell script:
  1. Parse TSPI model Java classes to extract field accessor methods.
  2. Build egrep-compatible regex patterns.
  3. Search business Java files in the repo.
  4. Normalise FieldNames to lowercase dot-notation.
  5. Write consolidated CSV output.
- Produced 613 rows on first run against `acqelavons2aservice`.
- CSV columns: `FieldName, ValidationStatus, ClassName, ModelClass, LineContent, LineNo, FilePath, RepoName`.

---

## Files Reference

| File | Purpose |
|------|---------|
| `scripts/find-tspi-field-usages.sh` | **Primary** — bash scanner; egrep + awk; produces lookup CSV |
| `scripts/update-elavon-usage.sh` | **Primary** — bash updater; joins lookup → stamps input-data.csv |
| `scripts/Find-TSPIFieldUsages.ps1` | Legacy — original PowerShell scanner (retained for reference) |
| `scripts/Update-ElavonUsage.ps1` | Legacy — original PowerShell updater (retained for reference) |
| `scripts/field-naming-conventions.txt` | 746 canonical TSPI field names in lowercase dot-notation |
| `input-data.csv` | 75 TSPI fields with ElavonUsage stamps |
| `logs/acqelavons2aservice_*.csv` | Timestamped lookup CSVs from each script run |
| `problem-stmt.txt` | Original requirements and reference egrep patterns |
| `CHANGELOG.md` | This file |

---

## Agent

**Location:** `C:\Users\e135408\Downloads\mcp-servers\.github\agents\tspi-field-usage-scanner.agent.md`

The GitHub Copilot agent `tspi-field-usage-scanner` orchestrates the full two-step pipeline.
Invoke it with a `REPO_PATH` argument pointing to any Java repo to scan for TSPI field usages.
