# Plan: Custom MCP AI Assistant Platform
> **Date:** March 28, 2026 | **Stack:** Java 17 · Spring Boot 3.4.x · Spring AI 1.0.0 · React 18 · TypeScript 5 · Vite

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Requirements Analysis](#2-requirements-analysis)
3. [System Architecture](#3-system-architecture)
4. [Project Structure](#4-project-structure)
5. [Technology Decisions](#5-technology-decisions)
6. [Backend Implementation Plan](#6-backend-implementation-plan)
7. [Frontend Implementation Plan](#7-frontend-implementation-plan)
8. [MCP Tool Integration Plan](#8-mcp-tool-integration-plan)
9. [WebSocket & Streaming Design](#9-websocket--streaming-design)
10. [Conversation Export Design](#10-conversation-export-design)
11. [Configuration & Environment Variables](#11-configuration--environment-variables)
12. [API Contract](#12-api-contract)
13. [Dependency Versions](#13-dependency-versions)
14. [Implementation Steps](#14-implementation-steps)
15. [Testing Strategy](#15-testing-strategy)
16. [Open Questions & Assumptions](#16-open-questions--assumptions)

---

## 1. Executive Summary

Build a **production-grade, full-stack AI assistant platform** composed of:

- A **Spring Boot 3.4.x MCP Server** powered by Spring AI 1.0.0, exposing AI chat over WebSocket/STOMP with token streaming, and registering Confluence, Jira, and Bitbucket integrations as MCP tools callable by the LLM.
- A **React 18 + TypeScript 5** single-page application with a polished streaming chat UI, real-time tool-call status badges, session history sidebar, and a one-click conversation export to a beautiful self-contained HTML page or clean Markdown document.
- **GitHub Copilot** as the primary LLM (via its OpenAI-compatible endpoint), with a zero-code swap path to Azure OpenAI, Anthropic Claude, or any other Spring AI-supported provider by changing a single `application.yml` property.
- A **custom MCP Server layer** (SSE transport) that exposes the Confluence, Jira, and Bitbucket integrations as first-class MCP tools, so any MCP-compatible client (Cursor, VS Code, Claude Desktop) can also consume them independently.

---

## 2. Requirements Analysis

### 2.1 Functional Requirements

| # | Requirement | Priority |
|---|---|---|
| FR-01 | User can send a message in a chat UI and receive a streamed AI response | Must |
| FR-02 | AI internally calls Confluence, Jira, Bitbucket tools when needed | Must |
| FR-03 | Frontend shows real-time tool-call status (e.g. "Searching Confluence…") | Must |
| FR-04 | Conversation history is maintained within a session | Must |
| FR-05 | User can download the full conversation as a styled HTML file | Must |
| FR-06 | User can download the full conversation as a Markdown file | Must |
| FR-07 | Multiple concurrent sessions are supported | Must |
| FR-08 | Session history sidebar shows past conversations | Should |
| FR-09 | MCP Server endpoint is reachable by external MCP clients (Cursor, Claude) | Should |
| FR-10 | Dark mode support in the frontend | Should |
| FR-11 | Code blocks in AI responses are syntax-highlighted | Should |
| FR-12 | User can create Jira issues, Confluence pages via chat commands | Could |

### 2.2 Non-Functional Requirements

| # | Requirement | Target |
|---|---|---|
| NFR-01 | Streaming first-token latency | < 500 ms |
| NFR-02 | WebSocket connection supports ≥ 100 concurrent sessions | Scalable |
| NFR-03 | All secrets via environment variables, never hardcoded | Mandatory |
| NFR-04 | CORS locked to known origins in production | Mandatory |
| NFR-05 | Backend startup time | < 10 s |
| NFR-06 | Frontend bundle size (gzipped) | < 300 KB |

### 2.3 Out of Scope (v1)

- User authentication / OAuth (assumed internal tool, trust header pattern)
- Persistent conversation storage to a database (in-memory per JVM restart)
- Horizontal scaling / Redis STOMP broker relay (noted as upgrade path)
- RAG / vector store integration (architecture leaves a slot for it)

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        MCP AI Assistant Platform                             │
│                                                                              │
│  ┌──────────────────────────┐          ┌─────────────────────────────────┐  │
│  │     React 18 Frontend    │          │   Spring Boot 3.4 MCP Server    │  │
│  │   (TypeScript 5 + Vite)  │◄─STOMP──►│        (Java 17)                │  │
│  │                          │  /ws     │                                 │  │
│  │  ┌──────────────────┐    │          │  ┌─────────────────────────┐    │  │
│  │  │  Chat UI         │    │          │  │  WebSocket/STOMP Broker  │    │  │
│  │  │  Streaming tokens│    │          │  │  /app/chat.send          │    │  │
│  │  │  Tool badges     │    │          │  │  /topic/session/{id}     │    │  │
│  │  │  Session sidebar │    │          │  └──────────┬──────────────┘    │  │
│  │  └──────────────────┘    │          │             │                   │  │
│  │  ┌──────────────────┐    │          │  ┌──────────▼──────────────┐    │  │
│  │  │  Export Button   │────┼──REST───►│  │  AiChatService           │    │  │
│  │  │  HTML / MD       │    │  /api/   │  │  ChatClient (Copilot)    │    │  │
│  │  └──────────────────┘    │  export  │  │  MessageMemoryAdvisor    │    │  │
│  └──────────────────────────┘          │  └──────────┬──────────────┘    │  │
│                                        │             │  Tool calls        │  │
│                                        │  ┌──────────▼──────────────┐    │  │
│                                        │  │   MCP Tool Orchestrator  │    │  │
│                                        │  │  (Spring AI @Tool beans) │    │  │
│                                        │  └──┬──────────┬────────┬───┘    │  │
│                                        └─────┼──────────┼────────┼────────┘  │
│                                              │          │        │            │
│              ┌───────────────────────────────┘          │        └──────────┐ │
│              ▼                                          ▼                   ▼ │
│  ┌───────────────────────┐          ┌───────────────────────┐  ┌──────────────┐│
│  │   Confluence Cloud    │          │     Jira Cloud        │  │  Bitbucket   ││
│  │   REST API v2         │          │     REST API v3       │  │  REST API v2 ││
│  │                       │          │                       │  │              ││
│  │  • Search pages       │          │  • Search issues(JQL) │  │  • List repos││
│  │  • Get page content   │          │  • Get issue details  │  │  • Get files ││
│  │  • Create page        │          │  • Create issue       │  │  • List PRs  ││
│  │  • Update page        │          │  • Add comment        │  │  • Get diff  ││
│  └───────────────────────┘          └───────────────────────┘  └──────────────┘│
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                       GitHub Copilot LLM                                │   │
│  │           (OpenAI-compatible endpoint: api.githubcopilot.com)           │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 WebSocket Message Flow

```
Browser                     Spring Boot                    GitHub Copilot LLM
   │                             │                                │
   │──STOMP CONNECT /ws─────────►│                                │
   │◄─CONNECTED─────────────────│                                │
   │                             │                                │
   │──SUBSCRIBE /topic/session/X►│                                │
   │                             │                                │
   │──SEND /app/chat.send───────►│                                │
   │   { sessionId, message }    │──ChatClient.stream()──────────►│
   │                             │                                │
   │◄─TOKEN { token:"Hello" }───│◄──token stream─────────────────│
   │◄─TOKEN { token:" world" }──│◄──token stream─────────────────│
   │◄─TOOL_CALL { tool:"jira" }─│  (AI decides to call Jira)     │
   │◄─TOKEN { token:"Issue..." }│◄──tool result + next tokens────│
   │◄─DONE {}───────────────────│◄──stream complete──────────────│
   │                             │                                │
   │──GET /api/export/X?format=html                              │
   │◄─200 conversation.html────────────────────────────────────  │
```

### 3.3 MCP Server Architecture (SSE Transport)

```
┌──────────────────────────────────────────────────────────────┐
│           Spring Boot MCP Server  (port 8080)                │
│                                                              │
│   GET  /mcp/sse        ← MCP clients connect here           │
│   POST /mcp/messages   ← MCP JSON-RPC messages              │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Registered MCP Tools (auto-discovered via @Tool)      │  │
│  │                                                        │  │
│  │  confluence_search_pages    confluence_get_page        │  │
│  │  confluence_create_page     confluence_update_page     │  │
│  │  jira_search_issues         jira_get_issue             │  │
│  │  jira_create_issue          jira_add_comment           │  │
│  │  bitbucket_list_repos       bitbucket_get_file         │  │
│  │  bitbucket_list_prs         bitbucket_get_pr_diff      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
         ▲                  ▲                  ▲
         │                  │                  │
    Cursor IDE         Claude Desktop      VS Code Copilot
    (MCP client)       (MCP client)        (MCP client)
```

---

## 4. Project Structure

```
Projects/
└── mcp-ai-assistant/
    │
    ├── backend/                                         ← Spring Boot 3.4.x
    │   ├── pom.xml
    │   └── src/
    │       ├── main/
    │       │   ├── java/com/ai/assistant/
    │       │   │   │
    │       │   │   ├── McpAiAssistantApplication.java          ← @SpringBootApplication
    │       │   │   │
    │       │   │   ├── config/
    │       │   │   │   ├── ChatClientConfig.java               ← ChatClient bean + memory + tools
    │       │   │   │   ├── WebSocketStompConfig.java           ← STOMP broker + /ws endpoint
    │       │   │   │   ├── McpServerConfig.java                ← MCP SSE transport config
    │       │   │   │   └── CorsConfig.java                     ← CORS for React dev server
    │       │   │   │
    │       │   │   ├── websocket/
    │       │   │   │   ├── ChatWebSocketController.java        ← @MessageMapping /chat.send
    │       │   │   │   └── model/
    │       │   │   │       ├── ChatRequest.java                ← { sessionId, userMessage }
    │       │   │   │       ├── StreamToken.java                ← { token, type, toolName }
    │       │   │   │       └── ConversationMessage.java        ← { role, content, timestamp, toolCalls }
    │       │   │   │
    │       │   │   ├── mcp/
    │       │   │   │   ├── tools/
    │       │   │   │   │   ├── ConfluenceMcpTools.java         ← @Tool methods for Confluence
    │       │   │   │   │   ├── JiraMcpTools.java               ← @Tool methods for Jira
    │       │   │   │   │   └── BitbucketMcpTools.java          ← @Tool methods for Bitbucket
    │       │   │   │   └── client/
    │       │   │   │       ├── ConfluenceApiClient.java        ← WebClient → Confluence REST
    │       │   │   │       ├── JiraApiClient.java              ← WebClient → Jira REST
    │       │   │   │       └── BitbucketApiClient.java         ← WebClient → Bitbucket REST
    │       │   │   │
    │       │   │   ├── service/
    │       │   │   │   ├── AiChatService.java                  ← streaming ChatClient + tool dispatch
    │       │   │   │   ├── ConversationStore.java              ← in-memory session → messages map
    │       │   │   │   └── ConversationExportService.java      ← HTML + MD export rendering
    │       │   │   │
    │       │   │   └── controller/
    │       │   │       ├── ExportController.java               ← GET /api/export/{sessionId}
    │       │   │       └── HealthController.java               ← GET /api/health
    │       │   │
    │       │   └── resources/
    │       │       ├── application.yml                         ← all config, env var refs
    │       │       ├── application-dev.yml                     ← dev overrides
    │       │       └── templates/
    │       │           ├── export-html.mustache                ← self-contained HTML export
    │       │           └── export-md.mustache                  ← Markdown export
    │       │
    │       └── test/java/com/ai/assistant/
    │           ├── websocket/ChatWebSocketControllerTest.java
    │           ├── mcp/tools/ConfluenceMcpToolsTest.java
    │           ├── mcp/tools/JiraMcpToolsTest.java
    │           ├── mcp/tools/BitbucketMcpToolsTest.java
    │           └── service/ConversationExportServiceTest.java
    │
    └── frontend/                                        ← React 18 + TypeScript 5 + Vite
        ├── package.json
        ├── tsconfig.json
        ├── vite.config.ts
        ├── index.html
        └── src/
            ├── main.tsx                                 ← ReactDOM.createRoot
            ├── App.tsx                                  ← Router + providers
            │
            ├── design-tokens/
            │   └── variables.css                        ← CSS custom properties, dark mode
            │
            ├── features/
            │   ├── chat/
            │   │   ├── ChatPage.tsx                     ← CSS Grid: sidebar + main
            │   │   ├── ChatSidebar.tsx                  ← session list + new chat button
            │   │   ├── ChatRoom.tsx                     ← message area + input
            │   │   ├── MessageList.tsx                  ← scrollable list of bubbles
            │   │   ├── MessageBubble.tsx                ← user / AI bubble + markdown render
            │   │   ├── StreamingMessage.tsx             ← live token accumulation + cursor
            │   │   ├── ToolCallBadge.tsx                ← animated "🔍 Searching Jira…" pill
            │   │   ├── ChatInput.tsx                    ← textarea + send + attach
            │   │   ├── useChatWebSocket.ts              ← STOMP hook: send + subscribe
            │   │   └── chat.types.ts                    ← TypeScript interfaces
            │   │
            │   └── export/
            │       ├── ExportButton.tsx                 ← dropdown: Export as HTML / MD
            │       └── useExport.ts                     ← fetch + trigger browser download
            │
            └── shared/
                ├── components/
                │   ├── Avatar.tsx                       ← user / AI avatar icon
                │   ├── Badge.tsx                        ← reusable status badge
                │   ├── Spinner.tsx                      ← loading spinner
                │   └── Tooltip.tsx                      ← hover tooltip
                └── hooks/
                    └── useStompClient.ts                ← SockJS + @stomp/stompjs lifecycle
```

---

## 5. Technology Decisions

### 5.1 Decision Matrix

| Concern | Choice | Rationale |
|---|---|---|
| **LLM Provider** | GitHub Copilot (OpenAI-compatible) | Requirement spec; zero-swap path via Spring AI |
| **AI Framework** | Spring AI 1.0.0 | Unified `ChatClient`, `@Tool`, memory advisors, MCP server starter |
| **MCP Transport** | SSE (HTTP) | Browser + IDE accessible; STDIO is desktop-only |
| **WebSocket Protocol** | STOMP over WebSocket | Topic pub/sub, session queues, horizontal scale path via Redis |
| **Frontend Framework** | React 18 + TypeScript 5 | Specified in reference stack; rich ecosystem |
| **Build Tool** | Vite 5 | Fast HMR, native ESM, small bundles |
| **Streaming Protocol** | WebSocket/STOMP (not SSE) | Full-duplex: send message + receive tokens on same connection |
| **Persistence** | In-memory `ConcurrentHashMap` | v1 simplicity; upgrade path to PostgreSQL/Redis noted |
| **Export Templating** | Mustache (JMustache) | Logic-less, no extra deps, works server-side |
| **HTTP Client (tools)** | Spring `WebClient` (reactive) | Non-blocking, fits Spring WebFlux pipeline |
| **Markdown rendering** | `react-markdown` + `remark-gfm` | Battle-tested, safe, extensible |
| **Code highlighting** | `react-syntax-highlighter` (Prism) | Works with react-markdown code blocks |

### 5.2 GitHub Copilot as LLM

GitHub Copilot exposes an **OpenAI-compatible REST API** at `https://api.githubcopilot.com`. Spring AI's `spring-ai-openai-spring-boot-starter` is used with the following `application.yml` overrides:

```yaml
spring:
  ai:
    openai:
      base-url: https://api.githubcopilot.com
      api-key: ${GITHUB_COPILOT_TOKEN}
      chat:
        options:
          model: gpt-4o
          temperature: 0.7
          max-tokens: 4096
```

**Zero-code swap path:** To switch to Azure OpenAI, replace the starter with `spring-ai-azure-openai-spring-boot-starter` and update `application.yml`. The `ChatClient` API is identical.

### 5.3 STOMP vs Raw WebSocket

The reference document (Section 15) demonstrates STOMP over WebSocket with `@EnableWebSocketMessageBroker`. STOMP is chosen over raw `TextWebSocketHandler` (Section 13) because:

1. **Topic-based pub/sub** — each session gets its own `/topic/session/{id}` channel
2. **Spring integration** — `@MessageMapping`, `SimpMessagingTemplate`, `@SendTo` annotations
3. **Horizontal scale path** — swap simple broker for Redis relay (`enableStompBrokerRelay`) with zero application code change
4. **SockJS fallback** — automatic HTTP long-polling for environments that block WebSocket

---

## 6. Backend Implementation Plan

### 6.1 `pom.xml` — Key Dependencies

```xml
<!-- Spring Boot Parent -->
<parent>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-parent</artifactId>
  <version>3.4.1</version>
</parent>

<!-- Spring AI BOM -->
<dependencyManagement>
  <dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-bom</artifactId>
    <version>1.0.0</version>
    <type>pom</type>
    <scope>import</scope>
  </dependency>
</dependencyManagement>

<!-- Core -->
spring-boot-starter-web
spring-boot-starter-websocket
spring-boot-starter-webflux

<!-- Spring AI -->
spring-ai-openai-spring-boot-starter          ← ChatClient / Copilot LLM
spring-ai-mcp-server-spring-boot-starter      ← MCP Server + @Tool registration

<!-- Export Templating -->
com.github.spullara.mustache.java:compiler:0.9.14

<!-- Utilities -->
org.projectlombok:lombok
com.fasterxml.jackson.core:jackson-databind
```

### 6.2 `McpAiAssistantApplication.java`

Standard `@SpringBootApplication`. No special customisation needed — Spring AI auto-configures `ChatClient.Builder` and MCP server from `application.yml` and `@Tool`-annotated beans.

### 6.3 `ChatClientConfig.java`

```
Responsibilities:
  • Build ChatClient bean with:
      - GitHub Copilot base-url / API key (from application.yml)
      - defaultSystem() — sets the assistant persona and capabilities
      - defaultAdvisors():
          * MessageChatMemoryAdvisor(InMemoryChatMemory) — rolling 20-message window
          * SimpleLoggerAdvisor — logs prompts/responses at DEBUG
      - defaultTools() — registers all @Tool beans:
          * confluenceMcpTools, jiraMcpTools, bitbucketMcpTools
```

### 6.4 `WebSocketStompConfig.java`

```
Responsibilities:
  • @EnableWebSocketMessageBroker
  • configureMessageBroker():
      - enableSimpleBroker("/topic", "/queue")
      - setApplicationDestinationPrefixes("/app")
      - setUserDestinationPrefix("/user")
  • registerStompEndpoints():
      - addEndpoint("/ws").setAllowedOriginPatterns("*").withSockJS()
```

### 6.5 `McpServerConfig.java`

```
Responsibilities:
  • Configure MCP SSE transport (spring.ai.mcp.server.type: SSE)
  • Server name: "mcp-ai-assistant", version: "1.0.0"
  • MCP endpoint paths: /mcp/sse, /mcp/messages
  • All @Tool beans auto-registered by Spring AI MCP server starter
```

### 6.6 `ChatWebSocketController.java`

```java
// Skeleton — full implementation in Step 14
@Controller
@RequiredArgsConstructor
public class ChatWebSocketController {

    @MessageMapping("/chat.send")
    public void handleMessage(ChatRequest request, SimpMessageHeaderAccessor headerAccessor) {
        // 1. Store user message in ConversationStore
        // 2. Call AiChatService.streamChat(sessionId, userMessage)
        // 3. Subscribe to Flux<StreamToken>:
        //    - On each token: messagingTemplate.convertAndSend("/topic/session/{id}", token)
        //    - On tool call start: send TOOL_CALL token with toolName
        //    - On complete: send DONE token, store full AI message in ConversationStore
    }
}
```

**StreamToken types:**
| type | payload | meaning |
|---|---|---|
| `TOKEN` | `{ token: "Hello" }` | Regular text token from LLM |
| `TOOL_CALL` | `{ toolName: "jira_search_issues", status: "CALLING" }` | Tool invocation started |
| `TOOL_RESULT` | `{ toolName: "jira_search_issues", status: "DONE" }` | Tool returned result |
| `DONE` | `{}` | Stream complete |
| `ERROR` | `{ message: "..." }` | Stream error |

### 6.7 `AiChatService.java`

```
Responsibilities:
  • inject ChatClient (pre-wired with tools + memory)
  • streamChat(sessionId, userMessage) → Flux<StreamToken>
      - chatClient.prompt().user(userMessage).stream().content()
      - map each token to StreamToken(type=TOKEN, token=t)
      - concat DONE token on completion
      - onErrorReturn StreamToken(type=ERROR)
  • Chat memory is keyed by conversationId → pass sessionId as
    advisor parameter: CHAT_MEMORY_CONVERSATION_ID_KEY
```

### 6.8 `ConversationStore.java`

```
Responsibilities:
  • ConcurrentHashMap<String, List<ConversationMessage>> sessions
  • addMessage(sessionId, message)
  • getMessages(sessionId) → List<ConversationMessage>
  • getSessions() → List<SessionSummary>  (for sidebar API)
  • deleteSession(sessionId)
  • Max 100 sessions in memory; evict LRU when exceeded
```

### 6.9 `ConversationExportService.java`

```
Responsibilities:
  • exportAsHtml(sessionId) → String
      - Load messages from ConversationStore
      - Convert markdown in AI messages to HTML (CommonMark parser)
      - Render export-html.mustache → self-contained HTML
  • exportAsMd(sessionId) → String
      - Render export-md.mustache → clean Markdown
```

### 6.10 `ExportController.java`

```
GET /api/export/{sessionId}?format=html
  Response: Content-Type: text/html
            Content-Disposition: attachment; filename="conversation-{date}.html"

GET /api/export/{sessionId}?format=md
  Response: Content-Type: text/markdown
            Content-Disposition: attachment; filename="conversation-{date}.md"

GET /api/sessions
  Response: List<SessionSummary> (for sidebar)
```

---

## 7. Frontend Implementation Plan

### 7.1 Dependencies (`package.json`)

```json
{
  "dependencies": {
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "@stomp/stompjs": "^7.0.0",
    "sockjs-client": "^1.6.1",
    "react-markdown": "^9.0.0",
    "remark-gfm": "^4.0.0",
    "react-syntax-highlighter": "^15.5.0",
    "lucide-react": "^0.400.0",
    "uuid": "^9.0.0",
    "date-fns": "^3.0.0"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "vite": "^5.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "@types/react": "^18.3.0",
    "@types/sockjs-client": "^1.5.4",
    "@types/react-syntax-highlighter": "^15.5.13"
  }
}
```

### 7.2 Design Tokens (`variables.css`)

```css
:root {
  /* Brand */
  --color-primary:        #6366f1;   /* indigo-500 */
  --color-primary-dark:   #4f46e5;   /* indigo-600 */
  --color-secondary:      #8b5cf6;   /* violet-500 */

  /* Surfaces */
  --color-bg:             #ffffff;
  --color-bg-secondary:   #f8fafc;
  --color-bg-sidebar:     #0f172a;   /* slate-900 */
  --color-surface:        #ffffff;
  --color-border:         #e2e8f0;

  /* Chat bubbles */
  --color-bubble-user:    #e0e7ff;   /* indigo-100 */
  --color-bubble-ai:      #f8fafc;   /* slate-50  */
  --color-bubble-ai-border: #e2e8f0;

  /* Text */
  --color-text:           #0f172a;   /* slate-900 */
  --color-text-muted:     #64748b;   /* slate-500 */
  --color-text-sidebar:   #e2e8f0;

  /* Tool badges */
  --color-tool-bg:        #fef3c7;   /* amber-100 */
  --color-tool-text:      #92400e;   /* amber-800 */
  --color-tool-border:    #fbbf24;   /* amber-400 */

  /* Spacing */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;

  /* Radius */
  --radius-sm:     0.375rem;
  --radius-md:     0.75rem;
  --radius-lg:     1.25rem;
  --radius-bubble: 1.25rem;

  /* Font */
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
  --font-sans: 'Inter', system-ui, sans-serif;
}

/* Dark mode — respects system preference */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg:             #0f172a;
    --color-bg-secondary:   #1e293b;
    --color-surface:        #1e293b;
    --color-border:         #334155;
    --color-bubble-user:    #312e81;
    --color-bubble-ai:      #1e293b;
    --color-bubble-ai-border: #334155;
    --color-text:           #f1f5f9;
    --color-text-muted:     #94a3b8;
    --color-tool-bg:        #451a03;
    --color-tool-text:      #fde68a;
    --color-tool-border:    #92400e;
  }
}
```

### 7.3 `chat.types.ts` — TypeScript Interfaces

```typescript
export type MessageRole = 'user' | 'assistant';
export type TokenType = 'TOKEN' | 'TOOL_CALL' | 'TOOL_RESULT' | 'DONE' | 'ERROR';

export interface StreamToken {
  type: TokenType;
  token?: string;
  toolName?: string;
  status?: 'CALLING' | 'DONE' | 'ERROR';
  message?: string;
}

export interface ToolCall {
  toolName: string;
  status: 'CALLING' | 'DONE' | 'ERROR';
  timestamp: Date;
}

export interface ChatMessage {
  id: string;
  role: MessageRole;
  content: string;
  timestamp: Date;
  toolCalls?: ToolCall[];
  isStreaming?: boolean;
}

export interface Session {
  id: string;
  title: string;        // first user message, truncated
  createdAt: Date;
  messageCount: number;
}

export interface ChatRequest {
  sessionId: string;
  userMessage: string;
}
```

### 7.4 `useStompClient.ts` — Low-level STOMP Hook

```
Responsibilities:
  • Create SockJS + StompClient on mount
  • Manage connection lifecycle: CONNECTING → CONNECTED → DISCONNECTED
  • Expose: { client, isConnected }
  • Auto-reconnect on disconnect (5s backoff)
  • Cleanup on unmount
```

### 7.5 `useChatWebSocket.ts` — Chat Hook

```
Responsibilities:
  • Subscribe to /topic/session/{sessionId} via useStompClient
  • sendMessage(userMessage):
      - Add user message to local state immediately (optimistic UI)
      - Create placeholder AI message (isStreaming: true)
      - Send ChatRequest to /app/chat.send via STOMP
  • Handle incoming StreamToken frames:
      - TOKEN   → append token.token to streaming AI message content
      - TOOL_CALL → add ToolCall badge to streaming message
      - TOOL_RESULT → update ToolCall badge status to DONE
      - DONE    → mark streaming message isStreaming: false
      - ERROR   → show error toast, mark streaming false
  • Expose: { messages, activeToolCalls, isStreaming, sendMessage }
```

### 7.6 `ChatPage.tsx` — Page Layout

```
Layout: CSS Grid — 260px sidebar | 1fr main
  ┌────────────────────────────────────────────┐
  │  Sidebar (260px)  │  Chat Main (1fr)        │
  │  ───────────────  │  ─────────────────────  │
  │  [+ New Chat]     │  Header: session title  │
  │                   │  [Export ▼ HTML / MD]   │
  │  Session list:    │  ─────────────────────  │
  │  • Session 1      │  MessageList            │
  │  • Session 2      │  (scrollable)           │
  │  • Session 3      │  ─────────────────────  │
  │                   │  ChatInput              │
  └────────────────────────────────────────────┘
Responsive: sidebar collapses to drawer on mobile (container query)
```

### 7.7 `StreamingMessage.tsx`

```tsx
// Renders live token stream with blinking cursor
// Uses react-markdown + remark-gfm for markdown rendering
// Uses react-syntax-highlighter for code blocks
// Shows ToolCallBadge for each active/completed tool call
// Auto-scrolls to bottom as content grows (useEffect on content)
```

### 7.8 `ToolCallBadge.tsx`

```
Visual design:
  CALLING: amber pill with spinning circle icon + tool display name
           e.g. "🔍 Searching Confluence…"
  DONE:    green pill with checkmark icon
           e.g. "✓ Confluence (3 results)"
  ERROR:   red pill with X icon

Tool display names:
  confluence_search_pages  → "Confluence"
  jira_search_issues       → "Jira"
  jira_create_issue        → "Jira (creating)"
  bitbucket_list_prs       → "Bitbucket"
  bitbucket_get_file       → "Bitbucket (file)"
```

### 7.9 `ExportButton.tsx`

```
UI: Floating button (top-right of chat area) with dropdown:
  ┌─────────────────┐
  │ Export          │
  ├─────────────────┤
  │ 📄 as HTML      │
  │ 📝 as Markdown  │
  └─────────────────┘

On click:
  1. Call GET /api/export/{sessionId}?format=html|md
  2. Create Blob from response
  3. Create <a download> link and click() it programmatically
  4. Revoke object URL
```

---

## 8. MCP Tool Integration Plan

### 8.1 Confluence MCP Tools

```java
@Component
@RequiredArgsConstructor
public class ConfluenceMcpTools {

    @Tool(description = "Search Confluence pages by keyword and optional space key")
    public List<PageSummary> confluenceSearchPages(
        @ToolParam(description = "Search query text") String query,
        @ToolParam(description = "Confluence space key (optional, e.g. 'ENG')") String spaceKey);

    @Tool(description = "Get the full content of a Confluence page by its page ID")
    public PageContent confluenceGetPage(
        @ToolParam(description = "Confluence page ID") String pageId);

    @Tool(description = "Create a new Confluence page in a space")
    public PageSummary confluenceCreatePage(
        @ToolParam(description = "Space key")    String spaceKey,
        @ToolParam(description = "Page title")   String title,
        @ToolParam(description = "Page body in storage format (HTML or wiki markup)") String body);

    @Tool(description = "Update the content of an existing Confluence page")
    public PageSummary confluenceUpdatePage(
        @ToolParam(description = "Page ID")             String pageId,
        @ToolParam(description = "New title")           String title,
        @ToolParam(description = "New body content")    String body,
        @ToolParam(description = "Current page version number") int version);
}
```

**Confluence API:** `GET /wiki/rest/api/content/search`, `GET /wiki/rest/api/content/{id}`, `POST /wiki/rest/api/content`, `PUT /wiki/rest/api/content/{id}`

### 8.2 Jira MCP Tools

```java
@Component
@RequiredArgsConstructor
public class JiraMcpTools {

    @Tool(description = "Search Jira issues using JQL (Jira Query Language)")
    public List<IssueSummary> jiraSearchIssues(
        @ToolParam(description = "JQL query, e.g. 'project = ENG AND status = Open'") String jql,
        @ToolParam(description = "Maximum results to return (default 20)") int maxResults);

    @Tool(description = "Get full details of a Jira issue by its key")
    public IssueDetail jiraGetIssue(
        @ToolParam(description = "Jira issue key, e.g. 'ENG-1234'") String issueKey);

    @Tool(description = "Create a new Jira issue in a project")
    public IssueSummary jiraCreateIssue(
        @ToolParam(description = "Project key")          String projectKey,
        @ToolParam(description = "Issue summary/title")  String summary,
        @ToolParam(description = "Issue type: Bug, Story, Task, Epic") String issueType,
        @ToolParam(description = "Issue description")    String description,
        @ToolParam(description = "Priority: Highest, High, Medium, Low") String priority);

    @Tool(description = "Add a comment to an existing Jira issue")
    public void jiraAddComment(
        @ToolParam(description = "Jira issue key") String issueKey,
        @ToolParam(description = "Comment text")   String comment);
}
```

**Jira API:** `GET /rest/api/3/search`, `GET /rest/api/3/issue/{key}`, `POST /rest/api/3/issue`, `POST /rest/api/3/issue/{key}/comment`

### 8.3 Bitbucket MCP Tools

```java
@Component
@RequiredArgsConstructor
public class BitbucketMcpTools {

    @Tool(description = "List repositories in a Bitbucket project or workspace")
    public List<RepoSummary> bitbucketListRepos(
        @ToolParam(description = "Project key or workspace slug") String project);

    @Tool(description = "Get the content of a file from a Bitbucket repository")
    public String bitbucketGetFile(
        @ToolParam(description = "Repository slug")       String repoSlug,
        @ToolParam(description = "File path in the repo") String filePath,
        @ToolParam(description = "Branch or commit ref (default: main)") String ref);

    @Tool(description = "List pull requests in a Bitbucket repository")
    public List<PrSummary> bitbucketListPrs(
        @ToolParam(description = "Repository slug")       String repoSlug,
        @ToolParam(description = "State: OPEN, MERGED, DECLINED") String state);

    @Tool(description = "Get the diff of a pull request")
    public String bitbucketGetPrDiff(
        @ToolParam(description = "Repository slug") String repoSlug,
        @ToolParam(description = "Pull request ID") int prId);
}
```

**Bitbucket API:** `GET /rest/api/latest/repos`, `GET /rest/api/latest/projects/{key}/repos/{slug}/browse/{path}`, `GET /rest/api/latest/projects/{key}/repos/{slug}/pull-requests`, `GET /rest/api/latest/projects/{key}/repos/{slug}/pull-requests/{id}/diff`

---

## 9. WebSocket & Streaming Design

### 9.1 STOMP Topic Structure

```
Inbound (client → server):
  /app/chat.send         → ChatWebSocketController.handleMessage()
  /app/session.new       → ChatWebSocketController.newSession()
  /app/session.delete    → ChatWebSocketController.deleteSession()

Outbound (server → client):
  /topic/session/{id}    → StreamToken frames (TOKEN, TOOL_CALL, DONE, ERROR)
  /user/queue/sessions   → Session list updates (on new/delete)
```

### 9.2 Streaming Flow with Tool Calls

```
User sends: "Find all open Jira bugs in project ENG assigned to me"

1. ChatWebSocketController receives ChatRequest
2. AiChatService.streamChat() calls ChatClient.prompt().stream()
3. ChatClient sends to Copilot LLM → LLM decides to call jira_search_issues
4. Spring AI intercepts tool call → invokes JiraMcpTools.jiraSearchIssues()
   → Frontend receives: TOOL_CALL { toolName: "jira_search_issues", status: "CALLING" }
5. JiraMcpTools calls Jira REST API → gets results
   → Frontend receives: TOOL_RESULT { toolName: "jira_search_issues", status: "DONE" }
6. Tool result fed back to LLM → LLM streams final response
   → Frontend receives: TOKEN, TOKEN, TOKEN, ..., DONE
```

### 9.3 Backpressure & Error Handling

```
• Flux.onBackpressureBuffer(256) on the streaming chain
• timeout(Duration.ofSeconds(60)) per request
• onErrorResume() → emit StreamToken(ERROR) instead of crashing session
• WebSocket session cleanup in afterConnectionClosed()
• Thread safety: all session state in ConcurrentHashMap
```

---

## 10. Conversation Export Design

### 10.1 HTML Export (`export-html.mustache`)

The exported HTML file is **fully self-contained** (no external dependencies at runtime):

```
┌──────────────────────────────────────────────────────────────┐
│  AI Assistant — Conversation Export                          │
│  📅 March 28, 2026  ·  Model: gpt-4o  ·  12 messages        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  👤 You — 14:23                                             │
│  ┌──────────────────────────────────────────────┐           │
│  │ Find all open Jira bugs assigned to me       │           │
│  └──────────────────────────────────────────────┘           │
│                                                              │
│  🤖 Assistant — 14:23                                       │
│  🔍 Searched Jira  ✓ 5 results                              │
│  ┌──────────────────────────────────────────────┐           │
│  │ I found **5 open bugs** assigned to you:    │           │
│  │                                              │           │
│  │ | Key      | Summary          | Priority |  │           │
│  │ |----------|------------------|----------|  │           │
│  │ | ENG-1234 | Login timeout    | High     |  │           │
│  │ | ENG-1287 | PDF export fails | Medium   |  │           │
│  └──────────────────────────────────────────────┘           │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  Exported by MCP AI Assistant · March 28, 2026              │
└──────────────────────────────────────────────────────────────┘
```

**HTML template features:**
- Inline CSS with Inter font (Google Fonts CDN — one external call acceptable for HTML)
- Prism.js (CDN) for code block syntax highlighting
- Responsive layout (max-width 900px, centered)
- Tool call badges rendered as styled `<span>` elements
- Markdown rendered server-side via CommonMark Java parser
- Print-friendly `@media print` styles

### 10.2 Markdown Export (`export-md.mustache`)

```markdown
# AI Assistant — Conversation Export
**Date:** March 28, 2026 | **Model:** gpt-4o | **Messages:** 12

---

## Session: abc-123

### 👤 You *(14:23)*

Find all open Jira bugs assigned to me

---

### 🤖 Assistant *(14:23)*

> 🔍 **Tool called:** `jira_search_issues` — ✅ Done

I found **5 open bugs** assigned to you:

| Key      | Summary          | Priority |
|----------|------------------|----------|
| ENG-1234 | Login timeout    | High     |
| ENG-1287 | PDF export fails | Medium   |

---

*Exported by MCP AI Assistant on March 28, 2026*
```

---

## 11. Configuration & Environment Variables

### 11.1 `application.yml`

```yaml
server:
  port: 8080

spring:
  application:
    name: mcp-ai-assistant

  ai:
    openai:
      base-url: https://api.githubcopilot.com
      api-key: ${GITHUB_COPILOT_TOKEN}
      chat:
        options:
          model: gpt-4o
          temperature: 0.7
          max-tokens: 4096
    mcp:
      server:
        name: mcp-ai-assistant
        version: 1.0.0
        type: SSE
        sse-endpoint: /mcp/sse
        message-endpoint: /mcp/messages

mcp:
  tools:
    confluence:
      base-url: ${CONFLUENCE_BASE_URL}
      token: ${CONFLUENCE_TOKEN}
      username: ${CONFLUENCE_USERNAME}
    jira:
      base-url: ${JIRA_BASE_URL}
      token: ${JIRA_TOKEN}
      username: ${JIRA_USERNAME}
    bitbucket:
      base-url: ${BITBUCKET_BASE_URL}
      token: ${BITBUCKET_TOKEN}

logging:
  level:
    com.ai.assistant: DEBUG
    org.springframework.ai: DEBUG
    org.springframework.web.socket: INFO
```

### 11.2 Environment Variables Reference

| Variable | Description | Example |
|---|---|---|
| `GITHUB_COPILOT_TOKEN` | GitHub PAT with Copilot API scope | `ghp_xxxxxxxxxxxx` |
| `CONFLUENCE_BASE_URL` | Confluence instance base URL | `https://myorg.atlassian.net` |
| `CONFLUENCE_USERNAME` | Confluence account email | `user@myorg.com` |
| `CONFLUENCE_TOKEN` | Confluence API token | `ATATT3xFfGF0...` |
| `JIRA_BASE_URL` | Jira instance base URL | `https://myorg.atlassian.net` |
| `JIRA_USERNAME` | Jira account email | `user@myorg.com` |
| `JIRA_TOKEN` | Jira API token | `ATATT3xFfGF0...` |
| `BITBUCKET_BASE_URL` | Bitbucket instance base URL | `https://bitbucket.myorg.com` |
| `BITBUCKET_TOKEN` | Bitbucket HTTP access token | `BBToken_xxxx` |

> **Note:** For Atlassian Cloud, Jira and Confluence share the same base URL and API token. Use Basic auth: `Base64(username:token)`.

---

## 12. API Contract

### 12.1 WebSocket/STOMP Messages

**Inbound — `ChatRequest` (client → `/app/chat.send`)**
```json
{
  "sessionId": "sess-uuid-1234",
  "userMessage": "Find all open Jira bugs assigned to me"
}
```

**Outbound — `StreamToken` (`/topic/session/{sessionId}`)**
```json
// TEXT token
{ "type": "TOKEN", "token": "I found " }

// Tool call started
{ "type": "TOOL_CALL", "toolName": "jira_search_issues", "status": "CALLING" }

// Tool call completed
{ "type": "TOOL_RESULT", "toolName": "jira_search_issues", "status": "DONE" }

// Stream complete
{ "type": "DONE" }

// Error
{ "type": "ERROR", "message": "LLM rate limit exceeded" }
```

### 12.2 REST Endpoints

```
GET  /api/health
     Response: 200 { "status": "UP", "version": "1.0.0" }

GET  /api/sessions
     Response: 200 [ { "id": "...", "title": "...", "createdAt": "...", "messageCount": 5 } ]

GET  /api/sessions/{sessionId}/messages
     Response: 200 [ { "id":"...", "role":"user|assistant", "content":"...", "timestamp":"..." } ]

DELETE /api/sessions/{sessionId}
     Response: 204

GET  /api/export/{sessionId}?format=html
     Response: 200  Content-Type: text/html
               Content-Disposition: attachment; filename="conversation-2026-03-28.html"

GET  /api/export/{sessionId}?format=md
     Response: 200  Content-Type: text/markdown
               Content-Disposition: attachment; filename="conversation-2026-03-28.md"

GET  /mcp/sse          ← MCP SSE transport endpoint
POST /mcp/messages     ← MCP JSON-RPC messages endpoint
```

---

## 13. Dependency Versions

| Component | Library | Version |
|---|---|---|
| **Runtime** | Java | 17 |
| **Framework** | Spring Boot | 3.4.1 |
| **AI** | Spring AI BOM | 1.0.0 |
| **AI Starter** | spring-ai-openai-spring-boot-starter | 1.0.0 |
| **MCP Server** | spring-ai-mcp-server-spring-boot-starter | 1.0.0 |
| **Reactive** | Spring WebFlux / Project Reactor | 3.6.x (via Boot BOM) |
| **Templating** | com.github.spullara.mustache.java:compiler | 0.9.14 |
| **Markdown (server)** | org.commonmark:commonmark | 0.22.0 |
| **Utilities** | Lombok | 1.18.32 |
| **Frontend** | React | 18.3.0 |
| **Frontend** | TypeScript | 5.4.0 |
| **Build** | Vite | 5.2.0 |
| **WebSocket client** | @stomp/stompjs | 7.0.0 |
| **WebSocket fallback** | sockjs-client | 1.6.1 |
| **Markdown render** | react-markdown | 9.0.0 |
| **Markdown GFM** | remark-gfm | 4.0.0 |
| **Syntax highlight** | react-syntax-highlighter | 15.5.0 |
| **Icons** | lucide-react | 0.400.0 |

---

## 14. Implementation Steps

### Phase 1 — Backend Scaffold (Day 1)
- [ ] 1.1 Create `backend/pom.xml` with all dependencies
- [ ] 1.2 Create `McpAiAssistantApplication.java`
- [ ] 1.3 Create `application.yml` with all config keys
- [ ] 1.4 Implement `ChatClientConfig.java`
- [ ] 1.5 Implement `WebSocketStompConfig.java`
- [ ] 1.6 Implement `McpServerConfig.java`
- [ ] 1.7 Implement `CorsConfig.java`
- [ ] 1.8 Implement `HealthController.java`
- [ ] **Milestone:** `mvn spring-boot:run` starts, `/api/health` returns 200, `/ws` accepts STOMP connect

### Phase 2 — MCP Tools & API Clients (Day 2)
- [ ] 2.1 Implement `ConfluenceApiClient.java` (WebClient, Basic auth)
- [ ] 2.2 Implement `ConfluenceMcpTools.java` (4 tools)
- [ ] 2.3 Implement `JiraApiClient.java` (WebClient, Basic auth)
- [ ] 2.4 Implement `JiraMcpTools.java` (4 tools)
- [ ] 2.5 Implement `BitbucketApiClient.java` (WebClient, Bearer token)
- [ ] 2.6 Implement `BitbucketMcpTools.java` (4 tools)
- [ ] **Milestone:** `/mcp/sse` connects, tools listed via MCP `ListTools` request

### Phase 3 — Chat Service & WebSocket Controller (Day 2–3)
- [ ] 3.1 Implement `ConversationStore.java`
- [ ] 3.2 Implement `ConversationMessage.java`, `ChatRequest.java`, `StreamToken.java`
- [ ] 3.3 Implement `AiChatService.java` (streaming + tool events)
- [ ] 3.4 Implement `ChatWebSocketController.java`
- [ ] **Milestone:** Send a STOMP message, receive streaming tokens + tool call events in a STOMP client (e.g. Postman)

### Phase 4 — Export Service & Controller (Day 3)
- [ ] 4.1 Create `export-html.mustache` template
- [ ] 4.2 Create `export-md.mustache` template
- [ ] 4.3 Implement `ConversationExportService.java`
- [ ] 4.4 Implement `ExportController.java`
- [ ] **Milestone:** `GET /api/export/{id}?format=html` returns downloadable HTML file

### Phase 5 — React Frontend Scaffold (Day 3–4)
- [ ] 5.1 `npm create vite@latest frontend -- --template react-ts`
- [ ] 5.2 Install all npm dependencies
- [ ] 5.3 Create `variables.css` design tokens
- [ ] 5.4 Implement `useStompClient.ts`
- [ ] 5.5 Implement `useChatWebSocket.ts`
- [ ] 5.6 Implement `chat.types.ts`
- [ ] **Milestone:** Browser connects to STOMP, sends a message, receives tokens to console

### Phase 6 — Chat UI Components (Day 4–5)
- [ ] 6.1 Implement `MessageBubble.tsx` (user + AI variants)
- [ ] 6.2 Implement `StreamingMessage.tsx` (live tokens + cursor + markdown)
- [ ] 6.3 Implement `ToolCallBadge.tsx` (CALLING / DONE / ERROR states)
- [ ] 6.4 Implement `MessageList.tsx` (auto-scroll)
- [ ] 6.5 Implement `ChatInput.tsx` (textarea + keyboard shortcut Ctrl+Enter)
- [ ] 6.6 Implement `ChatSidebar.tsx` (session list + new chat)
- [ ] 6.7 Implement `ChatRoom.tsx` + `ChatPage.tsx` (full layout)
- [ ] **Milestone:** Full chat UI works end-to-end with streaming

### Phase 7 — Export UI (Day 5)
- [ ] 7.1 Implement `useExport.ts`
- [ ] 7.2 Implement `ExportButton.tsx` (dropdown: HTML / MD)
- [ ] **Milestone:** Click "Export as HTML" → styled file downloads

### Phase 8 — Polish & Testing (Day 6)
- [ ] 8.1 Dark mode testing + fixes
- [ ] 8.2 Mobile/responsive layout
- [ ] 8.3 Backend unit tests (tool clients mocked)
- [ ] 8.4 Backend integration test (WebSocket STOMP)
- [ ] 8.5 Error states (LLM unavailable, tool failure, network loss)
- [ ] 8.6 README.md with setup instructions

---

## 15. Testing Strategy

### 15.1 Backend Tests

| Test Class | What it tests |
|---|---|
| `ChatWebSocketControllerTest` | STOMP send → receive TOKEN frames via `StompSession` |
| `AiChatServiceTest` | Mocked `ChatClient` → verify Flux stream tokens + DONE |
| `ConfluenceMcpToolsTest` | WireMock Confluence API → verify tool return values |
| `JiraMcpToolsTest` | WireMock Jira API → verify tool return values |
| `BitbucketMcpToolsTest` | WireMock Bitbucket API → verify tool return values |
| `ConversationExportServiceTest` | Known messages → rendered HTML/MD snapshot test |
| `ExportControllerTest` | `MockMvc` GET export → verify Content-Disposition header |

**Test dependencies:**
- `spring-boot-starter-test` (JUnit 5, Mockito, AssertJ)
- `wiremock-spring-boot` for HTTP client mocking
- `spring-boot-test-autoconfigure` WebSocket integration test support

### 15.2 Frontend Tests

| Test File | What it tests |
|---|---|
| `useChatWebSocket.test.ts` | Mock STOMP → verify message state accumulation |
| `StreamingMessage.test.tsx` | Renders markdown correctly, cursor shown during stream |
| `ToolCallBadge.test.tsx` | CALLING shows spinner, DONE shows check |
| `ExportButton.test.tsx` | Click triggers fetch + download |

---

## 16. Open Questions & Assumptions

### 16.1 Assumptions Made

| # | Assumption |
|---|---|
| A-01 | GitHub Copilot API token available with chat API access |
| A-02 | Atlassian Cloud APIs used (not Data Center) — REST API v3 for Jira, v2 for Confluence |
| A-03 | Bitbucket is Bitbucket Data Center (REST API v2) based on the MCP tools already configured |
| A-04 | Single-user or small-team deployment; in-memory session store is acceptable for v1 |
| A-05 | No authentication required on the chat UI (internal tool assumption) |
| A-06 | React 18 chosen over Angular (reference stack uses React 18 + TypeScript 5) |

### 16.2 Upgrade Path Notes

| Concern | v1 (this plan) | v2 upgrade path |
|---|---|---|
| Session persistence | In-memory `ConcurrentHashMap` | PostgreSQL + Spring Data JPA |
| Horizontal scaling | Single instance | Redis STOMP broker relay (`enableStompBrokerRelay`) |
| LLM provider | GitHub Copilot | Azure OpenAI / Anthropic (1-line `application.yml` change) |
| Auth | None (trust header) | Spring Security + JWT / OAuth2 |
| RAG | None | PGVector + `QuestionAnswerAdvisor` (Spring AI built-in) |
| MCP transport | SSE | Upgrade to Streamable HTTP (MCP spec 2025-11) |

---

*Plan version 1.0 — March 28, 2026 — Ready for implementation*
