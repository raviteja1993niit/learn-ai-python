# 🔤 Text Classification with BERT

## What is Text Classification with BERT?
BERT-based text classification fine-tunes a pre-trained transformer to assign labels to text — sentiment, topic, intent, toxicity, and more. The `transformers` Trainer API handles training loops, evaluation, and checkpointing with minimal boilerplate. For low-data scenarios, SetFit achieves strong results with as few as 8 examples per class.

## Why Learn It?
- State-of-the-art accuracy on most classification benchmarks
- Trainer API abstracts away training loops and mixed-precision
- DistilBERT is 60% smaller/faster than BERT with 97% of the accuracy
- SetFit enables few-shot classification without full fine-tuning
- ONNX export makes deployment fast and framework-agnostic

## Key Concepts
```python
import torch
from datasets import Dataset
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    Trainer,
    TrainingArguments,
)
from sklearn.metrics import accuracy_score, f1_score
import numpy as np

# --- Tokenizer + Model ---
MODEL = "distilbert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(MODEL)
model = AutoModelForSequenceClassification.from_pretrained(MODEL, num_labels=3)

# --- Custom Dataset ---
texts = ["I love this!", "Terrible product.", "It's okay I guess."]
labels = [2, 0, 1]  # positive, negative, neutral

def tokenize(batch):
    return tokenizer(batch["text"], truncation=True, padding="max_length", max_length=128)

raw = Dataset.from_dict({"text": texts, "label": labels})
tokenized = raw.map(tokenize, batched=True)
tokenized.set_format("torch", columns=["input_ids", "attention_mask", "label"])

# --- Training Arguments ---
args = TrainingArguments(
    output_dir="./bert-sentiment",
    num_train_epochs=3,
    per_device_train_batch_size=16,
    evaluation_strategy="epoch",
    save_strategy="epoch",
    load_best_model_at_end=True,
    metric_for_best_model="f1",
    fp16=torch.cuda.is_available(),
    logging_steps=10,
)

# --- Metrics ---
def compute_metrics(eval_pred):
    logits, labels = eval_pred
    preds = np.argmax(logits, axis=-1)
    return {
        "accuracy": accuracy_score(labels, preds),
        "f1": f1_score(labels, preds, average="weighted"),
    }

trainer = Trainer(
    model=model,
    args=args,
    train_dataset=tokenized,
    eval_dataset=tokenized,
    compute_metrics=compute_metrics,
)
trainer.train()

# --- Multi-label classification ---
from transformers import AutoModelForSequenceClassification
import torch.nn as nn

multi_model = AutoModelForSequenceClassification.from_pretrained(
    MODEL, num_labels=5, problem_type="multi_label_classification"
)

# --- SetFit: few-shot fine-tuning ---
from setfit import SetFitModel, Trainer as SetFitTrainer, TrainingArguments as SFArgs

sf_model = SetFitModel.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")
sf_trainer = SetFitTrainer(
    model=sf_model,
    train_dataset=raw,
    args=SFArgs(num_epochs=1, batch_size=16),
)
sf_trainer.train()

# --- ONNX Export ---
from transformers.onnx import export
from pathlib import Path
# export(preprocessor=tokenizer, model=model, config=..., opset=13, output=Path("model.onnx"))
```

## Classification Variants
| Type         | `num_labels` | `problem_type`              | Loss            |
|--------------|--------------|-----------------------------|-----------------|
| Binary       | 2            | `single_label_classification` | CrossEntropy   |
| Multi-class  | N            | `single_label_classification` | CrossEntropy   |
| Multi-label  | N            | `multi_label_classification`  | BCEWithLogits  |

## Learning Path
1. Fine-tune DistilBERT on SST-2 (binary sentiment) with Trainer API
2. Extend to multi-class (3–5 labels) on a custom dataset
3. Handle class imbalance with `class_weight` or oversampling
4. Try SetFit with 8 examples per class — compare to full fine-tune
5. Export to ONNX and benchmark inference latency
6. Deploy as FastAPI endpoint with batched inference

## What to Build
- [ ] Customer review sentiment classifier (positive/neutral/negative)
- [ ] Support ticket intent classifier (billing/technical/general)
- [ ] News topic tagger (multi-label: politics, tech, sports...)
- [ ] SetFit few-shot classifier trained on 10 examples per class
- [ ] ONNX-exported model benchmarked vs PyTorch baseline

## Related Folders
- `nlp\named-entity-recognition-main\` — token-level classification sibling task
- `nlp\sentence-transformers-main\` — embeddings used by SetFit
- `generative-ai\deepeval-llm-testing-main\` — evaluate classifier outputs
