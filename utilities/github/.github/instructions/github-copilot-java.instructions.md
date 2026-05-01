title: GitHub Copilot Java Guidelines
description: Comprehensive, universal, and optimized guidelines for Java development using GitHub Copilot.

# ✅ GitHub Copilot Java Development Guidelines

---

## **1. Purpose & Scope**
This document provides a 360° perspective for enterprise-grade Java development, including:
- Coding standards and naming conventions.
- Code explanation guidelines.
- Advanced Java features (Java 8-17).
- Testing strategies.
- Code review checklist.

---

## **2. Code Explanation Guidelines**
When reviewing or generating Java code:
- Explain **what the class does overall**.
- Describe **each public method** and its purpose.
- Provide **logic in plain English**.
- Highlight **potential pitfalls** in implementation.
- Suggest **one real-world use case**.

### Example Questions:
- "Explain OrderService.java in simple words"
- "What does calculateTotal() do?"
- "What real-world example fits this class?"

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

### 3.3 Class-Level Javadoc
```java
/**
 * Represents the service for processing orders.
 */
```

### 3.4 Class Declaration & Field Declaration
- Use PascalCase for classes, camelCase for fields.
- Constants in UPPER_SNAKE_CASE.
- Example:
```java
private static final Logger LOG = LoggerFactory.getLogger(MyClass.class);
```

### 3.5 Constructor & Method Template
- Prefer constructor injection.
- Methods should:
  - Use camelCase.
  - Include Javadoc.
  - Avoid magic numbers; use constants.

### 3.6 Comments & Code Organization
- Use Javadoc for classes and methods.
- Inline comments for complex logic.
- One public class per file.

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
- Use JUnit 5 for unit tests.
- Mock dependencies with Mockito.
- Use @SpringBootTest for integration tests.
- Apply Testcontainers for real DB testing.

---

## **7. Code Review Checklist**
- Naming conventions followed.
- No unused imports.
- Proper exception handling.
- Logging standards applied.
- Unit and integration tests present.
- Security and performance considerations.

---

**Always refer to this document for coding standards, explanations, and best practices.**
