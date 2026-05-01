# GenAI on AWS, GCP, Azure — Code Examples (20 Examples)

```bash
pip install boto3 google-cloud-aiplatform openai vertexai python-dotenv
```

---

## Example 1 — Bedrock: Claude via InvokeModel
```python
import boto3, json

bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")
MODEL = "anthropic.claude-3-haiku-20240307-v1:0"

def claude_invoke(prompt):
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [{"role":"user","content":prompt}]
    })
    r = bedrock.invoke_model(modelId=MODEL, body=body)
    return json.loads(r["body"].read())["content"][0]["text"]

print(claude_invoke("Explain cloud computing in 3 sentences."))
```

---

## Example 2 — Bedrock: Converse API (Unified)
```python
def bedrock_chat(messages, model="anthropic.claude-3-haiku-20240307-v1:0"):
    r = bedrock.converse(
        modelId=model,
        messages=messages,
        inferenceConfig={"maxTokens":1024,"temperature":0.7}
    )
    return r["output"]["message"]["content"][0]["text"]

msgs = [{"role":"user","content":[{"text":"What is Amazon Bedrock?"}]}]
print(bedrock_chat(msgs))
```

---

## Example 3 — Bedrock: Streaming Claude
```python
def claude_stream(prompt, model="anthropic.claude-3-haiku-20240307-v1:0"):
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 512,
        "messages": [{"role":"user","content":prompt}]
    })
    resp = bedrock.invoke_model_with_response_stream(modelId=model, body=body)
    for event in resp["body"]:
        chunk = json.loads(event["chunk"]["bytes"])
        if chunk.get("type") == "content_block_delta":
            print(chunk["delta"]["text"], end="", flush=True)
    print()

claude_stream("Write a limerick about AWS Lambda.")
```

---

## Example 4 — Bedrock: Llama 3 Inference
```python
def llama3_invoke(prompt, model="meta.llama3-1-70b-instruct-v1:0"):
    formatted = (
        f"<|begin_of_text|><|start_header_id|>user<|end_header_id|>"
        f"\n{prompt}<|eot_id|>"
        f"<|start_header_id|>assistant<|end_header_id|>"
    )
    body = json.dumps({
        "prompt": formatted,
        "max_gen_len": 512,
        "temperature": 0.7,
        "top_p": 0.9
    })
    r = bedrock.invoke_model(modelId=model, body=body)
    return json.loads(r["body"].read())["generation"].strip()

print(llama3_invoke("What are the pros and cons of microservices?"))
```

---

## Example 5 — Bedrock: Stable Diffusion Image Generation
```python
import base64

def generate_image(prompt, model="stability.stable-diffusion-xl-v1"):
    body = json.dumps({
        "text_prompts": [{"text": prompt, "weight": 1.0}],
        "cfg_scale": 7,
        "steps": 30,
        "seed": 42,
        "width": 1024,
        "height": 1024
    })
    r = bedrock.invoke_model(modelId=model, body=body)
    result = json.loads(r["body"].read())
    img_bytes = base64.b64decode(result["artifacts"][0]["base64"])
    with open("generated.png","wb") as f:
        f.write(img_bytes)
    print("Image saved to generated.png")

generate_image("A futuristic city at sunset, photorealistic, 8k")
```

---

## Example 6 — Bedrock: Titan Embeddings
```python
def titan_embed(text, model="amazon.titan-embed-text-v1"):
    body = json.dumps({"inputText": text})
    r = bedrock.invoke_model(modelId=model, body=body,
        contentType="application/json", accept="application/json")
    return json.loads(r["body"].read())["embedding"]

v1 = titan_embed("Machine learning is powerful")
v2 = titan_embed("AI is transforming industries")
import numpy as np
def cosine(a, b):
    a,b = np.array(a), np.array(b)
    return float(np.dot(a,b)/(np.linalg.norm(a)*np.linalg.norm(b)))
print(f"Similarity: {cosine(v1,v2):.4f}")
```

---

## Example 7 — Bedrock: Knowledge Base RAG
```python
def kb_query(question, kb_id, model="anthropic.claude-3-haiku-20240307-v1:0"):
    agent_runtime = boto3.client("bedrock-agent-runtime", region_name="us-east-1")
    r = agent_runtime.retrieve_and_generate(
        input={"text": question},
        retrieveAndGenerateConfiguration={
            "type": "KNOWLEDGE_BASE",
            "knowledgeBaseConfiguration": {
                "knowledgeBaseId": kb_id,
                "modelArn": f"arn:aws:bedrock:us-east-1::foundation-model/{model}"
            }
        }
    )
    return {
        "answer": r["output"]["text"],
        "citations": [c["retrievedReferences"] for c in r.get("citations",[])]
    }

# result = kb_query("What is our return policy?", "your-kb-id")
```

---

## Example 8 — Bedrock: Mistral Inference
```python
def mistral_invoke(prompt, model="mistral.mistral-7b-instruct-v0:2"):
    body = json.dumps({
        "prompt": f"<s>[INST] {prompt} [/INST]",
        "max_tokens": 512,
        "temperature": 0.7
    })
    r = bedrock.invoke_model(modelId=model, body=body)
    return json.loads(r["body"].read())["outputs"][0]["text"]

print(mistral_invoke("What is the difference between SQL and NoSQL?"))
```

---

## Example 9 — GCP Vertex AI: Gemini
```python
import vertexai
from vertexai.generative_models import GenerativeModel

vertexai.init(project="your-project-id", location="us-central1")
model = GenerativeModel("gemini-1.5-flash")

response = model.generate_content("Explain Kubernetes in simple terms.")
print(response.text)
print("Tokens:", response.usage_metadata.total_token_count)
```

---

## Example 10 — Vertex AI: Gemini Multimodal
```python
from vertexai.generative_models import GenerativeModel, Part

model = GenerativeModel("gemini-1.5-pro")

# Use GCS URI for large files
image_part = Part.from_uri("gs://your-bucket/image.jpg", mime_type="image/jpeg")
response = model.generate_content([image_part, "Describe this image in detail."])
print(response.text)
```

---

## Example 11 — Vertex AI: Streaming
```python
model = GenerativeModel("gemini-1.5-flash")
responses = model.generate_content("Write a poem about machine learning.", stream=True)
for chunk in responses:
    print(chunk.text, end="", flush=True)
print()
```

---

## Example 12 — Vertex AI: Embeddings
```python
from vertexai.language_models import TextEmbeddingModel

model = TextEmbeddingModel.from_pretrained("text-embedding-004")
embeddings = model.get_embeddings(["Hello world", "Machine learning is great"])
for i, emb in enumerate(embeddings):
    print(f"Text {i}: vector length={len(emb.values)}")
```

---

## Example 13 — Azure OpenAI: Basic Call
```python
from openai import AzureOpenAI
import os

azure = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_API_KEY"],
    api_version="2024-08-01-preview",
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"]
)

r = azure.chat.completions.create(
    model="gpt4o-deployment",    # Your deployment name in Azure
    messages=[{"role":"user","content":"What is Azure OpenAI Service?"}],
    max_tokens=512
)
print(r.choices[0].message.content)
```

---

## Example 14 — Azure OpenAI: Streaming
```python
stream = azure.chat.completions.create(
    model="gpt4o-deployment",
    messages=[{"role":"user","content":"Write a step-by-step guide to Azure DevOps."}],
    stream=True
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
print()
```

---

## Example 15 — Azure OpenAI: Embeddings
```python
r = azure.embeddings.create(
    model="text-embedding-3-small",   # Your embedding deployment name
    input="Azure OpenAI provides enterprise-grade AI."
)
embedding = r.data[0].embedding
print(f"Embedding dimensions: {len(embedding)}")
```

---

## Example 16 — Azure OpenAI: DALL-E 3
```python
r = azure.images.generate(
    model="dall-e-3",           # Your DALL-E 3 deployment name
    prompt="A cloud infrastructure diagram, minimalist style, blue tones",
    n=1, size="1024x1024", quality="standard"
)
print("Image URL:", r.data[0].url)
```

---

## Example 17 — Multi-Cloud Router
```python
class CloudLLMRouter:
    def __init__(self):
        from openai import OpenAI, AzureOpenAI
        self.oai = OpenAI()
        self.azure = AzureOpenAI(
            api_key=os.environ["AZURE_OPENAI_API_KEY"],
            api_version="2024-08-01-preview",
            azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"])

    def complete(self, prompt, provider="openai", deployment=None):
        msg = [{"role":"user","content":prompt}]
        if provider == "openai":
            r = self.oai.chat.completions.create(model="gpt-4o-mini", messages=msg)
        elif provider == "azure":
            r = self.azure.chat.completions.create(model=deployment or "gpt4o-mini-prod", messages=msg)
        elif provider == "bedrock":
            return claude_invoke(prompt)
        return r.choices[0].message.content

router = CloudLLMRouter()
print(router.complete("What is serverless computing?", provider="azure"))
```

---

## Example 18 — Bedrock: Multi-turn Converse
```python
conversation = []
def bedrock_multiturn(user_text, model="anthropic.claude-3-haiku-20240307-v1:0"):
    conversation.append({"role":"user","content":[{"text":user_text}]})
    r = bedrock.converse(modelId=model, messages=conversation,
        inferenceConfig={"maxTokens":512,"temperature":0.7})
    reply = r["output"]["message"]["content"][0]["text"]
    conversation.append({"role":"assistant","content":[{"text":reply}]})
    return reply

print(bedrock_multiturn("What is EC2?"))
print(bedrock_multiturn("And how does it compare to Lambda?"))
```

---

## Example 19 — Vertex AI: Function Calling
```python
from vertexai.generative_models import GenerativeModel, Tool, FunctionDeclaration

get_weather_fn = FunctionDeclaration(
    name="get_weather",
    description="Get current weather for a city",
    parameters={
        "type": "object",
        "properties": {
            "city": {"type": "string", "description": "City name"}
        },
        "required": ["city"]
    }
)
weather_tool = Tool(function_declarations=[get_weather_fn])
model = GenerativeModel("gemini-1.5-flash", tools=[weather_tool])
response = model.generate_content("What's the weather in London?")
# Check response.candidates[0].content.parts for function_call
```

---

## Example 20 — Cost Tracker
```python
import time

costs = {"input_tokens":0, "output_tokens":0, "requests":0}

def tracked_bedrock_call(prompt, model="anthropic.claude-3-haiku-20240307-v1:0"):
    body = json.dumps({
        "anthropic_version":"bedrock-2023-05-31",
        "max_tokens":512,
        "messages":[{"role":"user","content":prompt}]
    })
    r = bedrock.invoke_model(modelId=model, body=body)
    result = json.loads(r["body"].read())
    # Note: Bedrock returns usage in headers
    costs["requests"] += 1
    print(f"Request #{costs['requests']} completed")
    return result["content"][0]["text"]

# Haiku pricing: $0.25/1M input, $1.25/1M output
def estimate_cost(input_tok, output_tok, model="haiku"):
    rates = {"haiku":(0.25, 1.25), "sonnet":(3.0, 15.0)}
    r = rates.get(model, (0.25, 1.25))
    return (input_tok/1e6)*r[0] + (output_tok/1e6)*r[1]
```