# Python Core — Hands-On Practical Exercises
## 10 Projects to Cement Your Skills

---

## Exercise 1: Calculator App

### Objective
Build a command-line calculator that handles all arithmetic operations and
recovers gracefully from bad input.

### Requirements
- Support: `+`, `-`, `*`, `/`, `%`, `**` (power)
- Handle division by zero explicitly
- Validate that inputs are numeric — no crashes on letters
- Loop until the user types `quit`
- Display a help menu listing operations

### Hints
- Use `while True` with `break` on `quit`
- Wrap `float()` conversion in `try/except ValueError`
- Catch `ZeroDivisionError` separately
- Store operations in a dict: `{"+": lambda a,b: a+b, ...}`

### Sample Output
```
=== Python Calculator ===
Operations: +  -  *  /  %  **  (type 'quit' to exit)
Expression: 10 / 3
  Result: 3.3333
Expression: 5 / 0
  Error: Division by zero
Expression: abc + 1
  Error: Invalid number 'abc'
Expression: quit
  Goodbye!
```

### Starter Code
```python
import operator

OPS = {
    "+": operator.add,  "-": operator.sub,
    "*": operator.mul,  "/": operator.truediv,
    "%": operator.mod,  "**": operator.pow,
}

def calculate(expr):
    parts = expr.split()
    if len(parts) != 3:
        raise ValueError("Use format: number operator number")
    a_str, op, b_str = parts
    a, b = float(a_str), float(b_str)
    if op not in OPS:
        raise ValueError(f"Unknown operator: {op}")
    if op == "/" and b == 0:
        raise ZeroDivisionError("Division by zero")
    return OPS[op](a, b)

# TODO: Add the main REPL loop
```

---

## Exercise 2: Contact Book

### Objective
Implement a full CRUD contact management system using dictionaries,
with JSON persistence so data survives between runs.

### Requirements
- Add a contact (name, phone, email)
- View all contacts in a formatted table
- Search by name (case-insensitive, partial match)
- Update any field of an existing contact
- Delete a contact
- Load from `contacts.json` on startup; save on exit

### Hints
- Key the master dict by `name.lower()` for O(1) lookup
- `json.dump(contacts, f, indent=2)` / `json.load(f)` for persistence
- Guard `json.load` with `try/except FileNotFoundError`
- Use `f"{name:<20} {phone:<15} {email}"` for table alignment

### Sample Output
```
=== Contact Book ===
1) Add   2) View   3) Search   4) Update   5) Delete   6) Quit
Choice: 1
  Name  : Alice
  Phone : 555-1234
  Email : alice@example.com
  Saved!

Choice: 3
  Search: ali
  Alice | 555-1234 | alice@example.com
```

### Key Data Structure
```python
contacts = {
    "alice": {
        "name": "Alice",
        "phone": "555-1234",
        "email": "alice@example.com",
    }
}
```

---

## Exercise 3: Word Frequency Counter

### Objective
Read a text file, count word frequencies, and display a sorted report
including a simple ASCII bar chart.

### Requirements
- Accept a filename from the user or `sys.argv`
- Handle `FileNotFoundError` gracefully
- Strip punctuation and normalise to lowercase
- Show top-N most frequent words (N is configurable)
- Display total and unique word counts

### Hints
- `re.findall(r"\b[a-z]+\b", text.lower())` gives clean words
- `collections.Counter` handles frequency counting
- `counter.most_common(n)` returns sorted top-N list
- Build bar: `"#" * int(count / max_count * 20)` for scaling

### Sample Output
```
File: sample.txt  |  Total: 1,024 words  |  Unique: 382
Top 10 most frequent words:
  the            78  ####################
  of             45  ############
  and            41  ###########
  to             38  ##########
  a              35  #########
```

### Extension Ideas
- Export results to a CSV file
- Add a `--ignore` option to skip common stop-words
- Plot with `matplotlib` if available

---

## Exercise 4: Student Grade System

### Objective
Manage a class roster with multiple scores per student, compute statistics,
and print formatted report cards.

### Requirements
- Store students as a list of dicts: `{"name": str, "scores": [float]}`
- Compute: average, highest score, lowest score per student
- Assign letter grades: A ≥ 90, B ≥ 80, C ≥ 70, D ≥ 60, F < 60
- Print a formatted report card table for all students
- Identify the class topper (highest average)

### Hints
- Helper: `def letter_grade(avg): ...` with if/elif chain
- `sum(scores) / len(scores)` for average
- `max(students, key=lambda s: average(s["scores"]))` for topper
- Use `f"{name:<20} {avg:6.2f}  {grade}"` for alignment

### Sample Output
```
============================================
           STUDENT REPORT CARD
============================================
Name                   Avg   Grade
--------------------------------------------
Alice                94.33   A   <- TOP
Bob                  78.67   C
Carol                88.00   B
Dave                 61.50   D
============================================
Class average: 80.63
```

---

## Exercise 5: Number Guessing Game

### Objective
Build an interactive guessing game with difficulty levels and a
persistent best-score tracker.

### Requirements
- Player chooses difficulty: Easy (1–50, 10 guesses), Medium (1–100, 7),
  Hard (1–200, 5)
- After each guess: "Too high", "Too low", or "Correct!"
- Display remaining guesses after each attempt
- Validate input — reject non-numeric entries without ending the game
- Track best score (fewest guesses to win) across games in the session

### Hints
- `random.randint(low, high)` picks the secret number
- `while guesses_left > 0` controls the game loop
- Wrap `int(input(...))` in `try/except ValueError`
- Update best score only when the player wins

### Sample Output
```
=== Number Guessing Game ===
Difficulty [E/M/H]: M
Range: 1-100  |  Guesses: 7

Guess 1/7: 50
  Too low!
Guess 2/7: 75
  Too high!
Guess 3/7: 63
  Correct! You won in 3 guesses.
Best score this session: 3
Play again? [y/n]:
```

---

## Exercise 6: Caesar Cipher

### Objective
Implement Caesar cipher encryption and decryption that handles any
printable text, preserving case and non-alpha characters.

### Requirements
- Encrypt: shift each letter forward by `key` positions (0–25)
- Decrypt: shift each letter backward by `key` positions
- Preserve case (uppercase stays uppercase, lowercase stays lowercase)
- Leave spaces, punctuation, and digits unchanged
- Loop: let user encode/decode repeatedly until they quit

### Hints
- `ord(ch) - ord('A')` gives a 0–25 offset for uppercase letters
- `% 26` wraps around the alphabet
- Build a `str.maketrans` table as an alternative to char-by-char loop
- `mode == "decode"` is equivalent to encoding with `-key`

### Sample Output
```
Caesar Cipher  (type 'quit' to exit)
Mode   [encode/decode]: encode
Message: Hello, World!
Key    [0-25]        : 13
Result : Uryyb, Jbeyq!

Mode   [encode/decode]: decode
Message: Uryyb, Jbeyq!
Key    [0-25]        : 13
Result : Hello, World!
```

### Core Logic
```python
def caesar(text, shift, mode="encode"):
    if mode == "decode":
        shift = -shift
    result = []
    for ch in text:
        if ch.isalpha():
            base = ord('A') if ch.isupper() else ord('a')
            result.append(chr((ord(ch) - base + shift) % 26 + base))
        else:
            result.append(ch)
    return "".join(result)
```

---

## Exercise 7: CSV Data Analyser

### Objective
Load a sales CSV, compute revenue and quantity totals per product, and
produce a formatted summary report.

### Requirements
- Read a CSV with columns: `date, product, quantity, price`
- Handle `FileNotFoundError` and malformed rows gracefully
- Calculate: total revenue, revenue per product, units sold per product
- Find the best seller by quantity and by revenue
- Display results in an aligned table

### Hints
- `csv.DictReader` provides named column access
- `float(row["price"]) * int(row["quantity"])` for row revenue
- `defaultdict(float)` and `defaultdict(int)` for running totals
- `sorted(revenue.items(), key=lambda x: x[1], reverse=True)` for ranking

### Sample CSV (sales.csv)
```csv
date,product,quantity,price
2024-01-01,Widget A,5,9.99
2024-01-01,Widget B,2,24.99
2024-01-02,Widget A,3,9.99
2024-01-02,Widget C,1,49.99
2024-01-03,Widget B,4,24.99
```

### Sample Output
```
=== Sales Analysis Report ===
Total Transactions : 5
Total Revenue      : $299.83
Avg Transaction    : $59.97

Product          Units   Revenue
---------------------------------
Widget B             6   $149.94
Widget A             8    $79.92
Widget C             1    $49.99
---------------------------------
Best Seller (qty) : Widget A (8 units)
Best Seller (rev) : Widget B ($149.94)
```

---

## Exercise 8: Shopping Cart

### Objective
Implement a shopping cart system that demonstrates nested dicts, arithmetic
and formatted output working together.

### Requirements
- Browse a product catalog (dict: name -> price)
- Add items with quantity; update quantity if item already in cart
- Remove items or decrease quantity
- Display cart with subtotals, tax (8%), and grand total
- Support at least two discount codes (e.g., `SAVE10` for 10% off)

### Hints
- Cart: `dict` keyed by product name, value = `{"price": float, "qty": int}`
- Subtotal = `sum(item["price"] * item["qty"] for item in cart.values())`
- Grand total = `(subtotal - discount) * (1 + tax_rate)`
- Format with `f"${amount:>8.2f}"` for column alignment

### Sample Output
```
=== Shopping Cart ===
Product          Qty   Unit $   Subtotal
-----------------------------------------
Apple              3    1.29      3.87
Bread              1    3.49      3.49
Milk               2    2.99      5.98
-----------------------------------------
Subtotal                         13.34
Discount (SAVE10)                -1.33
Tax (8%)                          0.96
-----------------------------------------
TOTAL                            12.97
```

---

## Exercise 9: Temperature Converter

### Objective
Build a converter between Celsius, Fahrenheit, and Kelvin with input
validation and absolute-zero enforcement.

### Requirements
- Accept input as `"37 C"`, `"98.6 F"`, `"310 K"` (value then unit)
- Convert to the other two scales and display all three
- Reject temperatures below absolute zero (−273.15 °C)
- Handle non-numeric values without crashing
- Loop until user enters `quit`

### Hints
- `parts = input().split()` then `value, unit = float(parts[0]), parts[1].upper()`
- Convert everything to Celsius first, then to the target units
- Raise `ValueError` for below-absolute-zero inputs
- Store conversion formulas in dicts of lambdas

### Conversion Formulas
```python
to_celsius = {
    "F": lambda f: (f - 32) * 5 / 9,
    "K": lambda k: k - 273.15,
    "C": lambda c: c,
}
from_celsius = {
    "C": lambda c: c,
    "F": lambda c: c * 9 / 5 + 32,
    "K": lambda c: c + 273.15,
}
ABSOLUTE_ZERO_C = -273.15
```

### Sample Output
```
Temperature Converter  (e.g., '100 C' or 'quit')
Input: 100 C
  100.00 °C  =  212.00 °F  =  373.15 K

Input: 32 F
  32.00 °F  =  0.00 °C  =  273.15 K

Input: -300 C
  Error: -300.00 °C is below absolute zero (-273.15 °C)

Input: quit
  Goodbye!
```

---

## Exercise 10: Mini Bank Account (OOP Warmup via Dicts)

### Objective
Simulate a bank account using plain dicts and functions — practising
encapsulation principles before learning OOP formally.

### Requirements
- `create_account(name, initial_balance)` — returns an account dict
- `deposit(account, amount)` — validate amount > 0
- `withdraw(account, amount)` — enforce sufficient funds
- `transfer(source, target, amount)` — move money between accounts
- `print_statement(account)` — show all transactions with running balance
- Record every transaction: type, amount, timestamp, balance after

### Hints
- Account dict: `{"name": str, "balance": float, "transactions": []}`
- Transaction dict: `{"type": str, "amount": float, "ts": str, "balance_after": float}`
- Raise `InsufficientFundsError(Exception)` for overdrafts
- `datetime.datetime.now().strftime("%Y-%m-%d %H:%M")` for timestamps

### Sample Output
```
=== Account Statement: Alice ===
Date             Type        Amount     Balance
------------------------------------------------
2024-01-01 09:00  OPEN       +500.00    500.00
2024-01-01 10:30  DEPOSIT    +200.00    700.00
2024-01-01 11:00  WITHDRAW   -150.00    550.00
2024-01-01 11:05  TRANSFER   -100.00    450.00
------------------------------------------------
Current Balance: $450.00
Total Deposits : $700.00
Total Withdrawals: $250.00
```

### Starter Code
```python
import datetime

class InsufficientFundsError(Exception):
    pass

def _now():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

def _record(account, tx_type, amount):
    account["transactions"].append({
        "type":         tx_type,
        "amount":       amount,
        "ts":           _now(),
        "balance_after": account["balance"],
    })

def create_account(name, initial_balance=0.0):
    if initial_balance < 0:
        raise ValueError("Initial balance cannot be negative")
    acc = {"name": name, "balance": float(initial_balance), "transactions": []}
    _record(acc, "OPEN", initial_balance)
    return acc

def deposit(account, amount):
    if amount <= 0:
        raise ValueError("Deposit amount must be positive")
    account["balance"] += amount
    _record(account, "DEPOSIT", amount)

def withdraw(account, amount):
    if amount <= 0:
        raise ValueError("Withdrawal amount must be positive")
    if amount > account["balance"]:
        raise InsufficientFundsError(
            f"Cannot withdraw {amount:.2f}; balance is {account['balance']:.2f}"
        )
    account["balance"] -= amount
    _record(account, "WITHDRAW", -amount)

def transfer(source, target, amount):
    withdraw(source, amount)     # raises if insufficient funds
    deposit(target, amount)
    # Optionally add a TRANSFER_OUT / TRANSFER_IN record for clarity

def print_statement(account):
    print(f"\n=== Account Statement: {account['name']} ===")
    header = f"{'Date':<18} {'Type':<12} {'Amount':>10}  {'Balance':>10}"
    print(header)
    print("-" * len(header))
    for tx in account["transactions"]:
        sign = "+" if tx["amount"] >= 0 else ""
        print(
            f"{tx['ts']:<18} {tx['type']:<12} "
            f"{sign}{tx['amount']:>9.2f}  {tx['balance_after']:>10.2f}"
        )
    print("-" * len(header))
    print(f"Current Balance: ${account['balance']:.2f}")
```

---

## Quick-Reference: Concepts Exercised

| Exercise            | Core Concepts Practised                             |
|---------------------|-----------------------------------------------------|
| 1. Calculator       | loops, dicts of functions, exception handling       |
| 2. Contact Book     | dict CRUD, JSON persistence, string search          |
| 3. Word Counter     | file I/O, regex, Counter, formatted output          |
| 4. Grade System     | lists of dicts, functions, sorting, f-string align  |
| 5. Guessing Game    | while loop, random, input validation, state         |
| 6. Caesar Cipher    | string manipulation, ord/chr, modulo arithmetic     |
| 7. CSV Analyser     | csv module, defaultdict, list comprehension         |
| 8. Shopping Cart    | nested dicts, arithmetic, discount/tax logic        |
| 9. Temp Converter   | dict of lambdas, exceptions, input parsing          |
| 10. Bank Account    | dict-based records, custom exceptions, datetime     |

---

*End of PRACTICALS.md — 10 hands-on exercises for Core Python*
