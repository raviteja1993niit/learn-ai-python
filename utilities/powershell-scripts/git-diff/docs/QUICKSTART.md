# Git-Diff Scripts - Quick Start Guide

**Installation Location:** `C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff\`

---

## Files Created

✓ **Generate-GitDiff.ps1** – Core analysis engine (comprehensive, all features)
✓ **git-diff.ps1** – Quick wrapper (simplified, sensible defaults)
✓ **Batch-GenerateGitDiffs.ps1** – Batch processor (multiple repos)
✓ **Install-GitDiffScripts.ps1** – Setup and validation utility
✓ **README.md** – Complete documentation (this detailed guide)
✓ **QUICKSTART.md** – This file (quick reference)

---

## 5-Second Setup

```powershell
cd "C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

---

## 3 Most Common Commands

### 1. Analyze Current Directory
```powershell
.\git-diff.ps1
```
Output: `git-diff.txt` in current repo root

---

### 2. Analyze Specific Repository
```powershell
.\git-diff.ps1 -RepoPath "C:\path\to\repo"
```
Output: `C:\path\to\repo\git-diff.txt`

---

### 3. Batch Process Multiple Repos
```powershell
.\Batch-GenerateGitDiffs.ps1 -ParentPath "C:\projects"
```
Output: Reports in `.\git-diff-reports\repo-name\git-diff.txt`

---

## Mode Comparison

| Mode | Command | Speed | Detail | Best For |
|------|---------|-------|--------|----------|
| **Quick** | `.\git-diff.ps1 -Quick` | ⚡ Fast | Basic | Fast checks |
| **Standard** | `.\git-diff.ps1` | ⚡⚡ Normal | Detailed | Daily use |
| **Full** | `.\git-diff.ps1 -Full` | ⚡⚡⚡ Slow | Comprehensive | Deep analysis |

---

## Real-World Examples

### Example 1: Elavon Service Repository Analysis

Analyze the Elavon service repository for migration planning:

```powershell
$sourcePath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\temp\107651-pgsaaselavon-pgs-acquirer-elavon-interface-service"

.\git-diff.ps1 -RepoPath $sourcePath -Full -Verbose
```

**Output:** `git-diff.txt` at repo root with:
- All uncommitted changes
- All stashed changes
- 50-commit history
- Complete file status
- Branch information

---

### Example 2: Multiple Repository Analysis

Analyze all MODERNIZATION repositories:

```powershell
$reportsPath = "C:\Users\e135408\IdeaProjects\MODERNIZATION\git-diff-reports"

.\Batch-GenerateGitDiffs.ps1 `
  -ParentPath "C:\Users\e135408\IdeaProjects\MODERNIZATION" `
  -ReportsDir $reportsPath `
  -Recursive
```

**Output:** Organized reports for each repository:
```
C:\Users\e135408\IdeaProjects\MODERNIZATION\git-diff-reports\
├── 107651-pgsaaselavon-pgs-acquirer-elavon-interface-service\
│   └── git-diff.txt
├── 107651-pgsaaselavon-pgs-acquirer-elavon-interface-service-test\
│   └── git-diff.txt
└── [other repos]\
    └── git-diff.txt
```

---

### Example 3: Branch Comparison

Compare feature branch with develop:

```powershell
.\Generate-GitDiff.ps1 `
  -RepoPath "C:\path\to\repo" `
  -BranchCompare "origin/develop" `
  -HistoryDepth 50
```

**Shows:**
- ✓ Commits ahead of develop
- ✓ Commits behind develop
- ✓ Complete diff between branches
- ✓ Detailed commit info

---

## Report Contents Quick Reference

Generated `git-diff.txt` includes:

1. **Repository Info** – Branch, commit, remote URL
2. **Status Summary** – Untracked, modified, deleted, added counts
3. **Working Changes** – Uncommitted diffs
4. **Staged Changes** – Files in Git index
5. **Stashed Changes** – All stashes with full diffs
6. **Commit History** – Graph and detailed metadata
7. **File Details** – Organized by modification type
8. **Statistics** – Total files and change metrics

---

## Parameter Quick Reference

### Most Used Parameters

```powershell
# Path to repository
-RepoPath "C:\path\to\repo"

# Custom output file
-Output "C:\reports\custom-name.txt"
-OutputFile "C:\reports\custom-name.txt"

# Number of commits to include
-HistoryDepth 50              # Default: 20

# Compare with another branch
-BranchCompare "origin/develop"

# Modes
-Quick                        # Fastest (skip stashed, history)
-Full                         # Comprehensive (50 commits)

# Display options
-Verbose                      # Print to console while running
-VerboseOutput
```

---

## Troubleshooting

### "Not a git repository"
```powershell
# Verify repository path contains .git directory
Test-Path "C:\path\to\repo\.git"
```

### "Git command not found"
```powershell
# Check git installation
git --version

# Add to PATH if needed
# https://git-scm.com/download/win
```

### "Running scripts is disabled"
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

### "Permission denied" (output file)
```powershell
# Check and fix permissions
icacls "C:\reports" /grant "$env:USERNAME`:F"
```

---

## Advanced Tips

### Alias for Quick Access

Add to PowerShell profile (`$PROFILE`):

```powershell
Set-Alias gitdiff "C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff\git-diff.ps1"

# Usage: gitdiff -RepoPath "C:\path"
```

### Timestamp-Based Reporting

Create dated reports:

```powershell
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outFile = "C:\reports\repo-diff_$timestamp.txt"

.\git-diff.ps1 -RepoPath "C:\path\to\repo" -Output $outFile
```

### Analyze and Open Report

```powershell
$outFile = "C:\reports\analysis.txt"

.\git-diff.ps1 -RepoPath "C:\path\to\repo" -Output $outFile
notepad $outFile   # Open in Notepad
# or
code $outFile      # Open in VS Code
```

---

## Performance Guidelines

| Repository | Recommended Mode |
|------------|-----------------|
| Small (<100 files) | Any mode |
| Medium (100-1000) | Standard or Quick |
| Large (1000-10000) | Quick mode |
| Very Large (>10000) | Quick, limit commits |

For slow repos, use:
```powershell
.\git-diff.ps1 -RepoPath "C:\path" -Quick -Output "results.txt"
```

---

## Next Steps

1. **Read Full Documentation:** Open `README.md` for complete reference
2. **Try First Example:** Analyze current directory with `.\git-diff.ps1`
3. **Explore Options:** Run `Get-Help .\git-diff.ps1 -Full`
4. **Batch Process:** Use `Batch-GenerateGitDiffs.ps1` for multiple repos
5. **Customize:** Add to PowerShell profile for quick access

---

## Common Use Cases

### ✓ Code Migration Planning
```powershell
.\git-diff.ps1 -RepoPath "C:\source-repo" -Full
```

### ✓ Pre-Commit Audit
```powershell
.\git-diff.ps1 -RepoPath "C:\repo" -Quick
```

### ✓ Repository State Documentation
```powershell
.\Generate-GitDiff.ps1 -RepoPath "C:\repo" -HistoryDepth 100
```

### ✓ Branch Comparison
```powershell
.\Generate-GitDiff.ps1 -RepoPath "C:\repo" -BranchCompare "origin/develop"
```

### ✓ Archive Multiple Repos
```powershell
.\Batch-GenerateGitDiffs.ps1 -ParentPath "C:\projects" -ReportsDir "C:\archive"
```

---

## Support

**Documentation:** See `README.md` for detailed reference
**Help:** Run `Get-Help .\script-name.ps1 -Full`
**Issues:** Verify git installation and PowerShell version

---

**Location:** `C:\Users\e135408\IdeaProjects\utility-scripts\powershell-scripts\git-diff\`  
**Version:** 1.0.0  
**Updated:** 2026-04-13

