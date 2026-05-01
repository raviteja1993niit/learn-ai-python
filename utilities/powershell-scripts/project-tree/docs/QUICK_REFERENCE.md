# Quick Reference Guide: Dynamic Repository Path Scripts

## At a Glance

The `run-generate-tree.bat` and `generate-tree.ps1` scripts have been refactored to accept dynamic repository paths.

**Old Way**: `run-generate-tree.bat [MaxDepth] [OutFile]` (from project root)  
**New Way**: `run-generate-tree.bat [RepoPath] [MaxDepth] [OutFile]` (from anywhere)

---

## Common Commands

### Most Common Use Cases

```batch
REM Generate tree for current directory
run-generate-tree.bat

REM Generate tree with depth limit
run-generate-tree.bat 3

REM Generate tree for any repository
run-generate-tree.bat C:\path\to\repo

REM Generate tree for any repo with depth limit
run-generate-tree.bat C:\path\to\repo 2

REM Full specification
run-generate-tree.bat C:\path\to\repo 3 output.txt
```

---

## Syntax Reference

```
run-generate-tree.bat [RepoPath] [MaxDepth] [OutFile]

RepoPath    - (Optional) Path to repository
              • Absolute: C:\path\to\repo
              • Relative: ..\other-repo
              • Default: Current directory (%CD%)

MaxDepth    - (Optional) Maximum recursion depth
              • Numeric value (2, 3, 5, etc.)
              • Default: Unlimited (-1)

OutFile     - (Optional) Output file path
              • Default: RepoPath\project-tree.txt
```

---

## Smart Parameter Detection

The script intelligently detects what the first argument is:

| If First Argument | Action |
|-------------------|--------|
| Contains `:` | Treated as path (drive letter like `C:`) |
| Contains `\` or `/` | Treated as path (path separator) |
| Exists as directory | Treated as path (filesystem check) |
| Numeric value | Treated as MaxDepth (backward compatible) |
| Nothing | Uses current directory (backward compatible) |

**Examples**:
```batch
run-generate-tree.bat 2
  → Current dir, MaxDepth=2 (backward compatible)

run-generate-tree.bat C:\repo
  → C:\repo, no depth limit (detected as path)

run-generate-tree.bat C:\repo 2
  → C:\repo, MaxDepth=2 (detected as path)
```

---

## All Possible Invocations

| Command | RepoPath | MaxDepth | OutFile |
|---------|----------|----------|---------|
| `run-generate-tree.bat` | Current | -1 | repo\project-tree.txt |
| `run-generate-tree.bat 3` | Current | 3 | repo\project-tree.txt |
| `run-generate-tree.bat 3 out.txt` | Current | 3 | out.txt |
| `run-generate-tree.bat C:\repo` | C:\repo | -1 | C:\repo\project-tree.txt |
| `run-generate-tree.bat C:\repo 2` | C:\repo | 2 | C:\repo\project-tree.txt |
| `run-generate-tree.bat C:\repo 2 out.txt` | C:\repo | 2 | out.txt |

---

## Real-World Examples

### Example 1: Generate tree for current project
```batch
cd C:\MyProject
run-generate-tree.bat
REM Output: C:\MyProject\project-tree.txt
```

### Example 2: Generate shallow tree for analysis
```batch
run-generate-tree.bat C:\MyProject 2
REM Output: C:\MyProject\project-tree.txt (depth=2)
```

### Example 3: Generate tree for multiple repos
```batch
run-generate-tree.bat C:\Repo1 3 repo1-tree.txt
run-generate-tree.bat C:\Repo2 3 repo2-tree.txt
REM Outputs: repo1-tree.txt, repo2-tree.txt
```

### Example 4: Generate tree from any location
```batch
REM From C:\Work
run-generate-tree.bat C:\Projects\elavon-service 2 elavon-tree.txt
REM Output: C:\Work\elavon-tree.txt
```

### Example 5: Using relative paths
```batch
REM From C:\MyProjects
run-generate-tree.bat .\sub-project 1 tree.txt
REM Resolved to: C:\MyProjects\sub-project
REM Output: C:\MyProjects\tree.txt
```

---

## Error Handling

| Scenario | Output | Exit Code |
|----------|--------|-----------|
| Valid path | Generates tree successfully | 0 |
| Invalid path | `Error: RepoPath does not exist: "..."` | 1 |
| Missing PS script | PowerShell error | 1 |
| Permission denied | Windows access denied error | 1 |

---

## Direct PowerShell Usage

If you prefer calling PowerShell directly:

```powershell
# Default (current directory, no limit)
powershell -NoProfile -ExecutionPolicy Bypass -File ".\generate-tree.ps1"

# With custom path and depth
powershell -NoProfile -ExecutionPolicy Bypass -File ".\generate-tree.ps1" `
  -TargetPath "C:\path\to\repo" `
  -MaxDepth 3 `
  -OutFile "tree.txt"
```

---

## Output Format

The generated tree uses ASCII characters:

```
C:\path\to\repo
|-- folder1
|   |-- subfolder1
|   |   +-- file.txt
|   +-- file.txt
+-- folder2
    +-- file.txt
```

Excluded by default:
- `target/` (Maven build)
- `.git/` (Git repository)
- `node_modules/` (Node.js packages)

---

## Troubleshooting

### "Error: RepoPath does not exist"
**Cause**: Path doesn't exist or can't be found  
**Solution**: Check the path spelling and ensure it exists

```batch
REM ❌ Wrong
run-generate-tree.bat C:\Repoository

REM ✅ Correct
run-generate-tree.bat C:\Repository
```

### Script not found
**Cause**: PowerShell script (`generate-tree.ps1`) not in same directory  
**Solution**: Ensure both files are in same directory

### Unexpected results with first argument
**Cause**: Script misinterpreted numeric string as MaxDepth  
**Solution**: Provide explicit path with separators

```batch
REM ❌ Ambiguous
run-generate-tree.bat 2

REM ✅ Clear
run-generate-tree.bat 2 output.txt
run-generate-tree.bat . 2
```

---

## Help & Documentation

View full PowerShell help:
```powershell
Get-Help .\generate-tree.ps1 -Full
```

This displays:
- Complete parameter descriptions
- 6 detailed usage examples
- Notes on implementation details

---

## Backward Compatibility

✅ **100% Backward Compatible**

All old commands still work:
```batch
# These all still work exactly as before:
run-generate-tree.bat
run-generate-tree.bat 3
run-generate-tree.bat 3 myfile.txt
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Repo Path** | First argument, optional, any location |
| **Max Depth** | Second argument, optional, numeric |
| **Output File** | Third argument, optional, defaults to repo\project-tree.txt |
| **Smart Detection** | Auto-detects if first arg is path or parameter |
| **Backward Compatible** | 100% - old usage patterns still work |
| **Error Handling** | Clear messages on invalid paths |
| **Performance** | Instant tree generation |

---

**Last Updated**: April 13, 2026  
**Version**: 1.0 (Post-Refactoring)

