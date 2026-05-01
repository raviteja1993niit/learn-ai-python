# ✂️ SAM — Segment Anything Model

## What is SAM?
Segment Anything Model (SAM), released by Meta AI in 2023, is a promptable image segmentation
foundation model trained on 1 billion masks. Given point, box, or mask prompts, SAM returns
high-quality segmentation masks for any object — zero-shot — without retraining. SAM2 (2024)
extends this capability to video with a streaming memory architecture.

## Why Learn It?
- Zero-shot segmentation: works on any image domain without fine-tuning
- Promptable API enables interactive annotation pipelines that cut labelling time by 10x
- SAM2 handles video object segmentation out of the box
- Grounded-SAM combines open-vocabulary detection (GroundingDINO) with SAM for text-prompted segmentation
- Critical for medical imaging, satellite analysis, autonomous driving, and dataset curation

## Key Concepts
```python
# ── 1. SamPredictor: prompt-based segmentation ────────────────────────────
import numpy as np
import cv2
from segment_anything import sam_model_registry, SamPredictor

sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth")
sam.to("cuda")
predictor = SamPredictor(sam)

image = cv2.imread("image.jpg")
image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
predictor.set_image(image_rgb)   # encodes image once; re-use for multiple prompts

# Point prompt: (x, y) + label 1=foreground, 0=background
masks, scores, logits = predictor.predict(
    point_coords=np.array([[500, 375]]),
    point_labels=np.array([1]),
    multimask_output=True,
)
best_mask = masks[np.argmax(scores)]   # shape: (H, W) boolean

# Box prompt: [x1, y1, x2, y2]
masks, scores, logits = predictor.predict(
    box=np.array([100, 50, 800, 700]),
    multimask_output=False,
)

# ── 2. SamAutomaticMaskGenerator: segment everything ─────────────────────
from segment_anything import SamAutomaticMaskGenerator

mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    points_per_side=32,
    pred_iou_thresh=0.88,
    stability_score_thresh=0.95,
    crop_n_layers=1,
    min_mask_region_area=100,
)

anns = mask_generator.generate(image_rgb)
# anns is a list of dicts: {segmentation, area, bbox, predicted_iou, ...}
print(f"Found {len(anns)} masks")

# ── 3. Grounded-SAM: text prompt → detection → segmentation ──────────────
# pip install groundingdino-py segment-anything
from groundingdino.util.inference import load_model, predict
from torchvision.ops import box_convert
import torch

gd_model = load_model("groundingdino_swint_ogc.py", "groundingdino_swint_ogc.pth")

boxes, logits_gd, phrases = predict(
    model=gd_model,
    image=image_rgb,
    caption="a cat . a dog",
    box_threshold=0.3,
    text_threshold=0.25,
)
# Convert boxes to pixel coords, then feed to SAM as box prompts
h, w = image_rgb.shape[:2]
boxes_px = box_convert(boxes * torch.tensor([w, h, w, h]), "cxcywh", "xyxy").numpy()

# ── 4. SAM2 for Video ─────────────────────────────────────────────────────
# pip install sam2
from sam2.build_sam import build_sam2_video_predictor

predictor2 = build_sam2_video_predictor("sam2_hiera_large.yaml", "sam2_hiera_large.pt")

with torch.inference_mode():
    state = predictor2.init_state(video_path="video.mp4")
    predictor2.add_new_points_or_box(
        inference_state=state,
        frame_idx=0,
        obj_id=1,
        points=np.array([[300, 200]]),
        labels=np.array([1]),
    )
    for frame_idx, obj_ids, masks in predictor2.propagate_in_video(state):
        print(f"Frame {frame_idx}: {len(obj_ids)} tracked objects")

# ── 5. HuggingFace SAM integration ───────────────────────────────────────
from transformers import SamModel, SamProcessor
from PIL import Image

hf_model = SamModel.from_pretrained("facebook/sam-vit-huge").to("cuda")
processor = SamProcessor.from_pretrained("facebook/sam-vit-huge")

pil_image = Image.open("image.jpg").convert("RGB")
inputs = processor(pil_image, input_points=[[[500, 375]]], return_tensors="pt").to("cuda")
outputs = hf_model(**inputs)
masks = processor.image_processor.post_process_masks(
    outputs.pred_masks.cpu(), inputs["original_sizes"].cpu(), inputs["reshaped_input_sizes"].cpu()
)
```

## Learning Path
1. Understand encoder-decoder segmentation architectures (U-Net, Mask R-CNN)
2. Download SAM ViT-H checkpoint and run SamPredictor on a local image
3. Explore multimask output and the role of predicted IoU scores
4. Run SamAutomaticMaskGenerator and visualise all detected masks
5. Combine GroundingDINO + SAM for text-prompted segmentation (Grounded-SAM)
6. Upgrade to SAM2 and track an object across a short video clip
7. Fine-tune SAM on a domain-specific dataset (medical / satellite imagery)

## What to Build
- [ ] Interactive annotation tool: click on objects, export COCO-format masks
- [ ] Grounded-SAM pipeline: type "red car" and segment it in any image
- [ ] Automatic dataset annotator: SAM → polygon labels → YOLO training data
- [ ] SAM2 object tracker on a dashcam video clip
- [ ] Medical image segmenter: fine-tune SAM on a public radiology dataset (e.g. CheXpert)

## Related Folders
- `computer-vision/yolo-object-detection-main/` — combine YOLO detections as box prompts for SAM
- `computer-vision/image-classification-main/` — classification labels can guide SAM prompting
- `multimodal/` — SAM outputs feed into multimodal pipelines (vision + language)
