# 📖 Comprehensive Reference Guide
## Key Terms, Keywords, Acronyms, File Types & Concepts

Complete reference for every term, acronym, file format, and concept used across this repository.

---

## 📋 Table of Contents

1. [Acronyms & Abbreviations](#1-acronyms--abbreviations)
2. [File Types & Extensions](#2-file-types--extensions)
3. [Python & Programming Terms](#3-python--programming-terms)
4. [AI / ML Core Concepts](#4-ai--ml-core-concepts)
5. [Large Language Models (LLMs)](#5-large-language-models-llms)
6. [Agentic AI & Orchestration](#6-agentic-ai--orchestration)
7. [Generative AI Terms](#7-generative-ai-terms)
8. [Deep Learning Terms](#8-deep-learning-terms)
9. [Computer Vision Terms](#9-computer-vision-terms)
10. [NLP Terms](#10-nlp-terms)
11. [Data Science Terms](#11-data-science-terms)
12. [Vector Databases & Embeddings](#12-vector-databases--embeddings)
13. [MLOps & Deployment Terms](#13-mlops--deployment-terms)
14. [Cloud & Infrastructure Terms](#14-cloud--infrastructure-terms)
15. [Database Terms](#15-database-terms)
16. [Big Data Terms](#16-big-data-terms)
17. [Web Framework Terms](#17-web-framework-terms)
18. [Blockchain Terms](#18-blockchain-terms)
19. [Environment & Config Keywords](#19-environment--config-keywords)
20. [Python Package Ecosystem](#20-python-package-ecosystem)

---

## 1. Acronyms & Abbreviations

### AI / ML

| Acronym | Full Form | Definition |
|---------|-----------|------------|
| **AI** | Artificial Intelligence | Computer systems that simulate human intelligence |
| **ML** | Machine Learning | Systems that learn from data without explicit programming |
| **DL** | Deep Learning | ML using multi-layer neural networks |
| **NLP** | Natural Language Processing | AI for understanding and generating human language |
| **CV** | Computer Vision | AI for interpreting visual data (images/video) |
| **LLM** | Large Language Model | Massive neural network trained on text (GPT-4, Claude, Gemini) |
| **SLM** | Small Language Model | Compact LLM for edge deployment (Phi-3, Gemma 2B) |
| **VLM** | Vision Language Model | LLM that understands both images and text |
| **MLM** | Masked Language Model | BERT-style pre-training: predict masked tokens |
| **CLM** | Causal Language Model | GPT-style: predict next token |
| **RLHF** | Reinforcement Learning from Human Feedback | Training LLMs using human preference ratings |
| **PPO** | Proximal Policy Optimization | RLHF training algorithm |
| **DPO** | Direct Preference Optimization | Alternative to PPO for LLM alignment |
| **RAG** | Retrieval-Augmented Generation | Combining search + LLM generation |
| **KG** | Knowledge Graph | Structured representation of entities and relationships |
| **KNN** / **k-NN** | K-Nearest Neighbors | Classification/regression by proximity |
| **SVM** | Support Vector Machine | Supervised learning for classification |
| **GAN** | Generative Adversarial Network | Two-network architecture for generating data |
| **VAE** | Variational Autoencoder | Generative model with latent space |
| **AE** | Autoencoder | Neural net for unsupervised feature learning |
| **CNN** | Convolutional Neural Network | Neural net for image processing |
| **RNN** | Recurrent Neural Network | Neural net for sequential data |
| **LSTM** | Long Short-Term Memory | RNN variant that handles long-range dependencies |
| **GRU** | Gated Recurrent Unit | Simplified LSTM |
| **GNN** | Graph Neural Network | Neural net operating on graph structures |
| **ViT** | Vision Transformer | Transformer architecture applied to image patches |
| **BERT** | Bidirectional Encoder Representations from Transformers | Google's MLM pre-trained model |
| **GPT** | Generative Pre-trained Transformer | OpenAI's autoregressive language model |
| **T5** | Text-to-Text Transfer Transformer | Google's unified text generation model |
| **XGBoost** | Extreme Gradient Boosting | High-performance gradient boosting library |
| **GBDT** | Gradient Boosted Decision Trees | Ensemble method using decision trees sequentially |
| **PCA** | Principal Component Analysis | Dimensionality reduction technique |
| **t-SNE** | t-distributed Stochastic Neighbor Embedding | Non-linear dimensionality reduction for visualization |
| **UMAP** | Uniform Manifold Approximation and Projection | Fast dimensionality reduction |
| **AUC** | Area Under the Curve | Model evaluation metric |
| **ROC** | Receiver Operating Characteristic | Curve showing true vs false positive rates |
| **MSE** | Mean Squared Error | Regression loss function |
| **MAE** | Mean Absolute Error | Regression metric |
| **RMSE** | Root Mean Squared Error | Common regression metric |
| **F1** | F1 Score | Harmonic mean of precision and recall |
| **MAP** | Mean Average Precision | Ranking evaluation metric |
| **MCC** | Matthews Correlation Coefficient | Binary classification metric |
| **IOU** / **IoU** | Intersection over Union | Object detection overlap metric |
| **mAP** | Mean Average Precision | Object detection evaluation metric |
| **BLEU** | Bilingual Evaluation Understudy | Translation quality metric |
| **ROUGE** | Recall-Oriented Understudy for Gisting Evaluation | Summarization quality metric |
| **METEOR** | Metric for Evaluation of Translation with Explicit ORdering | NLP metric |
| **BM25** | Best Match 25 | TF-IDF-based document ranking algorithm |
| **TF-IDF** | Term Frequency-Inverse Document Frequency | Text importance weighting |
| **BoW** | Bag of Words | Text representation ignoring order |
| **NER** | Named Entity Recognition | Identifying names, places, orgs in text |
| **POS** | Part-of-Speech | Grammatical tagging of words |
| **ASR** | Automatic Speech Recognition | Speech-to-text |
| **TTS** | Text-to-Speech | Text-to-audio synthesis |
| **OCR** | Optical Character Recognition | Extracting text from images |
| **STT** | Speech-to-Text | See ASR |
| **EDA** | Exploratory Data Analysis | Initial data investigation |
| **FE** | Feature Engineering | Creating features from raw data |
| **HP** / **HPO** | Hyperparameter Optimization | Tuning model configuration |
| **MLP** | Multi-Layer Perceptron | Fully connected neural network |
| **BN** | Batch Normalization | Normalizing layer activations |
| **LN** | Layer Normalization | Normalization used in Transformers |
| **FFN** | Feed-Forward Network | Dense layers within a Transformer block |
| **MHA** | Multi-Head Attention | Core Transformer attention mechanism |
| **KV Cache** | Key-Value Cache | LLM inference optimization: reuse attention state |

---

### DevOps / Cloud / Infrastructure

| Acronym | Full Form | Definition |
|---------|-----------|------------|
| **API** | Application Programming Interface | Interface for software communication |
| **REST** | Representational State Transfer | HTTP-based API architecture |
| **gRPC** | Google Remote Procedure Call | High-performance RPC framework |
| **CI/CD** | Continuous Integration / Continuous Deployment | Automated build, test, deploy pipeline |
| **IaC** | Infrastructure as Code | Managing infrastructure via code (Terraform) |
| **VM** | Virtual Machine | Emulated computer running on physical hardware |
| **VPC** | Virtual Private Cloud | Isolated cloud network |
| **IAM** | Identity and Access Management | Cloud permissions system |
| **S3** | Simple Storage Service | AWS object storage |
| **EC2** | Elastic Compute Cloud | AWS virtual machines |
| **ECS** | Elastic Container Service | AWS container orchestration |
| **EKS** | Elastic Kubernetes Service | AWS managed Kubernetes |
| **GCS** | Google Cloud Storage | GCP object storage |
| **GKE** | Google Kubernetes Engine | GCP managed Kubernetes |
| **AKS** | Azure Kubernetes Service | Azure managed Kubernetes |
| **CDN** | Content Delivery Network | Distributed content caching |
| **DNS** | Domain Name System | Maps domain names to IPs |
| **SSL** / **TLS** | Secure Sockets Layer / Transport Layer Security | Encrypted communication |
| **JWT** | JSON Web Token | Stateless authentication standard |
| **OAuth** | Open Authorization | Authorization protocol |
| **CORS** | Cross-Origin Resource Sharing | Browser security policy for APIs |
| **WSGI** | Web Server Gateway Interface | Python web server interface (Flask, Django) |
| **ASGI** | Asynchronous Server Gateway Interface | Async Python web interface (FastAPI) |
| **ORM** | Object-Relational Mapping | Database abstraction layer (SQLAlchemy) |
| **CRUD** | Create, Read, Update, Delete | Basic database operations |
| **ETL** | Extract, Transform, Load | Data pipeline pattern |
| **ELT** | Extract, Load, Transform | Modern data pipeline (load first, transform in warehouse) |
| **OLAP** | Online Analytical Processing | Analytics workloads |
| **OLTP** | Online Transaction Processing | Transactional workloads |
| **SLA** | Service Level Agreement | Performance/uptime commitments |
| **SLO** | Service Level Objective | Internal performance targets |
| **GPU** | Graphics Processing Unit | Parallel computing processor for ML |
| **CPU** | Central Processing Unit | General-purpose processor |
| **TPU** | Tensor Processing Unit | Google's ML-optimized chip |
| **CUDA** | Compute Unified Device Architecture | NVIDIA's GPU programming platform |
| **cuDNN** | CUDA Deep Neural Network library | GPU-accelerated DL primitives |
| **ONNX** | Open Neural Network Exchange | Model interoperability format |
| **YAML** | YAML Ain't Markup Language | Human-readable config file format |
| **JSON** | JavaScript Object Notation | Lightweight data-interchange format |
| **TOML** | Tom's Obvious, Minimal Language | Config file format (pyproject.toml) |
| **CSV** | Comma-Separated Values | Tabular data text format |
| **SQL** | Structured Query Language | Relational database query language |
| **NoSQL** | Not Only SQL | Non-relational databases |
| **ACID** | Atomicity, Consistency, Isolation, Durability | Database transaction properties |
| **CAP** | Consistency, Availability, Partition tolerance | Distributed systems theorem |

---

### MLOps

| Acronym | Full Form | Definition |
|---------|-----------|------------|
| **MLOps** | Machine Learning Operations | DevOps practices applied to ML |
| **LLMOps** | Large Language Model Operations | MLOps for LLM systems |
| **AIOps** | AI for IT Operations | Using AI to manage infrastructure |
| **DataOps** | Data Operations | DevOps for data pipelines |
| **FeatureStore** | Feature Store | Centralized feature repository for ML |
| **DVC** | Data Version Control | Git-like versioning for datasets/models |
| **W&B** | Weights & Biases | ML experiment tracking platform |
| **A/B Testing** | Split Testing | Comparing two versions statistically |
| **PMML** | Predictive Model Markup Language | XML standard for ML models |
| **SHAP** | SHapley Additive exPlanations | Model interpretability framework |
| **LIME** | Local Interpretable Model-agnostic Explanations | ML explanation technique |

---

## 2. File Types & Extensions

### Python Files

| Extension | Name | Description | Example |
|-----------|------|-------------|---------|
| `.py` | Python Source File | Main Python code | `main.py`, `train.py` |
| `.ipynb` | Jupyter Notebook | Interactive Python notebook with code + markdown | `EDA.ipynb` |
| `.pyi` | Python Type Stub | Type hints for IDEs and mypy | `module.pyi` |
| `__init__.py` | Package Init | Makes a directory a Python package | `__init__.py` |
| `__main__.py` | Module Entry Point | Enables `python -m module` execution | `__main__.py` |
| `conftest.py` | Pytest Config | Shared fixtures for tests | `conftest.py` |
| `setup.py` | Legacy Package Setup | Old-style package configuration | `setup.py` |
| `setup.cfg` | Setup Config | INI-style package configuration | `setup.cfg` |

### Configuration Files

| Extension / Name | Format | Description |
|-----------------|--------|-------------|
| `pyproject.toml` | TOML | Modern Python project config (PEP 517/518); used by uv, poetry, build |
| `requirements.txt` | Plain text | pip dependency list with optional version pins |
| `requirements-dev.txt` | Plain text | Development-only dependencies |
| `environment.yml` | YAML | Conda environment definition |
| `uv.lock` | TOML-like | uv lockfile — exact pinned versions for reproducibility |
| `poetry.lock` | TOML | Poetry lockfile |
| `Pipfile` | TOML | Pipenv dependency file |
| `Pipfile.lock` | JSON | Pipenv lockfile |
| `.env` | Key=Value | Environment variables (secrets, config) — never commit |
| `.env.example` | Key=Value | Template `.env` with placeholder values — safe to commit |
| `.flake8` | INI | Flake8 linter config |
| `.pylintrc` | INI | Pylint linter config |
| `mypy.ini` | INI | Mypy type checker config |
| `pytest.ini` | INI | Pytest runner config |
| `tox.ini` | INI | Tox test automation config |
| `.pre-commit-config.yaml` | YAML | Pre-commit hooks config |
| `Makefile` | Make | Build automation commands |

### Docker & Container Files

| File | Description |
|------|-------------|
| `Dockerfile` | Instructions to build a Docker image |
| `docker-compose.yml` | Multi-container Docker app definition |
| `docker-compose.override.yml` | Local overrides for docker-compose |
| `.dockerignore` | Files to exclude from Docker build context |
| `k8s/*.yaml` | Kubernetes manifests (deployments, services) |
| `helm/` | Helm chart directory for Kubernetes templating |

### Git Files

| File | Description |
|------|-------------|
| `.gitignore` | Files/folders excluded from git tracking |
| `.gitattributes` | Git file handling rules (line endings, diff) |
| `.github/workflows/*.yml` | GitHub Actions CI/CD pipeline definitions |

### ML Model Files

| Extension | Format | Description | Used By |
|-----------|--------|-------------|---------|
| `.pt` / `.pth` | PyTorch | PyTorch model weights/checkpoint | torch.save() |
| `.ckpt` | Checkpoint | Training checkpoint (PyTorch Lightning, TF) | Lightning, TF |
| `.h5` / `.hdf5` | HDF5 | Keras/TensorFlow model weights | keras.save() |
| `.pb` | Protocol Buffer | TensorFlow SavedModel or frozen graph | TensorFlow |
| `.tflite` | TensorFlow Lite | Compressed model for mobile/edge | TFLite |
| `.onnx` | ONNX | Cross-framework model exchange format | All frameworks |
| `.pkl` / `.pickle` | Pickle | Python object serialization (models, scalers) | scikit-learn |
| `.joblib` | Joblib | Efficient pickle for NumPy arrays | scikit-learn |
| `.safetensors` | SafeTensors | Safe, fast HuggingFace model format | transformers |
| `.bin` | Binary | HuggingFace PyTorch weights | transformers |
| `.gguf` | GGUF | Quantized model format for llama.cpp/Ollama | Ollama, llama.cpp |
| `.ggml` | GGML | Older quantized format (superseded by GGUF) | llama.cpp |
| `.mlmodel` | CoreML | Apple CoreML model format | iOS/macOS |
| `.mar` | Model Archive | TorchServe model package | TorchServe |

### Data Files

| Extension | Format | Description |
|-----------|--------|-------------|
| `.csv` | CSV | Tabular data, comma-separated |
| `.tsv` | TSV | Tabular data, tab-separated |
| `.json` | JSON | Structured data |
| `.jsonl` | JSON Lines | One JSON object per line (datasets) |
| `.parquet` | Parquet | Columnar binary format (fast, compressed) |
| `.feather` | Feather | Fast columnar format (pandas/Arrow) |
| `.arrow` | Arrow | Apache Arrow in-memory format |
| `.hdf5` / `.h5` | HDF5 | Hierarchical Data Format (large arrays) |
| `.npy` | NumPy | Single NumPy array binary |
| `.npz` | NumPy Zip | Multiple NumPy arrays compressed |
| `.xlsx` / `.xls` | Excel | Microsoft Excel spreadsheet |
| `.db` / `.sqlite` | SQLite | Embedded relational database file |
| `.avro` | Avro | Hadoop serialization format |
| `.orc` | ORC | Optimized Row Columnar (Hive) |
| `.tfrecord` | TFRecord | TensorFlow training data format |
| `.msgpack` | MessagePack | Binary JSON alternative |

### Web & API Files

| Extension | Description |
|-----------|-------------|
| `.html` | HyperText Markup Language — web page |
| `.css` | Cascading Style Sheets — styling |
| `.js` | JavaScript — client-side logic |
| `.ts` | TypeScript — typed JavaScript |
| `.yaml` / `.yml` | YAML — config, OpenAPI specs, Docker Compose |
| `.toml` | TOML — pyproject, Cargo, config files |
| `.xml` | XML — structured data, PMML |
| `.proto` | Protocol Buffers — gRPC schema definition |
| `.graphql` | GraphQL — API query language schema |

### Media Files (used in CV/Audio projects)

| Extension | Description |
|-----------|-------------|
| `.jpg` / `.jpeg` | JPEG image (lossy compression) |
| `.png` | PNG image (lossless) |
| `.gif` | Animated/static image |
| `.bmp` | Bitmap image |
| `.tiff` | High-quality image (medical, satellite) |
| `.mp4` / `.avi` / `.mkv` | Video formats |
| `.mp3` / `.wav` / `.flac` | Audio formats |
| `.pt` (weights) | Also used for PyTorch YOLO weights (e.g., `yolov8n.pt`) |

---

## 3. Python & Programming Terms

### Language Constructs

| Term | Definition |
|------|------------|
| **Decorator** | `@` syntax to wrap/modify functions — `@app.route()`, `@staticmethod` |
| **Generator** | Function using `yield` — lazy iteration, memory-efficient |
| **Comprehension** | Compact syntax: `[x for x in list]`, `{k: v for k, v in dict.items()}` |
| **Context Manager** | `with` statement; handles setup/teardown — `with open(file) as f:` |
| **Dataclass** | `@dataclass` — auto-generates `__init__`, `__repr__` from fields |
| **Protocol** | Structural subtyping interface (duck typing with type hints) |
| **Type Hints** | `def fn(x: int) -> str:` — static type annotations |
| **f-string** | `f"Hello {name}"` — formatted string literals (Python 3.6+) |
| **Walrus Operator** | `:=` — assignment inside expressions (Python 3.8+) |
| **asyncio** | Python library for async/await concurrency |
| **GIL** | Global Interpreter Lock — CPython's thread safety mechanism |
| **Dunder** | Double-underscore methods: `__init__`, `__repr__`, `__len__` |
| **EAFP** | Easier to Ask Forgiveness than Permission — try/except style |
| **LBYL** | Look Before You Leap — check-first style |
| **MRO** | Method Resolution Order — class inheritance lookup order |
| **ABC** | Abstract Base Class — enforces method implementation |
| **Metaclass** | Class that creates other classes |
| **Closure** | Inner function capturing outer scope variables |
| **Lambda** | Anonymous one-line function: `lambda x: x * 2` |
| ***args / **kwargs** | Variable positional / keyword arguments |

### Package & Project Structure

| Term | Definition |
|------|------------|
| **Virtual Environment** | Isolated Python environment per project (`venv`, `conda env`) |
| **Package** | Directory with `__init__.py` — importable module collection |
| **Module** | Single `.py` file |
| **Namespace Package** | Package without `__init__.py` (PEP 420) |
| **Entry Point** | CLI command registered in `pyproject.toml` or `setup.py` |
| **Editable Install** | `pip install -e .` — changes reflect immediately without reinstall |
| **Wheel** | `.whl` — pre-built Python package (faster than source install) |
| **sdist** | Source distribution — `.tar.gz` package |
| **PEP** | Python Enhancement Proposal — official Python design documents |
| **PyPI** | Python Package Index — https://pypi.org |

---

## 4. AI / ML Core Concepts

### Fundamentals

| Term | Definition |
|------|------------|
| **Supervised Learning** | Training with labeled input→output pairs |
| **Unsupervised Learning** | Finding patterns in unlabeled data |
| **Semi-supervised Learning** | Mix of labeled and unlabeled data |
| **Self-supervised Learning** | Labels derived from data itself (e.g., predict next token) |
| **Reinforcement Learning** | Agent learns by reward/penalty feedback |
| **Online Learning** | Model updates incrementally with new data |
| **Batch Learning** | Model trained on full dataset at once |
| **Transfer Learning** | Reusing a pre-trained model on a new task |
| **Fine-tuning** | Additional training of a pre-trained model on task-specific data |
| **Zero-shot** | Model solves task without task-specific examples |
| **Few-shot** | Model solves task with a handful of examples in the prompt |
| **One-shot** | Model solves task with exactly one example |
| **In-context Learning** | LLM adapts behavior based solely on prompt examples |
| **Foundation Model** | Large pre-trained model used as base for many tasks |
| **Multi-modal** | Model handling multiple input types (text + image + audio) |

### Training Concepts

| Term | Definition |
|------|------------|
| **Epoch** | One complete pass through the training dataset |
| **Batch Size** | Number of samples per gradient update |
| **Learning Rate** | Step size for gradient updates |
| **Gradient Descent** | Optimization algorithm minimizing loss |
| **Stochastic Gradient Descent (SGD)** | Gradient descent with random batch sampling |
| **Adam** | Adaptive Moment Estimation — popular optimizer |
| **AdamW** | Adam with decoupled weight decay |
| **Weight Decay** | L2 regularization to prevent overfitting |
| **Dropout** | Random neuron deactivation during training (regularization) |
| **Early Stopping** | Stop training when validation loss stops improving |
| **Gradient Clipping** | Cap gradient magnitude to prevent exploding gradients |
| **Warmup** | Gradually increase learning rate at training start |
| **Learning Rate Scheduler** | Dynamically adjust LR during training |
| **Backpropagation** | Algorithm computing gradients via chain rule |
| **Forward Pass** | Computing predictions from input to output |
| **Loss Function** | Measures prediction error (Cross-entropy, MSE, etc.) |
| **Regularization** | Techniques to prevent overfitting (L1, L2, Dropout) |
| **Overfitting** | Model memorizes training data, fails on new data |
| **Underfitting** | Model too simple to capture data patterns |
| **Bias-Variance Tradeoff** | Balance between model complexity and generalization |
| **Cross-validation** | Evaluating model on multiple train/test splits |
| **K-Fold CV** | Splitting data into K equal parts for cross-validation |
| **Train/Val/Test Split** | Typical 70/15/15 or 80/10/10 data split |
| **Data Augmentation** | Artificially expanding dataset (flip, rotate, crop, etc.) |
| **Class Imbalance** | Unequal class distribution in classification data |
| **SMOTE** | Synthetic Minority Over-sampling Technique |
| **Hyperparameter** | Configuration set before training (lr, batch size, layers) |
| **Checkpoint** | Saved model state at a training step |
| **Mixed Precision** | Using float16 + float32 to speed up training |

### Model Evaluation

| Term | Definition |
|------|------------|
| **Accuracy** | (TP+TN) / Total — proportion correct |
| **Precision** | TP / (TP+FP) — of predicted positives, how many are correct |
| **Recall / Sensitivity** | TP / (TP+FN) — of actual positives, how many found |
| **Specificity** | TN / (TN+FP) — true negative rate |
| **F1 Score** | 2 * (Precision*Recall) / (Precision+Recall) |
| **Confusion Matrix** | Table of TP, TN, FP, FN counts |
| **ROC Curve** | Plot of TPR vs FPR at various thresholds |
| **AUC-ROC** | Area under ROC curve — 0.5 = random, 1.0 = perfect |
| **PR Curve** | Precision-Recall curve |
| **Log Loss** | Cross-entropy loss for probabilistic predictions |
| **Calibration** | How well predicted probabilities match actual frequencies |
| **Perplexity** | LLM evaluation: how well it predicts a sample; lower = better |

---

## 5. Large Language Models (LLMs)

### Architecture Terms

| Term | Definition |
|------|------------|
| **Transformer** | Attention-based neural architecture (Vaswani et al. 2017) |
| **Attention** | Mechanism weighing token relevance to each other |
| **Self-Attention** | Each token attends to all tokens in same sequence |
| **Cross-Attention** | Decoder attends to encoder output |
| **Multi-Head Attention (MHA)** | Multiple attention heads run in parallel |
| **Grouped Query Attention (GQA)** | Fewer key-value heads than query heads — memory efficient |
| **Multi-Query Attention (MQA)** | Single shared key-value head |
| **Flash Attention** | Memory-efficient attention computation (GPU-optimized) |
| **Positional Encoding** | Adding position information to token embeddings |
| **RoPE** | Rotary Position Embedding — used in LLaMA, GPT-NeoX |
| **ALiBi** | Attention with Linear Biases — positional bias approach |
| **Token** | Subword unit of text (roughly 3/4 of a word on average) |
| **Tokenizer** | Converts text ↔ token IDs (BPE, WordPiece, SentencePiece) |
| **BPE** | Byte Pair Encoding — common tokenization algorithm |
| **Vocabulary** | Set of all tokens a model knows |
| **Embedding** | Dense vector representation of a token or sentence |
| **Context Window** | Maximum tokens the model can process at once |
| **Context Length** | Number of tokens in the current input |
| **Parameters** | Learned weights in a model (e.g., 70B = 70 billion) |
| **Weights** | Numerical values of model parameters |
| **Layers** | Stacked Transformer blocks in a model |
| **Hidden Size** | Dimension of internal representations |
| **FFN Size** | Feed-forward layer dimension (typically 4× hidden size) |
| **Heads** | Number of attention heads per layer |

### Inference & Generation

| Term | Definition |
|------|------------|
| **Prompt** | Input text provided to an LLM |
| **Completion** | LLM's generated output |
| **System Prompt** | Instructions defining LLM behavior/persona |
| **User Message** | Human turn in a conversation |
| **Assistant Message** | LLM response turn |
| **Temperature** | Controls output randomness (0=deterministic, 2=very random) |
| **Top-p (nucleus sampling)** | Sample from smallest token set summing to probability p |
| **Top-k** | Sample from k most probable next tokens |
| **Greedy Decoding** | Always pick highest probability token |
| **Beam Search** | Track multiple candidate sequences during generation |
| **Max Tokens** | Maximum tokens to generate in a response |
| **Stop Sequences** | Strings that halt generation |
| **Logits** | Raw unnormalized scores before softmax |
| **Softmax** | Converts logits to probabilities |
| **Streaming** | Returning tokens one-by-one as generated |
| **Batching** | Processing multiple requests simultaneously |
| **Quantization** | Reducing model precision (INT8, INT4) to shrink size/speed up |
| **GGUF/GGML** | Quantized model format for CPU inference |
| **vLLM** | High-throughput LLM inference engine with PagedAttention |
| **PagedAttention** | vLLM's memory management for KV cache |
| **Speculative Decoding** | Use small model to draft tokens, large model verifies |

### Fine-tuning

| Term | Definition |
|------|------------|
| **Full Fine-tuning** | Update all model weights on new data |
| **PEFT** | Parameter-Efficient Fine-Tuning — update few parameters |
| **LoRA** | Low-Rank Adaptation — add small trainable rank matrices |
| **QLoRA** | Quantized LoRA — LoRA on quantized (4-bit) base model |
| **Adapter** | Small bottleneck modules inserted into frozen layers |
| **Instruction Tuning** | Fine-tune on instruction→response pairs |
| **Chat Tuning** | Fine-tune on multi-turn dialogue data |
| **DPO** | Direct Preference Optimization — alignment without PPO |
| **SFT** | Supervised Fine-Tuning — standard fine-tune on labeled examples |
| **ORPO** | Odds Ratio Preference Optimization — alignment technique |
| **Unsloth** | Fast LoRA fine-tuning library (2× speedup) |
| **TRL** | Transformer Reinforcement Learning library (HuggingFace) |
| **bitsandbytes** | Library for 4-bit/8-bit quantization |
| **accelerate** | HuggingFace library for multi-GPU/TPU training |
| **DeepSpeed** | Microsoft library for large-model training optimization |
| **FSDP** | Fully Sharded Data Parallel — PyTorch distributed training |

### Prompt Engineering

| Term | Definition |
|------|------------|
| **Prompt Engineering** | Crafting inputs to get optimal LLM outputs |
| **Zero-shot Prompting** | Task with no examples |
| **Few-shot Prompting** | Task with 2-5 examples in prompt |
| **Chain-of-Thought (CoT)** | "Think step by step" prompting for reasoning |
| **Self-Consistency** | Sample multiple CoT paths and take majority answer |
| **Tree of Thought (ToT)** | Explore multiple reasoning branches like a tree |
| **ReAct** | Reason + Act — alternating thinking and tool use |
| **Structured Output** | Constraining LLM to output valid JSON/XML |
| **System Prompt Injection** | Manipulating LLM via malicious input |
| **Hallucination** | LLM confidently generates false information |
| **Grounding** | Connecting LLM responses to verified sources |
| **Context Stuffing** | Putting relevant docs into prompt context (simple RAG) |

---

## 6. Agentic AI & Orchestration

| Term | Definition |
|------|------------|
| **Agent** | LLM system that can reason, plan, and use tools autonomously |
| **Tool** | Function/API an agent can call (search, calculator, code executor) |
| **Tool Calling / Function Calling** | LLM outputs structured call to a named function |
| **ReAct Agent** | Reason-Act loop: think → call tool → observe → repeat |
| **Plan-and-Execute** | Agent creates multi-step plan then executes each step |
| **Orchestrator** | Component coordinating multiple agents |
| **Sub-agent** | Specialized agent called by orchestrator |
| **Multi-agent System** | Multiple cooperating agents with different roles |
| **Memory** | Agent's ability to remember past interactions |
| **Short-term Memory** | In-context memory (conversation history) |
| **Long-term Memory** | Persistent memory stored in a vector DB |
| **Working Memory** | Scratchpad for current task reasoning |
| **Graph** | Computation graph of nodes (LLMs/tools) and edges (flow) |
| **Node** | A step in LangGraph — an LLM call, tool, or function |
| **Edge** | Connection between nodes in a graph |
| **Conditional Edge** | Edge that routes to different nodes based on state |
| **State** | Shared data passed through a LangGraph graph |
| **Checkpointer** | LangGraph component that saves/loads graph state |
| **Human-in-the-loop** | Pausing agent to get human approval before proceeding |
| **Interrupt** | LangGraph mechanism to pause and await human input |
| **Supervisor** | Agent that delegates tasks to worker agents |
| **A2A Protocol** | Agent-to-Agent communication protocol |
| **MCP** | Model Context Protocol — standardized tool/context interface |
| **MCP Server** | Service exposing tools via Model Context Protocol |
| **Semantic Kernel** | Microsoft's agent orchestration framework |
| **AutoGen** | Microsoft's multi-agent conversation framework |
| **CrewAI** | Role-based multi-agent framework |
| **DSPy** | Stanford's programmatic LLM framework (Demonstrate-Search-Predict) |
| **Haystack** | NLP/LLM pipeline framework by deepset |
| **LlamaIndex** | Data framework for LLM apps (formerly GPT Index) |
| **LangChain** | LLM application development framework |
| **LangGraph** | Graph-based stateful agent framework (by LangChain) |
| **LangSmith** | LLM observability, tracing, and evaluation platform |
| **Runnable** | LangChain abstraction — any chainable component |
| **LCEL** | LangChain Expression Language — `prompt | llm | parser` chain syntax |
| **Chain** | Sequence of LangChain components |
| **Retriever** | Component fetching relevant documents for RAG |
| **DocumentLoader** | LangChain component loading docs (PDF, web, DB) |
| **TextSplitter** | Splits documents into chunks for embedding |

---

## 7. Generative AI Terms

| Term | Definition |
|------|------------|
| **Generative AI** | AI that creates new content: text, images, audio, video, code |
| **Diffusion Model** | Generative model learning to denoise (Stable Diffusion, DALL-E) |
| **Forward Diffusion** | Gradually adding noise to training images |
| **Reverse Diffusion** | Denoising process to generate images from noise |
| **Denoising Score Matching** | Training objective for diffusion models |
| **DDPM** | Denoising Diffusion Probabilistic Models |
| **DDIM** | Denoising Diffusion Implicit Models — faster sampling |
| **CFG** | Classifier-Free Guidance — controls adherence to prompt |
| **Guidance Scale** | CFG strength (7.5 = balanced, higher = more prompt-adherent) |
| **Latent Diffusion** | Diffusion in compressed latent space (Stable Diffusion) |
| **VAE Encoder/Decoder** | Compresses images to/from latent space in SD |
| **UNet** | Backbone of diffusion models |
| **Scheduler** | Controls noise schedule in diffusion (DDIM, DPM++, etc.) |
| **ControlNet** | Adds spatial conditioning to diffusion (edges, pose, depth) |
| **LoRA (for images)** | Small fine-tuned weights for a specific style/subject |
| **Inpainting** | Regenerating masked regions of an image |
| **Outpainting** | Extending an image beyond its borders |
| **img2img** | Generate new image conditioned on input image |
| **Multimodal** | Models handling multiple modalities (text+image+audio) |
| **CLIP** | Contrastive Language-Image Pre-training — joint text+image embedding |
| **Whisper** | OpenAI's speech recognition model |
| **Structured Output** | LLM constrained to output valid schema (JSON, Pydantic) |
| **Instructor** | Library enforcing structured LLM outputs via Pydantic |
| **Outlines** | Library for constrained LLM generation |
| **Guardrails** | Input/output validation for LLM safety |
| **LiteLLM** | Unified interface to 100+ LLM APIs |
| **Ollama** | Local LLM runner with REST API |
| **Evaluation** | Measuring LLM quality (RAGAS, DeepEval, LangSmith) |
| **RAGAS** | RAG evaluation framework (faithfulness, relevance, recall) |
| **DeepEval** | LLM testing framework |
| **Faithfulness** | Is the answer supported by retrieved context? |
| **Relevance** | Is the answer relevant to the question? |
| **Groundedness** | Is the answer grounded in factual sources? |

---

## 8. Deep Learning Terms

| Term | Definition |
|------|------------|
| **Neural Network** | Layers of interconnected nodes (neurons) |
| **Neuron / Node** | Basic unit computing weighted sum + activation |
| **Activation Function** | Non-linearity: ReLU, GELU, Sigmoid, Tanh, SiLU |
| **ReLU** | max(0, x) — most common activation function |
| **GELU** | Gaussian Error Linear Unit — used in Transformers |
| **SiLU / Swish** | Sigmoid-weighted linear unit — used in LLaMA |
| **Softmax** | Normalizes outputs to probability distribution |
| **Cross-Entropy Loss** | Classification loss: -Σ y·log(ŷ) |
| **BCE Loss** | Binary Cross-Entropy — binary classification |
| **MSE Loss** | Mean Squared Error — regression |
| **Huber Loss** | Robust regression loss combining MSE and MAE |
| **Batch Normalization** | Normalizes layer inputs per batch |
| **Layer Normalization** | Normalizes across features (used in Transformers) |
| **Residual Connection** | Skip connection: output = F(x) + x |
| **Skip Connection** | See Residual Connection |
| **ResNet** | Deep CNN with residual connections (image classification) |
| **VGG** | Deep CNN architecture (Oxford) |
| **EfficientNet** | Scalable CNN balancing depth/width/resolution |
| **MobileNet** | Lightweight CNN for mobile devices |
| **Inception / GoogLeNet** | Multi-scale CNN architecture |
| **U-Net** | Encoder-decoder for image segmentation |
| **Encoder** | Network compressing input to latent representation |
| **Decoder** | Network reconstructing output from latent representation |
| **Latent Space** | Compressed representation learned by encoder |
| **Embedding Layer** | Maps discrete tokens to dense vectors |
| **Pooling** | Downsampling spatial dimensions (max, average, global) |
| **Flatten** | Converts multi-dim tensor to 1D vector |
| **Dense / Linear Layer** | Fully connected layer: y = Wx + b |
| **Convolution** | Local weighted sum over spatial region |
| **Depthwise Separable Conv** | Efficient convolution (MobileNet) |
| **Stride** | Step size of convolution filter |
| **Padding** | Adding zeros around input borders |
| **Kernel / Filter** | Convolution weight matrix |
| **Feature Map** | Output of a convolutional layer |
| **Transfer Learning** | Using pre-trained weights as starting point |
| **Frozen Layers** | Layers with weights fixed during fine-tuning |
| **Warm Start** | Initialize training from saved checkpoint |
| **Gradient Tape** | TensorFlow's automatic differentiation mechanism |
| **autograd** | PyTorch automatic differentiation |
| **Mixed Precision** | Training with float16 + float32 (faster, less memory) |
| **Gradient Accumulation** | Accumulate gradients over steps before updating (simulate large batch) |
| **Model Pruning** | Removing unnecessary weights to compress model |
| **Knowledge Distillation** | Training small student model to mimic large teacher |
| **Quantization** | Reducing weight precision (float32→int8) |
| **FastAI** | High-level PyTorch API for rapid deep learning |
| **Keras** | High-level TensorFlow neural network API |
| **PyTorch Lightning** | Structured PyTorch training framework |
| **Hugging Face** | Platform + libraries for transformers, datasets, spaces |
| **ONNX Runtime** | Cross-platform model inference engine |

---

## 9. Computer Vision Terms

| Term | Definition |
|------|------------|
| **Image Classification** | Assign a label to an entire image |
| **Object Detection** | Locate and classify objects with bounding boxes |
| **Semantic Segmentation** | Classify each pixel of an image |
| **Instance Segmentation** | Segmentation for each object instance separately |
| **Panoptic Segmentation** | Combines semantic + instance segmentation |
| **Pose Estimation** | Detecting body keypoints/joints |
| **Depth Estimation** | Predicting per-pixel depth from a single image |
| **Optical Flow** | Per-pixel motion between video frames |
| **Face Detection** | Locating faces in images |
| **Face Recognition** | Identifying who a face belongs to |
| **OCR** | Extracting text from images |
| **Bounding Box** | Rectangle around detected object [x, y, width, height] |
| **Anchor Box** | Prior bounding box shape for detection |
| **IoU** | Intersection over Union — bounding box overlap metric |
| **NMS** | Non-Maximum Suppression — removes duplicate detections |
| **Confidence Score** | Detection certainty (0.0–1.0) |
| **Class Score** | Per-class probability from a classifier |
| **YOLO** | You Only Look Once — real-time object detection family |
| **YOLOv8** | Ultralytics YOLO v8 — state-of-the-art detection/segmentation |
| **SAM** | Segment Anything Model (Meta) — zero-shot segmentation |
| **DINO** | Self-supervised vision transformer (Meta) |
| **CLIP** | Contrastive Language-Image Pre-training (OpenAI) |
| **OpenCV** | Open Source Computer Vision Library |
| **Haar Cascade** | Classical object detector (face detection) |
| **HOG** | Histogram of Oriented Gradients — feature descriptor |
| **SIFT** | Scale-Invariant Feature Transform — keypoint detector |
| **ORB** | Oriented FAST and Rotated BRIEF — fast keypoint detector |
| **MediaPipe** | Google's ML pipeline for real-time perception |
| **Augmented Reality (AR)** | Overlaying digital content on real world |
| **Pixel** | Smallest element of a digital image |
| **Grayscale** | Single-channel image (0–255) |
| **RGB** | Red-Green-Blue — 3-channel color image |
| **RGBA** | RGB + Alpha (transparency) channel |
| **BGR** | Blue-Green-Red — OpenCV's default channel order |
| **Normalization** | Scaling pixel values to [0,1] or [-1,1] |
| **Resize / Crop** | Image preprocessing transformations |
| **Data Augmentation** | Random flips, rotations, color jitter for training |
| **PixelLib** | Python library for image segmentation |
| **torchvision** | PyTorch library for CV — datasets, transforms, models |
| **Albumentations** | Fast image augmentation library |
| **Pillow (PIL)** | Python Imaging Library — basic image operations |

---

## 10. NLP Terms

| Term | Definition |
|------|------------|
| **Tokenization** | Splitting text into tokens (words, subwords, characters) |
| **Stemming** | Reducing words to their root (running→run) |
| **Lemmatization** | Reducing words to dictionary form (better→good) |
| **Stop Words** | Common words filtered out (the, is, and) |
| **n-gram** | Sequence of n consecutive tokens |
| **TF-IDF** | Term Frequency × Inverse Document Frequency — text importance weight |
| **Word Embedding** | Dense vector representation of a word (Word2Vec, GloVe) |
| **Word2Vec** | Shallow neural network learning word embeddings |
| **GloVe** | Global Vectors — co-occurrence-based word embeddings |
| **FastText** | Facebook's word embedding with subword characters |
| **Sentence Embedding** | Single vector representing whole sentence meaning |
| **Sentence-BERT (SBERT)** | Sentence Transformers using BERT pooling |
| **Cosine Similarity** | Angle-based similarity between vectors (0=different, 1=same) |
| **Semantic Similarity** | Meaning-based closeness between texts |
| **Named Entity Recognition (NER)** | Tag people, places, organizations in text |
| **POS Tagging** | Assign grammatical roles to words |
| **Dependency Parsing** | Analyze grammatical structure of sentences |
| **Coreference Resolution** | Link pronouns to their referents |
| **Sentiment Analysis** | Classify text as positive/negative/neutral |
| **Text Classification** | Assign categories to text documents |
| **Text Generation** | Model producing new text |
| **Text Summarization** | Condensing a document to key points |
| **Extractive Summarization** | Pick and arrange existing sentences |
| **Abstractive Summarization** | Generate new sentences capturing meaning |
| **Machine Translation** | Automated language translation |
| **Question Answering** | Find/generate answers to questions from text |
| **Reading Comprehension** | Answer questions based on given passage |
| **Open-Domain QA** | Answer questions without given context (uses retrieval) |
| **Span Extraction** | Identify answer as a span in source text |
| **Cloze Task** | Fill in the blank in a sentence |
| **Topic Modeling** | Discover abstract topics in a corpus |
| **LDA** | Latent Dirichlet Allocation — probabilistic topic model |
| **BERTopic** | BERT-based topic modeling |
| **spaCy** | Industrial-strength NLP library |
| **NLTK** | Natural Language Toolkit — classic NLP library |
| **Hugging Face Transformers** | Library with 100k+ pre-trained models |
| **Datasets (HF)** | HuggingFace library with 50k+ datasets |
| **Whisper** | OpenAI's multilingual speech recognition model |
| **Wav2Vec** | Facebook's speech representation model |
| **SpeechBrain** | Speech processing toolkit |
| **ROUGE** | Recall-Oriented metric for summarization evaluation |
| **BLEU** | Precision-based metric for translation evaluation |
| **BERTScore** | Semantic similarity metric using BERT embeddings |

---

## 11. Data Science Terms

### Statistics & Probability

| Term | Definition |
|------|------------|
| **Descriptive Statistics** | Summarizing data (mean, median, std, percentiles) |
| **Inferential Statistics** | Drawing conclusions about population from sample |
| **Hypothesis Testing** | Statistical test to accept/reject a null hypothesis |
| **p-value** | Probability of observing results if null hypothesis is true |
| **Significance Level (α)** | Threshold for rejecting null (typically 0.05) |
| **Confidence Interval** | Range likely containing true population parameter |
| **A/B Testing** | Comparing two variants with statistical significance |
| **Central Limit Theorem** | Sample means approach normal distribution as n→∞ |
| **Normal Distribution** | Bell-shaped distribution (Gaussian) |
| **Skewness** | Asymmetry of a distribution |
| **Kurtosis** | Tail heaviness of a distribution |
| **Correlation** | Linear relationship between two variables (-1 to 1) |
| **Covariance** | How much two variables change together |
| **Causation vs Correlation** | Correlation ≠ causation |
| **Causal Inference** | Estimating causal effects from observational data |
| **Bayesian Inference** | Updating beliefs with evidence using Bayes' theorem |
| **Prior / Posterior** | Bayesian belief before/after observing data |
| **Likelihood** | Probability of data given model parameters |
| **MLE** | Maximum Likelihood Estimation |
| **MAP** | Maximum A Posteriori — MLE with prior |
| **Monte Carlo** | Numerical estimation using random sampling |
| **Bootstrap** | Resampling with replacement for variance estimation |

### Data Engineering

| Term | Definition |
|------|------------|
| **Data Pipeline** | Automated flow of data from source to destination |
| **ETL** | Extract-Transform-Load pipeline |
| **EDA** | Exploratory Data Analysis |
| **Feature Engineering** | Creating ML-ready features from raw data |
| **Feature Scaling** | Normalizing feature ranges (StandardScaler, MinMaxScaler) |
| **Imputation** | Filling missing values |
| **Encoding** | Converting categorical to numeric (One-hot, Label, Target) |
| **Outlier** | Data point far from others |
| **Data Leakage** | Accidentally using future/target data in features |
| **Train-Test Split** | Separating data for training and evaluation |
| **Stratification** | Maintaining class proportions when splitting |
| **Pandas** | Python library for tabular data manipulation |
| **NumPy** | Python library for numerical array operations |
| **Polars** | Fast DataFrame library (Rust-based, replaces Pandas) |
| **Dask** | Parallel Pandas for datasets larger than RAM |
| **Vaex** | Out-of-core DataFrame for billion-row datasets |
| **Arrow** | Columnar in-memory format (Apache) |
| **Parquet** | Columnar storage format (fast analytics) |
| **DVC** | Data Version Control — git for datasets |
| **Great Expectations** | Data quality validation framework |
| **Profiling** | Automated EDA report (ydata-profiling, D-Tale) |
| **Plotly Dash** | Python framework for interactive web dashboards |
| **Streamlit** | Turn Python scripts into web apps instantly |
| **Prophet** | Facebook's time series forecasting library |
| **ARIMA** | AutoRegressive Integrated Moving Average — time series model |
| **Folium** | Python library for interactive maps (Leaflet.js) |
| **Causal Inference** | Determining cause-effect from observational data |
| **Differential Privacy** | Mathematical privacy guarantee for data analysis |

---

## 12. Vector Databases & Embeddings

| Term | Definition |
|------|------------|
| **Embedding** | Dense vector representing text/image semantic meaning |
| **Vector** | Array of floating-point numbers representing a data point |
| **Embedding Model** | Model converting text→vector (text-embedding-3-small, nomic-embed) |
| **Dimensions** | Length of an embedding vector (e.g., 1536, 768, 384) |
| **Cosine Similarity** | Similarity via angle between vectors |
| **Dot Product** | Similarity via vector multiplication |
| **Euclidean Distance** | L2 distance between two vectors |
| **ANN** | Approximate Nearest Neighbor search |
| **HNSW** | Hierarchical Navigable Small World — fast ANN index |
| **IVF** | Inverted File Index — partitioned vector search |
| **PQ** | Product Quantization — compressed vector storage |
| **FAISS** | Facebook AI Similarity Search — open-source vector library |
| **Vector Store** | Database optimized for storing and searching embeddings |
| **ChromaDB** | Embedded open-source vector database |
| **Pinecone** | Managed cloud vector database |
| **Qdrant** | Open-source vector database with filtering |
| **Weaviate** | Open-source vector DB with GraphQL API |
| **Milvus** | Open-source vector DB for enterprise scale |
| **pgvector** | PostgreSQL extension for vector search |
| **Redis Vector** | Redis with vector similarity search |
| **Chunk** | Text segment created by splitting a document |
| **Chunking Strategy** | How to split documents (fixed, recursive, semantic) |
| **Chunk Size** | Number of characters/tokens per chunk |
| **Chunk Overlap** | Shared characters between adjacent chunks |
| **Sparse Vector** | High-dimensional vector with mostly zeros (BM25, SPLADE) |
| **Dense Vector** | Low-dimensional continuous vector (neural embeddings) |
| **Hybrid Search** | Combining dense (semantic) + sparse (keyword) search |
| **Reranking** | Second-pass sorting of retrieved results for relevance |
| **Cross-Encoder** | Reranking model scoring query+document pair together |
| **Bi-Encoder** | Encodes query and document separately (faster retrieval) |
| **RAG Pipeline** | Retrieve relevant chunks → augment prompt → generate answer |
| **Advanced RAG** | RAG with reranking, HyDE, multi-hop, query expansion |
| **HyDE** | Hypothetical Document Embeddings — generate fake answer to query for retrieval |
| **Multi-hop RAG** | RAG requiring multiple retrieval steps to answer |
| **Self-RAG** | Model decides when and what to retrieve |
| **RAPTOR** | Recursive Abstractive Processing for Tree-Organized RAG |
| **Namespace** | Logical partition within a vector index (Pinecone) |
| **Collection** | Group of vectors in ChromaDB/Qdrant/Milvus |
| **Index** | Data structure for fast vector lookup |
| **Metadata Filtering** | Filter vectors by attached metadata before search |
| **Payload** | Metadata stored alongside vectors in Qdrant |

---

## 13. MLOps & Deployment Terms

| Term | Definition |
|------|------------|
| **MLOps** | Practices combining ML development and operations |
| **Model Registry** | Versioned store of trained models (MLflow, W&B) |
| **Experiment Tracking** | Logging parameters, metrics, artifacts per run |
| **Run** | Single training/evaluation execution |
| **Artifact** | File output of an ML run (model, dataset, plot) |
| **Pipeline** | Sequence of reproducible ML steps |
| **Feature Store** | Centralized repository for ML features (Feast) |
| **Data Drift** | Distribution of input data changes over time |
| **Concept Drift** | Relationship between input and output changes |
| **Model Monitoring** | Watching model performance in production |
| **Shadow Mode** | New model runs alongside old without affecting users |
| **Canary Deployment** | Route small % of traffic to new model version |
| **Blue-Green Deployment** | Switch traffic between two identical environments |
| **Rolling Update** | Gradually replace old model instances |
| **A/B Testing** | Statistical comparison of two model versions |
| **Endpoint** | Deployed model's API URL |
| **Inference** | Using a trained model to make predictions |
| **Batch Inference** | Predictions on large dataset at once |
| **Online Inference** | Real-time predictions on individual requests |
| **Latency** | Time to get a response from a model |
| **Throughput** | Requests/predictions per second |
| **Model Serving** | Exposing a model via API (BentoML, Triton, TorchServe) |
| **BentoML** | Python model serving framework |
| **Triton** | NVIDIA Triton Inference Server |
| **TorchServe** | PyTorch model serving |
| **Seldon Core** | Kubernetes-native model serving |
| **Docker** | Container platform for packaging applications |
| **Kubernetes (K8s)** | Container orchestration platform |
| **Helm** | Kubernetes package manager |
| **Kubeflow** | Kubernetes-native ML pipeline platform |
| **MLflow** | Open-source ML lifecycle platform |
| **Weights & Biases** | ML experiment tracking and visualization |
| **DVC** | Data Version Control — git for data and models |
| **Evidently AI** | ML model monitoring framework |
| **Prefect** | Modern Python workflow orchestration |
| **Apache Airflow** | DAG-based workflow scheduler |
| **GitHub Actions** | CI/CD automation via GitHub |
| **Terraform** | Infrastructure as Code tool |
| **Feast** | Open-source feature store |
| **DAG** | Directed Acyclic Graph — workflow structure |

---

## 14. Cloud & Infrastructure Terms

### AWS

| Term | Definition |
|------|------------|
| **EC2** | Elastic Compute Cloud — virtual machines |
| **S3** | Simple Storage Service — object storage |
| **Lambda** | Serverless function execution |
| **SageMaker** | Managed ML platform |
| **Bedrock** | Managed LLM API (Claude, Titan, Llama) |
| **ECS** | Elastic Container Service |
| **EKS** | Elastic Kubernetes Service |
| **RDS** | Relational Database Service |
| **DynamoDB** | Managed NoSQL database |
| **Kinesis** | Real-time data streaming |
| **Glue** | Serverless ETL service |
| **Athena** | Serverless SQL query on S3 |
| **Step Functions** | Serverless workflow orchestration |
| **CloudWatch** | Monitoring and logging service |
| **IAM** | Identity and Access Management |
| **VPC** | Virtual Private Cloud |
| **Beanstalk** | PaaS for web app deployment |
| **ECR** | Elastic Container Registry — Docker image store |
| **boto3** | AWS Python SDK |
| **awscli** | AWS Command Line Interface |

### Google Cloud

| Term | Definition |
|------|------------|
| **GCS** | Google Cloud Storage |
| **Compute Engine** | Virtual machines |
| **Cloud Run** | Serverless container execution |
| **Cloud Functions** | Serverless functions |
| **GKE** | Google Kubernetes Engine |
| **BigQuery** | Serverless data warehouse |
| **Vertex AI** | Managed ML platform |
| **Gemini API** | Google's LLM API |
| **AI Studio** | Google's Gemini prototyping interface |
| **Pub/Sub** | Message queue service |
| **Dataflow** | Apache Beam managed streaming/batch |
| **Cloud SQL** | Managed relational database |
| **Firestore** | Managed NoSQL document database |

### Azure

| Term | Definition |
|------|------------|
| **Azure ML** | Managed ML platform |
| **Azure OpenAI** | OpenAI models hosted on Azure |
| **Azure Blob Storage** | Object storage |
| **App Service** | PaaS for web apps |
| **Azure Functions** | Serverless functions |
| **AKS** | Azure Kubernetes Service |
| **Cosmos DB** | Multi-model NoSQL database |
| **Azure Cognitive Services** | Pre-built AI APIs |

### Infrastructure

| Term | Definition |
|------|------------|
| **Container** | Lightweight isolated process with its own filesystem |
| **Image** | Blueprint for creating containers |
| **Registry** | Container image repository (Docker Hub, ECR, GCR) |
| **Pod** | Kubernetes smallest deployable unit (1+ containers) |
| **Node** | Machine in a Kubernetes cluster |
| **Cluster** | Group of nodes managed by Kubernetes |
| **Namespace (K8s)** | Logical partition in Kubernetes cluster |
| **Service (K8s)** | Network endpoint exposing pods |
| **Ingress** | HTTP routing for Kubernetes services |
| **ConfigMap** | Kubernetes non-secret configuration |
| **Secret** | Kubernetes encrypted configuration |
| **PVC** | PersistentVolumeClaim — storage request in Kubernetes |
| **HPA** | Horizontal Pod Autoscaler — scale based on CPU/memory |
| **Load Balancer** | Distributes traffic across multiple instances |
| **Reverse Proxy** | Nginx/Traefik routing traffic to services |

---

## 15. Database Terms

### SQL / Relational

| Term | Definition |
|------|------------|
| **Schema** | Database structure definition |
| **Table** | Collection of rows and columns |
| **Row / Record** | Single data entry |
| **Column / Field** | Attribute of a record |
| **Primary Key** | Unique identifier for a row |
| **Foreign Key** | Reference to primary key in another table |
| **Index** | Data structure for fast lookups |
| **Join** | Combining rows from multiple tables |
| **INNER JOIN** | Returns rows matching in both tables |
| **LEFT JOIN** | All left rows + matching right rows |
| **Aggregate** | GROUP BY + COUNT, SUM, AVG, MIN, MAX |
| **Transaction** | Group of operations executed atomically |
| **ACID** | Atomicity, Consistency, Isolation, Durability |
| **Migration** | Versioned schema change |
| **ORM** | Object-Relational Mapper (SQLAlchemy, Django ORM) |
| **SQLAlchemy** | Python SQL toolkit and ORM |
| **psycopg2** | PostgreSQL adapter for Python |
| **pymysql** | MySQL adapter for Python |
| **pgvector** | PostgreSQL extension adding vector similarity search |

### NoSQL

| Term | Definition |
|------|------------|
| **Document DB** | Store JSON-like documents (MongoDB, Firestore) |
| **Key-Value Store** | Simple key→value storage (Redis, DynamoDB) |
| **Column-Family** | Wide-column storage (Cassandra, HBase) |
| **Graph DB** | Nodes and edges storage (Neo4j) |
| **Collection** | MongoDB equivalent of a table |
| **Document** | MongoDB equivalent of a row |
| **Pipeline** | MongoDB aggregation pipeline |
| **Index (MongoDB)** | B-tree or text index on a field |
| **Sharding** | Horizontal database partitioning |
| **Replication** | Copies of data across multiple nodes |
| **Replica Set** | MongoDB high-availability cluster |
| **PyMongo** | Official MongoDB Python driver |
| **Motor** | Async MongoDB driver for Python |

### Cache & Message Queue

| Term | Definition |
|------|------------|
| **Cache** | Fast temporary data store |
| **TTL** | Time-To-Live — cache expiry duration |
| **Cache Hit/Miss** | Found/not-found in cache |
| **Redis** | In-memory key-value store (cache, sessions, pub/sub) |
| **Redis Streams** | Redis data structure for event streaming |
| **Pub/Sub** | Publish-Subscribe messaging pattern |
| **Message Queue** | Asynchronous message passing system |
| **Kafka** | Distributed event streaming platform |
| **Topic (Kafka)** | Named stream of messages |
| **Consumer Group** | Group of Kafka consumers sharing partitions |
| **Offset** | Position of a message in a Kafka partition |
| **Celery** | Distributed Python task queue |
| **RabbitMQ** | Message broker implementing AMQP |

### Search

| Term | Definition |
|------|------------|
| **Elasticsearch** | Distributed full-text search engine |
| **Index (ES)** | Elasticsearch collection of documents |
| **Mapping** | Field type definition in Elasticsearch |
| **Analyzer** | Text processing pipeline (tokenizer + filters) |
| **Inverted Index** | Data structure mapping terms to documents |
| **Full-Text Search** | Searching across document text content |
| **Fuzzy Search** | Finding approximate matches |
| **Relevance Score** | How well a document matches a query |
| **BM25** | Best-Match ranking algorithm used by Elasticsearch |

---

## 16. Big Data Terms

| Term | Definition |
|------|------------|
| **Big Data** | Data too large for single-machine processing |
| **3 Vs** | Volume, Velocity, Variety — characteristics of big data |
| **Apache Spark** | Distributed in-memory data processing |
| **PySpark** | Python API for Apache Spark |
| **RDD** | Resilient Distributed Dataset — Spark's core data structure |
| **DataFrame (Spark)** | Typed distributed table (like Pandas but distributed) |
| **SparkSQL** | SQL interface for Spark DataFrames |
| **Partition** | Data split across nodes for parallel processing |
| **Shuffle** | Data redistribution across partitions (expensive) |
| **Lazy Evaluation** | Spark defers computation until an action is called |
| **Transformation** | Spark operation creating a new RDD/DF (lazy) |
| **Action** | Spark operation triggering computation (collect, count) |
| **Apache Kafka** | Distributed event streaming platform |
| **Apache Flink** | Stream and batch processing (lower latency than Spark) |
| **Apache Airflow** | Workflow scheduler with DAG-based pipelines |
| **Apache Hive** | SQL-on-Hadoop data warehouse |
| **HDFS** | Hadoop Distributed File System |
| **Data Lake** | Centralized raw data repository (any format) |
| **Data Warehouse** | Structured, processed analytics storage |
| **Data Lakehouse** | Combines lake flexibility with warehouse structure |
| **Delta Lake** | ACID transactions on data lakes (Databricks) |
| **Iceberg** | Table format for huge analytic tables |
| **Databricks** | Managed Spark + lakehouse platform |
| **Dask** | Parallel Python analytics (Pandas-compatible API) |
| **Ray** | Distributed Python compute framework for ML |
| **Polars** | Fast DataFrame library written in Rust |
| **Vaex** | Out-of-core DataFrame (billion rows on laptop) |
| **cuDF** | GPU-accelerated DataFrame (RAPIDS, NVIDIA) |
| **Great Expectations** | Data quality validation framework |
| **Data Quality** | Accuracy, completeness, consistency of data |
| **Schema Evolution** | Changing data schema without breaking consumers |
| **Medallion Architecture** | Bronze (raw) → Silver (cleaned) → Gold (aggregated) |
| **Streaming** | Processing data as it arrives (real-time) |
| **Batch** | Processing data at scheduled intervals |
| **Micro-batch** | Small, frequent batch processing (Spark Streaming) |
| **Watermark** | Threshold for late-arriving event data in streaming |
| **Windowing** | Grouping streaming events by time (tumbling, sliding, session) |

---

## 17. Web Framework Terms

### FastAPI

| Term | Definition |
|------|------------|
| **FastAPI** | Modern async Python web framework (built on Starlette + Pydantic) |
| **ASGI** | Async Server Gateway Interface — FastAPI's server protocol |
| **Uvicorn** | Lightweight ASGI server for FastAPI |
| **Gunicorn** | WSGI server (used with uvicorn workers in production) |
| **Route** | URL path mapped to a function (`@app.get("/")`) |
| **Path Parameter** | Variable in URL path `/items/{item_id}` |
| **Query Parameter** | URL query string `?limit=10` |
| **Request Body** | JSON data sent in POST/PUT requests |
| **Pydantic Model** | Request/response schema with automatic validation |
| **Dependency Injection** | FastAPI's `Depends()` — shared logic across routes |
| **Middleware** | Function running before/after every request |
| **Background Tasks** | FastAPI tasks running after response is sent |
| **WebSocket** | Full-duplex real-time communication |
| **OpenAPI / Swagger** | Auto-generated API docs at `/docs` |
| **Redoc** | Alternative API docs at `/redoc` |

### Flask

| Term | Definition |
|------|------------|
| **Flask** | Lightweight Python WSGI web framework |
| **Blueprint** | Modular Flask application component |
| **Jinja2** | Python templating engine (Flask default) |
| **Werkzeug** | Flask's underlying WSGI utility library |
| **Flask-SQLAlchemy** | SQLAlchemy integration for Flask |
| **Flask-Migrate** | Database migration for Flask |
| **Flask-Login** | User session management |
| **Flask-CORS** | Cross-Origin Resource Sharing for Flask |
| **SocketIO** | Real-time WebSocket support for Flask |

### Django

| Term | Definition |
|------|------------|
| **Django** | Full-stack Python web framework |
| **ORM** | Django's built-in Object-Relational Mapper |
| **Migration** | Versioned database schema change |
| **Admin** | Auto-generated Django admin interface |
| **View** | Django function/class handling a request |
| **URL Pattern** | Mapping URL to a view |
| **Template** | Django HTML template with `{% %}` tags |
| **Settings.py** | Django project configuration file |
| **manage.py** | Django command-line utility |
| **App** | Django modular component (models, views, urls) |

### UI Frameworks

| Term | Definition |
|------|------------|
| **Streamlit** | Turn Python scripts into interactive web apps |
| **Gradio** | Build ML demo UIs in Python |
| **Dash (Plotly)** | Analytical dashboard framework |
| **PyWebIO** | Build web UI with Python functions |
| **Panel** | Holoviz dashboard framework |
| **Bokeh** | Interactive visualization for browsers |

---

## 18. Blockchain Terms

| Term | Definition |
|------|------------|
| **Blockchain** | Immutable distributed ledger of transactions |
| **Block** | Container for a batch of transactions |
| **Chain** | Sequence of cryptographically linked blocks |
| **Hash** | Fixed-size digest of data (SHA-256, MD5) |
| **SHA-256** | 256-bit Secure Hash Algorithm — used in Bitcoin |
| **Genesis Block** | First block in a blockchain |
| **Node** | Participant in a blockchain network |
| **Consensus** | Agreement mechanism among nodes |
| **Proof of Work** | Consensus requiring computational effort (mining) |
| **Proof of Stake** | Consensus based on staked tokens |
| **Mining** | Computing PoW to add a block |
| **Wallet** | Stores cryptographic keys for transactions |
| **Public Key** | Shareable address for receiving funds |
| **Private Key** | Secret key for signing transactions |
| **Smart Contract** | Self-executing code on blockchain |
| **DApp** | Decentralized Application |
| **Merkle Tree** | Binary tree of hashes for efficient verification |
| **Nonce** | Number incremented to find valid PoW hash |
| **Immutability** | Cannot alter historical records |

---

## 19. Environment & Config Keywords

### `.env` File Keys

| Key | Description | Used By |
|-----|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key | openai, langchain-openai |
| `GROQ_API_KEY` | Groq LLM API key | groq, langchain-groq |
| `GOOGLE_API_KEY` | Google Gemini API key | google-generativeai |
| `ANTHROPIC_API_KEY` | Anthropic Claude key | anthropic, langchain-anthropic |
| `COHERE_API_KEY` | Cohere API key | cohere |
| `MISTRAL_API_KEY` | Mistral AI key | mistralai |
| `HUGGINGFACEHUB_API_TOKEN` | HuggingFace token | transformers, huggingface_hub |
| `HF_TOKEN` | Alias for HuggingFace token | huggingface_hub |
| `TAVILY_API_KEY` | Tavily search key | tavily-python |
| `SERPAPI_API_KEY` | SerpAPI key | google-search-results |
| `LANGCHAIN_API_KEY` | LangSmith key | langsmith |
| `LANGCHAIN_TRACING_V2` | Enable LangSmith tracing | langchain |
| `LANGCHAIN_PROJECT` | LangSmith project name | langchain |
| `LANGCHAIN_ENDPOINT` | LangSmith API endpoint | langchain |
| `PINECONE_API_KEY` | Pinecone key | pinecone-client |
| `QDRANT_URL` | Qdrant server URL | qdrant-client |
| `QDRANT_API_KEY` | Qdrant cloud key | qdrant-client |
| `WEAVIATE_URL` | Weaviate cluster URL | weaviate-client |
| `WEAVIATE_API_KEY` | Weaviate key | weaviate-client |
| `DATABASE_URL` | PostgreSQL connection string | sqlalchemy, psycopg2 |
| `MONGO_URI` | MongoDB connection string | pymongo |
| `REDIS_URL` | Redis connection string | redis |
| `NEO4J_URI` | Neo4j connection URI | neo4j |
| `AWS_ACCESS_KEY_ID` | AWS access key | boto3, awscli |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | boto3, awscli |
| `AWS_DEFAULT_REGION` | AWS region | boto3 |
| `GOOGLE_CLOUD_PROJECT` | GCP project ID | google-cloud |
| `WANDB_API_KEY` | Weights & Biases key | wandb |
| `MLFLOW_TRACKING_URI` | MLflow server URL | mlflow |
| `MODEL_NAME` | LLM model identifier | varies |
| `DEBUG` | Enable debug mode (`True`/`False`) | flask, fastapi |
| `SECRET_KEY` | Flask/Django session encryption key | flask, django |
| `ALLOWED_HOSTS` | Django allowed hostnames | django |

### pyproject.toml Keywords

| Key | Description |
|-----|-------------|
| `[project]` | Project metadata section |
| `name` | Package name |
| `version` | Package version |
| `dependencies` | Runtime dependencies list |
| `[project.optional-dependencies]` | Optional dependency groups |
| `[tool.uv]` | uv-specific configuration |
| `[tool.ruff]` | Ruff linter configuration |
| `[tool.mypy]` | Mypy type checker configuration |
| `[tool.pytest.ini_options]` | Pytest configuration |
| `[build-system]` | Build backend (setuptools, hatchling) |
| `requires-python` | Minimum Python version constraint |

---

## 20. Python Package Ecosystem

### Core ML / Data Science

| Package | Description | Install |
|---------|-------------|---------|
| `numpy` | N-dimensional arrays, math ops | `pip install numpy` |
| `pandas` | DataFrames and data manipulation | `pip install pandas` |
| `scikit-learn` | Classical ML algorithms | `pip install scikit-learn` |
| `scipy` | Scientific computing | `pip install scipy` |
| `statsmodels` | Statistical models and tests | `pip install statsmodels` |
| `matplotlib` | Static plotting | `pip install matplotlib` |
| `seaborn` | Statistical data visualization | `pip install seaborn` |
| `plotly` | Interactive plots | `pip install plotly` |
| `xgboost` | Extreme Gradient Boosting | `pip install xgboost` |
| `lightgbm` | Light Gradient Boosting | `pip install lightgbm` |
| `catboost` | Categorical Boosting | `pip install catboost` |
| `optuna` | Hyperparameter optimization | `pip install optuna` |
| `shap` | SHapley Additive exPlanations | `pip install shap` |
| `lime` | Local interpretable explanations | `pip install lime` |

### Deep Learning

| Package | Description | Install |
|---------|-------------|---------|
| `torch` | PyTorch deep learning framework | See pytorch.org |
| `torchvision` | CV transforms and models | See pytorch.org |
| `torchaudio` | Audio transforms | See pytorch.org |
| `tensorflow` | TensorFlow deep learning | `pip install tensorflow` |
| `keras` | High-level neural network API | `pip install keras` |
| `transformers` | HuggingFace models | `pip install transformers` |
| `datasets` | HuggingFace datasets | `pip install datasets` |
| `accelerate` | Multi-GPU/TPU training | `pip install accelerate` |
| `peft` | Parameter-efficient fine-tuning | `pip install peft` |
| `trl` | Transformer RL (RLHF, DPO, SFT) | `pip install trl` |
| `bitsandbytes` | Quantization (4-bit, 8-bit) | `pip install bitsandbytes` |
| `diffusers` | Diffusion models (Stable Diffusion) | `pip install diffusers` |
| `fastai` | High-level PyTorch API | `pip install fastai` |
| `onnx` | ONNX model format | `pip install onnx` |
| `onnxruntime` | ONNX inference engine | `pip install onnxruntime` |

### LLM / Agents

| Package | Description | Install |
|---------|-------------|---------|
| `openai` | OpenAI Python SDK | `pip install openai` |
| `anthropic` | Anthropic Claude SDK | `pip install anthropic` |
| `groq` | Groq Python SDK | `pip install groq` |
| `google-generativeai` | Google Gemini SDK | `pip install google-generativeai` |
| `cohere` | Cohere Python SDK | `pip install cohere` |
| `mistralai` | Mistral AI SDK | `pip install mistralai` |
| `langchain` | LLM application framework | `pip install langchain` |
| `langchain-core` | Core LangChain interfaces | `pip install langchain-core` |
| `langchain-community` | Community integrations | `pip install langchain-community` |
| `langchain-openai` | OpenAI + LangChain | `pip install langchain-openai` |
| `langchain-groq` | Groq + LangChain | `pip install langchain-groq` |
| `langchain-anthropic` | Claude + LangChain | `pip install langchain-anthropic` |
| `langchain-google-genai` | Gemini + LangChain | `pip install langchain-google-genai` |
| `langgraph` | Agent graph framework | `pip install langgraph` |
| `langsmith` | LLM tracing SDK | `pip install langsmith` |
| `llama-index` | LLM data framework | `pip install llama-index` |
| `haystack-ai` | NLP pipeline framework | `pip install haystack-ai` |
| `semantic-kernel` | Microsoft agent framework | `pip install semantic-kernel` |
| `crewai` | Multi-agent role framework | `pip install crewai` |
| `autogen` | Microsoft multi-agent | `pip install pyautogen` |
| `dspy-ai` | Stanford programmatic LLM | `pip install dspy-ai` |
| `litellm` | Universal LLM proxy | `pip install litellm` |
| `tavily-python` | Tavily search client | `pip install tavily-python` |
| `instructor` | Structured LLM outputs | `pip install instructor` |
| `outlines` | Constrained generation | `pip install outlines` |
| `guardrails-ai` | LLM safety validation | `pip install guardrails-ai` |

### NLP

| Package | Description | Install |
|---------|-------------|---------|
| `nltk` | Natural Language Toolkit | `pip install nltk` |
| `spacy` | Industrial NLP library | `pip install spacy` |
| `sentence-transformers` | Sentence/text embeddings | `pip install sentence-transformers` |
| `gensim` | Topic modeling, Word2Vec | `pip install gensim` |
| `textblob` | Simple NLP for beginners | `pip install textblob` |
| `bertopic` | BERT-based topic modeling | `pip install bertopic` |
| `texthero` | Text preprocessing library | `pip install texthero` |
| `textacy` | Advanced spaCy-based NLP | `pip install textacy` |
| `openai-whisper` | Speech recognition | `pip install openai-whisper` |
| `sacrebleu` | BLEU score calculation | `pip install sacrebleu` |
| `rouge-score` | ROUGE score calculation | `pip install rouge-score` |
| `PyPDF2` / `pypdf` | PDF text extraction | `pip install pypdf` |
| `pdfminer.six` | PDF parsing | `pip install pdfminer.six` |

### Computer Vision

| Package | Description | Install |
|---------|-------------|---------|
| `opencv-python` | OpenCV for Python | `pip install opencv-python` |
| `Pillow` | Python Imaging Library | `pip install Pillow` |
| `mediapipe` | Google ML perception pipeline | `pip install mediapipe` |
| `ultralytics` | YOLO v8/v9/v10/v11 | `pip install ultralytics` |
| `segment-anything` | Meta's SAM | `pip install segment-anything` |
| `albumentations` | Image augmentation | `pip install albumentations` |
| `pixellib` | Image segmentation library | `pip install pixellib` |
| `imageio` | Reading/writing images | `pip install imageio` |
| `scikit-image` | Image processing | `pip install scikit-image` |

### Vector Databases

| Package | Description | Install |
|---------|-------------|---------|
| `chromadb` | Embedded vector DB | `pip install chromadb` |
| `qdrant-client` | Qdrant Python client | `pip install qdrant-client` |
| `pinecone-client` | Pinecone client | `pip install pinecone-client` |
| `weaviate-client` | Weaviate client | `pip install weaviate-client` |
| `pymilvus` | Milvus client | `pip install pymilvus` |
| `faiss-cpu` | Facebook ANN search | `pip install faiss-cpu` |
| `pgvector` | pgvector Python adapter | `pip install pgvector` |

### Web & API

| Package | Description | Install |
|---------|-------------|---------|
| `fastapi` | Async Python web framework | `pip install fastapi` |
| `flask` | Micro web framework | `pip install flask` |
| `django` | Full-stack web framework | `pip install django` |
| `uvicorn` | ASGI server | `pip install uvicorn` |
| `gunicorn` | WSGI server | `pip install gunicorn` |
| `streamlit` | Data app framework | `pip install streamlit` |
| `gradio` | ML demo UI | `pip install gradio` |
| `httpx` | Async HTTP client | `pip install httpx` |
| `requests` | HTTP client | `pip install requests` |
| `aiohttp` | Async HTTP | `pip install aiohttp` |
| `pydantic` | Data validation via type hints | `pip install pydantic` |
| `python-dotenv` | Load `.env` files | `pip install python-dotenv` |
| `redis` | Redis Python client | `pip install redis` |
| `celery` | Distributed task queue | `pip install celery` |
| `websockets` | WebSocket library | `pip install websockets` |

### Database Clients

| Package | Description | Install |
|---------|-------------|---------|
| `sqlalchemy` | SQL toolkit and ORM | `pip install sqlalchemy` |
| `psycopg2-binary` | PostgreSQL adapter | `pip install psycopg2-binary` |
| `pymongo` | MongoDB driver | `pip install pymongo` |
| `motor` | Async MongoDB driver | `pip install motor` |
| `pymysql` | MySQL driver | `pip install pymysql` |
| `neo4j` | Neo4j driver | `pip install neo4j` |
| `elasticsearch` | Elasticsearch client | `pip install elasticsearch` |
| `redis` | Redis client | `pip install redis` |

### MLOps & Cloud

| Package | Description | Install |
|---------|-------------|---------|
| `mlflow` | ML lifecycle tracking | `pip install mlflow` |
| `wandb` | Experiment tracking | `pip install wandb` |
| `dvc` | Data version control | `pip install dvc` |
| `evidently` | Model monitoring | `pip install evidently` |
| `prefect` | Workflow orchestration | `pip install prefect` |
| `apache-airflow` | DAG scheduler | `pip install apache-airflow` |
| `boto3` | AWS Python SDK | `pip install boto3` |
| `google-cloud-aiplatform` | Vertex AI SDK | `pip install google-cloud-aiplatform` |
| `azure-ai-ml` | Azure ML SDK | `pip install azure-ai-ml` |
| `bentoml` | Model serving | `pip install bentoml` |
| `feast` | Feature store | `pip install feast` |

### Python Dev Tools

| Package | Description | Install |
|---------|-------------|---------|
| `pytest` | Testing framework | `pip install pytest` |
| `mypy` | Static type checker | `pip install mypy` |
| `ruff` | Fast Python linter | `pip install ruff` |
| `black` | Code formatter | `pip install black` |
| `isort` | Import sorter | `pip install isort` |
| `pre-commit` | Git pre-commit hooks | `pip install pre-commit` |
| `poetry` | Dependency management | See python-poetry.org |
| `uv` | Fast package manager | See astral.sh/uv |
| `jupyterlab` | JupyterLab notebook | `pip install jupyterlab` |
| `ipython` | Enhanced Python REPL | `pip install ipython` |
| `tqdm` | Progress bars | `pip install tqdm` |
| `rich` | Beautiful terminal output | `pip install rich` |
| `loguru` | Logging library | `pip install loguru` |
| `pydantic` | Data validation | `pip install pydantic` |
| `typer` | CLI framework using type hints | `pip install typer` |
| `click` | CLI creation kit | `pip install click` |

---

*Generated for: `python-ai` monorepo — covering 20 knowledge domains, 200+ acronyms, 100+ file types, and 500+ terms.*
