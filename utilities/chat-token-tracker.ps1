#!/usr/bin/env pwsh
# ============================================================
# chat-token-tracker.ps1
# Tracks token usage of the CURRENT AI conversation, not
# just files on disk.
#
# HOW IT WORKS
# ─────────────────────────────────────────────────────────────
# The script measures 4 sources that consume context window:
#
#   [A] System prompt   — model instructions, mode rules, skills
#   [B] Attached files  — files you attached to the chat
#   [C] Your messages   — everything you typed
#   [D] AI responses    — everything the AI replied
#
# You feed these in via a simple chat-log text file or by
# directly passing values as parameters.
#
# USAGE MODES
# ─────────────────────────────────────────────────────────────
#   Mode 1 — Measure a saved chat log file (recommended)
#     .\chat-token-tracker.ps1 -ChatLog "my-chat.txt"
#
#   Mode 2 — Measure attached files only
#     .\chat-token-tracker.ps1 -AttachedFiles "A.java","B.md"
#
#   Mode 3 — Measure attached files + estimate turns
#     .\chat-token-tracker.ps1 -AttachedFiles "A.java","B.md" -Turns 15
#
#   Mode 4 — Full manual breakdown
#     .\chat-token-tracker.ps1 `
#       -AttachedFiles "A.java","B.md" `
#       -UserMessageChars 3200 `
#       -AiResponseChars  8500 `
#       -SystemPromptTokens 2000
#
# HOW TO GET YOUR CHAT LOG
# ─────────────────────────────────────────────────────────────
#   JetBrains AI Assistant:
#     Right-click inside the chat panel → "Export Conversation"
#     (or manually copy-paste the chat into a .txt file)
#
#   GitHub Copilot Chat:
#     There is no built-in export. Copy the entire chat panel
#     text and save to a .txt file, then run Mode 1.
#
#   Claude.ai:
#     Use Ctrl+A, Ctrl+C inside the chat, paste into .txt file.
# ============================================================

param(
    [string]   $ChatLog            = "",           # Path to saved chat log text file
    [string[]] $AttachedFiles      = @(),          # Files attached to the session
    [int]      $Turns              = 0,            # Estimated number of message turns if no log
    [int]      $AvgUserCharsPerTurn  = 300,        # ~75 words per user message
    [int]      $AvgAiCharsPerTurn    = 1200,       # ~300 words per AI response
    [long]     $UserMessageChars   = 0,            # Override: paste total user message char count
    [long]     $AiResponseChars    = 0,            # Override: paste total AI response char count
    [int]      $SystemPromptTokens = 3000,         # Estimated system/mode instructions (default ~3K)
    [long]     $Limit              = 200000,       # Model context window
    [switch]   $Verbose
)

# ── token estimator ──────────────────────────────────────────
function Estimate-Tokens {
    param([long]$Chars, [string]$Type = "prose")
    $ratio = switch ($Type) {
        "code"  { 3.5 }
        "xml"   { 3.8 }
        default { 4.0 }   # prose / markdown / chat
    }
    return [math]::Ceiling($Chars / $ratio)
}

function Get-FileTokens {
    param([string]$FilePath)
    $ext  = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $text = Get-Content -Raw -Path $FilePath -ErrorAction SilentlyContinue
    if (-not $text) { return 0 }
    $type = if ($ext -in '.java','.ps1','.js','.ts','.py','.cs','.json') { "code" }
            elseif ($ext -in '.xml','.yaml','.yml') { "xml" }
            else { "prose" }
    return Estimate-Tokens -Chars $text.Length -Type $type
}

function Format-Tokens { param([long]$n) "$("{0:N0}" -f $n)" }
function Format-Pct    { param([long]$n, [long]$limit)
    if ($limit -eq 0) { return "N/A" }
    "$([math]::Round($n * 100.0 / $limit, 1))%"
}

function Get-Bar {
    param([long]$used, [long]$limit, [int]$width = 44)
    $filled = if ($limit -gt 0) { [math]::Round($used * $width / $limit) } else { 0 }
    $filled = [math]::Min([math]::Max($filled, 0), $width)
    $bar    = '#' * $filled + '-' * ($width - $filled)
    $color  = if ($filled -ge $width * 0.9) { 'Red' }
              elseif ($filled -ge $width * 0.7) { 'Yellow' }
              else { 'Green' }
    return [PSCustomObject]@{ Bar = "[$bar]"; Color = $color }
}

# ── parse chat log ───────────────────────────────────────────
$chatLogTokens    = 0
$chatLogFileTokens= 0

if ($ChatLog -ne "" -and (Test-Path $ChatLog)) {
    $raw = Get-Content -Raw $ChatLog
    $chatLogTokens = Estimate-Tokens -Chars $raw.Length -Type "prose"

    # Try to split USER vs AI sections for breakdown
    # Supports common export formats: "You:", "User:", "Assistant:", "Copilot:", "Claude:"
    $userMatches = [regex]::Matches($raw, '(?im)^(You|User)\s*:\s*([\s\S]*?)(?=^(You|User|Assistant|Copilot|Claude)\s*:|$\z)')
    $aiMatches   = [regex]::Matches($raw, '(?im)^(Assistant|Copilot|Claude|AI)\s*:\s*([\s\S]*?)(?=^(You|User|Assistant|Copilot|Claude)\s*:|$\z)')

    if ($userMatches.Count -gt 0 -or $aiMatches.Count -gt 0) {
        $UserMessageChars = ($userMatches | ForEach-Object { $_.Groups[2].Value.Length } | Measure-Object -Sum).Sum
        $AiResponseChars  = ($aiMatches   | ForEach-Object { $_.Groups[2].Value.Length } | Measure-Object -Sum).Sum
        Write-Host "  Chat log parsed: $($userMatches.Count) user turns, $($aiMatches.Count) AI turns" -ForegroundColor DarkGray
    } else {
        # Can't split — count whole file as conversation
        Write-Host "  Chat log loaded (unsplit format — counting as full conversation)" -ForegroundColor DarkGray
        $UserMessageChars = [long]($raw.Length * 0.3)   # rough 30/70 split
        $AiResponseChars  = [long]($raw.Length * 0.7)
    }
}

# ── estimate from turns if no explicit char counts ────────────
if ($UserMessageChars -eq 0 -and $Turns -gt 0) {
    $UserMessageChars = $Turns * $AvgUserCharsPerTurn
}
if ($AiResponseChars -eq 0 -and $Turns -gt 0) {
    $AiResponseChars = $Turns * $AvgAiCharsPerTurn
}

# ── attached files ─────────────────────────────────────────────
$fileRows   = @()
$fileTotTok = 0

foreach ($f in $AttachedFiles) {
    if (Test-Path $f) {
        $toks = Get-FileTokens -FilePath $f
        $fileTotTok += $toks
        $fileRows += [PSCustomObject]@{
            File   = Split-Path $f -Leaf
            Tokens = $toks
            Pct    = Format-Pct -n $toks -limit $Limit
        }
    } else {
        Write-Host "  WARNING: File not found — $f" -ForegroundColor Yellow
    }
}

# ── calculate totals ──────────────────────────────────────────
$userTok   = Estimate-Tokens -Chars $UserMessageChars -Type "prose"
$aiTok     = Estimate-Tokens -Chars $AiResponseChars  -Type "prose"
$sysTok    = $SystemPromptTokens
$totalTok  = $sysTok + $fileTotTok + $userTok + $aiTok
$remaining = $Limit - $totalTok

# ── display ───────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║       Chat Conversation Token Tracker            ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Model limit : $(Format-Tokens $Limit) tokens" -ForegroundColor Gray
Write-Host ""

# breakdown table
$breakdown = @(
    [PSCustomObject]@{ Source = "[A] System prompt / mode rules"; Tokens = $sysTok;      Pct = Format-Pct $sysTok $Limit }
    [PSCustomObject]@{ Source = "[B] Attached files ($($fileRows.Count) files)";  Tokens = $fileTotTok; Pct = Format-Pct $fileTotTok $Limit }
    [PSCustomObject]@{ Source = "[C] Your messages";              Tokens = $userTok;     Pct = Format-Pct $userTok $Limit }
    [PSCustomObject]@{ Source = "[D] AI responses";               Tokens = $aiTok;       Pct = Format-Pct $aiTok $Limit }
)

Write-Host "  ┌─────────────────────────────────────────┬────────────┬──────────┐" -ForegroundColor DarkGray
Write-Host "  │ Source                                  │   Tokens   │  % Limit │" -ForegroundColor DarkGray
Write-Host "  ├─────────────────────────────────────────┼────────────┼──────────┤" -ForegroundColor DarkGray
foreach ($row in $breakdown) {
    $src  = $row.Source.PadRight(39)
    $toks = (Format-Tokens $row.Tokens).PadLeft(10)
    $pct  = $row.Pct.PadLeft(8)
    Write-Host "  │ $src │ $toks │ $pct │" -ForegroundColor White
}
Write-Host "  ├─────────────────────────────────────────┼────────────┼──────────┤" -ForegroundColor DarkGray
$totStr = (Format-Tokens $totalTok).PadLeft(10)
$totPct = (Format-Pct $totalTok $Limit).PadLeft(8)
Write-Host "  │ TOTAL                                   │ $totStr │ $totPct │" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────┴────────────┴──────────┘" -ForegroundColor DarkGray
Write-Host ""

# remaining
$remColor = if ($remaining -lt 10000) { 'Red' } elseif ($remaining -lt 50000) { 'Yellow' } else { 'Green' }
Write-Host "  Remaining capacity : $(Format-Tokens $remaining) tokens" -ForegroundColor $remColor
Write-Host ""

# progress bar
$bar = Get-Bar -used $totalTok -limit $Limit
Write-Host -NoNewline "  Usage  "
Write-Host $bar.Bar -ForegroundColor $bar.Color
Write-Host ""

# risk
$usedPct = $totalTok * 100.0 / $Limit
$rating = if     ($usedPct -lt 30) { "🟢 LOW    — plenty of room for more context" }
          elseif ($usedPct -lt 60) { "🟡 MEDIUM — comfortable, continue the session" }
          elseif ($usedPct -lt 80) { "🟠 HIGH   — trim attached files or start winding down" }
          elseif ($usedPct -lt 95) { "🔴 CRITICAL — save to CHANGELOG and start a new session soon" }
          else                     { "💀 OVER LIMIT — context is being truncated NOW" }
Write-Host "  Risk   : $rating" -ForegroundColor White
Write-Host ""

# attached files verbose
if ($Verbose -and $fileRows.Count -gt 0) {
    Write-Host "  Attached files breakdown:" -ForegroundColor Cyan
    $fileRows | Sort-Object Tokens -Descending | ForEach-Object {
        Write-Host ("    {0,8} tokens  ({1,6})  {2}" -f (Format-Tokens $_.Tokens), $_.Pct, $_.File) -ForegroundColor Gray
    }
    Write-Host ""
}

# advice
Write-Host "  ── Advice ──────────────────────────────────────────" -ForegroundColor DarkGray
if ($remaining -lt 50000) {
    Write-Host "  ⚠  Save progress to CHANGELOG.md before context runs out" -ForegroundColor Yellow
    Write-Host "  ⚠  Start a new session — attach only CHANGELOG.md as context" -ForegroundColor Yellow
} elseif ($fileTotTok -gt ($Limit * 0.4)) {
    Write-Host "  💡 Attached files consume $(Format-Pct $fileTotTok $Limit) of limit — consider attaching fewer files" -ForegroundColor Cyan
} else {
    Write-Host "  ✅ Context usage is healthy — continue the session" -ForegroundColor Green
}
Write-Host ""

# how to get more accurate numbers
Write-Host "  ── How to get exact counts ─────────────────────────" -ForegroundColor DarkGray
Write-Host "  1. Export/copy-paste your chat to a .txt file" -ForegroundColor Gray
Write-Host "     Then: .\chat-token-tracker.ps1 -ChatLog 'my-chat.txt'" -ForegroundColor DarkGray
Write-Host "  2. Count chars in a chat message:" -ForegroundColor Gray
Write-Host "     ('your message here').Length   # paste in PowerShell" -ForegroundColor DarkGray
Write-Host "  3. Rerun with -UserMessageChars and -AiResponseChars overrides" -ForegroundColor Gray
Write-Host ""

