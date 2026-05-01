# GitHub Copilot Instructions for Code Change Documentation

## Purpose
This file provides standardized instructions for GitHub Copilot to generate comprehensive Confluence-style documentation for code changes between Git branches.

---

## Core Instruction Set

### 1. Initial Context Gathering

When asked to generate documentation for code changes, follow these steps:

```
STEP 1: Identify Branches
- Ask user for source branch (base) and target branch (feature)
- If not provided, detect current branch and ask for comparison branch
- Verify both branches exist using: git branch -a

STEP 2: Gather Change Statistics
- Execute: git diff <source>..<target> --shortstat
- Execute: git diff <source>..<target> --name-status
- Execute: git log <source>..<target> --oneline
- Count: Total files changed, insertions, deletions

STEP 3: Categorize Changes
- NEW FILES (A): Files added in target branch
- MODIFIED FILES (M): Files changed between branches
- DELETED FILES (D): Files removed in target branch
- RENAMED FILES (R): Files moved or renamed
```

---

### 2. Documentation Structure Template

Generate documentation following this exact structure:

```markdown
# [Feature Name]: [Brief Description]

## Document Information
| Property | Value |
|----------|-------|
| Story ID | [JIRA/Story ID] |
| Story Title | [Full Story Title] |
| Base Branch | [Source Branch Name] |
| Feature Branch | [Target Branch Name] |
| Author | [Development Team/Author] |
| Date | [Current Date] |
| Total Changes | X files changed, Y insertions(+), Z deletions(-) |

## 1. Executive Summary
[2-3 paragraphs summarizing the changes and their purpose]

### Key Highlights:
- ✅ [Major change 1]
- ✅ [Major change 2]
- ✅ [Major change 3]

## 2. Architectural Overview
[Diagrams and high-level architecture changes]

## 3. Detailed Changes Analysis
[File-by-file analysis of changes]

## 4. Key Classes Implementation
[Top 10-15 most important classes with code snippets]

## 5. Technical Implementation
[Implementation patterns, frameworks, APIs used]

## 6. Dependencies and Configuration
[New dependencies, version updates, configuration changes]

## 7. Testing Strategy
[Test coverage, test scenarios, testing approach]

## 8. Benefits and Impact
[Business value, technical improvements]

## 9. Commit History
[Chronological commit log with descriptions]

## 10. File Summary
[Complete list of new/modified/deleted files]

## 11. Next Steps and Recommendations
[Future work, follow-up tasks]

## 12. Risks and Mitigations
[Potential issues and solutions]

## 13. References
[Links to related documentation]

## 14. Appendix
[Code examples, configuration samples, commands]
```

---

### 3. Code Class Analysis Rules

For each important class, provide:

```markdown
### X.Y ClassName.java

**Location:** `full/package/path/ClassName.java`

**Code Structure:**
```java
[3-20 lines of actual code showing key methods]
```

**Purpose & Necessity:**
- **[Aspect 1]:** [Detailed explanation in 1-2 sentences]
- **[Aspect 2]:** [Why this change is necessary]
- **[Aspect 3]:** [How it integrates with system]
- **[Aspect 4]:** [Technical implementation details]
```

**Selection Criteria for Key Classes:**
1. New classes that introduce major functionality
2. Classes with >50 lines of changes
3. Classes that change core business logic
4. Classes that modify API/interfaces
5. Configuration classes
6. Test infrastructure classes
7. Classes that fix critical bugs
8. Classes that improve performance
9. Classes that enhance security
10. Classes that add new integrations

---

### 4. Diff Analysis Commands

Use these Git commands systematically:

```bash
# Get list of changed files with status
git diff <source>..<target> --name-status

# Get detailed diff for specific file
git diff <source>..<target> -- "path/to/file"

# Get file content from specific branch
git show <branch>:path/to/file

# Get commit messages between branches
git log <source>..<target> --oneline --no-merges

# Get detailed commit info
git log <source>..<target> --pretty=format:"%h - %an, %ar : %s"

# Get changed files with line statistics
git diff <source>..<target> --stat

# Get numeric summary
git diff <source>..<target> --shortstat

# Get list of authors
git log <source>..<target> --format='%aN' | sort -u
```

---

### 5. File Categorization Logic

Categorize files into these groups:

**New Modules/Packages:**
- Identify entirely new directory structures
- Document module purpose and responsibilities
- List key classes in module

**Configuration Files:**
- pom.xml, build.gradle
- application.yml, application.properties
- Dockerfile, docker-compose.yml
- Jenkins files, CI/CD configs

**Source Code:**
- Controllers, Services, Repositories
- Models, DTOs, Entities
- Utilities, Helpers, Constants
- Mappers, Converters

**Test Code:**
- Unit tests (*Test.java)
- Integration tests (*IT.java)
- Test utilities and helpers
- Test data and fixtures

**Documentation:**
- README files
- API documentation
- Configuration guides

---

### 6. Change Impact Analysis

For each change, analyze:

```
1. SCOPE
   - Which layers affected? (Controller, Service, Repository, etc.)
   - Which modules impacted?
   - Dependencies affected?

2. BREAKING CHANGES
   - API signature changes?
   - Configuration changes required?
   - Database schema changes?
   - Backward compatibility issues?

3. SECURITY IMPLICATIONS
   - Authentication/Authorization changes?
   - Data validation added/removed?
   - Encryption/security enhancements?

4. PERFORMANCE IMPACT
   - Algorithm improvements?
   - Caching changes?
   - Database query optimization?
   - Resource usage changes?

5. TESTING REQUIREMENTS
   - New test cases needed?
   - Existing tests affected?
   - Integration test updates?
```

---

### 7. Documentation Quality Standards

Ensure documentation meets these criteria:

**Completeness:**
- [ ] All changed files documented
- [ ] Key classes explained with code examples
- [ ] Commit history included
- [ ] Dependencies listed
- [ ] Configuration changes noted

**Clarity:**
- [ ] Technical jargon explained
- [ ] Clear section headings
- [ ] Logical flow of information
- [ ] Code examples are syntactically correct
- [ ] Diagrams included where helpful

**Accuracy:**
- [ ] Code snippets match actual implementation
- [ ] File paths are correct
- [ ] Version numbers accurate
- [ ] Links and references valid

**Actionability:**
- [ ] Next steps clearly defined
- [ ] Setup instructions provided
- [ ] Testing instructions included
- [ ] Troubleshooting guidance given

---

### 8. Code Snippet Extraction Rules

When extracting code snippets:

1. **Length:** 3-20 lines per snippet
2. **Focus:** Show key methods/logic, not entire class
3. **Context:** Include method signatures and key fields
4. **Formatting:** Proper indentation and syntax
5. **Completeness:** Include necessary imports in description

**Example Format:**
```java
public class ExampleService {
    // ...existing fields...
    
    @Autowired
    private DependencyService dependencyService;
    
    public ResponseDTO processRequest(RequestDTO request) {
        // Validate input
        validateRequest(request);
        
        // Transform data
        Entity entity = mapper.toEntity(request);
        
        // Persist
        return repository.save(entity);
    }
    
    // ...additional methods...
}
```

---

### 9. Markdown Formatting Standards

Use consistent Markdown formatting:

```markdown
# Main Title (H1) - Document title only
## Section (H2) - Major sections
### Subsection (H3) - Subsections
#### Minor heading (H4) - Details

**Bold** - Emphasis, file names, class names
*Italic* - Terms, references
`code` - Inline code, commands, variables
```code blocks``` - Multi-line code

> Blockquotes - Important notes, warnings

- Bullet lists - Features, changes
1. Numbered lists - Steps, procedures

| Tables | For structured data |

[Links](url) - External references
![Images](url) - Diagrams, screenshots

---

Horizontal rules - Section separators

✅ ⬜ - Checkboxes for status
🎯 📋 🔍 - Icons for visual appeal
```

---

### 10. Automation Workflow

Follow this workflow for documentation generation:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER INPUT: Provide source and target branches          │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│ 2. GIT ANALYSIS: Execute git diff/log commands             │
│    - Get changed files list                                 │
│    - Get commit history                                     │
│    - Calculate statistics                                   │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│ 3. FILE CATEGORIZATION: Group files by type                │
│    - New files (A)                                          │
│    - Modified files (M)                                     │
│    - Deleted files (D)                                      │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│ 4. CONTENT ANALYSIS: Read key files                        │
│    - Extract code snippets                                  │
│    - Identify important classes                             │
│    - Analyze changes                                        │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│ 5. DOCUMENTATION GENERATION: Build markdown document       │
│    - Follow template structure                              │
│    - Include code examples                                  │
│    - Add explanations                                       │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│ 6. QUALITY CHECK: Validate documentation                   │
│    - Check completeness                                     │
│    - Verify formatting                                      │
│    - Validate code syntax                                   │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│ 7. OUTPUT: Generate final .md file                         │
│    - Save to repository root or .github/docs/              │
│    - Name: <STORY_ID>_ANALYSIS_CONFLUENCE_DOC.md           │
└─────────────────────────────────────────────────────────────┘
```

---

### 11. Error Handling

Handle these common scenarios:

**Branch Not Found:**
```
ERROR: Branch '<branch-name>' does not exist.
ACTION: 
1. List available branches: git branch -a
2. Ask user to specify correct branch name
3. Suggest similar branch names if available
```

**No Changes Detected:**
```
ERROR: No differences found between branches.
ACTION:
1. Verify branches are different
2. Check if feature branch is ahead of base
3. Suggest: git merge-base <source> <target>
```

**Large Diff (>100 files):**
```
WARNING: Large number of changes detected (X files).
ACTION:
1. Confirm with user to proceed
2. Focus on most impactful changes
3. Suggest breaking into multiple documents
```

**Binary Files:**
```
WARNING: Binary files detected (images, JARs, etc.)
ACTION:
1. List binary files separately
2. Note in documentation without showing diff
3. Mention file size changes if significant
```

---

### 12. Prompt Templates

#### Template 1: Initial Request
```
I need to generate documentation for code changes between branches:
- Source Branch: [branch-name]
- Target Branch: [branch-name]
- Story ID: [optional]

Please analyze the changes and create comprehensive Confluence documentation.
```

#### Template 2: Focus on Specific Area
```
Generate documentation for [Feature Name] changes between [source] and [target] branches, 
focusing on:
- [Specific package/module]
- [Particular aspect, e.g., security, performance]
- Include detailed analysis of [specific class/file]
```

#### Template 3: Update Existing Documentation
```
Update the existing documentation at [file-path] with:
- New changes from commits [commit-hash-range]
- Focus on [specific area]
- Preserve existing sections: [section names]
```

---

### 13. Output File Naming Convention

Use this naming pattern:

```
<STORY_ID>_<FEATURE_NAME>_ANALYSIS_CONFLUENCE_DOC.md

Examples:
- G1198_16064_FLOW_FRAMEWORK_ANALYSIS_CONFLUENCE_DOC.md
- JIRA-1234_USER_AUTH_ENHANCEMENT_CONFLUENCE_DOC.md
- FEATURE_2024_01_API_REFACTORING_CONFLUENCE_DOC.md

Rules:
- Use UPPERCASE for story ID
- Use UPPERCASE with underscores for feature name
- Keep feature name concise (2-4 words)
- Always end with _ANALYSIS_CONFLUENCE_DOC.md
```

---

### 14. Best Practices Checklist

Before finalizing documentation, verify:

- [ ] **Accuracy**: All code examples compile and match actual code
- [ ] **Completeness**: All significant changes documented
- [ ] **Clarity**: Technical terms explained, no ambiguity
- [ ] **Structure**: Follows standard template
- [ ] **Formatting**: Consistent Markdown, proper tables
- [ ] **Code Quality**: Snippets are well-formatted and relevant
- [ ] **Links**: All references and links are valid
- [ ] **Grammar**: No spelling or grammatical errors
- [ ] **Sections**: All required sections present
- [ ] **Examples**: Sufficient code examples provided
- [ ] **Diagrams**: Architecture diagrams where helpful
- [ ] **Tables**: Used for structured data presentation
- [ ] **Icons**: Used appropriately for visual clarity
- [ ] **Commit History**: Complete and accurate
- [ ] **File Lists**: All files accounted for
- [ ] **Dependencies**: All dependency changes noted
- [ ] **Configuration**: Config changes documented
- [ ] **Testing**: Test approach described
- [ ] **Risks**: Potential issues identified
- [ ] **Next Steps**: Future work outlined
- [ ] **Appendix**: Additional resources provided

---

### 15. Common Patterns to Recognize

**Pattern 1: New Module Creation**
- Multiple new files in same package
- New pom.xml or build file
- README for module
→ Document as "New Module" with overview

**Pattern 2: Refactoring**
- Many modified files, similar line changes
- Class renames, package moves
- Method signature changes
→ Document as "Refactoring" with before/after

**Pattern 3: Feature Addition**
- New classes for feature
- Modified existing classes to integrate
- New tests
→ Document as "Feature Implementation"

**Pattern 4: Bug Fix**
- Few file changes
- Focused modifications
- Added validation or error handling
→ Document as "Bug Fix" with root cause

**Pattern 5: Framework Upgrade**
- Dependency version changes
- API usage updates
- Deprecated method replacements
→ Document as "Framework Upgrade"

**Pattern 6: Test Infrastructure**
- New test utilities
- Test data classes
- Test configuration
→ Document as "Test Framework Enhancement"

---

### 16. Example Usage

**User Request:**
```
Generate documentation for changes between G1198_16002_SIMULATOR_MIGRATE 
and G1198_16064_FLOW_FRAMEWORK_SETUP branches for story G1198_16064
```

**Copilot Response Flow:**
1. Execute git commands to analyze changes
2. Identify 29 files changed (25 new, 4 modified)
3. Recognize pattern: Test Framework Implementation
4. Read key files: ElavonSystemTransactions.java, ProcessingIT.java, etc.
5. Generate documentation following template
6. Include code examples from 10 key classes
7. Add architecture diagram
8. Document dependencies and configuration
9. Create file and save as G1198_16064_FLOW_FRAMEWORK_ANALYSIS_CONFLUENCE_DOC.md
10. Provide summary to user

---

### 17. Advanced Features

**Include Metrics:**
- Code churn (lines added/removed per file)
- Complexity metrics (if available)
- Test coverage changes
- Performance benchmarks

**Generate Diagrams:**
- Sequence diagrams for new flows
- Class diagrams for new modules
- Architecture diagrams for system changes
- Component interaction diagrams

**Link to External Resources:**
- JIRA tickets
- Design documents
- API documentation
- Related PRs

**Version Compatibility:**
- Note Java version requirements
- Spring Boot version compatibility
- Database schema versions
- API version changes

---

### 18. Quality Gates

Documentation must pass these gates:

**Gate 1: Technical Accuracy**
- Code compiles
- Paths exist
- Versions correct

**Gate 2: Completeness**
- All sections present
- Key classes documented
- Dependencies listed

**Gate 3: Readability**
- Clear language
- Logical structure
- Proper formatting

**Gate 4: Actionability**
- Setup instructions clear
- Examples runnable
- Next steps defined

---

## Quick Reference Card

### Essential Commands
```bash
# Compare branches
git diff branch1..branch2 --name-status

# Get commit log
git log branch1..branch2 --oneline

# View file from branch
git show branch:path/to/file

# Get statistics
git diff branch1..branch2 --shortstat
```

### Documentation Trigger Phrases
- "Generate documentation for changes between..."
- "Create Confluence doc for branch comparison..."
- "Document code changes from PR..."
- "Analyze and document feature implementation..."

### Output Quality Indicators
✅ All sections complete
✅ 10+ code examples
✅ Architecture diagram included
✅ Commit history present
✅ Dependencies documented
✅ Testing approach described

---

**Version:** 1.0  
**Last Updated:** January 9, 2026  
**Maintained By:** Development Team

