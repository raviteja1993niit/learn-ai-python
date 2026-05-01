# Competitive Programming — Practice Problems
## 15 Classic Problems: Easy → Medium → Hard

---

## EASY PROBLEMS

---

### Problem 1: Two Sum
**Difficulty**: Easy
**Category**: Arrays & Hashing

**Problem Statement:**
Given an array of integers `nums` and an integer `target`, return the indices of the two numbers that add up to `target`. Each input has exactly one solution and you may not use the same element twice.

**Example:**
- Input: `nums = [2, 7, 11, 15]`, `target = 9`
- Output: `[0, 1]` (because `nums[0] + nums[1] = 2 + 7 = 9`)

**Hints:**
1. A brute-force approach uses two nested loops — what's its time complexity?
2. Can you use a hash map to reduce it to O(n)?
3. For each element `x`, check if `target - x` is already in the map.

**Solution Approach:**
Use a dictionary to store `{value: index}` as you iterate. For each number, compute `complement = target - num` and check if it's already in the dict.

```python
def two_sum(nums, target):
    seen = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
```
**Complexity:** Time O(n) | Space O(n)

---

### Problem 2: Valid Parentheses
**Difficulty**: Easy
**Category**: Stack

**Problem Statement:**
Given a string containing only `(`, `)`, `{`, `}`, `[`, `]`, determine if the input string is valid. A string is valid if every opening bracket has a corresponding closing bracket in the correct order.

**Example:**
- Input: `"()[]{}"` → Output: `True`
- Input: `"([)]"` → Output: `False`

**Hints:**
1. What data structure tracks "the most recent unmatched opening bracket"?
2. When you see a closing bracket, what should it match?
3. What does an empty stack mean at the end?

**Solution Approach:**
Use a stack. Push opening brackets. For closing brackets, check if the top of the stack is the matching opener. Return `True` if stack is empty at the end.

```python
def is_valid(s):
    stack = []
    mapping = {')': '(', '}': '{', ']': '['}
    for char in s:
        if char in mapping:
            top = stack.pop() if stack else '#'
            if mapping[char] != top:
                return False
        else:
            stack.append(char)
    return not stack
```
**Complexity:** Time O(n) | Space O(n)

---

### Problem 3: Maximum Subarray (Kadane's Algorithm)
**Difficulty**: Easy
**Category**: Dynamic Programming / Greedy

**Problem Statement:**
Given an integer array `nums`, find the subarray with the largest sum and return its sum.

**Example:**
- Input: `[-2, 1, -3, 4, -1, 2, 1, -5, 4]`
- Output: `6` (subarray `[4, -1, 2, 1]`)

**Hints:**
1. Should you ever start a subarray from a negative cumulative sum?
2. At each position, decide: extend the existing subarray, or start fresh?
3. Keep a running `current_sum` and update `max_sum` at each step.

**Solution Approach:**
Kadane's algorithm: maintain `current_sum`. At each element, take the max of the element alone vs. extending the previous sum.

```python
def max_subarray(nums):
    max_sum = current_sum = nums[0]
    for num in nums[1:]:
        current_sum = max(num, current_sum + num)
        max_sum = max(max_sum, current_sum)
    return max_sum
```
**Complexity:** Time O(n) | Space O(1)

---

### Problem 4: Reverse a Linked List
**Difficulty**: Easy
**Category**: Linked List

**Problem Statement:**
Given the head of a singly linked list, reverse the list and return the new head.

**Example:**
- Input: `1 → 2 → 3 → 4 → 5`
- Output: `5 → 4 → 3 → 2 → 1`

**Hints:**
1. You need to change each node's `next` pointer to point backward.
2. Use three pointers: `prev`, `curr`, `next_node`.
3. Can you also solve this recursively?

**Solution Approach:**
Iterative: Walk the list, reversing `next` pointers one by one.

```python
def reverse_list(head):
    prev = None
    curr = head
    while curr:
        next_node = curr.next   # save next
        curr.next = prev        # reverse pointer
        prev = curr             # advance prev
        curr = next_node        # advance curr
    return prev
```
**Complexity:** Time O(n) | Space O(1)

---

### Problem 5: Best Time to Buy and Sell Stock
**Difficulty**: Easy
**Category**: Greedy / Arrays

**Problem Statement:**
Given an array `prices` where `prices[i]` is the price on day `i`, find the maximum profit from one buy-sell transaction. You must buy before you sell.

**Example:**
- Input: `[7, 1, 5, 3, 6, 4]` → Output: `5` (buy on day 2, sell on day 5)

**Hints:**
1. Track the minimum price seen so far.
2. At each price, calculate profit if you sold today.
3. No need to look back further than the current minimum.

**Solution Approach:**
One pass: track `min_price` and compute `max_profit = max(max_profit, price - min_price)`.

```python
def max_profit(prices):
    min_price = float('inf')
    max_profit = 0
    for price in prices:
        min_price = min(min_price, price)
        max_profit = max(max_profit, price - min_price)
    return max_profit
```
**Complexity:** Time O(n) | Space O(1)

---

## MEDIUM PROBLEMS

---

### Problem 6: Longest Substring Without Repeating Characters
**Difficulty**: Medium
**Category**: Sliding Window

**Problem Statement:**
Given a string `s`, find the length of the longest substring without repeating characters.

**Example:**
- Input: `"abcabcbb"` → Output: `3` (`"abc"`)

**Hints:**
1. Use a sliding window with a set to track characters in the window.
2. When a duplicate is found, shrink the window from the left.
3. Track `max_len` as the window expands.

**Solution Approach:**
Expand `right` pointer. If `s[right]` is in the set, move `left` forward until it's removed.

```python
def length_of_longest_substring(s):
    char_set = set()
    left = max_len = 0
    for right in range(len(s)):
        while s[right] in char_set:
            char_set.remove(s[left])
            left += 1
        char_set.add(s[right])
        max_len = max(max_len, right - left + 1)
    return max_len
```
**Complexity:** Time O(n) | Space O(min(n, alphabet))

---

### Problem 7: Number of Islands
**Difficulty**: Medium
**Category**: Graph / DFS / BFS

**Problem Statement:**
Given a 2D grid of `'1'` (land) and `'0'` (water), count the number of islands. An island is surrounded by water and formed by connecting adjacent lands horizontally/vertically.

**Example:**
```
11110
11010
11000
00000
```
Output: `1`

**Hints:**
1. Treat the grid as a graph — each `'1'` cell is a node.
2. Use DFS/BFS to explore and "sink" each island.
3. Each time you start a DFS on an unvisited land cell, it's a new island.

**Solution Approach:**
DFS: For each `'1'` found, increment count and DFS to mark all connected land as `'0'`.

```python
def num_islands(grid):
    def dfs(r, c):
        if r < 0 or c < 0 or r >= len(grid) or c >= len(grid[0]) or grid[r][c] != '1':
            return
        grid[r][c] = '0'             # mark as visited
        for dr, dc in [(0,1),(0,-1),(1,0),(-1,0)]:
            dfs(r + dr, c + dc)

    count = 0
    for r in range(len(grid)):
        for c in range(len(grid[0])):
            if grid[r][c] == '1':
                count += 1
                dfs(r, c)
    return count
```
**Complexity:** Time O(m×n) | Space O(m×n) call stack

---

### Problem 8: Binary Tree Level Order Traversal
**Difficulty**: Medium
**Category**: Trees / BFS

**Problem Statement:**
Return the level-order traversal of a binary tree's node values as a list of lists (one list per level).

**Example:**
```
    3
   / \
  9  20
    /  \
   15   7
```
Output: `[[3], [9, 20], [15, 7]]`

**Hints:**
1. Use a queue (BFS) to process nodes level by level.
2. At each level, record the queue size before processing — that tells you how many nodes are at the current level.
3. Add children to the queue as you process each node.

**Complexity:** Time O(n) | Space O(n)

---

### Problem 9: Word Search
**Difficulty**: Medium
**Category**: Backtracking

**Problem Statement:**
Given an `m×n` board and a word, return `True` if the word exists in the grid. The word can be constructed from adjacent cells (horizontally/vertically). The same cell may not be used more than once.

**Hints:**
1. Try DFS/backtracking from every cell that matches `word[0]`.
2. Mark cells as visited during exploration; unmark on backtrack.
3. Base case: if you've matched all characters, return `True`.

**Solution Approach:**
```python
def exist(board, word):
    rows, cols = len(board), len(board[0])

    def dfs(r, c, i):
        if i == len(word): return True
        if r < 0 or c < 0 or r >= rows or c >= cols: return False
        if board[r][c] != word[i]: return False
        board[r][c] = '#'            # mark visited
        found = any(dfs(r+dr, c+dc, i+1) for dr, dc in [(0,1),(0,-1),(1,0),(-1,0)])
        board[r][c] = word[i]        # unmark (backtrack)
        return found

    return any(dfs(r, c, 0) for r in range(rows) for c in range(cols))
```
**Complexity:** Time O(m×n×4^L) | Space O(L)

---

### Problem 10: Product of Array Except Self
**Difficulty**: Medium
**Category**: Arrays / Prefix Products

**Problem Statement:**
Given array `nums`, return an array where each element is the product of all other elements. You must not use division, in O(n) time.

**Example:**
- Input: `[1, 2, 3, 4]` → Output: `[24, 12, 8, 6]`

**Hints:**
1. For each index, you need the product of all elements to its left and to its right.
2. Compute a left-products pass, then a right-products pass.
3. Combine them without division.

**Solution Approach:**
```python
def product_except_self(nums):
    n = len(nums)
    result = [1] * n
    # left pass
    for i in range(1, n):
        result[i] = result[i-1] * nums[i-1]
    # right pass
    right = 1
    for i in range(n - 1, -1, -1):
        result[i] *= right
        right *= nums[i]
    return result
```
**Complexity:** Time O(n) | Space O(1) auxiliary

---

### Problem 11: Meeting Rooms II (Minimum Meeting Rooms)
**Difficulty**: Medium
**Category**: Intervals / Heap

**Problem Statement:**
Given an array of meeting time intervals `[start, end]`, find the minimum number of conference rooms required.

**Example:**
- Input: `[[0,30],[5,10],[15,20]]` → Output: `2`

**Hints:**
1. Sort meetings by start time.
2. Use a min-heap to track end times of ongoing meetings.
3. If the earliest-ending meeting finishes before the next one starts, reuse the room.

**Complexity:** Time O(n log n) | Space O(n)

---

## HARD PROBLEMS

---

### Problem 12: Longest Valid Parentheses
**Difficulty**: Hard
**Category**: Stack / Dynamic Programming

**Problem Statement:**
Given a string containing only `(` and `)`, find the length of the longest valid (well-formed) parentheses substring.

**Example:**
- Input: `")()())"` → Output: `4` (the substring `"()()"`)

**Hints:**
1. Stack approach: push index of `(`. When `)` is found, pop or record a gap.
2. Alternative: DP where `dp[i]` = length of longest valid substring ending at `i`.
3. Two-pass approach: count open/close left-to-right then right-to-left.

**Solution Approach (Stack):**
```python
def longest_valid_parentheses(s):
    stack = [-1]        # sentinel base
    max_len = 0
    for i, c in enumerate(s):
        if c == '(':
            stack.append(i)
        else:
            stack.pop()
            if stack:
                max_len = max(max_len, i - stack[-1])
            else:
                stack.append(i)   # new base
    return max_len
```
**Complexity:** Time O(n) | Space O(n)

---

### Problem 13: Trapping Rain Water
**Difficulty**: Hard
**Category**: Two Pointers / Stack

**Problem Statement:**
Given an elevation map represented by `height[]`, compute how much water it can trap after raining.

**Example:**
- Input: `[0,1,0,2,1,0,1,3,2,1,2,1]` → Output: `6`

**Hints:**
1. Water at index `i` = `min(max_left[i], max_right[i]) - height[i]`
2. Precompute `max_left` and `max_right` arrays in O(n).
3. Alternatively, use two pointers to do it in O(1) space.

**Solution Approach (Two Pointers):**
```python
def trap(height):
    left, right = 0, len(height) - 1
    left_max = right_max = water = 0
    while left < right:
        if height[left] < height[right]:
            if height[left] >= left_max:
                left_max = height[left]
            else:
                water += left_max - height[left]
            left += 1
        else:
            if height[right] >= right_max:
                right_max = height[right]
            else:
                water += right_max - height[right]
            right -= 1
    return water
```
**Complexity:** Time O(n) | Space O(1)

---

### Problem 14: Median of Two Sorted Arrays
**Difficulty**: Hard
**Category**: Binary Search

**Problem Statement:**
Given two sorted arrays `nums1` and `nums2`, find the median of the combined sorted array in O(log(m+n)) time.

**Example:**
- Input: `nums1 = [1,3]`, `nums2 = [2]` → Output: `2.0`
- Input: `nums1 = [1,2]`, `nums2 = [3,4]` → Output: `2.5`

**Hints:**
1. Merge and find median is O(m+n). Can you do better?
2. Binary search on the partition of the smaller array.
3. Find a partition such that all elements on the left ≤ all elements on the right.
4. The median is then the average of boundary elements.

**Key Insight:**
For combined size `n`, we need `n//2` elements on each side of the partition.
Binary search on the partition index in the smaller array; derive the other array's partition.

**Complexity:** Time O(log(min(m,n))) | Space O(1)

---

### Problem 15: Word Ladder
**Difficulty**: Hard
**Category**: BFS / Graph

**Problem Statement:**
Given `beginWord`, `endWord`, and a `wordList`, find the length of the shortest transformation sequence from `beginWord` to `endWord`, where each step changes exactly one letter and each intermediate word must be in `wordList`.

**Example:**
- `beginWord = "hit"`, `endWord = "cog"`, `wordList = ["hot","dot","dog","lot","log","cog"]`
- Output: `5` (`"hit" → "hot" → "dot" → "dog" → "cog"`)

**Hints:**
1. This is a shortest path problem — use BFS.
2. From each word, generate all possible one-letter mutations.
3. Check if each mutation is in the word set (O(1) with a set).
4. Use bidirectional BFS for better performance on large inputs.

**Solution Approach:**
```python
from collections import deque

def ladder_length(beginWord, endWord, wordList):
    word_set = set(wordList)
    if endWord not in word_set:
        return 0
    queue = deque([(beginWord, 1)])
    visited = {beginWord}

    while queue:
        word, steps = queue.popleft()
        for i in range(len(word)):
            for c in 'abcdefghijklmnopqrstuvwxyz':
                new_word = word[:i] + c + word[i+1:]
                if new_word == endWord:
                    return steps + 1
                if new_word in word_set and new_word not in visited:
                    visited.add(new_word)
                    queue.append((new_word, steps + 1))
    return 0
```
**Complexity:** Time O(M² × N) where M = word length, N = word list size | Space O(M² × N)

---

## Summary Table

| # | Problem                         | Difficulty | Category           | Key Technique        |
|---|---------------------------------|------------|--------------------|----------------------|
| 1 | Two Sum                         | Easy       | Arrays & Hashing   | Hash Map             |
| 2 | Valid Parentheses               | Easy       | Stack              | Stack                |
| 3 | Maximum Subarray                | Easy       | DP / Greedy        | Kadane's Algorithm   |
| 4 | Reverse Linked List             | Easy       | Linked List        | Three Pointers       |
| 5 | Best Time to Buy/Sell Stock     | Easy       | Greedy             | Min Tracking         |
| 6 | Longest Substring No Repeat     | Medium     | Sliding Window     | Sliding Window       |
| 7 | Number of Islands               | Medium     | Graph / DFS        | DFS / BFS            |
| 8 | Level Order Traversal           | Medium     | Trees / BFS        | BFS with Queue       |
| 9 | Word Search                     | Medium     | Backtracking       | DFS + Backtrack      |
|10 | Product Except Self             | Medium     | Arrays             | Prefix Products      |
|11 | Meeting Rooms II                | Medium     | Intervals / Heap   | Min-Heap             |
|12 | Longest Valid Parentheses       | Hard       | Stack / DP         | Stack                |
|13 | Trapping Rain Water             | Hard       | Two Pointers       | Two Pointers         |
|14 | Median of Two Sorted Arrays     | Hard       | Binary Search      | Binary Search        |
|15 | Word Ladder                     | Hard       | BFS / Graph        | BFS                  |

---

## Study Tips

1. **Understand before memorizing** — trace through examples by hand first.
2. **Pattern recognition** — most problems map to one of ~15 patterns.
3. **Time yourself** — Easy: 15 min, Medium: 30 min, Hard: 45 min.
4. **Write complexity analysis** for every solution.
5. **Revisit wrong answers** — failed problems teach the most.
6. **Build intuition** — practice same-category problems in batches.