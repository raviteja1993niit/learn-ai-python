# Multithreading, Multiprocessing & Async in Python

## Table of Contents
1. [The GIL – Global Interpreter Lock](#gil)
2. [Threading vs Multiprocessing vs Asyncio](#comparison)
3. [threading Module](#threading)
4. [Thread-Safety, Race Conditions & Deadlocks](#safety)
5. [multiprocessing Module](#multiprocessing)
6. [concurrent.futures](#futures)
7. [asyncio](#asyncio)
8. [aiohttp – Async HTTP](#aiohttp)
9. [ML Use Cases](#ml)
10. [sklearn n_jobs=-1](#sklearn)
11. [Dask and Ray (intro)](#dask-ray)

---

## 1. The GIL – Global Interpreter Lock <a name="gil"></a>

### What Is the GIL?
The **Global Interpreter Lock (GIL)** is a mutex (mutual exclusion lock) built into CPython
(the reference Python interpreter). It allows only **one thread to execute Python bytecode
at a time**, even on a multi-core machine.

### Why Does It Exist?
CPython manages memory with reference counting. Without the GIL, two threads could
simultaneously modify an object's reference count, causing memory corruption. The GIL is the
simplest way to protect CPython's memory management without fine-grained locking everywhere.

### What Does the GIL Block?
- True parallel execution of Python bytecode across CPU cores.
- CPU-bound threads cannot run simultaneously → no speedup from adding threads for pure Python
  computation.

### What the GIL Does NOT Block
- I/O-bound threads: the GIL is **released** when a thread performs I/O (file read, network
  call, sleep). Other threads can run during that time.
- C extensions that explicitly release the GIL (e.g., NumPy, OpenCV, most DB drivers).

### GIL in Other Implementations
- **PyPy**: has a GIL but is faster overall.
- **Jython / IronPython**: no GIL → true thread parallelism.
- **Python 3.13+**: per-interpreter GIL (experimental, work in progress to remove it).

---

## 2. Threading vs Multiprocessing vs Asyncio <a name="comparison"></a>

| Feature               | threading            | multiprocessing       | asyncio                  |
|-----------------------|----------------------|-----------------------|--------------------------|
| Parallelism model     | OS threads           | OS processes          | Cooperative coroutines   |
| True CPU parallelism? | No (GIL)             | Yes                   | No (single thread)       |
| Best for              | I/O-bound work       | CPU-bound work        | Many concurrent I/O ops  |
| Memory model          | Shared memory        | Separate memory space | Shared (single process)  |
| Overhead              | Low                  | High (process spawn)  | Very low                 |
| Communication         | Shared objects/Queue | Queue/Pipe/shm        | Coroutine cooperation    |
| Complexity            | Medium               | Medium-High           | Medium (async/await)     |

### When to Use Threading
- Network requests (HTTP, DB queries) where threads spend most time waiting.
- File I/O that blocks but does not need CPU processing.
- GUI applications – keep UI responsive while doing background work.

### When to Use Multiprocessing
- CPU-intensive work: image processing, ML training, numerical computation.
- Bypassing the GIL for pure-Python heavy computation.
- Isolating crashes – a failing process does not kill the main program.

### When to Use Asyncio
- Thousands of concurrent I/O operations (web scraping, REST API calls, chat servers).
- When you want maximum concurrency with minimal memory overhead.
- When you control the full stack (async libraries exist for everything needed).

---

## 3. threading Module <a name="threading"></a>

### Thread
The basic unit of concurrency in the threading module.

```python
import threading

def worker(name):
    print(f"Thread {name} running")

t = threading.Thread(target=worker, args=("A",), daemon=True)
t.start()
t.join()  # Wait for thread to finish
```

**Daemon threads**: automatically killed when the main program exits.

### Lock
Prevents multiple threads from accessing a shared resource simultaneously.

```python
lock = threading.Lock()

with lock:          # acquire on enter, release on exit
    shared_counter += 1
```

### RLock (Reentrant Lock)
A thread that already holds the lock can acquire it again without deadlocking. Useful for
recursive functions or methods that call other locked methods.

```python
rlock = threading.RLock()
with rlock:
    with rlock:     # same thread – safe
        ...
```

### Semaphore
Limits the number of threads that can access a resource concurrently.

```python
sem = threading.Semaphore(3)   # at most 3 threads at a time

with sem:
    do_limited_resource_work()
```

### Event
Allows one thread to signal another.

```python
event = threading.Event()

def waiter():
    event.wait()     # blocks until set()
    print("Event fired!")

threading.Thread(target=waiter).start()
event.set()          # unblocks waiter
```

### Queue (thread-safe)
`queue.Queue` is the preferred way to communicate between threads safely.

```python
import queue

q = queue.Queue()

def producer():
    q.put("item")

def consumer():
    item = q.get()
    q.task_done()
```

---

## 4. Thread-Safety, Race Conditions & Deadlocks <a name="safety"></a>

### Race Condition
Occurs when two threads read-modify-write a shared variable without synchronization.

```
Thread A reads counter = 0
Thread B reads counter = 0
Thread A writes counter = 1
Thread B writes counter = 1   ← lost increment!
```

**Fix**: use `threading.Lock` around every read-modify-write.

### Deadlock
Two threads each hold a lock the other needs → both wait forever.

```
Thread A holds Lock1, waits for Lock2
Thread B holds Lock2, waits for Lock1   ← deadlock
```

**Prevention strategies**:
- Always acquire locks in the same order.
- Use `threading.RLock` for recursive scenarios.
- Prefer higher-level constructs (Queue, concurrent.futures).
- Use `lock.acquire(timeout=N)` and handle failure.

### Thread-Safe Data Structures
- `queue.Queue` — fully thread-safe FIFO queue.
- `collections.deque` with `appendleft`/`pop` — thread-safe for those ops.
- Python's GIL makes simple reads/writes to built-in types atomic in CPython,
  but this is an implementation detail; use locks for correctness guarantees.

---

## 5. multiprocessing Module <a name="multiprocessing"></a>

### Process
Spawns a separate OS process with its own Python interpreter and memory space.

```python
from multiprocessing import Process

def heavy(n):
    return sum(range(n))

p = Process(target=heavy, args=(10**7,))
p.start()
p.join()
```

### Pool
Manages a pool of worker processes. Ideal for parallel map-style workloads.

```python
from multiprocessing import Pool

with Pool(processes=4) as pool:
    results = pool.map(heavy, [10**6, 10**7, 10**8])
```

- `pool.map(fn, iterable)` — blocks until all done.
- `pool.imap(fn, iterable)` — lazy iterator, lower memory.
- `pool.apply_async(fn, args)` — non-blocking single call.
- `pool.starmap(fn, list_of_tuples)` — like map but unpacks args.

### Queue (multiprocessing)
Process-safe queue using OS pipes under the hood.

```python
from multiprocessing import Queue

q = Queue()
q.put({"data": [1,2,3]})
item = q.get()
```

### Pipe
Bidirectional (or unidirectional) communication channel between two processes.

```python
from multiprocessing import Pipe

parent_conn, child_conn = Pipe()
# child process sends, parent receives
child_conn.send("hello")
msg = parent_conn.recv()
```

### Shared Memory
`multiprocessing.Value` and `multiprocessing.Array` allow sharing primitive data without
serialization overhead.

```python
from multiprocessing import Value, Array

counter = Value('i', 0)      # shared integer
arr = Array('d', [1.0, 2.0]) # shared double array

with counter.get_lock():
    counter.value += 1
```

`multiprocessing.shared_memory` (Python 3.8+) supports arbitrary shared memory blocks,
accessible as NumPy arrays across processes.

---

## 6. concurrent.futures <a name="futures"></a>

High-level API that unifies thread-pool and process-pool execution.

### ThreadPoolExecutor
```python
from concurrent.futures import ThreadPoolExecutor

with ThreadPoolExecutor(max_workers=8) as executor:
    futures = [executor.submit(fetch_url, url) for url in urls]
```

### ProcessPoolExecutor
```python
from concurrent.futures import ProcessPoolExecutor

with ProcessPoolExecutor(max_workers=4) as executor:
    results = list(executor.map(cpu_task, data_chunks))
```

### as_completed
Yields futures as they finish (not necessarily in order).

```python
from concurrent.futures import as_completed

for future in as_completed(futures):
    result = future.result()
    print(result)
```

### map
Like built-in map but parallel, results come back in submission order.

```python
results = list(executor.map(process, items, timeout=30))
```

### Future API
- `future.result(timeout=N)` — block until result.
- `future.done()` — non-blocking status check.
- `future.cancel()` — cancel if not started.
- `future.exception()` — retrieve exception if task failed.

---

## 7. asyncio <a name="asyncio"></a>

### Event Loop
The core scheduler that runs coroutines. One event loop per thread (usually per process).

```python
import asyncio

asyncio.run(main())   # Python 3.7+ preferred entry point
```

### Coroutines (async def / await)
```python
async def fetch(url):
    await asyncio.sleep(1)   # non-blocking wait
    return f"result from {url}"
```
- `async def` defines a coroutine function.
- `await` suspends the coroutine until the awaitable completes.
- Coroutines do not run until awaited or scheduled.

### gather
Run multiple coroutines concurrently, wait for all.

```python
results = await asyncio.gather(
    fetch("https://api.example.com/a"),
    fetch("https://api.example.com/b"),
)
```

### create_task
Schedule a coroutine to run concurrently without awaiting immediately.

```python
task = asyncio.create_task(fetch(url))
# do other work …
result = await task
```

### asyncio.Queue
Thread-safe queue for async producers/consumers.

```python
queue = asyncio.Queue()
await queue.put(item)
item = await queue.get()
queue.task_done()
```

### Timeouts and Cancellation
```python
try:
    result = await asyncio.wait_for(fetch(url), timeout=5.0)
except asyncio.TimeoutError:
    print("Request timed out")
```

---

## 8. aiohttp – Async HTTP <a name="aiohttp"></a>

`aiohttp` is the most popular library for async HTTP requests and servers in Python.

```python
import aiohttp
import asyncio

async def fetch(session, url):
    async with session.get(url) as response:
        return await response.json()

async def main(urls):
    async with aiohttp.ClientSession() as session:
        tasks = [fetch(session, url) for url in urls]
        return await asyncio.gather(*tasks)
```

**Key features**:
- Connection pooling via `ClientSession` (reuse connections).
- `TCPConnector(limit=100)` to throttle concurrency.
- Built-in support for timeouts, retries (via `aiohttp-retry`).
- Can serve as a web server (`aiohttp.web`) for async APIs.

---

## 9. ML Use Cases <a name="ml"></a>

### Parallel Data Loading
Large datasets can be loaded in parallel using `ThreadPoolExecutor` (I/O-bound) or
`ProcessPoolExecutor` (CPU-bound preprocessing).

```python
from concurrent.futures import ThreadPoolExecutor
import pandas as pd

def load_file(path):
    return pd.read_parquet(path)

with ThreadPoolExecutor(max_workers=8) as ex:
    dfs = list(ex.map(load_file, file_paths))

df = pd.concat(dfs)
```

### Parallel Feature Engineering
Apply expensive feature transformations across chunks of a DataFrame.

```python
from multiprocessing import Pool
import numpy as np

def engineer_chunk(chunk):
    chunk["feature"] = np.log1p(chunk["value"])
    return chunk

chunks = np.array_split(df, 8)
with Pool(8) as pool:
    result = pd.concat(pool.map(engineer_chunk, chunks))
```

### Parallel Model Training (Cross-Validation)
Run k-fold CV folds in parallel with `ProcessPoolExecutor`.

```python
from concurrent.futures import ProcessPoolExecutor
from sklearn.model_selection import KFold

def train_fold(args):
    X, y, train_idx, val_idx = args
    model = build_model()
    model.fit(X[train_idx], y[train_idx])
    return model.score(X[val_idx], y[val_idx])

kf = KFold(n_splits=5)
fold_args = [(X, y, tr, va) for tr, va in kf.split(X)]

with ProcessPoolExecutor(max_workers=5) as ex:
    scores = list(ex.map(train_fold, fold_args))
```

---

## 10. sklearn n_jobs=-1 <a name="sklearn"></a>

Many scikit-learn estimators accept an `n_jobs` parameter that controls parallelism
via **joblib** (which uses multiprocessing or threading internally).

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score

# Use all available CPU cores
model = RandomForestClassifier(n_jobs=-1, n_estimators=200)
scores = cross_val_score(model, X, y, cv=5, n_jobs=-1)
```

| n_jobs value | Meaning                          |
|-------------|----------------------------------|
| 1 (default) | Single process, no parallelism   |
| -1          | Use all available CPU cores      |
| N > 1       | Use exactly N cores              |
| -2          | Use all cores except one         |

Models that support `n_jobs`:
- `RandomForestClassifier / Regressor`
- `GradientBoostingClassifier` (partial)
- `LogisticRegression` (solver permitting)
- `cross_val_score`, `GridSearchCV`, `RandomizedSearchCV`
- `Pipeline` (propagates to components)

---

## 11. Dask and Ray (Intro) <a name="dask-ray"></a>

### Dask
Dask provides parallel NumPy arrays, Pandas DataFrames, and task graphs that scale
from a single laptop to a cluster.

```python
import dask.dataframe as dd

df = dd.read_parquet("s3://bucket/data/*.parquet")
result = df.groupby("category")["value"].mean().compute()
```

Key concepts: **lazy evaluation**, **task graph**, **distributed scheduler**.

### Ray
Ray is a distributed computing framework designed for ML workloads.

```python
import ray

ray.init()

@ray.remote
def train_model(config):
    ...

futures = [train_model.remote(cfg) for cfg in configs]
results = ray.get(futures)
```

Ecosystem: **Ray Tune** (hyperparameter search), **Ray Serve** (model serving),
**Ray Data** (parallel data processing).

> 📁 For detailed Dask and Ray examples, see the **big-data** folder:
> `C:\Users\e135408\Downloads\personal-work\learn-ai\projects\python-ai\big-data\`

---

## Quick Reference Summary

| Task                             | Best Tool                              |
|----------------------------------|----------------------------------------|
| Concurrent HTTP requests (few)   | threading / ThreadPoolExecutor         |
| Concurrent HTTP requests (1000s) | asyncio + aiohttp                      |
| CPU-bound computation            | multiprocessing / ProcessPoolExecutor  |
| sklearn parallel training        | n_jobs=-1 (joblib)                     |
| Thread communication             | queue.Queue                            |
| Process communication            | multiprocessing.Queue / Pipe           |
| Large-scale data processing      | Dask                                   |
| Distributed ML training          | Ray                                    |