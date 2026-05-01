---
name: toggle-codebase-usage-analyzer
description: '>-'
This agent performs comprehensive toggle code-usage enquiry for CardPaymentEngine (CPE): ''
and Orchestrator repositories. It reads feature toggles from FeatureToggleConfluencePageEnquiryResults.csv: ''
in batches of 5, identifies toggle registry classes, traces all usage points in implementation: ''
classes (not just declarations), analyzes ON/OFF behavior impacts, and performs deep S2A: ''
transaction analysis. For each toggle usage, it examines code-path impacts and functional: ''
implications, with explicit focus on S2A-related classes (MegaMessageMap, JsonMegaMessageMap, Tspi).: ''
Results are persisted to ToggleCodebaseUsageAnalysis.csv with one row per usage location.: ''
argument-hint: '>-'
Use "analyze toggles batch 1-5" to start batch analysis of first 5 toggles, then "analyze toggles batch 6-10": ''
for subsequent batches. The agent will trace each toggle from declaration through all implementation: ''
usage points, analyze ON/OFF behavior impacts on code paths and functionality, check for S2A implications: ''
in MegaMessageMap/JsonMegaMessageMap/Tspi classes, and write results to CSV with one row per usage location.: ''
Use "analyze all toggles with S2A focus" to prioritize S2A impact analysis across all toggles.: ''
tools: ['read_file', 'file_search', 'grep_search', 'list_dir', 'create_file', 'insert_edit_into_file', 'replace_string_in_file', 'run_in_terminal', 'show_content', 'run_subagent', 'apply_patch', 'get_terminal_output', 'open_file', 'get_errors', 'validate_cves']
---
# Toggle Codebase Usage Analyzer Agent

The Toggle Codebase Usage Analyzer Agent bridges feature toggle documentation with actual code implementation. It locates toggle usage patterns across **6 repositories**, identifies S2A-related keywords and classes, and generates comprehensive impact reports.

> ⚡ **Multi-Repo Registry (802 entries across 6 repos — updated 2026-04-11)**:
> `CPE` · `Orchestrator` · `BusinessService` · `Console` · `MSOUI` · `DirectAPI`
> DirectAPI uses a **targeted 22-file scan** (99.8% file reduction, <1 sec vs ~5 min).
> Registry builder: `tools/BuildToggleRegistryLookup.ps1` (normal) or `... -RefreshDirectAPIFileList` (full DirectAPI rescan).
> Registry now has **7 columns** (added `line_number`) and **multiple rows per toggle** (one per caller class).

---

## 📂 Reference Documents

All detailed specifications are in `.github/agents/docs/`. Read the relevant file before executing each phase:

| # | File | Contents |
|---|------|----------|
| 01 | [`docs/01-repositories.md`](docs/01-repositories.md) | Base paths, source roots, scan strategies for all 6 repos |
| 02 | [`docs/02-search-patterns-and-csv.md`](docs/02-search-patterns-and-csv.md) | Toggle name variants, S2A keywords, CSV format, ON/OFF impact format |
| 03 | [`docs/03-optimization-rules.md`](docs/03-optimization-rules.md) | Rules 1–10: registry cache, file index, S2A index, batch variants, search scope, test exclusion, four-pattern detection, checkpoints, one-row-per-impl-class |
| 04 | [`docs/04-workflow.md`](docs/04-workflow.md) | Phase 0–6 step-by-step workflow, batch processing cycle |
| 05 | [`docs/05-s2a-field-notation.md`](docs/05-s2a-field-notation.md) | ISO DE vs TSPI JSON notation, S2A trigger detection, toggle type classification |
| 06 | [`docs/06-analysis-guidelines.md`](docs/06-analysis-guidelines.md) | Code path capture requirements, error handling, output examples |
| 07 | [`docs/07-lessons-learned.md`](docs/07-lessons-learned.md) | Cardinal Errors 1–13, validation checklist (14 steps), hybrid class detection, ToggleHelper indirection, fully-qualified usage, wildcard imports, isOn() pattern, multi-class toggles |
| 08 | [`docs/08-mcp-toolkit.md`](docs/08-mcp-toolkit.md) | PS1 tools reference, registry builder commands, batch workflow options |

---

## Responsibilities

- **CSV Batch Ingestion**: Read toggles in batches of 5 from `jobs/TogglePageEnquiry/data/FeatureToggleConfluencePageEnquiryResults.csv`. Focus on `toggle_name` and `is_s2a` columns.
- **Toggle Registry Identification**: Use pre-built `ToggleRegistryLookup.csv` (802 entries, 6 repos, 7 cols incl. `line_number`). See `docs/03-optimization-rules.md` Rule 1.
- **Implementation-Specific Usage Tracing**: Find toggle usage in conditional logic — NOT just declarations. Distinguish DECLARATION from IMPLEMENTATION rows. See `docs/04-workflow.md` Phase 3.
- **Complete Code-Path Analysis** (ACCURACY CRITICAL): Read COMPLETE if/else blocks. Write **two-part impact format** for every ON and OFF: `Business: <outcome>  Field Impact: <fields>`. See `docs/02-search-patterns-and-csv.md`.
- **S2A Transaction Analysis**: For `is_s2a=TRUE` toggles, use cached `S2AKeywordsLookup.csv`. Apply correct ISO DE vs TSPI JSON notation per class. See `docs/05-s2a-field-notation.md`.
- **Dual-Repository Separation**: If toggle used in both CPE AND Orchestrator → create **separate rows** per repo. Never combine.
- **Result Persistence**: Append to `jobs/TogglePageEnquiry/data/ToggleCodebaseUsageAnalysis.csv` — 6 columns, one row per usage location per repo.

---

## Quick-Start Workflow Summary

```
Session start:
  1. Read docs/04-workflow.md (Phase 0) — load registry, build indexes
  2. Read docs/03-optimization-rules.md — confirm Rule 5/5B search scope

Per toggle batch (5 toggles):
  Phase 1: Read toggles from input CSV; clean toggle names
  Phase 2: Lookup in ToggleRegistryLookup.csv → get constant_name, usage_type
  Phase 3A: grep_search by display string + constant_name (includePattern="src/main/java/**/*.java")
             → filter: skip /test/, skip pure DECLARATION files (with hybrid check)
             → cross-repo search MANDATORY
  Phase 3B: read_file(fullPath, offset=blockStart, limit=blockEnd-blockStart+5)
  Phase 4:  Write ON/OFF impact in two-part format (Business + Field Impact)
  Phase 5:  S2A analysis via S2AKeywordsLookup.csv lookup (NO codebase search)
  Phase 6:  Consolidate → append to ToggleCodebaseUsageAnalysis.csv → checkpoint

Before marking NOT_FOUND or DECLARATION_ONLY:
  → Run the 14-step validation checklist in docs/07-lessons-learned.md
```

---

## Key Rules (Summary — full detail in docs/03-optimization-rules.md)

| Rule | Summary |
|------|---------|
| **Rule 1** | Registry pre-built (802 entries, 6 repos, 7 cols). Reuse for all 73 toggles — no re-searching. Multiple IMPLEMENTATION rows per toggle allowed. |
| **Rule 5** | ALWAYS `includePattern="src/main/java/**/*.java"` — never `**/*.java` |
| **Rule 5B** | NEVER search `/test/`, `*Test.java`, `*Tests.java`, `*Spec.java` |
| **Rule 5C** | Detect all 4 patterns: named import, wildcard import (`.*`), fully-qualified body (`ClassName.CONST`), `isOn()` short form |
| **Rule 8** | Skip pure DECLARATION file matches — but run hybrid check first (same file may have `isToggleOn`/`isOn` too) |
| **Rule 10** | One row per (toggle + repo + constant + class) — never collapse multiple impl classes to one row |
| **Cardinal Error 6** | After finding declaration, ALWAYS scan same file for `isToggleOn`/`isOn` — hybrid classes exist |
| **Cardinal Error 9** | If no direct `isToggleOn` callers, check for `ToggleHelper` wrapper → search wrapper method name |
| **Cardinal Error 10** | Match `ClassName.CONSTANT_NAME` in window, not just bare `CONSTANT_NAME` |
| **Cardinal Error 11** | Detect wildcard static imports → expand ALL constants from declared class |
| **Cardinal Error 12** | Add `Toggles.isOn()` to toggle detection patterns alongside `isToggleOn()` |
| **Cardinal Error 13** | One IMPLEMENTATION row per caller class — do not collapse multiple callers to one row |

---

## Available Tools

| Tool | Purpose |
|---|---|
| `read_file` | Read CSV files, Java source blocks (Phase 3B) |
| `grep_search` | Search toggle names and S2A keywords across repos |
| `file_search` | Find Java files by name pattern |
| `run_in_terminal` | Bulk searches via PowerShell `Select-String` |
| `insert_edit_into_file` | Append analysis rows to output CSV |
| `create_file` | Create checkpoint and intermediate files |
| `show_content` | Render analysis results in formatted tables |

---

# Phase 0: Optimization Setup (One-Time Only)

**Execute once before processing any toggles**

1. **Load Toggle Registry Lookup Cache** (Rule 1):
   - Registry pre-built at `jobs/TogglePageEnquiry/data/ToggleRegistryLookup.csv` — **279 entries across 6 repositories** (CPE 199 + Orchestrator 45 + MSOUI 16 + DirectAPI 14 + BusinessService 3 + Console 2)
   - Schema (6 columns): `toggle_name`, `registry_file_path`, `registry_class_name`, `repository`, `constant_name`, `usage_type`
   - `usage_type = DECLARATION` → use for exclusion filter only (skip as analysis target)
   - `usage_type = IMPLEMENTATION` → go directly to this file in Phase 3B (priority read target)
   - Load into in-memory map: `toggle_name → {registry_file_path, constant_name, usage_type, repository}` (all entries for that toggle)
   - **Rebuild registry** by running `tools/BuildToggleRegistryLookup.ps1` if new toggles have been added
     - Normal mode: fast targeted scan (DirectAPI uses 22-file list, <1 sec)
     - `-RefreshDirectAPIFileList` mode: full DirectAPI scan to rediscover toggle-bearing files (~5 min)
   - **Lookup cost: One-time load, reused for all 73 input toggles**

   > ⚡ **DirectAPI Optimization Note**: DirectAPI has ~10,367 Java files but only 22 contain toggle constants. The registry builder hard-codes these 22 file paths to avoid the ~5-minute full scan. When searching DirectAPI for toggle usage during Phase 3A, limit `grep_search` to those same 22 known paths where possible, or use `includePattern: "src/main/java/**/*.java"` with DirectAPI base path (will still be fast given few matches).

2. **Index Java Files from Tree Files** (Rule 2):
   - Parse `cardpaymentengine.tree.txt` → extract all `.java` file paths
   - Parse `orchestrator.tree.txt` → extract all `.java` file paths
   - Build `CPEJavaFileLookup.csv` and `OrchestratorJavaFileLookup.csv`
   - Create in-memory indices: `ClassName → [RelativePaths]`, `PackagePrefix → [Files]`
   - **Total CPE Java files: 3142**, **Total Orchestrator Java files: 847**
   - **Benefit: 60-70% search scope reduction when filtering by class name or package**

3. **Build S2A Keywords Index** (Rule 3):
   - Search `.java` files ONLY for S2A keywords: `S2A|Streamlined|JsonMegaMessageMap|MegaMessageMap|TSPI|Acquirer|S2I`
   - Record: class name, file path, S2A keywords found, has MegaMessageMap, has JsonMegaMessageMap, has TSPI
   - Persist to `S2AKeywordsLookup.csv`
   - **Lookup cost: One-time, eliminates redundant S2A keyword searches during Phase 5**

4. **Validation**:
   - Verify all 3 lookup CSVs created and contain expected entries
   - Create `OptimizationSetup_Checkpoint.txt` with counts and status
   - Proceed only if all lookups successfully built

---

# Phase 1: Batch Input Processing

1. Read 5 toggles at a time from `FeatureToggleConfluencePageEnquiryResults.csv` (e.g., rows 2-6 for batch 1)
2. **Clean toggle names**: strip any `^\d+\s*\|\s*` line-number prefix corruption (e.g., `"61 | Enable New COF..."` → `"Enable New COF..."`)
3. Continue iteratively: batch 1 (toggles 1-5), batch 2 (toggles 6-10), ..., batch 15 (toggles 71-73)
4. For each batch:
   - Extract `toggle_name` (cleaned) and `is_s2a` status from input CSV
   - Keep a running list of all toggles in current batch

---

# Phase 2: Toggle Registry Lookup (Using Cache)

1. **DO NOT re-search registry classes** — use loaded `ToggleRegistryLookup.csv` from Phase 0
2. For each toggle in the batch:
   - Lookup `toggle_name` in `ToggleRegistryLookup.csv`
   - Retrieve: `registry_class_name`, `registry_file_path`, `constant_name`, `usage_type`, `repository`
   - Collect **all** constant_name values for this toggle (may appear in multiple repos under different aliases)
   - Build dual-search pattern set: `[display_string] + [all constant_names]` → pass to Phase 3A
   - IMPLEMENTATION rows: add `fullPath` to Phase 3B priority read list (skip Phase 3A grep, go straight to read)
   - DECLARATION rows: **DO NOT blindly exclude** — add to Phase 3A for same-file implementation check
     - The registry class itself may be a HYBRID containing both declaration AND `isToggleOn` calls
     - Only after confirming zero `isToggleOn` calls in that file can it be treated as pure constants class
3. If toggle NOT found in registry lookup:
   - Note as "REGISTRY_NOT_FOUND" in batch report
   - Continue with display-string-only search in Phase 3A (may miss constant-name aliases)
4. Build in-batch registry reference map for Phase 3A filtering

---

# Phase 3: Usage Tracing — Two Sub-Phases (3A Locate + 3B Read)

## Phase 3A: Locate (Run `Toggle-SearchUtility.ps1`)

For each toggle in the batch:

1. **Dual Search — MANDATORY** (W1 fix):
   - Run `Toggle-SearchUtility.ps1 -ToggleName "<display_name>" -Repository "Both" -ExcludeDeclarations`
   - The script automatically searches by BOTH the display string AND all `constant_name` values from `ToggleRegistryLookup.csv`
   - This ensures CPE-side aliases (e.g. `TOGGLE_FOR_ACCOUNT_FUNDING_ENHANCEMENT` for `"Enable Account Funding enhanced..."`) are found
   - Scope: `src/main/java` only; test files (`*Test.java`, `*Tests.java`, `*IT.java`, `*ITest.java`, `src/test/java/**`) excluded

2. **Parse JSON Output** — each result contains:
   - `repository` — CPE or Orchestrator
   - `className` — implementation class name
   - `filePath` — relative path from repo root
   - `fullPath` — absolute path for `read_file`
   - `lineNumber` — 1-based match line
   - `blockStart` — 1-based line of enclosing method opening brace
   - `blockEnd` — 1-based line of enclosing method closing brace
   - `isDeclaration` — true if line is a `public static final String =` assignment (skip these)

3. **Filter Out Declaration Lines — WITH SAME-FILE IMPLEMENTATION CHECK** (Rule 8 + BUG FIX):
   - For any result where `isDeclaration == true` OR where `filePath` matches `registry_file_path`:
     - **DO NOT immediately skip** — first run a secondary check:
     - Search the **same file** for `isToggleOn|isEnabled` calls (excluding comment lines)
     - **IF isToggleOn found in same file** → the file is a HYBRID class containing both declaration and implementation
       → Keep this file as an analysis target; use the isToggleOn line numbers as the actual usage locations
       → **This was the root cause of CARDINAL ERROR 6** — misclassifying hybrid classes as declaration-only
     - **IF isToggleOn NOT found in same file** → confirmed pure constants class → safely skip (declaration-only)
   - IMPLEMENTATION-typed registry rows are priority targets — go there first
   - **Known hybrid classes** (declaration + isToggleOn in same file):
     - `CardTypeDetailsDecorator.java` — declaration line 70, usage line 124
     - `SanctionHelper.java` — declaration line 327, usage lines 1568, 1708, 1729, 1755
     - `TransactionDataCommonService.java` — declaration line 157, usage lines 550, 1540
     - Any other class that is NOT a pure constants class

4. **Cross-Repo Search — MANDATORY** (W5/dual-repo fix):
   - After locating in the registry-indicated repo, always scan the other repo using constant_name
   - If hits found in `src/main/java` of second repo → produce additional rows for that repo

## Phase 3B: Read (Agent `read_file` calls)

For each non-declaration result from Phase 3A:

1. **Targeted Read**:
   ```
   read_file(fullPath, offset=blockStart, limit=blockEnd - blockStart + 5)
   ```
   - This returns the COMPLETE enclosing method block (including the full `if/else` conditional)
   - `blockStart`/`blockEnd` are 1-based line numbers from Phase 3A JSON

2. **Store Block Content** — feed directly into Phase 4 analysis

3. **Filter Out Test Classes** (Rule 5B — MANDATORY):
   - Skip any match where path contains `/test/` or class ends with `Test`, `Tests`, `Spec`, `IT`, `ITest`

4. **Classify Implementation Classes**:
   - Record repository (CPE vs Orchestrator)
   - For dual-repo toggles: one Phase 3B read per implementation class per repo

---

# Phase 4: Complete Code Analysis — Business Impact + Field Impact

**CRITICAL**: Write BOTH ON and OFF impacts in the mandatory two-part format for every usage location.

For each toggle usage block read in Phase 3B:

1. **Read the Complete If/Else Block** (from Phase 3B output — no shortcuts):
   - The block is already available from `read_file(fullPath, offset=blockStart, limit=blockEnd-blockStart+5)`
   - Identify the exact conditional: `if (isToggleOn(...))`, `if (toggle)`, ternary, etc.
   - Read ENTIRE if block and ENTIRE else block (or document what does NOT execute if no else)
   - Include nested conditionals, field assignments, method calls, object instantiations

2. **Analyze Toggle ON (TRUE) Behavior** — two-part format (MANDATORY):
   - **Business**: What does the merchant / cardholder / acquirer gain or lose? What operation succeeds or is unlocked?
   - **Field Impact**: Which specific TSPI/merchant API fields are populated, validated, or accepted? Which ISO 8583 Data Elements (DE) are included or excluded? Which acquirer message fields (S2I ISO DE, MEGA JSON fields) are sent?
   - If no external fields: state `Field Impact: Internal only — no TSPI/ISO/acquirer fields affected`

3. **Analyze Toggle OFF (FALSE) Behavior** — same two-part format (MANDATORY):
   - **Business**: What fallback / legacy behavior applies? What is NOT available to the merchant or acquirer?
   - **Field Impact**: Which fields are NOT populated, NOT validated, or NOT sent? What defaults apply?

4. **Field Impact Reference Guide** (use exact names from code):
   | Category | Examples |
   |---|---|
   | TSPI / Merchant API | `sourceOfFunds.provided.card.securityCode`, `accountFunding.purposeOfPayment`, `accountFunding.reference`, `accountFunding.foreignExchangeFee`, `order.id` |
   | ISO 8583 DE (S2I) | `ISO DE48 SE36 SF05`, `ISO DE48 SE03 SF05`, `ISO DE54`, `ISO DE108 SF01`, `ISO DE61 SF11`, `ISO DE123` |
   | MEGA / TSPI JSON | `AccountFundingPaymentPurpose`, `AccountFundingForeignExchangeFee`, `PaymentRecipientMiddleName`, `PaymentRecipientStreet`, `CustomerIdentificationType`, `CustomerIdentificationValue` |
   | Internal only | No external protocol fields affected — state explicitly |

5. **Prohibited Patterns** (NEVER use these):
   - ✗ `"When enabled: executes pingServers() method on fixed delay..."` (code-centric, no business context)
   - ✗ `"Enables S2A feature"` (too vague, no field impact)
   - ✗ `"ON Impact: Based on code at ClassName.java:LineNumber"` (placeholder — never acceptable)
   - ✗ `"OFF Impact: Complementary behavior when toggle disabled"` (placeholder — never acceptable)

6. **Correct Format Examples**:
   ```
   ✓ Toggle ON: "Business: For Scheme Token transactions the gateway accepts payment without CSC/CVV
     validation — tokenized payments proceed even when CSC is absent.
     Field Impact: sourceOfFunds.provided.card.securityCode not validated; isCscProvided() /
     wasCscPreviouslyProvided() / validateEmptyCsc() all bypassed for scheme token transactions."

   ✓ Toggle ON: "Business: CPE sends enriched Account Funding data to S2I/MEGA acquiring network —
     enables full Visa/MC enhanced AFT processing including purpose mapping and FX fee.
     Field Impact: ISO DE48 SE36 SF05 — purposeOfPayment from merchant used directly;
     ISO DE54 — foreignExchangeFee validated and mapped for Visa AFT auth/capture;
     ISO DE108 SF01 — reference from accountFunding.reference (not card number);
     MEGA JSON: AccountFundingPaymentPurpose, AccountFundingForeignExchangeFee,
     PaymentRecipientMiddleName, PaymentRecipientStreet/Street2/City included."

   ✓ Toggle OFF: "Business: Only basic AFT data flows to S2I/MEGA — enhanced fields silently dropped.
     Field Impact: DE48 SF05 uses legacy Purpose.name() enum string; DE54 FX fee not mapped;
     DE108 SF01 uses card number not reference; MEGA JSON omits all enhanced recipient,
     identification, FX fee, and payment purpose fields."
   ```

---

# Phase 5: S2A Impact Analysis (Using Cached Lookup — NO Searching)

**CRITICAL**: Use cached `S2AKeywordsLookup.csv` (Rule 3) — do NOT search codebase for S2A keywords.
For S2A field notation rules, see **§ S2A-Focused Analysis** (differentiating S2I ISO DE vs TSPI JSON fields).

For toggles marked `is_s2a = TRUE` or whose implementation classes match S2A patterns:

#### 1. S2A Trigger Detection
- Trigger S2A analysis if implementation class name or registry file path matches any of:
  - `*S2IAcquirer*`, `*S2IAcquirerV1*`, `*S2IAcquirerV2*` → S2I ISO message builder
  - `*JsonMegaMessageRequestBuilder*`, `*JsonMegaMessageMap*`, `*MegaMessageMap*` → S2A MEGA/TSPI JSON builder
  - `*TspiRequestMessageBuilder*` → T-SPI message builder
  - `*acquirer/messagemapimpl/*` (file path pattern) → any acquirer message mapping class
  - `*S2AKeywords*`, `*S2AProcessor*`, `*StreamlinedAcquirer*` → direct S2A flow classes
- Registry class path containing `/acquirer/messagemapimpl/` → always treat as S2A-adjacent regardless of class name

#### 2. Differentiating S2I ISO DE Fields vs S2A MEGA JSON Message Structure

The two acquirer message formats are **fundamentally different** in structure. When documenting Field Impact for S2A toggles, identify which format applies based on the implementation class, and use the correct field naming convention:

---

##### S2I ISO 8583 DE Field Context (`S2IAcquirerV1`, `S2IAcquirerV2`, ISO DE message classes)

S2I sends **ISO 8583 binary messages** to the acquirer. Fields are identified by Data Element (DE) number and optional Sub-Element (SE) / Sub-Field (SF) hierarchy.

**Field naming convention**: `ISO DE<number> [SE<number>] [SF<number>]`

| ISO DE | Description | Toggle Impact Examples |
|--------|-------------|----------------------|
| `ISO DE48` | Additional Data — Private Use (sub-element based) | `DE48 SE36 SF05` = purposeOfPayment code; `DE48 SE03 SF05` = purpose sub-element; `DE48 SE37 SF4` = aggregator/sub-merchant data; `DE48 SE78 SF06` = ATRI indicator; `DE48 SE86` = COF; `DE48 SE91` = CIT TID |
| `ISO DE54` | Additional Amounts (cashback, FX fee) | `DE54` = Foreign Exchange Fee for Visa AFT; cashback amount |
| `ISO DE61 SF<n>` | Point of Service Data | `DE61 SF3` = POS terminal type; `DE61 SF10` = Cardholder-activated; `DE61 SF11` = Terminal input capability; `DE61 SF13/14` = POS location/capability |
| `ISO DE108` | Money Transfer Information | `DE108 SF01` = Transaction Reference (sender ref or card number); `DE108 SE03 SF05` = purpose code |
| `ISO DE120` | Record Data / Unique Transaction ID | `DE120 SE96` = unique transaction identifier |
| `ISO DE121` | Reserved for National Use | Terminal foreign indicator |
| `ISO DE122` | Message version / MDQ gateway data | MDQ edit code, message version |
| `ISO DE123` | Address Verification / Tag Data | OTD tag, service code, CTI tag, statement descriptor, network data tag, clearing tag |
| `ISO DE52/53` | PIN Block / Security Related | Online PIN translation |
| `ISO DE15` | Date, Settlement | Settlement date; `DE15` absent in void auth when toggle on |
| `ISO DE26` | Point of Service PIN Capture Code | Amex PIN transactions |

**S2I Field Impact notation**: `ISO DE48 SE36 SF05`, `ISO DE54 (Additional Amounts)`, `ISO DE108 SF01 (Transaction Reference)`

---

##### S2A MEGA / TSPI JSON Message Structure Context (`JsonMegaMessageRequestBuilder`, `TspiRequestMessageBuilder`)

S2A (Streamlined-to-Acquirer) sends **JSON messages** to the MEGA/TSPI acquirer endpoint. The JSON has a top-level structure with four major context objects:

```
JsonMegaMessage {
  Transaction { ... }           ← Transaction-level fields
  Acquirer { ... }              ← Acquirer routing & identification fields
  Merchant { ... }              ← Merchant configuration & identification fields
  RoutingHeader { ... }         ← Message routing metadata
}
```

**Field naming convention**: `TSPI: <ContextObject>.<FieldName>` or just the JSON field name directly

| TSPI Context | Description | Toggle Impact Examples |
|---|---|---|
| **Transaction** | Core payment transaction data | `Transaction.Amount`, `Transaction.Currency`, `Transaction.CardNumber`, `Transaction.TransactionType`, `Transaction.CredentialOnFile` (COF token value), `Transaction.AuthenticationStatus` |
| **Transaction.AccountFunding** | Account Funding Transaction (AFT) sub-object | `AccountFundingPurpose`, `AccountFundingPaymentPurpose`, `AccountFundingForeignExchangeFee`, `PaymentSenderType`, `PaymentSenderIsRecipient`, `PaymentReference` |
| **Transaction.AccountFunding.Recipient** | AFT recipient details | `PaymentRecipientFirstName`, `PaymentRecipientLastName`, `PaymentRecipientMiddleName` *(toggle-gated)*, `PaymentRecipientCountry`, `PaymentRecipientDateOfBirth`, `PaymentRecipientPostcodeZip`, `PaymentRecipientStateProvinceCode` |
| **Transaction.AccountFunding.Recipient.Address** | Recipient address *(toggle-gated)* | `PaymentRecipientStreet` *(toggle-gated)*, `PaymentRecipientStreet2` *(toggle-gated)*, `PaymentRecipientCity` *(toggle-gated)* |
| **Transaction.AccountFunding.Recipient.Identification** | Recipient ID *(toggle-gated)* | `PaymentRecipientIdenficationCountry` *(toggle-gated)*, `PaymentRecipientIdentificationType` *(toggle-gated)* |
| **Transaction.CustomerIdentification** | Customer identification *(toggle-gated)* | `CustomerIdentificationType` *(toggle-gated)*, `CustomerIdentificationCountry` *(toggle-gated)*, `CustomerIdentificationValue` *(toggle-gated)* |
| **Acquirer** | Acquirer routing and identification | `Acquirer.AcquirerId`, `Acquirer.AcquirerBin`, `Acquirer.CountryCode`, `Acquirer.NetworkTransactionId` (FNT), `Acquirer.FinancialNetworkTransactionId` |
| **Merchant** | Merchant configuration data | `Merchant.MerchantId`, `Merchant.MerchantCategoryCode`, `Merchant.SubMerchant.Id`, `Merchant.SubMerchant.MarketplaceId`, `Merchant.SubMerchant.DisputePhone`, `Merchant.AggregatorName`, `Merchant.VisaPaymentFacilitatorId` |
| **RoutingHeader** | Message routing metadata | `RoutingHeader.MessageType`, `RoutingHeader.AcquirerType`, `RoutingHeader.RoutingStrategy` |

**TSPI/MEGA JSON Field Impact notation**: `TSPI: Transaction.AccountFunding.Recipient.Address (PaymentRecipientStreet/Street2/City)`, `TSPI: Transaction.CustomerIdentification (CustomerIdentificationType, CustomerIdentificationValue)`

---

#### 3. How to Decide Which Notation to Use

| Implementation Class Found | Acquirer Format | Field Notation to Use |
|---|---|---|
| `S2IAcquirerV1`, `S2IAcquirerV2` | S2I ISO 8583 | `ISO DE<n> [SE<n>] [SF<n>]` |
| `IsoDataField*Populator`, `S2IAcquirerHelper` | S2I ISO 8583 sub-field | `ISO DE<n> SE<n> SF<n>` |
| `JsonMegaMessageRequestBuilder` | S2A MEGA JSON | `TSPI: Transaction.<Field>`, `TSPI: Merchant.<Field>`, `TSPI: Acquirer.<Field>` |
| `TspiRequestMessageBuilder` | T-SPI JSON | `TSPI: Transaction.<Field>`, `TSPI: RoutingHeader.<Field>` |
| `AccountFundingValidator` (Orchestrator) | TSPI/Merchant API request | `accountFunding.<field>` (API field name) |
| `TransactionRequestValidator` (CPE) | TSPI/Merchant API request | `accountFunding.<field>` (API field name) |
| Both S2IAcquirerV1 AND JsonMegaMessageRequestBuilder | Both formats | Document ISO DE fields for S2I row; TSPI JSON fields for MEGA row — separate rows |

#### 4. S2A Toggle Type Classification
- **S2I DE Field Toggle**: ON adds/modifies specific ISO DE sub-elements in S2I acquirer message; OFF omits them
- **S2A JSON Field Toggle**: ON populates TSPI JSON context fields (Transaction/Acquirer/Merchant/RoutingHeader); OFF omits/defaults them
- **S2A Flow Toggle**: ON routes to S2A/TSPI acquirer path; OFF uses legacy S2I/standard path
- **S2A Feature Toggle**: ON enables a specific TSPI feature within S2A flow; OFF disables within S2A (both paths still use S2A)
- **API Validation Toggle**: ON applies/relaxes validation on TSPI API request fields before acquirer message is built; OFF reverses

#### 5. S2A Field Impact Documentation Examples

```
S2I ISO 8583 example:
  Field Impact: ISO DE48 SE36 SF05 — purposeOfPayment from merchant used directly (not enum default);
    ISO DE48 SE03 SF05 — purpose sub-field populated (CRYPTO→11, HIGH_RISK→16, PAYROLL→09, OTHER→08);
    ISO DE54 (Additional Amounts) — Foreign Exchange Fee validated and mapped for Visa AFT.

S2A MEGA JSON example:
  Field Impact: TSPI: Transaction.AccountFunding.Recipient.Address (PaymentRecipientStreet,
    PaymentRecipientStreet2, PaymentRecipientCity) included in MEGA JSON message;
    TSPI: Transaction.AccountFunding.Recipient.Identification (PaymentRecipientIdenficationCountry,
    PaymentRecipientIdentificationType) included;
    TSPI: Transaction.CustomerIdentification (CustomerIdentificationType, CustomerIdentificationCountry,
    CustomerIdentificationValue) included.

Dual-format toggle (separate rows needed):
  CPE S2I row — Field Impact: ISO DE108 SF01 (Transaction Reference) set to accountFunding.reference
    instead of card number; ISO DE54 FX fee mapped.
  CPE MEGA row — Field Impact: TSPI: Transaction.AccountFunding (AccountFundingPaymentPurpose,
    AccountFundingForeignExchangeFee); TSPI: Transaction.AccountFunding.Recipient
    (PaymentRecipientMiddleName, PaymentRecipientStreet, PaymentRecipientCity).
```

---

# Phase 6: Results Compilation and Output Generation (Rule 9)

For the entire batch of 5 toggles:

1. **Consolidate Batch Results**:
   - Read all matches from `ToggleBatch_{N}_SearchResults.csv` (from Phase 3)
   - Remove exact duplicate rows (same toggle, class, line number)
   - Merge usage locations (same class with multiple line numbers → keep all, each is separate row)
   - Apply registry class filtering (Rule 8) again for safety
   - Persist intermediate: `ToggleBatch_{N}_Consolidated.csv`

2. **Validate Complete Code Analysis from Phases 4 & 5**:
   - For each unique usage location, verify Phase 4 analysis captured:
     - BOTH if-block AND else-block (or absence thereof) with complete statements
     - All methods invoked in ON and OFF paths
     - All class instantiations in ON and OFF paths
     - All transformations in ON and OFF paths
   - For each S2A-related toggle, verify Phase 5 analysis captured:
     - Exact S2A control type (flow toggle, feature toggle, routing toggle, or message format toggle)
     - Which S2A classes are involved (MegaMessageMap, JsonMegaMessageMap, TSPI)
     - How toggle ON/OFF affects S2A transaction processing

3. **Ensure Accurate Impact Descriptions**:
   - **Toggle ON Impact**: Must follow two-part format — `Business: <business outcome> Field Impact: <field/protocol names>`
     - Example: `"Business: Merchants can reuse an Order ID for risk-blocked or reversed transactions enabling flexible order retry. Field Impact: order.id (TSPI/merchant API field) reuse validated against advanced rule set including risk-block and reversal history."`
     - NOT: "Enables new order reuse logic" (too vague, missing field impact)
   - **Toggle OFF Impact**: Same two-part format — `Business: <legacy/fallback outcome> Field Impact: <fields not populated or not validated>`
     - Example: `"Business: Legacy order reuse rules apply — only original narrow conditions permitted; risk-blocked or reversed Order IDs rejected. Field Impact: order.id reuse evaluated using legacy logic; order.status history not checked for new reuse conditions."`
     - NOT: "Disables feature" or "Uses old behavior"

4. **Create Output CSV Rows**:
   - Create one row per usage location per repository (dual-repo toggles produce multiple rows)
   - **Columns (6)**: `Toggle Name`, `Implementation Class Name`, `Line Number Code`, `Toggle ON Impact`, `Toggle OFF Impact`, `Repository`
   - `Repository` = `CPE` or `Orchestrator` — never combined, never omitted
   - Toggle ON/OFF Impact must use mandatory two-part format — reject any placeholder text
   - Persist to intermediate: `ToggleBatch_{N}_Consolidated.csv`

5. **Append to Final Output**:
   - Append consolidated rows to `ToggleCodebaseUsageAnalysis.csv`
   - Verify row count and persistence with `read_file`

6. **Create Batch Checkpoint** (Rule 7):
   - After batch processing complete, create `ToggleBatch_{N}_Checkpoint.txt`
   - Record metrics: toggles processed, implementation classes found, usage locations, rows written
   - Validate completion and status before proceeding to next batch

---

# Batch Processing Cycle (Optimized with Test Class Exclusion)

1. **Optimization Setup** (Phase 0):
   - Build Toggle Registry Lookup Cache (Rule 1) - **one-time, reused for all batches**
   - Index Java files from tree files (Rule 2) - **one-time, reused for all batches**
   - Build S2A Keywords Index (Rule 3) - **one-time, reused for all batches**
   - Create `OptimizationSetup_Checkpoint.txt` with setup status
   
2. **Batch Processing Loop** (15 iterations, batches 1-15):
   - **Batch {N}** (5 toggles per batch):
     - Execute Phase 1: Read 5 toggles, clean names, extract is_s2a flag
     - Execute Phase 2: Lookup in registry cache — build dual-search pattern set (display_string + constant_names); flag IMPLEMENTATION rows as Phase 3B priority targets
     - Execute Phase 3A: Run `Toggle-SearchUtility.ps1` dual search (Rule 5, skip tests Rule 5B), parse JSON with blockStart/blockEnd; cross-repo scan mandatory
     - Execute Phase 3B: `read_file(fullPath, offset=blockStart, limit=blockEnd-blockStart+5)` for each non-declaration result
     - Execute Phase 4: Analyze ON/OFF behavior using mandatory two-part Business + Field Impact format
     - Execute Phase 5: S2A analysis using cached keywords index (Rule 3) — triggered by registry class name patterns, not only is_s2a flag
     - Execute Phase 6: Consolidate → append to ToggleCodebaseUsageAnalysis.csv → checkpoint

3. **After Each Batch**:
   - Verify output CSV persistence with `read_file` (Rule 7)
   - Validate checkpoint: toggles processed, rows written, status
   - Display batch summary (with metrics from checkpoint)
   - Clean up working files: `ToggleBatch_{N}_SearchResults.csv`, `ToggleBatch_{N}_Work/`
   - Continue with next 5 toggles (if > 73 toggles exist)

4. **Repeat until all toggles processed**:
   - Batch 1-5, Batch 6-10, Batch 11-15 (covering all 73 toggles)
   - Final output: `ToggleCodebaseUsageAnalysis.csv` with all toggle usage analysis

5. **Performance Optimization Summary**:
   - Toggle Registry Lookup: 1 search (Phase 0) → reused 73 times (Rule 1)
   - Java File Index: 1 build (Phase 0) → reused 73 times (Rule 2)
   - S2A Keywords Index: 1 search (Phase 0) → reused 73 times (Rule 3)
   - Search Scope: 3989 Java files (60-70% reduction from original codebase via Rules 2 & 5)
   - Total search operations: ~73 x 5-7 variants (but consolidated via Rule 6)
   - Duplicate elimination: Rule 6 & 9 prevent redundant processing

---

# MCP Toolkit - Optimized Search & Publish Utilities

### Toolkit Components

The toggle analysis now includes production-ready MCP utilities for optimized search and result publishing:

#### 1. Toggle-SearchUtility.ps1 (PowerShell)
**Location**: `C:\Users\e135408\Downloads\mcp-servers\tools\Toggle-SearchUtility.ps1`

**Purpose**: Search for toggle usage patterns across CPE and Orchestrator repositories
- Returns structured JSON output
- Searches both repositories simultaneously
- Filters out test classes automatically
- Deduplicates results by location
- Optional declaration filtering using registry lookup

**Usage**:
```powershell
.\Toggle-SearchUtility.ps1 -ToggleName "Toggle Name" -Repository "Both"
```

**Output**: JSON with line numbers, code context, and file paths

---

#### 2. Toggle-PublishUtility.ps1 (PowerShell)
**Location**: `C:\Users\e135408\Downloads\mcp-servers\tools\Toggle-PublishUtility.ps1`

**Purpose**: Publish validated analysis data to ToggleCodebaseUsageAnalysis.csv
- Validates data before writing
- Proper CSV formatting with quote escaping
- Supports append or replace mode
- Validate-only mode for dry runs
- Returns JSON for tool integration

**Usage**:
```powershell
.\Toggle-PublishUtility.ps1 -AnalysisData $analysisData -BatchName "Batch1"
```

**Input Data Structure**:
```powershell
@{
    ToggleName = "Toggle Name"
    ImplementationClassName = "ClassName"
    LineNumber = "42"
    ONImpact = "When enabled: ..."
    OFFImpact = "When disabled: ..."
    Repository = "CPE|Orchestrator"
}
```

---

#### 3. Toggle-AnalysisBatchProcessor.ps1 (PowerShell)
**Location**: `C:\Users\e135408\Downloads\mcp-servers\tools\Toggle-AnalysisBatchProcessor.ps1`

**Purpose**: Master orchestration combining Search and Publish utilities for batch processing
- Batch processing support (5 toggles per batch by default)
- Automatic workflow: Search → Analyze → Publish
- Batch numbers (1-15) or custom ranges
- Detailed progress reporting

**Usage**:
```powershell
# Process Batch 1 (toggles 1-5)
.\Toggle-AnalysisBatchProcessor.ps1 -BatchNumber 1

# Process custom range
.\Toggle-AnalysisBatchProcessor.ps1 -StartToggleIndex 5 -ToggleCount 3
```

---

#### 4. toggle_search_optimized.py (Python - Recommended)
**Location**: `C:\Users\e135408\Downloads\mcp-servers\tools\toggle_search_optimized.py`

**Purpose**: High-performance toggle search with parallel processing and caching
- 50-80% faster than PowerShell
- 8 concurrent worker threads
- Smart caching of Java file index (1-hour TTL)
- Intelligent match type detection (DECLARATION, USAGE_CHECK, REFERENCE)
- Batch export (JSON + CSV)

**Features**:
- Parallel processing: 8 concurrent worker threads
- Caching: Automatic Java file index caching (1 hour TTL)
- Context extraction: ±3 lines around each match
- Match classification: DECLARATION vs USAGE_CHECK vs REFERENCE
- Repository awareness: Auto-detects CPE vs Orchestrator
- Statistics: Files/second, matches by repo, unique classes

**Usage**:
```bash
python toggle_search_optimized.py
```

**Performance Metrics**:
- Single toggle: <2 seconds (vs 2-5 PowerShell)
- 5-toggle batch: ~8 seconds (vs 15-30 PowerShell)
- 73-toggle analysis: ~25-30 minutes (vs 2-3 hours PowerShell)
- Memory: 50MB (vs 120MB PowerShell)

---

### Toolkit Integration with Agent Workflow

The agent can invoke these utilities through `run_in_terminal`:

**Step 1: Search for toggle usage**
```powershell
$results = & Toggle-SearchUtility.ps1 -ToggleName "Toggle Name" -Repository "Both"
$jsonData = $results | ConvertFrom-Json
```

**Step 2: Analyze results (agent work)**
- Read code files
- Extract ON/OFF impacts
- Document class/method details

**Step 3: Publish results**
```powershell
$analysisData = @(...)  # Array of analysis objects
& Toggle-PublishUtility.ps1 -AnalysisData $analysisData -AppendOnly
```

---

### Optimization Rules Implementation in Toolkit

The toolkit implements all 9 optimization rules:

| Rule | Toolkit Implementation |
|------|------------------------|
| 1 | Toggle registry cache built (220 declarations) in Phase 0 |
| 2 | Java file index cached and reused across all searches |
| 3 | S2A keywords index available for Phase 5 analysis |
| 4 | Batch variant patterns pre-generated in search utility |
| 5 | Java-only search with `includePattern="src/main/java/**/*.java"` |
| 5B | Test class exclusion built into search filters |
| 6 | Batch caching in-memory, consolidated before CSV output |
| 7 | Checkpoint support for resumable analysis |
| 8 | Registry filtering integrated in search results |
| 9 | Deduplication and validation before publishing |

---

### Documentation

**Complete Toolkit Guide**: `README_MCP_Tools.md`
- Detailed parameter documentation
- Usage examples
- Input/output specifications
- Integration guidelines
- Troubleshooting guide

**Deployment Summary**: `MCP_TOOLS_DEPLOYMENT_SUMMARY.md`
- Tool inventory and status
- Performance metrics
- Test results
- Next steps

---

### Batch 1 Results (Complete)

**Status**: ✓ COMPLETE - 7 analysis rows generated

**Toggles Analyzed**: 5 toggles
- System Toggle: CPE Load Balancer Uses Ping (2 locations)
- System Toggle: Enable Lookup up to 8 digit bin for Card Identification
- Apply New Order ID Reuse Rule (2 locations - dual-repository)
- System Toggle: Disables loading from orderCache in CPE
- Enable TAF fields support for Passthrough

**Output**: `ToggleCodebaseUsageAnalysis.csv` with 7 data rows

**Performance**:
- Search time: <3 seconds per toggle
- Total processing: ~15 seconds for 5 toggles
- Files scanned: 4,278 Java files

---

### Recommended Workflow for Remaining Batches (2-15)

**Option A: Automated (PowerShell Batch Processor)**
```powershell
2..15 | ForEach-Object {
    .\Toggle-AnalysisBatchProcessor.ps1 -BatchNumber $_
    Start-Sleep -Seconds 5
}
```
- Time: ~2-3 hours
- Automated end-to-end
- Progress tracking built-in

**Option B: Optimized (Python + PowerShell)**
```bash
# Fast search with Python
python toggle_search_optimized.py

# Detailed analysis with agent (manual or scripted)
# Publish with PowerShell utility
```
- Time: ~30-45 minutes
- 50-80% faster
- Parallel processing advantage

**Option C: Hybrid (Best of Both)**
```powershell
# Use Python for fast parallel search
# Use agent for detailed code analysis
# Use PowerShell for result publishing
```
- Time: ~45 minutes - 1 hour
- Balanced speed and accuracy
- Leverages all tool strengths

---