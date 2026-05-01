# YAML Spec Agent — Memory Map
> Quick navigation guide for LLM context

## 🎯 Agent Purpose
Know and autonomously edit the three OpenAPI YAML spec files in `src/main/resources/`.

## 📁 Structure Overview
```
.github/instructions/yaml-spec-agent/
├── README.md                   → Quick Start + Commands
├── MEMORY_MAP.md               → You are here (navigation)
├── yaml-spec-agent.chatmode.md → Agent brain (all instructions, domain knowledge, workflows)
├── agent-config.yaml           → Configuration & dynamic paths
└── knowledge-base/
    ├── learning-log.md         → What agent learned
    ├── changelog.md            → All YAML changes made
    └── solutions.md            → Reusable edit patterns
```

## 🔑 Key Files to Read

| When You Need | Read This |
|---------------|-----------|
| How to invoke agent | `README.md` |
| Full domain knowledge + workflows | `yaml-spec-agent.chatmode.md` |
| Dynamic paths | `agent-config.yaml → paths` |
| Past YAML changes | `knowledge-base/changelog.md` |
| Edit patterns | `knowledge-base/solutions.md` |
| Learnings | `knowledge-base/learning-log.md` |

## 🗂️ YAML Files Managed

| File | Location | Lines |
|------|----------|-------|
| `card-payment-connectivity-api.yaml` | `src/main/resources/` | ~5911 |
| `acquirer-card-payment-connectivity-api.yaml` | `src/main/resources/` | 738 |
| `acquirer_connectivity_config_api.yaml` | `src/main/resources/` | 1026 |

## 🔑 Key Schema Locations (card-payment-connectivity-api.yaml)

| Schema | Approx Line |
|--------|-------------|
| `Authorization` (response) | ~894 |
| `AuthorizationSubmission` | ~2708 |
| `AuthorizationUpdateSubmission` | ~1367 |
| `AuthorizationVoidSubmission` | ~2047 |
| `AuthorizationSystemReversal` | ~1200 |
| `VerificationSubmission` | ~5507 |
| `TransactionType` enum | ~5320 |
| `OrderId` schema | ~4745 |
| `PaymentSource` enum | (in schemas section) |
| `CardScheme` enum | (in schemas section) |
| `CardFundingMethod` enum | (in schemas section) |

## 🔑 Key Schema Locations (acquirer-card-payment-connectivity-api.yaml)

| Schema | Approx Line |
|--------|-------------|
| `AcquirerAuthorizationSubmission` | ~341 |
| `AcquirerVerificationSubmission` | ~441 |
| `AcquirerCaptureSubmission` | ~457 |
| `ClearingData` | ~509 |
| All responses | ~681 |

## 🔄 PDCA Quick Reference
- **PLAN**: Locate schema → check KB patterns → identify cross-file impacts
- **DO**: Apply minimal precise edit → correct indentation → valid $ref
- **CHECK**: No duplicate required fields → valid enum values → YAML syntax OK
- **ACT**: Confirm → update changelog.md → store solutions

## 🔗 Cross-File Reference Map
```
acquirer-card-payment-connectivity-api.yaml
  └── allOf $ref → card-payment-connectivity-api.yaml (base schemas)
  └── $ref → acquirer_connectivity_config_api.yaml (AcquirerConfigurationData)
  └── parameters/responses $ref → card-payment-connectivity-api.yaml (shared components)
```

---
*Last updated: 2026-02-25*
