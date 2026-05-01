param(
    [string]$TopicSlug = "ai-coding-assistants",
    [string]$ChunksPath = "materials\output\chunks\ai-coding-assistants_chunks.json",
    [string]$AnalysisPath = "materials\output\ai-coding-assistants_analysis.json",
    [string]$OutDir = "materials\output"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptRoot))

$ChunksFull  = Join-Path $RepoRoot $ChunksPath
$AnalysisFull= Join-Path $RepoRoot $AnalysisPath
$OutFullDir  = Join-Path $RepoRoot $OutDir

if (-not (Test-Path $ChunksFull)) { Write-Error "Chunks file not found: $ChunksFull"; exit 1 }
if (-not (Test-Path $AnalysisFull)) { Write-Error "Analysis file not found: $AnalysisFull"; exit 1 }
if (-not (Test-Path $OutFullDir)) { New-Item -ItemType Directory -Path $OutFullDir -Force | Out-Null }

Write-Host "Generating draft guide for $TopicSlug..." -ForegroundColor Cyan

$chunksObj   = Get-Content $ChunksFull -Raw | ConvertFrom-Json
$analysisObj = Get-Content $AnalysisFull -Raw | ConvertFrom-Json

$meta = $analysisObj.meta
$style = $analysisObj.style_fingerprint

$topicName = ($TopicSlug -replace '-', ' ')
# Title-case each word safely
$topicName = ($topicName -split '\s+' | Where-Object { $_.Length -gt 0 } | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' '
$dateStr = Get-Date -Format yyyy-MM-dd

$guideLines = @()
$guideLines += "# $($topicName) — A Complete Guide"
$guideLines += "> *Based on: Transcript: $($meta.transcript_path)*"
$guideLines += "> *Generated: $dateStr | Audience: Intermediate*"
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "## 🧭 What This Guide Covers"
$guideLines += ""
$guideLines += "A comprehensive synthesis of the narrator's discussion on $topicName. This guide preserves the narrator's style and practical examples and organises content into core concepts, implementation guidance, and gotchas."
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "## 💡 The Big Picture"
$guideLines += ""
# include sample analogy if present
if ($style.sample_analogies -and $style.sample_analogies.Length -gt 0) {
    $sample = $style.sample_analogies -join ' ' 
    $guideLines += $sample
    $guideLines += ""
    $sampleQuoted = '> 💬 *"' + $sample + '"*'
    $guideLines += $sampleQuoted
    $guideLines += ""
} else {
    $guideLines += "<Narrator's opening analogy or mental model goes here.>"
    $guideLines += ""
}
$guideLines += "---"
$guideLines += ""
$guideLines += "## 📚 Core Concepts"
$guideLines += ""

# Prepare empty sections containers
$coreConcepts = @()
$howItWorks = @()
$practical = @()
$gotchas = @()
$connections = @()
$keyTakeaways = @()
$narratorQuotes = @()

# simple heuristics
$analogyPatterns = @('think of it','imagine','like a','similar to','just like','as if','picture','analogy')
$gotchaPatterns   = @("don't",'do not','watch out','be careful','avoid','gotcha','warning','edge case')
$codeMarkers      = @('```','System.','public ','class ','def ','function ','npm ','pip ')

foreach ($c in $chunksObj.chunks) {
    $text = $c.content
    $lower = $text.ToLower()

    # collect explicit quoted lines
    if ($text -match '"(.{20,})"') {
        $matches = [regex]::Matches($text, '"(.{20,}?)"') | ForEach-Object { $_.Groups[1].Value }
        foreach ($m in $matches) { $narratorQuotes += $m }
    }

    $isCode = $false
    foreach ($cm in $codeMarkers) { if ($text -like "*$cm*") { $isCode = $true; break } }
    $isAnalogy = $false
    foreach ($ap in $analogyPatterns) { if ($lower -like "*$ap*") { $isAnalogy = $true; break } }
    $isGotcha = $false
    foreach ($gp in $gotchaPatterns) { if ($lower -like "*$gp*") { $isGotcha = $true; break } }

    if ($isCode) {
        $practical += $text
        continue
    }
    if ($isGotcha) {
        $gotchas += $text
        continue
    }
    if ($isAnalogy) {
        # prefer big picture but also keep as concept
        $coreConcepts += $text
        continue
    }

    # default: core concept
    $coreConcepts += $text
}

# deduplicate while preserving order
function Unique-Ordered($arr){ $seen=@{}; $out=@(); foreach($i in $arr){ if(-not $seen.ContainsKey($i)){ $seen[$i]=1; $out+=$i } } ; return $out }
$coreConcepts = Unique-Ordered $coreConcepts
$practical = Unique-Ordered $practical
$gotchas = Unique-Ordered $gotchas
$narratorQuotes = Unique-Ordered $narratorQuotes

# Ensure arrays for safe property access
$coreConcepts = @($coreConcepts)
$practical = @($practical)
$gotchas = @($gotchas)
$narratorQuotes = @($narratorQuotes)

# write core concepts as H3 blocks (limit to first 12 for readability)
$conceptIdx = 1
foreach ($c in $coreConcepts[0..([Math]::Min( ($coreConcepts.Count-1), 11))]) {
    $heading = "### Concept $conceptIdx"
    $guideLines += $heading
    $guideLines += ""
    $guideLines += $c
    $guideLines += ""
    $selQuote = ''
    if ($narratorQuotes.Count -ge $conceptIdx) { $selQuote = $narratorQuotes[$conceptIdx-1] } else { $selQuote = $c.Substring(0,[Math]::Min(120,$c.Length)) }
    $guideLines += ('> 💬 *"' + $selQuote + '"*')
    $guideLines += ""
    $guideLines += '```text'
    $guideLines += $c
    $guideLines += '```'
    $guideLines += ""
    $guideLines += "**Why this matters:**"
    $guideLines += "In the narrator's framing, this concept is important because it enables practical, reliable outcomes described in the talk."
    $guideLines += ""
    $conceptIdx += 1
}

$guideLines += "---"
$guideLines += ""
$guideLines += "## ⚙️ How It Works — Under the Hood"
$guideLines += ""
if ($howItWorks.Count -gt 0) { $guideLines += ($howItWorks -join "\n\n") } else { $guideLines += "(Detailed internal mechanics captured from the transcript will be placed here.)" }
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "## 🔧 Practical Usage & Implementation"
$guideLines += ""
if ($practical.Count -gt 0) { foreach($p in $practical){ $guideLines += "- " + $p; $guideLines += "" } } else { $guideLines += "(Practical steps, code and configuration examples captured from the transcript.)" }
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "## ⚠️ Gotchas & Common Mistakes"
$guideLines += ""
$guideLines += "| Gotcha | Why It Happens | Narrator's Advice |"
$guideLines += "|--------|---------------|-------------------|"
if ($gotchas.Count -gt 0) { foreach ($g in $gotchas[0..([Math]::Min(($gotchas.Count-1),9))]) { $guideLines += "| **Likely issue** | Derived from transcript fragment | $g |" } } else { $guideLines += "| *No explicit gotchas detected* | - | - |" }
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "## 🔗 How It Connects to Other Concepts"
$guideLines += ""
$guideLines += "(Connections and dependencies mentioned by the narrator.)"
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "## 🎯 Key Takeaways"
$guideLines += ""
if ($coreConcepts.Count -gt 0) { foreach($i in 0..([Math]::Min(($coreConcepts.Count-1),6))){ $guideLines += "- " + ($coreConcepts[$i].Substring(0,[Math]::Min(140,$coreConcepts[$i].Length))) } } else { $guideLines += "- <No takeaways extracted>" }
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "## 📖 Narrator's Own Words"
$guideLines += ""
if ($narratorQuotes.Count -gt 0) { foreach ($q in $narratorQuotes[0..([Math]::Min(($narratorQuotes.Count-1),4))]) { $guideLines += ('> *"' + $q + '"*'); $guideLines += "" } } else { $guideLines += "> *<No long quotes extracted>*" }
$guideLines += ""
$guideLines += "---"
$guideLines += ""
$guideLines += "*Guide synthesised from: Transcript: $($meta.transcript_path) | Agent: transcript-guide v1.0.0 | Validated: <pending>*"

# Write out file
$outFile = Join-Path $OutFullDir "${TopicSlug}-guide.md"
$guideLines | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Draft guide generated: $outFile" -ForegroundColor Green

# Return path for subsequent validator
Write-Output $outFile
