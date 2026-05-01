# 📏 Depth Estimation — MiDaS & DepthAnything

## What is Depth Estimation?
Depth estimation predicts the distance of each pixel from the camera, producing a dense depth map from a single image (monocular) or two images (stereo). Monocular depth relies on learned visual cues like perspective and shading, while stereo depth uses geometric triangulation. Modern models like MiDaS and DepthAnything v2 achieve near-metric quality from a single RGB frame.

## Why Learn It?
- Powers robotics navigation, obstacle avoidance, and spatial awareness
- Essential for AR/VR scene understanding and 3D compositing
- Enables autonomous driving perception without expensive LiDAR
- Feeds 3D reconstruction and point cloud generation pipelines
- Pairs with object detection to estimate real-world object distances

## Key Concepts
```python
import torch
import cv2
import numpy as np
import matplotlib.pyplot as plt

# --- MiDaS via torch.hub ---
model_type = "DPT_Large"          # or "midas_v21_small" for speed
midas = torch.hub.load("intel-isl/MiDaS", model_type)
midas.eval()

transforms = torch.hub.load("intel-isl/MiDaS", "transforms")
transform = transforms.dpt_transform  # or small_transform

img = cv2.imread("scene.jpg")
img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
input_tensor = transform(img_rgb)

with torch.no_grad():
    depth = midas(input_tensor)               # relative depth, higher = closer
    depth = torch.nn.functional.interpolate(
        depth.unsqueeze(1), size=img.shape[:2],
        mode="bicubic", align_corners=False
    ).squeeze()

depth_np = depth.cpu().numpy()
plt.imshow(depth_np, cmap="plasma")           # visualize with colormap
plt.colorbar(); plt.show()

# --- DepthAnything v2 via HuggingFace ---
from transformers import pipeline
from PIL import Image

pipe = pipeline("depth-estimation", model="depth-anything/Depth-Anything-V2-Small-hf")
result = pipe(Image.open("scene.jpg"))
depth_map = result["depth"]                   # PIL image, grayscale
depth_arr = np.array(depth_map)
plt.imshow(depth_arr, cmap="inferno"); plt.show()

# --- ZoeDepth: metric depth (meters) ---
repo = "isl-org/ZoeDepth"
zoedepth = torch.hub.load(repo, "ZoeD_NK", pretrained=True).eval()
depth_metric = zoedepth.infer_pil(Image.open("scene.jpg"))  # numpy, in meters

# --- 3D Point Cloud from depth + RGB (Open3D) ---
import open3d as o3d

h, w = depth_arr.shape
fx = fy = 525.0; cx, cy = w / 2, h / 2
K = o3d.camera.PinholeCameraIntrinsic(w, h, fx, fy, cx, cy)

color_o3d = o3d.geometry.Image(img_rgb.astype(np.uint8))
depth_o3d = o3d.geometry.Image((depth_arr * 1000).astype(np.uint16))  # mm
rgbd = o3d.geometry.RGBDImage.create_from_color_and_depth(color_o3d, depth_o3d)
pcd = o3d.geometry.PointCloud.create_from_rgbd_image(rgbd, K)
o3d.visualization.draw_geometries([pcd])

# --- Real-time depth with webcam ---
cap = cv2.VideoCapture(0)
while True:
    ret, frame = cap.read()
    if not ret: break
    inp = transform(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    with torch.no_grad():
        d = midas(inp).squeeze().cpu().numpy()
    d_norm = cv2.normalize(d, None, 0, 255, cv2.NORM_MINMAX, cv2.CV_8U)
    d_color = cv2.applyColorMap(d_norm, cv2.COLORMAP_PLASMA)
    cv2.imshow("Depth", d_color)
    if cv2.waitKey(1) & 0xFF == ord('q'): break
cap.release(); cv2.destroyAllWindows()
```

## Learning Path
1. Understand monocular vs stereo depth and relative vs metric depth
2. Run MiDaS `midas_v21_small` on a static image, visualize with matplotlib
3. Upgrade to `DPT_Large` and compare quality vs speed
4. Try DepthAnything v2 via HuggingFace `pipeline("depth-estimation")`
5. Use ZoeDepth to get metric depth estimates in real units
6. Build a 3D point cloud from depth + RGB using Open3D
7. Build a real-time depth webcam app with OpenCV

## What to Build
- [ ] Depth map visualizer comparing MiDaS vs DepthAnything on the same image
- [ ] Metric distance estimator — click a pixel, get distance in meters (ZoeDepth)
- [ ] Real-time webcam depth stream with colormap overlay
- [ ] 3D point cloud viewer from a single photo using Open3D
- [ ] Depth-guided portrait blur (bokeh effect) using depth as alpha mask

## Related Folders
- `computer-vision\object-detection-main\` — combine depth + bounding box for 3D object localization
- `computer-vision\optical-flow-video-analysis-main\` — use depth + flow for scene motion understanding
- `computer-vision\image-segmentation-main\` — depth-aware segmentation masks
