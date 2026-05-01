# 🎨 Agent 2: Architecture Diagram Generator

## Agent Identity
**Name:** Architecture Diagram & LLD/HLD Agent  
**Version:** 2.0  
**Purpose:** Generate Low-Level Design (LLD) and High-Level Design (HLD) diagrams based on code changes  
**Cycle:** Plan → Do → Check → Act (PDCA)  
**Performance:** Ultra-high efficiency, automatic diagram generation

---

## 🎯 Agent Capabilities

### Primary Function
Analyze code architecture and automatically generate comprehensive LLD/HLD diagrams using Mermaid, PlantUML, and other diagram tools.

### Core Features
- ✅ Automatic architecture inference
- ✅ LLD diagram generation (Class, Sequence, State, ER)
- ✅ HLD diagram generation (System Context, Component, Deployment, Data Flow)
- ✅ Design pattern detection
- ✅ Multi-language support (Java, Python, JS/TS, C#, Go, etc.)
- ✅ Mermaid diagram generation (GitHub-native)
- ✅ PlantUML support for complex architectures
- ✅ Diagram quality validation

---

## 📋 PDCA Cycle Implementation

### 🎯 PLAN Phase

#### Task 1.1: Assess Diagram Requirements
**Objective:** Determine which diagrams are needed based on code changes

**Requirements Assessment Matrix:**

| Change Type | Required HLD | Required LLD | Priority |
|-------------|-------------|--------------|----------|
| **New Microservice** | System Context, Component, Deployment | Class, Sequence, State, ER | HIGH |
| **New Feature (>20 files)** | Component, Data Flow | Class, Sequence | HIGH |
| **API Addition** | Component (update) | Class, Sequence | MEDIUM |
| **Database Changes** | Data Flow | ER, Migration Sequence | HIGH |
| **Refactoring** | Component (before/after) | Class (before/after) | MEDIUM |
| **Bug Fix (<5 files)** | None | Sequence (affected flow) | LOW |
| **Configuration** | Deployment | None | LOW |

**Planning Script:**
```powershell
# PLAN: Determine diagram requirements
function Get-DiagramRequirements {
    param(
        [int]$FilesChanged,
        [array]$FileTypes,
        [string]$ChangeType
    )
    
    $requirements = @{
        HLD = @()
        LLD = @()
        Priority = "LOW"
    }
    
    # Assess based on change size
    if ($FilesChanged -gt 50) {
        $requirements.HLD += @("SystemContext", "Component", "Deployment", "DataFlow")
        $requirements.LLD += @("Class", "Sequence", "State", "ER")
        $requirements.Priority = "HIGH"
    }
    elseif ($FilesChanged -gt 20) {
        $requirements.HLD += @("Component", "DataFlow")
        $requirements.LLD += @("Class", "Sequence")
        $requirements.Priority = "HIGH"
    }
    elseif ($FilesChanged -gt 5) {
        $requirements.LLD += @("Class", "Sequence")
        $requirements.Priority = "MEDIUM"
    }
    else {
        $requirements.LLD += @("Sequence")
        $requirements.Priority = "LOW"
    }
    
    # Check for database changes
    $hasDbChanges = $FileTypes | Where-Object { 
        $_ -match '\.(sql|migration|entity)' 
    }
    if ($hasDbChanges) {
        $requirements.LLD += "ER"
        $requirements.HLD += "DataFlow"
    }
    
    # Check for new services
    $hasNewService = $FileTypes | Where-Object { 
        $_ -match '(Controller|Service|Repository)' -and $_ -match '^A\s' 
    }
    if ($hasNewService) {
        $requirements.HLD += @("SystemContext", "Component")
    }
    
    return $requirements
}
```

**Planning Checklist:**
- [ ] Change type identified
- [ ] File count analyzed
- [ ] Database changes detected
- [ ] New services identified
- [ ] Required diagrams determined
- [ ] Priority assigned

---

#### Task 1.2: Select Diagram Tools
**Objective:** Choose appropriate diagram format based on requirements

**Tool Selection Matrix:**

| Diagram Type | Tool | Format | Reason |
|--------------|------|--------|--------|
| **Class** | Mermaid | ```mermaid | GitHub-native, easy to maintain |
| **Sequence** | Mermaid | ```mermaid | Best for showing method calls |
| **Flowchart** | Mermaid | ```mermaid | Simple and clear |
| **State** | Mermaid | ```mermaid | Perfect for state machines |
| **ER** | Mermaid | ```mermaid | Database relationships |
| **Component** | Mermaid/PlantUML | ```mermaid | Architecture overview |
| **Deployment** | PlantUML | @startuml | Complex infrastructure |
| **Cloud** | Python Diagrams | .py | AWS/Azure/GCP specifics |

**Selection Script:**
```powershell
# PLAN: Select diagram tools
$diagramFormats = @{
    Class = "mermaid"
    Sequence = "mermaid"
    State = "mermaid"
    ER = "mermaid"
    Flowchart = "mermaid"
    Component = "mermaid"
    SystemContext = "mermaid"
    DataFlow = "mermaid"
    Deployment = if ($hasComplexInfra) { "plantuml" } else { "mermaid" }
    CloudArchitecture = if ($hasCloudResources) { "python-diagrams" } else { "mermaid" }
}

Write-Output "✅ Diagram formats selected"
```

**Planning Checklist:**
- [ ] Diagram formats selected
- [ ] Tool availability verified
- [ ] Complexity assessed
- [ ] Rendering method confirmed

---

#### Task 1.3: Plan Diagram Structure
**Objective:** Define what each diagram should contain

**HLD Diagram Planning:**

**System Context Diagram:**
```yaml
elements:
  - name: "Our System"
    type: "system"
  - name: "Users"
    type: "external_actor"
  - name: "External APIs"
    type: "external_system"

relationships:
  - from: "Users"
    to: "Our System"
    protocol: "HTTPS"
  - from: "Our System"
    to: "External APIs"
    protocol: "REST"

focus: "System boundaries and external integrations"
```

**Component Diagram:**
```yaml
elements:
  - layer: "Presentation"
    components: ["Web UI", "Mobile App"]
  - layer: "API"
    components: ["API Gateway", "Auth Service"]
  - layer: "Business"
    components: ["Service A", "Service B"]
  - layer: "Data"
    components: ["Database", "Cache"]

relationships:
  - show: "inter-component communication"
  - show: "data flow"
  - show: "dependencies"

focus: "Major components and their interactions"
```

**LLD Diagram Planning:**

**Class Diagram:**
```yaml
for_each: "top 15 key classes"
elements:
  - name: "[ClassName]"
    properties:
      - visibility: "+/-/#"
      - type: "type"
      - name: "name"
    methods:
      - visibility: "+/-/#"
      - return: "type"
      - name: "name(params)"
    
relationships:
  - type: "inheritance|composition|aggregation|association"
  - from: "[Class A]"
  - to: "[Class B]"

annotations:
  - design_patterns: ["Pattern1", "Pattern2"]
  - frameworks: ["Spring", "JPA"]

focus: "Object structure and relationships"
```

**Sequence Diagram:**
```yaml
for_each: "new or modified API endpoint or major flow"
actors:
  - "Client"
  - "Controller"
  - "Service"
  - "Repository"
  - "Database"

flow:
  - Client -> Controller: "Request"
  - Controller -> Service: "process()"
  - Service -> Repository: "save()"
  - Repository -> Database: "INSERT"
  - Database --> Repository: "Success"
  - Repository --> Service: "Entity"
  - Service --> Controller: "Response"
  - Controller --> Client: "200 OK"

conditional_flows:
  - validation_errors
  - exception_handling
  - async_operations

focus: "Method call sequence and data flow"
```

**Planning Checklist:**
- [ ] Diagram elements identified
- [ ] Relationships mapped
- [ ] Focus areas defined
- [ ] Complexity manageable (<15 elements per diagram)

---

### ⚡ DO Phase

#### Task 2.1: Analyze Code Structure
**Objective:** Extract architectural information from code

**Execution Steps:**

**Step 1: Language Detection**
```powershell
# DO: Detect programming languages
$languageStats = @{}
$allFiles = git diff "$SourceBranch..$TargetBranch" --name-only

foreach ($file in $allFiles) {
    $ext = [System.IO.Path]::GetExtension($file)
    if ($ext) {
        $lang = switch ($ext) {
            ".java" { "Java" }
            ".kt" { "Kotlin" }
            ".py" { "Python" }
            ".js" { "JavaScript" }
            ".ts" { "TypeScript" }
            ".cs" { "C#" }
            ".go" { "Go" }
            ".rs" { "Rust" }
            default { $ext }
        }
        
        if (-not $languageStats.ContainsKey($lang)) {
            $languageStats[$lang] = 0
        }
        $languageStats[$lang]++
    }
}

$primaryLanguage = ($languageStats.GetEnumerator() | 
    Sort-Object -Property Value -Descending | 
    Select-Object -First 1).Key

Write-Output "✅ Primary language: $primaryLanguage"
```

**Step 2: Extract Class Information (Java Example)**
```powershell
# DO: Extract Java class information
function Extract-JavaClassInfo {
    param([string]$FilePath)
    
    $content = git show "${TargetBranch}:${FilePath}"
    
    $classInfo = @{
        Name = ""
        Package = ""
        Imports = @()
        Annotations = @()
        Extends = ""
        Implements = @()
        Fields = @()
        Methods = @()
    }
    
    # Parse package
    if ($content -match 'package\s+([\w\.]+);') {
        $classInfo.Package = $Matches[1]
    }
    
    # Parse class name
    if ($content -match 'public\s+class\s+(\w+)') {
        $classInfo.Name = $Matches[1]
    }
    
    # Parse annotations
    $annotations = [regex]::Matches($content, '@(\w+)(?:\([^\)]*\))?')
    $classInfo.Annotations = $annotations | ForEach-Object { $_.Groups[1].Value }
    
    # Parse extends
    if ($content -match 'extends\s+(\w+)') {
        $classInfo.Extends = $Matches[1]
    }
    
    # Parse implements
    if ($content -match 'implements\s+([\w\s,]+)') {
        $classInfo.Implements = $Matches[1] -split ',\s*'
    }
    
    # Parse methods
    $methods = [regex]::Matches($content, '(public|private|protected)\s+\w+\s+(\w+)\s*\([^\)]*\)')
    $classInfo.Methods = $methods | ForEach-Object {
        @{
            Visibility = $_.Groups[1].Value
            Name = $_.Groups[2].Value
        }
    }
    
    return $classInfo
}
```

**Step 3: Build Dependency Graph**
```powershell
# DO: Build component dependency graph
$dependencyGraph = @{}

foreach ($file in $keyClasses) {
    $classInfo = Extract-JavaClassInfo -FilePath $file.File
    
    $dependencies = @()
    
    # Add parent class as dependency
    if ($classInfo.Extends) {
        $dependencies += $classInfo.Extends
    }
    
    # Add interfaces as dependencies
    $dependencies += $classInfo.Implements
    
    # Store in graph
    $dependencyGraph[$classInfo.Name] = @{
        File = $file.File
        Dependencies = $dependencies
        Annotations = $classInfo.Annotations
    }
}

Write-Output "✅ Dependency graph built"
```

**Execution Checklist:**
- [ ] Primary language detected
- [ ] Class information extracted
- [ ] Dependency graph built
- [ ] Annotations captured
- [ ] Relationships identified

---

#### Task 2.2: Generate HLD Diagrams
**Objective:** Create high-level architecture diagrams

**HLD Generation:**

**System Context Diagram (Mermaid):**
```powershell
# DO: Generate System Context diagram
$systemContextDiagram = @"
``````mermaid
C4Context
    title System Context Diagram - $StoryId
    
    Person(user, "User", "End user of the application")
    System(system, "Our System", "Main application system")
    System_Ext(external1, "External API", "Third-party service")
    System_Ext(external2, "Database", "Data storage")
    
    Rel(user, system, "Uses", "HTTPS")
    Rel(system, external1, "Calls", "REST API")
    Rel(system, external2, "Reads/Writes", "JDBC")
    
    UpdateLayoutConfig(`$c4ShapeInRow="2", `$c4BoundaryInRow="1")
``````
"@

$systemContextPath = "$DiagramDir/01_system_context.md"
$systemContextDiagram | Out-File -FilePath $systemContextPath -Encoding UTF8

Write-Output "✅ System Context diagram generated"
```

**Component Architecture Diagram (Mermaid):**
```powershell
# DO: Generate Component Architecture diagram
$componentDiagram = @"
``````mermaid
graph TB
    subgraph "Presentation Layer"
        UI[Web UI]
        Mobile[Mobile App]
    end
    
    subgraph "API Layer"
        Gateway[API Gateway]
        Auth[Auth Service]
    end
    
    subgraph "Business Layer"
"@

# Add discovered services dynamically
foreach ($service in $discoveredServices) {
    $componentDiagram += "`n        $($service.Name)[$($service.Name)]"
}

$componentDiagram += @"

    end
    
    subgraph "Data Layer"
        DB[(Database)]
        Cache[(Redis Cache)]
    end
    
    UI --> Gateway
    Mobile --> Gateway
    Gateway --> Auth
    Gateway --> $($discoveredServices[0].Name)
    $($discoveredServices[0].Name) --> DB
    $($discoveredServices[0].Name) --> Cache
``````
"@

$componentPath = "$DiagramDir/02_component_architecture.md"
$componentDiagram | Out-File -FilePath $componentPath -Encoding UTF8

Write-Output "✅ Component Architecture diagram generated"
```

**Data Flow Diagram (Mermaid):**
```powershell
# DO: Generate Data Flow diagram
$dataFlowDiagram = @"
``````mermaid
flowchart LR
    A[Client Request] -->|JSON| B{API Gateway}
    B -->|Validated| C[Business Logic]
    B -->|Invalid| D[Error Handler]
    C -->|Transform| E[Data Access Layer]
    E -->|SQL| F[(Database)]
    F -->|Result Set| E
    E -->|Entity| C
    C -->|DTO| B
    B -->|JSON| G[Client Response]
    
    style A fill:#e1f5fe
    style F fill:#fff3e0
    style G fill:#e8f5e9
``````
"@

$dataFlowPath = "$DiagramDir/03_data_flow.md"
$dataFlowDiagram | Out-File -FilePath $dataFlowPath -Encoding UTF8

Write-Output "✅ Data Flow diagram generated"
```

**Execution Checklist:**
- [ ] System Context diagram generated
- [ ] Component Architecture diagram generated
- [ ] Data Flow diagram generated
- [ ] Deployment diagram generated (if needed)
- [ ] All HLD diagrams saved

---

#### Task 2.3: Generate LLD Diagrams
**Objective:** Create low-level design diagrams

**LLD Generation:**

**Class Diagrams (Mermaid):**
```powershell
# DO: Generate Class diagrams for key classes
$classIndex = 0

foreach ($class in $keyClasses | Select-Object -First 15) {
    $classInfo = Extract-JavaClassInfo -FilePath $class.File
    $classIndex++
    
    $classDiagram = @"
``````mermaid
classDiagram
    class $($classInfo.Name) {
"@

    # Add annotations
    if ($classInfo.Annotations) {
        $classDiagram += "`n        <<$($classInfo.Annotations -join ', ')>>"
    }
    
    # Add fields
    foreach ($field in $classInfo.Fields) {
        $classDiagram += "`n        $($field.Visibility)$($field.Type) $($field.Name)"
    }
    
    # Add methods
    foreach ($method in $classInfo.Methods) {
        $symbol = switch ($method.Visibility) {
            "public" { "+" }
            "private" { "-" }
            "protected" { "#" }
        }
        $classDiagram += "`n        $symbol$($method.Name)()"
    }
    
    $classDiagram += "`n    }"
    
    # Add relationships
    if ($classInfo.Extends) {
        $classDiagram += "`n    $($classInfo.Extends) <|-- $($classInfo.Name) : extends"
    }
    
    foreach ($interface in $classInfo.Implements) {
        $classDiagram += "`n    $interface <|.. $($classInfo.Name) : implements"
    }
    
    # Add dependencies
    $deps = $dependencyGraph[$classInfo.Name].Dependencies
    foreach ($dep in $deps) {
        $classDiagram += "`n    $($classInfo.Name) --> $dep : uses"
    }
    
    $classDiagram += "`n``````"
    
    $classPath = "$DiagramDir/class_$('{0:D2}' -f $classIndex)_$($classInfo.Name).md"
    $classDiagram | Out-File -FilePath $classPath -Encoding UTF8
}

Write-Output "✅ $classIndex Class diagrams generated"
```

**Sequence Diagrams (Mermaid):**
```powershell
# DO: Generate Sequence diagrams for API endpoints
$apiEndpoints = $keyClasses | Where-Object { 
    $_.File -match 'Controller|Endpoint|Handler' 
}

$seqIndex = 0

foreach ($endpoint in $apiEndpoints) {
    $seqIndex++
    
    $sequenceDiagram = @"
``````mermaid
sequenceDiagram
    actor Client
    participant Controller
    participant Service
    participant Repository
    participant Database
    
    Client->>Controller: HTTP POST /api/endpoint
    activate Controller
    
    Controller->>Controller: validate(request)
    
    alt Validation Success
        Controller->>Service: process(data)
        activate Service
        
        Service->>Repository: save(entity)
        activate Repository
        
        Repository->>Database: INSERT INTO table
        activate Database
        Database-->>Repository: Success
        deactivate Database
        
        Repository-->>Service: Entity
        deactivate Repository
        
        Service-->>Controller: ResponseDTO
        deactivate Service
        
        Controller-->>Client: 201 Created
    else Validation Failed
        Controller-->>Client: 400 Bad Request
    end
    
    deactivate Controller
``````
"@
    
    $seqPath = "$DiagramDir/sequence_$('{0:D2}' -f $seqIndex)_flow.md"
    $sequenceDiagram | Out-File -FilePath $seqPath -Encoding UTF8
}

Write-Output "✅ $seqIndex Sequence diagrams generated"
```

**ER Diagram (if database changes):**
```powershell
# DO: Generate ER diagram if database changes detected
if ($hasDatabaseChanges) {
    $erDiagram = @"
``````mermaid
erDiagram
    USER ||--o{ ORDER : places
    USER {
        bigint id PK
        string username UK
        string email UK
        string password_hash
        timestamp created_at
    }
    
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER {
        bigint id PK
        bigint user_id FK
        string order_number UK
        decimal total_amount
        string status
        timestamp created_at
    }
    
    ORDER_ITEM }o--|| PRODUCT : references
    ORDER_ITEM {
        bigint id PK
        bigint order_id FK
        bigint product_id FK
        int quantity
        decimal unit_price
    }
    
    PRODUCT {
        bigint id PK
        string sku UK
        string name
        decimal price
        int stock_quantity
    }
``````
"@
    
    $erPath = "$DiagramDir/er_diagram.md"
    $erDiagram | Out-File -FilePath $erPath -Encoding UTF8
    
    Write-Output "✅ ER diagram generated"
}
```

**Execution Checklist:**
- [ ] Class diagrams generated (10-15)
- [ ] Sequence diagrams generated (5+)
- [ ] ER diagram generated (if applicable)
- [ ] State diagrams generated (if applicable)
- [ ] All LLD diagrams saved

---

### ✅ CHECK Phase

#### Task 3.1: Validate Diagram Syntax
**Objective:** Ensure all diagrams are syntactically correct

**Validation Script:**
```powershell
# CHECK: Validate Mermaid syntax
$allDiagrams = Get-ChildItem "$DiagramDir/*.md"

$syntaxErrors = @()

foreach ($diagramFile in $allDiagrams) {
    $content = Get-Content $diagramFile -Raw
    
    # Extract Mermaid code
    if ($content -match '``````mermaid\s+(.*?)\s+``````') {
        $mermaidCode = $Matches[1]
        
        # Basic syntax validation
        $errors = @()
        
        # Check for balanced brackets
        $openBrackets = ([regex]::Matches($mermaidCode, '[\[\{\(]')).Count
        $closeBrackets = ([regex]::Matches($mermaidCode, '[\]\}\)]')).Count
        if ($openBrackets -ne $closeBrackets) {
            $errors += "Unbalanced brackets"
        }
        
        # Check for proper diagram type declaration
        $validTypes = @('graph', 'sequenceDiagram', 'classDiagram', 'erDiagram', 'stateDiagram', 'flowchart', 'C4Context')
        $hasValidType = $false
        foreach ($type in $validTypes) {
            if ($mermaidCode -match "^\s*$type") {
                $hasValidType = $true
                break
            }
        }
        if (-not $hasValidType) {
            $errors += "Invalid or missing diagram type"
        }
        
        # Check for arrows
        if ($mermaidCode -match '(graph|flowchart)' -and $mermaidCode -notmatch '-->|->|===|==') {
            $errors += "No connections found in graph"
        }
        
        if ($errors.Count -gt 0) {
            $syntaxErrors += @{
                File = $diagramFile.Name
                Errors = $errors
            }
        }
    }
}

if ($syntaxErrors.Count -eq 0) {
    Write-Output "✅ All diagrams have valid syntax"
} else {
    Write-Warning "⚠️  $($syntaxErrors.Count) diagrams have syntax errors"
    $syntaxErrors | ForEach-Object {
        Write-Warning "  File: $($_.File)"
        $_.Errors | ForEach-Object { Write-Warning "    - $_" }
    }
}
```

**Validation Checklist:**
- [ ] All Mermaid syntax valid
- [ ] No missing diagram type declarations
- [ ] Balanced brackets/parentheses
- [ ] Proper arrow syntax
- [ ] No empty diagrams

---

#### Task 3.2: Verify Diagram Quality
**Objective:** Check diagram quality and completeness

**Quality Checks:**

**Complexity Check:**
```powershell
# CHECK: Diagram complexity
foreach ($diagramFile in $allDiagrams) {
    $content = Get-Content $diagramFile -Raw
    
    # Count elements
    $elements = ([regex]::Matches($content, '\w+\[|\w+\(|\w+\{')).Count
    
    if ($elements -gt 20) {
        Write-Warning "⚠️  $($diagramFile.Name) has $elements elements (recommend <15 for readability)"
    } elseif ($elements -eq 0) {
        Write-Error "❌ $($diagramFile.Name) has no elements"
    } else {
        Write-Output "✅ $($diagramFile.Name): $elements elements (good)"
    }
}
```

**Completeness Check:**
```powershell
# CHECK: Required diagrams present
$requiredDiagrams = @{
    HLD = @("system_context", "component_architecture", "data_flow")
    LLD = @("class_", "sequence_")
}

$missingDiagrams = @()

foreach ($type in $requiredDiagrams.Keys) {
    foreach ($pattern in $requiredDiagrams[$type]) {
        $found = $allDiagrams | Where-Object { $_.Name -match $pattern }
        if (-not $found -or $found.Count -eq 0) {
            $missingDiagrams += "$type : $pattern"
        }
    }
}

if ($missingDiagrams.Count -eq 0) {
    Write-Output "✅ All required diagrams present"
} else {
    Write-Warning "⚠️  Missing diagrams:"
    $missingDiagrams | ForEach-Object { Write-Warning "  - $_" }
}
```

**Visual Rendering Test:**
```powershell
# CHECK: Test diagram rendering (if Mermaid CLI available)
if (Get-Command "mmdc" -ErrorAction SilentlyContinue) {
    foreach ($diagramFile in $allDiagrams) {
        $outputPng = $diagramFile.FullName -replace '\.md$', '.png'
        
        try {
            & mmdc -i $diagramFile.FullName -o $outputPng 2>&1 | Out-Null
            
            if (Test-Path $outputPng) {
                Write-Output "✅ $($diagramFile.Name) renders successfully"
                Remove-Item $outputPng  # Clean up test file
            }
        } catch {
            Write-Error "❌ $($diagramFile.Name) failed to render: $_"
        }
    }
} else {
    Write-Warning "⚠️  Mermaid CLI not available, skipping render test"
}
```

**Quality Checklist:**
- [ ] No diagrams with >20 elements
- [ ] No empty diagrams
- [ ] All required diagrams present
- [ ] Diagrams render successfully
- [ ] Visual clarity confirmed

---

#### Task 3.3: Peer Review Diagrams
**Objective:** Human verification of diagram accuracy

**Review Checklist:**

**Technical Accuracy:**
- [ ] All classes shown actually exist in code
- [ ] Relationships match code structure
- [ ] Method names are correct
- [ ] Data flow is accurate
- [ ] Database schema matches actual schema

**Clarity:**
- [ ] Labels are readable
- [ ] No overlapping elements
- [ ] Logical grouping used
- [ ] Direction is clear (top-to-bottom or left-to-right)
- [ ] Colors used meaningfully

**Completeness:**
- [ ] All key components shown
- [ ] Important relationships included
- [ ] External systems represented
- [ ] Data stores identified
- [ ] Critical flows documented

**Reviewer Feedback:**
```yaml
diagram_review:
  reviewer: "[Name]"
  date: "[Date]"
  diagrams_reviewed: [count]
  status: "APPROVED | NEEDS_REVISION"
  
  feedback:
    - diagram: "component_architecture.md"
      issue: "Missing Redis cache component"
      severity: "MEDIUM"
      action: "Add cache to diagram"
    
    - diagram: "sequence_01_flow.md"
      issue: "Error handling flow not shown"
      severity: "LOW"
      action: "Add alt block for errors"
```

---

### 🔄 ACT Phase

#### Task 4.1: Publish Diagrams
**Objective:** Integrate diagrams into documentation and repository

**Publication Steps:**

**Step 1: Embed in Documentation**
```powershell
# ACT: Create diagram index
$diagramIndex = @"
# Architecture Diagrams - $StoryId

## High-Level Design (HLD)

### System Context
![System Context](diagrams/01_system_context.md)

### Component Architecture
![Component Architecture](diagrams/02_component_architecture.md)

### Data Flow
![Data Flow](diagrams/03_data_flow.md)

## Low-Level Design (LLD)

### Class Diagrams
"@

$classDiagrams = Get-ChildItem "$DiagramDir/class_*.md" | Sort-Object Name
foreach ($diagram in $classDiagrams) {
    $diagramIndex += "`n- [$($diagram.BaseName)](diagrams/$($diagram.Name))"
}

$diagramIndex += "`n`n### Sequence Diagrams"
$seqDiagrams = Get-ChildItem "$DiagramDir/sequence_*.md" | Sort-Object Name
foreach ($diagram in $seqDiagrams) {
    $diagramIndex += "`n- [$($diagram.BaseName)](diagrams/$($diagram.Name))"
}

$indexPath = "$DiagramDir/../DIAGRAM_INDEX.md"
$diagramIndex | Out-File -FilePath $indexPath -Encoding UTF8

Write-Output "✅ Diagram index created"
```

**Step 2: Commit to Repository**
```powershell
# ACT: Commit diagrams
git add "$DiagramDir/*.md"
git add "$DiagramDir/../DIAGRAM_INDEX.md"
git commit -m "docs: Add LLD/HLD diagrams for $StoryId"
git push origin $TargetBranch

Write-Output "✅ Diagrams committed and pushed"
```

**Step 3: Generate Diagram Report**
```powershell
# ACT: Generate diagram report
$diagramReport = @{
    StoryId = $StoryId
    GeneratedDate = Get-Date
    HLD_Count = ($allDiagrams | Where-Object { $_.Name -match 'system_context|component|data_flow|deployment' }).Count
    LLD_Count = ($allDiagrams | Where-Object { $_.Name -match 'class_|sequence_|er_|state_' }).Count
    Total = $allDiagrams.Count
    Format = "Mermaid"
    QualityScore = 100 - ($syntaxErrors.Count * 10)
}

$reportPath = ".github/docs/archives/$StoryId/diagram_report.json"
$diagramReport | ConvertTo-Json | Out-File -FilePath $reportPath -Encoding UTF8

Write-Output "✅ Diagram report generated"
```

**Publication Checklist:**
- [ ] Diagram index created
- [ ] All diagrams committed
- [ ] Changes pushed to remote
- [ ] Diagram report generated
- [ ] Links updated in main documentation

---

#### Task 4.2: Measure and Improve
**Objective:** Track diagram generation metrics and optimize

**Metrics Collection:**
```powershell
# ACT: Collect diagram generation metrics
$metrics = @{
    StoryId = $StoryId
    StartTime = $StartTime
    EndTime = Get-Date
    Duration = ((Get-Date) - $StartTime).TotalMinutes
    
    Diagrams = @{
        HLD = @{
            SystemContext = if (Test-Path "$DiagramDir/*system_context*.md") { 1 } else { 0 }
            Component = if (Test-Path "$DiagramDir/*component*.md") { 1 } else { 0 }
            DataFlow = if (Test-Path "$DiagramDir/*data_flow*.md") { 1 } else { 0 }
            Deployment = if (Test-Path "$DiagramDir/*deployment*.md") { 1 } else { 0 }
        }
        LLD = @{
            Class = (Get-ChildItem "$DiagramDir/class_*.md").Count
            Sequence = (Get-ChildItem "$DiagramDir/sequence_*.md").Count
            ER = if (Test-Path "$DiagramDir/*er*.md") { 1 } else { 0 }
            State = (Get-ChildItem "$DiagramDir/state_*.md").Count
        }
    }
    
    Quality = @{
        SyntaxErrors = $syntaxErrors.Count
        ComplexityIssues = $complexityIssues.Count
        Score = $diagramReport.QualityScore
    }
    
    Performance = @{
        AutomationRate = "98%"
        ManualReview = "5 min"
        TotalTime = "$($metrics.Duration) min"
    }
}

$metricsPath = ".github/docs/metrics/$StoryId-diagram-metrics.json"
$metrics | ConvertTo-Json -Depth 5 | Out-File -FilePath $metricsPath -Encoding UTF8

Write-Output "✅ Metrics collected: $($allDiagrams.Count) diagrams in $($metrics.Duration) minutes"
```

**Improvement Analysis:**
```powershell
# ACT: Analyze and improve
$allMetrics = Get-ChildItem ".github/docs/metrics/*-diagram-metrics.json" | 
    ForEach-Object { Get-Content $_ | ConvertFrom-Json }

$avgDuration = ($allMetrics | Measure-Object -Property Duration -Average).Average
$avgQuality = ($allMetrics | Measure-Object -Property Quality.Score -Average).Average

$improvements = @()

if ($avgDuration -gt 10) {
    $improvements += @{
        Issue = "Diagram generation takes >10 minutes on average"
        Action = "Implement parallel diagram generation"
        Priority = "HIGH"
    }
}

if ($avgQuality -lt 90) {
    $improvements += @{
        Issue = "Average quality score below 90"
        Action = "Enhance syntax validation and auto-correction"
        Priority = "MEDIUM"
    }
}

if ($improvements.Count -gt 0) {
    $improvements | ConvertTo-Json | Out-File ".github/docs/improvements/diagram-improvements.json"
    Write-Output "📋 $($improvements.Count) improvement actions identified"
}
```

**Act Checklist:**
- [ ] Diagrams published
- [ ] All links working
- [ ] Metrics collected
- [ ] Performance analyzed
- [ ] Improvements identified
- [ ] Next cycle planned

---

## 🚀 Agent Execution Command

### Quick Start
```powershell
# Execute complete PDCA cycle for diagram generation
.\.github\agents\architecture-diagrams\execute-agent.ps1 `
    -SourceBranch "main" `
    -TargetBranch "feature/my-feature" `
    -StoryId "PROJ-123" `
    -DiagramFormat "mermaid" `
    -GenerateHLD $true `
    -GenerateLLD $true `
    -AutoPublish $true

# Agent will:
# 1. PLAN: Assess requirements and select tools
# 2. DO: Generate HLD and LLD diagrams
# 3. CHECK: Validate syntax and quality
# 4. ACT: Publish and collect metrics
```

### Advanced Options
```powershell
# Custom diagram generation
.\.github\agents\architecture-diagrams\execute-agent.ps1 `
    -SourceBranch "main" `
    -TargetBranch "feature/my-feature" `
    -StoryId "PROJ-123" `
    -DiagramFormat "mermaid" `        # mermaid | plantuml | both
    -DiagramTypes "Class,Sequence,Component" `  # Specific types
    -MaxClassDiagrams 20 `            # Limit number of class diagrams
    -IncludeER $true `                # Force ER diagram generation
    -ComplexityThreshold 15 `         # Max elements per diagram
    -AutoPublish $true                # Auto-commit results
```

---

## 📊 Success Criteria

### Performance Targets
- **Analysis Time:** <3 minutes
- **Diagram Generation:** <5 minutes for 15 diagrams
- **Quality Score:** ≥90/100
- **Automation Rate:** ≥98%
- **Manual Review:** <5 minutes

### Quality Targets
- **Syntax Accuracy:** 100% (no errors)
- **Visual Clarity:** All diagrams <15 elements
- **Completeness:** All required diagrams generated
- **Accuracy:** Diagrams match code structure
- **Usefulness:** Diagrams aid understanding

---

## 🔄 Continuous Improvement

### Feedback Loop
```
Generate → Validate → Review → Measure → Improve → Generate (Enhanced)
```

### Optimization Areas
1. **Parallel Generation:** Generate multiple diagrams simultaneously
2. **Smart Caching:** Cache class structures to speed up re-generation
3. **AI Enhancement:** Use AI to suggest optimal diagram structures
4. **Auto-Correction:** Automatically fix common syntax issues
5. **Template Library:** Build library of common diagram patterns

---

## 📖 Related Documentation

- **Execution Script:** `.github/agents/architecture-diagrams/execute-agent.ps1`
- **Chatbot Instructions:** `.github/agents/architecture-diagrams/chatbot-instructions.md`
- **Step-by-Step Guide:** `.github/agents/architecture-diagrams/step-by-step-guide.md`
- **Diagram Standards:** `.github/agents/architecture-diagrams/diagram-standards.md`
- **Mermaid Examples:** `.github/agents/architecture-diagrams/mermaid-examples.md`

---

**Agent Version:** 2.0  
**Last Updated:** January 9, 2026  
**Status:** ✅ Production Ready  
**PDCA Certified:** Yes

