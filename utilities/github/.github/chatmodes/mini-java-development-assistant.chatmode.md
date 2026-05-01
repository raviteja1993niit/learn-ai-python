title: GitHub Copilot Java Guidelines
description: Comprehensive, universal, and optimized guidelines for Java development using GitHub Copilot.

# ✅ GitHub Copilot Java Development Guidelines

---

## **1. Introduction**
GitHub Copilot is an AI-powered coding assistant that helps developers write code faster and with fewer errors. This guide provides:
- Enterprise-grade Java coding standards.
- Best practices for maintainability, scalability, and security.
- Detailed instructions for leveraging Copilot effectively.

Benefits:
- Accelerates development.
- Improves code quality.
- Reduces repetitive tasks.

---

## **2. Code Explanation Guidelines**
When reviewing or generating Java code:
- **Class Overview:** Explain what the class does and its role in the application.
- **Method Details:** Describe each public method, its parameters, return type, and logic.
- **Plain English Logic:** Summarize complex logic in simple terms.
- **Pitfalls:** Highlight potential issues (e.g., null handling, concurrency).
- **Real-World Use Case:** Suggest practical applications.

### Template:
```text
Class: OrderService
Purpose: Handles order processing and validation.
Methods:
- calculateTotal(): Computes total price of items.
Pitfalls: Ensure proper rounding and currency handling.
Use Case: E-commerce checkout system.
```

---

## **3. Coding Standards**
### 3.1 File Header & Package Declaration
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.example.project;
```

### 3.2 Import Statements
- Use explicit imports; avoid wildcard imports.
- Group imports logically: Java core, third-party, project-specific.

### 3.3 Naming Conventions
- Classes: PascalCase (e.g., PaymentProcessor).
- Methods & variables: camelCase (e.g., processPayment).
- Constants: UPPER_SNAKE_CASE (e.g., MAX_RETRY_COUNT).

### 3.4 Javadoc & Comments
- Provide Javadoc for classes and methods.
- Inline comments for complex logic.

### 3.5 Error Handling
- Use specific exceptions.
- Avoid swallowing exceptions; log appropriately.

---

## **4. Best Practices & Principles**
- Apply SOLID principles.
- Follow DRY, KISS, YAGNI.
- Prefer immutability for thread safety.
- Use meaningful names that convey intent.

---

## **5. Advanced Java Features (Java 8-17)**
### Java 8
- Lambdas, Streams, Optional, Date/Time API.
Example:
```java
list.stream().filter(x -> x > 10).forEach(System.out::println);
```
### Java 9
- Modules, JShell.
### Java 10
- var for local variables.
### Java 11
- HTTP Client, String enhancements.
### Java 12-13
- Switch Expressions.
### Java 14
- Records.
### Java 15
- Text Blocks.
### Java 16
- Pattern Matching.
### Java 17
- Sealed Classes.

---

## **6. Testing Guidelines**
### Unit Testing
- Use JUnit 5.
- Mock dependencies with Mockito.
### Integration Testing
- Use @SpringBootTest.
- Apply Testcontainers for DB testing.
### Performance Testing
- Use JMH for benchmarks.
### Security Testing
- Validate input sanitization and authentication flows.

---

## **7. CI/CD Integration**
- Automate tests with Maven/Gradle.
- Use GitHub Actions for pipelines.
- Generate coverage reports with JaCoCo.

---

## **8. Logging Standards**
- Use SLF4J with Logback.
- Log at appropriate levels (INFO, DEBUG, ERROR).
- Avoid logging sensitive data.

---

## **9. Documentation Best Practices**
- Maintain README with setup instructions.
- Use Markdown for clarity.
- Include architecture diagrams.

---

## **10. Code Review Checklist**
- Naming conventions followed.
- No unused imports.
- Proper exception handling.
- Logging standards applied.
- Unit and integration tests present.
- Security and performance considerations.
- Code is readable and maintainable.

---

**Always refer to this document for coding standards, explanations, and best practices.**
