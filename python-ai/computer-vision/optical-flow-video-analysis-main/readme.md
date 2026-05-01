# 🎥 Optical Flow & Video Analysis — Pixel Motion & Scene Dynamics

## What is Optical Flow?
Optical flow estimates the apparent motion of pixels between consecutive video frames, producing a 2D vector field showing where each pixel moved. Sparse methods like Lucas-Kanade track a set of feature points, while dense methods like Farneback compute flow for every pixel. Deep learning approaches like RAFT achieve state-of-the-art accuracy by treating flow as a learned iterative refinement problem.

## Why Learn It?
- Core primitive for action recognition, gesture detection, and activity analysis
- Enables robust video object tracking without re-detection every frame
- Powers background subtraction and motion detection in surveillance systems
- Two-stream CNNs using RGB + flow achieve top results on action datasets
- Building block for video stabilization, slow-motion synthesis, and frame interpolation

## Key Concepts
```python
import cv2
import numpy as np
import torch

# --- Lucas-Kanade Sparse Optical Flow ---
cap = cv2.VideoCapture("video.mp4")
ret, old_frame = cap.read()
old_gray = cv2.cvtColor(old_frame, cv2.COLOR_BGR2GRAY)

feature_params = dict(maxCorners=200, qualityLevel=0.3, minDistance=7, blockSize=7)
lk_params = dict(winSize=(15, 15), maxLevel=2,
                 criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03))
p0 = cv2.goodFeaturesToTrack(old_gray, mask=None, **feature_params)
mask = np.zeros_like(old_frame)

while True:
    ret, frame = cap.read()
    if not ret: break
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    p1, st, _ = cv2.calcOpticalFlowPyrLK(old_gray, gray, p0, None, **lk_params)
    good_new = p1[st == 1]; good_old = p0[st == 1]
    for new, old in zip(good_new, good_old):
        a, b = new.ravel().astype(int); c, d = old.ravel().astype(int)
        mask = cv2.line(mask, (a, b), (c, d), (0, 255, 0), 2)
        frame = cv2.circle(frame, (a, b), 5, (0, 0, 255), -1)
    cv2.imshow("Sparse Flow", cv2.add(frame, mask))
    old_gray = gray.copy(); p0 = good_new.reshape(-1, 1, 2)
    if cv2.waitKey(30) & 0xFF == ord('q'): break
cap.release(); cv2.destroyAllWindows()

# --- Farneback Dense Optical Flow + HSV Visualization ---
def dense_flow_hsv(prev_gray, curr_gray):
    flow = cv2.calcOpticalFlowFarneback(
        prev_gray, curr_gray, None,
        pyr_scale=0.5, levels=3, winsize=15,
        iterations=3, poly_n=5, poly_sigma=1.2, flags=0
    )
    mag, ang = cv2.cartToPolar(flow[..., 0], flow[..., 1])
    hsv = np.zeros((*prev_gray.shape, 3), dtype=np.uint8)
    hsv[..., 0] = ang * 180 / np.pi / 2   # hue = direction
    hsv[..., 1] = 255                       # full saturation
    hsv[..., 2] = cv2.normalize(mag, None, 0, 255, cv2.NORM_MINMAX)
    return cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)

# --- Background Subtraction (MOG2) ---
backSub = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=50)
cap = cv2.VideoCapture("video.mp4")
while True:
    ret, frame = cap.read()
    if not ret: break
    fg_mask = backSub.apply(frame)         # foreground mask
    fg_mask = cv2.morphologyEx(fg_mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    cv2.imshow("Foreground", fg_mask)
    if cv2.waitKey(30) & 0xFF == ord('q'): break
cap.release()

# --- CSRT Object Tracker ---
cap = cv2.VideoCapture("video.mp4")
ret, frame = cap.read()
bbox = cv2.selectROI("Select Object", frame, fromCenter=False)
tracker = cv2.TrackerCSRT_create()
tracker.init(frame, bbox)
while True:
    ret, frame = cap.read()
    if not ret: break
    ok, bbox = tracker.update(frame)
    if ok:
        x, y, w, h = map(int, bbox)
        cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
    cv2.imshow("Tracking", frame)
    if cv2.waitKey(30) & 0xFF == ord('q'): break

# --- RAFT Deep Optical Flow (torchvision) ---
from torchvision.models.optical_flow import raft_large, Raft_Large_Weights
from torchvision.transforms.functional import to_tensor

weights = Raft_Large_Weights.DEFAULT
model = raft_large(weights=weights).eval()
transforms = weights.transforms()

import PIL.Image
img1 = transforms(to_tensor(PIL.Image.open("frame1.jpg").convert("RGB")).unsqueeze(0))
img2 = transforms(to_tensor(PIL.Image.open("frame2.jpg").convert("RGB")).unsqueeze(0))
with torch.no_grad():
    flow_list = model(img1, img2)           # list of progressively refined flows
flow = flow_list[-1].squeeze()             # final flow: [2, H, W]
```

## Learning Path
1. Understand pixel motion vectors and the aperture problem in optical flow
2. Implement Lucas-Kanade sparse flow with `goodFeaturesToTrack` feature points
3. Implement Farneback dense flow and visualize with HSV color wheel encoding
4. Build a motion detection pipeline using MOG2 background subtraction
5. Track objects across frames using `cv2.TrackerCSRT_create()`
6. Run RAFT (torchvision) for high-accuracy deep optical flow
7. Build a two-stream action recognition network (RGB + flow as inputs)

## What to Build
- [ ] Dense flow visualizer with HSV color wheel on a webcam feed
- [ ] Motion alert system — trigger when flow magnitude exceeds threshold
- [ ] Multi-object tracker using CSRT on a busy street video
- [ ] Action classifier using flow features (walking, running, jumping)
- [ ] Video stabilizer using Lucas-Kanade to estimate and compensate camera motion

## Related Folders
- `computer-vision\depth-estimation-main\` — combine depth + flow for full 3D scene motion (scene flow)
- `computer-vision\object-detection-main\` — detection + tracking pipeline (detect → CSRT → flow)
- `computer-vision\image-segmentation-main\` — segment moving objects using flow masks
