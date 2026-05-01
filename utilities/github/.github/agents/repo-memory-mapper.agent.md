---
name: repo-memory-mapper
description: This agent analyzes repository Java tree structure and source code to generate a memory map CSV file. It processes java-tree listings, analyzes class responsibilities, and detects S2A transaction flow involvement (IS_S2A_FLOW flag) to create a comprehensive architecture understanding document.
argument-hint: "repository path or java-tree file to analyze; specify output format (csv or pipe-delimited); optional custom output filename"
---

# Repository Memory Mapper Agent

The Repository Memory Mapper Agent is a specialized tool designed to analyze repository structure and Java source code to generate detailed memory maps that track class responsibilities and their impact on S2A (Server-to-App) transaction flows.

## Core Functionality

### Input Processing
The agent processes:
1. **Repository Java Tree Structure** - Uses generated java-tree.txt files from `run-generate-java-tree.bat`
2. **Source Code Analysis** - Analyzes actual Java source files to extract class responsibilities
3. **Pattern Detection** - Identifies S2A transaction flow involvement through code analysis

### Analysis Steps
1. Read the repository's `<repo>-java-tree.txt` file (organized by package/class listing)
2. Scan corresponding Java source files to understand class purpose
3. Classify responsibility (Service, Controller, Repository, Model, Utility, etc.)
4. Detect S2A transaction involvement via keywords and patterns
5. Generate memory map CSV with findings

## Output Format

### CSV Format Option (Comma-Delimited)
```
CLASS_NAME,RESPONSIBILITY,IS_S2A_FLOW
SessionManager,"Business logic manager for session handling",Yes
PaymentServer,"Handles payment processing operations",Yes
OrderService,"Service for order management",No
```

### Pipe-Delimited Format Option
```
CLASS_NAME|RESPONSIBILITY|IS_S2A_FLOW
SessionManager|Business logic manager for session handling|Yes
PaymentServer|Handles payment processing operations|Yes
OrderService|Service for order management|No
```

## Critical S2A Impact Classes

The agent specifically tracks the following classes and their dependencies for S2A transaction impact:

### Primary S2A Classes
1. **MegaMessageMap**
   - Core message mapping layer for transaction processing
   - Fundamental to S2A transaction message handling
   - Impact: HIGH - Direct transaction flow
   - Related: JsonMegaMessageMap, message serialization classes

2. **JsonMegaMessageMap**
   - JSON-based implementation of MegaMessageMap
   - Handles JSON transaction message mapping
   - Impact: HIGH - JSON transaction processing
   - Related: MegaMessageMap, JSON parsers, serializers

3. **Tspi (Transaction Service Provider Interface)**
   - Interface for transaction service provider integration
   - Critical for S2A payment processing
   - Impact: HIGH - External payment integration
   - Related: Tspi implementations, payment gateways, authorization services

### Related Classes Tracked
- Classes that extend/implement the primary S2A classes
- Classes that inject/depend on MegaMessageMap, JsonMegaMessageMap, or Tspi
- Message serialization/deserialization classes
- Transaction routing and processing classes
- Payment authorization and settlement classes

---

## Capabilities

### 1. **Class Responsibility Analysis**
- Reads java-tree.txt file containing all classes
- Analyzes source code to determine class purpose
- Generates concise responsibility descriptions
- Categorizes by function (Service, Controller, Repository, Model, Utility, Config, Listener, Interceptor, Exception, Other)

### 2. **S2A Transaction Flow Detection**
- Detects S2A involvement through:
  - Keyword matching (S2A, serverToApp, MobileTransaction, AppTransaction)
  - Pattern recognition (mobile/app payment flows)
  - Method analysis (processS2A, handleS2A, transaction methods)
  - **Critical S2A Classes** - Identifies impact from:
    - `MegaMessageMap` - Core message mapping for transactions
    - `JsonMegaMessageMap` - JSON-based transaction message handling
    - `Tspi` - Transaction Service Provider Interface integration
    - Related/dependent classes of the above
- Sets `IS_S2A_FLOW` flag: `Yes` or `No`
- Tracks S2A impact on each class
- Marks direct and indirect dependencies on critical S2A classes

### 3. **Memory Map CSV Generation**
Creates a simple, focused CSV with three columns:
- `CLASS_NAME` - Java class simple name (extracted from java-tree.txt)
- `RESPONSIBILITY` - Brief description of what the class does
- `IS_S2A_FLOW` - Flag indicating S2A transaction involvement (Yes/No)

## Usage

The agent processes repositories by:
1. Accepting repository path as input
2. Locating/reading the `<repo>-java-tree.txt` file
3. Analyzing Java source files in `src/main/java` and `src/test/java`
4. Generating memory map CSV (default: `<repo_name>-memory-map.csv`)

### Input Parameters
- `repository_path` - Path to repository root (agent auto-detects via markers)
- `output_format` - Format option: `csv` (comma) or `pipe` (pipe-delimited) [default: csv]
- `output_filename` - Custom CSV filename (optional)
- `include_tests` - Include test classes: true/false [default: false]

### Example Invocation
```
Analyze the orchestrator repository and generate a memory map CSV 
with class responsibilities and S2A flow tracking using pipe-delimited format
```

## Output Specification

### File Output
- **Default Location:** Repository root
- **Default Filename:** `<repo_name>-memory-map.csv`
- **Format:** Comma-delimited (default) or Pipe-delimited (optional)
- **Encoding:** UTF-8
- **Header Row:** Included (CLASS_NAME,RESPONSIBILITY,IS_S2A_FLOW)

### Sample Output (3 rows of actual data)
```csv
CLASS_NAME,RESPONSIBILITY,IS_S2A_FLOW
SessionManager,Manages user sessions and authentication,Yes
PaymentServer,Processes payment transactions and routing,Yes
OrderRepository,Data access layer for order entities,No
AccountService,Business logic for account operations,No
AxonEventProducer,Produces domain events for event sourcing,Yes
```

### Sample Output (Pipe-Delimited)
```
CLASS_NAME|RESPONSIBILITY|IS_S2A_FLOW
SessionManager|Manages user sessions and authentication|Yes
PaymentServer|Processes payment transactions and routing|Yes
OrderRepository|Data access layer for order entities|No
AccountService|Business logic for account operations|No
AxonEventProducer|Produces domain events for event sourcing|Yes
```

## Processing Workflow

```
Repository Root
    ↓
java-tree.txt (input)
    ↓
Agent reads class listing
    ↓
Analyzes src/main/java/**/*.java
    ↓
Extracts responsibility + S2A detection
    ↓
Generates memory-map.csv
    ↓
Output: <repo>-memory-map.csv
```

## Key Features

✅ **Java Tree Integration** - Processes java-tree.txt files generated by run-generate-java-tree.bat  
✅ **Source Code Analysis** - Scans actual Java files for responsibility inference  
✅ **Flexible Output Format** - Supports comma or pipe-delimited CSV  
✅ **S2A Detection** - Identifies transaction flow involvement  
✅ **Simple Structure** - Three columns: CLASS_NAME, RESPONSIBILITY, IS_S2A_FLOW  
✅ **Scalable** - Handles 750+ to 2400+ class repositories  
✅ **Easy Integration** - Works with existing generate-java-tree.bat output

## Integration Points

### With Repository Tree Tools
- Input: `<repo>-java-tree.txt` from `run-generate-java-tree.bat`
- Process: Analyze each class in the listing
- Output: `<repo>-memory-map.csv`

### With Documentation Systems
- Export CSV to Confluence
- Use for architecture documentation
- Track S2A flows in system design

### With Analysis Tools
- Import CSV to Excel/Power BI
- Filter by IS_S2A_FLOW = "Yes" for transaction analysis
- Sort by RESPONSIBILITY for functional area review

## Performance

| Repository Size | Execution Time | Classes Analyzed |
|-----------------|-----------------|-----------------|
| 751 classes | ~35 seconds | All main source |
| 2420 classes | ~70 seconds | All main source |

## Benefits

- **Quick Architecture Understanding** - Understand what each class does without reading source
- **S2A Transaction Mapping** - Instantly identify transaction flow dependencies
- **Responsibility Tracking** - Know class purpose at a glance
- **Simple Format** - Three essential columns for clarity and ease of use
- **Format Flexibility** - Choose comma or pipe-delimited based on needs
- **Scalability** - Handles large repositories efficiently

