# Generative AI on AWS, GCP, and Azure — Complete Reference

## Table of Contents
**AWS Bedrock**: 1. Overview  2. Available Models  3. Boto3 Setup  4. InvokeModel API
5. Converse API  6. Streaming  7. Knowledge Bases (RAG)  8. Bedrock Agents  9. IAM
**GCP Vertex AI**: 10. Vertex AI GenAI  11. Model Garden  12. Vertex AI Search  13. Tuning
**Azure OpenAI**: 14. Azure vs Direct OpenAI  15. AzureOpenAI Client  16. Deployments
17. Azure OpenAI Studio  18. Responsible AI  19. Multi-cloud Patterns  20. Cost Comparison

---

## 1. AWS Bedrock Overview

Amazon Bedrock is a fully managed service for foundation models.
No GPU management required — pay per API call.

### Key Benefits
- Access to multiple model providers in one API
- Enterprise security (VPC, IAM, PrivateLink)
- No data leaves AWS environment
- Model evaluation and comparison tools
- Fine-tuning (Titan, Claude 3 Haiku, Llama 2)

### Setup
```bash
pip install boto3
aws configure   # set region to us-east-1 or us-west-2
```

---

## 2. AWS Bedrock — Available Models

| Provider   | Models                                      | Strengths                        |
|------------|---------------------------------------------|----------------------------------|
| Anthropic  | Claude 3 (Opus/Sonnet/Haiku), Claude 3.5    | Reasoning, safety, coding        |
| Meta       | Llama 3.1 (8B/70B/405B), Llama 2            | Open, customisable               |
| Amazon     | Titan Text, Titan Embeddings, Nova          | AWS-native, cost-effective        |
| Mistral    | Mistral 7B, Mixtral 8x7B, Large            | Fast, European, multilingual     |
| AI21 Labs  | Jamba                                       | Long context                     |
| Cohere     | Command R, Command R+                       | RAG-optimised                    |
| Stability  | Stable Diffusion XL, SD3                   | Image generation                 |

### Model IDs
```python
CLAUDE_SONNET   = "anthropic.claude-3-5-sonnet-20241022-v2:0"
CLAUDE_HAIKU    = "anthropic.claude-3-haiku-20240307-v1:0"
LLAMA3_70B      = "meta.llama3-1-70b-instruct-v1:0"
TITAN_TEXT      = "amazon.titan-text-express-v1"
MISTRAL_7B      = "mistral.mistral-7b-instruct-v0:2"
SDXL            = "stability.stable-diffusion-xl-v1"
```

---

## 3. Boto3 Bedrock Setup

```python
import boto3, json, os

# Create bedrock-runtime client
bedrock = boto3.client(
    service_name="bedrock-runtime",
    region_name="us-east-1",           # Bedrock not available in all regions
    aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
)

# Or use default credential chain (recommended for production):
# boto3.client("bedrock-runtime", region_name="us-east-1")
# Credentials resolved from: env vars -> ~/.aws/credentials -> EC2 role
```

### Required IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:Retrieve",
      "bedrock:RetrieveAndGenerate"
    ],
    "Resource": "arn:aws:bedrock:us-east-1::foundation-model/*"
  }]
}
```

---

## 4. InvokeModel API

Low-level API — you manually format the request body per model.

### Claude via InvokeModel
```python
def invoke_claude(prompt, model_id=CLAUDE_HAIKU):
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [{"role":"user","content":prompt}]
    })
    response = bedrock.invoke_model(
        modelId=model_id,
        body=body,
        contentType="application/json",
        accept="application/json"
    )
    result = json.loads(response["body"].read())
    return result["content"][0]["text"]

print(invoke_claude("What is the capital of France?"))
```

### Llama 3 via InvokeModel
```python
def invoke_llama3(prompt, model_id=LLAMA3_70B):
    body = json.dumps({
        "prompt": f"<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>",
        "max_gen_len": 512,
        "temperature": 0.7,
        "top_p": 0.9
    })
    response = bedrock.invoke_model(modelId=model_id, body=body)
    return json.loads(response["body"].read())["generation"]
```

---

## 5. Converse API (Unified Interface)

The Converse API provides a consistent interface across ALL Bedrock models.
Recommended for new projects — no model-specific formatting needed.

```python
def bedrock_converse(messages, model_id=CLAUDE_HAIKU, system="You are helpful."):
    response = bedrock.converse(
        modelId=model_id,
        system=[{"text": system}],
        messages=messages,
        inferenceConfig={
            "maxTokens": 1024,
            "temperature": 0.7,
            "topP": 0.9
        }
    )
    return response["output"]["message"]["content"][0]["text"]

messages = [{"role":"user","content":[{"text":"Explain quantum entanglement."}]}]
print(bedrock_converse(messages))
```

### Multi-turn with Converse
```python
conversation = []
def chat(user_text, model_id=CLAUDE_HAIKU):
    conversation.append({"role":"user","content":[{"text":user_text}]})
    r = bedrock.converse(modelId=model_id, messages=conversation,
        inferenceConfig={"maxTokens":512,"temperature":0.7})
    reply = r["output"]["message"]["content"][0]["text"]
    conversation.append({"role":"assistant","content":[{"text":reply}]})
    return reply
```

---

## 6. Streaming with Bedrock

```python
def invoke_claude_stream(prompt, model_id=CLAUDE_HAIKU):
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [{"role":"user","content":prompt}]
    })
    response = bedrock.invoke_model_with_response_stream(
        modelId=model_id, body=body
    )
    for event in response["body"]:
        chunk = json.loads(event["chunk"]["bytes"])
        if chunk.get("type") == "content_block_delta":
            print(chunk["delta"]["text"], end="", flush=True)
    print()

invoke_claude_stream("Write a haiku about cloud computing.")
```

---

## 7. Knowledge Bases — Managed RAG

Bedrock Knowledge Bases = fully managed RAG (S3 → chunking → embeddings → vector store).

```python
bedrock_agent_runtime = boto3.client("bedrock-agent-runtime", region_name="us-east-1")

def query_knowledge_base(question, kb_id, model_id=CLAUDE_HAIKU):
    response = bedrock_agent_runtime.retrieve_and_generate(
        input={"text": question},
        retrieveAndGenerateConfiguration={
            "type": "KNOWLEDGE_BASE",
            "knowledgeBaseConfiguration": {
                "knowledgeBaseId": kb_id,
                "modelArn": f"arn:aws:bedrock:us-east-1::foundation-model/{model_id}"
            }
        }
    )
    return {
        "answer": response["output"]["text"],
        "citations": response.get("citations", [])
    }

result = query_knowledge_base("What is our refund policy?", "kb-XXXXXX")
print(result["answer"])
```

---

## 8. Bedrock Agents

Intelligent agents that can plan and execute multi-step tasks using tools.

```python
def invoke_bedrock_agent(user_input, agent_id, agent_alias_id, session_id):
    response = bedrock_agent_runtime.invoke_agent(
        agentId=agent_id,
        agentAliasId=agent_alias_id,
        sessionId=session_id,
        inputText=user_input
    )
    result = ""
    for event in response["completion"]:
        if "chunk" in event:
            result += event["chunk"]["bytes"].decode()
    return result
```

---

## 9. AWS IAM Permissions

Required policies for Bedrock usage:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockFullAccess",
      "Effect": "Allow",
      "Action": ["bedrock:*"],
      "Resource": "*"
    },
    {
      "Sid": "S3ForKnowledgeBase",
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:ListBucket"],
      "Resource": ["arn:aws:s3:::my-kb-bucket/*"]
    }
  ]
}
```

---

## 10. GCP Vertex AI — Gemini

```bash
pip install google-cloud-aiplatform
gcloud auth application-default login
```

```python
import vertexai
from vertexai.generative_models import GenerativeModel, Part

vertexai.init(project="your-gcp-project", location="us-central1")
model = GenerativeModel("gemini-1.5-flash")

response = model.generate_content("Explain transformer architecture.")
print(response.text)
print("Tokens:", response.usage_metadata.total_token_count)
```

---

## 11. Vertex AI Model Garden

Model Garden offers 150+ models including Llama, Mistral, and custom open models.

```python
# Access Llama 3 via Vertex AI Model Garden
from vertexai.preview.language_models import TextGenerationModel

# Deploy an endpoint first from Vertex AI console, then:
from google.cloud import aiplatform
endpoint = aiplatform.Endpoint(endpoint_name="projects/.../endpoints/...")
response = endpoint.predict(
    instances=[{"prompt": "What is machine learning?"}],
    parameters={"temperature": 0.7, "maxOutputTokens": 512}
)
print(response.predictions[0])
```

---

## 12. Vertex AI Search (Managed RAG)

```python
from google.cloud import discoveryengine_v1 as discoveryengine

def vertex_search(query, project_id, location, data_store_id):
    client = discoveryengine.SearchServiceClient()
    serving_config = (
        f"projects/{project_id}/locations/{location}/"
        f"dataStores/{data_store_id}/servingConfigs/default_config"
    )
    request = discoveryengine.SearchRequest(
        serving_config=serving_config,
        query=query,
        page_size=5
    )
    response = client.search(request)
    results = []
    for r in response.results:
        doc = r.document.derived_struct_data
        results.append({"title": doc.get("title",""), "snippet": doc.get("snippets","")})
    return results
```

---

## 13. Vertex AI Model Tuning

```python
from vertexai.tuning import sft   # Supervised Fine-Tuning

tuning_job = sft.train(
    source_model="gemini-1.5-flash-001",
    train_dataset="gs://your-bucket/train.jsonl",
    validation_dataset="gs://your-bucket/val.jsonl",
    epochs=3,
    learning_rate_multiplier=1.0,
    tuned_model_display_name="my-fine-tuned-model"
)
tuning_job.wait()
print("Tuned model:", tuning_job.tuned_model_name)
```

---

## 14. Azure OpenAI vs Direct OpenAI

| Feature              | OpenAI Direct          | Azure OpenAI              |
|----------------------|------------------------|---------------------------|
| Authentication       | API key                | API key + endpoint URL    |
| Model naming         | gpt-4o, gpt-4o-mini    | Custom deployment name    |
| Data residency       | OpenAI servers         | Your Azure region         |
| Compliance           | Limited                | SOC2, HIPAA, PCI DSS      |
| Content filtering    | OpenAI moderation      | Azure Responsible AI      |
| Fine-tuning          | Yes                    | Yes (same models)         |
| Pricing              | Standard               | Same + Azure commitment   |
| SLA                  | No SLA                 | 99.9% SLA                 |

---

## 15. AzureOpenAI Client

```bash
pip install openai
```

```python
from openai import AzureOpenAI
import os

azure_client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_API_KEY"],
    api_version="2024-08-01-preview",
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    # e.g. https://your-resource.openai.azure.com/
)

response = azure_client.chat.completions.create(
    model="gpt-4o",   # This is the DEPLOYMENT NAME, not the model name!
    messages=[{"role":"user","content":"What is Azure OpenAI?"}]
)
print(response.choices[0].message.content)
```

---

## 16. Azure Deployments vs Model Names

In Azure OpenAI, you create **deployments** with custom names:
- You deploy "gpt-4o" model as deployment name "my-gpt4o-prod"
- You use "my-gpt4o-prod" as the `model` parameter in API calls

```python
# Manage deployments via Azure CLI
# az cognitiveservices account deployment create \
#   --name your-resource \
#   --resource-group your-rg \
#   --deployment-name gpt4o-prod \
#   --model-name gpt-4o \
#   --model-version 2024-08-06

response = azure_client.chat.completions.create(
    model="gpt4o-prod",    # Your deployment name
    messages=[...]
)
```

---

## 17. Azure OpenAI Studio

Azure AI Studio (https://ai.azure.com):
- Create and manage deployments
- Playground for testing prompts
- Fine-tuning interface
- Evaluation tools
- Prompt Flow for LLM orchestration

---

## 18. Azure Responsible AI Content Filters

```python
# Content filters are applied automatically
# Custom filter policy can be configured in Azure portal
# Categories: hate, sexual, violence, self-harm (4 levels each)

try:
    response = azure_client.chat.completions.create(
        model="gpt4o-prod",
        messages=[{"role":"user","content":"..."}]
    )
    print(response.choices[0].message.content)
except Exception as e:
    if "content_filter" in str(e).lower():
        print("Content blocked by Azure Responsible AI filter")
    else:
        raise
```

---

## 19. Multi-cloud LLM Router Pattern

Route requests to different providers based on task type and cost.

```python
class LLMRouter:
    def __init__(self):
        from openai import OpenAI, AzureOpenAI
        import boto3
        self.openai = OpenAI()
        self.azure = AzureOpenAI(...)
        self.bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

    def route(self, task_type, prompt, messages):
        if task_type == "reasoning":
            # DeepSeek R1 for complex reasoning
            return self._deepseek(messages)
        elif task_type == "vision":
            return self._openai_vision(messages)
        elif task_type == "document":
            return self._gemini(messages)    # 2M context
        elif task_type == "enterprise":
            return self._azure(messages)     # compliance requirement
        else:
            return self._bedrock_claude(messages)  # default
```

---

## 20. Cost Comparison

| Provider         | Model               | Input/1M  | Output/1M |
|------------------|---------------------|-----------|-----------|
| AWS Bedrock      | Claude 3 Haiku      | $0.25     | $1.25     |
| AWS Bedrock      | Claude 3.5 Sonnet   | $3.00     | $15.00    |
| AWS Bedrock      | Llama 3.1 70B       | $0.72     | $0.72     |
| GCP Vertex AI    | Gemini 1.5 Flash    | $0.075    | $0.30     |
| GCP Vertex AI    | Gemini 1.5 Pro      | $1.25     | $5.00     |
| Azure OpenAI     | GPT-4o              | $2.50     | $10.00    |
| Azure OpenAI     | GPT-4o-mini         | $0.165    | $0.66     |
| Direct OpenAI    | GPT-4o              | $2.50     | $10.00    |

*Prices approximate as of early 2025. Always check current pricing.*