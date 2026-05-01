applyTo: "*.java"
description: "This document defines coding rules, conventions, templates, optimal Java features (Java 8-17), and advanced best practices for enterprise-grade development."

# ✅ Comprehensive Java Coding Best Practices & Language Features

---

## **1. Java Source File Header Template & Instructions**
### 1.1 File Header
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
```

### 1.2 Package Declaration
- Use lowercase, domain-based naming: `com.mastercard.gateway.acquiring`.

### 1.3 Import Statements
- Use explicit imports; avoid wildcard imports.
- Group imports logically: Java core, third-party, project-specific.

### 1.4 Class-Level Javadoc
```java
/**
 * Represents the service for acquiring transactions.
 */
```

### 1.5 Class Declaration
- Use PascalCase for class names.
- Annotate with relevant framework annotations.

### 1.6 Field Declaration
- camelCase for fields, UPPER_SNAKE_CASE for constants.
- Example:
```java
private static final Logger LOG = LoggerFactory.getLogger(MyClass.class);
```

### 1.7 Constructor
- Prefer constructor injection for dependencies.

### 1.8 Method Template
- camelCase for method names.
- Javadoc for each method.
- Avoid magic numbers; use constants.

### 1.9 Comments
- Use Javadoc for classes and methods.
- Inline comments for complex logic.

### 1.10 Code Organization
- One public class per file.
- Group related methods logically.

---

## **2. Best Naming Conventions**
- **Packages:** lowercase, domain-based (e.g., `com.company.project.module`).
- **Classes & Interfaces:** PascalCase (e.g., `PaymentProcessor`).
- **Enums:** PascalCase (e.g., `TransactionStatus`).
- **Methods:** camelCase (e.g., `processPayment`).
- **Variables:** camelCase (e.g., `retryCount`).
- **Constants:** UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`).
- **Generics:** Use single uppercase letters (e.g., `T`, `E`).

---

## **3. Intent-Driven Best Practices**
- Write code for **clarity and readability**.
- Favor **maintainability and scalability** over micro-optimizations.
- Keep methods focused on **single responsibility**.
- Use meaningful names that convey intent.
- Avoid abbreviations unless universally understood.

---

## **4. Advanced Guidelines**
### Immutability
- Prefer immutable classes for thread safety.
- Use `final` for fields where possible.

### SOLID Principles
- **S**ingle Responsibility: One reason to change.
- **O**pen/Closed: Open for extension, closed for modification.
- **L**iskov Substitution: Subtypes must be substitutable.
- **I**nterface Segregation: No unnecessary methods.
- **D**ependency Inversion: Depend on abstractions.

### Clean Code Patterns
- DRY (Don’t Repeat Yourself).
- KISS (Keep It Simple, Stupid).
- YAGNI (You Aren’t Gonna Need It).

---

## **5. Optimal Java Features (Java 8 - Java 17)**
### Java 8
- Lambdas & Streams:
```java
names.stream().filter(n -> n.startsWith("A")).forEach(System.out::println);
```
- Optional:
```java
Optional<String> value = Optional.ofNullable(getValue());
```
- Date/Time API:
```java
LocalDate today = LocalDate.now();
```

### Java 9
- Modules:
```java
module com.example.myapp { requires java.sql; }
```
- JShell for interactive coding.

### Java 10
- var for local variables:
```java
var list = new ArrayList<String>();
```

### Java 11
- HTTP Client:
```java
HttpClient client = HttpClient.newHttpClient();
```
- String methods:
```java
" test ".isBlank();
```

### Java 12 & 13
- Switch Expressions:
```java
String result = switch(day) {
    case MONDAY -> "Start";
    default -> "Other";
};
```

### Java 14
- Records:
```java
public record Point(int x, int y) {}
```

### Java 15
- Text Blocks:
```java
String json = 