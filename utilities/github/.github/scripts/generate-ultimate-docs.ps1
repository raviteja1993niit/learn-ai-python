# Ultimate PR Documentation Generator with Diagram Support
# PowerShell Script v2.0 - Enhanced with LLD/HLD Diagram Generation

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
    [switch]$GenerateDiagrams = $true,

    [Parameter(Mandatory=$false)]
    [string]$DiagramFormat = "mermaid",  # mermaid, plantuml, both

    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"
$ScriptVersion = "2.0"
$ScriptDate = Get-Date -Format "MMMM d, yyyy"

# Color functions
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Diagram { Write-Host $args -ForegroundColor Magenta }

# Banner
Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  🤖 ULTIMATE AI PR DOCUMENTATION GENERATOR v$ScriptVersion          ║
║     With LLD/HLD Diagram Support                                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Info "`n🚀 Starting ultimate documentation generation..."
Write-Info "📊 Source Branch: $SourceBranch"
Write-Info "📊 Target Branch: $TargetBranch"
Write-Info "🎫 Story ID: $StoryId"
Write-Info "🎨 Generate Diagrams: $GenerateDiagrams"
Write-Info "📐 Diagram Format: $DiagramFormat"
Write-Info "📅 Date: $ScriptDate`n"

# Create directories
$ArchiveDir = ".github/docs/archives/$StoryId"
$DiagramDir = "$ArchiveDir/diagrams"

if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    Write-Success "✓ Created archive directory"
}

if ($GenerateDiagrams -and -not (Test-Path $DiagramDir)) {
    New-Item -ItemType Directory -Path $DiagramDir -Force | Out-Null
    Write-Diagram "✓ Created diagram directory"
}

# Step 1: Git Repository Verification
Write-Info "`n[Step 1/15] 🔍 Verifying Git repository..."
try {
    git status | Out-Null
    Write-Success "✓ Git repository verified"
} catch {
    Write-Error "✗ Not a git repository"
    exit 1
}

# Step 2: Branch Verification
Write-Info "`n[Step 2/15] 🌿 Verifying branches..."
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
Write-Info "`n[Step 3/15] 🔄 Updating branches..."
try {
    git fetch origin 2>&1 | Out-Null
    Write-Success "✓ Branches updated"
} catch {
    Write-Warning "⚠ Could not fetch (may be offline)"
}

# Step 4: Change Statistics
Write-Info "`n[Step 4/15] 📊 Analyzing changes..."
$shortstat = git diff "$SourceBranch..$TargetBranch" --shortstat | Out-String
$statsMatch = $shortstat -match '(\d+) files? changed(?:, (\d+) insertions?\(\+\))?(?:, (\d+) deletions?\(-\))?'
if ($statsMatch) {
    $filesChanged = [int]$Matches[1]
    $insertions = if ($Matches[2]) { [int]$Matches[2] } else { 0 }
    $deletions = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
    Write-Success "✓ Files: $filesChanged | Insertions: $insertions | Deletions: $deletions"
} else {
    $filesChanged = 0; $insertions = 0; $deletions = 0
}

# Step 5: File Lists
Write-Info "`n[Step 5/15] 📝 Generating file lists..."
$filesListPath = Join-Path $ArchiveDir "changed_files.txt"
git diff "$SourceBranch..$TargetBranch" --name-status | Out-File -FilePath $filesListPath -Encoding UTF8

$newFilesPath = Join-Path $ArchiveDir "new_files.txt"
git diff "$SourceBranch..$TargetBranch" --name-status | Where-Object { $_ -match "^A\s" } | Out-File -FilePath $newFilesPath -Encoding UTF8
$newFilesCount = (Get-Content $newFilesPath -ErrorAction SilentlyContinue | Measure-Object).Count

$modifiedFilesPath = Join-Path $ArchiveDir "modified_files.txt"
git diff "$SourceBranch..$TargetBranch" --name-status | Where-Object { $_ -match "^M\s" } | Out-File -FilePath $modifiedFilesPath -Encoding UTF8
$modifiedFilesCount = (Get-Content $modifiedFilesPath -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Success "✓ New: $newFilesCount | Modified: $modifiedFilesCount"

# Step 6: Commit History
Write-Info "`n[Step 6/15] 📜 Extracting commit history..."
$commitsPath = Join-Path $ArchiveDir "commit_history.txt"
git log "$SourceBranch..$TargetBranch" --oneline --no-merges | Out-File -FilePath $commitsPath -Encoding UTF8
$commitCount = (Get-Content $commitsPath -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Success "✓ Commits: $commitCount"

# Step 7: Language Detection
Write-Info "`n[Step 7/15] 🔤 Detecting programming languages..."
$allFiles = git diff "$SourceBranch..$TargetBranch" --name-only
$languages = @{}
foreach ($file in $allFiles) {
    $ext = [System.IO.Path]::GetExtension($file)
    if ($ext) {
        if (-not $languages.ContainsKey($ext)) {
            $languages[$ext] = 0
        }
        $languages[$ext]++
    }
}
$languagesPath = Join-Path $ArchiveDir "languages_detected.txt"
$languages.GetEnumerator() | Sort-Object -Property Value -Descending | Out-File -FilePath $languagesPath -Encoding UTF8
Write-Success "✓ Languages detected: $($languages.Count)"

# Step 8: Identify Key Classes
Write-Info "`n[Step 8/15] 🎯 Identifying key classes for diagrams..."
$keyClasses = @()
$changedFiles = git diff "$SourceBranch..$TargetBranch" --name-status
foreach ($line in $changedFiles) {
    if ($line -match '\.(java|py|js|ts|cs|go|kt)$') {
        $parts = $line -split '\s+'
        if ($parts.Length -ge 2) {
            $file = $parts[1]
            $stat = git diff "$SourceBranch..$TargetBranch" --numstat -- $file
            if ($stat) {
                $statParts = $stat -split '\s+'
                $added = if ($statParts[0] -match '^\d+$') { [int]$statParts[0] } else { 0 }
                $removed = if ($statParts[1] -match '^\d+$') { [int]$statParts[1] } else { 0 }
                $total = $added + $removed

                if ($total -gt 50 -or $parts[0] -eq 'A') {  # New files or significant changes
                    $keyClasses += [PSCustomObject]@{
                        File = $file
                        Status = $parts[0]
                        Changes = $total
                        Added = $added
                        Removed = $removed
                    }
                }
            }
        }
    }
}
$keyClasses = $keyClasses | Sort-Object -Property Changes -Descending | Select-Object -First 15
$keyClassesPath = Join-Path $ArchiveDir "key_classes.txt"
$keyClasses | Format-Table -AutoSize | Out-File -FilePath $keyClassesPath -Encoding UTF8
Write-Success "✓ Key classes identified: $($keyClasses.Count)"

# Step 9: Architecture Analysis
Write-Info "`n[Step 9/15] 🏗️ Analyzing architecture..."
$architecturePath = Join-Path $ArchiveDir "architecture_analysis.txt"
$architectureInfo = @"
ARCHITECTURE ANALYSIS
=====================
Generated: $ScriptDate

CHANGE SCOPE:
- Total Files: $filesChanged
- New Files: $newFilesCount
- Modified Files: $modifiedFilesCount
- Scope Assessment: $(if ($filesChanged -lt 10) { "Small - Bug Fix/Minor Enhancement" } elseif ($filesChanged -lt 30) { "Medium - Feature Addition" } else { "Large - Major Feature/Refactoring" })

KEY MODULES AFFECTED:
"@

$modules = @{}
foreach ($file in $allFiles) {
    $parts = $file -split '/'
    if ($parts.Length -gt 1) {
        $module = $parts[0]
        if (-not $modules.ContainsKey($module)) {
            $modules[$module] = 0
        }
        $modules[$module]++
    }
}
foreach ($module in ($modules.GetEnumerator() | Sort-Object -Property Value -Descending)) {
    $architectureInfo += "`n- $($module.Key): $($module.Value) files"
}

$architectureInfo | Out-File -FilePath $architecturePath -Encoding UTF8
Write-Success "✓ Architecture analyzed"

# Step 10: Generate Mermaid Diagrams
if ($GenerateDiagrams -and ($DiagramFormat -eq "mermaid" -or $DiagramFormat -eq "both")) {
    Write-Diagram "`n[Step 10/15] 🎨 Generating Mermaid diagrams..."

    # Component Diagram Template
    $componentDiagram = @"
``````mermaid
graph TB
    subgraph "Changed Components"
"@
    $componentIndex = 0
    foreach ($module in ($modules.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5)) {
        $componentDiagram += "`n        M$componentIndex[$($module.Key)]"
        $componentIndex++
    }
    $componentDiagram += "`n    end"
    $componentDiagram += "`n    style M0 fill:#f9f,stroke:#333,stroke-width:4px"
    $componentDiagram += "`n``````"

    $componentDiagramPath = Join-Path $DiagramDir "component_diagram.md"
    $componentDiagram | Out-File -FilePath $componentDiagramPath -Encoding UTF8

    # Class Diagram Template for Top Classes
    $classDiagram = @"
``````mermaid
classDiagram
"@
    foreach ($class in ($keyClasses | Select-Object -First 5)) {
        $className = [System.IO.Path]::GetFileNameWithoutExtension($class.File)
        $classDiagram += "`n    class $className {"
        $classDiagram += "`n        +$(if ($class.Status -eq 'A') { 'NEW' } else { 'MODIFIED' })"
        $classDiagram += "`n        +Changes: $($class.Changes) lines"
        $classDiagram += "`n    }"
    }
    $classDiagram += "`n``````"

    $classDiagramPath = Join-Path $DiagramDir "class_diagram_template.md"
    $classDiagram | Out-File -FilePath $classDiagramPath -Encoding UTF8

    Write-Diagram "✓ Mermaid diagram templates generated"
}

# Step 11: Generate AI Prompt
Write-Info "`n[Step 11/15] 🤖 Generating AI documentation prompt..."
$promptPath = Join-Path $ArchiveDir "AI_PROMPT.txt"
$prompt = @"
🤖 AI DOCUMENTATION GENERATION PROMPT
======================================

Generate comprehensive PR documentation with LLD/HLD diagrams for:

STORY INFORMATION:
- Story ID: $StoryId
- Story Title: $StoryTitle
- Source Branch: $SourceBranch
- Target Branch: $TargetBranch
- Date: $ScriptDate

CHANGE STATISTICS:
- Files Changed: $filesChanged
- Insertions: $insertions
- Deletions: $deletions
- New Files: $newFilesCount
- Modified Files: $modifiedFilesCount
- Commits: $commitCount

KEY CLASSES TO DOCUMENT (Top 10):
$($keyClasses | Select-Object -First 10 | ForEach-Object { "- $($_.File) ($($_.Changes) lines changed)" } | Out-String)

LANGUAGES DETECTED:
$($languages.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object { "- $($_.Key): $($_.Value) files" } | Out-String)

MODULES AFFECTED:
$($modules.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object { "- $($_.Key): $($_.Value) files" } | Out-String)

REQUIRED DIAGRAMS:

HIGH-LEVEL DESIGN (HLD):
1. System Context Diagram (Mermaid) - Show external systems and integrations
2. Component Architecture (Mermaid) - Show affected modules and their relationships
3. Data Flow Diagram (Mermaid) - Show how data moves through the system
4. Deployment Architecture (Mermaid) - If infrastructure changes

LOW-LEVEL DESIGN (LLD):
1. Class Diagrams (Mermaid) - For each of the top 10 key classes above
2. Sequence Diagrams (Mermaid) - For new/modified API endpoints or major flows
3. ER Diagram (Mermaid) - If database schema changes detected
4. State Machine (Mermaid) - For stateful entities if applicable

DOCUMENTATION REQUIREMENTS:
✅ Follow template: .github/DOCUMENTATION_TEMPLATE.md
✅ Follow guidelines: .github/AI_DOCUMENTATION_AGENT.md
✅ Include 10-15 code examples with explanations
✅ Embed all diagrams inline with collapsible Mermaid source
✅ Generate before/after diagrams for refactoring
✅ Annotate diagrams with design patterns
✅ Include universal language support for detected languages
✅ Add deployment and security diagrams
✅ Provide diagram quality checklist

OUTPUT FILE: ${StoryId}_ULTIMATE_ANALYSIS_CONFLUENCE_DOC.md

ANALYSIS FILES LOCATION: $ArchiveDir

USE THIS PROMPT WITH:
- GitHub Copilot
- ChatGPT
- Claude
- Any AI coding assistant

EXAMPLE USAGE IN COPILOT:
"@workspace Generate documentation using the prompt in $promptPath"
"@

$prompt | Out-File -FilePath $promptPath -Encoding UTF8
Write-Success "✓ AI prompt generated"

# Step 12: Dependencies Analysis
Write-Info "`n[Step 12/15] 📦 Analyzing dependencies..."
$dependenciesPath = Join-Path $ArchiveDir "dependency_changes.txt"
"=== DEPENDENCY ANALYSIS ===" | Out-File -FilePath $dependenciesPath -Encoding UTF8
"" | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8

$buildFiles = @("pom.xml", "build.gradle", "package.json", "requirements.txt", "go.mod", "Cargo.toml")
foreach ($file in $buildFiles) {
    $diff = git diff "$SourceBranch..$TargetBranch" -- $file 2>&1
    if ($LASTEXITCODE -eq 0 -and $diff) {
        "=== $file CHANGES ===" | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8
        $diff | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8
        "" | Out-File -FilePath $dependenciesPath -Append -Encoding UTF8
    }
}
Write-Success "✓ Dependencies analyzed"

# Step 13: Generate Summary
Write-Info "`n[Step 13/15] 📄 Generating summary report..."
$summaryPath = Join-Path $ArchiveDir "ULTIMATE_ANALYSIS_SUMMARY.txt"
@"
🤖 ULTIMATE PR DOCUMENTATION ANALYSIS SUMMARY
==============================================
Generated: $ScriptDate
Version: $ScriptVersion

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 STORY INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Story ID:          $StoryId
Story Title:       $StoryTitle
Source Branch:     $SourceBranch
Target Branch:     $TargetBranch

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 CHANGE STATISTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Files:       $filesChanged
New Files:         $newFilesCount
Modified Files:    $modifiedFilesCount
Lines Added:       $insertions
Lines Removed:     $deletions
Total Commits:     $commitCount

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 IMPACT ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Change Size:       $(if ($filesChanged -lt 10) { "🟢 Small (Bug Fix)" } elseif ($filesChanged -lt 30) { "🟡 Medium (Feature)" } else { "🔴 Large (Major Change)" })
Complexity:        $(if ($keyClasses.Count -gt 10) { "High" } elseif ($keyClasses.Count -gt 5) { "Medium" } else { "Low" })
Modules Affected:  $($modules.Count)
Languages:         $($languages.Count)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎨 DIAGRAM GENERATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status:            $(if ($GenerateDiagrams) { "✅ Enabled" } else { "⏸️ Disabled" })
Format:            $DiagramFormat
Templates:         $(if ($GenerateDiagrams) { "Generated in $DiagramDir" } else { "Not generated" })

Recommended Diagrams:
$(if ($filesChanged -gt 20) { "  ✓ System Context Diagram (HLD)" } else { "  - System Context (optional)" })
$(if ($modules.Count -gt 2) { "  ✓ Component Architecture (HLD)" } else { "  - Component Architecture (optional)" })
$(if ($keyClasses.Count -gt 5) { "  ✓ Class Diagrams (LLD)" } else { "  - Class Diagrams (optional)" })
$(if ($newFilesCount -gt 0) { "  ✓ Sequence Diagrams (LLD)" } else { "  - Sequence Diagrams (optional)" })

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 GENERATED FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1.  changed_files.txt              - All changed files with status
2.  new_files.txt                  - New files only
3.  modified_files.txt             - Modified files only
4.  commit_history.txt             - Commit log
5.  languages_detected.txt         - Programming languages
6.  key_classes.txt                - Classes for diagram generation
7.  architecture_analysis.txt      - Architecture impact
8.  dependency_changes.txt         - Build file changes
9.  AI_PROMPT.txt                  - Ready-to-use AI prompt
10. ULTIMATE_ANALYSIS_SUMMARY.txt  - This summary
$(if ($GenerateDiagrams) { "11. diagrams/*.md                   - Mermaid diagram templates" } else { "" })

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OPTION 1: 🤖 AI-Generated (Recommended - 15-30 minutes)
────────────────────────────────────────────────────────────────────
1. Open GitHub Copilot / ChatGPT / Claude
2. Copy prompt from: $promptPath
3. Review and refine generated documentation
4. Verify diagrams render correctly

OPTION 2: 📝 Manual with AI Assistance (1-2 hours)
────────────────────────────────────────────────────────────────────
1. Use generated analysis files as reference
2. Follow: .github/AI_DOCUMENTATION_AGENT.md
3. Use: .github/DOCUMENTATION_CHECKLIST.md
4. Generate diagrams manually using Mermaid

OPTION 3: 🛠️ Fully Manual (4-8 hours)
────────────────────────────────────────────────────────────────────
1. Follow: .github/DOCUMENTATION_GUIDE.md (30 steps)
2. Use: .github/DOCUMENTATION_TEMPLATE.md
3. Create diagrams in: .github/AI_DOCUMENTATION_AGENT.md examples

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 QUICK COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# View this summary
cat "$summaryPath"

# View AI prompt
cat "$promptPath"

# View key classes
cat "$keyClassesPath"

# Open archive directory
cd "$ArchiveDir"

# View diagram templates
$(if ($GenerateDiagrams) { "cat $DiagramDir/*.md" } else { "# Diagrams not generated" })

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 EXPECTED OUTPUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: ${StoryId}_ULTIMATE_ANALYSIS_CONFLUENCE_DOC.md
Size: ~50-100 KB (with diagrams)
Sections: 21 required sections
Diagrams: 5-15 embedded Mermaid diagrams
Code Examples: 10-15 snippets
Quality: Production-ready, reviewer-friendly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Analysis complete! Ready for AI documentation generation.

"@ | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Success "✓ Summary generated"

# Step 14: Generate Archive README
Write-Info "`n[Step 14/15] 📚 Creating archive README..."
$readmePath = Join-Path $ArchiveDir "README.md"
@"
# 🤖 Ultimate Analysis for Story $StoryId

## Overview
AI-powered analysis files for comprehensive PR documentation with LLD/HLD diagrams.

**Generated:** $ScriptDate
**Script Version:** $ScriptVersion
**Branches:** ``$SourceBranch`` → ``$TargetBranch``

---

## 📊 Quick Stats

| Metric | Value |
|--------|-------|
| Files Changed | $filesChanged |
| New Files | $newFilesCount |
| Modified Files | $modifiedFilesCount |
| Commits | $commitCount |
| Lines Added | $insertions |
| Lines Removed | $deletions |
| Languages | $($languages.Count) |
| Modules | $($modules.Count) |
| Key Classes | $($keyClasses.Count) |

---

## 📁 Generated Files

### Analysis Files
- ``changed_files.txt`` - All files with status codes
- ``new_files.txt`` - New files only (A)
- ``modified_files.txt`` - Modified files only (M)
- ``commit_history.txt`` - Git commit log
- ``languages_detected.txt`` - Programming languages used
- ``key_classes.txt`` - Important classes for documentation
- ``architecture_analysis.txt`` - Architecture impact assessment
- ``dependency_changes.txt`` - Build file modifications

### AI Generation
- ``AI_PROMPT.txt`` - **Ready-to-use prompt for AI assistants**
- ``ULTIMATE_ANALYSIS_SUMMARY.txt`` - Comprehensive summary

$(if ($GenerateDiagrams) { @"
### Diagram Templates
- ``diagrams/component_diagram.md`` - Component architecture template
- ``diagrams/class_diagram_template.md`` - Class diagram template

"@ } else { "" })

---

## 🎨 Diagram Requirements

### High-Level Design (HLD)
$(if ($filesChanged -gt 20 -or $modules.Count -gt 3) { "✅" } else { "⬜" }) System Context Diagram
$(if ($modules.Count -gt 2) { "✅" } else { "⬜" }) Component Architecture
$(if ($newFilesCount -gt 5 -or $modifiedFilesCount -gt 10) { "✅" } else { "⬜" }) Data Flow Diagram
⬜ Deployment Architecture (if infrastructure changes)

### Low-Level Design (LLD)
$(if ($keyClasses.Count -gt 5) { "✅" } else { "⬜" }) Class Diagrams (for top $($keyClasses.Count) classes)
$(if ($newFilesCount -gt 0) { "✅" } else { "⬜" }) Sequence Diagrams (for new flows)
⬜ ER Diagram (if database changes)
⬜ State Diagrams (for stateful entities)

---

## 🚀 Usage

### With AI Assistant (Recommended)

#### GitHub Copilot
``````
@workspace Generate documentation using AI_PROMPT.txt
``````

#### ChatGPT/Claude
``````
Copy content from AI_PROMPT.txt and paste into chat
``````

### Manual Documentation
``````bash
# Follow the guide
cat ../.github/DOCUMENTATION_GUIDE.md

# Use the checklist
cat ../.github/DOCUMENTATION_CHECKLIST.md

# Use the template
cp ../.github/DOCUMENTATION_TEMPLATE.md ${StoryId}_ULTIMATE_ANALYSIS_CONFLUENCE_DOC.md
``````

---

## 📖 Reference Documentation

- [AI Documentation Agent](../.github/AI_DOCUMENTATION_AGENT.md) - Complete AI guidelines
- [Documentation Guide](../.github/DOCUMENTATION_GUIDE.md) - 30-step manual process
- [Documentation Checklist](../.github/DOCUMENTATION_CHECKLIST.md) - 200+ quality items
- [Quick Reference](../.github/QUICK_REFERENCE.md) - Quick commands

---

## 🎯 Expected Output

**File:** ``${StoryId}_ULTIMATE_ANALYSIS_CONFLUENCE_DOC.md``
**Size:** 50-100 KB (with embedded diagrams)
**Diagrams:** 5-15 Mermaid diagrams
**Code Examples:** 10-15 snippets
**Quality:** Production-ready for Confluence

---

**Generated by:** Ultimate PR Documentation Generator v$ScriptVersion
**Date:** $ScriptDate
**User:** $env:USERNAME
"@ | Out-File -FilePath $readmePath -Encoding UTF8

Write-Success "✓ Archive README created"

# Step 15: Display Results
Write-Info "`n[Step 15/15] ✅ Process complete!"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════╗
║                     🎉 ANALYSIS COMPLETE 🎉                          ║
╚══════════════════════════════════════════════════════════════════════╝

📊 CHANGE SUMMARY:
──────────────────────────────────────────────────────────────────────
📁 Total Files:        $filesChanged
📝 New Files:          $newFilesCount
✏️  Modified Files:     $modifiedFilesCount
💻 Commits:            $commitCount
➕ Lines Added:        $insertions
➖ Lines Removed:      $deletions
🔤 Languages:          $($languages.Count)
📦 Modules:            $($modules.Count)
🎯 Key Classes:        $($keyClasses.Count)

🎨 DIAGRAM STATUS:
──────────────────────────────────────────────────────────────────────
$(if ($GenerateDiagrams) { "✅ Enabled - Templates generated" } else { "⏸️  Disabled" })
Format: $DiagramFormat
Location: $DiagramDir

📁 FILES LOCATION:
──────────────────────────────────────────────────────────────────────
Analysis: $ArchiveDir
$(if ($GenerateDiagrams) { "Diagrams: $DiagramDir" } else { "" })

🚀 NEXT STEPS:
──────────────────────────────────────────────────────────────────────
1. 📖 Read: $summaryPath
2. 🤖 Copy prompt from: $promptPath
3. 💬 Paste into GitHub Copilot / ChatGPT / Claude
4. ✅ Review generated documentation
5. 📊 Verify diagrams render correctly
6. 📝 Commit and publish

⚡ QUICK START:
──────────────────────────────────────────────────────────────────────
# View summary
cat "$summaryPath"

# View AI prompt
cat "$promptPath"

# Use with Copilot
@workspace Generate documentation using $promptPath

# Expected output file
${StoryId}_ULTIMATE_ANALYSIS_CONFLUENCE_DOC.md

╔══════════════════════════════════════════════════════════════════════╗
║  ✨ Ultimate AI-Powered Documentation System Ready! ✨              ║
╚══════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Success "`n✅ All systems operational! Ready for AI documentation generation.`n"

exit 0

