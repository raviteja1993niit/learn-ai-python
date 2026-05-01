# ProcessingIT Diagram Index

## Overview
Complete diagram index for the ProcessingIT Integration Test architecture documentation.

---

## 📊 High-Level Design (HLD) Diagrams

| # | Diagram | Description | File |
|---|---------|-------------|------|
| 1 | [System Context](./HLD/01_system_context.md) | External systems and boundaries for ProcessingIT | `HLD/01_system_context.md` |
| 2 | [Component Architecture](./HLD/02_component_architecture.md) | Module dependencies and component relationships | `HLD/02_component_architecture.md` |
| 3 | [Data Flow](./HLD/03_data_flow.md) | Information flow through test execution | `HLD/03_data_flow.md` |

---

## 📐 Low-Level Design (LLD) Diagrams

### Class Diagrams

| # | Diagram | Description | File |
|---|---------|-------------|------|
| 1 | [Class Diagram](./LLD/01_class_diagram.md) | Complete class structure and relationships | `LLD/01_class_diagram.md` |

### State Diagrams

| # | Diagram | Description | File |
|---|---------|-------------|------|
| 2 | [State Diagram](./LLD/02_state_diagram.md) | Test execution and transaction state flows | `LLD/02_state_diagram.md` |

### Sequence Diagrams

| # | Diagram | Description | File |
|---|---------|-------------|------|
| 3 | [Test Execution Flow](./LLD/sequence/01_test_execution_flow.md) | Complete test execution sequence | `LLD/sequence/01_test_execution_flow.md` |
| 4 | [Model Construction](./LLD/sequence/02_model_construction.md) | How test models are built | `LLD/sequence/02_model_construction.md` |
| 5 | [Request/Response Flow](./LLD/sequence/03_request_response_flow.md) | Transaction processing details | `LLD/sequence/03_request_response_flow.md` |
| 6 | [Interaction Layers](./LLD/sequence/04_interaction_layers.md) | CPC, Connectivity, Acquirer layer interaction | `LLD/sequence/04_interaction_layers.md` |

---

## 🗂️ Folder Structure

```
.github/docs/archives/ProcessingIT/diagrams/
├── DIAGRAM_INDEX.md (this file)
├── HLD/
│   ├── 01_system_context.md
│   ├── 02_component_architecture.md
│   └── 03_data_flow.md
└── LLD/
    ├── 01_class_diagram.md
    ├── 02_state_diagram.md
    └── sequence/
        ├── 01_test_execution_flow.md
        ├── 02_model_construction.md
        ├── 03_request_response_flow.md
        └── 04_interaction_layers.md
```

---

## 📈 Generation Metrics

| Metric | Value |
|--------|-------|
| Total Diagrams | 9 |
| HLD Diagrams | 3 |
| LLD Diagrams | 6 |
| Mermaid Syntax | 100% Valid |
| Coverage | Complete ProcessingIT flow |

---

## 🔑 Key Components Covered

### Test Framework
- ProcessingIT (main test class)
- IntegrationTestsConfig (Spring configuration)
- MCTF Integration (Mastercard Test Framework)

### Model Layer
- ElavonSystemTransactions (model container)
- AuthFPANTest (test scenarios)
- TestConstants (request/response builders)

### Message Layer
- Acquirer (message definitions)
- ElavonMessage (ISO 8583 structure)
- ElavonTransactionHandler (transaction processing)

### Interaction Layers
- CPC Layer (Card Processing Component)
- Connectivity Layer (Protocol routing)
- Acquirer Layer (Elavon S2A endpoint)

---

## 📝 Usage Instructions

### Viewing Diagrams
1. Open any `.md` file in a Markdown viewer with Mermaid support
2. Use GitHub, GitLab, or VS Code with Mermaid extension
3. Diagrams render automatically in supported viewers

### Exporting Diagrams
```bash
# Using Mermaid CLI (mmdc)
mmdc -i diagram.md -o diagram.png

# Or use online Mermaid Live Editor
# https://mermaid.live/
```

### Updating Diagrams
1. Edit the relevant `.md` file
2. Validate Mermaid syntax using Mermaid Live Editor
3. Commit changes to repository

---

## 📚 Related Documentation

- [ProcessingIT.java](../../../../lib-elavon-interface-integration-tests/src/test/java/com/mastercard/pgs/connectivity/acquirer/test/ProcessingIT.java)
- [AuthFPANTest.java](../../../../lib-elavon-interface-test-data/src/main/java/com/mastercard/pgs/connectivity/acquirer/flow/model/AuthFPANTest.java)
- [ElavonSystemTransactions.java](../../../../lib-elavon-interface-test-data/src/main/java/com/mastercard/pgs/connectivity/acquirer/flow/ElavonSystemTransactions.java)

---

*Generated: January 20, 2026*
