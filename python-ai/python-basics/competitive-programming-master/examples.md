# Competitive Programming — Algorithm Examples
## 20+ Implementations with Step-by-Step Explanations

---

## 1. Binary Search
**Complexity**: Time O(log n) | Space O(1)

```python
def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = left + (right - left) // 2   # avoids integer overflow
        if arr[mid] == target:
            return mid                       # found
        elif arr[mid] < target:
            left = mid + 1                  # search right half
        else:
            right = mid - 1                 # search left half
    return -1                               # not found

arr = [1, 3, 5, 7, 9, 11, 15]
print(binary_search(arr, 7))   # Output: 3
print(binary_search(arr, 6))   # Output: -1
```

---

## 2. Merge Sort
**Complexity**: Time O(n log n) | Space O(n)

```python
def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])    # recursively sort left half
    right = merge_sort(arr[mid:])   # recursively sort right half
    return merge(left, right)

def merge(left, right):
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:     # <= ensures stability
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])         # append remaining elements
    result.extend(right[j:])
    return result

print(merge_sort([5, 2, 8, 1, 9, 3]))  # [1, 2, 3, 5, 8, 9]
```

---

## 3. Quick Sort
**Complexity**: Time O(n log n) avg, O(n²) worst | Space O(log n)

```python
def quick_sort(arr, low, high):
    if low < high:
        pi = partition(arr, low, high)  # partition index
        quick_sort(arr, low, pi - 1)    # sort left of pivot
        quick_sort(arr, pi + 1, high)   # sort right of pivot

def partition(arr, low, high):
    pivot = arr[high]               # choose last element as pivot
    i = low - 1                     # index of smaller element
    for j in range(low, high):
        if arr[j] <= pivot:
            i += 1
            arr[i], arr[j] = arr[j], arr[i]
    arr[i + 1], arr[high] = arr[high], arr[i + 1]
    return i + 1

arr = [10, 7, 8, 9, 1, 5]
quick_sort(arr, 0, len(arr) - 1)
print(arr)  # [1, 5, 7, 8, 9, 10]
```

---

## 4. Bubble Sort
**Complexity**: Time O(n²) | Space O(1)

```python
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        swapped = False
        for j in range(0, n - i - 1):   # last i elements are already sorted
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:                  # early exit if already sorted
            break
    return arr

print(bubble_sort([64, 34, 25, 12, 22, 11, 90]))
```

---

## 5. Two Pointers — Two Sum (Sorted Array)
**Complexity**: Time O(n) | Space O(1)

```python
def two_sum_sorted(arr, target):
    # Works only on sorted arrays
    left, right = 0, len(arr) - 1
    while left < right:
        current_sum = arr[left] + arr[right]
        if current_sum == target:
            return [left, right]         # found pair
        elif current_sum < target:
            left += 1                    # need larger sum
        else:
            right -= 1                   # need smaller sum
    return []

print(two_sum_sorted([2, 7, 11, 15], 9))  # [0, 1]
```

---

## 6. Sliding Window — Maximum Sum Subarray of Size K
**Complexity**: Time O(n) | Space O(1)

```python
def max_sum_subarray(arr, k):
    n = len(arr)
    if n < k:
        return -1

    window_sum = sum(arr[:k])       # compute first window
    max_sum = window_sum

    for i in range(k, n):
        window_sum += arr[i]         # add incoming element
        window_sum -= arr[i - k]     # remove outgoing element
        max_sum = max(max_sum, window_sum)

    return max_sum

print(max_sum_subarray([2, 1, 5, 1, 3, 2], 3))  # 9
```

---

## 7. BFS — Level Order Traversal
**Complexity**: Time O(V+E) | Space O(V)

```python
from collections import deque

def bfs(graph, start):
    visited = set([start])
    queue = deque([start])
    order = []

    while queue:
        node = queue.popleft()           # dequeue front
        order.append(node)
        for neighbor in graph[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)   # enqueue unvisited neighbors
    return order

graph = {0: [1, 2], 1: [2, 3], 2: [4], 3: [], 4: []}
print(bfs(graph, 0))  # [0, 1, 2, 3, 4]
```

---

## 8. DFS — Connected Components
**Complexity**: Time O(V+E) | Space O(V)

```python
def dfs(graph, node, visited, component):
    visited.add(node)
    component.append(node)
    for neighbor in graph[node]:
        if neighbor not in visited:
            dfs(graph, neighbor, visited, component)

def count_components(graph):
    visited = set()
    components = []
    for node in graph:
        if node not in visited:
            component = []
            dfs(graph, node, visited, component)
            components.append(component)
    return components

graph = {0: [1], 1: [0], 2: [3], 3: [2], 4: []}
print(count_components(graph))  # [[0, 1], [2, 3], [4]]
```

---

## 9. Dijkstra's Algorithm
**Complexity**: Time O((V+E) log V) | Space O(V)

```python
import heapq

def dijkstra(graph, start):
    # graph[u] = [(weight, v), ...]
    dist = {node: float('inf') for node in graph}
    dist[start] = 0
    heap = [(0, start)]         # (cost, node)

    while heap:
        cost, u = heapq.heappop(heap)
        if cost > dist[u]:       # outdated entry
            continue
        for weight, v in graph[u]:
            new_cost = cost + weight
            if new_cost < dist[v]:
                dist[v] = new_cost
                heapq.heappush(heap, (new_cost, v))
    return dist

graph = {
    'A': [(1, 'B'), (4, 'C')],
    'B': [(2, 'C'), (5, 'D')],
    'C': [(1, 'D')],
    'D': []
}
print(dijkstra(graph, 'A'))  # {'A': 0, 'B': 1, 'C': 3, 'D': 4}
```

---

## 10. Dynamic Programming — Fibonacci with Memoization
**Complexity**: Time O(n) | Space O(n)

```python
from functools import lru_cache

@lru_cache(maxsize=None)            # automatic memoization
def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2) # overlapping subproblems cached

# Tabulation (bottom-up) version — O(n) time, O(1) space
def fib_tab(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b

print(fib(10))      # 55
print(fib_tab(10))  # 55
```

---

## 11. 0/1 Knapsack — Tabulation
**Complexity**: Time O(n × W) | Space O(n × W)

```python
def knapsack(weights, values, W):
    n = len(weights)
    # dp[i][w] = max value with first i items and capacity w
    dp = [[0] * (W + 1) for _ in range(n + 1)]

    for i in range(1, n + 1):
        for w in range(W + 1):
            dp[i][w] = dp[i-1][w]          # exclude item i
            if weights[i-1] <= w:
                dp[i][w] = max(dp[i][w],
                    dp[i-1][w - weights[i-1]] + values[i-1])  # include item i
    return dp[n][W]

weights = [1, 3, 4, 5]
values  = [1, 4, 5, 7]
print(knapsack(weights, values, 7))  # 9
```

---

## 12. Longest Common Subsequence (LCS)
**Complexity**: Time O(m × n) | Space O(m × n)

```python
def lcs(s1, s2):
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if s1[i-1] == s2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1   # characters match
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])  # take best

    return dp[m][n]

print(lcs("ABCBDAB", "BDCAB"))  # 4 (BCAB or BDAB)
```

---

## 13. Coin Change — Minimum Coins
**Complexity**: Time O(amount × n) | Space O(amount)

```python
def coin_change(coins, amount):
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0               # base case: 0 coins for amount 0

    for a in range(1, amount + 1):
        for coin in coins:
            if coin <= a:
                dp[a] = min(dp[a], dp[a - coin] + 1)  # use this coin

    return dp[amount] if dp[amount] != float('inf') else -1

print(coin_change([1, 5, 6, 9], 11))  # 2 (5+6)
```

---

## 14. Backtracking — Generate All Permutations
**Complexity**: Time O(n × n!) | Space O(n)

```python
def permutations(nums):
    result = []

    def backtrack(path, remaining):
        if not remaining:               # base case: no elements left
            result.append(path[:])
            return
        for i, num in enumerate(remaining):
            path.append(num)
            backtrack(path, remaining[:i] + remaining[i+1:])
            path.pop()                  # undo choice (backtrack)

    backtrack([], nums)
    return result

print(permutations([1, 2, 3]))
# [[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]
```

---

## 15. Union-Find (Disjoint Set Union)
**Complexity**: Time O(α(n)) per op ≈ O(1) | Space O(n)

```python
class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))    # each node is its own parent
        self.rank = [0] * n

    def find(self, x):
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])  # path compression
        return self.parent[x]

    def union(self, x, y):
        px, py = self.find(x), self.find(y)
        if px == py:
            return False                # already connected
        if self.rank[px] < self.rank[py]:
            px, py = py, px
        self.parent[py] = px            # union by rank
        if self.rank[px] == self.rank[py]:
            self.rank[px] += 1
        return True

uf = UnionFind(5)
uf.union(0, 1)
uf.union(1, 2)
print(uf.find(0) == uf.find(2))  # True (connected)
print(uf.find(0) == uf.find(3))  # False (not connected)
```

---

## 16. Topological Sort — Kahn's Algorithm (BFS)
**Complexity**: Time O(V+E) | Space O(V)

```python
from collections import deque

def topological_sort(graph, num_nodes):
    in_degree = [0] * num_nodes
    for u in graph:
        for v in graph[u]:
            in_degree[v] += 1           # count incoming edges

    queue = deque([i for i in range(num_nodes) if in_degree[i] == 0])
    order = []

    while queue:
        node = queue.popleft()
        order.append(node)
        for neighbor in graph.get(node, []):
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)

    return order if len(order) == num_nodes else []  # [] means cycle exists

graph = {0: [1, 2], 1: [3], 2: [3], 3: []}
print(topological_sort(graph, 4))  # [0, 1, 2, 3] or [0, 2, 1, 3]
```

---

## 17. Prefix Sum — Range Sum Query
**Complexity**: Build O(n) | Query O(1) | Space O(n)

```python
def build_prefix(arr):
    prefix = [0] * (len(arr) + 1)
    for i, v in enumerate(arr):
        prefix[i + 1] = prefix[i] + v   # prefix[i] = sum of arr[0..i-1]
    return prefix

def range_sum(prefix, l, r):
    return prefix[r + 1] - prefix[l]    # sum of arr[l..r] inclusive

arr = [1, 3, 5, 7, 9]
prefix = build_prefix(arr)
print(range_sum(prefix, 1, 3))  # 15 (3+5+7)
```

---

## 18. KMP String Matching
**Complexity**: Time O(n+m) | Space O(m)

```python
def kmp_search(text, pattern):
    def build_lps(p):                   # longest proper prefix-suffix
        lps = [0] * len(p)
        length = 0
        i = 1
        while i < len(p):
            if p[i] == p[length]:
                length += 1
                lps[i] = length
                i += 1
            elif length:
                length = lps[length - 1]
            else:
                lps[i] = 0
                i += 1
        return lps

    lps = build_lps(pattern)
    matches = []
    i = j = 0                           # text pointer, pattern pointer

    while i < len(text):
        if text[i] == pattern[j]:
            i += 1; j += 1
        if j == len(pattern):
            matches.append(i - j)       # match found at index i-j
            j = lps[j - 1]
        elif i < len(text) and text[i] != pattern[j]:
            j = lps[j - 1] if j else (i := i + 1) or 0
    return matches

print(kmp_search("AABAACAADAABAABA", "AABA"))  # [0, 9, 12]
```

---

## 19. Heap — Top K Frequent Elements
**Complexity**: Time O(n log k) | Space O(n)

```python
import heapq
from collections import Counter

def top_k_frequent(nums, k):
    count = Counter(nums)               # frequency map O(n)
    # min-heap of size k; stores (freq, element)
    heap = []
    for num, freq in count.items():
        heapq.heappush(heap, (freq, num))
        if len(heap) > k:
            heapq.heappop(heap)         # remove least frequent

    return [num for freq, num in heap]

print(top_k_frequent([1,1,1,2,2,3], 2))  # [1, 2]
```

---

## 20. Monotonic Stack — Next Greater Element
**Complexity**: Time O(n) | Space O(n)

```python
def next_greater_element(arr):
    n = len(arr)
    result = [-1] * n               # default: no greater element
    stack = []                      # stores indices

    for i in range(n):
        # pop elements smaller than current — current is their "next greater"
        while stack and arr[stack[-1]] < arr[i]:
            idx = stack.pop()
            result[idx] = arr[i]
        stack.append(i)

    return result

print(next_greater_element([4, 5, 2, 10, 8]))
# [5, 10, 10, -1, -1]
```

---

## 21. Trie — Insert and Search
**Complexity**: Insert/Search O(L) where L = word length | Space O(ALPHABET × N × L)

```python
class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end = True              # mark end of word

    def search(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                return False
            node = node.children[char]
        return node.is_end

    def starts_with(self, prefix):
        node = self.root
        for char in prefix:
            if char not in node.children:
                return False
            node = node.children[char]
        return True

trie = Trie()
trie.insert("apple")
print(trie.search("apple"))    # True
print(trie.starts_with("app")) # True
print(trie.search("app"))      # False
```

---

## 22. Fast & Slow Pointers — Detect Cycle in Linked List
**Complexity**: Time O(n) | Space O(1)

```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def has_cycle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next            # move 1 step
        fast = fast.next.next       # move 2 steps
        if slow == fast:
            return True             # cycle detected
    return False

# Create cycle: 1 -> 2 -> 3 -> 4 -> 2 (cycle back)
n1, n2, n3, n4 = ListNode(1), ListNode(2), ListNode(3), ListNode(4)
n1.next, n2.next, n3.next, n4.next = n2, n3, n4, n2
print(has_cycle(n1))   # True
```

---

## Summary Table

| # | Algorithm              | Time       | Space   | Pattern          |
|---|------------------------|------------|---------|------------------|
| 1 | Binary Search          | O(log n)   | O(1)    | Divide & Conquer |
| 2 | Merge Sort             | O(n log n) | O(n)    | Divide & Conquer |
| 3 | Quick Sort             | O(n log n) | O(log n)| Divide & Conquer |
| 4 | Bubble Sort            | O(n²)      | O(1)    | Comparison       |
| 5 | Two Pointers           | O(n)       | O(1)    | Two Pointers     |
| 6 | Sliding Window         | O(n)       | O(1)    | Sliding Window   |
| 7 | BFS                    | O(V+E)     | O(V)    | Graph            |
| 8 | DFS                    | O(V+E)     | O(V)    | Graph            |
| 9 | Dijkstra               | O((V+E)lgV)| O(V)    | Greedy           |
|10 | Fibonacci DP           | O(n)       | O(1)    | DP               |
|11 | 0/1 Knapsack           | O(nW)      | O(nW)   | DP               |
|12 | LCS                    | O(mn)      | O(mn)   | DP               |
|13 | Coin Change            | O(amount×n)| O(amount)| DP              |
|14 | Permutations           | O(n×n!)    | O(n)    | Backtracking     |
|15 | Union-Find             | O(α(n))    | O(n)    | Union-Find       |
|16 | Topological Sort       | O(V+E)     | O(V)    | Graph            |
|17 | Prefix Sum             | O(1) query | O(n)    | Prefix Sum       |
|18 | KMP                    | O(n+m)     | O(m)    | String           |
|19 | Top K Frequent         | O(n log k) | O(n)    | Heap             |
|20 | Next Greater Element   | O(n)       | O(n)    | Monotonic Stack  |
|21 | Trie                   | O(L)       | O(NL)   | Trie             |
|22 | Cycle Detection        | O(n)       | O(1)    | Fast/Slow Ptr    |