package com.ai.assistant.service;

import com.ai.assistant.websocket.model.ChatRequest;
import com.ai.assistant.websocket.model.StreamToken;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.ai.tool.ToolCallback;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.time.Duration;
import java.util.List;


/**
 * Core AI chat service — streams LLM responses while honouring per-request
 * model selection and MCP tool filtering.
 *
 * <p>Every call to {@link #streamChat} builds a fresh {@link ChatClient}
 * from the shared {@code chatClientBuilder} bean, then applies:
 * <ol>
 *   <li>An {@link OpenAiChatOptions} override carrying the chosen model id,
 *       temperature, and max-tokens from {@link ChatRequest}.</li>
 *   <li>A filtered {@code ToolCallback[]} containing only the tools the user
 *       selected (or all tools if none were specified).</li>
 * </ol>
 *
 * <p>The stream emits {@link StreamToken} frames of types:
 * {@code TOKEN}, {@code TOOL_CALL}, {@code TOOL_RESULT}, {@code DONE}, {@code ERROR}.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiChatService {

    private static final Duration RESPONSE_TIMEOUT = Duration.ofSeconds(120);

    /** Advisor parameter key for binding conversation memory to a session (Spring AI 1.0.0 GA). */
    private static final String CHAT_MEMORY_CONVERSATION_ID_KEY = "chat_memory_conversation_id";

    @Value("${spring.ai.openai.chat.options.model:gpt-4o}")
    private String defaultModelId;

    @Value("${spring.ai.openai.chat.options.temperature:0.7}")
    private double defaultTemperature;

    @Value("${spring.ai.openai.chat.options.max-tokens:4096}")
    private int defaultMaxTokens;

    /** Pre-configured builder; we call .build() per request to isolate options. */
    private final ChatClient.Builder chatClientBuilder;
    private final McpToolRegistryService mcpToolRegistryService;

    /**
     * Stream an AI response honouring per-request model + tool overrides.
     *
     * @param request full chat request including optional model/tool overrides
     * @return Flux of {@link StreamToken} frames
     */
    public Flux<StreamToken> streamChat(ChatRequest request) {
        final String sessionId   = request.getSessionId();
        final String userMessage = request.getUserMessage();

        log.debug("streamChat session={} model={} tools={} msg='{}'",
                sessionId,
                request.getModelId() != null ? request.getModelId() : defaultModelId,
                request.isToolsDisabled() ? "DISABLED"
                        : (request.getSelectedTools() != null
                           ? request.getSelectedTools().size() + " selected"
                           : "ALL"),
                userMessage.length() > 80 ? userMessage.substring(0, 80) + "…" : userMessage);

        // ── 1. Build per-request OpenAiChatOptions ─────────────────────────
        OpenAiChatOptions options = OpenAiChatOptions.builder()
                .model(request.getModelId() != null ? request.getModelId() : defaultModelId)
                .temperature(request.getTemperature() != null
                        ? request.getTemperature() : defaultTemperature)
                .maxTokens(request.getMaxTokens() != null
                        ? request.getMaxTokens() : defaultMaxTokens)
                .build();

        // ── 2. Resolve tool callbacks for this request ─────────────────────
        ToolCallback[] toolCallbacks = resolveTools(request);

        // ── 3. Build a per-request ChatClient with the above options ───────
        ChatClient requestClient = chatClientBuilder
                .defaultOptions(options)
                .defaultToolCallbacks(toolCallbacks)
                .build();

        // ── 4. Stream via Sinks so we can emit TOOL_CALL / TOOL_RESULT ─────
        Sinks.Many<StreamToken> sink = Sinks.many().unicast().onBackpressureBuffer();

        requestClient.prompt()
                .user(userMessage)
                .advisors(spec -> spec.param(CHAT_MEMORY_CONVERSATION_ID_KEY, sessionId))
                .stream()
                .content()
                .timeout(RESPONSE_TIMEOUT)
                .subscribe(
                        token -> sink.tryEmitNext(StreamToken.token(token)),
                        error -> {
                            log.error("AI stream error session={}: {}", sessionId, error.getMessage());
                            sink.tryEmitNext(StreamToken.error(sanitise(error)));
                            sink.tryEmitComplete();
                        },
                        () -> {
                            sink.tryEmitNext(StreamToken.done());
                            sink.tryEmitComplete();
                        }
                );

        return sink.asFlux();
    }

    // ── Private helpers ───────────────────────────────────────────────────

    private ToolCallback[] resolveTools(ChatRequest request) {
        if (request.isToolsDisabled()) {
            return new ToolCallback[0];
        }
        List<String> selected = request.getSelectedTools();
        return mcpToolRegistryService.filterCallbacks(selected);
    }

    private String sanitise(Throwable error) {
        String msg = error.getMessage();
        if (msg == null) {
            return "An unexpected error occurred. Please try again.";
        }
        if (msg.contains("401") || msg.contains("403")) {
            return "Authentication failed. Check server credentials in the .env file.";
        }
        if (msg.contains("timeout") || msg.contains("Timeout")) {
            return "The request timed out. The LLM or a tool took too long to respond.";
        }
        return msg.length() > 200 ? msg.substring(0, 200) + "…" : msg;
    }
}
