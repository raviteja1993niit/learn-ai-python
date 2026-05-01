# 🔁 RNN & LSTM — Recurrent Networks for Sequential Data

## What is RNN & LSTM?
Recurrent Neural Networks (RNNs) are neural networks designed to process sequential data by maintaining a hidden state across time steps. LSTMs (Long Short-Term Memory) extend RNNs with gating mechanisms that solve the vanishing gradient problem, enabling learning of long-range dependencies in sequences like text, audio, and time series.

## Why Learn It?
- Powers foundational sequence models used in NLP, speech, and forecasting
- LSTM gating (forget/input/output gates) is a key architectural concept in modern AI
- Understanding RNNs clarifies why Transformers were invented — and where they win
- Still highly practical for time series, IoT sensor data, and resource-constrained models

## Key Concepts
```python
import torch
import torch.nn as nn

# Bidirectional LSTM for sequence classification
class BiLSTMClassifier(nn.Module):
    def __init__(self, vocab_size, embed_dim, hidden_dim, num_classes):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, embed_dim)
        self.lstm = nn.LSTM(
            embed_dim, hidden_dim,
            num_layers=2,
            batch_first=True,
            dropout=0.3,
            bidirectional=True
        )
        self.fc = nn.Linear(hidden_dim * 2, num_classes)  # *2 for bidirectional

    def forward(self, x):
        x = self.embedding(x)                    # (batch, seq, embed)
        out, (hidden, cell) = self.lstm(x)       # out: (batch, seq, hidden*2)
        # Use final hidden states from both directions
        out = self.fc(out[:, -1, :])
        return out

model = BiLSTMClassifier(vocab_size=10000, embed_dim=128, hidden_dim=256, num_classes=2)

# GRU — lighter alternative to LSTM
gru = nn.GRU(input_size=128, hidden_size=256, batch_first=True)

# Time series forecasting: many-to-one
x = torch.randn(32, 50, 10)   # (batch=32, seq_len=50, features=10)
out, h_n = gru(x)
prediction = out[:, -1, :]     # use last timestep output
```

## Learning Path
1. `pip install torch torchvision`
2. Understand RNN unrolling and hidden state propagation through time
3. Study the vanishing gradient problem — why gradients shrink over long sequences
4. Learn LSTM gates: forget (what to discard), input (what to add), output (what to expose)
5. Implement seq2seq with encoder-decoder LSTM for sequence-to-sequence tasks

## What to Build
- [ ] Time series forecaster: predict stock prices or weather with LSTM
- [ ] Text generation character-level RNN (Shakespeare-style)
- [ ] Sentiment classifier using Bidirectional LSTM on IMDB dataset

## Related Folders
- `deep-learning/transformers-main/` — the architecture that replaced RNNs for most NLP
- `nlp/sentence-transformers-main/` — modern sentence embeddings built on Transformer encoders
- `deep-learning/pytorch-main/` — PyTorch fundamentals needed to build LSTMs
