# 🏷️ Named Entity Recognition — Extracting Real-World Entities from Text

## What is NER?
Named Entity Recognition (NER) is an NLP task that locates and classifies named entities in text into
predefined categories such as PERSON, ORG, GPE, DATE, and MONEY. It is a foundational building block
for information extraction, knowledge graph construction, and document AI pipelines.

## Why Learn It?
- Core NLP primitive used in virtually every production text-processing pipeline
- spaCy provides production-ready NER with sub-millisecond inference per sentence
- HuggingFace token classification enables fine-tuned, state-of-the-art NER
- GLiNER enables zero-shot NER with arbitrary entity types — no training data needed
- Critical for document AI, legal tech, biomedical, and financial NLP applications

## Key Concepts
```python
# ── 1. IOB Tagging Scheme ─────────────────────────────────────────────────
# B-PER  → Beginning of a PERSON entity
# I-PER  → Inside a PERSON entity
# O      → Outside any entity
# BIOES adds S- (single token) and E- (end) for finer granularity

# ── 2. spaCy NER ──────────────────────────────────────────────────────────
import spacy

nlp = spacy.load("en_core_web_trf")   # transformer-based model

texts = [
    "Apple Inc. was founded by Steve Jobs in Cupertino, California in 1976.",
    "The WHO declared a global health emergency on January 30, 2020.",
]

for doc in nlp.pipe(texts, batch_size=32):
    for ent in doc.ents:
        print(f"{ent.text:<30} {ent.label_:<12} {spacy.explain(ent.label_)}")

# ── 3. HuggingFace Token Classification ───────────────────────────────────
from transformers import pipeline, AutoTokenizer, AutoModelForTokenClassification

model_name = "dslim/bert-base-NER"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForTokenClassification.from_pretrained(model_name)

ner_pipeline = pipeline("ner", model=model, tokenizer=tokenizer, aggregation_strategy="simple")

text = "Elon Musk leads Tesla and SpaceX, both headquartered in the United States."
entities = ner_pipeline(text)
for e in entities:
    print(f"{e['word']:<25} {e['entity_group']:<10} score={e['score']:.3f}")

# ── 4. Custom NER Training with spaCy v3 ──────────────────────────────────
import spacy
from spacy.tokens import DocBin

nlp_blank = spacy.blank("en")
db = DocBin()

TRAIN_DATA = [
    ("Tesla reported $24B in revenue for Q3 2024.", {"entities": [(0, 5, "ORG"), (16, 19, "MONEY")]}),
    ("Sundar Pichai joined Google in 2004.", {"entities": [(0, 13, "PERSON"), (21, 27, "ORG")]}),
]

for text, annotations in TRAIN_DATA:
    doc = nlp_blank.make_doc(text)
    ents = []
    for start, end, label in annotations["entities"]:
        span = doc.char_span(start, end, label=label, alignment_mode="contract")
        if span:
            ents.append(span)
    doc.ents = ents
    db.add(doc)

db.to_disk("train.spacy")
# Then: python -m spacy train config.cfg --output ./output --paths.train train.spacy

# ── 5. GLiNER — Zero-Shot NER ─────────────────────────────────────────────
from gliner import GLiNER

gliner = GLiNER.from_pretrained("urchade/gliner_medium-v2.1")

text = "Dr. Sarah Connor was awarded the Nobel Prize in Berlin on December 10th."
labels = ["person", "award", "location", "date"]

entities = gliner.predict_entities(text, labels, threshold=0.5)
for e in entities:
    print(f"{e['text']:<25} → {e['label']} ({e['score']:.2f})")

# ── 6. Entity Linking ─────────────────────────────────────────────────────
# After extraction, link "Apple" → Q312 (Wikidata), "Steve Jobs" → Q19837
# Tools: spaCy + NEL component, REL, mREBEL, or Wikidata API lookup
```

## Learning Path
1. Understand IOB/BIOES tagging and why sequence labeling differs from classification
2. Run spaCy's pre-trained NER and explore all built-in entity types
3. Fine-tune `dslim/bert-base-NER` on a custom dataset with HuggingFace Trainer
4. Train a spaCy v3 NER model using `config.cfg` and the CLI
5. Explore GLiNER for zero-shot NER on domain-specific entity types
6. Add entity linking to connect extracted entities to a knowledge base
7. Study nested NER (overlapping spans) with SpanCategorizer in spaCy

## What to Build
- [ ] Resume parser extracting PERSON, ORG, DATE, SKILL entities with spaCy
- [ ] News article entity extractor with entity linking to Wikipedia URLs
- [ ] Custom biomedical NER fine-tuned on the NCBI Disease corpus
- [ ] GLiNER zero-shot demo: extract arbitrary entity types without training data
- [ ] Knowledge graph builder: NER → entity linking → Neo4j / NetworkX graph

## Related Folders
- `nlp/question-answering-systems-main/` — NER enriches context for QA pipelines
- `nlp/topic-modeling-bertopic-main/` — combine NER with topic discovery for richer analysis
- `rag/` — NER-extracted entities can serve as structured metadata filters in RAG
