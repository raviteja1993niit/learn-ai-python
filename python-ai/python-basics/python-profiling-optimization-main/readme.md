# ⚡ Python Profiling & Performance Optimization — Find and Fix Bottlenecks

## What is this?
Profiling measures where your Python program spends time and memory so you can optimize the right code, not the wrong code. The Python ecosystem offers tools ranging from built-in `cProfile` to GPU-aware `Scalene`, and optimization techniques from `lru_cache` to compiled Numba JIT kernels.

## Why Learn It?
- ML training loops waste hours on avoidable Python-level overhead — profiling reveals the culprit
- NumPy vectorization can be 100–1000× faster than equivalent Python loops
- Memory profiling prevents OOM crashes on large datasets before they hit production
- Knowing when to reach for Numba or Cython vs. just fixing an algorithm saves days of work

## Key Concepts
```python
# ── 1. cProfile: whole-program profiling ──────────────────────────────────────
# CLI: python -m cProfile -s cumtime my_script.py
import cProfile, pstats, io

def slow_fn():
    return sum(i**2 for i in range(500_000))

pr = cProfile.Profile()
pr.enable()
slow_fn()
pr.disable()

stream = io.StringIO()
ps = pstats.Stats(pr, stream=stream).sort_stats("cumulative")
ps.print_stats(10)   # top 10 hotspots
print(stream.getvalue())

# ── 2. timeit: micro-benchmarks ───────────────────────────────────────────────
import timeit

list_comp = timeit.timeit("[i**2 for i in range(1000)]", number=10_000)
numpy_way = timeit.timeit(
    "import numpy as np; np.arange(1000)**2", number=10_000
)
print(f"list comp: {list_comp:.3f}s  |  numpy: {numpy_way:.3f}s")

# ── 3. line_profiler: line-by-line timing ─────────────────────────────────────
# pip install line_profiler
# Decorate with @profile, then: kernprof -l -v my_script.py
#
# @profile
# def training_step(model, batch):
#     x, y = batch
#     preds = model(x)          # <-- kernprof shows time here
#     loss = criterion(preds, y)
#     loss.backward()
#     optimizer.step()
#     return loss.item()

# ── 4. memory_profiler: line-by-line RAM usage ────────────────────────────────
# pip install memory_profiler
# Decorate with @profile, then: python -m memory_profiler my_script.py
# CLI batch profiling: mprof run my_script.py && mprof plot
#
# @profile
# def load_dataset(path):
#     df = pd.read_csv(path)     # line shows +MB delta
#     return df.values

# ── 5. Scalene: CPU + memory + GPU in one tool ────────────────────────────────
# pip install scalene
# scalene my_script.py   →  opens browser report
# Shows Python vs native time split, highlights lines worth optimizing

# ── 6. Python loops vs NumPy vectorization ────────────────────────────────────
import numpy as np

data = list(range(1_000_000))

def python_loop(data):
    return [x * 2 + 1 for x in data]          # ~80ms

def numpy_vec(data):
    arr = np.array(data)
    return arr * 2 + 1                          # ~3ms — ~27x faster

# ── 7. functools.lru_cache for expensive repeated calls ──────────────────────
from functools import lru_cache

@lru_cache(maxsize=256)
def tokenize(text: str) -> tuple:
    return tuple(text.lower().split())

# ── 8. __slots__ to shrink per-object memory ─────────────────────────────────
class NormalSample:
    def __init__(self, x, y): self.x = x; self.y = y

class SlottedSample:
    __slots__ = ("x", "y")
    def __init__(self, x, y): self.x = x; self.y = y

import sys
print(sys.getsizeof(NormalSample(1, 2)))   # ~48 bytes (+ dict overhead)
print(sys.getsizeof(SlottedSample(1, 2)))  # ~32 bytes

# ── 9. Numba JIT: near-C speed for numeric loops ─────────────────────────────
# pip install numba
from numba import jit

@jit(nopython=True)
def numba_pairwise(X):
    n = X.shape[0]
    D = np.empty((n, n))
    for i in range(n):
        for j in range(n):
            D[i, j] = np.sqrt(np.sum((X[i] - X[j])**2))
    return D

X = np.random.rand(300, 128).astype(np.float32)
D = numba_pairwise(X)   # first call compiles; subsequent calls are fast

# ── 10. Profile a ML training loop with cProfile ─────────────────────────────
# python -m cProfile -o profile.out train.py
# python -c "import pstats; p=pstats.Stats('profile.out'); p.sort_stats('cumtime'); p.print_stats(20)"
```

## Learning Path
1. `pip install line_profiler memory_profiler scalene numba`
2. Profile a script you own with `python -m cProfile -s cumtime`
3. Identify the top hotspot and rewrite it with NumPy vectorization
4. Run `mprof run` on a data-loading script and plot memory over time
5. Apply `@jit(nopython=True)` to a numeric loop and compare with `timeit`
6. Install Scalene and profile a PyTorch training step end-to-end

## What to Build
- [ ] Profile a slow preprocessing pipeline and cut runtime by 50% using NumPy
- [ ] Memory-profile a DataLoader and track peak RAM per batch size
- [ ] Replace a nested Python loop with a Numba-compiled function and benchmark
- [ ] Build a decorator that wraps any function with `cProfile` and logs top-5 hotspots
- [ ] Compare `lru_cache` vs `functools.cache` on a recursive Fibonacci and tokenizer

## Related Folders
- `python-basics\numpy-pandas-main\` — vectorization patterns that replace slow loops
- `deep-learning\pytorch-basics-main\` — profiling `torch.utils.bottleneck` in training
- `python-basics\concurrency-main\` — multiprocessing as another speed lever
