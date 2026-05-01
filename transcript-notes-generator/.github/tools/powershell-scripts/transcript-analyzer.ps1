<#
.SYNOPSIS
    Analyses a transcript to extract narrator style fingerprint and topic map.

.DESCRIPTION
    transcript-analyzer.ps1 performs a fast first-pass skim of the transcript to:
    - Detect the narrator's explanation style (analogy domain, vocabulary register, rhythm)
    - Build a topic map of all concepts covered
    - Identify section headings and major transitions
    - Output a structured style-report JSON for the transcript-guide agent to consume

.PARAMETER TranscriptPath
    Path to the transcript file. Defaults to materials/transcripts/transcript.txt

.PARAMETER TopicSlug
    Short kebab-case name for the output file. Defaults to 'transcript'.

.PARAMETER OutputDir
    Directory to write analysis JSON. Defaults to materials/output/

.EXAMPLE
    .\transcript-analyzer.ps1 -TopicSlug "ai-agents"
    .\transcript-analyzer.ps1 -TranscriptPath "materials/input/spring_transcript.txt" -TopicSlug "spring-boot"
#>

param(
    [string]$TranscriptPath = "materials\transcripts\transcript.txt",
    [string]$TopicSlug      = "transcript",
    [string]$OutputDir      = "materials\output"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────
# 1. RESOLVE PATHS
# ─────────────────────────────────────────
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptRoot))

$TranscriptFullPath = Join-Path $RepoRoot $TranscriptPath
$OutputFullDir      = Join-Path $RepoRoot $OutputDir

if (-not (Test-Path $TranscriptFullPath)) {
    Write-Error "Transcript not found: $TranscriptFullPath"
    exit 1
}

if (-not (Test-Path $OutputFullDir)) {
    New-Item -ItemType Directory -Path $OutputFullDir -Force | Out-Null
}

# ─────────────────────────────────────────
# 2. READ & CLEAN
# ─────────────────────────────────────────
Write-Host "`n[1/5] Reading transcript..." -ForegroundColor Yellow
$rawContent = Get-Content $TranscriptFullPath -Raw -Encoding UTF8
$cleaned    = ($rawContent -replace '\d+:\d+\s*', '') -replace '\s+', ' '
$sentences  = $cleaned -split '(?<=[.!?])\s+' | Where-Object { $_.Trim().Length -gt 15 }

Write-Host "      Total characters : $($rawContent.Length)" -ForegroundColor Gray
Write-Host "      Total sentences  : $($sentences.Count)" -ForegroundColor Gray

# ─────────────────────────────────────────
# 3. DETECT NARRATOR STYLE SIGNALS
# ─────────────────────────────────────────
Write-Host "[2/5] Detecting narrator style..." -ForegroundColor Yellow

$analogyPatterns   = @('think of it', 'imagine', 'like a', 'similar to', 'just like', 'as if', 'picture', 'analogy')
$rhythmPatterns    = @("here's the thing", "the reason is", "so what this means", "the key insight", "now the interesting", "what actually happens")
$casualMarkers     = @('basically', 'essentially', 'actually', 'really', 'just', 'pretty much', "let's")
$formalMarkers     = @('therefore', 'consequently', 'moreover', 'subsequently', 'implementation', 'architecture')
$caveats           = @("but wait", "watch out", "be careful", "the catch", "important note", "don't confuse", "only works when")
$structuralCues    = @("let's start", "moving on", "next", "finally", "the last", "to summarize", "in summary", "at this point")

$fullText = $sentences -join ' '

$analogyCount   = ($analogyPatterns | ForEach-Object { ([regex]::Matches($fullText, [regex]::Escape($_), 'IgnoreCase')).Count } | Measure-Object -Sum).Sum
$casualCount    = ($casualMarkers   | ForEach-Object { ([regex]::Matches($fullText, "\b$([regex]::Escape($_))\b", 'IgnoreCase')).Count } | Measure-Object -Sum).Sum
$formalCount    = ($formalMarkers   | ForEach-Object { ([regex]::Matches($fullText, "\b$([regex]::Escape($_))\b", 'IgnoreCase')).Count } | Measure-Object -Sum).Sum
$caveatCount    = ($caveats         | ForEach-Object { ([regex]::Matches($fullText, [regex]::Escape($_), 'IgnoreCase')).Count } | Measure-Object -Sum).Sum

$register = if ($casualCount -gt $formalCount) { "casual-practitioner" } else { "formal-technical" }

# Extract actual analogy sentences
$analogySentences = $sentences | Where-Object {
    $s = $_
    $analogyPatterns | Where-Object { $s -imatch $_ }
} | Select-Object -First 5

# Extract caveat sentences
$caveatSentences = $sentences | Where-Object {
    $s = $_
    $caveats | Where-Object { $s -imatch $_ }
} | Select-Object -First 5

Write-Host "      Vocabulary register : $register (casual=$casualCount, formal=$formalCount)" -ForegroundColor Gray
Write-Host "      Analogy signals     : $analogyCount" -ForegroundColor Gray
Write-Host "      Caveat signals      : $caveatCount" -ForegroundColor Gray

# ─────────────────────────────────────────
# 4. BUILD TOPIC MAP
# ─────────────────────────────────────────
Write-Host "[3/5] Building topic map..." -ForegroundColor Yellow

# Detect capitalised noun phrases as potential topic markers
$topicCandidates = [regex]::Matches($fullText, '\b([A-Z][a-z]+(?: [A-Z][a-z]+){1,4})\b') |
    ForEach-Object { $_.Groups[1].Value } |
    Group-Object |
    Where-Object { $_.Count -ge 2 } |
    Sort-Object Count -Descending |
    Select-Object -First 20 |
    ForEach-Object { [PSCustomObject]@{ topic = $_.Name; mentions = $_.Count } }
# Ensure it's always an array for safe property access
$topicCandidates = @($topicCandidates)

# Detect section titles (sentences that look like headings)
$sectionTitles = $sentences | Where-Object {
    $_ -match "^(Introduction|Overview|How|What|Why|Understanding|Building|Setting|Creating|Implementing|Using|Working)" -and
    $_.Length -lt 80
} | Select-Object -First 15
# Ensure it's always an array for safe property access
$sectionTitles = @($sectionTitles)

Write-Host "      Top topics detected : $($topicCandidates.Count)" -ForegroundColor Gray
Write-Host "      Section markers     : $($sectionTitles.Count)" -ForegroundColor Gray

# ─────────────────────────────────────────
# 5. WRITE ANALYSIS JSON
# ─────────────────────────────────────────
Write-Host "[4/5] Writing analysis report..." -ForegroundColor Yellow

$report = [PSCustomObject]@{
    meta = [PSCustomObject]@{
        topic_slug      = $TopicSlug
        transcript_path = $TranscriptPath
        total_chars     = $rawContent.Length
        total_sentences = $sentences.Count
        generated_at    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
    style_fingerprint = [PSCustomObject]@{
        vocabulary_register = $register
        analogy_count       = $analogyCount
        caveat_count        = $caveatCount
        sample_analogies    = @($analogySentences)
        sample_caveats      = @($caveatSentences)
        structural_cues     = @($structuralCues)
    }
    topic_map = [PSCustomObject]@{
        detected_topics  = @($topicCandidates)
        section_markers  = @($sectionTitles)
    }
}

$outputFile = Join-Path $OutputFullDir "${TopicSlug}_analysis.json"
$report | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

Write-Host "[5/5] Analysis saved  : $outputFile" -ForegroundColor Green
Write-Host "`n✅ Analysis complete.`n" -ForegroundColor Green
