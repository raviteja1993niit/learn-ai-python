# 🎨 GANs — Generative Adversarial Networks

## What are GANs?
GANs consist of two competing neural networks:
- **Generator** — creates fake data to fool the Discriminator
- **Discriminator** — distinguishes real data from fake

They train together until the Generator produces realistic outputs.

## GAN Variants
| GAN Type | Use Case |
|----------|----------|
| Vanilla GAN | Basic image generation |
| DCGAN | Deep Convolutional GAN — realistic images |
| cGAN | Conditional GAN — controlled generation |
| CycleGAN | Image-to-image translation (horse → zebra) |
| StyleGAN | High-resolution face generation |
| Pix2Pix | Paired image translation |
| WGAN | Wasserstein GAN — more stable training |

## Key Concepts
```python
# Generator: noise → fake image
generator = nn.Sequential(
    nn.Linear(latent_dim, 256),
    nn.ReLU(),
    nn.Linear(256, img_size),
    nn.Tanh()
)

# Discriminator: image → real/fake probability
discriminator = nn.Sequential(
    nn.Linear(img_size, 256),
    nn.LeakyReLU(0.2),
    nn.Linear(256, 1),
    nn.Sigmoid()
)

# Loss
adversarial_loss = nn.BCELoss()
```

## Training Tips
- Use LeakyReLU in Discriminator, ReLU in Generator
- Batch Normalization stabilizes training
- Label smoothing (use 0.9 instead of 1.0 for real)
- Monitor: Generator loss should decrease, Discriminator ~0.5

## Learning Path
1. Vanilla GAN on MNIST digits
2. DCGAN on CIFAR-10 / CelebA
3. cGAN — generate specific digits
4. CycleGAN — image translation
5. Evaluate with FID score

## What to Build
- [ ] MNIST digit generator (vanilla GAN)
- [ ] Face generator using DCGAN + CelebA
- [ ] Data augmentation GAN for imbalanced datasets
- [ ] Art style transfer with CycleGAN

## Related Folders
- `deep-learning/Pytorch-Tutorial-master/` — PyTorch foundation
- `computer-vision/cats-dogs-main/` — image datasets
- `generative-ai/Stable-Diffusion-main/` — modern image generation