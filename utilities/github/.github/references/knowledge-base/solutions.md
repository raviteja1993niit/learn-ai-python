# Solutions Archive
> Reusable YAML edit patterns for the three OpenAPI spec files

---

## SOL-001: Add field to `required` array of a submission schema

**Problem:** A field exists in `properties:` of a schema but is not enforced as required, yet the business contract and payloads always send it.

**Solution:**
```yaml
# Before (VerificationSubmission example):
required:
  - acquirerId
  - ...existing fields...
  - orderId

# After — append new required field:
required:
  - acquirerId
  - ...existing fields...
  - orderId
  - transactionType
```

**Rules:**
- The field MUST already exist in `properties:` of the same schema
- Maintain 2-space indent + `- fieldName` list format
- Do NOT duplicate existing entries
- Check that the acquirer overlay (`allOf` pattern) inherits it automatically

**When to Use:** Field is always present in valid payloads, business contract mandates it.
**Success Rate:** 100% (used 1 time)
**Last Used:** 2026-02-25
**Tags:** required, VerificationSubmission, schema-contract

---

## SOL-002: Reference an existing primitive schema in a property

**Problem:** Need to add a property that references an existing reusable schema.

**Solution:**
```yaml
# Simple direct $ref:
propertyName:
  $ref: '#/components/schemas/ExistingSchemaName'

# With added description (wrap in allOf):
propertyName:
  description: Custom description for this usage context.
  allOf:
    - $ref: '#/components/schemas/ExistingSchemaName'
```

**When to Use:** Any time adding a property whose type is an existing schema.
**Tags:** property, $ref, schema-reference

---

## SOL-003: Add a cross-file $ref in acquirer overlay

**Problem:** Acquirer overlay needs to reference a schema from the primary spec or config spec.

**Solution:**
```yaml
# Reference from primary spec:
$ref: './card-payment-connectivity-api.yaml#/components/schemas/SchemaName'

# Reference from config spec:
$ref: './acquirer_connectivity_config_api.yaml#/components/schemas/AcquirerConfigurationData'

# Reference a deeply nested schema:
$ref: './card-payment-connectivity-api.yaml#/components/schemas/Authorization/properties/transactionReferences/properties/systemTraceAuditNumber'
```

**When to Use:** Any cross-file reference in acquirer-card-payment-connectivity-api.yaml.
**Tags:** cross-file, $ref, acquirer-overlay

---

## SOL-004: Add acquirerConfigurations + systemTraceAuditNumber to a new acquirer submission schema

**Problem:** Need to create a new acquirer-flavoured submission schema following the established pattern.

**Solution:**
```yaml
AcquirerNewOperationSubmission:
  type: object
  required:
    - acquirerConfigurations
    - systemTraceAuditNumber
  allOf:
    - $ref: './card-payment-connectivity-api.yaml#/components/schemas/NewOperationSubmission'
  properties:
    acquirerConfigurations:
      type: array
      minItems: 0
      items:
        $ref: './acquirer_connectivity_config_api.yaml#/components/schemas/AcquirerConfigurationData'
    systemTraceAuditNumber:
      $ref: './card-payment-connectivity-api.yaml#/components/schemas/Authorization/properties/transactionReferences/properties/systemTraceAuditNumber'
```

**When to Use:** Creating any new acquirer submission schema.
**Tags:** acquirer-overlay, new-schema, allOf

---

## Solution Categories

| Category | Count | Most Used |
|----------|-------|-----------|
| Required list management | 1 | SOL-001 |
| Schema references | 2 | SOL-002 |
| Cross-file patterns | 2 | SOL-003 |

## Quick Lookup

| Tag | Solutions |
|-----|-----------|
| required | SOL-001 |
| $ref | SOL-002, SOL-003 |
| acquirer-overlay | SOL-003, SOL-004 |
| allOf | SOL-002, SOL-004 |
| cross-file | SOL-003 |

---
*Add new solutions after each successful novel problem resolution*
