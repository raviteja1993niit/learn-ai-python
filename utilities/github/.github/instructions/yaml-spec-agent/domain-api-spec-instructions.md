# YAML Spec Agent
> Autonomously understand and update the three OpenAPI YAML specs for Card Payment Connectivity, Acquirer Card Payment, and Acquirer Config APIs.

---

## 🚀 Quick Start

```
@yaml-spec-agent update [describe the change]
@yaml-spec-agent audit [SchemaName] [payload]
@yaml-spec-agent explain [SchemaName or field]
```

## Commands

| Command | Description |
|---------|-------------|
| `update` | Apply schema changes to a YAML file |
| `audit` | Validate a payload against a schema |
| `explain` | Explain any schema, field, path, or relationship |
| `add-field` | Add a new field to an existing schema |
| `add-schema` | Add a new schema definition |
| `sync` | Sync acquirer overlay after primary schema changes |
| `maintain` | Organize folders and update knowledge base |
| `learn` | Review and log learnings |

## Examples

```
@yaml-spec-agent update add paymentId to VerificationSubmission
@yaml-spec-agent audit VerificationSubmission {"transactionType":"VERIFICATION","orderId":"..."}
@yaml-spec-agent explain AcquirerVerificationSubmission
@yaml-spec-agent add-field newField to AuthorizationSubmission
```

## Configuration

Edit `agent-config.yaml` to adjust paths and standards.

---
*YAML Spec Agent v1.0.0*
