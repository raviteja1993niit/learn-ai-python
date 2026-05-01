<#
.SYNOPSIS
    Splits a transcript file into 5-sentence chunks and writes a JSON output file.

.DESCRIPTION
    transcript-chunker.ps1 reads a transcript from materials/input/ (or the default
    materials/transcripts/transcript.txt), splits it into chunks of N sentences,
    and writes a structured JSON chunk file to materials/output/chunks/.

    The JSON output is consumed by the transcript-guide agent during processing.

.PARAMETER TranscriptPath
    Path to the transcript file. Defaults to materials/transcripts/transcript.txt

.PARAMETER ChunkSize
    Number of sentences per chunk. Defaults to 5.

.PARAMETER TopicSlug
    Short kebab-case name for the topic (used in output file name). Defaults to 'transcript'.

.PARAMETER OutputDir
    Directory to write chunk JSON. Defaults to materials/output/chunks/

.EXAMPLE
    .\transcript-chunker.ps1 -TopicSlug "ai-agents"
    .\transcript-chunker.ps1 -TranscriptPath "materials/input/spring_transcript.txt" -TopicSlug "spring-boot" -ChunkSize 5
#>

param(
    [string]$TranscriptPath = "materials\transcripts\transcript.txt",
    [int]$ChunkSize = 5,
    [string]$TopicSlug = "transcript",
    [string]$OutputDir = "materials\output\chunks"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────
# 1. RESOLVE PATHS
# ─────────────────────────────────────────
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptRoot))  # three levels up from .github/tools/powershell-scripts

$TranscriptFullPath = Join-Path $RepoRoot $TranscriptPath
$OutputFullDir      = Join-Path $RepoRoot $OutputDir

if (-not (Test-Path $TranscriptFullPath)) {
    Write-Error "Transcript not found: $TranscriptFullPath"
    exit 1
}

if (-not (Test-Path $OutputFullDir)) {
    New-Item -ItemType Directory -Path $OutputFullDir -Force | Out-Null
    Write-Host "Created output directory: $OutputFullDir" -ForegroundColor Cyan
}

# ─────────────────────────────────────────
# 2. READ & CLEAN TRANSCRIPT
# ─────────────────────────────────────────
Write-Host "`n[1/4] Reading transcript: $TranscriptFullPath" -ForegroundColor Yellow
$rawContent = Get-Content $TranscriptFullPath -Raw -Encoding UTF8

# Remove timestamps (e.g. "0:00", "1:23", "10:45")
$cleaned = $rawContent -replace '\d+:\d+\s*', ''

# Normalise whitespace
$cleaned = $cleaned -replace '\s+', ' '
$cleaned = $cleaned.Trim()

# ─────────────────────────────────────────
# 3. SPLIT INTO SENTENCES
# ─────────────────────────────────────────
Write-Host "[2/4] Splitting into sentences..." -ForegroundColor Yellow

$sentences = $cleaned -split '(?<=[.!?])\s+' |
    Where-Object { $_.Trim().Length -gt 15 } |
    ForEach-Object { $_.Trim() }

$totalSentences = $sentences.Count
$totalChunks    = [Math]::Ceiling($totalSentences / $ChunkSize)

Write-Host "      Total sentences : $totalSentences" -ForegroundColor Gray
Write-Host "      Chunk size      : $ChunkSize sentences" -ForegroundColor Gray
Write-Host "      Total chunks    : $totalChunks" -ForegroundColor Gray

# ─────────────────────────────────────────
# 4. BUILD CHUNK OBJECTS
# ─────────────────────────────────────────
Write-Host "[3/4] Building chunks..." -ForegroundColor Yellow

$chunks = @()
for ($i = 0; $i -lt $totalSentences; $i += $ChunkSize) {
    $endIdx        = [Math]::Min($i + $ChunkSize - 1, $totalSentences - 1)
    $chunkNum      = [int]($i / $ChunkSize) + 1
    $chunkSentences = $sentences[$i..$endIdx]
    $chunkText     = $chunkSentences -join ' '

    $chunks += [PSCustomObject]@{
        chunk_id       = $chunkNum
        sentence_start = $i
        sentence_end   = $endIdx
        sentence_count = $chunkSentences.Count
        content        = $chunkText
        status         = "pending"
        section_target = $null
        notes          = $null
    }
}

# ─────────────────────────────────────────
# 5. WRITE OUTPUT JSON
# ─────────────────────────────────────────
$date          = Get-Date -Format "yyyy-MM-dd"
$outputFile    = Join-Path $OutputFullDir "${TopicSlug}_chunks.json"
$logFile       = Join-Path (Join-Path $RepoRoot "materials\output\logs") "${TopicSlug}_${date}_chunk-log.txt"

# Ensure logs dir exists
$logsDir = Join-Path $RepoRoot "materials\output\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$output = [PSCustomObject]@{
    meta = [PSCustomObject]@{
        topic_slug       = $TopicSlug
        transcript_path  = $TranscriptPath
        chunk_size       = $ChunkSize
        total_sentences  = $totalSentences
        total_chunks     = $totalChunks
        generated_at     = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
    chunks = $chunks
}

$output | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8
Write-Host "[4/4] Output written : $outputFile" -ForegroundColor Green

# Write summary log
$logContent = @"
TRANSCRIPT CHUNKER LOG
======================
Date           : $date
Topic          : $TopicSlug
Transcript     : $TranscriptPath
Chunk size     : $ChunkSize sentences
Total sentences: $totalSentences
Total chunks   : $totalChunks
Output file    : $outputFile
"@
$logContent | Set-Content $logFile -Encoding UTF8

Write-Host "`n✅ Chunking complete." -ForegroundColor Green
Write-Host "   Chunks JSON : $outputFile"
Write-Host "   Run log     : $logFile`n"
