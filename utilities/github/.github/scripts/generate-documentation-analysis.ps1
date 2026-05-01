# Documentation Generation Automation Script
# PowerShell script for Windows environments

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceBranch,

    [Parameter(Mandatory=$true)]
    [string]$TargetBranch,

    [Parameter(Mandatory=$true)]
    [string]$StoryId,

    [Parameter(Mandatory=$false)]
    [string]$StoryTitle = "Code Changes Analysis",

    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "."
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptVersion = "1.0"
$ScriptDate = Get-Date -Format "MMMM d, yyyy"

# Color output functions
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

# Banner
Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     CODE CHANGE DOCUMENTATION GENERATOR v$ScriptVersion           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Info "`nStarting documentation generation process..."
Write-Info "Source Branch: $SourceBranch"
Write-Info "Target Branch: $TargetBranch"
Write-Info "Story ID: $StoryId"
Write-Info "Date: $ScriptDate`n"

# Create output directory if it doesn't exist
$ArchiveDir = ".github/docs/archives/$StoryId"
if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    Write-Success "✓ Created archive directory: $ArchiveDir"
}

# Step 1: Verify Git Repository
Write-Info "`n[Step 1/10] Verifying Git repository..."
try {
    git status | Out-Null
    Write-Success "✓ Git repository verified"
} catch {
    Write-Error "✗ Not a git repository or git not installed"
    exit 1
}

# Step 2: Verify Branches Exist
Write-Info "`n[Step 2/10] Verifying branches..."
$allBranches = git branch -a | Out-String

if ($allBranches -notmatch $SourceBranch) {
    Write-Error "✗ Source branch '$SourceBranch' not found"
    exit 1
}
if ($allBranches -notmatch $TargetBranch) {
    Write-Error "✗ Target branch '$TargetBranch' not found"
    exit 1
}
Write-Success "✓ Both branches verified"

# Step 3: Update Branches
Write-Info "`n[Step 3/10] Updating branches..."
try {
    git fetch origin 2>&1 | Out-Null
    Write-Success "✓ Branches updated from remote"
} catch {
    Write-Warning "⚠ Could not fetch from remote (may be offline)"
}

# Step 4: Get Change Statistics
Write-Info "`n[Step 4/10] Analyzing changes..."
$shortstat = git diff "$SourceBranch..$TargetBranch" --shortstat | Out-String
Write-Info "Statistics: $shortstat"

# Parse statistics
$statsMatch = $shortstat -match '(\d+) files? changed(?:, (\d+) insertions?\(\+\))?(?:, (\d+) deletions?\(-\))?'
if ($statsMatch) {
    $filesChanged = [int]$Matches[1]
    $insertions = if ($Matches[2]) { [int]$Matches[2] } else { 0 }
    $deletions = if ($Matches[3]) { [int]$Matches[3] } else { 0 }

    Write-Success "✓ Files Changed: $filesChanged"
    Write-Success "✓ Insertions: $insertions"
    Write-Success "✓ Deletions: $deletions"
} else {
    Write-Warning "⚠ Could not parse statistics"
    $filesChanged = 0
    $insertions = 0
    $deletions = 0
}

# Step 5: Generate File Lists
Write-Info "`n[Step 5/10] Generating file lists..."

$filesListPath = Join-Path $ArchiveDir "changed_files.txt"
git diff "$SourceBranch..$TargetBranch" --name-status | Out-File -FilePath $filesListPath -Encoding UTF8
Write-Success "✓ Created: $filesListPath"

$newFilesPath = Join-Path $ArchiveDir "new_files.txt"
git diff "$SourceBranch..$TargetBranch" --name-status | Where-Object { $_ -match "^A\s" } | Out-File -FilePath $newFilesPath -Encoding UTF8
$newFilesCount = (Get-Content $newFilesPath | Measure-Object).Count
Write-Success "✓ New files: $newFilesCount"

$modifiedFilesPath = Join-Path $ArchiveDir "modified_files.txt"
git diff "$SourceBranch..$TargetBranch" --name-status | Where-Object { $_ -match "^M\s" } | Out-File -FilePath $modifiedFilesPath -Encoding UTF8
$modifiedFilesCount = (Get-Content $modifiedFilesPath | Measure-Object).Count
Write-Success "✓ Modified files: $modifiedFilesCount"

$deletedFilesPath = Join-Path $ArchiveDir "deleted_files.txt"
git diff "$SourceBranch..$TargetBranch" --name-status | Where-Object { $_ -match "^D\s" } | Out-File -FilePath $deletedFilesPath -Encoding UTF8
$deletedFilesCount = (Get-Content $deletedFilesPath | Measure-Object).Count
Write-Success "✓ Deleted files: $deletedFilesCount"

# Step 6: Generate Commit History
Write-Info "`n[Step 6/10] Extracting commit history..."

$commitsPath = Join-Path $ArchiveDir "commit_history.txt"
git log "$SourceBranch..$TargetBranch" --oneline --no-merges | Out-File -FilePath $commitsPath -Encoding UTF8
$commitCount = (Get-Content $commitsPath | Measure-Object).Count
Write-Success "✓ Commits captured: $commitCount"

$commitDetailsPath = Join-Path $ArchiveDir "commit_details.txt"
git log "$SourceBranch..$TargetBranch" --pretty=format:"%h - %an, %ar : %s" --no-merges | Out-File -FilePath $commitDetailsPath -Encoding UTF8
Write-Success "✓ Detailed commit info saved"

# Step 7: Analyze Dependencies
Write-Info "`n[Step 7/10] Analyzing dependencies..."

$dependenciesPath = Join-Path $ArchiveDir "dependency_changes.txt"
"=== POM.XML CHANGES ===" | Out-File -FilePath $dependenciesPath -Encoding UTF8
git diff "$SourceBranch..$TargetBranch" -- "pom.xml" 2>&1 | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8

"=== BUILD.GRADLE CHANGES ===" | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8
git diff "$SourceBranch..$TargetBranch" -- "build.gradle" 2>&1 | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8

"=== PACKAGE.JSON CHANGES ===" | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8
git diff "$SourceBranch..$TargetBranch" -- "package.json" 2>&1 | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8

Write-Success "✓ Dependency analysis saved"

# Step 8: Generate Summary Report
Write-Info "`n[Step 8/10] Generating summary report..."

$summaryPath = Join-Path $ArchiveDir "ANALYSIS_SUMMARY.txt"

@"
CODE CHANGE ANALYSIS SUMMARY
Generated: $ScriptDate

STORY INFORMATION
-----------------
Story ID: $StoryId
Story Title: $StoryTitle
Source Branch: $SourceBranch
Target Branch: $TargetBranch

STATISTICS
----------
Total Files Changed: $filesChanged
New Files: $newFilesCount
Modified Files: $modifiedFilesCount
Deleted Files: $deletedFilesCount
Total Commits: $commitCount
Lines Inserted: $insertions
Lines Deleted: $deletions

IMPACT ASSESSMENT
-----------------
Change Size: $(if ($filesChanged -lt 10) { "Small" } elseif ($filesChanged -lt 50) { "Medium" } else { "Large" })
Scope: $(if ($modifiedFilesCount -gt $newFilesCount) { "Refactoring/Enhancement" } else { "New Feature" })

FILES GENERATED
---------------
1. changed_files.txt - Complete file list with status
2. new_files.txt - New files only
3. modified_files.txt - Modified files only
4. deleted_files.txt - Deleted files only
5. commit_history.txt - Commit log
6. commit_details.txt - Detailed commit info
7. dependency_changes.txt - Dependency analysis
8. ANALYSIS_SUMMARY.txt - This summary

NEXT STEPS
----------
1. Review generated files in: $ArchiveDir
2. Use GitHub Copilot to generate full documentation:
   - Open Copilot Chat
   - Reference: .github/COPILOT_INSTRUCTIONS.md
   - Provide: Story ID, branch names, files from archive
3. Follow checklist in: .github/DOCUMENTATION_CHECKLIST.md
4. Review guide at: .github/DOCUMENTATION_GUIDE.md

DOCUMENTATION COMMAND
---------------------
Request Copilot:
"Generate comprehensive Confluence documentation for story $StoryId
comparing branches $SourceBranch and $TargetBranch.
Use the analysis files in $ArchiveDir."

"@ | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Success "✓ Summary report created: $summaryPath"

# Step 9: Generate README for Archive
Write-Info "`n[Step 9/10] Creating archive README..."

$readmePath = Join-Path $ArchiveDir "README.md"

@"
# Analysis Files for Story $StoryId

## Overview
This directory contains automated analysis files for code changes between:
- **Source Branch:** ``$SourceBranch``
- **Target Branch:** ``$TargetBranch``

## Generated Files

| File | Description | Purpose |
|------|-------------|---------|
| ``changed_files.txt`` | All files with change status | Complete change inventory |
| ``new_files.txt`` | New files (Added) | Track new additions |
| ``modified_files.txt`` | Modified files | Track modifications |
| ``deleted_files.txt`` | Deleted files | Track deletions |
| ``commit_history.txt`` | Commit log (one-line) | Quick commit overview |
| ``commit_details.txt`` | Detailed commit info | Full commit context |
| ``dependency_changes.txt`` | Build file changes | Dependency tracking |
| ``ANALYSIS_SUMMARY.txt`` | Analysis summary | Quick reference |

## Statistics

- **Files Changed:** $filesChanged
- **New Files:** $newFilesCount
- **Modified Files:** $modifiedFilesCount
- **Deleted Files:** $deletedFilesCount
- **Commits:** $commitCount
- **Lines Added:** $insertions
- **Lines Removed:** $deletions

## Usage

These files are input for the documentation generation process. Use them with:

1. **GitHub Copilot:** Reference these files when requesting documentation
2. **Manual Review:** Review changes systematically
3. **PR Description:** Summarize changes for pull request

## Generated By

- **Script:** generate-documentation.ps1 v$ScriptVersion
- **Date:** $ScriptDate
- **User:** $env:USERNAME

## Related Documentation

- Full documentation: ``${StoryId}_ANALYSIS_CONFLUENCE_DOC.md`` (once generated)
- Checklist: ``.github/DOCUMENTATION_CHECKLIST.md``
- Guide: ``.github/DOCUMENTATION_GUIDE.md``
- Instructions: ``.github/COPILOT_INSTRUCTIONS.md``

---

*This directory and its contents are for internal use and should not be committed to the repository.*
"@ | Out-File -FilePath $readmePath -Encoding UTF8

Write-Success "✓ Archive README created"

# Step 10: Display Completion Summary
Write-Info "`n[Step 10/10] Process complete!"

Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                    ANALYSIS COMPLETE                         ║
╚══════════════════════════════════════════════════════════════╝

SUMMARY OF CHANGES:
-------------------
📁 Files Changed:     $filesChanged
📝 New Files:         $newFilesCount
✏️  Modified Files:    $modifiedFilesCount
🗑️  Deleted Files:     $deletedFilesCount
📦 Commits:           $commitCount
➕ Lines Added:       $insertions
➖ Lines Removed:     $deletions

FILES LOCATION:
---------------
All analysis files saved to: $ArchiveDir

NEXT STEPS:
-----------
1. ✅ Review the ANALYSIS_SUMMARY.txt file
2. ✅ Use GitHub Copilot to generate full documentation:

   Open Copilot Chat and say:
   "Generate comprehensive Confluence documentation for story $StoryId
   comparing branches $SourceBranch and $TargetBranch.
   Use analysis files in $ArchiveDir.
   Follow template from .github/COPILOT_INSTRUCTIONS.md"

3. ✅ Follow the checklist: .github/DOCUMENTATION_CHECKLIST.md
4. ✅ Review the guide: .github/DOCUMENTATION_GUIDE.md

QUICK COMMANDS:
---------------
# View summary
cat $summaryPath

# View changed files
cat $filesListPath

# View commits
cat $commitsPath

# Open archive directory
cd $ArchiveDir

DOCUMENTATION FILE:
-------------------
Expected output: ${StoryId}_ANALYSIS_CONFLUENCE_DOC.md

"@ -ForegroundColor Green

Write-Success "`n✓ Documentation generation preparation complete!`n"

# Return success
exit 0

