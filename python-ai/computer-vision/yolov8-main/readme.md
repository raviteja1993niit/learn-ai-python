# 🎯 YOLOv8 — Real-Time Object Detection & Beyond

## What is YOLOv8?
YOLOv8 by Ultralytics is the latest generation of the YOLO (You Only Look Once) family, supporting detection, segmentation, pose estimation, tracking, and classification in a single unified API. It delivers state-of-the-art accuracy at real-time speeds and is far simpler to use than previous YOLO versions. It has become the industry standard for applied computer vision projects.

## Why Learn It?
- One API covers detection, segmentation, pose, tracking, and classification tasks
- Pretrained COCO weights let you run inference in 3 lines of code
- Training on custom datasets is straightforward with a simple `data.yaml` config
- Models export to ONNX and TensorRT for edge and production deployment

## Key Concepts
```python
from ultralytics import YOLO

# Load pretrained model — sizes: n(ano) s(mall) m(edium) l(arge) x(tra-large)
model = YOLO("yolov8n.pt")          # detection
model = YOLO("yolov8n-seg.pt")      # instance segmentation
model = YOLO("yolov8n-pose.pt")     # pose estimation
model = YOLO("yolov8n-cls.pt")      # image classification

# Inference — image, video, webcam, URL, or numpy array
results = model.predict(source="image.jpg", conf=0.5, iou=0.45, save=True)
results = model.predict(source=0, stream=True)   # webcam real-time

for r in results:
    print(r.boxes.xyxy)      # bounding boxes [x1,y1,x2,y2]
    print(r.boxes.cls)       # class indices
    print(r.boxes.conf)      # confidence scores
    r.show()                 # display annotated frame

# Object tracking across frames
results = model.track(source="video.mp4", persist=True, tracker="bytetrack.yaml")

# Train on a custom dataset
# data.yaml  →  path, train, val, nc (num classes), names (class list)
model = YOLO("yolov8n.pt")
model.train(
    data="data.yaml",
    epochs=100,
    imgsz=640,
    batch=16,
    project="runs/train",
    name="my_model"
)

# Validate and export
metrics = model.val()
print(metrics.box.map50)            # mAP@0.5

model.export(format="onnx")         # also: tensorrt, coreml, tflite
```

## Learning Path
1. `pip install ultralytics`
2. Run `yolo predict model=yolov8n.pt source='https://ultralytics.com/images/bus.jpg'`
3. Explore all task types: detect, segment, pose, classify
4. Annotate a custom dataset with Roboflow or CVAT; export COCO format
5. Write `data.yaml` and fine-tune `yolov8n.pt` for your classes
6. Evaluate with `model.val()` and inspect mAP, precision, recall curves
7. Export to ONNX and run inference without the Ultralytics dependency

## What to Build
- [ ] Real-time webcam people counter using detection + tracking
- [ ] Custom defect detector trained on a small industrial dataset
- [ ] Pose-based exercise rep counter (squat/curl tracking via keypoints)
- [ ] Segmentation pipeline that masks and crops detected objects for downstream ML

## Related Folders
- `computer-vision/opencv-fundamentals-main/` — preprocessing frames before YOLO
- `computer-vision/` — other vision tasks: classification, OCR, depth estimation
- `deployment/` — serving ONNX/TensorRT models via FastAPI or Triton
