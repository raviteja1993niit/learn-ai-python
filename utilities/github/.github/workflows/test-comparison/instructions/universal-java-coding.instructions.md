applyTo: "*.java"
description: "This document defines the coding rules, conventions, and templates to be followed across all Java source files."

# ✅ Java Coding Best Practices

---

## **1. Java Source File Header Template & Instructions**
### 1.1 File Header
- Every new Java file (classes, interfaces, enums, annotations) must include:
  ```java
  /*
   * Copyright (c) 2025 Mastercard. All rights reserved.
   */
  ```

### 1.2 Package Declaration
- Use standard Java package naming (lowercase, domain-based).
- Example: `com.mastercard.gateway.acquiring`.

### 1.3 Import Statements
- Always use explicit imports. **Do NOT** use wildcard imports (`import *`).
- Group imports by package:
  - Java core (`java.*`)
  - Javax (`javax.*`)
  - Third-party libraries
  - Project-specific classes
- Separate groups with a blank line.

### 1.4 Class-Level Javadoc
- Every class/interface/enum/annotation/record/abstract class should have Javadoc:
  ```java
  /**
   * Represents the service for acquiring transactions.
   */
  ```

### 1.5 Class Declaration
- Use PascalCase for class/interface/enum names.
- Annotate with relevant Spring or other framework annotations if needed.
- Use generics where appropriate.

### 1.6 Field Declaration
- Use camelCase for instance/static fields.
- Use UPPER_SNAKE_CASE for constants.
- Use dependency injection (`@Autowired`) for Spring beans.
- Example:
  ```java
  private static final Logger LOG = LoggerFactory.getLogger(MyClass.class);
  ```
- Do **NOT** use prefixes like `m` or `_`.

### 1.7 Constructor
- Provide constructors for required dependencies (prefer constructor injection).

### 1.8 Method Template
- Use camelCase for method names.
- Each method should have a Javadoc comment describing its purpose.
- Keep methods concise and focused on a single responsibility.
- Declare local variables as close as possible to their use.
- Use custom exceptions for error handling; avoid catching generic exceptions.
- Log important events and errors.
- Avoid magic numbers/strings; use named constants.
- Braces on the same line as the declaration.
- Indentation: 4 spaces.
- Use spaces around operators, after commas, and between keywords and braces.
- Reasonable line length (70-120 characters).

### 1.9 Comments
- Use Javadoc for classes, interfaces, enums, annotations, records.
- Use inline comments to explain complex logic or non-obvious aspects.
- Do not wrap one-line comments.

### 1.10 Code Organization
- Each source file contains a single public class, interface, enum.
- Group related methods (e.g., getters/setters, overridden methods).
- Regularly refactor code to improve design and maintainability.

---

## **2. Additional Best Practices**
### Naming Conventions
- Classes: PascalCase (e.g., `PaymentProcessor`).
- Methods & variables: camelCase (e.g., `processPayment`).
- Constants: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`).

### Error Handling
- Use specific exceptions.
- Avoid swallowing exceptions; log them appropriately.
- Use `try-with-resources` for resource management.

### Performance Considerations
- Avoid unnecessary object creation.
- Use efficient data structures.
- Optimize loops and stream operations.

### Security Guidelines
- Validate all inputs.
- Avoid hardcoding sensitive data.
- Use secure APIs for cryptography and authentication.

---
## **3. Advanced Concepts**

### 3.1 Thread Safety & Concurrency Best Practices
- Use `synchronized` blocks or locks only when necessary.
- Prefer high-level concurrency utilities from `java.util.concurrent` (e.g., `ExecutorService`, `ConcurrentHashMap`).
- Avoid shared mutable state; use immutable objects where possible.
- Validate thread safety for singleton beans in Spring.

### 3.2 Logging Standards
- Use SLF4J with Logback or Log4j2 for logging.
- Define a static logger:
  ```java
  private static final Logger LOG = LoggerFactory.getLogger(MyClass.class);
  ```
- Log at appropriate levels: `INFO` for normal operations, `DEBUG` for troubleshooting, `ERROR` for failures.
- Avoid logging sensitive data.

### 3.3 Java 17+ Features Usage Guidelines
- Use `var` for local variable type inference where readability improves.
- Use `record` for immutable data carriers.
- Use `sealed` classes for controlled inheritance.
- Prefer `switch` expressions for cleaner branching.

### 3.4 Code Review Checklist
- Verify adherence to naming conventions.
- Ensure proper exception handling and logging.
- Check for thread safety in concurrent code.
- Validate performance optimizations.
- Confirm compliance with security standards.
- Ensure unit and integration tests are present and passing.

---
**Always refer to this document when creating or editing Java files to ensure compliance with coding standards and advanced practices.**
