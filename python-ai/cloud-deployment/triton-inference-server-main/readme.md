# 🚀 Triton Inference Server — High-Performance Model Serving

## What is Triton Inference Server?
NVIDIA Triton Inference Server is an open-source inference serving platform optimized for GPU and CPU deployments. It supports multiple backends simultaneously (PyTorch, TensorFlow, ONNX, TensorRT, Python), dynamic batching to maximize GPU utilization, and ensemble pipelines for chaining models. A single Triton instance can serve hundreds of models with microsecond overhead, making it the standard for production ML serving at scale.

## Why Learn It?
- Serves PyTorch, TensorFlow, ONNX, and TensorRT models from the same server instance
- Dynamic batching groups concurrent requests to maximize GPU throughput
- Ensemble models chain preprocessing → model → postprocessing in one server-side graph
- Native gRPC and HTTP endpoints with shared-memory support for low-latency clients
- First-class Kubernetes/Helm support and GPU Multi-Instance (MIG) partitioning

## Key Concepts
```python
# ── Model Repository Layout ──────────────────────────────────────────────────
# model_repository/
#   resnet50/
#     config.pbtxt
#     1/
#       model.pt          ← TorchScript exported model
#   bert_onnx/
#     config.pbtxt
#     1/
#       model.onnx
#   ensemble_pipeline/
#     config.pbtxt        ← no model file, just graph definition
#     1/

# ── config.pbtxt (PyTorch backend) ───────────────────────────────────────────
"""
name: "resnet50"
backend: "pytorch"
max_batch_size: 32

input [{ name: "INPUT__0"  data_type: TYPE_FP32  dims: [3, 224, 224] }]
output[{ name: "OUTPUT__0" data_type: TYPE_FP32  dims: [1000]        }]

dynamic_batching { preferred_batch_size: [8, 16, 32]  max_queue_delay_microseconds: 5000 }

instance_group [{ count: 2  kind: KIND_GPU  gpus: [0] }]

model_warmup [{
    name: "warmup"
    batch_size: 1
    inputs { key: "INPUT__0"  value { data_type: TYPE_FP32  dims: [3, 224, 224]  zero_data: true }}
}]
"""

# ── Export TorchScript model ──────────────────────────────────────────────────
import torch, torchvision

model = torchvision.models.resnet50(pretrained=True).eval()
dummy = torch.randn(1, 3, 224, 224)
traced = torch.jit.trace(model, dummy)
traced.save("model_repository/resnet50/1/model.pt")

# ── tritonclient HTTP inference ───────────────────────────────────────────────
import tritonclient.http as httpclient
import numpy as np

client = httpclient.InferenceServerClient(url="localhost:8000")

img = np.random.rand(1, 3, 224, 224).astype(np.float32)
inputs  = [httpclient.InferInput("INPUT__0", img.shape, "FP32")]
outputs = [httpclient.InferRequestedOutput("OUTPUT__0")]
inputs[0].set_data_from_numpy(img)

result = client.infer(model_name="resnet50", inputs=inputs, outputs=outputs)
logits = result.as_numpy("OUTPUT__0")
print("Top class:", np.argmax(logits))

# ── tritonclient gRPC (shared memory, lower latency) ─────────────────────────
import tritonclient.grpc as grpcclient

grpc_client = grpcclient.InferenceServerClient(url="localhost:8001")
inputs  = [grpcclient.InferInput("INPUT__0", img.shape, "FP32")]
outputs = [grpcclient.InferRequestedOutput("OUTPUT__0")]
inputs[0].set_data_from_numpy(img)
result = grpc_client.infer("resnet50", inputs=inputs, outputs=outputs)

# ── Ensemble config.pbtxt ────────────────────────────────────────────────────
"""
name: "ensemble_pipeline"
platform: "ensemble"
max_batch_size: 32

input [{ name: "RAW_INPUT"   data_type: TYPE_FP32  dims: [3, 256, 256] }]
output[{ name: "FINAL_SCORE" data_type: TYPE_FP32  dims: [1000]        }]

ensemble_scheduling {
    step [
        { model_name: "preprocess"  model_version: 1
          input_map  { key: "RAW_INPUT"   value: "RAW_INPUT"   }
          output_map { key: "PROC_OUTPUT" value: "PROC_OUTPUT" } },
        { model_name: "resnet50"    model_version: 1
          input_map  { key: "INPUT__0"    value: "PROC_OUTPUT" }
          output_map { key: "OUTPUT__0"   value: "FINAL_SCORE" } }
    ]
}
"""
```

```bash
# Launch Triton with Docker
docker run --gpus all --rm -p 8000:8000 -p 8001:8001 -p 8002:8002 \
  -v $(pwd)/model_repository:/models \
  nvcr.io/nvidia/tritonserver:24.01-py3 \
  tritonserver --model-repository=/models --log-verbose=1

# perf_analyzer benchmarking
perf_analyzer -m resnet50 -u localhost:8000 --concurrency-range 1:16 --measurement-interval 5000
```

## Learning Path
1. Understand the model repository layout and `config.pbtxt` schema
2. Export a TorchScript model and serve it locally with Docker
3. Write a `tritonclient.http` client to send inference requests
4. Enable dynamic batching and measure throughput with `perf_analyzer`
5. Build an ensemble pipeline chaining a Python preprocessor → ONNX model
6. Deploy on Kubernetes using the official NVIDIA Triton Helm chart
7. Compare Triton vs BentoML vs TorchServe for your latency/throughput targets

## What to Build
- [ ] ResNet50 image classifier served on Triton with dynamic batching enabled
- [ ] BERT text classifier exported to ONNX and benchmarked with `perf_analyzer`
- [ ] Ensemble pipeline: Python tokenizer → ONNX BERT → Python postprocessor
- [ ] Load-testing dashboard comparing Triton throughput at concurrency 1–32
- [ ] Kubernetes Helm deployment with GPU MIG partitioning for multi-tenant serving

## Related Folders
- `cloud-deployment\seldon-core-main\` — orchestrate Triton as a backend inside Seldon
- `cloud-deployment\model-deployment-main\` — compare BentoML, TorchServe, Triton, KServe
- `model-optimization\onnx-tensorrt-main\` — optimize models before serving on Triton
