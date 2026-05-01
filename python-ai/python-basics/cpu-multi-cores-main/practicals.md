# Multithreading, Multiprocessing & Async — Practical Exercises

> 10 hands-on exercises. Each includes an objective, requirements, hints, and expected outcome.

---

## Exercise 1 — Thread-Safe Counter

### Objective
Implement a `SafeCounter` class that can be incremented concurrently from multiple threads
without losing any increments.

### Requirements
- Create a class `SafeCounter` with methods `increment()` and `value`.
- Spawn 10 threads, each calling `increment()` 10,000 times.
- The final counter value must equal 100,000.

### Hints
- Use `threading.Lock` inside the class.
- Use `with self._lock:` as a context manager for clean acquisition and release.
- Compare the result with a version that has no lock to see the race condition.

### Expected Outcome
```
Safe counter result: 100000
Unsafe counter result: <some number < 100000>
```

---

## Exercise 2 — Bounded Producer-Consumer Pipeline

### Objective
Build a producer-consumer system where the producer cannot get more than 5 items ahead
of the consumer (backpressure).

### Requirements
- Use `queue.Queue(maxsize=5)` to enforce backpressure.
- Producer generates 20 items with a 0.05s delay each.
- Consumer processes each item with a 0.1s delay.
- Use a sentinel value (`None`) to signal the consumer to stop.
- Print timestamps for each produced and consumed item.

### Hints
- `queue.Queue.put()` blocks when the queue is full.
- Use `time.time()` for timestamps.
- A single consumer thread is fine here.

### Expected Outcome
```
[0.00] Produced item-0
[0.05] Produced item-1
[0.10] Consumed item-0
[0.10] Produced item-2
...
Total time: ~2.0s (not 20*0.1 = 2s sequential, but pipelined)
```

---

## Exercise 3 — Parallel File Word Count

### Objective
Count the total number of words across 50 text files using a `ProcessPoolExecutor`.

### Requirements
- Generate 50 small text files (use `lorem-ipsum` or just repeat a string).
- Write a `count_words(filepath)` function.
- Use `ProcessPoolExecutor.map()` to count all files in parallel.
- Measure and print wall-clock time vs sequential execution.

### Hints
- Use `len(text.split())` for a simple word count.
- Wrap the executor in an `if __name__ == "__main__":` guard.
- Use `time.perf_counter()` for timing.

### Expected Outcome
```
Sequential: 1.23s — Total words: 42000
Parallel  : 0.34s — Total words: 42000
Speedup   : 3.6x
```

---

## Exercise 4 — Async Web Scraper with Rate Limiting

### Objective
Scrape the titles from 20 Wikipedia pages using `aiohttp`, limiting to at most
5 concurrent requests at any time.

### Requirements
- Use `asyncio.Semaphore(5)` to enforce the concurrency limit.
- Use `aiohttp.ClientSession` (one session for all requests).
- Parse the `<title>` tag from each HTML page.
- Print each title as it is fetched (not in order).
- Handle HTTP errors gracefully (log and skip).

### Hints
- Create a list of Wikipedia article URLs (e.g., /wiki/Python, /wiki/Java, etc.)
- `async with sem:` inside the fetch coroutine.
- `await resp.text()` then parse with `re` or `BeautifulSoup`.
- Use `asyncio.gather(*tasks)`.

### Expected Outcome
```
Fetched: Python (programming language) [200]
Fetched: Java (programming language)   [200]
...
20/20 pages scraped in 3.2s
```

---

## Exercise 5 — Parallel ML Model Selection

### Objective
Train 6 different sklearn classifiers in parallel using `ProcessPoolExecutor` and
select the best model by cross-validation accuracy.

### Requirements
- Use `sklearn.datasets.make_classification(n_samples=20_000, n_features=20)`.
- Models: `RandomForest`, `GradientBoosting`, `SVC`, `KNeighbors`, `LogisticRegression`, `DecisionTree`.
- Evaluate each with 5-fold CV in a separate process.
- Print a sorted leaderboard of models by mean accuracy.

### Hints
- Each worker function receives `(model_name, model_instance, X, y)`.
- Use `cross_val_score(model, X, y, cv=5, scoring="accuracy")`.
- Use `ProcessPoolExecutor(max_workers=6)` for maximum parallelism.
- Guard with `if __name__ == "__main__":`.

### Expected Outcome
```
Model Leaderboard:
1. GradientBoosting: 0.9212 ± 0.0031
2. RandomForest    : 0.9187 ± 0.0042
3. SVC             : 0.9101 ± 0.0028
...
Total time: ~15s parallel vs ~45s sequential
```

---

## Exercise 6 — Async Task Queue with Worker Pool

### Objective
Implement an async worker pool that processes tasks from a shared queue using
a configurable number of async workers.

### Requirements
- Create an `asyncio.Queue` loaded with 30 "tasks" (integers 1–30).
- Spawn 5 async worker coroutines that pull tasks and simulate processing
  (`await asyncio.sleep(random.uniform(0.1, 0.5))`).
- Each worker prints which task it processed and how long it took.
- Main coroutine waits until all tasks are done using `queue.join()`.

### Hints
- Workers loop with `while True: task = await queue.get()` then call `queue.task_done()`.
- Use `asyncio.create_task()` for each worker.
- Cancel worker tasks after `await queue.join()`.

### Expected Outcome
```
Worker-1 processing task 3 (0.23s)
Worker-3 processing task 7 (0.41s)
...
All 30 tasks completed in 2.8s
```

---

## Exercise 7 — Multiprocessing Shared Array for Parallel Computation

### Objective
Fill a large array with computed values (e.g., `sqrt(i)`) using multiple processes
writing to a shared memory array, then verify the result.

### Requirements
- Create a `multiprocessing.Array('d', N)` of size N=1,000,000.
- Split the index range into 4 equal chunks.
- Each process fills its chunk: `arr[i] = math.sqrt(i)`.
- After all processes finish, verify spot-check values match `math.sqrt(i)`.

### Hints
- Pass the shared array directly to child processes (it is picklable).
- Use `Process(target=fill_chunk, args=(arr, start, end))`.
- No lock needed since each process writes to a distinct slice.

### Expected Outcome
```
Spot check arr[999999] = 999.9995 ✓
Spot check arr[500000] = 707.1068 ✓
All checks passed.
```

---

## Exercise 8 — Deadlock Detection & Prevention

### Objective
Reproduce a classic deadlock with two locks, then fix it using consistent lock ordering.

### Requirements
**Part A — Create the deadlock**:
- Thread A acquires `lock1` then tries to acquire `lock2`.
- Thread B acquires `lock2` then tries to acquire `lock1`.
- Observe the program hanging.
- Interrupt it manually (Ctrl+C) after confirming the hang.

**Part B — Fix it**:
- Change both threads to always acquire `lock1` before `lock2`.
- Verify the program completes correctly.

### Hints
- Use `time.sleep(0.1)` between the two acquisitions to make the race reliable.
- For Part A, set a 3-second timeout: `lock.acquire(timeout=3)`.
- Print lock acquisition messages to trace execution.

### Expected Outcome
```
Part A: Thread A and Thread B deadlocked (timeout after 3s)
Part B: Both threads completed successfully
```

---

## Exercise 9 — Async Data Pipeline (Fetch → Transform → Save)

### Objective
Build a three-stage async pipeline:
1. **Fetch**: retrieve JSON records from a public API concurrently.
2. **Transform**: process each record asynchronously (compute derived fields).
3. **Save**: write results to a JSON lines file asynchronously.

### Requirements
- Use `https://jsonplaceholder.typicode.com/todos/{id}` (IDs 1–50).
- Stage 1: fetch all 50 records using `aiohttp` with max 10 concurrent requests.
- Stage 2: add a `"priority"` field: `"high"` if `completed=False`, else `"done"`.
- Stage 3: use `aiofiles` to write each transformed record as a JSON line.
- Measure total pipeline time.

### Hints
- Use two `asyncio.Queue` objects: one between fetch→transform, one between transform→save.
- Run all three stages concurrently with `asyncio.gather()`.
- Install: `pip install aiohttp aiofiles`.

### Expected Outcome
```
Fetched 50 records in 1.2s
Transformed 50 records
Saved 50 records to output.jsonl
Total pipeline time: 1.5s
```

---

## Exercise 10 — Parallel Hyperparameter Grid Search

### Objective
Implement a custom parallel grid search for a RandomForest using `ProcessPoolExecutor`,
then compare results with `sklearn.model_selection.GridSearchCV`.

### Requirements
- Dataset: `sklearn.datasets.load_breast_cancer()`.
- Parameter grid: `n_estimators=[50, 100, 200]`, `max_depth=[3, 5, None]`.
- Custom search: evaluate all 9 combinations in parallel (one process each).
- Use 3-fold CV for each combination.
- Compare your best params and score with `GridSearchCV(n_jobs=-1)`.

### Hints
- Create a `param_grid` as a list of dicts using `itertools.product`.
- Worker function: `def evaluate(params, X, y)` → returns `(params, mean_score)`.
- Sort results by score descending to find the best.
- `GridSearchCV` is for verification — your custom result should match.

### Expected Outcome
```
Custom Grid Search (parallel):
  Best params : {'n_estimators': 200, 'max_depth': None}
  Best CV score: 0.9736
  Time: 18.4s

GridSearchCV (n_jobs=-1):
  Best params : {'max_depth': None, 'n_estimators': 200}
  Best CV score: 0.9736
  Time: 6.2s   ← sklearn's joblib is more optimized

Results match ✓
```

---

## Tips for All Exercises

1. **Always guard multiprocessing code** with `if __name__ == "__main__":` on Windows.
2. **Profile before parallelising** — use `cProfile` to confirm the bottleneck.
3. **Match the tool to the workload**: threads for I/O, processes for CPU, asyncio for high-concurrency I/O.
4. **Measure speedup**: `sequential_time / parallel_time` — expect sub-linear gains due to overhead.
5. **Test correctness first on small data**, then scale up.
6. **Handle exceptions in futures**: always call `future.result()` inside a try/except.
7. **Tune worker count**: more workers ≠ always faster; find the sweet spot for your machine.