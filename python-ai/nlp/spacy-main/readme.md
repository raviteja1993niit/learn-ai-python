# 🧠 spaCy — Industrial-Strength NLP

## What is spaCy?
spaCy is the most widely used **production NLP library** in Python.
Unlike NLTK (educational), spaCy is built for real-world speed and accuracy.

## Why Learn It?
- Standard in NLP industry pipelines
- 10–100x faster than NLTK for most tasks
- Built-in: tokenizer, POS tagger, NER, dependency parser, word vectors

## Key Concepts

| Concept | Description |
|---------|-------------|
| `nlp = spacy.load("en_core_web_sm")` | Load a language model |
| `doc = nlp("text")` | Process text → Doc object |
| `doc.ents` | Named Entity Recognition (NER) |
| `token.pos_` | Part-of-Speech tagging |
| `token.dep_` | Dependency parsing |
| `token.lemma_` | Lemmatization |
| `token.is_stop` | Stop word detection |
| `doc.similarity(doc2)` | Semantic similarity via word vectors |
| `Matcher` | Rule-based token matching |
| `EntityRuler` | Custom NER rules |
| `@Language.component` | Custom pipeline components |

## Language Models
```
en_core_web_sm   # small, fast
en_core_web_md   # medium, includes word vectors
en_core_web_lg   # large, best accuracy
en_core_web_trf  # transformer-based (BERT)
```

## Learning Path
1. `pip install spacy` → `python -m spacy download en_core_web_sm`
2. Basic NLP: tokenize → POS → NER
3. Custom NER with EntityRuler
4. Text classification pipeline
5. Integration with Transformers (`en_core_web_trf`)

## What to Build
- [ ] Resume parser (extract name, skills, education using NER)
- [ ] Product review analyzer (POS + sentiment)
- [ ] Custom NER for medical/legal documents
- [ ] Text similarity engine using word vectors

## Resources
- https://spacy.io/usage/spacy-101
- https://course.spacy.io/ — free official course
- Compare: spaCy (production) vs NLTK (education) vs HuggingFace (transformers)

## Related Folders
- `nlp/Natural-Language-Processing-master/` — NLTK basics
- `nlp/texthero-main/` — TextHero built on spaCy
- `nlp/Text-Summarization-NLP-Project-main/` — full NLP project