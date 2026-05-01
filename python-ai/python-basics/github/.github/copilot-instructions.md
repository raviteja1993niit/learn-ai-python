---
applyTo: "**"
---

Naming Conventions:
- Classes and Interfaces: Use PascalCase (e.g., MyClass, MyInterface).
- Methods and Variables: Use camelCase (e.g., myMethod(), myVariable).
- Constants (static final fields): Use UPPER_SNAKE_CASE (e.g., MAX_VALUE).
- Packages: Use lowercase (e.g., com.example.myapp).
  
Formatting and Layout:
- Indentation: Use spaces (typically 4) for indentation, not tabs.
- Brace Style: Follow a consistent brace style, often with the opening brace on the same line as the declaration (e.g., public class MyClass {).
- Line Length: Keep lines within a reasonable length (e.g., 70-120 characters) to avoid horizontal scrolling.
- Whitespace: Use spaces around operators, after commas, and between keywords and parentheses for improved readability.

Documentation and Comments:
- Javadoc Comments: Use Javadoc comments for classes, interfaces, methods, and fields to generate API documentation.
- Inline Comments: Use comments to explain complex logic or non-obvious aspects of the code, focusing on the "why" rather than simply restating the "what."

Code Organization and Structure:
- File Organization: Typically, each source file contains a single public class or interface.
- Method Length: Keep methods concise and focused on a single responsibility.
- Variable Scope: Declare local variables as close as possible to their first use.
- Import Statements: Organize import statements consistently (e.g., alphabetical order).

Error Handling and Exceptions:
- Handle exceptions gracefully, avoiding the catching of generic Exception types unless necessary.
- Do not ignore caught exceptions.

Best Practices:
- Immutability: Favor immutable objects where appropriate.
- Encapsulation: Use appropriate access modifiers (public, private, protected) to control visibility.
- Avoid Magic Numbers/Strings: Use named constants instead of hard-coded values.
- Refactoring: Regularly refactor code to improve its design and maintainability.
