# 📐 Linear Algebra for ML — The Math Behind the Models

## What is Linear Algebra for ML?
Linear algebra is the mathematical foundation of nearly every machine learning algorithm. Vectors represent data points and embeddings, matrices encode transformations and weights, and operations like SVD and eigendecomposition power dimensionality reduction, attention mechanisms, and more.

## Why Learn It?
- Neural network layers are matrix multiplications — understanding shapes prevents bugs
- Word/image embeddings are vectors; cosine similarity and dot products drive RAG and search
- PCA and SVD compress high-dimensional data and are used in recommendation systems
- Eigenvalues explain variance in data and stability in optimization

## Key Concepts
```python
import numpy as np

# Vectors and dot product (cosine similarity in embeddings)
a = np.array([1.0, 2.0, 3.0])
b = np.array([4.0, 5.0, 6.0])
dot = np.dot(a, b)
cosine_sim = dot / (np.linalg.norm(a) * np.linalg.norm(b))

# Matrix multiplication (core of every neural net layer)
W = np.random.randn(4, 3)   # weight matrix
x = np.random.randn(3, 1)   # input vector
output = W @ x              # shape (4, 1)

# Eigenvalues / eigenvectors
cov_matrix = np.cov(np.random.randn(3, 100))
eigenvalues, eigenvectors = np.linalg.eig(cov_matrix)

# SVD — the engine behind PCA and LSA
X = np.random.randn(50, 10)
U, S, Vt = np.linalg.svd(X, full_matrices=False)

# PCA from scratch (without sklearn)
X_centered = X - X.mean(axis=0)
cov = np.cov(X_centered.T)
vals, vecs = np.linalg.eigh(cov)
top_k = vecs[:, -2:]                    # top 2 principal components
X_reduced = X_centered @ top_k          # project to 2D
print(f"Original: {X.shape}, Reduced: {X_reduced.shape}")
```

## Learning Path
1. `pip install numpy matplotlib`
2. Master vectors: addition, scaling, dot product, norm, cosine similarity
3. Master matrices: multiplication (`@`), transpose, inverse, determinant
4. Study eigendecomposition — run it on a covariance matrix and interpret results
5. Implement PCA from scratch using SVD, then compare with `sklearn.decomposition.PCA`

## What to Build
- [ ] A cosine similarity search engine over 1000 random embedding vectors
- [ ] PCA from scratch that reduces MNIST 784-dim images to 2D for visualization
- [ ] A matrix factorization toy recommender system using SVD on a user-item matrix

## Related Folders
- `python-basics/asyncio-concurrency-main/` — async vector search queries over embedding stores
- `machine-learning/xgboost-tutorial-main/` — feature matrices feed directly into gradient boosted trees
