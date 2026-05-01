title: Code Explainer Guidelines
description: Comprehensive and universal guidelines for explaining Java classes and methods in plain English.

# ✅ Code Explainer Guidelines for GitHub Copilot

---

## **1. Introduction**
The purpose of this guide is to help developers and AI assistants explain Java code clearly and effectively. Code explanation improves understanding, aids debugging, and enhances maintainability.

Benefits:
- Makes complex logic accessible.
- Helps beginners learn faster.
- Improves collaboration and documentation quality.

---

## **2. Core Principles for Code Explanation**
When given Java code, explain:
- **What the class does overall**: Summarize its responsibility and role.
- **Each public method**: Describe its purpose, parameters, return type, and logic.
- **Logic in plain English**: Break down complex operations into simple steps.
- **Potential pitfalls**: Highlight issues like null handling, concurrency, performance bottlenecks.
- **One real-world use case**: Provide practical examples of where this class or method is applied.

Keep answers beginner-friendly and concise while maintaining technical accuracy.

---

## **3. Structured Explanation Template**
```text
Class Name: OrderService
Purpose: Handles order processing and validation.
Public Methods:
- calculateTotal(): Computes total price of items.
Logic: Iterates through items, sums prices, applies discounts.
Pitfalls: Ensure proper rounding and currency handling.
Real-World Use Case: E-commerce checkout system.
```

---

## **4. Best Practices for Clarity and Readability**
- Use simple language for complex logic.
- Avoid jargon unless necessary.
- Provide examples for better understanding.
- Highlight assumptions and edge cases.

---

## **5. Common Pitfalls in Java Code**
- **Null Handling**: Always check for null values.
- **Concurrency Issues**: Synchronize shared resources.
- **Performance**: Avoid unnecessary loops and object creation.
- **Security**: Validate inputs and avoid hardcoded credentials.

---

## **6. Example Explanations**
### Simple Class Example:
```java
public class Calculator {
    public int add(int a, int b) { return a + b; }
}
```
Explanation:
- Class: Calculator performs basic arithmetic operations.
- Method add(): Adds two integers and returns the sum.
- Pitfalls: None for basic addition.
- Use Case: Used in financial calculations or simple math utilities.

### Complex Class Example:
```java
public class PaymentProcessor {
    public boolean processPayment(Order order) {
        // logic for payment processing
    }
}
```
Explanation:
- Class: Handles payment transactions.
- Method processPayment(): Validates order, interacts with payment gateway.
- Pitfalls: Network failures, transaction rollback.
- Use Case: Online shopping platforms.

---

## **7. Integration with GitHub Copilot Prompts**
Sample Prompts:
- "Explain OrderService.java in simple words"
- "What does calculateTotal() do?"
- "What real-world example fits this class?"

---

## **8. Additional Guidelines**
- Ensure explanations are context-aware.
- Provide links to official documentation for advanced topics.
- Suggest improvements or refactoring ideas when relevant.

---

**Always aim for clarity, completeness, and practical relevance in code explanations.**
