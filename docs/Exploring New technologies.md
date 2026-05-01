# Exploring New Technologies — Ultimate 360° Reference Guide
> **Date:** March 2026 | **Audience:** Senior Engineers & Architects | **Stack:** Java 17, Spring Boot 3, Node.js 22, TypeScript 5, React 18

---

## Table of Contents

1. [Ways to Interact with AI — The Full Landscape](#1-ways-to-interact-with-ai)
2. [MCP Servers — Model Context Protocol](#2-mcp-servers)
3. [Spring AI — Universal AI Integration Layer](#3-spring-ai)
4. [OpenAI / Azure OpenAI SDK](#4-openai--azure-openai-sdk)
5. [Google Gemini SDK](#5-google-gemini-sdk)
6. [Amazon Bedrock SDK](#6-amazon-bedrock-sdk)
7. [Anthropic Claude & Claude Agents](#7-anthropic-claude--claude-agents)
8. [Agentic Multi-Agent Workflows](#8-agentic-multi-agent-workflows)
9. [LangChain4J (Java)](#9-langchain4j-java)
10. [LangChain (Python/JS)](#10-langchain-pythonjs)
11. [LangGraph — Stateful Agent Graphs](#11-langgraph)
12. [Building Custom MCP Servers](#12-building-custom-mcp-servers)
13. [WebSocket Programming](#13-websocket-programming)
14. [Duplex / Bidirectional Systems](#14-duplex--bidirectional-systems)
15. [Real-Time Chat Applications](#15-real-time-chat-applications)
16. [Webhooks & Event-Driven Integration](#16-webhooks--event-driven-integration)
17. [Reactive Programming](#17-reactive-programming)
18. [GraphQL](#18-graphql)
19. [gRPC](#19-grpc)
20. [Notification Systems & Push Webhooks](#20-notification-systems--push-webhooks)
21. [Advanced UI / UFX Frontend Layout](#21-advanced-ui--ufx-frontend-layout)
22. [Figma — Design to Code Workflows](#22-figma--design-to-code-workflows)
23. [AI Agent Automation Use Cases](#23-ai-agent-automation-use-cases)
24. [Architecture Patterns Summary](#24-architecture-patterns-summary)

---

## 1. Ways to Interact with AI

### The Full Interaction Landscape

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI Interaction Modes                         │
├─────────────────┬───────────────────┬───────────────────────────┤
│  Direct API     │  Agent Frameworks │  Protocol-Based           │
│  ─────────────  │  ───────────────  │  ─────────────────────    │
│  REST calls     │  LangChain        │  MCP (Model Context       │
│  SDK clients    │  LangGraph        │    Protocol)              │
│  Chat UI        │  LangChain4J      │  OpenAI Function Calling  │
│  Prompt APIs    │  CrewAI           │  Tool Use / Actions       │
├─────────────────┼───────────────────┼───────────────────────────┤
│  Embedded       │  Event-Driven     │  Multimodal               │
│  ─────────────  │  ───────────────  │  ─────────────────────    │
│  Spring AI      │  Webhook triggers │  Text + Image             │
│  Amazon Bedrock │  Kafka → AI       │  Text + Audio             │
│  Azure OpenAI   │  WebSocket AI     │  Text + Video             │
│  Vertex AI      │  Streaming SSE    │  Text + Documents         │
└─────────────────┴───────────────────┴───────────────────────────┘
```

### When to Use Which Approach

| Use Case | Best Approach |
|---|---|
| Simple Q&A chatbot | Direct REST API + streaming SSE |
| Document analysis pipeline | LangChain4J / LangChain with RAG |
| Autonomous task completion | Multi-agent workflow (LangGraph) |
| IDE / editor assistant | MCP Server |
| Enterprise Java app | Spring AI |
| AWS-native app | Amazon Bedrock SDK |
| Azure-native app | Azure OpenAI SDK |
| Real-time collaborative AI | WebSocket + streaming |
| High-throughput AI microservice | gRPC streaming |

---

## 2. MCP Servers

### What is MCP?
The **Model Context Protocol** (MCP) is an open standard by Anthropic that lets AI models interact with external tools, databases, and services through a defined JSON-RPC-style protocol over STDIO or SSE transport.

### Architecture

```
┌─────────────┐     MCP Protocol      ┌─────────────────────┐
│  AI Model   │ ◄──────────────────── │   MCP Server        │
│  (Claude,   │  ListTools request    │                     │
│   Copilot,  │  CallTool request     │  - Tool definitions │
│   Cursor)   │  Resource reads       │  - Business logic   │
└─────────────┘                       │  - External APIs    │
                                      └─────────────────────┘
```

### MCP Server — TypeScript (Node.js / STDIO)

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { ListToolsRequestSchema, CallToolRequestSchema } from "@modelcontextprotocol/sdk/types.js";

const server = new Server(
    { name: "payment-mcp-server", version: "1.0.0" },
    { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [{
        name: "get_transaction_status",
        description: "Get the status of a payment transaction",
        inputSchema: {
            type: "object",
            properties: {
                transactionId: { type: "string", description: "Transaction ID" }
            },
            required: ["transactionId"]
        }
    }]
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
    if (request.params.name === "get_transaction_status") {
        const { transactionId } = request.params.arguments as { transactionId: string };
        const status = await fetchTransactionStatus(transactionId);
        return { content: [{ type: "text", text: JSON.stringify(status) }] };
    }
    throw new Error(`Unknown tool: ${request.params.name}`);
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

### MCP Client Config (Claude Desktop / VS Code / Cursor)
```json
{
  "mcpServers": {
    "payment-server": {
      "command": "node",
      "args": ["build/payment-server.js"],
      "env": { "PAYMENT_API_URL": "https://api.payment.com" }
    }
  }
}
```

---

## 3. Spring AI

### What is Spring AI?
Spring AI is the official Spring Framework integration for AI models. It provides a **unified abstraction** over OpenAI, Azure OpenAI, Anthropic, Google Vertex AI, Amazon Bedrock, Ollama, and more — all behind the same `ChatClient` API.

### Maven BOM
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.ai</groupId>
            <artifactId>spring-ai-bom</artifactId>
            <version>1.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>org.springframework.ai</groupId>
        <artifactId>spring-ai-openai-spring-boot-starter</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.ai</groupId>
        <artifactId>spring-ai-anthropic-spring-boot-starter</artifactId>
    </dependency>
    <!-- PGVector for RAG -->
    <dependency>
        <groupId>org.springframework.ai</groupId>
        <artifactId>spring-ai-pgvector-store-spring-boot-starter</artifactId>
    </dependency>
</dependencies>
```

### Simple Chat + Streaming
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;

/**
 * Facade over Spring AI ChatClient for Mastercard AI assistant features.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiAssistantService {

    private final ChatClient chatClient;

    /**
     * One-shot conversation.
     *
     * @param userMessage the user's input
     * @return AI-generated response
     */
    public String chat(String userMessage) {
        return chatClient.prompt()
            .user(userMessage)
            .call()
            .content();
    }

    /**
     * Streaming response — suitable for WebSocket or SSE delivery.
     *
     * @param userMessage the user's input
     * @return reactive stream of response tokens
     */
    public Flux<String> streamChat(String userMessage) {
        return chatClient.prompt()
            .user(userMessage)
            .stream()
            .content();
    }
}
```

### ChatClient Bean with System Prompt and Memory
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.config;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.client.advisor.SimpleLoggerAdvisor;
import org.springframework.ai.chat.memory.InMemoryChatMemory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Spring AI ChatClient configuration with system prompt and conversational memory.
 */
@Configuration
public class ChatClientConfig {

    @Bean
    public ChatClient chatClient(ChatClient.Builder builder) {
        return builder
            .defaultSystem("""
                You are an expert Mastercard payment processing assistant.
                Always respond in a professional, concise manner.
                Never reveal PAN, CVV, or any PCI-sensitive data.
                """)
            .defaultAdvisors(
                new MessageChatMemoryAdvisor(new InMemoryChatMemory()),
                new SimpleLoggerAdvisor()
            )
            .build();
    }
}
```

### RAG (Retrieval-Augmented Generation)
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.QuestionAnswerAdvisor;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

/**
 * Document Q&A service using RAG — retrieves relevant context before
 * sending to the LLM, grounding responses in real documents.
 */
@Service
@RequiredArgsConstructor
public class DocumentQaService {

    private final ChatClient chatClient;
    private final VectorStore vectorStore;

    /**
     * Answers a question using retrieved context from the vector store.
     *
     * @param question the user question
     * @return grounded answer from the LLM
     */
    public String answerWithContext(String question) {
        return chatClient.prompt()
            .advisors(new QuestionAnswerAdvisor(vectorStore,
                SearchRequest.defaults().withTopK(5)))
            .user(question)
            .call()
            .content();
    }
}
```

### application.yml — Spring AI
```yaml
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY}
      chat:
        options:
          model: gpt-4o
          temperature: 0.7
          max-tokens: 2048
    anthropic:
      api-key: ${ANTHROPIC_API_KEY}
      chat:
        options:
          model: claude-3-5-sonnet-20241022
```

---

## 4. OpenAI / Azure OpenAI SDK

### Java — Official OpenAI SDK
```xml
<dependency>
    <groupId>com.openai</groupId>
    <artifactId>openai-java</artifactId>
    <version>2.1.0</version>
</dependency>
```

```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.service;

import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;
import java.util.function.Consumer;

/**
 * Direct OpenAI SDK integration with tool calling and streaming support.
 */
@Service
@Slf4j
public class OpenAiService {

    private final OpenAIClient client;

    public OpenAiService(@Value("${openai.api-key}") String apiKey) {
        this.client = OpenAIOkHttpClient.builder()
            .apiKey(apiKey)
            .build();
    }

    /**
     * Chat with tool/function calling.
     *
     * @param userMessage the user prompt
     * @return model response text
     */
    public String chatWithTools(String userMessage) {
        ChatCompletionCreateParams params = ChatCompletionCreateParams.builder()
            .model(ChatModel.GPT_4O)
            .addUserMessage(userMessage)
            .addTool(ChatCompletionTool.builder()
                .function(FunctionDefinition.builder()
                    .name("get_payment_status")
                    .description("Get payment transaction status by ID")
                    .build())
                .build())
            .build();

        ChatCompletion completion = client.chat().completions().create(params);
        return completion.choices().get(0).message().content().orElse("");
    }

    /**
     * Streaming chat — delivers tokens as they arrive.
     *
     * @param message      the prompt
     * @param tokenConsumer callback receiving each token
     */
    public void streamChat(String message, Consumer<String> tokenConsumer) {
        client.chat().completions()
            .createStreaming(ChatCompletionCreateParams.builder()
                .model(ChatModel.GPT_4O)
                .addUserMessage(message)
                .build())
            .stream()
            .forEach(chunk -> chunk.choices().stream()
                .map(c -> c.delta().content())
                .filter(java.util.Optional::isPresent)
                .map(java.util.Optional::get)
                .forEach(tokenConsumer));
    }
}
```

### Azure OpenAI — application.yml
```yaml
spring:
  ai:
    azure:
      openai:
        endpoint: ${AZURE_OPENAI_ENDPOINT}
        api-key:  ${AZURE_OPENAI_KEY}
        chat:
          options:
            deployment-name: gpt-4o
```

---

## 5. Google Gemini SDK

### Spring AI + Vertex AI Gemini
```yaml
spring:
  ai:
    vertex:
      ai:
        gemini:
          project-id: ${GCP_PROJECT_ID}
          location: us-central1
          chat:
            options:
              model: gemini-1.5-pro
```

```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import org.springframework.util.MimeTypeUtils;

/**
 * Multimodal AI service using Google Gemini via Spring AI.
 * Supports text + image analysis for document processing.
 */
@Service
public class GeminiService {

    private final ChatClient chatClient;

    public GeminiService(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    /**
     * Analyse an image alongside a text prompt (multimodal).
     *
     * @param imageBytes JPEG image bytes
     * @param prompt     text instruction for the model
     * @return analysis result
     */
    public String analyzeImage(byte[] imageBytes, String prompt) {
        return chatClient.prompt()
            .user(u -> u.text(prompt)
                .media(MimeTypeUtils.IMAGE_JPEG, imageBytes))
            .call()
            .content();
    }
}
```

### Node.js — Google AI SDK
```typescript
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

async function analyzeDocument(text: string): Promise<string> {
    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-pro",
        generationConfig: { temperature: 0.4, maxOutputTokens: 2048 },
    });
    const result = await model.generateContent(text);
    return result.response.text();
}

// Streaming
async function streamResponse(prompt: string): Promise<void> {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const result = await model.generateContentStream(prompt);
    for await (const chunk of result.stream) {
        process.stdout.write(chunk.text());
    }
}
```

---

## 6. Amazon Bedrock SDK

### Maven
```xml
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>bedrockruntime</artifactId>
    <version>2.29.0</version>
</dependency>
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-bedrock-converse-spring-boot-starter</artifactId>
</dependency>
```

### Direct Bedrock Client (Java)
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.service;

import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.bedrockruntime.BedrockRuntimeClient;
import software.amazon.awssdk.services.bedrockruntime.model.InvokeModelResponse;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

/**
 * Amazon Bedrock integration — invokes foundation models hosted on AWS.
 * Supports Claude, Titan, Llama, and other Bedrock-hosted models.
 */
@Service
@Slf4j
public class BedrockService {

    private static final String CLAUDE_MODEL_ID =
        "anthropic.claude-3-5-sonnet-20241022-v2:0";

    private final BedrockRuntimeClient bedrockClient;

    public BedrockService() {
        this.bedrockClient = BedrockRuntimeClient.builder()
            .region(Region.US_EAST_1)
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build();
    }

    /**
     * Invoke Claude 3.5 Sonnet on Amazon Bedrock.
     *
     * @param userMessage the prompt
     * @return model response text
     */
    public String invokeClaudeOnBedrock(String userMessage) {
        String requestBody = """
            {
              "anthropic_version": "bedrock-2023-05-31",
              "max_tokens": 1024,
              "messages": [{"role": "user", "content": "%s"}]
            }
            """.formatted(userMessage);

        InvokeModelResponse response = bedrockClient.invokeModel(req -> req
            .modelId(CLAUDE_MODEL_ID)
            .body(SdkBytes.fromUtf8String(requestBody))
            .contentType("application/json")
            .accept("application/json"));

        // Parse response — content[0].text path in Anthropic response schema
        return parseBedrockResponse(response.body().asByteArray());
    }
}
```

### Spring AI + Bedrock Config
```yaml
spring:
  ai:
    bedrock:
      aws:
        region:     us-east-1
        access-key: ${AWS_ACCESS_KEY_ID}
        secret-key: ${AWS_SECRET_ACCESS_KEY}
      converse:
        chat:
          options:
            model: anthropic.claude-3-5-sonnet-20241022-v2:0
```

---

## 7. Anthropic Claude & Claude Agents

### Java — Anthropic SDK
```xml
<dependency>
    <groupId>com.anthropic</groupId>
    <artifactId>sdk</artifactId>
    <version>1.2.0</version>
</dependency>
```

```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.service;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.models.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;

/**
 * Anthropic Claude agent — runs an agentic loop with tool use until
 * the model signals end-of-turn without pending tool calls.
 */
@Service
public class ClaudeAgentService {

    private final AnthropicClient client;

    public ClaudeAgentService(@Value("${anthropic.api-key}") String apiKey) {
        this.client = AnthropicOkHttpClient.builder()
            .apiKey(apiKey)
            .build();
    }

    /**
     * Agentic loop — keeps running until Claude stops calling tools.
     *
     * @param task  the task description
     * @param tools tools available to Claude
     * @return final text response from Claude
     */
    public String agentLoop(String task, List<Tool> tools) {
        List<MessageParam> messages = new ArrayList<>();
        messages.add(MessageParam.builder()
            .role(MessageParam.Role.USER)
            .content(task)
            .build());

        while (true) {
            Message response = client.messages().create(
                MessageCreateParams.builder()
                    .model(Model.CLAUDE_3_5_SONNET_20241022)
                    .maxTokens(4096)
                    .tools(tools)
                    .messages(messages)
                    .build());

            if (response.stopReason() == StopReason.TOOL_USE) {
                ToolUseBlock toolUse = extractToolUse(response);
                String toolResult = executeTool(toolUse);

                messages.add(MessageParam.builder()
                    .role(MessageParam.Role.ASSISTANT)
                    .content(response.content())
                    .build());
                messages.add(MessageParam.builder()
                    .role(MessageParam.Role.USER)
                    .content(List.of(ToolResultBlockParam.builder()
                        .toolUseId(toolUse.id())
                        .content(toolResult)
                        .build()))
                    .build());
                continue;
            }

            return extractText(response);
        }
    }
}
```

---

## 8. Agentic Multi-Agent Workflows

### Architecture Patterns

```
┌──────────────────────────────────────────────────────────┐
│                  Multi-Agent Patterns                    │
├────────────────────┬─────────────────────────────────────┤
│  Orchestrator      │  Supervisor → Specialists           │
│  ─────────────     │  ─────────────────────────────────  │
│  Routes tasks to   │  Supervisor Agent                   │
│  specialist agents │    ├── Research Agent               │
│                    │    ├── Code Agent                   │
│                    │    ├── Review Agent                 │
│                    │    └── Deploy Agent                 │
├────────────────────┼─────────────────────────────────────┤
│  Pipeline          │  Debate / Critique                  │
│  ─────────────     │  ─────────────────                  │
│  A → B → C         │  Agent A proposes                   │
│  (sequential)      │  Agent B critiques                  │
│                    │  Agent A refines                    │
└────────────────────┴─────────────────────────────────────┘
```

### Java Multi-Agent Pipeline with Spring AI
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.agent;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

/**
 * Orchestrates a three-agent code generation pipeline:
 * 1. Research Agent — analyses requirements
 * 2. Code Agent    — generates implementation
 * 3. Review Agent  — validates and critiques
 */
@Service
@Slf4j
public class CodeGenerationOrchestrator {

    private final ChatClient researchAgent;
    private final ChatClient codeAgent;
    private final ChatClient reviewAgent;

    /**
     * Run the full pipeline against a requirement description.
     *
     * @param requirement plain-English requirement
     * @return aggregated result containing analysis, code, and review
     */
    public AgentPipelineResult run(String requirement) {
        String analysis = researchAgent.prompt()
            .system("You are an expert software architect. Analyse requirements.")
            .user(requirement)
            .call()
            .content();

        String generatedCode = codeAgent.prompt()
            .system("You are a Java 17 Spring Boot expert. Write clean, tested code.")
            .user("Analysis:\n" + analysis + "\n\nGenerate the implementation.")
            .call()
            .content();

        String review = reviewAgent.prompt()
            .system("You are a senior code reviewer. Check for bugs, security issues, and SOLID violations.")
            .user("Review this code:\n" + generatedCode)
            .call()
            .content();

        return new AgentPipelineResult(analysis, generatedCode, review);
    }
}
```

---

## 9. LangChain4J (Java)

### What is LangChain4J?
LangChain4J is the Java port of LangChain. It provides AI service interfaces, RAG pipelines, conversational memory, and tool integration — all idiomatic Java with annotation-driven configuration.

### Maven
```xml
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-open-ai-spring-boot-starter</artifactId>
    <version>0.36.0</version>
</dependency>
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-spring-boot-starter</artifactId>
    <version>0.36.0</version>
</dependency>
```

### AI Service Interface (annotation-driven)
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.service;

import dev.langchain4j.service.AiService;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;

/**
 * LangChain4J AI service — implementation is generated at runtime.
 * The framework wires the LLM, memory, and tools automatically.
 */
@AiService
public interface PaymentAssistant {

    @SystemMessage("""
        You are a Mastercard payment processing expert.
        Always cite the specific transaction ID in your responses.
        Never reveal PAN or CVV data.
        """)
    String answer(String question);

    @SystemMessage("You are a fraud detection specialist.")
    @UserMessage("Analyse this transaction for fraud risk: {{transaction}}")
    String analyseForFraud(@V("transaction") String transactionJson);
}
```

### Configuration Bean
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.config;

import dev.langchain4j.memory.ChatMemory;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import com.mastercard.pgs.connectivity.acquirer.ai.service.PaymentAssistant;
import com.mastercard.pgs.connectivity.acquirer.ai.tools.PaymentTools;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import lombok.RequiredArgsConstructor;

/**
 * Wires the LangChain4J PaymentAssistant with memory and tools.
 */
@Configuration
@RequiredArgsConstructor
public class LangChain4jConfig {

    private final ChatLanguageModel chatModel;

    @Bean
    public PaymentAssistant paymentAssistant(PaymentTools tools) {
        return AiServices.builder(PaymentAssistant.class)
            .chatLanguageModel(chatModel)
            .chatMemory(MessageWindowChatMemory.withMaxMessages(20))
            .tools(tools)
            .build();
    }
}
```

### Tools (Function Calling)
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.tools;

import dev.langchain4j.agent.tool.Tool;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;
import java.time.LocalDate;
import java.util.List;

/**
 * LangChain4J tool implementations — discovered via @Tool annotation.
 * The framework automatically calls these when the LLM requests them.
 */
@Component
@RequiredArgsConstructor
public class PaymentTools {

    private final PaymentService paymentService;

    /** @return transaction status for the given ID */
    @Tool("Look up the status of a payment transaction by its ID")
    public TransactionStatus getTransactionStatus(String transactionId) {
        return paymentService.findById(transactionId)
            .orElseThrow(() -> new IllegalArgumentException(
                "Transaction not found: " + transactionId));
    }

    /** @return list of transactions matching the search criteria */
    @Tool("Search transactions by merchant ID and date range")
    public List<Transaction> searchTransactions(
            String merchantId, LocalDate from, LocalDate to) {
        return paymentService.search(merchantId, from, to);
    }
}
```

---

## 10. LangChain (Python/JS)

### Python — RAG Pipeline
```python
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import PGVector
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
import os

llm = ChatOpenAI(model="gpt-4o", temperature=0)

vectorstore = PGVector.from_existing_index(
    embedding=OpenAIEmbeddings(),
    collection_name="payment_docs",
    connection_string=os.getenv("DATABASE_URL")
)

PROMPT = PromptTemplate(
    template="""You are a payment processing expert.
Use the context below. If unsure, say so — never guess.

Context: {context}
Question: {question}
Answer:""",
    input_variables=["context", "question"]
)

qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vectorstore.as_retriever(search_kwargs={"k": 5}),
    chain_type_kwargs={"prompt": PROMPT},
    return_source_documents=True
)

result = qa_chain.invoke({"query": "What is the chargeback process for Visa?"})
print(result["result"])
```

### TypeScript — LangChain.js
```typescript
import { ChatOpenAI } from "@langchain/openai";
import { createRetrievalChain } from "langchain/chains/retrieval";
import { createStuffDocumentsChain } from "langchain/chains/combine_documents";
import { ChatPromptTemplate } from "@langchain/core/prompts";

const llm = new ChatOpenAI({ model: "gpt-4o", temperature: 0 });

const prompt = ChatPromptTemplate.fromTemplate(`
Answer based on the context below.
Context: {context}
Question: {input}
`);

const documentChain = await createStuffDocumentsChain({ llm, prompt });
const retrievalChain = await createRetrievalChain({
    combineDocsChain: documentChain,
    retriever: vectorStore.asRetriever({ k: 5 }),
});

const result = await retrievalChain.invoke({
    input: "Explain the 3DS authentication flow",
});
console.log(result.answer);
```

---

## 11. LangGraph

### What is LangGraph?
LangGraph builds **stateful, cyclic agent workflows** as directed graphs. Unlike linear chains, it supports loops, conditional branching, and human-in-the-loop interrupts.

```
State ──► Node A ──► Conditional Edge ──► Node B  (if condition true)
  ▲                         │             └──► Node C (otherwise)
  └──────── Loop back ───────┘
```

### Python — Agentic Loop
```python
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
from typing import TypedDict, Annotated
import operator

class AgentState(TypedDict):
    messages:   Annotated[list, operator.add]
    iterations: int

llm = ChatOpenAI(model="gpt-4o").bind_tools(tools)

def agent_node(state: AgentState) -> AgentState:
    response = llm.invoke(state["messages"])
    return {"messages": [response], "iterations": state["iterations"] + 1}

def should_continue(state: AgentState) -> str:
    last = state["messages"][-1]
    if hasattr(last, "tool_calls") and last.tool_calls:
        return "tools"
    return "end"

workflow = StateGraph(AgentState)
workflow.add_node("agent", agent_node)
workflow.add_node("tools", ToolNode(tools))
workflow.set_entry_point("agent")
workflow.add_conditional_edges("agent", should_continue,
    {"tools": "tools", "end": END})
workflow.add_edge("tools", "agent")   # loop back after tool execution

app = workflow.compile()

result = app.invoke({
    "messages": [HumanMessage(content="Analyse all high-value transactions from last 7 days")],
    "iterations": 0
})
```

### Human-in-the-Loop
```python
from langgraph.checkpoint.memory import MemorySaver

memory = MemorySaver()
app = workflow.compile(checkpointer=memory,
                       interrupt_before=["execute_payment"])

config = {"configurable": {"thread_id": "txn-001"}}
state = app.invoke(initial_state, config)   # pauses at execute_payment

# Human reviews and resumes
app.invoke(None, config)
```

---

## 12. Building Custom MCP Servers

### Spring Boot MCP Server (Java)
```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-mcp-server-spring-boot-starter</artifactId>
</dependency>
```

```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.mcp;

import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;
import java.time.LocalDate;
import java.util.List;

/**
 * MCP tool definitions — Spring AI auto-registers these with the MCP server.
 * Each @Tool method becomes a callable tool exposed to AI models via MCP protocol.
 */
@Component
@RequiredArgsConstructor
public class PaymentMcpTools {

    private final PaymentService paymentService;

    @Tool(description = "Search payment transactions by merchant ID and date range")
    public List<TransactionSummary> searchTransactions(
            @ToolParam(description = "Merchant ID")          String merchantId,
            @ToolParam(description = "Start date ISO 8601")  String startDate,
            @ToolParam(description = "End date ISO 8601")    String endDate) {
        return paymentService.search(merchantId,
            LocalDate.parse(startDate), LocalDate.parse(endDate));
    }

    @Tool(description = "Get current fraud risk score for a transaction")
    public FraudScore getFraudScore(
            @ToolParam(description = "Transaction ID") String transactionId) {
        return paymentService.calculateFraudScore(transactionId);
    }
}
```

```yaml
# application.yml
spring:
  ai:
    mcp:
      server:
        name: payment-mcp-server
        version: 1.0.0
        type: STDIO      # STDIO for desktop clients, SSE for HTTP
```

### TypeScript MCP Server with SSE Transport
```typescript
import express from "express";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { ListToolsRequestSchema, CallToolRequestSchema } from "@modelcontextprotocol/sdk/types.js";

const app = express();
const mcpServer = new Server(
    { name: "analytics-mcp", version: "1.0.0" },
    { capabilities: { tools: {}, resources: {} } }
);

mcpServer.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
        {
            name: "query_analytics",
            description: "Run an analytics query and return aggregated results",
            inputSchema: {
                type: "object",
                properties: {
                    metric:    { type: "string", enum: ["revenue", "volume", "fraud_rate"] },
                    period:    { type: "string", description: "ISO 8601 period (e.g. P7D)" },
                    groupBy:   { type: "string", enum: ["merchant", "region", "currency"] }
                },
                required: ["metric", "period"]
            }
        }
    ]
}));

mcpServer.setRequestHandler(CallToolRequestSchema, async (req) => {
    if (req.params.name === "query_analytics") {
        const result = await runAnalytics(req.params.arguments);
        return { content: [{ type: "text", text: JSON.stringify(result) }] };
    }
    throw new Error("Unknown tool");
});

// HTTP SSE transport — allows browser and HTTP-based MCP clients
app.get("/sse", async (req, res) => {
    const transport = new SSEServerTransport("/messages", res);
    await mcpServer.connect(transport);
});

app.listen(3000);
```

---

## 13. WebSocket Programming

### Spring Boot WebSocket Server
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ws;

import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * WebSocket handler that streams AI tokens back to connected clients.
 * Each incoming message triggers a reactive AI stream.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AiChatWebSocketHandler extends TextWebSocketHandler {

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final ChatClient chatClient;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.put(session.getId(), session);
        log.info("Client connected: {}", session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        chatClient.prompt()
            .user(message.getPayload())
            .stream()
            .content()
            .subscribe(
                token  -> sendSafely(session, token),
                error  -> log.error("Stream error for session {}", session.getId(), error),
                ()     -> sendSafely(session, "[DONE]")
            );
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session,
                                      org.springframework.web.socket.CloseStatus status) {
        sessions.remove(session.getId());
    }

    private void sendSafely(WebSocketSession session, String text) {
        try {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(text));
            }
        } catch (IOException e) {
            log.error("Failed to send to session {}", session.getId(), e);
        }
    }
}
```

### WebSocket Config
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ws;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import lombok.RequiredArgsConstructor;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {

    private final AiChatWebSocketHandler handler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/chat")
                .setAllowedOriginPatterns("*");
    }
}
```

---

## 14. Duplex / Bidirectional Systems

### SSE — Server-Sent Events (Unidirectional Streaming)
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.controller;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import lombok.RequiredArgsConstructor;
import java.util.UUID;

/**
 * SSE endpoint — streams AI response tokens as Server-Sent Events.
 * The browser subscribes once and receives tokens as they arrive.
 */
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiStreamController {

    private final ChatClient chatClient;

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> stream(@RequestParam String prompt) {
        return chatClient.prompt()
            .user(prompt)
            .stream()
            .content()
            .map(token -> ServerSentEvent.<String>builder()
                .id(UUID.randomUUID().toString())
                .event("token")
                .data(token)
                .build())
            .concatWith(Flux.just(ServerSentEvent.<String>builder()
                .event("done")
                .data("[DONE]")
                .build()));
    }
}
```

### Full Duplex — gRPC Bidirectional Streaming (Proto)
```protobuf
syntax = "proto3";
package ai.payment.v1;

service AiChatService {
    // Full duplex: client sends messages, server streams tokens back
    rpc Chat(stream ChatMessage) returns (stream ChatResponse);
}

message ChatMessage {
    string session_id = 1;
    string content    = 2;
}

message ChatResponse {
    string token    = 1;
    bool   is_final = 2;
}
```

---

## 15. Real-Time Chat Applications

### STOMP over WebSocket Architecture
```
React UI ──SockJS/STOMP──► Spring Boot ──► ChatClient (AI)
    ▲                             │                │
    │                             ▼                ▼
    └──── token stream ──── Redis Pub/Sub ──── Streaming API
                                 │
                             (horizontal scale)
```

### STOMP Message Broker Config
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ws;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.*;

/**
 * STOMP over WebSocket configuration with topic-based messaging.
 */
@Configuration
@EnableWebSocketMessageBroker
public class StompConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
}
```

### Chat Room Service
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ws.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Handles incoming chat messages and streams AI responses to the room topic.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ChatRoomService {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatClient chatClient;

    /**
     * Streams AI response tokens to the designated room topic.
     *
     * @param message incoming chat message
     */
    public void processMessage(ChatMessage message) {
        chatClient.prompt()
            .user(message.getContent())
            .stream()
            .content()
            .subscribe(
                token -> messagingTemplate.convertAndSend(
                    "/topic/room/" + message.getRoomId(),
                    new StreamToken(token, false)),
                error -> log.error("AI stream failed for room {}", message.getRoomId(), error),
                ()    -> messagingTemplate.convertAndSend(
                    "/topic/room/" + message.getRoomId(),
                    new StreamToken("", true))
            );
    }
}
```

---

## 16. Webhooks & Event-Driven Integration

### Receiving Webhooks (Spring Boot)
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.webhook;

import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.web.bind.annotation.*;
import org.springframework.ai.chat.client.ChatClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Receives inbound webhooks (e.g., GitHub PR events) and triggers
 * asynchronous AI processing — returns 200 immediately.
 */
@RestController
@RequestMapping("/webhooks")
@RequiredArgsConstructor
@Slf4j
public class WebhookController {

    private final WebhookValidator validator;
    private final WebhookProcessor processor;

    @PostMapping("/github/push")
    public ResponseEntity<Void> handleGithubPush(
            @RequestBody String payload,
            @RequestHeader("X-Hub-Signature-256") String signature) {

        if (!validator.isValid(payload, signature)) {
            log.warn("Rejected webhook with invalid signature");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        processor.processAsync(payload);   // async — respond immediately
        return ResponseEntity.ok().build();
    }
}

@Service
@Slf4j
@RequiredArgsConstructor
class WebhookProcessor {

    private final ChatClient chatClient;
    private final GitHubClient gitHubClient;

    @Async
    public void processAsync(String payload) {
        GitHubPushEvent event = parsePayload(payload);
        event.getCommits().forEach(commit ->
            commit.getModified().forEach(filePath -> {
                String diff   = gitHubClient.getDiff(filePath);
                String review = chatClient.prompt()
                    .system("You are a senior code reviewer. Be concise.")
                    .user("Review this diff:\n" + diff)
                    .call()
                    .content();
                gitHubClient.postReviewComment(commit.getId(), filePath, review);
            })
        );
    }
}
```

### Delivering Webhooks with Retry
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.webhook;

import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import java.time.Duration;

/**
 * Delivers outbound webhooks with exponential-backoff retry and
 * an outbox pattern for at-least-once delivery guarantees.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WebhookDispatchService {

    private static final int      MAX_ATTEMPTS    = 5;
    private static final Duration INITIAL_BACKOFF = Duration.ofSeconds(1);

    private final WebClient    webClient;
    private final OutboxRepository outboxRepository;

    public void dispatch(WebhookSubscription subscription, Object payload) {
        OutboxEntry entry = outboxRepository.save(
            OutboxEntry.pending(subscription, payload));

        webClient.post()
            .uri(subscription.getTargetUrl())
            .header("X-Webhook-ID",        entry.getId())
            .header("X-Webhook-Signature", sign(payload, subscription.getSecret()))
            .bodyValue(payload)
            .retrieve()
            .toBodilessEntity()
            .retryWhen(Retry.backoff(MAX_ATTEMPTS, INITIAL_BACKOFF)
                .maxBackoff(Duration.ofMinutes(5))
                .jitter(0.3))
            .doOnSuccess(r -> outboxRepository.markDelivered(entry.getId()))
            .doOnError(e  -> outboxRepository.markFailed(entry.getId(), e.getMessage()))
            .subscribe();
    }
}
```

---

## 17. Reactive Programming

### Project Reactor — Batch AI Processing
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.reactive;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import java.time.Duration;

/**
 * Reactive AI processing pipeline — processes transaction batches
 * concurrently with backpressure and timeout handling.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReactiveAiService {

    private final ChatClient chatClient;

    /**
     * Process a stream of transactions concurrently through AI analysis.
     * Uses boundedElastic scheduler to avoid blocking the event loop.
     *
     * @param transactions reactive stream of transactions
     * @return stream of AI analysis results
     */
    public Flux<AnalysisResult> analyseTransactionsBatch(
            Flux<Transaction> transactions) {
        return transactions
            .limitRate(10)
            .flatMap(txn ->
                Mono.fromCallable(() -> analyse(txn))
                    .subscribeOn(Schedulers.boundedElastic())
                    .timeout(Duration.ofSeconds(30))
                    .onErrorReturn(AnalysisResult.failed(txn.getId())),
                8)   // max 8 concurrent AI calls
            .doOnNext(r  -> log.debug("Analysed: {}", r.getTransactionId()))
            .doOnError(e -> log.error("Batch analysis failed", e));
    }

    /**
     * Real-time event pipeline — buffers micro-batches and classifies with AI.
     */
    public Flux<ClassificationResult> realtimePipeline(Flux<RawEvent> events) {
        return events
            .filter(e -> e.getAmount().compareTo(java.math.BigDecimal.ZERO) > 0)
            .bufferTimeout(50, Duration.ofMillis(100))
            .flatMap(this::enrichAndClassify)
            .share();
    }
}
```

### R2DBC — Reactive Database
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.repository;

import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * Reactive repository for non-blocking database access.
 * Integrates with Project Reactor and WebFlux pipelines.
 */
public interface TransactionReactiveRepository
        extends ReactiveCrudRepository<Transaction, String> {

    Flux<Transaction> findByMerchantIdAndCreatedAtBetween(
            String merchantId, Instant from, Instant to);

    @Query("SELECT * FROM transactions WHERE amount > :amount AND status = 'PENDING'")
    Flux<Transaction> findHighValuePending(BigDecimal amount);
}
```

---

## 18. GraphQL

### Schema
```graphql
type Query {
    transaction(id: ID!): Transaction
    transactions(filter: TransactionFilter, page: Int, size: Int): TransactionPage
    aiAnalysis(transactionId: ID!): AiAnalysis
}

type Subscription {
    transactionUpdates(merchantId: ID!): TransactionEvent
    aiStreamResponse(prompt: String!): AiToken
}

type Mutation {
    triggerFraudReview(transactionId: ID!): FraudReviewResult
}

type Transaction {
    id:         ID!
    amount:     Float!
    currency:   String!
    merchantId: String!
    status:     TransactionStatus!
    createdAt:  String!
}

type AiAnalysis {
    summary:   String!
    riskScore: Float!
    flags:     [String!]!
}

type AiToken {
    token:   String!
    isFinal: Boolean!
}

enum TransactionStatus { PENDING COMPLETED FAILED REVERSED }
```

### Spring GraphQL Controller
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.graphql;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.graphql.data.method.annotation.*;
import org.springframework.stereotype.Controller;
import reactor.core.publisher.Flux;
import lombok.RequiredArgsConstructor;

/**
 * GraphQL controller — resolves queries, mutations, and subscriptions.
 * Subscriptions deliver real-time AI token streams to GraphQL clients.
 */
@Controller
@RequiredArgsConstructor
public class TransactionGraphQlController {

    private final TransactionService transactionService;
    private final ChatClient chatClient;

    @QueryMapping
    public Transaction transaction(@Argument String id) {
        return transactionService.findById(id)
            .orElseThrow(() -> new RuntimeException("Transaction not found: " + id));
    }

    @QueryMapping
    public AiAnalysis aiAnalysis(@Argument String transactionId) {
        Transaction txn = transactionService.findById(transactionId).orElseThrow();
        String result = chatClient.prompt()
            .user("Analyse this transaction for risk: " + txn.toJson())
            .call()
            .content();
        return AiAnalysis.parse(result);
    }

    /**
     * GraphQL subscription — streams AI response tokens in real time.
     *
     * @param prompt the user's question
     * @return reactive stream of AI tokens
     */
    @SubscriptionMapping
    public Flux<AiToken> aiStreamResponse(@Argument String prompt) {
        return chatClient.prompt()
            .user(prompt)
            .stream()
            .content()
            .map(token -> new AiToken(token, false))
            .concatWith(Flux.just(new AiToken("", true)));
    }
}
```

---

## 19. gRPC

### Proto Definition
```protobuf
syntax = "proto3";
package ai.payment.v1;

service PaymentAiService {
    // Unary RPC
    rpc AnalyseTransaction(TransactionRequest) returns (AnalysisResponse);
    // Server streaming — AI tokens
    rpc StreamAnalysis(TransactionRequest)    returns (stream AiToken);
    // Bidirectional streaming — full duplex chat
    rpc ChatSession(stream ChatMessage)        returns (stream ChatResponse);
}

message TransactionRequest {
    string transaction_id = 1;
    double amount         = 2;
    string currency       = 3;
    string merchant_id    = 4;
}

message AnalysisResponse {
    string summary            = 1;
    double risk_score         = 2;
    repeated string flags     = 3;
}

message AiToken {
    string content  = 1;
    bool   is_final = 2;
}

message ChatMessage { string session_id = 1; string content = 2; }
message ChatResponse { string token = 1; bool is_final = 2; }
```

### Spring Boot gRPC Service
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.grpc;

import io.grpc.Status;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;
import org.springframework.ai.chat.client.ChatClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * gRPC service implementation — supports unary, server-streaming,
 * and bidirectional streaming RPCs for AI-powered payment analysis.
 */
@GrpcService
@RequiredArgsConstructor
@Slf4j
public class PaymentAiGrpcService
        extends PaymentAiServiceGrpc.PaymentAiServiceImplBase {

    private final ChatClient chatClient;
    private final TransactionService transactionService;

    /** Unary RPC. */
    @Override
    public void analyseTransaction(TransactionRequest request,
                                   StreamObserver<AnalysisResponse> out) {
        try {
            Transaction txn = transactionService.findById(request.getTransactionId())
                .orElseThrow(() -> Status.NOT_FOUND
                    .withDescription("Transaction not found: " + request.getTransactionId())
                    .asRuntimeException());

            String analysis = chatClient.prompt()
                .user("Analyse: " + txn.toJson())
                .call()
                .content();

            out.onNext(AnalysisResponse.newBuilder()
                .setSummary(analysis)
                .setRiskScore(parseRiskScore(analysis))
                .build());
            out.onCompleted();
        } catch (Exception e) {
            out.onError(Status.INTERNAL.withCause(e).asRuntimeException());
        }
    }

    /** Server-streaming RPC — one request, stream of AI tokens. */
    @Override
    public void streamAnalysis(TransactionRequest request,
                               StreamObserver<AiToken> out) {
        chatClient.prompt()
            .user("Analyse transaction " + request.getTransactionId())
            .stream()
            .content()
            .subscribe(
                token -> out.onNext(AiToken.newBuilder()
                    .setContent(token).setIsFinal(false).build()),
                error -> out.onError(Status.INTERNAL.withCause(error).asRuntimeException()),
                () -> {
                    out.onNext(AiToken.newBuilder().setIsFinal(true).build());
                    out.onCompleted();
                }
            );
    }
}
```

---

## 20. Notification Systems & Push Webhooks

### FCM + AI-Generated Personalised Notifications
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.notification;

import com.google.firebase.messaging.*;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Generates personalised AI notification copy and delivers via FCM.
 * The AI model tailors the message based on user preferences and
 * transaction context — improving engagement rates.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SmartNotificationService {

    private final FirebaseMessaging fcm;
    private final ChatClient chatClient;
    private final UserPreferenceService preferenceService;

    /**
     * Send a personalised push notification for a transaction event.
     *
     * @param userId the target user ID
     * @param event  the transaction event to notify about
     */
    public void sendSmartNotification(String userId, TransactionEvent event) {
        String userPrefs = preferenceService.getPreferences(userId);

        String notificationBody = chatClient.prompt()
            .system("Generate a friendly push notification (max 100 characters).")
            .user("Transaction: " + event.toJson() + "\nUser preferences: " + userPrefs)
            .call()
            .content();

        try {
            Message message = Message.builder()
                .setToken(preferenceService.getFcmToken(userId))
                .setNotification(Notification.builder()
                    .setTitle("Payment Update")
                    .setBody(notificationBody)
                    .build())
                .putData("transactionId", event.getTransactionId())
                .putData("type", event.getType().name())
                .build();

            String messageId = fcm.send(message);
            log.info("FCM notification sent: {}", messageId);
        } catch (FirebaseMessagingException e) {
            log.error("FCM notification failed for user {}", userId, e);
        }
    }
}
```

---

## 21. Advanced UI / UFX Frontend Layout

### React Component Architecture for AI Apps

```
src/
├── app/
│   ├── App.tsx              # Root, providers, routing
│   └── providers/           # Theme, Auth, WebSocket providers
├── features/
│   ├── chat/
│   │   ├── ChatRoom.tsx
│   │   ├── MessageList.tsx
│   │   ├── StreamingMessage.tsx   ← real-time token streaming
│   │   ├── ChatInput.tsx
│   │   └── useChatRoom.ts
│   ├── transactions/
│   │   ├── TransactionTable.tsx
│   │   └── AiInsightPanel.tsx
│   └── analytics/
│       ├── Dashboard.tsx
│       └── AiDashboard.tsx
├── shared/
│   ├── components/          # Design system components
│   ├── hooks/               # useWebSocket, useSSE, useGraphQL
│   └── services/            # API clients
└── design-tokens/           # CSS custom properties
    ├── variables.css
    └── tokens.ts
```

### Streaming AI Message Component (React + TypeScript)
```tsx
import { useRef, useEffect } from "react";

interface StreamingMessageProps {
    content:     string;    // accumulated text so far
    isStreaming: boolean;   // show blinking cursor while streaming
}

/**
 * Renders an AI message bubble with real-time token streaming.
 * Auto-scrolls as new tokens arrive and shows a blinking cursor.
 */
export function StreamingMessage({ content, isStreaming }: StreamingMessageProps) {
    const anchorRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        anchorRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [content]);

    return (
        <article className="message message--ai" aria-live="polite">
            <div className="message__avatar"><AiAvatar /></div>
            <div className="message__body">
                <MarkdownRenderer content={content} />
                {isStreaming && (
                    <span className="cursor-blink" aria-hidden="true">▋</span>
                )}
            </div>
            <div ref={anchorRef} />
        </article>
    );
}
```

### CSS — UFX Layout with Container Queries & Design Tokens
```css
/* Design tokens */
:root {
    --color-ai-primary:   #6366f1;
    --color-ai-surface:   #f8fafc;
    --color-user-bubble:  #e0e7ff;
    --space-xs:           0.25rem;
    --space-sm:           0.5rem;
    --space-md:           1rem;
    --space-lg:           1.5rem;
    --radius-bubble:      1.25rem;
}

/* Full-height chat layout with CSS Grid */
.chat-layout {
    display:             grid;
    grid-template-rows:  auto 1fr auto;
    height:              100dvh;          /* dynamic viewport height */
    container-type:      inline-size;     /* enable container queries */
}

/* Message list — anchored scrolling */
.message-list {
    overflow-y:          auto;
    scroll-behavior:     smooth;
    overscroll-behavior: contain;
    padding:             var(--space-md);
    display:             flex;
    flex-direction:      column;
    gap:                 var(--space-md);
}

/* AI message bubble */
.message--ai .message__body {
    background:          var(--color-ai-surface);
    border:              1px solid #e2e8f0;
    border-radius:       var(--radius-bubble);
    border-top-left-radius: 0.25rem;
    padding:             var(--space-md) var(--space-lg);
    max-width:           85%;
}

/* Blinking cursor */
.cursor-blink {
    animation: blink 1s step-end infinite;
    color:     var(--color-ai-primary);
}

@keyframes blink {
    0%, 100% { opacity: 1; }
    50%       { opacity: 0; }
}

/* Container query — compact layout on narrow containers */
@container (max-width: 480px) {
    .message__body { max-width: 95%; }
    .chat-input    { padding: var(--space-sm); }
}
```

### AI Analytics Dashboard Layout
```tsx
/**
 * Responsive AI analytics dashboard — CSS Grid layout with
 * sidebar navigation, metrics grid, and an embedded AI assistant panel.
 */
export function AiDashboard() {
    return (
        <div className="dashboard">
            <aside className="dashboard__sidebar"><NavigationPanel /></aside>
            <main className="dashboard__main">
                <header className="dashboard__header"><DashboardHeader /></header>
                <section className="dashboard__widgets">
                    <MetricCard title="Transactions Analysed" value={42_891} trend="+12%" />
                    <MetricCard title="Fraud Detected"        value={127}    trend="-3%"  alert />
                    <MetricCard title="AI Accuracy"           value="97.4%"  trend="+0.2%" />
                    <AiInsightsPanel />
                    <TransactionHeatmap />
                    <RealTimeFeedWidget />
                </section>
            </main>
            <aside className="dashboard__ai-panel"><AiAssistantPanel /></aside>
        </div>
    );
}
```

---

## 22. Figma — Design to Code Workflows

### End-to-End Workflow

```
Figma Design
    │
    ▼  Tokens Studio plugin
tokens.json  (design tokens export)
    │
    ▼  Style Dictionary build
    ├── variables.css        (CSS custom properties)
    └── tokens.ts            (TypeScript constants)
    │
    ▼  Figma Dev Mode / Anima / Builder.io
HTML/CSS skeleton
    │
    ▼  GitHub Copilot / Cursor AI
React component with:
    ✓ TypeScript props interface
    ✓ Accessibility (aria attributes, roles)
    ✓ Design token CSS variables
    ✓ Storybook story
    ✓ Unit tests
```

### tokens.json (Figma Tokens Studio export)
```json
{
  "color": {
    "brand": {
      "primary":   { "value": "#6366f1", "type": "color" },
      "secondary": { "value": "#8b5cf6", "type": "color" }
    },
    "semantic": {
      "success":   { "value": "#22c55e", "type": "color" },
      "warning":   { "value": "#f59e0b", "type": "color" },
      "danger":    { "value": "#ef4444", "type": "color" }
    }
  },
  "spacing": {
    "xs": { "value": "4",  "type": "spacing" },
    "sm": { "value": "8",  "type": "spacing" },
    "md": { "value": "16", "type": "spacing" },
    "lg": { "value": "24", "type": "spacing" }
  },
  "typography": {
    "heading-1": {
      "fontSize":   { "value": "32", "type": "fontSizes" },
      "fontWeight": { "value": "700", "type": "fontWeights" },
      "lineHeight": { "value": "1.25", "type": "lineHeights" }
    }
  }
}
```

### Style Dictionary Build Config
```javascript
// style-dictionary.config.js
module.exports = {
    source: ["tokens/**/*.json"],
    platforms: {
        css: {
            transformGroup: "css",
            buildPath:      "src/design-tokens/",
            files: [{ destination: "variables.css", format: "css/variables" }]
        },
        ts: {
            transformGroup: "js",
            buildPath:      "src/design-tokens/",
            files: [{ destination: "tokens.ts", format: "javascript/es6" }]
        }
    }
};
```

---

## 23. AI Agent Automation Use Cases

### Use Case Matrix

| Domain | AI Agent Task | Technologies |
|---|---|---|
| **Code Review** | Analyse PR diffs, post inline comments | GitHub Webhook → Claude + LangChain4J |
| **Test Generation** | Read source → generate JUnit 5 tests | Spring AI + Claude 3.5 Sonnet |
| **Documentation** | Scan codebase → update Confluence pages | MCP Server + Confluence REST API |
| **Incident Response** | Detect anomaly → diagnose → execute runbook → notify | LangGraph + PagerDuty webhook |
| **Fraud Detection** | Classify transactions → score → alert | Spring AI + Bedrock + Kafka |
| **Customer Support** | Answer queries → escalate unknown cases | Spring AI RAG + Jira MCP |
| **Release Notes** | git log → structured changelog → publish | Claude + Git MCP + Confluence MCP |
| **Security Scanning** | Scan code → CVE lookup → create Jira ticket | LangGraph + Sonar MCP + Jira MCP |
| **Reporting** | Query DB → generate PDF report → email | Spring AI + JasperReports |
| **API Testing** | Read OpenAPI spec → generate test suite | LangChain4J + OpenAPI spec |
| **Acquirer Mapping** | Read legacy config → generate new mapper class | Spring AI + Code generation |

### Complete Example — AI Code Review Agent
```java
/*
 * Copyright (c) 2025 Mastercard. All rights reserved.
 */
package com.mastercard.pgs.connectivity.acquirer.ai.agent;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Automated code review agent pipeline:
 * 1. Receives a GitHub PR number
 * 2. Fetches all changed file diffs
 * 3. AI reviews each diff for security, quality, and SOLID violations
 * 4. Posts inline review comments on GitHub
 * 5. Creates Jira issues for BLOCKER findings
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CodeReviewAgent {

    private final ChatClient chatClient;
    private final GitHubClient gitHubClient;
    private final JiraClient jiraClient;

    /**
     * Run a full AI-powered code review on a pull request.
     *
     * @param prNumber the GitHub PR number
     */
    public void reviewPullRequest(String prNumber) {
        List<FileDiff> diffs = gitHubClient.getPrDiffs(prNumber);

        List<ReviewComment> comments = diffs.stream()
            .flatMap(diff -> reviewFile(diff).stream())
            .collect(Collectors.toList());

        comments.forEach(c -> gitHubClient.postInlineComment(prNumber, c));

        comments.stream()
            .filter(c -> c.getSeverity() == Severity.BLOCKER)
            .forEach(c -> jiraClient.createIssue(
                JiraIssue.builder()
                    .projectKey("PROJ")
                    .summary("Code Review Blocker: " + c.getTitle())
                    .description(c.getDetail())
                    .priority("High")
                    .build()));

        log.info("PR {} reviewed: {} comments ({} blockers)",
            prNumber, comments.size(),
            comments.stream().filter(c -> c.getSeverity() == Severity.BLOCKER).count());
    }

    private List<ReviewComment> reviewFile(FileDiff diff) {
        String prompt = """
            Review this Java code diff for:
            1. Security vulnerabilities (PAN/CVV exposure, SQL injection)
            2. Missing error handling or exception swallowing
            3. SOLID principle violations
            4. Missing Javadoc on public methods
            5. Performance anti-patterns

            File: %s
            Diff:
            %s

            Respond as JSON: [{"line": N, "severity": "BLOCKER|WARNING|INFO",
            "title": "...", "detail": "..."}]
            """.formatted(diff.getFilePath(), diff.getContent());

        String response = chatClient.prompt().user(prompt).call().content();
        return parseComments(response);
    }
}
```

### AI Incident Response Agent (LangGraph / Python)
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict

class IncidentState(TypedDict):
    alert:         dict
    diagnosis:     str
    runbook_steps: list
    resolution:    str

def diagnose(state: IncidentState) -> IncidentState:
    diagnosis = llm.invoke(
        f"Diagnose this alert and suggest root cause: {state['alert']}")
    return {"diagnosis": diagnosis.content}

def fetch_runbook(state: IncidentState) -> IncidentState:
    docs  = vectorstore.similarity_search(state["diagnosis"], k=3)
    steps = [d.page_content for d in docs]
    return {"runbook_steps": steps}

def remediate(state: IncidentState) -> IncidentState:
    result = execute_runbook(state["runbook_steps"])
    return {"resolution": result}

def notify(state: IncidentState) -> IncidentState:
    slack.send(f"🚨 *Resolved*\nDiagnosis: {state['diagnosis']}\n"
               f"Resolution: {state['resolution']}")
    return state

workflow = StateGraph(IncidentState)
workflow.add_node("diagnose",  diagnose)
workflow.add_node("runbook",   fetch_runbook)
workflow.add_node("remediate", remediate)
workflow.add_node("notify",    notify)

workflow.set_entry_point("diagnose")
workflow.add_edge("diagnose",  "runbook")
workflow.add_edge("runbook",   "remediate")
workflow.add_edge("remediate", "notify")
workflow.add_edge("notify",    END)

incident_agent = workflow.compile()
```

---

## 24. Architecture Patterns Summary

### Technology Decision Guide

```
Requirement                               Use
────────────────────────────────────────────────────────────────────
AI chat in Java/Spring Boot           →  Spring AI ChatClient
Multi-provider AI (OpenAI+Claude+AWS) →  Spring AI (unified abstraction)
AWS-native AI                         →  Amazon Bedrock SDK
Azure-native AI                       →  Azure OpenAI SDK
Java agent with tools/memory          →  LangChain4J @AiService
Python agent workflows                →  LangChain + LangGraph
Stateful cyclic agent loops           →  LangGraph StateGraph
IDE / editor AI tooling               →  MCP Server (STDIO)
HTTP-accessible MCP server            →  MCP Server (SSE transport)
Real-time AI response streaming       →  WebSocket + Project Reactor
Full-duplex AI communication          →  gRPC bidirectional streaming
Browser AI token streaming            →  SSE (text/event-stream)
API-first with subscriptions          →  GraphQL + Spring GraphQL
Event-driven AI pipeline              →  Kafka + Reactive Streams
Push notifications                    →  FCM + Webhook dispatcher
Design system to production code      →  Figma + Tokens Studio + Style Dictionary
```

### Full Integration Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Enterprise AI Platform                           │
│                                                                         │
│  ┌─────────────┐   ┌────────────────┐   ┌───────────────────────────┐  │
│  │  React UI   │   │  Spring Boot   │   │  AI Orchestration Layer   │  │
│  │             │   │  API Gateway   │   │                           │  │
│  │  WebSocket  │◄─►│                │◄─►│  Spring AI / LangChain4J  │  │
│  │  GraphQL    │   │  gRPC          │   │  Multi-Agent Workflows    │  │
│  │  SSE        │   │  SSE           │   │  RAG Pipelines            │  │
│  └─────────────┘   └──────┬─────────┘   └────────────┬──────────────┘  │
│                           │                          │                  │
│             ┌─────────────┼──────────────┐           │                  │
│             ▼             ▼              ▼           ▼                  │
│        ┌─────────┐  ┌──────────┐  ┌──────────┐ ┌──────────┐           │
│        │ OpenAI  │  │ Anthropic│  │ Bedrock  │ │ Gemini   │           │
│        │ GPT-4o  │  │ Claude   │  │ (AWS)    │ │ (Google) │           │
│        └─────────┘  └──────────┘  └──────────┘ └──────────┘           │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  MCP Tool Layer                                                  │  │
│  │  Jira | Confluence | GitHub | Jenkins | SonarQube | Slack        │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Event Layer — Webhooks, Kafka, WebSocket, FCM, Reactor          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference — Dependency Versions (March 2026)

| Library | Version | Ecosystem |
|---|---|---|
| Spring AI BOM | 1.0.0 | Java / Spring Boot |
| LangChain4J | 0.36.0 | Java |
| OpenAI Java SDK | 2.1.0 | Java |
| Anthropic Java SDK | 1.2.0 | Java |
| AWS SDK v2 (Bedrock) | 2.29.0 | Java |
| MCP SDK | 1.8.0 | TypeScript / Node.js |
| Google AI SDK | 0.21.0 | TypeScript / Node.js |
| LangChain | 0.3.x | Python |
| LangGraph | 0.2.x | Python |
| Spring Boot | 3.4.x | Java 17+ |
| Project Reactor | 3.6.x | Java |
| gRPC Java | 1.68.x | Java |
| React | 18.3.x | TypeScript |

---

*Last updated: March 2026 — Review quarterly as AI SDKs and protocols evolve rapidly.*
