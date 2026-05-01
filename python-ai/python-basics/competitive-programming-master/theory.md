# Competitive Programming Theory
## Algorithms, Data Structures & Problem Solving

---

## 1. Complexity Analysis

### Time Complexity — Big O Notation

Big O notation describes the **upper bound** of an algorithm's running time as input size grows.

| Notation     | Name         | Example                         |
|-------------|--------------|----------------------------------|
| O(1)        | Constant     | Array access, hash lookup        |
| O(log n)    | Logarithmic  | Binary search, balanced BST ops  |
| O(n)        | Linear       | Linear search, single loop       |
| O(n log n)  | Linearithmic | Merge sort, heap sort            |
| O(n²)       | Quadratic    | Bubble sort, nested loops        |
| O(2ⁿ)       | Exponential  | Subset enumeration, naive DP     |
| O(n!)       | Factorial    | Permutation generation           |

**Growth rate (slowest → fastest):**
O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!)

**Rules:**
- Drop constants: O(3n) → O(n)
- Drop lower-order terms: O(n² + n) → O(n²)
- Nested loops multiply: O(n) × O(n) = O(n²)
- Sequential steps add: O(n) + O(n) = O(n)

**Amortized Analysis:**
Some operations are occasionally expensive but cheap on average.
Example: Python list `.append()` is O(1) amortized (occasional resize is O(n)).

---

### Space Complexity

Space complexity measures memory usage relative to input size.

- **O(1) space**: In-place algorithms (bubble sort, two-pointer)
- **O(n) space**: Storing n elements (hash table, recursion call stack of depth n)
- **O(n²) space**: 2D DP tables, adjacency matrix for dense graphs
- **O(log n) space**: Recursive binary search call stack

**Auxiliary space** vs **Total space**:
- Auxiliary = extra space not counting the input itself
- Merge sort has O(n) auxiliary space despite being O(n log n) time

---

## 2. Data Structures

### Array
- **Access**: O(1) | **Search**: O(n) | **Insert/Delete**: O(n)
- Contiguous memory, cache-friendly
- Python: `list` (dynamic array), supports slicing

### Linked List
- **Access**: O(n) | **Insert/Delete at head**: O(1)
- Singly linked: each node has `val` and `next`
- Doubly linked: also has `prev`
- No random access; good for frequent insertions

### Stack (LIFO)
- **Push/Pop/Peek**: O(1)
- Use for: function call stack, undo operations, balanced parentheses, DFS
- Python: `list` with `.append()` and `.pop()`

### Queue (FIFO)
- **Enqueue/Dequeue**: O(1) with deque
- Use for: BFS, task scheduling, sliding window
- Python: `collections.deque` (doubly-ended queue)

### Deque (Double-Ended Queue)
- **Push/Pop from both ends**: O(1)
- Python: `collections.deque`
- Use for: sliding window maximum, palindrome check

### Heap (Priority Queue)
- **Insert**: O(log n) | **Extract min/max**: O(log n) | **Peek**: O(1)
- Min-heap: root is smallest element
- Max-heap: root is largest element
- Python: `heapq` module (min-heap by default; negate values for max-heap)

### Hash Table
- **Search/Insert/Delete**: O(1) average, O(n) worst case
- Python: `dict`, `set`
- Key insight: collisions degrade performance

### Tree
- **Binary Tree**: each node has at most 2 children
- **BST**: left < node < right; Search/Insert/Delete O(log n) average
- **Balanced BST** (AVL, Red-Black): O(log n) guaranteed
- **Heap**: complete binary tree with heap property

### Graph
- **Directed vs Undirected**
- **Weighted vs Unweighted**
- Representations:
  - Adjacency List: O(V+E) space — good for sparse graphs
  - Adjacency Matrix: O(V²) space — good for dense graphs
- Key metrics: vertices (V), edges (E)

### Trie (Prefix Tree)
- Each node represents a character
- **Insert/Search**: O(L) where L = length of word
- Use for: autocomplete, prefix search, spell checking
- Space: O(ALPHABET_SIZE × N × L)

---

## 3. Sorting Algorithms

| Algorithm      | Best       | Average    | Worst      | Space  | Stable |
|---------------|------------|------------|------------|--------|--------|
| Bubble Sort   | O(n)       | O(n²)      | O(n²)      | O(1)   | Yes    |
| Selection Sort| O(n²)      | O(n²)      | O(n²)      | O(1)   | No     |
| Insertion Sort| O(n)       | O(n²)      | O(n²)      | O(1)   | Yes    |
| Merge Sort    | O(n log n) | O(n log n) | O(n log n) | O(n)   | Yes    |
| Quick Sort    | O(n log n) | O(n log n) | O(n²)      | O(log n)| No    |
| Heap Sort     | O(n log n) | O(n log n) | O(n log n) | O(1)   | No     |
| Tim Sort      | O(n)       | O(n log n) | O(n log n) | O(n)   | Yes    |

**Bubble Sort**: Repeatedly swap adjacent elements if out of order.
**Selection Sort**: Find minimum, place at front, repeat.
**Insertion Sort**: Insert each element into its sorted position. Best for nearly sorted data.
**Merge Sort**: Divide and conquer — split, sort halves, merge. Stable, guaranteed O(n log n).
**Quick Sort**: Pivot-based partitioning. Fast in practice but O(n²) worst case.
**Heap Sort**: Build heap, repeatedly extract max.

---

## 4. Searching Algorithms

### Linear Search
- O(n) time | Works on unsorted data
- Check each element one by one

### Binary Search
- O(log n) time | Requires **sorted** array
- Halve the search space each step
- Variants: lower bound, upper bound, search in rotated array

### Two Pointers
- O(n) time | Usually O(1) space
- Two indices moving toward each other or in same direction
- Use for: pair sum, removing duplicates, container with most water

### Sliding Window
- O(n) time | Fixed or variable window
- Use for: max subarray sum of size k, longest substring without repeat

---

## 5. Recursion & Dynamic Programming

### Recursion
- Base case + recursive case
- Each call adds a frame to the call stack
- Time: depends on number of calls × work per call
- Space: O(depth) for call stack

### Memoization (Top-Down DP)
- Cache results of recursive calls
- Python: `@functools.lru_cache` or manual dict
- Avoids recomputing overlapping subproblems

### Tabulation (Bottom-Up DP)
- Fill a table iteratively from base cases
- Often more space-efficient than memoization
- No recursion overhead

### DP Patterns
- **0/1 Knapsack**: include or exclude each item
- **Unbounded Knapsack**: items can be reused
- **Longest Common Subsequence (LCS)**
- **Longest Increasing Subsequence (LIS)**
- **Coin Change**
- **Edit Distance**
- **Matrix Chain Multiplication**

---

## 6. Graph Algorithms

### BFS (Breadth-First Search)
- Time: O(V+E) | Space: O(V)
- Uses a queue; explores level by level
- Use for: shortest path in unweighted graph, level-order traversal

### DFS (Depth-First Search)
- Time: O(V+E) | Space: O(V)
- Uses stack (explicit or call stack)
- Use for: connected components, cycle detection, topological sort

### Dijkstra's Algorithm
- Time: O((V+E) log V) with min-heap
- Shortest path from source to all vertices (non-negative weights)
- Greedy: always expand the cheapest unvisited vertex

### Topological Sort
- Time: O(V+E) | Only for DAGs
- Kahn's algorithm (BFS-based) or DFS-based
- Use for: task scheduling, build systems, course prerequisites

### Union-Find (Disjoint Set Union)
- Near O(1) per operation with path compression + union by rank
- Use for: detecting cycles, Kruskal's MST

---

## 7. String Algorithms

### KMP (Knuth-Morris-Pratt)
- Pattern matching in O(n+m) time
- Uses failure function (partial match table)
- Avoids redundant comparisons

### Z-Algorithm
- O(n+m) pattern matching
- Z-array: Z[i] = length of longest substring starting from i that matches a prefix

### Anagram Check
- Sort both strings: O(n log n)
- Character frequency count: O(n) using `Counter`

### Other String Techniques
- Rolling hash (Rabin-Karp): O(n) average pattern matching
- Trie for prefix queries
- Palindrome: expand from center, Manacher's algorithm

---

## 8. Greedy Algorithms

Greedy makes the locally optimal choice at each step.

**When greedy works**: Problem has greedy choice property + optimal substructure.

**Classic greedy problems**:
- Activity selection / interval scheduling
- Huffman encoding
- Fractional knapsack
- Minimum spanning tree (Prim's, Kruskal's)
- Jump Game

---

## 9. Backtracking

Explore all possibilities by building solution incrementally; abandon ("backtrack") invalid paths.

**Template**:
```
def backtrack(state):
    if is_solution(state):
        record(state); return
    for choice in get_choices(state):
        make_choice(choice)
        backtrack(state)
        undo_choice(choice)
```

**Classic problems**: N-Queens, Sudoku, permutations, combinations, word search.

---

## 10. Python-Specific Tools

### collections module
- `Counter(iterable)` — frequency map, O(n) build
- `defaultdict(type)` — dict with default factory (e.g., `defaultdict(list)`)
- `deque` — O(1) append/pop from both ends
- `OrderedDict` — maintains insertion order

### heapq module
- `heapq.heappush(heap, item)` — O(log n)
- `heapq.heappop(heap)` — O(log n)
- `heapq.heapify(list)` — O(n)
- `heapq.nlargest(k, iterable)` / `nsmallest`
- **Max-heap trick**: push `-value`

### bisect module
- `bisect.bisect_left(a, x)` — leftmost position to insert x (lower bound)
- `bisect.bisect_right(a, x)` — rightmost position to insert x (upper bound)
- `bisect.insort(a, x)` — insert x keeping sorted order

---

## 11. Problem-Solving Patterns

### Two Pointers
Use when array is sorted or you need to find pairs.
Pattern: `left=0, right=len-1`, move based on condition.

### Sliding Window
Use for contiguous subarray/substring problems.
Pattern: expand right, shrink left when invalid.

### Fast/Slow Pointers (Floyd's Cycle)
Use for linked list cycle detection, finding middle.
Pattern: fast moves 2x, slow moves 1x.

### Prefix Sum
Pre-compute cumulative sums for O(1) range sum queries.
`prefix[i] = prefix[i-1] + arr[i]`

### Monotonic Stack
Maintain a stack in increasing/decreasing order.
Use for: next greater element, largest rectangle in histogram.

### Binary Search on Answer
When answer lies in a range and you can validate in O(n).
Pattern: binary search on the answer space, check feasibility.

---

## 12. LeetCode Pattern Categories

1. **Arrays & Hashing** — frequency maps, two sum
2. **Two Pointers** — sorted arrays, palindrome
3. **Sliding Window** — substrings, subarrays
4. **Stack** — parentheses, monotonic stack
5. **Binary Search** — sorted arrays, search space
6. **Linked List** — fast/slow, reversal
7. **Trees** — DFS/BFS, LCA, diameter
8. **Tries** — prefix matching, autocomplete
9. **Heap / Priority Queue** — top-k, merge k lists
10. **Intervals** — merge, insert, meeting rooms
11. **Greedy** — scheduling, minimum cost
12. **Advanced Graphs** — Dijkstra, topological sort, Union-Find
13. **1D Dynamic Programming** — Fibonacci variants, knapsack
14. **2D Dynamic Programming** — grid paths, LCS, edit distance
15. **Backtracking** — permutations, combinations, N-queens
16. **Bit Manipulation** — XOR tricks, counting bits

---

## 13. Complexity Cheat Sheet for Interviews

- Target < 10⁸ operations per second (rough estimate)
- n ≤ 20 → O(2ⁿ) or O(n!) OK
- n ≤ 500 → O(n³) OK
- n ≤ 5000 → O(n²) OK
- n ≤ 10⁶ → O(n log n) or O(n) required
- n ≤ 10⁸ → O(n) or O(log n) required