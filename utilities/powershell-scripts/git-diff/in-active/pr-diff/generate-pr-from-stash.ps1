param(
    [string] $StashRef = 'stash@{0}',
    [string] $TempBranchPrefix = 'pr/',
    [switch] $AutoCommit = $false
)

function Timestamp { return (Get-Date).ToString('yyyyMMdd-HHmmss') }

function New-UniqueBranchName($prefix) {
    for ($i = 0; $i -lt 10; $i++) {
        $candidate = "$prefix" + "temp-" + [System.Guid]::NewGuid().ToString('N').Substring(0,8) + "-$(Timestamp)"
        # check if branch exists
        git show-ref --verify --quiet "refs/heads/$candidate"
        if ($LASTEXITCODE -ne 0) { return $candidate }
    }
    throw "Failed to generate a unique branch name after multiple attempts"
}

$branch = New-UniqueBranchName $TempBranchPrefix
Write-Host "Preparing branch: $branch"

# Check if stash exists
$stashList = git stash list 2>$null
$stashExists = $false
if ($stashList) {
    if ($stashList -match [regex]::Escape($StashRef.Split('{')[0])) { $stashExists = $true }
    elseif ($stashList -match [regex]::Escape($StashRef)) { $stashExists = $true }
}

# Create branch from current HEAD (safe)
Write-Host "Creating new branch: $branch"
git checkout -b $branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create branch $branch. Aborting." -ForegroundColor Red
    exit 1
}

$appliedStash = $false
if ($stashExists) {
    Write-Host "Found stash list; attempting to apply stash $StashRef onto $branch (non-destructive fallback enabled)"
    # Try 'git stash apply' (do not rely on git stash branch which may try to adjust index)
    git stash apply --index $StashRef 2>&1 | Tee-Object -Variable stashOut
    if ($LASTEXITCODE -eq 0) {
        $appliedStash = $true
        Write-Host "Stash applied successfully to $branch"
    }
    else {
        Write-Host "Warning: failed to apply stash (output below). We'll proceed using the working-tree changes to generate a PR draft." -ForegroundColor Yellow
        Write-Host $stashOut
        Write-Host "If you want the stash applied, please resolve local index conflicts or run: git stash branch <new-branch> $StashRef" -ForegroundColor Yellow
    }
}
else {
    Write-Host "No stash found or stash list empty — proceeding using current working-tree changes."
}

# Collect changed files (include staged and unstaged changes)
# Use union of 'git diff --name-only HEAD' and 'git ls-files -m'
$diffFiles = @()
$headDiff = git diff --name-only HEAD
if ($headDiff) { $diffFiles += $headDiff }
$modified = git ls-files -m
if ($modified) { $diffFiles += $modified }
$diffFiles = $diffFiles | Select-Object -Unique

if (-not $diffFiles -or $diffFiles.Count -eq 0) {
    Write-Host "No changed files detected on branch $branch. Exiting." -ForegroundColor Cyan
    exit 0
}

# Group by top-level folder or file extension
$groups = @{}
foreach ($f in $diffFiles) {
    $top = if ($f -match '[\\/]') { ($f -split '[\\/]')[0] } else { $f }
    if (-not $groups.ContainsKey($top)) { $groups[$top] = @() }
    $groups[$top] += $f
}

function Choose-CommitType($fileList) {
    if ($fileList -match '\.md$' -or $fileList -match '\.adoc$') { return 'docs' }
    if ($fileList -match '\b(src[/\\]test|/test/)\b') { return 'test' }
    if ($fileList -match '\.java$') { return 'refactor' }
    if ($fileList -match '\.yml$' -or $fileList -match '\.yaml$') { return 'chore' }
    return 'chore'
}

$commitMessages = @()
foreach ($g in $groups.Keys) {
    $flist = $groups[$g]
    $type = Choose-CommitType(($flist -join ' '))
    $scope = $g -replace '[\\/:*?<>|]','' -replace '\s+','-'
    $summaryFiles = ($flist | ForEach-Object { Split-Path $_ -Leaf }) -join ', '
    $summary = "$type($scope): update $summaryFiles"

    $bodyLines = @()
    $bodyLines += "Files:"
    $bodyLines += ($flist | ForEach-Object { '- ' + $_ })
    $bodyLines += "`nSuggested tests: run module unit tests or 'mvn -DskipTests package'"

    $commitMessages += [pscustomobject]@{ Type=$type; Scope=$scope; Summary=$summary; Body = ($bodyLines -join "`n") }
}

# Ensure PR descriptions dir exists
$prDir = '.git/pr-descriptions'
if (-not (Test-Path $prDir)) { New-Item -ItemType Directory -Force -Path $prDir | Out-Null }
$prFile = "$prDir/pr-$($branch)-$(Timestamp).md"

$prText = @()
$prText += "# PR Draft for branch $branch"
$prText += "\n## Summary"
$prText += "Auto-generated PR description (source: " + (if ($appliedStash) { $StashRef } else { 'working-tree' }) + ")"
$prText += "\n## Commits"
foreach ($c in $commitMessages) {
    $prText += "\n- **$($c.Summary)**"
    $prText += "\n```\n$($c.Body)\n```\n"
}
$prText += "\n## Quick QA"
$prText += "- mvn -DskipTests package"
$prText += "- Run module-specific unit tests"
$prText += "\n## Notes"
$prText += "- The branch was created locally: $branch"
$prText += "- If stash apply failed, please resolve conflicts or apply the stash manually before committing."

$prText | Out-File -FilePath $prFile -Encoding utf8
Write-Host "PR draft saved to: $prFile"

if ($AutoCommit) {
    foreach ($c in $commitMessages) {
        git add --all
        git commit -m $c.Summary -m $c.Body
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Commit failed for: $($c.Summary). Please inspect working tree." -ForegroundColor Red
            break
        }
    }
    Write-Host 'Committed all suggested commits (if no errors reported)'
} else {
    Write-Host "AutoCommit not set; please review changes and use the suggested messages in: $prFile"
}

Write-Host "When ready: git push -u origin $branch && create PR using your preferred tool (GitHub/GitLab CLI)"
