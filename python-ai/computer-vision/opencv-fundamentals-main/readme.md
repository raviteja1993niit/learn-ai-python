# 🖼️ OpenCV Fundamentals — Computer Vision from Scratch

## What is OpenCV?
OpenCV (Open Source Computer Vision Library) is the foundational library for image and video processing in Python. It provides hundreds of optimised algorithms covering everything from basic pixel manipulation and geometric transforms to face detection and optical flow. Nearly every computer vision pipeline—including YOLO preprocessing—relies on OpenCV under the hood.

## Why Learn It?
- Universal dependency in computer vision; essential knowledge before any CV framework
- Handles the entire I/O pipeline: reading images, processing webcam frames, writing video
- Efficient C++ backend with a simple Python API makes it fast enough for real-time apps
- Built-in Haar cascade classifiers enable face/eye detection without any ML training

## Key Concepts
```python
import cv2
import numpy as np

# Read, display, write
img = cv2.imread("photo.jpg")          # BGR (not RGB!) by default
cv2.imshow("window", img)
cv2.waitKey(0); cv2.destroyAllWindows()
cv2.imwrite("output.jpg", img)

# Color space conversions
rgb   = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
gray  = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
hsv   = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

# Resize, crop, rotate
resized = cv2.resize(img, (640, 480))
cropped = img[100:300, 200:400]        # [y1:y2, x1:x2]
M = cv2.getRotationMatrix2D((img.shape[1]//2, img.shape[0]//2), angle=45, scale=1)
rotated = cv2.warpAffine(img, M, (img.shape[1], img.shape[0]))

# Drawing
cv2.rectangle(img, (50, 50), (200, 200), color=(0, 255, 0), thickness=2)
cv2.circle(img, (300, 300), radius=50, color=(255, 0, 0), thickness=-1)
cv2.putText(img, "Hello CV", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0,0,255), 2)

# Blurring and thresholding
blurred = cv2.GaussianBlur(gray, (5, 5), 0)
_, thresh = cv2.threshold(blurred, 127, 255, cv2.THRESH_BINARY)
adaptive  = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                   cv2.THRESH_BINARY, 11, 2)

# Edge detection and contours
edges    = cv2.Canny(blurred, threshold1=50, threshold2=150)
contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
cv2.drawContours(img, contours, -1, (0, 255, 0), 2)

# Morphological operations
kernel = np.ones((5, 5), np.uint8)
dilated = cv2.dilate(thresh, kernel, iterations=1)
eroded  = cv2.erode(thresh, kernel, iterations=1)

# Face detection with Haar cascades
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5)
for (x, y, w, h) in faces:
    cv2.rectangle(img, (x, y), (x+w, y+h), (255, 0, 0), 2)

# Webcam / video capture
cap = cv2.VideoCapture(0)             # 0 = webcam; pass filepath for video
while cap.isOpened():
    ret, frame = cap.read()
    if not ret: break
    cv2.imshow("Live", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"): break
cap.release(); cv2.destroyAllWindows()
```

## Learning Path
1. `pip install opencv-python numpy`
2. Read an image and explore `.shape`, `.dtype`, and pixel indexing
3. Practice all color space conversions; visualise each channel separately
4. Apply blur → threshold → Canny → contours on a real photo
5. Build a live webcam feed with rectangle drawing on every frame
6. Run Haar cascade face detection on a group photo
7. Combine steps 4–6: real-time edge detection on webcam input

## What to Build
- [ ] Live motion detector using frame differencing on webcam feed
- [ ] Document scanner: detect corners → perspective warp → threshold
- [ ] Real-time face + eye detector with bounding-box overlay
- [ ] Colour-based object tracker using HSV range masking

## Related Folders
- `computer-vision/yolov8-main/` — use OpenCV for preprocessing before YOLO inference
- `computer-vision/` — OCR, depth estimation, and other vision tasks
- `data-science/` — NumPy array manipulation underpins all image operations
