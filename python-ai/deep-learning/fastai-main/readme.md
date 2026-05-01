# 🚀 FastAI — High-Level Deep Learning Library

## What is FastAI?
FastAI is a high-level deep learning library built on PyTorch that enables
**state-of-the-art results with minimal code**.

## FastAI vs PyTorch vs Keras
| | FastAI | PyTorch | Keras |
|-|--------|---------|-------|
| Code amount | Minimal | Verbose | Medium |
| Best for | Rapid prototyping | Research | Production |
| Built on | PyTorch | - | TensorFlow |
| Transfer learning | ✅ Super easy | Manual | Easy |

## Key Code
```python
from fastai.vision.all import *

# Image classification in 5 lines
path = untar_data(URLs.PETS)
dls = ImageDataLoaders.from_name_re(path/"images", get_image_files(path/"images"),
                                    pat=r"(.+)_\d+.jpg$", item_tfms=Resize(224))
learn = vision_learner(dls, resnet34, metrics=error_rate)
learn.fine_tune(3)  # 3 epochs fine-tuning
learn.show_results()

# Text classification
dls = TextDataLoaders.from_csv(path, "texts.csv", text_col="text", label_col="label")
learn = text_classifier_learner(dls, AWD_LSTM, metrics=accuracy)
learn.fine_tune(4)
```

## FastAI Learner Tricks
- `lr_find()` — find optimal learning rate
- `fine_tune()` — discriminative learning rates
- `fit_one_cycle()` — cyclical learning rates
- `tta()` — test-time augmentation

## Learning Path
1. `pip install fastai`
2. Image classification (pets dataset)
3. Transfer learning with different architectures
4. Text classification with AWD-LSTM
5. Tabular data with FastAI

## What to Build
- [ ] Image classifier (cats/dogs) — compare with manual PyTorch version
- [ ] Skin disease classifier with 3 lines of fine-tuning
- [ ] Tabular ML with FastAI (replace sklearn)

## Related Folders
- `deep-learning/Pytorch-Tutorial-master/` — PyTorch foundation
- `deep-learning/Transfer-Learning-master/` — transfer learning manually
- `computer-vision/cats-dogs-main/` — same problem, more code