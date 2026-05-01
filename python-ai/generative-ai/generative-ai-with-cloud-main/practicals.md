# GenAI on Cloud — Practical Projects (10 Projects)

```bash
pip install boto3 google-cloud-aiplatform openai python-dotenv streamlit numpy
```

---

## Project 1 — Multi-cloud LLM Router
**Goal**: Single API that routes requests to the best provider based on task type and cost.
**Providers**: OpenAI, Azure OpenAI, AWS Bedrock (Claude), GCP Vertex (Gemini)
**Routing logic**: task_type → provider + model selection
**Features**: fallback on error, cost tracking, latency measurement, provider comparison
**Hint**:
```python
ROUTING_MAP = {
    "reasoning": ("deepseek", "deepseek-reasoner"),
    "vision": ("openai", "gpt-4o"),
    "document": ("vertex", "gemini-1.5-pro"),
    "general": ("bedrock", "claude-haiku"),
    "enterprise": ("azure", "gpt4o-prod")
}
```

---

## Project 2 — Bedrock RAG Application
**Goal**: Build a RAG chatbot using Bedrock Knowledge Bases.
**Architecture**: S3 bucket with docs → Knowledge Base (auto-chunking + embeddings) → Bedrock Converse API → chat UI
**Features**: document upload to S3, question answering with citations, conversation history
**Key concepts**: boto3 bedrock-agent-runtime, retrieve_and_generate, S3 integration
**Hint**: Create Knowledge Base via AWS Console or boto3.client("bedrock-agent"), then use retrieve_and_generate for RAG

---

## Project 3 — Cloud Cost Comparison Tool
**Goal**: Run the same prompt across 5+ cloud providers, compare cost + quality.
**Metrics**: cost per query, time to first token, total latency, output quality (human rated)
**Providers**: OpenAI, Azure, Bedrock Claude, Bedrock Llama, Vertex Gemini
**Features**: results table, cost leaderboard, CSV export
**Hint**: Track input/output tokens for each call; use published pricing to compute cost; display as pandas DataFrame

---

## Project 4 — Enterprise Document Processor (Azure)
**Goal**: Process business documents using Azure OpenAI with full compliance.
**Features**: document classification, key entity extraction, summary generation, audit log
**Key concepts**: AzureOpenAI client, content filters, system prompt, structured output
**Compliance notes**: All data stays in Azure region; content filter policies enforced
**Hint**: Use Azure AI Document Intelligence for OCR, then Azure OpenAI for understanding

---

## Project 5 — AWS Bedrock Batch Processor
**Goal**: Process 100+ documents using Bedrock with rate limiting and cost tracking.
**Features**: concurrent processing with backoff, progress tracking, cost estimation, result export
**Key concepts**: boto3, threading, exponential backoff, token estimation
**Hint**:
```python
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
def process_batch(docs, max_workers=5):
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(claude_invoke, d): d for d in docs}
        for future in as_completed(futures):
            yield future.result()
```

---

## Project 6 — Vertex AI Multimodal Pipeline
**Goal**: Process mixed media (images, PDFs, videos) using Vertex Gemini.
**Features**: auto-detect file type, appropriate model selection, structured extraction
**Key concepts**: Vertex AI GenerativeModel, Part.from_uri(), GCS integration
**Hint**: For videos >20MB, upload to GCS first; use Part.from_uri("gs://..."); Gemini 1.5 Pro handles all media types

---

## Project 7 — Serverless LLM API (AWS Lambda)
**Goal**: Deploy a Bedrock-powered API as a Lambda function with API Gateway.
**Architecture**: API Gateway → Lambda → Bedrock → Response
**Features**: REST API endpoint, rate limiting, auth via API key, CloudWatch logging
**Hint**:
```python
# lambda_function.py
import boto3, json
bedrock = boto3.client("bedrock-runtime")
def lambda_handler(event, context):
    body = json.loads(event.get("body","{}"))
    prompt = body.get("prompt","")
    response = bedrock.converse(modelId="anthropic.claude-3-haiku-20240307-v1:0",
        messages=[{"role":"user","content":[{"text":prompt}]}],
        inferenceConfig={"maxTokens":512})
    return {"statusCode":200,"body":json.dumps({"response":response["output"]["message"]["content"][0]["text"]})}
```

---

## Project 8 — GCP Vertex AI Fine-tuning Pipeline
**Goal**: Fine-tune Gemini on custom Q&A data using Vertex AI.
**Steps**: prepare JSONL dataset, upload to GCS, launch tuning job, evaluate, deploy
**Key concepts**: vertexai.tuning.sft, GCS, model evaluation
**Hint**: Dataset format: `{"messages":[{"role":"user","content":"Q"},{"role":"model","content":"A"}]}`
**Expected output**: Fine-tuned model endpoint with improved domain-specific accuracy

---

## Project 9 — Real-time Cloud Chat with WebSocket
**Goal**: Real-time streaming chat app backed by any cloud LLM.
**Architecture**: FastAPI WebSocket → Bedrock/Vertex streaming → Frontend
**Features**: model selector (Bedrock/Vertex/Azure), streaming display, session management
**Hint**:
```python
import asyncio
from fastapi import FastAPI, WebSocket
app = FastAPI()
@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    while True:
        data = await ws.receive_text()
        # stream from Bedrock or Vertex
        for chunk in stream_from_bedrock(data):
            await ws.send_text(chunk)
```

---

## Project 10 — Cloud LLM Monitoring Dashboard
**Goal**: Monitor LLM usage, costs, and errors across cloud providers.
**Features**: Streamlit dashboard, real-time metrics, cost alerts, error rate tracking, latency graphs
**Metrics tracked**: requests/min, avg latency, cost/day, error rate, top failure reasons
**Hint**: Store metrics in SQLite with timestamps; use Streamlit's st.metric() and plotly charts for visualization; set email alerts when daily cost exceeds threshold