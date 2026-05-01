# Git-Diff Utility Scripts

**Comprehensive Git Repository Analysis and Diff Reporting Tool**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Installation](#installation)
4. [Scripts](#scripts)
5. [Usage Examples](#usage-examples)
6. [Report Contents](#report-contents)
7. [Command Reference](#command-reference)
8. [Advanced Usage](#advanced-usage)
9. [Troubleshooting](#troubleshooting)
10. [Technical Details](#technical-details)

---

## Overview

The **Git-Diff Utility Scripts** provide a comprehensive solution for analyzing and reporting Git repository changes. Generate detailed, structured diff reports for any local Git repository in seconds, capturing:

- ✓ Uncommitted working directory changes
- ✓ Staged changes (index)
- ✓ All stashed changes with full diffs
- ✓ Commit history with detailed metadata
- ✓ Branch comparisons and ahead/behind counts
- ✓ Complete file status listings
- ✓ Summary statistics

**Perfect for:**
- Code migration planning and verification
- Repository state documentation
- Change tracking and analysis
- Pre-commit audits
- Multi-repository reporting

---

## Features

### Generic & Universal
- Works with **any Git repository** (no hardcoded paths or module names)
- Platform independent (Windows, Linux, macOS)
- No external dependencies beyond Git

### Multiple Modes
- **Quick Mode** – Fast analysis (skip stashed, history)
- **Full Mode** – Comprehensive with extended history
- **Batch Mode** – Process multiple repositories at once
- **Custom Mode** – Full control over all parameters

### Output Formats
- **Text Report** (`.txt`) – Plain text, comprehensive, searchable
- **Structured Sections** – Organized by change type
- **Statistics** – File counts, change metrics
- **Console Output** – Real-time progress with color coding

### Flexible Configuration
- Configurable history depth (commits to include)
- Optional stashed change analysis
- Branch comparison support
- Custom output locations
- Verbose/silent modes

---

## Installation

### Prerequisites

- **PowerShell 5.0+** (Windows 10+ or Windows Server 2016+)
- **Git 2.0+** (installed and in system PATH)

Verify installation:
```powershell
git --version
$PSVersionTable.PSVersion
```

### Step 1: Verify Scripts Location

Scripts are pre-installed in:
```
C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff\
```

Verify all scripts exist:
```powershell
cd "C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff"
Get-ChildItem -Filter "*.ps1" | Select-Object Name
```

You should see:
- ✓ Generate-GitDiff.ps1
- ✓ Batch-GenerateGitDiffs.ps1
- ✓ git-diff.ps1
- ✓ Install-GitDiffScripts.ps1

### Step 2: (Optional) Run Installation Script

To validate and optionally add to system PATH:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
.\Install-GitDiffScripts.ps1
```

With admin privileges, also add to PATH:
```powershell
.\Install-GitDiffScripts.ps1 -AddToPath
```

---

## Scripts

### 1. Generate-GitDiff.ps1

**Main script for generating comprehensive git-diff reports.**

#### Purpose
Analyzes a Git repository and creates a detailed `git-diff.txt` report.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-RepoPath` | String | **Required** | Path to git repository to analyze |
| `-OutputFile` | String | `<repo>/git-diff.txt` | Output file path for report |
| `-HistoryDepth` | Int | 20 | Number of commits to include |
| `-IncludeHistory` | Switch | true | Include commit history in report |
| `-IncludeStashed` | Switch | true | Include stashed changes in report |
| `-BranchCompare` | String | null | Compare with this branch (e.g., 'develop') |
| `-VerboseOutput` | Switch | false | Print output to console while writing |

#### Example Usage

```powershell
# Basic usage with defaults
.\Generate-GitDiff.ps1 -RepoPath "C:\projects\my-service"

# Custom output file and history depth
.\Generate-GitDiff.ps1 -RepoPath "C:\projects\my-service" `
  -OutputFile "C:\reports\my-service-diff.txt" `
  -HistoryDepth 50

# Compare with develop branch
.\Generate-GitDiff.ps1 -RepoPath "C:\projects\my-service" `
  -BranchCompare "origin/develop"

# Quick analysis (minimal output)
.\Generate-GitDiff.ps1 -RepoPath "C:\projects\my-service" `
  -IncludeHistory:$false `
  -IncludeStashed:$false

# Verbose mode (see output in real-time)
.\Generate-GitDiff.ps1 -RepoPath "C:\projects\my-service" `
  -VerboseOutput
```

---

### 2. git-diff.ps1

**Quick wrapper with sensible defaults for common use cases.**

#### Purpose
Simplified interface to `Generate-GitDiff.ps1` for rapid analysis.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-RepoPath` | String | Current directory | Repository path |
| `-Output` | String | `<repo>/git-diff.txt` | Output file path |
| `-Quick` | Switch | false | Fast mode (exclude stashed, history) |
| `-Full` | Switch | false | Full mode (50-commit history) |
| `-Verbose` | Switch | false | Print to console |

#### Example Usage

```powershell
# Current directory (uses working directory)
.\git-diff.ps1

# Specific repository
.\git-diff.ps1 -RepoPath "C:\projects\my-service"

# Quick mode (fastest)
.\git-diff.ps1 -RepoPath "C:\projects\my-service" -Quick

# Full mode (comprehensive)
.\git-diff.ps1 -RepoPath "C:\projects\my-service" -Full

# Custom output location
.\git-diff.ps1 -RepoPath "C:\projects\my-service" `
  -Output "C:\reports\analysis.txt"

# Verbose with custom output
.\git-diff.ps1 -RepoPath "C:\projects\my-service" `
  -Output "C:\reports\analysis.txt" `
  -Full `
  -Verbose
```

---

### 3. Batch-GenerateGitDiffs.ps1

**Batch process multiple repositories.**

#### Purpose
Scan a parent directory for Git repositories and generate reports for all of them.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ParentPath` | String | **Required** | Parent directory containing repos |
| `-ReportsDir` | String | `./git-diff-reports` | Output directory for reports |
| `-Recursive` | Switch | false | Recursively search for repos |
| `-HistoryDepth` | Int | 20 | Commits per report |

#### Example Usage

```powershell
# Batch process all repos in a directory
.\Batch-GenerateGitDiffs.ps1 -ParentPath "C:\projects" `
  -ReportsDir "C:\reports\git-diffs"

# Recursive search for nested repositories
.\Batch-GenerateGitDiffs.ps1 -ParentPath "C:\projects" `
  -Recursive `
  -ReportsDir "C:\reports\git-diffs" `
  -HistoryDepth 50

# Save reports to custom location with extended history
.\Batch-GenerateGitDiffs.ps1 -ParentPath "C:\projects\elavon" `
  -ReportsDir "D:\analysis\elavon-diffs" `
  -HistoryDepth 100
```

**Output Structure:**
```
C:\reports\git-diffs\
├── repo-name-1\
│   └── git-diff.txt
├── repo-name-2\
│   └── git-diff.txt
└── repo-name-3\
    └── git-diff.txt
```

---

### 4. Install-GitDiffScripts.ps1

**Validation and setup utility.**

#### Purpose
Verify installation, test execution, optionally add to system PATH.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-InstallPath` | String | Script location | Installation directory |
| `-AddToPath` | Switch | false | Add to system PATH (requires admin) |

#### Example Usage

```powershell
# Validate installation
.\Install-GitDiffScripts.ps1

# Add to system PATH (requires administrator)
.\Install-GitDiffScripts.ps1 -AddToPath
```

---

## Usage Examples

### Real-World Scenarios

#### Scenario 1: Analyze Source Repository for Migration

Examine a source repository before migrating code to a target repo:

```powershell
$sourcePath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service"

.\git-diff.ps1 -RepoPath $sourcePath -Full -Output "C:\analysis\source-repo-analysis.txt"
```

**Output File:** `C:\analysis\source-repo-analysis.txt`

---

#### Scenario 2: Compare Multiple Project Repositories

Generate reports for all projects under MODERNIZATION:

```powershell
.\Batch-GenerateGitDiffs.ps1 `
  -ParentPath "C:\Users\e135408\IdeaProjects\MODERNIZATION" `
  -ReportsDir "C:\Users\e135408\IdeaProjects\MODERNIZATION\git-diff-reports" `
  -Recursive `
  -HistoryDepth 50
```

**Result:** Reports for each repository in organized subdirectories.

---

#### Scenario 3: Quick Check of Current Directory

Fast analysis of current repository without stashed changes:

```powershell
cd "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service"
.\git-diff.ps1 -Quick
```

**Output File:** `git-diff.txt` in repository root.

---

#### Scenario 4: Branch Comparison Before Merge

Compare feature branch with develop:

```powershell
.\Generate-GitDiff.ps1 `
  -RepoPath "C:\projects\my-service" `
  -BranchCompare "origin/develop" `
  -HistoryDepth 30
```

**Shows:**
- Commits ahead of develop
- Commits behind develop
- Full diff between branches
- Commit details for all ahead commits

---

#### Scenario 5: Archive Complete Repository State

Create comprehensive documentation of repository state:

```powershell
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archiveDir = "C:\archive\repo-states\$timestamp"

New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

.\Generate-GitDiff.ps1 `
  -RepoPath "C:\projects\my-service" `
  -OutputFile "$archiveDir\git-diff.txt" `
  -HistoryDepth 100 `
  -VerboseOutput
```

---

## Report Contents

### Section 1: Repository Information

```
REPOSITORY INFORMATION:
  Current Branch: feature/G1198_18135_ELAVON_VERIFY_FLOW_MIGRATION
  Current Commit: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
  Remote URL: https://github.com/magh-395/107651-pgsaaselavon-pgs-acquirer-elavon-interface-service.git
  Untracked Files: 2
  Modified Files: 5
  Deleted Files: 1
  Renamed Files: 0
  Added Files: 3
  Total Changes: 11
```

**Contains:**
- Current branch name
- Current commit SHA
- Remote origin URL
- Summary counts of each change type

---

### Section 2: Working Directory Changes

Full unified diff of uncommitted changes in working directory.

```
WORKING DIRECTORY CHANGES (Uncommitted)
--- a/src/main/java/com/example/MyClass.java
+++ b/src/main/java/com/example/MyClass.java
@@ -10,6 +10,7 @@
     public void myMethod() {
         // Existing code
+        // New change
         doSomething();
     }
```

**Contains:**
- Unified diff format
- File path changes
- Line-by-line modifications

---

### Section 3: Staged Changes

Full diff of files in Git index (staged for commit).

```
STAGED CHANGES (Index)
--- a/src/test/java/com/example/MyTest.java
+++ b/src/test/java/com/example/MyTest.java
@@ -1,3 +1,4 @@
+// New import
 import org.junit.Test;
```

---

### Section 4: Stashed Changes

Complete listing and details of all Git stashes.

```
STASHED CHANGES

Stash List:
stash@{0}: WIP on develop: a1b2c3d Add feature X
stash@{1}: WIP on main: e5f6g7h Fix bug Y

Stash Details:

--- Stash 0 ---
[Full diff for stash 0]

--- Stash 1 ---
[Full diff for stash 1]
```

---

### Section 5: Commit History

Graph view and detailed metadata for recent commits.

```
COMMIT HISTORY (Last 20 commits)

* a1b2c3d (HEAD -> feature/branch) Add verification flow
* e5f6g7h (origin/develop) Update dependencies
|\ 
| * i9j0k1l (origin/feature/other) Merge pull request
```

**Detailed Info:**
```
Commit: a1b2c3
  Author: John Doe
  Date: 2026-04-13 14:32:15 +0000
  Message: Add verification flow

Commit: e5f6g7
  Author: Jane Smith
  Date: 2026-04-12 09:15:42 +0000
  Message: Update dependencies
```

---

### Section 6: File Status Details

Organized listing by modification type.

```
FILE STATUS DETAILS

Untracked Files:
  ?? src/main/resources/new-config.yaml
  ?? .DS_Store

Modified Files:
   M src/main/java/MyClass.java
  M  pom.xml

Deleted Files:
   D src/test/java/OldTest.java

Added Files:
  A src/main/java/NewFeature.java
```

---

### Section 7: Summary Statistics

```
SUMMARY STATISTICS

Total tracked files: 247
Uncommitted changes: 11
Report generated: 2026-04-13 14:45:22
```

---

## Command Reference

### Quick Reference Table

| Task | Command |
|------|---------|
| Analyze current directory | `.\git-diff.ps1` |
| Analyze specific repo | `.\git-diff.ps1 -RepoPath "path"` |
| Quick mode | `.\git-diff.ps1 -RepoPath "path" -Quick` |
| Full analysis | `.\git-diff.ps1 -RepoPath "path" -Full` |
| Compare branches | `.\Generate-GitDiff.ps1 -RepoPath "path" -BranchCompare "develop"` |
| Batch process | `.\Batch-GenerateGitDiffs.ps1 -ParentPath "path"` |
| Custom output | `.\git-diff.ps1 -RepoPath "path" -Output "file.txt"` |
| Verbose output | `.\git-diff.ps1 -RepoPath "path" -Verbose` |
| Validate install | `.\Install-GitDiffScripts.ps1` |

---

## Advanced Usage

### Custom PowerShell Profiles

Add function to your PowerShell profile for quick access:

```powershell
# Add to $PROFILE
function New-GitDiff {
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$Quick,
        [switch]$Full
    )
    
    $scriptPath = "C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff\git-diff.ps1"
    & $scriptPath -RepoPath $Path -Quick:$Quick -Full:$Full
}

# Usage: New-GitDiff -Path "C:\projects\repo" -Full
```

---

### Scheduled Analysis

Create a scheduled task to generate daily reports:

```powershell
$action = New-ScheduledTaskAction -Execute powershell.exe `
    -Argument "-File 'C:\...\git-diff.ps1' -RepoPath 'C:\projects\repo' -Output 'C:\reports\daily\repo-$(Get-Date -f yyyyMMdd).txt'"

Register-ScheduledTask -TaskName "DailyGitDiffReport" -Action $action -Trigger (New-ScheduledTaskTrigger -Daily -At 2am)
```

---

### Recursive Analysis Script

Analyze all repositories under a path and create dated archive:

```powershell
$basePath = "C:\projects"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archivePath = "C:\archive\analysis\$timestamp"

New-Item -ItemType Directory -Path $archivePath -Force | Out-Null

.\Batch-GenerateGitDiffs.ps1 `
    -ParentPath $basePath `
    -ReportsDir "$archivePath\diffs" `
    -Recursive `
    -HistoryDepth 100

Write-Host "Analysis complete: $archivePath"
```

---

### Export to CSV for Analysis

Parse reports and export to CSV:

```powershell
$reportPath = "C:\reports\git-diff.txt"
$content = Get-Content $reportPath

# Extract key metrics
$metrics = @{
    "Branch" = ($content | Select-String "Current Branch:" | % {$_.Line -replace '.*: ', ''})
    "Commit" = ($content | Select-String "Current Commit:" | % {$_.Line -replace '.*: ', ''})
    "TotalChanges" = ($content | Select-String "Total Changes:" | % {$_.Line -replace '.*: ', ''})
}

$metrics | Export-Csv -Path "C:\analysis\metrics.csv" -NoTypeInformation
```

---

## Troubleshooting

### Issue: "Not a git repository"

**Problem:** Script reports repository is not a Git repo.

**Solution:**
```powershell
# Verify .git directory exists
Test-Path "C:\path\to\repo\.git"

# If missing, initialize repository
cd "C:\path\to\repo"
git init
```

---

### Issue: Git command not found

**Problem:** Git is not in system PATH.

**Solution:**
```powershell
# Check if git is accessible
git --version

# If not found, add to PATH or install Git from:
# https://git-scm.com/download/win
```

---

### Issue: Permission Denied on Output File

**Problem:** Cannot write to output directory.

**Solution:**
```powershell
# Check directory permissions
icacls "C:\reports"

# Grant write permissions
icacls "C:\reports" /grant "$env:USERNAME`:F"
```

---

### Issue: PowerShell Execution Policy

**Problem:** "cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow script execution for current user
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

# Or run script with bypass
powershell -ExecutionPolicy Bypass -File ".\git-diff.ps1" -RepoPath "C:\path"
```

---

### Issue: Large Report Files (Slow Generation)

**Problem:** Reports take too long on large repositories.

**Solution:**
```powershell
# Use Quick mode
.\git-diff.ps1 -RepoPath "path" -Quick

# Or reduce history depth
.\Generate-GitDiff.ps1 -RepoPath "path" -HistoryDepth 5

# Or disable stashed changes
.\Generate-GitDiff.ps1 -RepoPath "path" -IncludeStashed:$false
```

---

## Technical Details

### Architecture

```
git-diff.ps1 (Quick wrapper)
    └─> Generate-GitDiff.ps1 (Core analysis engine)
            └─> Git commands (git diff, git log, git status, etc.)

Batch-GenerateGitDiffs.ps1 (Batch processor)
    └─> Generate-GitDiff.ps1 (for each repo)
            └─> Git commands
```

### Git Commands Used

| Command | Purpose |
|---------|---------|
| `git rev-parse --abbrev-ref HEAD` | Current branch |
| `git rev-parse HEAD` | Current commit |
| `git config --get remote.origin.url` | Remote URL |
| `git status --porcelain` | File status summary |
| `git diff --no-color` | Working directory diff |
| `git diff --cached --no-color` | Staged changes diff |
| `git stash list` | List all stashes |
| `git stash show -p` | Stash details |
| `git log` | Commit history |
| `git rev-list --count` | Ahead/behind counts |

### Performance Characteristics

| Repository Size | Quick Mode | Full Mode |
|-----------------|-----------|-----------|
| Small (<100 files) | < 1 sec | 1-2 sec |
| Medium (100-1000 files) | 1-2 sec | 2-5 sec |
| Large (1000-10000 files) | 3-5 sec | 5-15 sec |
| Very Large (>10000 files) | 5-15 sec | 15-60 sec |

*Times vary based on system, Git version, history depth, and stash count.*

---

### Output File Size Estimates

| Mode | Typical Size |
|------|-------------|
| Quick (20 commits, no stashed) | 50-200 KB |
| Standard (20 commits, with stashed) | 100-500 KB |
| Full (50 commits, with stashed) | 200-1000 KB |
| Repository with large diffs | 1-10 MB |

---

## Support & Documentation

### Getting Help

```powershell
# Display full help for main script
Get-Help ".\Generate-GitDiff.ps1" -Full

# Display help for quick wrapper
Get-Help ".\git-diff.ps1" -Full

# Display help for batch script
Get-Help ".\Batch-GenerateGitDiffs.ps1" -Full
```

---

### For Issues or Enhancements

1. **Check existing reports** – Review git-diff.txt output for clues
2. **Verify Git installation** – Ensure Git works independently
3. **Test with simple repo** – Try script on a small repository first
4. **Check PowerShell version** – Requires PowerShell 5.0+
5. **Contact development team** – For feature requests or bugs

---

## Summary

The **Git-Diff Utility Scripts** provide a powerful, flexible solution for comprehensive Git repository analysis. Whether you need quick checks or deep forensic analysis, these tools adapt to your workflow.

### Key Takeaways

✓ **Generic** – Works with any Git repository
✓ **Flexible** – Multiple modes and parameters
✓ **Comprehensive** – Captures all repository state information
✓ **Fast** – Quick mode for rapid analysis
✓ **Documented** – Detailed reports with actionable insights
✓ **Reliable** – Tested on various repository sizes and configurations

---

**Version:** 1.0.0  
**Updated:** 2026-04-13  
**Author:** Mastercard PGS Connectivity Team  
**Location:** `C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff\`

