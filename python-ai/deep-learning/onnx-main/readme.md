# 🔄 ONNX — Open Neural Network Exchange

## What is ONNX?
ONNX is an open format for **exporting and deploying ML models** across frameworks.
Train in PyTorch → export to ONNX → deploy on any platform (mobile, edge, cloud).

## Why ONNX?
- Framework-agnostic: PyTorch → TFLite → CoreML → OpenVINO
- 2–10x inference speedup via ONNX Runtime
- Deploy to edge devices (Raspberry Pi, phones)

## Key Workflow
```python
import torch
import onnx
import onnxruntime

# 1. Export PyTorch model to ONNX
torch.onnx.export(
    model,
    dummy_input,
    "model.onnx",
    export_params=True,
    opset_version=17,
    input_names=["input"],
    output_names=["output"],
    dynamic_axes={"input": {0: "batch_size"}}
)

# 2. Verify
onnx_model = onnx.load("model.onnx")
onnx.checker.check_model(onnx_model)

# 3. Run inference with ONNX Runtime (fast!)
session = onnxruntime.InferenceSession("model.onnx")
outputs = session.run(None, {"input": input_data})
```

## Supported Conversions
- PyTorch → ONNX → TensorFlow Lite (mobile)
- PyTorch → ONNX → OpenVINO (Intel edge)
- Sklearn → ONNX via `sklearn-onnx`
- HuggingFace → ONNX via `optimum`

## Learning Path
1. `pip install onnx onnxruntime`
2. Export a simple PyTorch model to ONNX
3. Run inference with ONNX Runtime
4. Quantize model (INT8) for faster inference
5. Deploy to edge device

## What to Build
- [ ] Export your car price / churn model to ONNX
- [ ] ONNX Runtime inference benchmark vs PyTorch
- [ ] Quantized ONNX model for Raspberry Pi deployment

## Related Folders
- `deep-learning/Pytorch-Tutorial-master/` — PyTorch models to export
- `cloud-deployment/Docker-Tutorial-main/` — containerize ONNX app