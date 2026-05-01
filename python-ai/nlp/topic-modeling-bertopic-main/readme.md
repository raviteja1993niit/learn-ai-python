# 📚 BERTopic & Topic Modeling — Neural Topic Discovery

## What is BERTopic?
BERTopic is a topic modeling framework that leverages transformer embeddings, UMAP dimensionality
reduction, and HDBSCAN clustering to discover coherent topics in a text corpus. Unlike traditional
LDA (which uses bag-of-words), BERTopic captures semantic meaning, produces human-readable topic
labels, and scales to millions of documents.

## Why Learn It?
- Outperforms LDA and NMF on topic coherence benchmarks with minimal tuning
- Works zero-shot — no labelled data required for basic topic discovery
- Supports dynamic topic modeling (topics over time), guided topics, and zero-shot topic assignment
- Built-in interactive visualisations (Plotly) ready for dashboards and reports
- Widely used in customer feedback analysis, social media monitoring, and research mining

## Key Concepts
```python
from bertopic import BERTopic
from bertopic.representation import KeyBERTInspired, MaximalMarginalRelevance
from sentence_transformers import SentenceTransformer
from sklearn.datasets import fetch_20newsgroups
import pandas as pd

# ── 1. Basic pipeline: embed → UMAP → HDBSCAN → c-TF-IDF ─────────────────
docs = fetch_20newsgroups(subset="train", remove=("headers", "footers", "quotes"))["data"]

embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
topic_model = BERTopic(embedding_model=embedding_model, verbose=True)
topics, probs = topic_model.fit_transform(docs)

print(topic_model.get_topic_info().head(10))
print(topic_model.get_topic(0))   # top words for topic 0

# ── 2. Fine-grained representations ───────────────────────────────────────
representation_model = {
    "KeyBERT": KeyBERTInspired(),
    "MMR": MaximalMarginalRelevance(diversity=0.3),
}
topic_model_adv = BERTopic(
    embedding_model=embedding_model,
    representation_model=representation_model,
)
topics, probs = topic_model_adv.fit_transform(docs)

# ── 3. Visualisations ─────────────────────────────────────────────────────
topic_model.visualize_barchart(top_n_topics=10)          # word scores per topic
topic_model.visualize_heatmap()                           # topic similarity
topic_model.visualize_hierarchy()                        # dendrogram
topic_model.visualize_topics()                           # 2-D topic scatter

# ── 4. Dynamic topic modeling (topics over time) ──────────────────────────
timestamps = ["2020-01", "2021-06", "2022-12"] * (len(docs) // 3 + 1)
timestamps = timestamps[:len(docs)]
topics_over_time = topic_model.topics_over_time(docs, timestamps, nr_bins=10)
topic_model.visualize_topics_over_time(topics_over_time, top_n_topics=5)

# ── 5. Zero-shot topic modeling ───────────────────────────────────────────
zeroshot_topics = ["machine learning", "sports", "politics", "health"]
zs_model = BERTopic(zeroshot_topic_list=zeroshot_topics, zeroshot_min_similarity=0.7)
topics, probs = zs_model.fit_transform(docs)

# ── 6. Guided topic modeling ──────────────────────────────────────────────
seed_topic_list = [["gpu", "cuda", "nvidia"], ["election", "vote", "congress"]]
guided_model = BERTopic(seed_topic_list=seed_topic_list)
guided_model.fit_transform(docs)

# ── 7. LDA comparison ─────────────────────────────────────────────────────
from sklearn.decomposition import LatentDirichletAllocation
from sklearn.feature_extraction.text import CountVectorizer

cv = CountVectorizer(max_df=0.95, min_df=2, stop_words="english")
dtm = cv.fit_transform(docs)
lda = LatentDirichletAllocation(n_components=10, random_state=42)
lda.fit(dtm)
# BERTopic: semantic topics | LDA: co-occurrence topics — different strengths
```

## Learning Path
1. Understand LDA and bag-of-words topic modeling as a baseline
2. Study the BERTopic pipeline: embeddings → UMAP → HDBSCAN → c-TF-IDF
3. Run BERTopic on 20 Newsgroups and inspect topic quality
4. Experiment with different sentence transformers and UMAP/HDBSCAN parameters
5. Add KeyBERTInspired or LLM-based representation for richer topic labels
6. Build dynamic topic modeling on a time-stamped corpus
7. Evaluate with topic coherence (TC) and topic diversity (TD) metrics

## What to Build
- [ ] Topic explorer for a news article dataset with interactive Plotly visualisations
- [ ] Customer review analyzer using BERTopic + sentiment per topic
- [ ] Dynamic topic model tracking tech trends from arXiv abstracts (2018–2024)
- [ ] Zero-shot topic classifier compared against supervised text classification
- [ ] LDA vs BERTopic coherence benchmark on the same corpus

## Related Folders
- `nlp/named-entity-recognition-main/` — combine NER with topic modeling for richer extraction
- `nlp/question-answering-systems-main/` — topics can guide open-domain QA retrieval
- `rag/` — topic clusters can inform chunking and retrieval strategies
