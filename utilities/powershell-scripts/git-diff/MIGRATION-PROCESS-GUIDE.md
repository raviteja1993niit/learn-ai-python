# Code Migration Process Guide

> **Audience:** Developers on the Mastercard PGS Connectivity team migrating staged
> Java source changes between sibling repositories using the `git-diff` utility
> toolkit.
>
> **Last updated:** 2026-04-13  
> **Context:** Migration of Void Auth & Verify Operations changes from the service
> source repository into the test-data repository.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Repositories Involved](#2-repositories-involved)
3. [Folder Structure of This Toolkit](#3-folder-structure-of-this-toolkit)
4. [Scripts Reference](#4-scripts-reference)
   - [Generate-GitDiff.ps1](#41-generate-gitdiffps1--primary-diff-engine)
   - [git-diff.ps1](#42-git-diffps1--quick-wrapper)
   - [Batch-GenerateGitDiffs.ps1](#43-batch-generategitdiffsps1--multi-repo-batch)
   - [Install-GitDiffScripts.ps1](#44-install-gitdiffscriptsps1--installer)
   - [active/git-diff-capture-simple.ps1](#45-activegit-diff-capture-simpleps1--branch-to-branch-diff)
   - [active/run-git-diff.bat](#46-activerun-git-diffbat--windows-batch-launcher)
   - [in-active/git-diff-capture.ps1](#47-in-activegit-diff-captureps1--legacy-branch-diff)
   - [in-active/pr-diff/generate-pr-from-stash.ps1](#48-in-activepr-diffgenerate-pr-from-stashps1--pr-draft-from-stash)
5. [Migration Workflow — Step by Step](#5-migration-workflow--step-by-step)
   - [Phase 1 — Inspect the Source Repository](#phase-1--inspect-the-source-repository)
   - [Phase 2 — Identify Files to Migrate](#phase-2--identify-files-to-migrate)
   - [Phase 3 — Extract Staged Content](#phase-3--extract-staged-content)
   - [Phase 4 — Apply Changes to Target Repository](#phase-4--apply-changes-to-target-repository)
   - [Phase 5 — Verify the Target Build](#phase-5--verify-the-target-build)
6. [Commands Used in This Session](#6-commands-used-in-this-session)
7. [Known Issue: UTF-8 BOM in Migrated Java Files](#7-known-issue-utf-8-bom-in-migrated-java-files)
   - [Symptoms](#symptoms)
   - [Root Cause](#root-cause)
   - [Diagnosis Command](#diagnosis-command)
   - [Fix — Strip BOM from All Affected Files](#fix--strip-bom-from-all-affected-files)
   - [Prevention — Write Java Files Without BOM](#prevention--write-java-files-without-bom)
8. [Output Files Produced](#8-output-files-produced)
9. [Execution Policy](#9-execution-policy)

---

## 1. Overview

This guide documents the **end-to-end process** used to:

1. **Capture** the state of a feature branch in the source service repository using
   the `Generate-GitDiff.ps1` script — streaming all diff content to a timestamped
   log file for review.
2. **Identify** which staged Java source changes are relevant to the companion test
   repository.
3. **Safely migrate** those changes (staged index versions only, not unstaged working
   directory versions) to the correct paths in the test repository.
4. **Diagnose and fix** the UTF-8 BOM encoding issue that broke the Java compiler
   after the initial migration.

The toolkit is designed as a **read-only inspection layer** that does not modify the
source repository. All output is written to the local `logs/` and `output/` folders
of the toolkit itself.

```
Source Repo (service)          git-diff toolkit              Target Repo (test-data)
─────────────────────          ────────────────              ───────────────────────
feature branch                 Generate-GitDiff.ps1          lib-elavon-interface-
  staged changes   ──────────▶   inspects & logs   ──────▶    test-data (migrated)
  stash                          timestamped log
                                 diff-summary
```

---

## 2. Repositories Involved

| Role | Local Path |
|------|-----------|
| **Source** (service repo) | `C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\`<br>`107651-pgsaaselavon-pgs-acquirer-elavon-interface-service` |
| **Target** (test repo) | `C:\Users\e135408\IdeaProjects\MODERNIZATION\`<br>`107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test` |
| **Toolkit** | `C:\Users\e135408\IdeaProjects\utility-scripts\`<br>`powershell-scripts\git-diff` |

**Source branch at time of migration:**
```
feature/G1198_18577_TIMEOUT_FLOW_TESTS
commit: c707403f2876df0bc28f1f7718625f273b5b547f
```

**Stash captured:**
```
stash@{0}: On feature/G1198_18577_TIMEOUT_FLOW_TESTS: Working Void Auth & Verify Operations
```

**Staged files migrated (from `lib-elavon-interface-test-data/`):**

| Git Status | File |
|-----------|------|
| `M` Modified | `flow/ElavonSystemTransactions.java` |
| `M` Modified | `flow/config/BaseElavon.java` |
| `M` Modified | `flow/constant/TestConstants.java` |
| `M` Modified | `flow/model/ElavonVerifyTransactions.java` |
| `M` Modified | `flow/msg/Acquirer.java` |
| `A` New file  | `flow/model/ElavonVoidTransactions.java` |
| `A` New file  | `flow/scenarios/VoidScenarios.java` |

> **Important:** Only the **staged (index) version** of each file is migrated —
> not the working directory version, which may contain additional unstaged changes
> still in progress.

---

## 3. Folder Structure of This Toolkit

```
git-diff/
│
├── Generate-GitDiff.ps1          ← PRIMARY: full repo diff → timestamped log
├── git-diff.ps1                  ← Quick wrapper with sensible defaults
├── Batch-GenerateGitDiffs.ps1    ← Run Generate-GitDiff across many repos
├── Install-GitDiffScripts.ps1    ← Validates install, optional PATH setup
│
├── active/                       ← In-use branch-comparison scripts
│   ├── git-diff-capture-simple.ps1   ← Branch-to-branch diff, LLM-friendly output
│   └── run-git-diff.bat              ← Windows .bat launcher for the PS1 above
│
├── in-active/                    ← Archived / superseded scripts (kept for reference)
│   ├── git-diff-capture.ps1          ← Legacy branch diff (older version)
│   └── pr-diff/
│       └── generate-pr-from-stash.ps1 ← Experimental PR draft generator from stash
│
├── logs/                         ← Full timestamped diff logs (streamed, never overwritten)
│   ├── git-diff-<yyyyMMdd_HHmmss>.log
│   └── change-report-*.md
│
├── output/                       ← Lightweight summary files + legacy outputs
│   ├── diff-summary-<yyyyMMdd_HHmmss>.txt
│   └── git-diff.txt  (legacy, pre-streaming)
│
└── docs/                         ← Reference documentation
    ├── README.md
    ├── QUICKSTART.md
    ├── INSTALLATION_SUMMARY.md
    └── script-commands.txt
```

**Design principle:** The `logs/` folder receives the heavy full-patch files
(timestamped, never overwritten). The `output/` folder holds lightweight summary
files and legacy outputs. Scripts remain at the root for direct `.\` invocation.

---

## 4. Scripts Reference

### 4.1 `Generate-GitDiff.ps1` — Primary Diff Engine

**Version:** 2.0.0  
**Purpose:** Analyze any local git repository and stream the complete diff state
to a timestamped log file, with a paired lightweight summary.

**Key design decisions:**

- Uses `[System.IO.StreamWriter]` instead of `ArrayList` — writes each diff line
  directly to disk, avoiding large in-memory buffering for big repositories.
- Both output files share the **same timestamp** so each run produces a matched pair
  that can never be confused with previous runs.
- The `-C <repo>` flag is placed **before** git sub-commands (`& git -C $RepoPath
  @Arguments`) — the correct order required by git.

**Parameters:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-RepoPath` | ✅ Yes | — | Path to the git repository |
| `-LogsDir` | No | `<script-dir>\logs` | Directory for timestamped log files |
| `-IncludeHistory` | No | `$true` | Include commit history in log |
| `-HistoryDepth` | No | `20` | Number of commits to include |
| `-IncludeStashed` | No | `$true` | Include stash diffs in log |
| `-BranchCompare` | No | — | Compare current branch vs this branch |
| `-VerboseOutput` | No | `$false` | Print section headers to console |

**Output files produced per run:**

```
logs\git-diff-<yyyyMMdd_HHmmss>.log        ← Full diff (streamed, ~400 KB typical)
diff-summary-<yyyyMMdd_HHmmss>.txt         ← Quick stats: branch, counts, stash list
```

**Content sections written to the full log:**

1. Repository information (branch, commit SHA, remote URL)
2. File status counts (untracked / modified / deleted / renamed / added)
3. File status details (porcelain listing per category)
4. Working directory changes (`git diff`)
5. Staged changes — index (`git diff --cached`)
6. Stashed changes — stat + full patch per stash entry
7. Branch comparison diff (optional, requires `-BranchCompare`)
8. Commit history with graph decoration

---

### 4.2 `git-diff.ps1` — Quick Wrapper

**Purpose:** Simplified interface to `Generate-GitDiff.ps1` with three one-flag
modes for everyday use.

**Modes:**

| Flag | History | Stash | History Depth |
|------|---------|-------|---------------|
| *(default)* | ✅ | ✅ | 20 |
| `-Quick` | ❌ | ❌ | — |
| `-Full` | ✅ | ✅ | 50 |

**Examples:**
```powershell
# Current directory (default)
.\git-diff.ps1

# Named repo, quick mode
.\git-diff.ps1 -RepoPath "C:\projects\myrepo" -Quick

# Full 50-commit history, verbose
.\git-diff.ps1 -RepoPath "C:\projects\myrepo" -Full -Verbose
```

---

### 4.3 `Batch-GenerateGitDiffs.ps1` — Multi-Repo Batch

**Purpose:** Scans a parent directory for git repositories and generates a diff
report for each one, organised under a `git-diff-reports/<repo-name>/` folder.

**Parameters:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-ParentPath` | ✅ Yes | — | Directory containing multiple repos |
| `-ReportsDir` | No | `.\git-diff-reports` | Output root |
| `-Recursive` | No | `$false` | Search subdirectories for repos |
| `-HistoryDepth` | No | `20` | Commits per repo |

**Example:**
```powershell
# Generate reports for all repos under MODERNIZATION/
.\Batch-GenerateGitDiffs.ps1 `
    -ParentPath "C:\Users\e135408\IdeaProjects\MODERNIZATION" `
    -ReportsDir "C:\reports\diffs" `
    -Recursive
```

---

### 4.4 `Install-GitDiffScripts.ps1` — Installer

**Purpose:** Validates all required scripts are present and optionally adds the
toolkit directory to the system `PATH` (requires administrator privileges).

**What it checks:**
- `Generate-GitDiff.ps1` present
- `Batch-GenerateGitDiffs.ps1` present
- `git-diff.ps1` present
- Script execution test (runs `git-diff.ps1 -Quick` against its own directory)

**Example:**
```powershell
# Validate only
.\Install-GitDiffScripts.ps1

# Validate and add to system PATH (run as Administrator)
.\Install-GitDiffScripts.ps1 -AddToPath
```

---

### 4.5 `active/git-diff-capture-simple.ps1` — Branch-to-Branch Diff

**Purpose:** Generates a structured, **LLM-parsable** diff report comparing two
named branches. Useful for feeding diff content to AI code review tools or for
generating change-report documents.

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-SourceBranch` | ✅ Yes | Feature branch (changes you want to inspect) |
| `-TargetBranch` | ✅ Yes | Base branch to compare against |
| `-OutputFile` | No | Auto-generated with timestamp if omitted |
| `-FileFilter` | No | Regex pattern — e.g. `\.java$` |
| `-DirectoryFilter` | No | Relative or absolute path segment |

**Output format:** Structured report with labelled sections
(`REPORT_HEADER`, `FILE_CHANGE_SUMMARY`, `DETAILED_DIFFS`, `STATISTICS`,
`COMMIT_LOG`) and fenced ` ```diff ` blocks per file — designed to be pasted
directly into an AI prompt or Confluence page.

**Example — same commands used in this project:**
```powershell
cd "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service"

.\active\git-diff-capture-simple.ps1 `
    -SourceBranch "G1198_16781_SUPPORT_VERIFY_OPS" `
    -TargetBranch "develop"

# Filter to Java files only
.\active\git-diff-capture-simple.ps1 `
    -SourceBranch "G1198_16781_SUPPORT_VERIFY_OPS" `
    -TargetBranch "develop" `
    -FileFilter "\.java$"

# Filter to a specific sub-module
.\active\git-diff-capture-simple.ps1 `
    -SourceBranch "G1198_16781_SUPPORT_VERIFY_OPS" `
    -TargetBranch "develop" `
    -DirectoryFilter "lib-elavon-interface-test-data"
```

Output is saved to:
```
logs\git-diffs-<source>-vs-<target>-<yyyyMMdd_HHmmss>.txt
```

---

### 4.6 `active/run-git-diff.bat` — Windows Batch Launcher

**Purpose:** A Windows `.bat` wrapper around `git-diff-capture-simple.ps1` for
users who prefer double-clicking or running from Command Prompt without typing
PowerShell parameters.

**How to use:**

1. Open `run-git-diff.bat` in a text editor.
2. Edit the `USER CONFIGURATION` section at the top:
   ```batch
   SET SOURCE_BRANCH=G1198_16781_SUPPORT_VERIFY_OPS
   SET TARGET_BRANCH=develop
   SET FILE_FILTER=.yaml
   SET DIR_FILTER=src/main/resources
   SET OUTPUT_FILE=
   ```
3. Save and double-click, or run from a terminal:
   ```cmd
   scripts\run-git-diff.bat
   ```

The `.bat` resolves relative paths, validates required variables, and calls
PowerShell with `-ExecutionPolicy Bypass` so no permanent policy change is needed.

---

### 4.7 `in-active/git-diff-capture.ps1` — Legacy Branch Diff

**Status:** Archived — superseded by `active/git-diff-capture-simple.ps1`.

**Why archived:** The original version used `Invoke-Expression` for git calls
(security risk with dynamic strings), did not normalize directory filter paths,
and lacked the LLM-friendly structured output format. Kept for historical reference.

---

### 4.8 `in-active/pr-diff/generate-pr-from-stash.ps1` — PR Draft from Stash

**Status:** Experimental / archived.

**Purpose:** Creates a temporary branch, applies a stash onto it, groups changed
files by top-level folder, and generates a suggested set of conventional commit
messages plus a PR description draft saved to `.git/pr-descriptions/`.

**Use case:** When a stash contains a large set of changes across multiple modules
and you want a head-start on structuring the commits and PR body.

**Example:**
```powershell
# Apply stash@{0} and generate PR draft (no auto-commit)
.\in-active\pr-diff\generate-pr-from-stash.ps1 -StashRef "stash@{0}"

# Auto-commit the suggested groupings
.\in-active\pr-diff\generate-pr-from-stash.ps1 -StashRef "stash@{0}" -AutoCommit
```

---

## 5. Migration Workflow — Step by Step

### Phase 1 — Inspect the Source Repository

**Goal:** Capture a full snapshot of all uncommitted, staged, and stashed changes
so you have a reliable reference before touching any files.

```powershell
# Navigate to the toolkit
cd "C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff"

# Allow script execution for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Run the full diff capture against the source service repo
.\Generate-GitDiff.ps1 `
    -RepoPath "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service" `
    -VerboseOutput
```

**What this does:**

1. Validates the path is a git repository.
2. Opens a `StreamWriter` on `logs\git-diff-<timestamp>.log`.
3. Streams: repo metadata → status counts → working-dir diff → staged diff →
   stash full patches → commit history.
4. Closes the writer and writes a paired `diff-summary-<timestamp>.txt`.

**Review the summary first:**
```powershell
Get-Content ".\output\diff-summary-20260413_112811.txt"
```

Sample output:
```
Branch      : feature/G1198_18577_TIMEOUT_FLOW_TESTS
FILE STATUS:
  Untracked : 10
  Modified  : 7
  Added     : 2
  Total     : 19
STASHES (1 found):
  stash@{0}: On feature/...: Working Void Auth & Verify Operations
```

---

### Phase 2 — Identify Files to Migrate

**Goal:** Determine which of the staged changes belong in the target test repository.

```powershell
$src = "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service"

# List all staged files with their status (A=added, M=modified, D=deleted)
git -C $src diff --cached --name-status
```

**Decision rules applied:**

| File | Migrate? | Reason |
|------|----------|--------|
| `lib-elavon-interface-test-data/src/main/java/**/*.java` | ✅ Yes | These are test-data classes that live in the test repo |
| `pgs-acquirer-elavon-interface-service/src/...` | ❌ No | Service-only code; no corresponding path in test repo |
| `pgs-acquirer-elavon-interface-service/src/main/resources/application.yml` | ❌ No | Service configuration; not in test repo |
| `pom.xml` (root, service module) | ❌ No | Service POM; not applicable |
| `AD` (staged-then-deleted markdown/script files) | ❌ No | Documentation/script artefacts |

**Version discipline:** Always extract the **staged (index) version** using
`git show :<path>` — never copy working-directory files directly, as the working
directory may contain additional unstaged in-progress changes.

```powershell
# Extract exact staged content of a specific file (index version)
git -C $src show ":lib-elavon-interface-test-data/src/main/java/com/mastercard/pgs/connectivity/acquirer/flow/model/ElavonVoidTransactions.java"
```

---

### Phase 3 — Extract Staged Content

**Goal:** For each file to migrate, capture the exact staged content and write
it to the corresponding path in the target repository.

**Key rule — always write Java files without BOM:**

```powershell
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)  # $false = no BOM

# Extract staged content and write to target
$content = git -C $sourceRepo show ":$relPath"
$targetPath = "C:\...\test-repo\$relPath"
[System.IO.File]::WriteAllText($targetPath, ($content -join "`n") + "`n", $utf8NoBom)
```

> ⚠️ **Do NOT use `| Out-File -Encoding UTF8`** — Windows PowerShell 5.x writes
> UTF-8 **with BOM**, which breaks the Java compiler.  
> See [Section 7](#7-known-issue-utf-8-bom-in-migrated-java-files) for full details.

---

### Phase 4 — Apply Changes to Target Repository

Recommended order of migration (foundational → dependent):

| Step | File | Action |
|------|------|--------|
| 1 | `TestConstants.java` | Modify: add new constants, relocate `ASSOC_AUTH_MERCHANT_ORDER_WS_API_ID`, update `CARD_ACCEPTOR` value |
| 2 | `VoidScenarios.java` | **Create new file** in `scenarios/` package |
| 3 | `Acquirer.java` | Modify: add `voidRequest()` and `voidResponse()` factory methods |
| 4 | `BaseElavon.java` | Modify: add `getElavonVoidBaseInteraction()` method + import updates |
| 5 | `ElavonVoidTransactions.java` | **Create new file** in `model/` package |
| 6 | `ElavonVerifyTransactions.java` | Modify: add acquirer processing time fields to all switch branches |
| 7 | `ElavonSystemTransactions.java` | Modify: update imports, comment old `.with()` calls, add new ones |

**After applying each file, verify no BOM was introduced** (see Phase 5).

---

### Phase 5 — Verify the Target Build

```powershell
$testRepo = "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test"

# Step 1: BOM check on all migrated Java files
$migratedFiles = @(
    "$testRepo\lib-elavon-interface-test-data\src\main\java\com\mastercard\pgs\connectivity\acquirer\flow\config\BaseElavon.java",
    "$testRepo\lib-elavon-interface-test-data\src\main\java\com\mastercard\pgs\connectivity\acquirer\flow\constant\TestConstants.java",
    "$testRepo\lib-elavon-interface-test-data\src\main\java\com\mastercard\pgs\connectivity\acquirer\flow\ElavonSystemTransactions.java",
    "$testRepo\lib-elavon-interface-test-data\src\main\java\com\mastercard\pgs\connectivity\acquirer\flow\model\ElavonVoidTransactions.java",
    "$testRepo\lib-elavon-interface-test-data\src\main\java\com\mastercard\pgs\connectivity\acquirer\flow\model\ElavonVerifyTransactions.java",
    "$testRepo\lib-elavon-interface-test-data\src\main\java\com\mastercard\pgs\connectivity\acquirer\flow\msg\Acquirer.java",
    "$testRepo\lib-elavon-interface-test-data\src\main\java\com\mastercard\pgs\connectivity\acquirer\flow\scenarios\VoidScenarios.java"
)

foreach ($f in $migratedFiles) {
    $b = [System.IO.File]::ReadAllBytes($f)
    $hasBom = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
    Write-Host ("{0,-35}  BOM={1}" -f (Split-Path -Leaf $f), $hasBom)
}

# Step 2: Compile the test-data module
cd "$testRepo\lib-elavon-interface-test-data"
mvn clean compile -q
```

**Expected result:** No `illegal character: '\ufeff'` errors. The only acceptable
failure at this stage is a network/SSL error reaching the internal Archiva Maven
repository (`PKIX path building failed`) — this is an environment issue unrelated
to the migrated source files and will succeed in the CI environment.

---

## 6. Commands Used in This Session

All raw git commands used during inspection and migration:

```powershell
$src = "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service"

# --- Repository inspection ---

# Current branch
git -C $src rev-parse --abbrev-ref HEAD

# Current commit SHA
git -C $src rev-parse HEAD

# Full status (porcelain — machine-readable)
git -C $src status --porcelain

# List staged files with status (A/M/D)
git -C $src diff --cached --name-only
git -C $src diff --cached --name-status

# Full staged patch (what would go into the next commit)
git -C $src diff --cached --no-color

# Full working-directory patch (unstaged changes)
git -C $src diff --no-color

# Recent history with graph
git -C $src log -n 20 --oneline --graph --decorate --all


# --- Stash inspection ---

# List all stashes
git -C $src stash list

# File summary of a stash (fast, no patch)
git -C $src stash show --stat --no-color "stash@{0}"

# Full patch of a stash
git -C $src stash show -p --no-color "stash@{0}"

# Apply stash (keeps stash in list)
git -C $src stash apply "stash@{0}"

# Pop stash (applies and removes from list)
git -C $src stash pop "stash@{0}"


# --- Staged content extraction ---

# Get exact staged (index) version of a specific file
git -C $src show ":lib-elavon-interface-test-data/src/main/java/com/mastercard/pgs/connectivity/acquirer/flow/model/ElavonVoidTransactions.java"

git -C $src show ":lib-elavon-interface-test-data/src/main/java/com/mastercard/pgs/connectivity/acquirer/flow/scenarios/VoidScenarios.java"


# --- Toolkit commands ---

cd "C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff"

# Allow scripts for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Full diff capture — source service repo
.\Generate-GitDiff.ps1 `
    -RepoPath "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service"

# With verbose console headers
.\Generate-GitDiff.ps1 `
    -RepoPath "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service" `
    -VerboseOutput

# With branch comparison
.\Generate-GitDiff.ps1 `
    -RepoPath "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service" `
    -BranchCompare "origin/develop"

# Full diff capture — target test repo
.\Generate-GitDiff.ps1 `
    -RepoPath "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test"

# Branch-to-branch diff (LLM-friendly output)
.\active\git-diff-capture-simple.ps1 `
    -SourceBranch "G1198_16781_SUPPORT_VERIFY_OPS" `
    -TargetBranch "develop"
```

---

## 7. Known Issue: UTF-8 BOM in Migrated Java Files

### Symptoms

After migrating Java files, the Maven build fails with these errors on every
migrated file:

```
java: illegal character: '\ufeff'
<FileName>.java:5:9
java: class, interface, enum, or record expected
```

The `'\ufeff'` character is the **Unicode Byte Order Mark (BOM)**.
It appears on line 1, before the `/*` copyright comment — causing the compiler
to reject the file before it even reaches the package declaration.

### Root Cause

**Windows PowerShell 5.x** (`Out-File -Encoding UTF8`) writes UTF-8 files
**with a 3-byte BOM prefix** (`0xEF 0xBB 0xBF`).

The Java compiler (`javac`) does **not** tolerate a BOM at the start of a source
file — it treats it as an illegal character and fails immediately.

This is a well-known PowerShell 5.x behaviour. PowerShell 7+ uses UTF-8 **without**
BOM by default, but the project targets Windows PowerShell 5.1.

### Diagnosis Command

Run this to check which files have a BOM before attempting a build:

```powershell
$testRepo = "C:\Users\e135408\IdeaProjects\MODERNIZATION\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test"

Get-ChildItem "$testRepo\lib-elavon-interface-test-data\src" -Recurse -Filter "*.java" | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    if ($hasBom) {
        Write-Host "BOM FOUND: $($_.Name)  ->  $($_.FullName)" -ForegroundColor Red
    }
}
```

### Fix — Strip BOM from All Affected Files

The fix reads the raw bytes, drops the first 3 bytes if they are the BOM sequence,
then rewrites the file using `[System.Text.UTF8Encoding]::new($false)`:

```powershell
$files = @(
    "C:\...\flow\config\BaseElavon.java",
    "C:\...\flow\constant\TestConstants.java",
    "C:\...\flow\ElavonSystemTransactions.java",
    "C:\...\flow\model\ElavonVoidTransactions.java",
    "C:\...\flow\model\ElavonVerifyTransactions.java",
    "C:\...\flow\msg\Acquirer.java",
    "C:\...\flow\scenarios\VoidScenarios.java"
)

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes[3..($bytes.Length - 1)])
    } else {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    [System.IO.File]::WriteAllText($f, $text, $utf8NoBom)
    Write-Host "  BOM removed  ->  $(Split-Path -Leaf $f)" -ForegroundColor Green
}
```

**Result after running the fix:**

```
  BOM removed  ->  BaseElavon.java
  BOM removed  ->  TestConstants.java
  BOM removed  ->  ElavonSystemTransactions.java
  BOM removed  ->  ElavonVoidTransactions.java
  BOM removed  ->  ElavonVerifyTransactions.java
  BOM removed  ->  Acquirer.java
  BOM removed  ->  VoidScenarios.java
```

Subsequent `mvn clean compile` produced **no BOM errors** — only the expected
network SSL error reaching the internal Archiva repository (unrelated to the
source files, passes in CI).

### Prevention — Write Java Files Without BOM

Any script that writes Java source files must use `[System.IO.File]::WriteAllText`
with the no-BOM encoder:

```powershell
# ✅ CORRECT — UTF-8 without BOM (Java-safe)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($targetPath, $content, $utf8NoBom)

# ❌ WRONG — PowerShell 5.x Out-File adds BOM, breaks javac
$content | Out-File -FilePath $targetPath -Encoding UTF8

# ❌ ALSO WRONG — Set-Content UTF8 in PS 5.x also adds BOM
$content | Set-Content -Path $targetPath -Encoding UTF8
```

> **Note for PowerShell 7+ users:** `Out-File -Encoding utf8` in PS 7+ writes
> without BOM by default. However, since this project runs on Windows PowerShell
> 5.1, always use `[System.IO.File]::WriteAllText` with the explicit no-BOM
> encoder for portability.

---

## 8. Output Files Produced

Each run of `Generate-GitDiff.ps1` produces exactly two files sharing the same
timestamp:

| File | Location | Purpose | Typical Size |
|------|----------|---------|-------------|
| `git-diff-<ts>.log` | `logs/` | Full streamed diff — all sections | ~400 KB |
| `diff-summary-<ts>.txt` | `output/` | Quick stats — branch, counts, stash list, path to log | ~1 KB |

**Session output (2026-04-13):**

| File | Timestamp | Size |
|------|-----------|------|
| `logs/git-diff-20260413_112811.log` | 2026-04-13 11:28:11 | 417 KB |
| `output/diff-summary-20260413_112811.txt` | 2026-04-13 11:28:23 | 1.2 KB |

The `logs/` folder also retains earlier captures:

| File | Notes |
|------|-------|
| `logs/git-diff-20260413_112442.log` | First run (before staged files were added) |
| `logs/git-diff-20260413_112811.log` | Second run (after `git add` of new files) |
| `logs/git-diffs-G1198_16781_SUPPORT_VERIFY_OPS-vs-develop-20260407_185449.txt` | Branch comparison from earlier session |
| `logs/change-report-G1198_16781_SUPPORT_VERIFY_OPS-vs-develop.md` | Structured Markdown change report |

---

## 9. Execution Policy

If PowerShell blocks script execution with:
```
.\Generate-GitDiff.ps1 cannot be loaded because running scripts is disabled on this system.
```

Run this **once per terminal session** — it does not change any system-wide setting:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run any script normally. The bypass expires when the terminal window closes.

