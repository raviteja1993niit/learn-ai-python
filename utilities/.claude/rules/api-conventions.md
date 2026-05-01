# API Conventions

## REST Design

- URIs use **lowercase kebab-case** nouns: `/payment-transactions`, `/authorisation-requests`
- Never use verbs in URIs — let HTTP methods convey the action
- Resource naming: plural nouns for collections (`/transactions`); singular for singletons
- HTTP method semantics:
  - `POST` — create or trigger an action
  - `GET` — read (idempotent, no side effects)
  - `PUT` — full replacement update (idempotent)
  - `PATCH` — partial update
  - `DELETE` — remove resource

## HTTP Status Codes

| Scenario | Code |
|----------|------|
| Created successfully | 201 |
| Accepted (async) | 202 |
| Success, no body | 204 |
| Bad request / validation failure | 400 |
| Unauthenticated | 401 |
| Forbidden (authorised but not permitted) | 403 |
| Resource not found | 404 |
| Conflict | 409 |
| Unprocessable entity | 422 |
| Internal server error | 500 |
| Service unavailable | 503 |

## Request / Response Design

- Use **camelCase** field names in JSON (`transactionAmount`, not `transaction_amount`)
- Use ISO 8601 for all dates and timestamps: `2025-06-15T14:30:00Z`
- Amounts: represent as `long` (minor currency unit) or `BigDecimal`; never `double` or `float` for money
- Wrap responses in a consistent envelope where applicable:
  ```json
  { "data": { ... }, "meta": { "requestId": "..." } }
  ```
- Error responses must use the structured format:
  ```json
  { "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }
  ```

## Versioning

- Version via URI path: `/v1/payment-transactions`
- Do not break existing versions — add a new version for breaking changes
- Deprecate old versions with `Deprecation` response header and Jira ticket reference

## Pagination

- Never return unbounded result sets — always pass page size / limit parameters
- Pagination envelope:
  ```json
  { "data": [...], "pagination": { "page": 1, "size": 20, "total": 143 } }
  ```

## Security

- All APIs must enforce authentication (JWT Bearer or mutual TLS)
- Validate `Authorization` header presence at the handler boundary
- Never expose internal identifiers (database IDs, internal service names) in public API responses
- Apply CORS restrictions; do not use wildcard `*` in production

## Documentation

- All public REST endpoints must have a Javadoc `@Operation` (OpenAPI annotation) or equivalent
- Include `@param`, `@return`, `@throws` in all controller method Javadocs
- OpenAPI spec (`openapi.yaml`) must be updated as part of any PR that adds or modifies endpoints
