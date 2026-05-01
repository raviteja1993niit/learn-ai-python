# ❓ Question Answering Systems — From Extractive to Generative QA

## What is a Question Answering System?
A Question Answering (QA) system takes a natural-language question and returns a precise answer, either
by extracting a span from a passage (extractive QA), generating a free-form response (generative QA),
or retrieving relevant documents and reading them together (open-domain QA). It is the backbone of
enterprise search, chatbots, and knowledge-base assistants.

## Why Learn It?
- Foundation of RAG pipelines — understanding QA helps you build better retrieval + generation systems
- SQuAD benchmark is the "ImageNet" of NLP — mastering it is a rite of passage
- Covers the full spectrum from classic BERT fine-tuning to modern LLM prompting
- Transferable to legal document search, medical Q&A, and customer support automation
- Multi-hop and table QA push the boundaries of current LLM reasoning

## Key Concepts
```python
# ── 1. Extractive QA with HuggingFace pipeline ────────────────────────────
from transformers import pipeline

qa_pipeline = pipeline("question-answering", model="distilbert-base-cased-distilled-squad")

context = """
The Eiffel Tower is a wrought-iron lattice tower on the Champ de Mars in Paris, France.
It was constructed from 1887 to 1889 as the centerpiece of the 1889 World's Fair.
The tower is 330 metres tall and is the most-visited paid monument in the world.
"""

result = qa_pipeline(question="How tall is the Eiffel Tower?", context=context)
print(f"Answer: {result['answer']}  (score={result['score']:.3f})")

# ── 2. BERT start/end logits (under the hood) ─────────────────────────────
from transformers import AutoTokenizer, AutoModelForQuestionAnswering
import torch

model_name = "distilbert-base-cased-distilled-squad"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForQuestionAnswering.from_pretrained(model_name)

inputs = tokenizer("How tall is the Eiffel Tower?", context, return_tensors="pt")
with torch.no_grad():
    outputs = model(**inputs)

start = torch.argmax(outputs.start_logits)
end   = torch.argmax(outputs.end_logits) + 1
answer = tokenizer.convert_tokens_to_string(
    tokenizer.convert_ids_to_tokens(inputs["input_ids"][0][start:end])
)
print(f"Span answer: {answer}")

# ── 3. Fine-tuning DistilBERT on custom QA pairs ──────────────────────────
from datasets import Dataset
from transformers import TrainingArguments, Trainer, DefaultDataCollator

custom_data = [
    {
        "id": "1",
        "context": "Python was created by Guido van Rossum and first released in 1991.",
        "question": "Who created Python?",
        "answers": {"text": ["Guido van Rossum"], "answer_start": [19]},
    }
]
dataset = Dataset.from_list(custom_data)
# Use run_qa.py from HuggingFace examples or squad_v2 preprocessing for full fine-tuning

# ── 4. Generative QA with T5 ──────────────────────────────────────────────
from transformers import T5ForConditionalGeneration, T5Tokenizer

t5 = T5ForConditionalGeneration.from_pretrained("google/flan-t5-base")
t5_tok = T5Tokenizer.from_pretrained("google/flan-t5-base")

prompt = f"Answer the question based on the context.\nContext: {context}\nQuestion: Who built the Eiffel Tower?"
inputs = t5_tok(prompt, return_tensors="pt", max_length=512, truncation=True)
output = t5.generate(**inputs, max_new_tokens=50)
print(t5_tok.decode(output[0], skip_special_tokens=True))

# ── 5. Open-Domain QA (Retriever + Reader) ────────────────────────────────
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain.chains import RetrievalQA

vectorstore = FAISS.from_texts([context], OpenAIEmbeddings())
qa_chain = RetrievalQA.from_chain_type(
    llm=ChatOpenAI(model="gpt-4o-mini"),
    retriever=vectorstore.as_retriever(search_kwargs={"k": 3}),
)
print(qa_chain.run("What year was the Eiffel Tower built?"))

# ── 6. Evaluation Metrics ─────────────────────────────────────────────────
def exact_match(prediction: str, ground_truth: str) -> float:
    return float(prediction.strip().lower() == ground_truth.strip().lower())

def token_f1(prediction: str, ground_truth: str) -> float:
    pred_tokens = prediction.lower().split()
    gt_tokens   = ground_truth.lower().split()
    common      = set(pred_tokens) & set(gt_tokens)
    if not common:
        return 0.0
    precision = len(common) / len(pred_tokens)
    recall    = len(common) / len(gt_tokens)
    return 2 * precision * recall / (precision + recall)
```

## Learning Path
1. Understand the SQuAD dataset format (context, question, answer span)
2. Run HuggingFace's `question-answering` pipeline on SQuAD examples
3. Inspect BERT start/end logit mechanics for extractive span selection
4. Fine-tune DistilBERT on a custom QA dataset using HuggingFace Trainer
5. Build a generative QA system with Flan-T5 or GPT-4o
6. Implement an open-domain QA pipeline with FAISS retrieval + LLM reading
7. Benchmark with Exact Match (EM) and F1 on a held-out evaluation set

## What to Build
- [ ] Extractive QA over a PDF document (PyMuPDF + DistilBERT)
- [ ] Custom QA dataset creation and DistilBERT fine-tuning pipeline
- [ ] Open-domain QA system over 100 Wikipedia articles with FAISS + GPT-4o
- [ ] TAPAS table QA: answer questions from CSV/Excel tables
- [ ] Multi-hop QA: chain two retrieval steps to answer complex questions

## Related Folders
- `nlp/named-entity-recognition-main/` — NER enriches context before QA retrieval
- `rag/` — open-domain QA is essentially RAG — study both together
- `nlp/topic-modeling-bertopic-main/` — topic clusters can narrow QA search scope
