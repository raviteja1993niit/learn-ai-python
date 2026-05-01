# 🎯 RLHF — Reinforcement Learning from Human Feedback

## What is this?
RLHF is the training pipeline that transforms a pretrained language model into a helpful, harmless assistant. It has three stages: supervised fine-tuning (SFT) on curated demonstrations, training a reward model on human preference pairs, then optimizing the LLM with PPO against that reward signal. DPO simplifies this by skipping the explicit reward model entirely.

## Why Learn It?
- RLHF is the core technique behind ChatGPT, Claude, and Gemini's instruction-following behavior
- DPO has become the dominant practical alternative — simpler, more stable, and competitive with PPO
- Understanding preference optimization is essential for anyone fine-tuning open-weight models
- The TRL library makes the full RLHF pipeline accessible without writing PPO from scratch

## Key Concepts
```python
# ── 1. Full RLHF Pipeline Overview ───────────────────────────────────────────
# Stage 1 — SFT: fine-tune on (prompt, good_response) pairs
# Stage 2 — Reward Model: train on (prompt, chosen, rejected) preference pairs
# Stage 3 — PPO: optimize SFT model to maximize reward while staying close to SFT ref

# ── 2. Reward Model Training with TRL ────────────────────────────────────────
# pip install trl transformers datasets accelerate
from trl import RewardTrainer, RewardConfig
from transformers import AutoModelForSequenceClassification, AutoTokenizer
from datasets import Dataset

# Preference dataset format:
data = [
    {
        "input_ids_chosen":   [1, 2, 3, 4],   # tokenized chosen response
        "attention_mask_chosen": [1, 1, 1, 1],
        "input_ids_rejected": [1, 2, 5, 6],   # tokenized rejected response
        "attention_mask_rejected": [1, 1, 1, 1],
    }
]
# Bradley-Terry model: P(chosen > rejected) = sigmoid(r_chosen - r_rejected)
# Loss = -log σ(r_chosen - r_rejected)

# ── 3. PPO Training with TRL ──────────────────────────────────────────────────
from trl import PPOTrainer, PPOConfig, AutoModelForCausalLMWithValueHead
import torch

ppo_config = PPOConfig(
    model_name="gpt2",
    learning_rate=1.41e-5,
    batch_size=16,
    mini_batch_size=4,
    gradient_accumulation_steps=1,
    kl_penalty="kl",         # penalize deviation from SFT reference policy
    target_kl=0.1,
    init_kl_coef=0.2,
)

# model = AutoModelForCausalLMWithValueHead.from_pretrained(ppo_config.model_name)
# ref_model = AutoModelForCausalLMWithValueHead.from_pretrained(ppo_config.model_name)
# ppo_trainer = PPOTrainer(ppo_config, model, ref_model, tokenizer)
#
# for batch in dataloader:
#     query_tensors = batch["input_ids"]
#     response_tensors = ppo_trainer.generate(query_tensors, max_new_tokens=64)
#     rewards = [reward_model(q, r) for q, r in zip(query_tensors, response_tensors)]
#     stats = ppo_trainer.step(query_tensors, response_tensors, rewards)

# ── 4. DPO — Direct Preference Optimization ──────────────────────────────────
# Skips reward model. Directly optimizes LLM on preference pairs.
# Loss = -log σ(β · [log π(y_w|x) - log π_ref(y_w|x)]
#                 - β · [log π(y_l|x) - log π_ref(y_l|x)])
from trl import DPOTrainer, DPOConfig
from transformers import AutoModelForCausalLM

dpo_config = DPOConfig(
    beta=0.1,                # temperature — controls deviation from reference
    max_length=512,
    max_prompt_length=256,
    learning_rate=5e-7,
    per_device_train_batch_size=2,
    num_train_epochs=3,
)

# DPO dataset format:
dpo_sample = {
    "prompt":   "Explain gravity in one sentence.",
    "chosen":   "Gravity is the attractive force between masses.",
    "rejected": "Gravity is some force or something idk.",
}

# model = AutoModelForCausalLM.from_pretrained("mistralai/Mistral-7B-Instruct-v0.1")
# ref_model = AutoModelForCausalLM.from_pretrained("mistralai/Mistral-7B-Instruct-v0.1")
# dpo_trainer = DPOTrainer(model, ref_model, args=dpo_config, train_dataset=dataset, tokenizer=tokenizer)
# dpo_trainer.train()

# ── 5. Algorithm Comparison ───────────────────────────────────────────────────
# PPO    → on-policy RL, reward model required, unstable but flexible
# DPO    → offline, no reward model, simpler, competitive quality
# ORPO   → no reference model needed, single-stage, memory-efficient
# SimPO  → reference-free DPO variant, length-normalized rewards
# CAI    → Constitutional AI (Anthropic): model self-critiques using principles

# ── 6. Mistral Instruct prompt format for RLHF datasets ──────────────────────
def format_mistral_prompt(instruction: str, response: str = "") -> str:
    return f"<s>[INST] {instruction} [/INST] {response}</s>"

chosen_pair = {
    "prompt":  format_mistral_prompt("What is the capital of France?"),
    "chosen":  format_mistral_prompt("What is the capital of France?", "Paris is the capital of France."),
    "rejected": format_mistral_prompt("What is the capital of France?", "I don't know."),
}
```

## Learning Path
1. `pip install trl transformers datasets accelerate peft`
2. Read the InstructGPT paper (Ouyang et al. 2022) — the original RLHF pipeline
3. Read the DPO paper (Rafailov et al. 2023) — understand the equivalence proof
4. Fine-tune a small model (GPT-2) with `DPOTrainer` on the Anthropic HH dataset
5. Experiment with `beta` in DPO and observe the quality/diversity tradeoff
6. Explore the `trl` examples repo for PPO sentiment steering

## What to Build
- [ ] Train a reward model on the Anthropic HH-RLHF preference dataset
- [ ] DPO fine-tune `TinyLlama` on a custom Q&A preference dataset
- [ ] Compare PPO vs DPO on a summarization task using ROUGE scores
- [ ] Implement Bradley-Terry loss from scratch and validate against `RewardTrainer`
- [ ] Build a simple Constitutional AI loop: generate → critique → revise

## Related Folders
- `generative-ai\llm-fine-tuning-main\` — SFT foundation required before RLHF
- `generative-ai\langchain-main\` — chain reward model calls with LangChain
- `deep-learning\transformers-main\` — attention architecture underlying all LLMs
