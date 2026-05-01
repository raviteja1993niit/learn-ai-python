<#
.SYNOPSIS
Generate a hierarchical tree view of a folder (files + folders) using pure PowerShell.

.DESCRIPTION
This script prints a tree-like structure for the specified target path. It is pure PowerShell (no external tools) and supports:
- dynamic repository path selection
- excluding common large folders
- limiting recursion depth
- writing output to a file or to stdout

.PARAMETER TargetPath
Path to print. Defaults to the current working directory when invoked.
Can be an absolute path (e.g., "C:\path\to\repo") or relative path (e.g., ".").

.PARAMETER MaxDepth
Maximum recursion depth. -1 for unlimited (default). Use numeric values like 2, 3, 5, etc.

.PARAMETER Exclude
Array of file or folder names to exclude (basename match, case-insensitive).
Default: 'target', '.git', 'node_modules'

.PARAMETER OutFile
If specified, writes output to the given path (UTF8). Otherwise prints to console.
Defaults to OutFile path when not provided.

.EXAMPLE
# Using the batch wrapper from the script's directory (uses current directory)
run-generate-tree.bat

.EXAMPLE
# Using the batch wrapper with a specific repo path
run-generate-tree.bat "C:\path\to\repo"

.EXAMPLE
# Using the batch wrapper with repo path and max depth
run-generate-tree.bat "C:\path\to\repo" 3

.EXAMPLE
# Using the batch wrapper with all parameters
run-generate-tree.bat "C:\path\to\repo" 3 "output.txt"

.EXAMPLE
# Direct PowerShell invocation with default location
powershell -NoProfile -ExecutionPolicy Bypass -File ".\generate-tree.ps1"

.EXAMPLE
# Direct PowerShell invocation with explicit repo path
powershell -NoProfile -ExecutionPolicy Bypass -File ".\generate-tree.ps1" -TargetPath "C:\path\to\repo" -MaxDepth 3 -OutFile "tree.txt"
#
# Copyright: utility script - no sensitive data is printed by design (it lists filenames only).
#
# Notes:
# - The batch wrapper `run-generate-tree.bat` intelligently detects whether the first argument is a repo path
#   (by checking for path separators, drive letters, or filesystem existence) or shifts to MaxDepth if not.
# - This allows backward-compatible usage: run-generate-tree.bat [RepoPath] [MaxDepth] [OutFile]
# - When no RepoPath is provided, the batch wrapper defaults to the current working directory.
#
# / End header
#>
param(
    [Parameter(Position=0)]
    [string]
    $TargetPath = '.',

    [int]
    $MaxDepth = -1,

    [string[]]
    $Exclude = @('target', '.git', 'node_modules'),

    [string]
    $OutFile = ''
)

function Write-Log {
    param([string]$Message)
    # Use Write-Host so output remains readable when piping/redirecting. Keep minimal formatting.
    Write-Host $Message
}

try {
    $resolved = Resolve-Path -LiteralPath $TargetPath -ErrorAction Stop
    $root = $resolved.Path
} catch {
    Write-Error "TargetPath '$TargetPath' does not exist or cannot be resolved."
    exit 2
}

# Normalise exclude names to lower-case for comparisons
$excludeSet = $Exclude | ForEach-Object { $_.ToLowerInvariant() }

$lines = [System.Collections.Generic.List[string]]::new()

function Add-Line {
    param([string]$text)
    [void]$lines.Add($text)
}

function Print-Tree {
    param(
        [string]$Path,
        [string]$Prefix = '',
        [int]$Depth = 0
    )

    if (($MaxDepth -ge 0) -and ($Depth -gt $MaxDepth)) { return }

    try {
        $children = Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop | Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name
    } catch {
        Add-Line("$Prefix[ACCESS DENIED] $(Split-Path -Leaf $Path)")
        return
    }

    for ($i = 0; $i -lt $children.Count; $i++) {
        $entry = $children[$i]
        $isLast = ($i -eq $children.Count - 1)
        # Use ASCII connectors to avoid Unicode/encoding issues on Windows PowerShell
        $connector = if ($isLast) { '+-- ' } else { '|-- ' }
        $name = $entry.Name
        # Skip excluded basenames (case-insensitive)
        if ($excludeSet -contains $name.ToLowerInvariant()) { continue }

        Add-Line("$Prefix$connector$name")

        if ($entry.PSIsContainer) {
            # Use '|' as the vertical continuation marker in the ASCII output
            $nextPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix|   " }
            if (($MaxDepth -lt 0) -or ($Depth -lt $MaxDepth)) {
                Print-Tree -Path $entry.FullName -Prefix $nextPrefix -Depth ($Depth + 1)
            }
        }
    }
}

# Start output
Add-Line($root)
Print-Tree -Path $root -Prefix '' -Depth 0

# Sanitize OutFile in case caller passed embedded quotes like \"C:\path\to\file\" or leading backslashes
if ($OutFile -and $OutFile.Trim() -ne '') {
    $OutFile = $OutFile.Trim()

    # Iteratively remove leading quote/backslash characters
    while ($OutFile.Length -gt 0 -and ( $OutFile[0] -eq '"' -or $OutFile[0] -eq "'" -or $OutFile[0] -eq '\\' )) {
        $OutFile = $OutFile.Substring(1)
    }

    # Iteratively remove trailing quote/backslash characters
    while ($OutFile.Length -gt 0 -and ( $OutFile[-1] -eq '"' -or $OutFile[-1] -eq "'" -or $OutFile[-1] -eq '\\' )) {
        $OutFile = $OutFile.Substring(0, $OutFile.Length - 1)
    }

    # As a safety, if there's still a leading backslash before a drive letter (e.g. \C:\), remove leading backslashes
    while ($OutFile -match '^[\\]+(?=[A-Za-z]:)') {
        $OutFile = $OutFile.TrimStart('\')
    }
}

if ($OutFile -and $OutFile.Trim() -ne '') {
    try {
        $outDir = Split-Path -Path $OutFile -Parent
        if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
        $lines | Out-File -FilePath $OutFile -Encoding utf8 -Force
        Write-Log "Wrote tree to: $OutFile"
    } catch {
        Write-Error "Failed to write OutFile '$OutFile': $_"
        exit 3
    }
} else {
    # Print to console
    foreach ($l in $lines) { Write-Log $l }
}
