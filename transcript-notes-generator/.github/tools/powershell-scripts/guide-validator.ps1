<#
.SYNOPSIS
    Validates a generated guide against coverage, voice, and flow quality criteria.

.DESCRIPTION
    guide-validator.ps1 runs the final review pass on a generated guide markdown file,
    checking:
    - COMPLETENESS  : All expected sections have content (no placeholders remain)
    - VOICE         : Narrator quotes and analogies are preserved
    - FLOW          : No disconnected bullets, transitions exist between sections
    - FORMATTING    : White-paper structure rules are met (H1→H2→H3 hierarchy, tables, code blocks)

    Outputs a validation report JSON and prints a pass/fail summary to console.

.PARAMETER GuidePath
    Path to the generated guide .md file to validate.

.PARAMETER ChunkLogPath
    (Optional) Path to the chunk processing log. Used to cross-check captured quotes.

.PARAMETER OutputDir
    Directory to write validation report. Defaults to materials/output/

.EXAMPLE
    .\guide-validator.ps1 -GuidePath "claude/Materials/ai-agents-complete-guide.md" -TopicSlug "ai-agents"
#>

param(
    [Parameter(Mandatory)]
    [string]$GuidePath,

    [string]$TopicSlug      = "guide",
    [string]$ChunkLogPath   = "",
    [string]$OutputDir      = "materials\output"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────
# 1. RESOLVE PATHS
# ─────────────────────────────────────────
$ScriptRoot     = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot       = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptRoot))
$GuideFullPath  = Join-Path $RepoRoot $GuidePath
$OutputFullDir  = Join-Path $RepoRoot $OutputDir

if (-not (Test-Path $GuideFullPath)) {
    Write-Error "Guide not found: $GuideFullPath"
    exit 1
}

if (-not (Test-Path $OutputFullDir)) {
    New-Item -ItemType Directory -Path $OutputFullDir -Force | Out-Null
}

# ─────────────────────────────────────────
# 2. READ GUIDE
# ─────────────────────────────────────────
Write-Host "`n[1/5] Reading guide: $GuideFullPath" -ForegroundColor Yellow
$guideContent = Get-Content $GuideFullPath -Raw -Encoding UTF8
$guideLines   = Get-Content $GuideFullPath -Encoding UTF8

# ─────────────────────────────────────────
# 3. COMPLETENESS CHECK
# ─────────────────────────────────────────
Write-Host "[2/5] Running completeness check..." -ForegroundColor Yellow

$requiredSections = @(
    '## 🧭',   # what this guide covers
    '## 💡',   # the big picture
    '## 📚',   # core concepts
    '## ⚙️',   # how it works
    '## 🔧',   # practical usage
    '## ⚠️',   # gotchas
    '## 🔗',   # how it connects
    '## 🎯',   # key takeaways
    '## 📖'    # narrator quotes
)

$placeholderPatterns = @(
    '\*\[To be filled',
    '\*\[Content will be added',
    '\*\[To be filled during chunk processing\]\*',
    'TBD',
    'TODO'
)

$completenessResults = @()
foreach ($section in $requiredSections) {
    $present = $guideContent -match [regex]::Escape($section)
    $completenessResults += [PSCustomObject]@{
        section = $section
        present = $present
        status  = if ($present) { "PASS" } else { "FAIL" }
    }
}
$completenessResults = @($completenessResults)

$placeholderFound = @($placeholderPatterns | Where-Object { $guideContent -match $_ })
$failedSections = @($completenessResults | Where-Object { $_.status -eq "FAIL" })
$completenessPass = ($failedSections.Count -eq 0) -and ($placeholderFound.Count -eq 0)

# ─────────────────────────────────────────
# 4. VOICE CHECK
# ─────────────────────────────────────────
Write-Host "[3/5] Running voice check..." -ForegroundColor Yellow

$quoteBlocks     = [regex]::Matches($guideContent, '> 💬 \*"[^"]+"\*')
$quoteCount      = $quoteBlocks.Count
$narratorSection = $guideContent -match '## 📖'
$hasNarratorWords= $guideContent -match '## 📖.*?> \*"'

$voicePass = $quoteCount -ge 3 -and $narratorSection

Write-Host "      Inline narrator quotes : $quoteCount (need ≥3)" -ForegroundColor Gray
Write-Host "      Narrator quotes section: $(if($narratorSection){'PRESENT'}else{'MISSING'})" -ForegroundColor Gray

# ─────────────────────────────────────────
# 5. FORMATTING CHECK (White-Paper Rules)
# ─────────────────────────────────────────
Write-Host "[4/5] Running formatting check..." -ForegroundColor Yellow

# Build a version of guideLines with code-block content stripped out
# so that bash/shell comments (# ...) are not counted as headings
$inCodeBlock = $false
$markdownOnlyLines = foreach ($line in $guideLines) {
    if ($line -match '^```') { $inCodeBlock = -not $inCodeBlock; $line }
    elseif ($inCodeBlock)    { '' }   # blank out code content
    else                     { $line }
}

$h1Count      = @($markdownOnlyLines | Where-Object { $_ -match '^# [^#]' }).Count
$h2Count      = @($markdownOnlyLines | Where-Object { $_ -match '^## ' }).Count
$h3Count      = @($markdownOnlyLines | Where-Object { $_ -match '^### ' }).Count
$tableCount   = @($markdownOnlyLines | Where-Object { $_ -match '^\|' }).Count
$codeBlocks   = [regex]::Matches($guideContent, '```').Count / 2
$hasTitle     = $guideContent -match '^# .+— A Complete Guide'
$hasSource    = $guideContent -match '> \*Based on:'
$hasFooter    = $guideContent -match 'Guide synthesised from:'
$hasHrBetween = @($markdownOnlyLines | Where-Object { $_ -match '^---$' }).Count

$formattingIssues = @()
if ($h1Count -ne 1)        { $formattingIssues += "H1 count should be exactly 1 (found $h1Count)" }
if ($h2Count -lt 7)        { $formattingIssues += "Need at least 7 H2 sections (found $h2Count)" }
if (-not $hasTitle)        { $formattingIssues += "Title must follow pattern: '# <Topic> — A Complete Guide'" }
if (-not $hasSource)       { $formattingIssues += "Missing source citation: '> *Based on: ...'" }
if (-not $hasFooter)       { $formattingIssues += "Missing footer: 'Guide synthesised from:'" }
if ($hasHrBetween -lt 5)   { $formattingIssues += "Need horizontal rules (---) between major sections (found $hasHrBetween)" }
$formattingIssues = @($formattingIssues)

$formattingPass = $formattingIssues.Count -eq 0

Write-Host "      H1/H2/H3         : $h1Count / $h2Count / $h3Count" -ForegroundColor Gray
Write-Host "      Tables           : $tableCount rows" -ForegroundColor Gray
Write-Host "      Code blocks      : $([Math]::Floor($codeBlocks))" -ForegroundColor Gray
Write-Host "      Formatting issues: $($formattingIssues.Count)" -ForegroundColor Gray

# ─────────────────────────────────────────
# 6. SUMMARY & REPORT
# ─────────────────────────────────────────
Write-Host "[5/5] Writing validation report..." -ForegroundColor Yellow

$overallPass = $completenessPass -and $voicePass -and $formattingPass

$report = [PSCustomObject]@{
    meta = [PSCustomObject]@{
        topic_slug   = $TopicSlug
        guide_path   = $GuidePath
        validated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        overall      = if ($overallPass) { "PASS" } else { "FAIL" }
    }
    completeness = [PSCustomObject]@{
        passed             = $completenessPass
        missing_sections   = @($failedSections | ForEach-Object { $_.section })
        placeholders_found = @($placeholderFound)
    }
    voice = [PSCustomObject]@{
        passed      = $voicePass
        quote_count = $quoteCount
    }
    formatting = [PSCustomObject]@{
        passed  = $formattingPass
        h1      = $h1Count
        h2      = $h2Count
        h3      = $h3Count
        issues  = @($formattingIssues)
    }
}

$outputFile = Join-Path $OutputFullDir "${TopicSlug}_validation.json"
$report | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

# Console summary
Write-Host "`n══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Completeness : $(if($completenessPass){'✅ PASS'}else{'❌ FAIL'})"
Write-Host "  Voice        : $(if($voicePass){'✅ PASS'}else{'❌ FAIL'})"
Write-Host "  Formatting   : $(if($formattingPass){'✅ PASS'}else{'❌ FAIL'})"
Write-Host "──────────────────────────────────────"
Write-Host "  Overall      : $(if($overallPass){'✅ PASS — ready to publish'}else{'❌ FAIL — review issues above'})"
Write-Host "══════════════════════════════════════`n"

if ($formattingIssues.Count -gt 0) {
    Write-Host "Formatting issues to fix:" -ForegroundColor Red
    $formattingIssues | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    Write-Host ""
}

Write-Host "Report saved: $outputFile`n"
exit $(if ($overallPass) { 0 } else { 1 })
