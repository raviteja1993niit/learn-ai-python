# Optimization Patterns Knowledge Base

> **Auto-generated and maintained by Test Fixer & Code Optimizer Agent**
> Last Updated: 2026-01-22

This file stores discovered optimization patterns for reuse across the codebase.

---

## Java 17+ Feature Patterns

### 1. Switch Expressions

**Pattern ID:** `OPT-SWITCH-001`  
**Category:** Java 17+ Feature  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
// Old style switch with break statements
switch (variable) {
    case X:
        result = value1;
        break;
    case Y:
        result = value2;
        break;
    default:
        result = defaultValue;
        break;
}
```

**Optimization Template:**
```java
var result = switch (variable) {
    case X -> value1;
    case Y -> value2;
    default -> defaultValue;
};
```

**Applied In:**
- `TspiToElavonMessageMapper.java` - `getCardSchemeData()` method

---

### 2. Pattern Matching for instanceof

**Pattern ID:** `OPT-INSTANCEOF-001`  
**Category:** Java 17+ Feature  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
if (obj instanceof SomeType) {
    SomeType typed = (SomeType) obj;
    typed.doSomething();
}
```

**Optimization Template:**
```java
if (obj instanceof SomeType typed) {
    typed.doSomething();
}
```

---

### 3. Records for Immutable Data

**Pattern ID:** `OPT-RECORD-001`  
**Category:** Java 17+ Feature  
**Risk Level:** 🟡 Moderate

**Detection Pattern:**
```java
public final class DataClass {
    private final String field1;
    private final String field2;
    // Constructor, getters, equals, hashCode, toString
}
```

**Optimization Template:**
```java
public record DataClass(String field1, String field2) {}
```

**Considerations:**
- Only for immutable data carriers
- Cannot extend other classes
- All fields are final

---

### 4. Text Blocks

**Pattern ID:** `OPT-TEXTBLOCK-001`  
**Category:** Java 17+ Feature  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
String multiLine = "line1\n" +
    "line2\n" +
    "line3";
```

**Optimization Template:**
```java
String multiLine = """
    line1
    line2
    line3
    """;
```

---

## Lombok Patterns

### 5. Data Class with Lombok

**Pattern ID:** `OPT-LOMBOK-001`  
**Category:** Boilerplate Removal  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
public class MyClass {
    private String field;
    
    public String getField() { return field; }
    public void setField(String field) { this.field = field; }
    // equals, hashCode, toString...
}
```

**Optimization Template:**
```java
@Data
public class MyClass {
    private String field;
}
```

**Lombok Annotations Reference:**
| Annotation | Generates |
|------------|-----------|
| `@Getter` | Getter methods |
| `@Setter` | Setter methods |
| `@ToString` | toString() method |
| `@EqualsAndHashCode` | equals() and hashCode() |
| `@Data` | All of the above + @RequiredArgsConstructor |
| `@Builder` | Builder pattern |
| `@Slf4j` | Logger field |
| `@NoArgsConstructor` | No-args constructor |
| `@AllArgsConstructor` | All-args constructor |
| `@RequiredArgsConstructor` | Constructor for final fields |

---

### 6. Logger with Lombok

**Pattern ID:** `OPT-LOMBOK-002`  
**Category:** Boilerplate Removal  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
private static final Logger logger = LoggerFactory.getLogger(MyClass.class);
private static final Logger LOG = LoggerFactory.getLogger(MyClass.class);
```

**Optimization Template:**
```java
@Slf4j
public class MyClass {
    // Use: log.info(), log.debug(), log.error()
}
```

---

## Deduplication Patterns

### 7. Extract Common Method

**Pattern ID:** `OPT-DEDUP-001`  
**Category:** Deduplication  
**Risk Level:** 🟡 Moderate

**Detection Pattern:**
```java
// Same code block appearing in multiple methods
void methodA() {
    // common code block
    specificA();
}

void methodB() {
    // same common code block (copy-pasted)
    specificB();
}
```

**Optimization Template:**
```java
private void commonOperation() {
    // extracted common code
}

void methodA() {
    commonOperation();
    specificA();
}

void methodB() {
    commonOperation();
    specificB();
}
```

---

### 8. Map Instead of Switch for Lookups

**Pattern ID:** `OPT-DEDUP-002`  
**Category:** Deduplication  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
switch (key) {
    case "A": return valueA;
    case "B": return valueB;
    case "C": return valueC;
    default: return defaultValue;
}
```

**Optimization Template:**
```java
private static final Map<String, Value> LOOKUP = Map.of(
    "A", valueA,
    "B", valueB,
    "C", valueC
);

return LOOKUP.getOrDefault(key, defaultValue);
```

---

### 9. Constants for Magic Values

**Pattern ID:** `OPT-CONST-001`  
**Category:** Code Quality  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
if (code.equals("000")) { ... }
if (amount > 10000) { ... }
String url = "https://api.example.com/v1";
```

**Optimization Template:**
```java
private static final String ACTION_CODE_APPROVED = "000";
private static final BigDecimal HIGH_VALUE_THRESHOLD = new BigDecimal("10000");
private static final String API_BASE_URL = "https://api.example.com/v1";

if (code.equals(ACTION_CODE_APPROVED)) { ... }
if (amount.compareTo(HIGH_VALUE_THRESHOLD) > 0) { ... }
```

---

## Stream API Patterns

### 10. Filter and Collect

**Pattern ID:** `OPT-STREAM-001`  
**Category:** Stream API  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
List<T> result = new ArrayList<>();
for (T item : items) {
    if (condition(item)) {
        result.add(item);
    }
}
```

**Optimization Template:**
```java
List<T> result = items.stream()
    .filter(this::condition)
    .toList();  // Java 16+
```

---

### 11. Grouping By

**Pattern ID:** `OPT-STREAM-002`  
**Category:** Stream API  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
Map<K, List<V>> grouped = new HashMap<>();
for (V item : items) {
    K key = getKey(item);
    grouped.computeIfAbsent(key, k -> new ArrayList<>()).add(item);
}
```

**Optimization Template:**
```java
Map<K, List<V>> grouped = items.stream()
    .collect(Collectors.groupingBy(this::getKey));
```

---

## Structure Improvement Patterns

### 12. Early Return / Guard Clause

**Pattern ID:** `OPT-STRUCT-001`  
**Category:** Code Structure  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
if (condition1) {
    if (condition2) {
        if (condition3) {
            // actual logic
        }
    }
}
```

**Optimization Template:**
```java
if (!condition1) return;
if (!condition2) return;
if (!condition3) return;

// actual logic (flat structure)
```

---

### 13. Extract Method for Complex Conditions

**Pattern ID:** `OPT-STRUCT-002`  
**Category:** Code Structure  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
if (a && b || c && (d || e) && !f) {
    // logic
}
```

**Optimization Template:**
```java
if (isValidTransaction(a, b, c, d, e, f)) {
    // logic
}

private boolean isValidTransaction(boolean a, boolean b, boolean c, 
                                    boolean d, boolean e, boolean f) {
    boolean condition1 = a && b;
    boolean condition2 = c && (d || e);
    return condition1 || (condition2 && !f);
}
```

---

## Type Safety Patterns

### 14. Enum Instead of String Constants

**Pattern ID:** `OPT-ENUM-001`  
**Category:** Type Safety  
**Risk Level:** 🟡 Moderate

**Detection Pattern:**
```java
// String with space/delimiter for multiple values
String status = "PENDING APPROVED REJECTED";
String[] statuses = status.split(" ");

// Magic string comparisons
if (type.equals("AUTH")) { ... }
if (type.equals("CAPTURE")) { ... }

// String constants scattered
public static final String TYPE_AUTH = "AUTH";
public static final String TYPE_CAPTURE = "CAPTURE";
```

**Optimization Template:**
```java
public enum TransactionStatus {
    PENDING, APPROVED, REJECTED
}

public enum TransactionType {
    AUTH, CAPTURE, REFUND, VOID;
    
    public static TransactionType fromString(String value) {
        return valueOf(value.toUpperCase());
    }
}

// Usage
if (type == TransactionType.AUTH) { ... }
```

**Benefits:**
- Compile-time type safety
- IDE auto-completion
- No typos possible
- Self-documenting code

---

### 15. Enum with Properties

**Pattern ID:** `OPT-ENUM-002`  
**Category:** Type Safety  
**Risk Level:** 🟢 Safe

**Detection Pattern:**
```java
// Map or switch for value lookup
String getCode(String type) {
    switch(type) {
        case "VISA": return "VC";
        case "MASTERCARD": return "MC";
        default: return "";
    }
}
```

**Optimization Template:**
```java
public enum CardScheme {
    VISA("VC", "Visa"),
    MASTERCARD("MC", "Mastercard"),
    AMEX("AE", "American Express");
    
    private final String code;
    private final String displayName;
    
    CardScheme(String code, String displayName) {
        this.code = code;
        this.displayName = displayName;
    }
    
    public String getCode() { return code; }
    public String getDisplayName() { return displayName; }
}
```

---

## SonarQube Issue Patterns

### 16. Cognitive Complexity (S3776)

**Pattern ID:** `SONAR-S3776`  
**Category:** SonarQube  
**Risk Level:** 🟡 Moderate  
**Sonar Rule:** Cognitive Complexity of methods should not be too high

**Detection Pattern:**
```java
// High cognitive complexity (nested conditions, loops)
void process(Request req) {
    if (req != null) {
        if (req.isValid()) {
            for (Item item : req.getItems()) {
                if (item.getType().equals("A")) {
                    if (item.getValue() > 0) {
                        // deep nesting...
                    }
                }
            }
        }
    }
}
```

**Optimization Template:**
```java
void process(Request req) {
    if (!isValidRequest(req)) return;
    
    req.getItems().stream()
        .filter(this::isProcessableItem)
        .forEach(this::processItem);
}

private boolean isValidRequest(Request req) {
    return req != null && req.isValid();
}

private boolean isProcessableItem(Item item) {
    return "A".equals(item.getType()) && item.getValue() > 0;
}
```

---

### 17. String Literal Duplication (S1192)

**Pattern ID:** `SONAR-S1192`  
**Category:** SonarQube  
**Risk Level:** 🟢 Safe  
**Sonar Rule:** String literals should not be duplicated

**Detection Pattern:**
```java
log.info("Processing transaction");
// ... elsewhere
log.debug("Processing transaction");
// ... elsewhere
throw new Exception("Processing transaction failed");
```

**Optimization Template:**
```java
private static final String MSG_PROCESSING = "Processing transaction";

log.info(MSG_PROCESSING);
log.debug(MSG_PROCESSING);
throw new Exception(MSG_PROCESSING + " failed");
```

---

### 18. Raw Types (S3740)

**Pattern ID:** `SONAR-S3740`  
**Category:** SonarQube  
**Risk Level:** 🟢 Safe  
**Sonar Rule:** Raw types should not be used

**Detection Pattern:**
```java
List items = new ArrayList();
Map data = new HashMap();
```

**Optimization Template:**
```java
List<Item> items = new ArrayList<>();
Map<String, Object> data = new HashMap<>();
```

---

### 19. Null Check Before instanceof (S4201)

**Pattern ID:** `SONAR-S4201`  
**Category:** SonarQube  
**Risk Level:** 🟢 Safe  
**Sonar Rule:** Null check is redundant before instanceof

**Detection Pattern:**
```java
if (obj != null && obj instanceof String) {
    String s = (String) obj;
}
```

**Optimization Template:**
```java
// instanceof already handles null
if (obj instanceof String s) {  // Java 17+ pattern matching
    // use s directly
}
```

---

### 20. Empty Catch Block (S108)

**Pattern ID:** `SONAR-S108`  
**Category:** SonarQube  
**Risk Level:** 🔴 Critical  
**Sonar Rule:** Nested blocks of code should not be empty

**Detection Pattern:**
```java
try {
    doSomething();
} catch (Exception e) {
    // empty - swallowing exception
}
```

**Optimization Template:**
```java
try {
    doSomething();
} catch (Exception e) {
    log.error("Failed to do something", e);
    throw new ServiceException("Operation failed", e);
}
```

---

### 21. Unused Method Parameters (S1172)

**Pattern ID:** `SONAR-S1172`  
**Category:** SonarQube  
**Risk Level:** 🟢 Safe  
**Sonar Rule:** Unused method parameters should be removed

**Detection Pattern:**
```java
public void process(String data, String unusedParam) {
    // unusedParam is never used
    System.out.println(data);
}
```

**Optimization Template:**
```java
public void process(String data) {
    System.out.println(data);
}
```

---

### 22. Hardcoded Credentials (S2068)

**Pattern ID:** `SONAR-S2068`  
**Category:** SonarQube Security  
**Risk Level:** 🔴 Critical  
**Sonar Rule:** Credentials should not be hard-coded

**Detection Pattern:**
```java
String password = "admin123";
String apiKey = "sk-abc123xyz";
```

**Optimization Template:**
```java
// Use environment variables or secure vault
String password = System.getenv("DB_PASSWORD");
String apiKey = configService.getSecret("API_KEY");
```

---

### 23. Synchronized on Non-final Field (S2445)

**Pattern ID:** `SONAR-S2445`  
**Category:** SonarQube  
**Risk Level:** 🔴 Critical  
**Sonar Rule:** Blocks should be synchronized on non-reassignable fields

**Detection Pattern:**
```java
private Object lock = new Object();  // non-final

synchronized(lock) {
    // critical section
}
```

**Optimization Template:**
```java
private final Object lock = new Object();  // final

synchronized(lock) {
    // critical section
}
```

---

### 24. Utility Class Constructor (S1118)

**Pattern ID:** `SONAR-S1118`  
**Category:** SonarQube  
**Risk Level:** 🟢 Safe  
**Sonar Rule:** Utility classes should not have public constructors

**Detection Pattern:**
```java
public class StringUtils {
    public static String trim(String s) { ... }
    // implicit public constructor
}
```

**Optimization Template:**
```java
@UtilityClass  // Lombok
public class StringUtils {
    public static String trim(String s) { ... }
}

// Or without Lombok:
public final class StringUtils {
    private StringUtils() {
        throw new UnsupportedOperationException("Utility class");
    }
    public static String trim(String s) { ... }
}
```

---

### 25. Use try-with-resources (S2095)

**Pattern ID:** `SONAR-S2095`  
**Category:** SonarQube  
**Risk Level:** 🟡 Moderate  
**Sonar Rule:** Resources should be closed

**Detection Pattern:**
```java
InputStream is = new FileInputStream(file);
try {
    // use stream
} finally {
    is.close();
}
```

**Optimization Template:**
```java
try (InputStream is = new FileInputStream(file)) {
    // use stream
}  // auto-closed
```

---

### 26. Optional.get() Without isPresent() (S3655)

**Pattern ID:** `SONAR-S3655`  
**Category:** SonarQube  
**Risk Level:** 🟡 Moderate  
**Sonar Rule:** Optional value should only be accessed after calling isPresent()

**Detection Pattern:**
```java
Optional<User> user = findUser(id);
String name = user.get().getName();  // may throw NoSuchElementException
```

**Optimization Template:**
```java
Optional<User> user = findUser(id);
String name = user.map(User::getName).orElse("Unknown");

// Or
String name = user.orElseThrow(() -> 
    new UserNotFoundException(id)).getName();
```

---

### 27. Field Injection (S3306)

**Pattern ID:** `SONAR-S3306`  
**Category:** SonarQube Spring  
**Risk Level:** 🟡 Moderate  
**Sonar Rule:** Constructor injection should be used instead of field injection

**Detection Pattern:**
```java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;
}
```

**Optimization Template:**
```java
@Service
@RequiredArgsConstructor  // Lombok
public class UserService {
    private final UserRepository userRepository;
}
```

---

## Optimization Statistics

| Category | Patterns | Applied Count |
|----------|----------|---------------|
| Java 17+ Features | 4 | 0 |
| Lombok | 2 | 0 |
| Deduplication | 3 | 0 |
| Stream API | 2 | 0 |
| Code Structure | 2 | 0 |
| Type Safety | 2 | 0 |
| SonarQube | 12 | 0 |
| **Total** | **27** | **0** |

---

## Version History

| Date | Change | Patterns Added |
|------|--------|----------------|
| 2026-01-22 | Initial optimization patterns library | 13 |
| 2026-01-22 | Added Enum patterns for type safety | 2 |
| 2026-01-22 | Added SonarQube issue patterns | 12 |
