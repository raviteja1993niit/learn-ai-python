# Multithreading, Multiprocessing & Async — Code Examples

> 20+ fully working examples from basic threads to complete async pipelines.

---

## Example 1 — Basic Thread Creation

**Explanation**: The simplest way to run a function in a separate thread.

```python
import threading
import time

def say_hello(name, delay):
    time.sleep(delay)
    print(f"Hello from {name}!")

t1 = threading.Thread(target=say_hello, args=("Thread-1", 1))
t2 = threading.Thread(target=say_hello, args=("Thread-2", 2))

t1.start()
t2.start()

t1.join()  # wait for t1 to finish
t2.join()  # wait for t2 to finish
print("All threads done.")
```

---

## Example 2 — Thread with Return Value (using list)

**Explanation**: Threads don't natively return values; use a mutable container.

```python
import threading

results = []

def compute(n, out):
    out.append(sum(range(n)))

t = threading.Thread(target=compute, args=(1_000_000, results))
t.start()
t.join()
print(f"Result: {results[0]}")  # 499999500000
```

---

## Example 3 — Race Condition Demo (broken)

**Explanation**: Without a lock, two threads corrupt a shared counter.

```python
import threading

counter = 0

def increment():
    global counter
    for _ in range(100_000):
        counter += 1  # NOT atomic — race condition!

t1 = threading.Thread(target=increment)
t2 = threading.Thread(target=increment)
t1.start(); t2.start()
t1.join(); t2.join()

print(f"Expected 200000, got {counter}")  # likely < 200000
```

---

## Example 4 — Race Condition Fixed with Lock

**Explanation**: A `threading.Lock` ensures only one thread increments at a time.

```python
import threading

counter = 0
lock = threading.Lock()

def safe_increment():
    global counter
    for _ in range(100_000):
        with lock:
            counter += 1

t1 = threading.Thread(target=safe_increment)
t2 = threading.Thread(target=safe_increment)
t1.start(); t2.start()
t1.join(); t2.join()

print(f"Result: {counter}")  # always 200000
```

---

## Example 5 — Semaphore: Limit Concurrent Access

**Explanation**: Allow at most 3 threads to access a "database" simultaneously.

```python
import threading
import time

sem = threading.Semaphore(3)

def query_db(thread_id):
    with sem:
        print(f"Thread {thread_id} accessing DB")
        time.sleep(1)
        print(f"Thread {thread_id} done")

threads = [threading.Thread(target=query_db, args=(i,)) for i in range(8)]
for t in threads: t.start()
for t in threads: t.join()
```

---

## Example 6 — Event: Thread Signalling

**Explanation**: A worker waits for a start signal from the main thread.

```python
import threading
import time

start_event = threading.Event()

def worker():
    print("Worker waiting for start signal…")
    start_event.wait()
    print("Worker started!")

t = threading.Thread(target=worker)
t.start()

time.sleep(2)
print("Main: firing event")
start_event.set()
t.join()
```

---

## Example 7 — Producer-Consumer with queue.Queue

**Explanation**: The thread-safe Queue decouples producers from consumers.

```python
import threading
import queue
import time

q = queue.Queue(maxsize=5)

def producer(q):
    for i in range(10):
        q.put(f"item-{i}")
        print(f"Produced item-{i}")
        time.sleep(0.1)

def consumer(q):
    while True:
        item = q.get()
        if item is None:
            break
        print(f"  Consumed {item}")
        q.task_done()

t_prod = threading.Thread(target=producer, args=(q,))
t_cons = threading.Thread(target=consumer, args=(q,))

t_prod.start(); t_cons.start()
t_prod.join()
q.put(None)   # sentinel to stop consumer
t_cons.join()
```

---

## Example 8 — ThreadPoolExecutor: Parallel Downloads

**Explanation**: Fetch multiple URLs concurrently using a thread pool.

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.request

URLS = [
    "https://httpbin.org/get?id=1",
    "https://httpbin.org/get?id=2",
    "https://httpbin.org/get?id=3",
]

def fetch(url):
    with urllib.request.urlopen(url, timeout=5) as r:
        return url, len(r.read())

with ThreadPoolExecutor(max_workers=3) as executor:
    futures = {executor.submit(fetch, url): url for url in URLS}
    for future in as_completed(futures):
        url, size = future.result()
        print(f"{url} → {size} bytes")
```

---

## Example 9 — ProcessPoolExecutor: Parallel CPU Work

**Explanation**: Use multiple CPU cores to compute factorials in parallel.

```python
from concurrent.futures import ProcessPoolExecutor
import math

def heavy(n):
    return len(str(math.factorial(n)))  # digits in n!

numbers = [5000, 10000, 15000, 20000]

if __name__ == "__main__":
    with ProcessPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(heavy, numbers))
    for n, r in zip(numbers, results):
        print(f"{n}! has {r} digits")
```

---

## Example 10 — multiprocessing.Pool: Image Processing

**Explanation**: Apply a filter to many images in parallel.

```python
from multiprocessing import Pool
from PIL import Image
import os

def resize_image(path):
    img = Image.open(path)
    img = img.resize((224, 224))
    out = path.replace(".jpg", "_resized.jpg")
    img.save(out)
    return out

if __name__ == "__main__":
    images = [f"img_{i}.jpg" for i in range(100)]
    with Pool(processes=os.cpu_count()) as pool:
        results = pool.map(resize_image, images)
    print(f"Processed {len(results)} images")
```

---

## Example 11 — multiprocessing.Pipe: Bidirectional Communication

**Explanation**: Two processes exchange messages over a Pipe.

```python
from multiprocessing import Process, Pipe

def child(conn):
    msg = conn.recv()
    print(f"Child received: {msg}")
    conn.send(f"Echo: {msg}")
    conn.close()

if __name__ == "__main__":
    parent_conn, child_conn = Pipe()
    p = Process(target=child, args=(child_conn,))
    p.start()
    parent_conn.send("Hello, child!")
    reply = parent_conn.recv()
    print(f"Parent received: {reply}")
    p.join()
```

---

## Example 12 — Shared Memory with multiprocessing.Value

**Explanation**: Share a counter across processes safely using a lock.

```python
from multiprocessing import Process, Value

def increment(shared_val, n):
    for _ in range(n):
        with shared_val.get_lock():
            shared_val.value += 1

if __name__ == "__main__":
    counter = Value('i', 0)
    procs = [Process(target=increment, args=(counter, 100_000)) for _ in range(4)]
    for p in procs: p.start()
    for p in procs: p.join()
    print(f"Counter = {counter.value}")  # 400000
```

---

## Example 13 — Basic asyncio Coroutine

**Explanation**: The simplest async/await example with simulated I/O.

```python
import asyncio

async def greet(name, delay):
    await asyncio.sleep(delay)   # non-blocking sleep
    print(f"Hello, {name}!")

async def main():
    await asyncio.gather(
        greet("Alice", 1),
        greet("Bob", 2),
        greet("Charlie", 0.5),
    )

asyncio.run(main())
# Output order: Charlie, Alice, Bob (by delay)
```

---

## Example 14 — asyncio.create_task: Fire and Forget

**Explanation**: Schedule tasks without immediately awaiting them.

```python
import asyncio

async def background_job(name):
    await asyncio.sleep(1)
    print(f"Job {name} done")

async def main():
    task1 = asyncio.create_task(background_job("A"))
    task2 = asyncio.create_task(background_job("B"))
    print("Tasks created, doing other work…")
    await asyncio.sleep(0.1)
    await task1
    await task2

asyncio.run(main())
```

---

## Example 15 — asyncio Producer-Consumer

**Explanation**: An async queue coordinates producer and consumer coroutines.

```python
import asyncio

async def producer(queue):
    for i in range(5):
        await asyncio.sleep(0.1)
        await queue.put(f"item-{i}")
        print(f"Produced item-{i}")
    await queue.put(None)  # sentinel

async def consumer(queue):
    while True:
        item = await queue.get()
        if item is None:
            break
        print(f"  Consumed {item}")
        queue.task_done()

async def main():
    q = asyncio.Queue()
    await asyncio.gather(producer(q), consumer(q))

asyncio.run(main())
```

---

## Example 16 — aiohttp: Async HTTP Requests

**Explanation**: Fetch 10 URLs concurrently using aiohttp.

```python
# pip install aiohttp
import asyncio
import aiohttp

URLS = [f"https://httpbin.org/get?n={i}" for i in range(10)]

async def fetch(session, url):
    async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as resp:
        data = await resp.json()
        return data["args"]

async def main():
    async with aiohttp.ClientSession() as session:
        tasks = [fetch(session, url) for url in URLS]
        results = await asyncio.gather(*tasks)
    for r in results:
        print(r)

asyncio.run(main())
```

---

## Example 17 — asyncio with Timeout

**Explanation**: Cancel a coroutine if it takes too long.

```python
import asyncio

async def slow_operation():
    await asyncio.sleep(10)
    return "done"

async def main():
    try:
        result = await asyncio.wait_for(slow_operation(), timeout=2.0)
    except asyncio.TimeoutError:
        print("Operation timed out after 2 seconds")

asyncio.run(main())
```

---

## Example 18 — Parallel sklearn Cross-Validation

**Explanation**: Use n_jobs=-1 to run CV folds on all CPU cores.

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score
from sklearn.datasets import make_classification
import numpy as np

X, y = make_classification(n_samples=50_000, n_features=20, random_state=42)

# n_jobs=-1 uses ALL available CPU cores
model = RandomForestClassifier(n_estimators=200, n_jobs=-1, random_state=42)
scores = cross_val_score(model, X, y, cv=5, n_jobs=-1, scoring="accuracy")

print(f"CV Scores: {np.round(scores, 4)}")
print(f"Mean: {scores.mean():.4f} ± {scores.std():.4f}")
```

---

## Example 19 — Parallel Feature Engineering

**Explanation**: Apply expensive transformations to DataFrame chunks in parallel.

```python
from multiprocessing import Pool
import pandas as pd
import numpy as np
import os

def engineer_chunk(chunk):
    chunk = chunk.copy()
    chunk["log_val"] = np.log1p(chunk["value"].clip(lower=0))
    chunk["zscore"] = (chunk["value"] - chunk["value"].mean()) / chunk["value"].std()
    return chunk

if __name__ == "__main__":
    df = pd.DataFrame({"value": np.random.exponential(5, size=1_000_000)})
    chunks = np.array_split(df, os.cpu_count())

    with Pool(processes=os.cpu_count()) as pool:
        processed = pool.map(engineer_chunk, chunks)

    result = pd.concat(processed, ignore_index=True)
    print(result.head())
```

---

## Example 20 — Full Async Web Scraper Pipeline

**Explanation**: A complete async pipeline: fetch → parse → save, with concurrency limiting.

```python
# pip install aiohttp beautifulsoup4
import asyncio
import aiohttp
from bs4 import BeautifulSoup

URLS = [
    "https://en.wikipedia.org/wiki/Python_(programming_language)",
    "https://en.wikipedia.org/wiki/Asyncio",
    "https://en.wikipedia.org/wiki/Multithreading_(computer_architecture)",
]

SEM = asyncio.Semaphore(2)  # max 2 concurrent requests

async def fetch_page(session, url):
    async with SEM:
        async with session.get(url, timeout=aiohttp.ClientTimeout(total=15)) as resp:
            return url, await resp.text()

def parse_title(html):
    soup = BeautifulSoup(html, "html.parser")
    tag = soup.find("h1", {"id": "firstHeading"})
    return tag.get_text(strip=True) if tag else "Unknown"

async def scrape(url, session, results):
    url, html = await fetch_page(session, url)
    title = parse_title(html)
    results.append({"url": url, "title": title})
    print(f"Scraped: {title}")

async def main():
    results = []
    async with aiohttp.ClientSession() as session:
        tasks = [scrape(url, session, results) for url in URLS]
        await asyncio.gather(*tasks)
    return results

if __name__ == "__main__":
    data = asyncio.run(main())
    for item in data:
        print(item)
```

---

## Example 21 — ProcessPoolExecutor with Chunked ML Training

**Explanation**: Train multiple models in parallel and pick the best one.

```python
from concurrent.futures import ProcessPoolExecutor, as_completed
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.datasets import make_classification
import numpy as np

X, y = make_classification(n_samples=10_000, n_features=15, random_state=0)

def evaluate_model(args):
    name, model = args
    scores = cross_val_score(model, X, y, cv=3, scoring="accuracy")
    return name, scores.mean()

models = [
    ("RandomForest", RandomForestClassifier(n_estimators=100, random_state=0)),
    ("GBM", GradientBoostingClassifier(n_estimators=100, random_state=0)),
    ("LogReg", LogisticRegression(max_iter=1000)),
]

if __name__ == "__main__":
    with ProcessPoolExecutor(max_workers=3) as executor:
        futures = {executor.submit(evaluate_model, m): m[0] for m in models}
        for future in as_completed(futures):
            name, score = future.result()
            print(f"{name}: {score:.4f}")
```

---

## Example 22 — RLock for Recursive Thread-Safe Operations

**Explanation**: Use RLock when a method that holds a lock calls another locked method.

```python
import threading

class BankAccount:
    def __init__(self, balance):
        self.balance = balance
        self._lock = threading.RLock()

    def withdraw(self, amount):
        with self._lock:
            if amount <= self.balance:
                self.balance -= amount
                return True
            return False

    def transfer_to(self, other, amount):
        with self._lock:       # re-acquires same RLock safely
            if self.withdraw(amount):
                other.balance += amount
                return True
            return False

acc1 = BankAccount(1000)
acc2 = BankAccount(500)
acc1.transfer_to(acc2, 200)
print(acc1.balance, acc2.balance)  # 800 700
```