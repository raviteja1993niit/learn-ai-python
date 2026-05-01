# 🤖 Agent 1: Code Analysis & Documentation Generator

## Agent Identity
**Name:** Code Analysis & Documentation Agent  
**Version:** 2.0  
**Purpose:** Analyze code changes and generate comprehensive PR documentation  
**Cycle:** Plan → Do → Check → Act (PDCA)  
**Performance:** Ultra-high efficiency, 95% automation

---

## 🎯 Agent Capabilities

### Primary Function
Analyze code changes between Git branches and generate comprehensive, production-ready documentation for Pull Requests.

### Core Features
- ✅ Git diff analysis and statistics
- ✅ File categorization (new, modified, deleted)
- ✅ Code change impact assessment
- ✅ Commit history extraction
- ✅ Dependency analysis
- ✅ Code snippet extraction
- ✅ Documentation generation with AI
- ✅ Quality validation

---

## 📋 PDCA Cycle Implementation

### 🎯 PLAN Phase

#### Task 1.1: Define Documentation Scope
**Objective:** Determine what needs to be documented

**Inputs:**
- Source branch name
- Target branch name
- Story/Ticket ID
- Story title (optional)

**Planning Checklist:**
- [ ] Identify source and target branches
- [ ] Verify branches exist in repository
- [ ] Confirm story ID format
- [ ] Set documentation goals (scope)
- [ ] Define success criteria

**Planning Script:**
```powershell
# PLAN: Validate inputs and set objectives
$planningChecklist = @{
    SourceBranch = "[BRANCH_NAME]"
    TargetBranch = "[BRANCH_NAME]"
    StoryId = "[STORY_ID]"
    Scope = "Full|Partial|Summary"
    SuccessCriteria = @(
        "All changed files documented",
        "10+ code examples included",
        "Commit history complete"
    )
}
```

**Expected Outputs:**
- Validated input parameters
- Documentation scope definition
- Success criteria list

---

#### Task 1.2: Plan Analysis Strategy
**Objective:** Determine analysis approach based on change size

**Strategy Matrix:**

| Change Size | Files | Strategy | Time |
|-------------|-------|----------|------|
| **Small** | <10 | Quick analysis, focused docs | 15 min |
| **Medium** | 10-50 | Standard analysis, full docs | 30-45 min |
| **Large** | >50 | Phased analysis, sectioned docs | 1-2 hrs |

**Planning Decisions:**
```
IF files_changed < 10:
    strategy = "QUICK_ANALYSIS"
    focus = ["Key changes only", "Top 5 classes", "Main flow"]
    
ELIF files_changed < 50:
    strategy = "STANDARD_ANALYSIS"
    focus = ["All significant changes", "Top 15 classes", "All flows"]
    
ELSE:
    strategy = "COMPREHENSIVE_ANALYSIS"
    focus = ["All changes by module", "Top 20 classes", "All flows + integration"]
```

**Planning Checklist:**
- [ ] Estimate number of files changed
- [ ] Select analysis strategy
- [ ] Define focus areas
- [ ] Allocate time budget
- [ ] Identify key classes/files

---

### ⚡ DO Phase

#### Task 2.1: Execute Git Analysis
**Objective:** Extract all code change information

**Execution Steps:**

**Step 1: Repository Validation**
```powershell
# DO: Verify Git repository
try {
    git status | Out-Null
    Write-Output "✅ Git repository validated"
} catch {
    Write-Error "❌ Not a Git repository"
    EXIT 1
}
```

**Step 2: Branch Verification**
```powershell
# DO: Verify both branches exist
$branches = git branch -a
if ($branches -notmatch $SourceBranch) {
    Write-Error "❌ Source branch not found"
    EXIT 1
}
if ($branches -notmatch $TargetBranch) {
    Write-Error "❌ Target branch not found"
    EXIT 1
}
Write-Output "✅ Branches verified"
```

**Step 3: Extract Change Statistics**
```powershell
# DO: Get diff statistics
$stats = git diff "$SourceBranch..$TargetBranch" --shortstat
$fileList = git diff "$SourceBranch..$TargetBranch" --name-status

# Parse statistics
$filesChanged = [regex]::Match($stats, '(\d+) files? changed').Groups[1].Value
$insertions = [regex]::Match($stats, '(\d+) insertions?').Groups[1].Value
$deletions = [regex]::Match($stats, '(\d+) deletions?').Groups[1].Value

Write-Output "✅ Statistics extracted: $filesChanged files, +$insertions, -$deletions"
```

**Step 4: Categorize Files**
```powershell
# DO: Categorize changed files
$newFiles = $fileList | Where-Object { $_ -match '^A\s' }
$modifiedFiles = $fileList | Where-Object { $_ -match '^M\s' }
$deletedFiles = $fileList | Where-Object { $_ -match '^D\s' }

Write-Output "✅ Files categorized: New($($newFiles.Count)) Modified($($modifiedFiles.Count)) Deleted($($deletedFiles.Count))"
```

**Step 5: Extract Commit History**
```powershell
# DO: Get commit history
$commits = git log "$SourceBranch..$TargetBranch" --oneline --no-merges
$commitDetails = git log "$SourceBranch..$TargetBranch" --pretty=format:"%h|%an|%ar|%s" --no-merges

Write-Output "✅ Extracted $($commits.Count) commits"
```

**Execution Checklist:**
- [ ] Git repository validated
- [ ] Branches verified
- [ ] Statistics extracted
- [ ] Files categorized
- [ ] Commits extracted
- [ ] All data saved to files

---

#### Task 2.2: Identify Key Changes
**Objective:** Determine most important changes for documentation

**Execution Algorithm:**
```powershell
# DO: Identify key classes for documentation
$keyClasses = @()

foreach ($file in $modifiedFiles + $newFiles) {
    $filePath = ($file -split '\s+')[1]
    
    # Get line changes for this file
    $diffStat = git diff "$SourceBranch..$TargetBranch" --numstat -- $filePath
    if ($diffStat) {
        $parts = $diffStat -split '\s+'
        $added = [int]$parts[0]
        $removed = [int]$parts[1]
        $total = $added + $removed
        
        # Key class criteria
        if ($total -gt 50 -or $file -match '^A\s') {
            $keyClasses += @{
                File = $filePath
                Changes = $total
                Priority = if ($total -gt 200) { "HIGH" } 
                          elseif ($total -gt 100) { "MEDIUM" } 
                          else { "LOW" }
            }
        }
    }
}

# Sort by changes and take top 15
$keyClasses = $keyClasses | Sort-Object -Property Changes -Descending | Select-Object -First 15

Write-Output "✅ Identified $($keyClasses.Count) key classes"
```

**Key Class Selection Criteria:**
1. **New files** (always include)
2. **>200 lines changed** (high priority)
3. **100-200 lines changed** (medium priority)
4. **50-100 lines changed** (low priority)
5. **API/Controller classes** (always include)
6. **Service/Business logic** (high priority)
7. **Configuration files** (always include)

**Execution Checklist:**
- [ ] Key classes identified (10-15)
- [ ] Prioritization complete
- [ ] File paths validated
- [ ] Change counts accurate

---

#### Task 2.3: Generate AI Prompt
**Objective:** Create ready-to-use AI prompt for documentation generation

**Execution Template:**
```markdown
# DO: Generate AI Documentation Prompt

## TASK FOR AI
Generate comprehensive PR documentation for the following code changes.

## CONTEXT
- **Story ID:** {StoryId}
- **Story Title:** {StoryTitle}
- **Source Branch:** {SourceBranch}
- **Target Branch:** {TargetBranch}
- **Date:** {CurrentDate}

## STATISTICS
- **Files Changed:** {FilesChanged}
- **New Files:** {NewFilesCount}
- **Modified Files:** {ModifiedFilesCount}
- **Deleted Files:** {DeletedFilesCount}
- **Insertions:** {Insertions}
- **Deletions:** {Deletions}
- **Commits:** {CommitCount}

## KEY CHANGES TO DOCUMENT
{foreach KeyClass}
- **{FilePath}** - {Changes} lines changed ({Priority} priority)
{end}

## LANGUAGES DETECTED
{foreach Language}
- {Extension}: {FileCount} files
{end}

## MODULES AFFECTED
{foreach Module}
- {ModuleName}: {FileCount} files
{end}

## DOCUMENTATION REQUIREMENTS

### Structure
Follow this exact structure:
1. Executive Summary (2-3 paragraphs + key highlights)
2. Architectural Overview (if >20 files changed)
3. Detailed Changes Analysis
4. Key Classes Implementation (code examples for top 15)
5. Technical Implementation Details
6. Dependencies and Configuration
7. Testing Strategy
8. Benefits and Impact
9. Commit History
10. File Summary
11-21. [Additional standard sections]

### Code Examples
- Include 10-15 code examples
- Show 3-20 lines of key logic per class
- Explain purpose and necessity (4 bullet points each)
- Use proper syntax highlighting

### Quality Requirements
- All sections must be complete
- No placeholder text
- Professional language
- Technical accuracy
- Clear explanations

## OUTPUT
File: {StoryId}_CODE_ANALYSIS_DOCUMENTATION.md
Format: Markdown
Size: 30-60 KB expected
```

**Execution Checklist:**
- [ ] Prompt template filled
- [ ] All statistics included
- [ ] Key classes listed
- [ ] Requirements clear
- [ ] Output format specified

---

### ✅ CHECK Phase

#### Task 3.1: Validate Generated Files
**Objective:** Ensure all analysis files are created correctly

**Validation Script:**
```powershell
# CHECK: Validate all generated files
$requiredFiles = @(
    "changed_files.txt",
    "new_files.txt",
    "modified_files.txt",
    "commit_history.txt",
    "key_classes.txt",
    "AI_PROMPT.txt",
    "ANALYSIS_SUMMARY.txt"
)

$allValid = $true
foreach ($file in $requiredFiles) {
    $filePath = ".github/docs/archives/$StoryId/$file"
    if (-not (Test-Path $filePath)) {
        Write-Error "❌ Missing: $file"
        $allValid = $false
    } elseif ((Get-Item $filePath).Length -eq 0) {
        Write-Error "❌ Empty: $file"
        $allValid = $false
    } else {
        Write-Output "✅ Valid: $file"
    }
}

if ($allValid) {
    Write-Output "✅ All analysis files validated"
} else {
    Write-Error "❌ Validation failed"
    EXIT 1
}
```

**Validation Checklist:**
- [ ] All required files exist
- [ ] No empty files
- [ ] File formats correct
- [ ] Data accuracy verified
- [ ] No corrupted files

---

#### Task 3.2: Quality Check Documentation
**Objective:** Verify documentation meets quality standards

**Quality Gates:**

**Gate 1: Completeness Check**
```powershell
# CHECK: Documentation completeness
$doc = Get-Content "{StoryId}_CODE_ANALYSIS_DOCUMENTATION.md" -Raw

$requiredSections = @(
    "# .+: .+",  # Title
    "## 1\. Executive Summary",
    "## 2\. Architectural Overview",
    "## 3\. Detailed Changes",
    "## 4\. Key Classes",
    "## .+ Commit History",
    "## .+ File Summary"
)

$missingSection = $false
foreach ($section in $requiredSections) {
    if ($doc -notmatch $section) {
        Write-Error "❌ Missing section: $section"
        $missingSection = $true
    }
}

if (-not $missingSection) {
    Write-Output "✅ All sections present"
}
```

**Gate 2: Code Example Check**
```powershell
# CHECK: Code examples count
$codeBlocks = ([regex]::Matches($doc, '```\w+')).Count
if ($codeBlocks -lt 10) {
    Write-Warning "⚠️  Only $codeBlocks code examples (minimum 10 required)"
} else {
    Write-Output "✅ $codeBlocks code examples found"
}
```

**Gate 3: Quality Metrics**
```powershell
# CHECK: Documentation quality metrics
$wordCount = ($doc -split '\s+').Count
$sectionCount = ([regex]::Matches($doc, '^##\s', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
$tableCount = ([regex]::Matches($doc, '\|.*\|')).Count

$qualityScore = 0
if ($wordCount -gt 5000) { $qualityScore += 25 }
if ($sectionCount -ge 15) { $qualityScore += 25 }
if ($codeBlocks -ge 10) { $qualityScore += 25 }
if ($tableCount -ge 5) { $qualityScore += 25 }

Write-Output "Quality Score: $qualityScore/100"
if ($qualityScore -ge 75) {
    Write-Output "✅ Quality check passed"
} else {
    Write-Warning "⚠️  Quality below threshold (75)"
}
```

**Quality Checklist:**
- [ ] All required sections present
- [ ] 10+ code examples included
- [ ] No placeholder text (TBD, TODO, etc.)
- [ ] Proper Markdown formatting
- [ ] Tables formatted correctly
- [ ] No broken syntax
- [ ] Quality score ≥75

---

#### Task 3.3: Peer Review Validation
**Objective:** Human verification of documentation

**Review Checklist:**

**Technical Accuracy:**
- [ ] Code examples compile/are valid
- [ ] File paths are correct
- [ ] Statistics match Git output
- [ ] Commit SHAs are valid
- [ ] Branch names accurate

**Content Quality:**
- [ ] Executive summary is clear
- [ ] Technical terms explained
- [ ] Logical flow of information
- [ ] No spelling errors
- [ ] Professional tone

**Completeness:**
- [ ] All major changes documented
- [ ] Key classes explained
- [ ] Dependencies listed
- [ ] Testing approach described
- [ ] Next steps defined

**Reviewer Sign-off:**
```yaml
reviewer:
  name: [Reviewer Name]
  date: [Review Date]
  status: APPROVED | NEEDS_REVISION
  comments: |
    [Feedback and suggestions]
```

---

### 🔄 ACT Phase

#### Task 4.1: Publish Documentation
**Objective:** Commit and distribute documentation

**Publication Steps:**

**Step 1: Commit to Repository**
```powershell
# ACT: Commit documentation
git add "{StoryId}_CODE_ANALYSIS_DOCUMENTATION.md"
git add ".github/docs/archives/$StoryId/*"
git commit -m "docs: Add code analysis documentation for $StoryId"
git push origin $TargetBranch

Write-Output "✅ Documentation committed"
```

**Step 2: Link to PR**
```powershell
# ACT: Update PR description
$prLink = "Documentation: [${StoryId}_CODE_ANALYSIS_DOCUMENTATION.md](./${StoryId}_CODE_ANALYSIS_DOCUMENTATION.md)"
Write-Output "Add this to PR description: $prLink"
```

**Step 3: Update JIRA/Ticket**
```powershell
# ACT: Link documentation to ticket
$docUrl = "https://github.com/[org]/[repo]/blob/$TargetBranch/${StoryId}_CODE_ANALYSIS_DOCUMENTATION.md"
Write-Output "Add documentation link to $StoryId: $docUrl"
```

**Step 4: Notify Stakeholders**
```powershell
# ACT: Send notifications
$stakeholders = @("team@example.com", "reviewers@example.com")
$subject = "Documentation Ready: $StoryId"
$body = @"
Documentation for $StoryId is now available:

File: ${StoryId}_CODE_ANALYSIS_DOCUMENTATION.md
Location: [Repository Link]
Size: [File Size] KB
Sections: [Section Count]

Please review and provide feedback.
"@

Write-Output "✅ Notification template ready"
```

**Publication Checklist:**
- [ ] Documentation committed to Git
- [ ] PR description updated
- [ ] JIRA ticket updated
- [ ] Team notified
- [ ] Stakeholders informed
- [ ] Documentation index updated

---

#### Task 4.2: Measure and Improve
**Objective:** Track metrics and identify improvements

**Metrics Collection:**
```powershell
# ACT: Collect performance metrics
$metrics = @{
    StoryId = $StoryId
    StartTime = $StartTime
    EndTime = Get-Date
    Duration = (Get-Date) - $StartTime
    FilesAnalyzed = $filesChanged
    CodeExamples = $codeBlocks
    QualityScore = $qualityScore
    Strategy = $strategy
    ManualEffort = "5-10 min review"
    AutomationRate = "95%"
}

# Save metrics
$metrics | ConvertTo-Json | Out-File ".github/docs/metrics/$StoryId-metrics.json"

Write-Output "✅ Metrics collected"
```

**Performance Analysis:**
```powershell
# ACT: Analyze trends
$allMetrics = Get-ChildItem ".github/docs/metrics/*.json" | 
    ForEach-Object { Get-Content $_ | ConvertFrom-Json }

$avgDuration = ($allMetrics | Measure-Object -Property Duration -Average).Average
$avgQuality = ($allMetrics | Measure-Object -Property QualityScore -Average).Average

Write-Output "Average Duration: $avgDuration"
Write-Output "Average Quality: $avgQuality"

if ($avgDuration -gt 30) {
    Write-Warning "⚠️  Consider optimization - average time exceeds target"
}
```

**Improvement Actions:**
```yaml
improvements:
  identified:
    - issue: "Long processing time for large PRs"
      action: "Implement parallel file analysis"
      priority: HIGH
    
    - issue: "Manual review takes 10+ minutes"
      action: "Add automated quality pre-checks"
      priority: MEDIUM
    
    - issue: "Some code examples missing context"
      action: "Improve snippet extraction logic"
      priority: LOW
  
  implemented:
    - date: 2026-01-09
      improvement: "Added parallel Git operations"
      result: "30% faster analysis"
```

**Act Checklist:**
- [ ] Documentation published
- [ ] All links updated
- [ ] Stakeholders notified
- [ ] Metrics collected
- [ ] Performance analyzed
- [ ] Improvements identified
- [ ] Next cycle planned

---

## 🚀 Agent Execution Command

### Quick Start
```powershell
# Execute complete PDCA cycle
.\.github\agents\code-analysis-docs\execute-agent.ps1 `
    -SourceBranch "main" `
    -TargetBranch "feature/my-feature" `
    -StoryId "PROJ-123" `
    -StoryTitle "Feature Implementation" `
    -AutoPublish $true

# Agent will:
# 1. PLAN: Validate inputs and determine strategy
# 2. DO: Analyze code and generate documentation
# 3. CHECK: Validate quality and completeness
# 4. ACT: Publish and collect metrics
```

### Advanced Options
```powershell
# Custom configuration
.\.github\agents\code-analysis-docs\execute-agent.ps1 `
    -SourceBranch "main" `
    -TargetBranch "feature/my-feature" `
    -StoryId "PROJ-123" `
    -Strategy "COMPREHENSIVE" `      # QUICK | STANDARD | COMPREHENSIVE
    -QualityThreshold 85 `           # Minimum quality score
    -SkipPeerReview $false `         # Require human review
    -AutoPublish $true `             # Auto-commit results
    -NotifyTeam $true                # Send notifications
```

---

## 📊 Success Criteria

### Performance Targets
- **Analysis Time:** <5 minutes for <50 files
- **Documentation Time:** <15 minutes with AI
- **Quality Score:** ≥75/100
- **Automation Rate:** ≥95%
- **Manual Review:** <10 minutes

### Quality Targets
- **Completeness:** 100% required sections
- **Code Examples:** ≥10
- **Accuracy:** 100% (no incorrect information)
- **Readability:** Professional, clear language
- **Usefulness:** Actionable for reviewers

---

## 🔄 Continuous Improvement

### Feedback Loop
```
Metrics Collection → Analysis → Improvements → Implementation → Validation → Repeat
```

### Monthly Review
- Analyze all collected metrics
- Identify common issues
- Prioritize improvements
- Update agent logic
- Retrain if needed

---

## 📖 Related Documentation

- **Execution Script:** `.github/agents/code-analysis-docs/execute-agent.ps1`
- **Chatbot Instructions:** `.github/agents/code-analysis-docs/chatbot-instructions.md`
- **Step-by-Step Guide:** `.github/agents/code-analysis-docs/step-by-step-guide.md`
- **Quality Standards:** `.github/agents/code-analysis-docs/quality-standards.md`

---

**Agent Version:** 2.0  
**Last Updated:** January 9, 2026  
**Status:** ✅ Production Ready  
**PDCA Certified:** Yes

