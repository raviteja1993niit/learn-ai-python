<#
.SYNOPSIS
    Finds usages of TransactionRequest / TransactionResponse fields and methods
    in a Java codebase and writes a single consolidated CSV lookup file.

.DESCRIPTION
    Phase 1 – Parses every .java file under $ModelBasePath to extract class names,
              camelCase accessor names, public no-arg method names, and derives each
              class's canonical dot-notation path prefix (e.g. Acquirer → merchantcontext.acquirer).
    Phase 2 – Builds per-class regex patterns covering all three usage forms:
              ClassName::  |  camelName().  |  camelName.
    Phase 3 – Searches $RepoPath for *.java files, excluding test, integration,
              and test-data files (by directory path and filename convention).
    Phase 4 – Extracts a normalised lowercase dot-notation FieldName from each matched
              line (e.g. merchantContext().acquirer().acquirerId() → merchantcontext.acquirer.acquirerid).
    Phase 5 – Writes one timestamped consolidated CSV:
              FieldName, ClassName, ModelClass, LineContent, LineNo, FilePath, RepoName
              ClassName   = Java class name of the FILE where the usage was found.
              ModelClass  = The TSPI model class whose accessor matched (e.g. Transaction, Merchant).
              LineContent = Full trimmed source line containing the usage.

.PARAMETER RepoPath
    Path to the Java codebase to search. (Required)

.PARAMETER ModelBasePath
    Root directory of the generated megajson model Java classes.
    Default: libmpgs-megajson-model generated-sources path.

.PARAMETER OutputDir
    Directory where the output CSV is written.
    Default: logs\ folder beside this script.

.PARAMETER OutputCsvName
    Base name for the output CSV file is derived automatically from the repo name + timestamp
    (e.g. acqelavons2aservice_20260417_103000.csv).

.PARAMETER ExcludeModules
    Module folder names inside RepoPath to skip entirely (e.g. integration-test or test-data
    modules). The comparison is case-insensitive and matches the immediate folder name only.
    Default: elavon-integration-tests, libmpgs-elavon-test-data, and any folder whose name
    contains 'integration-test', 'test-data', or 'testdata'.

.PARAMETER UseRipgrep
    When present, uses 'rg' (ripgrep) for searching instead of Select-String.
    Ripgrep is significantly faster on large codebases.

.EXAMPLE
    .\Find-TSPIFieldUsages.ps1 -RepoPath "C:\repos\acqelavons2aservice"

.EXAMPLE
    .\Find-TSPIFieldUsages.ps1 -RepoPath "C:\repos\another-service" -Verbose

.EXAMPLE
    # Override which modules to skip
    .\Find-TSPIFieldUsages.ps1 -RepoPath "C:\repos\svc" `
        -ExcludeModules @("my-integration-tests","my-test-data")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoPath,

    [string] $ModelBasePath = `
        "C:\Users\e135408\IdeaProjects\MPGS\SourceCode\libmpgs-megajson-model\target\generated-sources\sdkgen\com\mastercard\gateway\acquiring\megajson",

    [string] $OutputDir = `
        (Join-Path $PSScriptRoot "..\logs"),

    [string] $FieldNamingConventionsFile = `
        (Join-Path $PSScriptRoot "field-naming-conventions.txt"),

    # Explicitly named modules to exclude(case-insensitive folder name match).
    # Leave empty to rely only on the automatic pattern-based detection below.
    [string[]] $ExcludeModules = @(),

    [switch] $UseRipgrep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# ---------------------------------------------------------------------------
# Load canonical FieldName conventions for validation
# ---------------------------------------------------------------------------
$script:ConventionSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if (Test-Path $FieldNamingConventionsFile) {
    Get-Content $FieldNamingConventionsFile | Where-Object { $_.Trim() -ne '' } | ForEach-Object {
        [void]$script:ConventionSet.Add($_.Trim().ToLower())
    }
    Write-Host "  [INFO]  Loaded $($script:ConventionSet.Count) canonical field names from conventions file." -ForegroundColor White
} else {
    Write-Host "  [WARN]  Conventions file not found – ValidationStatus will be 'UNCHECKED'." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Phase {
    param([int]$Num, [string]$Title)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  Phase $Num : $Title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-Info  { param([string]$Msg) Write-Host "  [INFO]  $Msg" -ForegroundColor White }
function Write-Ok    { param([string]$Msg) Write-Host "  [ OK ]  $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "  [WARN]  $Msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# Test-file / test-module exclusion
#
# Excludes a file when ANY of the following is true:
#
# A) MODULE-LEVEL: The file lives inside a module whose folder name matches
#    a known test/integration/test-data pattern, OR is listed in $ExcludeModules.
#    Patterns (case-insensitive, matched against the first path segment below RepoPath):
#      - contains "integration-test" or "integration-tests"
#      - contains "test-data" or "testdata"
#      - ends with "-it"
#
# B) DIRECTORY-LEVEL: The file path contains \src\test\ or \src\it\
#    (standard Maven test source directories — same filter as `grep -v "/src/test/"`)
#
# C) FILENAME-LEVEL: The filename (without extension) matches JUnit / test
#    naming conventions:
#      ends with: Test, Tests, IT, Spec, TestCase, TestBase, TestHelper,
#                 TestSuite, TestSupport, TestConfig, TestConfiguration,
#                 Runner (when under test dir), StepDefinitions
#      starts with: Mock, Stub, Fake
#      exact:       AbstractElavon*Test, *Builder (test helper builders)
# ---------------------------------------------------------------------------

# Auto-detect module exclusion patterns from folder names under RepoPath
$script:ExcludeModuleSet = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

if (Test-Path $RepoPath) {
    Get-ChildItem $RepoPath -Directory | ForEach-Object {
        $name = $_.Name
        # Exclude modules that are clearly test/integration/test-data by name
        if ($name -match '(?i)(integration[-_]?tests?|test[-_]?data|testdata)' -or
            $name -match '(?i)-it$') {
            [void] $script:ExcludeModuleSet.Add($name)
        }
    }
}
# Also add any caller-supplied module names
foreach ($m in $ExcludeModules) {
    [void] $script:ExcludeModuleSet.Add($m)
}

$script:RepoPathNorm = $RepoPath.TrimEnd('\') + '\'

# Directory path fragments that always mean "test source"
$script:DirExcludePatterns = @(
    '*\src\test\*',
    '*\src\it\*'
)

# Filename suffixes (without .java) that identify test/infra classes
$script:TestNameSuffixPattern = '(?i)(Tests?|IT|Spec|TestCase|TestBase|TestHelper|TestSuite|TestSupport|TestConfig(uration)?|StepDefinitions?|Runner)$'
# Filename prefixes that identify mock/stub/fake helper classes
$script:TestNamePrefixPattern = '(?i)^(Mock|Stub|Fake)'

function Test-IsTestFile {
    param([string] $FullPath)

    $normalized = $FullPath -replace '/', '\'

    # A) Module-level exclusion: check first path segment below RepoPath
    if ($normalized.StartsWith($script:RepoPathNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative     = $normalized.Substring($script:RepoPathNorm.Length)
        $firstSegment = ($relative -split '\\')[0]
        if ($script:ExcludeModuleSet.Contains($firstSegment)) {
            return $true
        }
    }

    # B) Directory-level exclusion (src\test, src\it)
    foreach ($pat in $script:DirExcludePatterns) {
        if ($normalized -like $pat) { return $true }
    }

    # C) Filename-level exclusion
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FullPath)
    if ($baseName -match $script:TestNameSuffixPattern) { return $true }
    if ($baseName -match $script:TestNamePrefixPattern)  { return $true }

    return $false
}

# ---------------------------------------------------------------------------
# Derive canonical dot-notation path prefix from a model file's relative path.
#
# Rules (relative to megajson root):
#   TransactionRequest.java          → ""   (root wrapper, no prefix)
#   TransactionResponse.java         → ""   (root wrapper)
#   transactionrequest\Foo.java      → "foo"                (strip namespace)
#   transactionrequest\bar\Baz.java  → "bar.baz"
#   transactionresponse\Foo.java     → "foo"
#   transactionresponse\transactionresponse\Foo.java → "transactionresponse.foo"
#                                     (deduplicate consecutive identical segments)
# ---------------------------------------------------------------------------

function Get-ClassPathPrefix {
    param([string] $RelPath)

    # Normalise separators and strip .java extension
    [string[]] $parts = @(
        ($RelPath -replace '\.java$', '' -replace '/', '\') -split '\\' |
        Where-Object { $_ -ne '' }
    )

    if ($parts.Count -le 1) { return '' }   # root-level wrapper file

    # Strip top-level namespace folders that are just organisational
    # ('transactionrequest' → the actual fields sit at top level: transaction, merchantcontext…)
    if ($parts[0] -eq 'transactionrequest') {
        [string[]] $parts = @($parts[1..($parts.Count - 1)])
    }

    if ($parts.Count -eq 0) { return '' }

    # Deduplicate consecutive identical segments (handles transactionresponse/transactionresponse/…)
    [string[]] $deduped = @($parts[0])
    for ($i = 1; $i -lt $parts.Count; $i++) {
        if ($parts[$i].ToLower() -ne $parts[$i - 1].ToLower()) {
            $deduped += $parts[$i]
        }
    }

    return ($deduped | ForEach-Object { $_.ToLower() }) -join '.'
}

# ---------------------------------------------------------------------------
# Phase 1 – Parse Java model files
# ---------------------------------------------------------------------------

Write-Phase 1 "Parsing Java model files under ModelBasePath"

if (-not (Test-Path $ModelBasePath)) {
    Write-Error "ModelBasePath not found: $ModelBasePath"
    exit 1
}

# Regex patterns used while parsing
$classNameRegex   = [regex] '(?m)public\s+(?:class|enum|interface)\s+(\w+)'
$noArgMethodRegex = [regex] '(?m)public\s+\S+\s+(\w+)\s*\(\s*\)\s*(?:throws\s+\w+\s*)?\{'

# Words that are Java boilerplate methods, not model accessors
$excludedMethods = [System.Collections.Generic.HashSet[string]] @(
    'validate','toString','hashCode','equals','copy','clone','build',
    'readObject','writeObject','compareTo','iterator'
)

# Map: ClassName -> @{ CamelName, Methods[], PathPrefix, FilePath, RelativePath }
$classMap = [System.Collections.Generic.Dictionary[string,hashtable]]::new()

$javaModelFiles = Get-ChildItem -Path $ModelBasePath -Recurse -Filter "*.java"

foreach ($jf in $javaModelFiles) {
    $content = Get-Content $jf.FullName -Raw

    # Derive class name from file name (reliable) and confirm with source
    $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($jf.Name)

    $classMatch = $classNameRegex.Match($content)
    $className  = if ($classMatch.Success) { $classMatch.Groups[1].Value } else { $fileBaseName }

    # camelCase name used as accessor: e.g. Transaction -> transaction
    $camelName = $className.Substring(0,1).ToLower() + $className.Substring(1)

    # Extract all public no-arg method names
    $methodMatches = $noArgMethodRegex.Matches($content)
    [string[]] $methods = @(
        $methodMatches |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object   { $_ -ne $className -and -not $excludedMethods.Contains($_) } |
        Select-Object  -Unique
    )

    # Relative path from ModelBasePath (used as a human-readable context)
    $relPath    = $jf.FullName.Substring($ModelBasePath.Length).TrimStart('\','/')
    $pathPrefix = Get-ClassPathPrefix -RelPath $relPath

    $entry = @{
        ClassName    = $className
        CamelName    = $camelName
        Methods      = $methods
        PathPrefix   = $pathPrefix
        FilePath     = $jf.FullName
        RelativePath = $relPath
    }

    if (-not $classMap.ContainsKey($className)) {
        $classMap[$className] = $entry
    }

    Write-Verbose "  Parsed $className  prefix='$pathPrefix'  ($($methods.Count) methods)  [$relPath]"
}

Write-Ok "Found $($classMap.Count) model classes across $($javaModelFiles.Count) Java files."

# ---------------------------------------------------------------------------
# Phase 2 – Build search patterns
# ---------------------------------------------------------------------------

Write-Phase 2 "Building search patterns"

# For each class we build a regex that matches any of:
#   ClassName::           (static reference / method reference)
#   camelName().          (method call chained access)
#   camelName.            (field access)
#
# We escape special chars but these are all plain identifiers, so it's safe.

function New-ClassPattern {
    param([hashtable]$Entry)
    $cn = $Entry.ClassName
    $cc = $Entry.CamelName
    # The trailing dot/bracket distinguishes from unrelated identifiers
    return "($([regex]::Escape($cn))::|$([regex]::Escape($cc))\(\)\.|$([regex]::Escape($cc))\.)"
}

# Build individual patterns and also a single mega-pattern for efficient one-pass search
$patternMap = [ordered]@{}   # ClassName -> pattern string

foreach ($key in $classMap.Keys) {
    $patternMap[$key] = New-ClassPattern -Entry $classMap[$key]
}

# Combined OR pattern (all classes at once – single grep pass per file)
$megaPattern = "(" + (($patternMap.Values | ForEach-Object { $_.TrimStart('(').TrimEnd(')') }) -join "|") + ")"

Write-Ok "Built patterns for $($patternMap.Count) classes."
Write-Verbose "Mega-pattern length: $($megaPattern.Length) chars"

# Check if ripgrep is available (faster for large repos)
$rgAvailable = $false
if ($UseRipgrep) {
    $rgAvailable = $null -ne (Get-Command rg -ErrorAction SilentlyContinue)
    if (-not $rgAvailable) {
        Write-Warn "ripgrep (rg) not found on PATH – falling back to Select-String."
    } else {
        Write-Ok "ripgrep found – will use rg for searching."
    }
}

# ---------------------------------------------------------------------------
# Phase 3 – Search repo
# ---------------------------------------------------------------------------

Write-Phase 3 "Searching repo for field/method usages (excluding test/integration/test-data)"

if (-not (Test-Path $RepoPath)) {
    Write-Error "RepoPath not found: $RepoPath"
    exit 1
}

$repoName = Split-Path $RepoPath -Leaf
Write-Info "Repo  : $repoName"
Write-Info "Path  : $RepoPath"

if ($script:ExcludeModuleSet.Count -gt 0) {
    Write-Info "Excluded modules (entire):"
    foreach ($m in ($script:ExcludeModuleSet | Sort-Object)) {
        Write-Info "    - $m"
    }
} else {
    Write-Info "No entire modules excluded (all src\test paths still skipped)"
}
Write-Info "Also excluding: all src\test\, src\it\ directories + JUnit filename patterns"

# Collects all raw match results
$allMatches = [System.Collections.Generic.List[pscustomobject]]::new()

if ($rgAvailable) {
    # ---------------------------------------------------------------
    # ripgrep path – very fast, outputs file:line:content
    $rgPath = $RepoPath -replace '\\', '/'

    # Compose --glob exclusions for ripgrep
    $rgExcludes = @(
        '!**/src/test/**', '!**/src/it/**', '!**/test-data/**',
        '!**/integration/**', '!**/e2e/**',
        '!**/*Test.java', '!**/*Tests.java', '!**/*IT.java',
        '!**/*Spec.java', '!**/*TestCase.java', '!**/*TestBase.java',
        '!**/Mock*.java', '!**/Stub*.java', '!**/Fake*.java'
    )
    $rgGlobArgs = $rgExcludes | ForEach-Object { "--glob"; $_ }

    $rgOutput = & rg --no-heading --line-number --include '*.java' @rgGlobArgs `
                     -e $megaPattern $rgPath 2>$null

    foreach ($line in $rgOutput) {
        if ($line -match '^(.+):(\d+):(.+)$') {
            $allMatches.Add([pscustomobject]@{
                FilePath = $Matches[1]
                LineNo   = [int]$Matches[2]
                RawLine  = $Matches[3]
                RepoName = $repoName
            })
        }
    }

} else {
    # ---------------------------------------------------------------
    # Select-String path – pure PowerShell, no external dependencies
    $allJavaFiles  = Get-ChildItem -Path $RepoPath -Recurse -Filter "*.java" -ErrorAction SilentlyContinue
    $javaFiles     = $allJavaFiles | Where-Object { -not (Test-IsTestFile -FullPath $_.FullName) }
    $excludedCount = $allJavaFiles.Count - ($javaFiles | Measure-Object).Count
    $fileCount     = ($javaFiles | Measure-Object).Count

    Write-Info "  Total .java files found  : $($allJavaFiles.Count)"
    Write-Info "  Excluded (test/infra)    : $excludedCount"
    Write-Info "  Business classes to scan : $fileCount"

    $i = 0
    foreach ($jf in $javaFiles) {
        $i++
        if ($i % 50 -eq 0) { Write-Verbose "  ... scanned $i / $fileCount files" }

        try {
            $hits = Select-String -Path $jf.FullName -Pattern $megaPattern -ErrorAction SilentlyContinue
            foreach ($hit in $hits) {
                $allMatches.Add([pscustomobject]@{
                    FilePath = $jf.FullName
                    LineNo   = $hit.LineNumber
                    RawLine  = $hit.Line
                    RepoName = $repoName
                })
            }
        } catch {
            Write-Verbose "  Skipped (read error): $($jf.FullName)"
        }
    }
}

Write-Ok "Search complete – $($allMatches.Count) raw matches found."

# ---------------------------------------------------------------------------
# Phase 4 – Extract normalised dot-notation FieldName from each match
# ---------------------------------------------------------------------------

Write-Phase 4 "Normalising FieldName to dot-notation (lowercase, no parentheses)"

# Root-level accessor words that anchor the canonical field path.
# NOTE: longer alternatives must come before shorter ones (transactionResponse before transaction).
$chainRegex = [regex] (
    '(?i)\b(transactionResponse|transactionresponse|transaction' +
    '|merchantContext|merchantcontext|routingHeader|routingheader' +
    '|settlementRequest|settlementrequest)' +
    '(?:\(\))?(?:\.(?:[a-zA-Z_]\w*)(?:\(\))?(?:\[\d*\]|\[\])?)*'
)

# Java Object / String utility methods that appear at the end of access chains
# but are NOT TSPI fields. Truncate the chain when we hit one of these.
$script:JavaNoiseMethods = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        'tostring','equals','equalsignorecase','touppercase','tolowercase',
        'hashcode','length','substring','trim','contains','startswith','endswith',
        'isempty','isblank','compareto','matches','replace','replaceall','format',
        'optional','ofnullable','orelse','orelsethrow','orelsethrow','ispresent',
        'isnotempty','isnotblank','isnull','nonnull','requirenonnull'
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)

# Strip Java utility method noise from the tail of a dot-notation chain.
function Remove-JavaNoiseSuffix {
    param([string] $Chain)
    $parts = $Chain -split '\.'
    $clean = [System.Collections.Generic.List[string]]::new()
    foreach ($part in $parts) {
        if ($script:JavaNoiseMethods.Contains($part)) { break }
        $clean.Add($part)
    }
    return ($clean -join '.')
}

function Get-NormalizedFieldName {
    param(
        [string] $RawLine,
        [string] $PathPrefix,
        [string] $MethodName,
        [string] $CamelName = ''      # camelCase accessor of the matched model class
    )

    # --- Attempt 1: extract chain anchored at a known root word ---
    $best      = ""
    $bestScore = 0
    foreach ($m in $chainRegex.Matches($RawLine)) {
        # Skip PascalCase STATIC references like RoutingHeader.Action.CAPTURE (dot after class name).
        # Keep PascalCase CONSTRUCTOR chains like new TransactionResponse().sourceTransactionId()
        # (opening paren immediately follows the class name).
        if ($m.Value[0] -cmatch '[A-Z]' -and $m.Value -notmatch '^[A-Z][a-zA-Z0-9]*\(') { continue }
        if ($m.Value.Contains('.') -and $m.Value.Length -gt $bestScore) {
            $best      = $m.Value
            $bestScore = $m.Value.Length
        }
    }

    if ($best -ne "") {
        $normalised = $best -replace '\(\)', '' -replace '\[\d*\]', '' -replace '\[\]', ''
        $normalised = $normalised.ToLower().Trim('.')

        # Strip 'transactionrequest.' variable-name prefix — it is never a canonical root;
        # the canonical roots are 'transaction', 'merchantcontext', 'routingheader', etc.
        if ($normalised -match '^transactionrequest\.(.+)$') { $normalised = $Matches[1] }

        # Strip other known request-wrapper variable prefixes that aren't canonical roots
        if ($normalised -match '^settlementrequest\.((?:merchantcontext|transaction|routingheader).*)$') {
            $normalised = $Matches[1]
        }

        # Collapse consecutive identical segments (e.g. transactionresponse.transactionresponse.x)
        $segs   = $normalised -split '\.'
        [string[]] $deduped = @($segs[0])
        for ($i = 1; $i -lt $segs.Length; $i++) {
            if ($segs[$i] -ne $segs[$i - 1]) { $deduped += $segs[$i] }
        }
        $normalised = $deduped -join '.'

        return Remove-JavaNoiseSuffix $normalised
    }

    # --- Attempt 2: chain from the matched class's own camelName ---
    # Handles patterns like: t.agreementData().firstTransactionOfAgreement().amount()
    # where 't' is a Transaction alias and the chain doesn't start with a root word.
    if ($CamelName -ne '') {
        $ccEsc = [regex]::Escape($CamelName)
        # Require at least one further segment after the camelName
        # Trailing \b prevents 'acquirer' matching inside 'acquirerCustomFields', etc.
        $subChainRegex = [regex]("(?i)\b$ccEsc\b(?:\(\))?(?:\.(?:[a-zA-Z_]\w*)(?:\(\))?(?:\[\d*\]|\[\])?)+")
        $bestSub = ''; $bestSubLen = 0
        foreach ($sm in $subChainRegex.Matches($RawLine)) {
            # Skip PascalCase static refs (e.g. TransactionResponse.ResponseCode.APPROVED).
            # Keep constructor chains (e.g. new TransactionResponse().sourceTransactionId()).
            if ($sm.Value[0] -cmatch '[A-Z]' -and $sm.Value -notmatch '^[A-Z][a-zA-Z0-9]*\(') { continue }
            if ($sm.Value.Length -gt $bestSubLen) { $bestSub = $sm.Value; $bestSubLen = $sm.Value.Length }
        }
        if ($bestSub -ne '') {
            # Strip leading camelName (and optional ()) to get sub-chain: .field1().field2()
            $subChain = $bestSub -replace "(?i)^$ccEsc(\(\))?", ''
            $subChain = ($subChain -replace '\(\)', '' -replace '\[\d*\]', '' -replace '\[\]', '').ToLower().Trim('.')
            $subChain = Remove-JavaNoiseSuffix $subChain
            if ($PathPrefix -ne '' -and $subChain -ne '') { return "$PathPrefix.$subChain" }
            if ($PathPrefix -ne '')                       { return $PathPrefix }
            return $subChain
        }
    }

    # --- Attempt 3: ClassName::methodName method-reference (e.g. Merchant::name) ---
    $methodRefMatch = [regex]::Match($RawLine, '(?<cls>[A-Z][a-zA-Z0-9_]+)::(?<method>[a-zA-Z_]\w*)')
    if ($methodRefMatch.Success) {
        $refMethod = $methodRefMatch.Groups['method'].Value.ToLower()
        if ($PathPrefix -ne '') { return "$PathPrefix.$refMethod" }
        return $refMethod
    }

    # --- Attempt 4: static enum ref ClassName.EnumValue (e.g. Transaction.CardType.VISA) ---
    $staticRefMatch = [regex]::Match($RawLine, '(?<cls>[A-Z][a-zA-Z0-9_]+)\.(?<inner>[A-Z][a-zA-Z0-9_]+)')
    if ($staticRefMatch.Success) {
        $inner = $staticRefMatch.Groups['inner'].Value.ToLower()
        if ($PathPrefix -ne '') { return "$PathPrefix.$inner" }
        return $inner
    }

    # --- Fallback: pathPrefix + methodName ---
    if ($PathPrefix -ne '' -and $MethodName -ne '') { return "$PathPrefix.$($MethodName.ToLower())" }
    if ($PathPrefix -ne '') { return $PathPrefix }
    if ($MethodName -ne '')  { return $MethodName.ToLower() }
    return ""
}

function Get-MatchingClassEntry {
    param([string] $Line, $ClassMap)
    # Return the entry whose camelName appears deepest (most specific) in the chain
    $bestEntry = $null
    $bestPos   = -1
    foreach ($key in $ClassMap.Keys) {
        $entry = $ClassMap[$key]
        $cn    = $entry.ClassName
        $cc    = $entry.CamelName
        # Build patterns with word boundaries to prevent 'merchant' matching inside 'subMerchant',
        # 'acquirer' inside 'acquirerCustomFields', etc.
        [string[]] $pats = @(
            ('\b' + $([regex]::Escape($cc)) + '\b\(\)\.'),
            ('\b' + $([regex]::Escape($cc)) + '\b\.'),
            ('\b' + $([regex]::Escape($cn)) + '\b::')
        )
        foreach ($pat in $pats) {
            $m = [regex]::Match($Line, '(?i)' + $pat)   # case-insensitive, same as Select-String default
            if ($m.Success -and $m.Index -gt $bestPos) {
                $bestPos   = $m.Index
                $bestEntry = $entry
            }
        }
    }
    return $bestEntry
}

function Get-MatchingMethodName {
    param([string] $Line, [hashtable] $ClassEntry)
    if ($null -eq $ClassEntry) { return "" }
    foreach ($method in $ClassEntry.Methods) {
        if ($Line -match "\.$([regex]::Escape($method))\(\)" -or
            $Line -match "\.$([regex]::Escape($method))(?!\w)") {
            return $method
        }
    }
    return ""
}

# ---------------------------------------------------------------------------
# Phase 5 – Build result rows and write single consolidated CSV
# ---------------------------------------------------------------------------

Write-Phase 5 "Building result set and writing consolidated CSV"

$results = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($match in $allMatches) {
    $line = $match.RawLine.Trim()

    # Skip import statements, package declarations, pure comment lines,
    # and @Property annotations — these are not meaningful field usages.
    if ($line -match '^\s*(import\s|package\s)' -or
        $line -match '^\s*(//|/\*|\*)' -or
        $line -match '^\s*@Property\b') {
        continue
    }

    $classEntry      = Get-MatchingClassEntry -Line $line -ClassMap $classMap
    $modelClass      = if ($null -ne $classEntry) { $classEntry.ClassName } else { "Unknown" }
    $pathPrefix      = if ($null -ne $classEntry) { $classEntry.PathPrefix } else { "" }
    $camelName       = if ($null -ne $classEntry) { $classEntry.CamelName  } else { "" }
    $methodName      = Get-MatchingMethodName -Line $line -ClassEntry $classEntry
    $fieldName       = Get-NormalizedFieldName -RawLine $line -PathPrefix $pathPrefix -MethodName $methodName -CamelName $camelName
    $sourceClassName = [IO.Path]::GetFileNameWithoutExtension($match.FilePath)

    $validationStatus = if ($script:ConventionSet.Count -eq 0) { 'UNCHECKED' }
                        elseif ($fieldName -eq '')              { 'EMPTY' }
                        elseif ($script:ConventionSet.Contains($fieldName)) { 'VALID' }
                        else                                    { 'NOT_IN_CONVENTIONS' }

    $results.Add([pscustomobject]@{
        FieldName        = $fieldName
        ValidationStatus = $validationStatus
        ClassName        = $sourceClassName
        ModelClass       = $modelClass
        LineContent      = $line
        LineNo           = $match.LineNo
        FilePath         = $match.FilePath
        RepoName         = $match.RepoName
    })
}

Write-Ok "$($results.Count) result rows assembled."

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Info "Created output directory: $OutputDir"
}

# ---- Single consolidated CSV ----
$csvFileName = ($repoName.ToLower() -replace '[^a-z0-9]+', '_').Trim('_') + "_${timestamp}.csv"
$csvPath = Join-Path $OutputDir $csvFileName
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Ok "CSV written: $csvPath"

# ---- Summary ----
Write-Phase 0 "Summary"
Write-Host ""
Write-Host "  Repo scanned       : $repoName"                   -ForegroundColor White
Write-Host "  Model classes      : $($classMap.Count)"          -ForegroundColor White
Write-Host "  Total matches      : $($results.Count)"           -ForegroundColor White
Write-Host "  Classes with hits  : $(($results | Where-Object { $_.ModelClass -ne 'Unknown' } | Select-Object -Unique ModelClass | Measure-Object).Count)" -ForegroundColor White
Write-Host "  Unique FieldNames  : $(($results | Where-Object { $_.FieldName -ne '' } | Select-Object -Unique FieldName | Measure-Object).Count)" -ForegroundColor White
Write-Host ""
if ($script:ConventionSet.Count -gt 0) {
    $validCount   = ($results | Where-Object { $_.ValidationStatus -eq 'VALID' } | Measure-Object).Count
    $invalidCount = ($results | Where-Object { $_.ValidationStatus -eq 'NOT_IN_CONVENTIONS' } | Measure-Object).Count
    $emptyCount   = ($results | Where-Object { $_.ValidationStatus -eq 'EMPTY' } | Measure-Object).Count
    Write-Host "  Validation (rows)  : VALID=$validCount  NOT_IN_CONVENTIONS=$invalidCount  EMPTY=$emptyCount" -ForegroundColor Cyan
    $uniqueValid   = ($results | Where-Object { $_.ValidationStatus -eq 'VALID' }   | Select-Object -Unique FieldName | Measure-Object).Count
    $uniqueInvalid = ($results | Where-Object { $_.ValidationStatus -eq 'NOT_IN_CONVENTIONS' } | Select-Object -Unique FieldName | Measure-Object).Count
    Write-Host "  Validation (unique): VALID=$uniqueValid  NOT_IN_CONVENTIONS=$uniqueInvalid" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "  Output CSV         : $csvPath"                    -ForegroundColor Green
Write-Host ""

# Print a quick top-10 table by source file class
Write-Host "  Top source classes by hit count:" -ForegroundColor Cyan
$results | Group-Object ClassName |
    Sort-Object Count -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        Write-Host ("    {0,-45} {1,5} hits" -f $_.Name, $_.Count) -ForegroundColor White
    }

# Print top model classes too
Write-Host ""
Write-Host "  Top model classes by hit count:" -ForegroundColor Cyan
$results | Group-Object ModelClass |
    Sort-Object Count -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        Write-Host ("    {0,-45} {1,5} hits" -f $_.Name, $_.Count) -ForegroundColor White
    }

# Print sample FieldNames from each top class
Write-Host ""
Write-Host "  Sample FieldNames (unique, sorted):" -ForegroundColor Cyan
$results | Where-Object { $_.FieldName -ne '' } |
    Select-Object -ExpandProperty FieldName |
    Select-Object -Unique |
    Sort-Object |
    Select-Object -First 20 |
    ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

Write-Host ""
Write-Ok "Done."
