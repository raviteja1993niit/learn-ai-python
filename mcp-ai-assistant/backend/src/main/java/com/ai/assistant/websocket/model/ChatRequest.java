package com.ai.assistant.websocket.model;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Inbound STOMP message payload sent by the React frontend to {@code /app/chat.send}.
 *
 * <p>In addition to the user message, the frontend may pass:
 * <ul>
 *   <li>{@code modelId}      — which LLM model to use (e.g. {@code "gpt-4o-mini"})</li>
 *   <li>{@code temperature}  — sampling temperature override [0.0–2.0]</li>
 *   <li>{@code maxTokens}    — response length cap override</li>
 *   <li>{@code selectedTools} — explicit subset of MCP tool names to enable</li>
 *   <li>{@code toolsDisabled} — disable all tool calling for this request</li>
 * </ul>
 * All override fields are optional; when absent the defaults from
 * {@code application.yml} are used.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatRequest {

    // ── Required ──────────────────────────────────────────────────────

    @NotBlank(message = "sessionId must not be blank")
    private String sessionId;

    @NotBlank(message = "userMessage must not be blank")
    @Size(max = 32_000, message = "userMessage must not exceed 32 000 characters")
    private String userMessage;

    // ── LLM overrides ────────────────────────────────────────────────

    /** Model id as returned by {@code GET /api/models}, e.g. {@code "gpt-4o"}. */
    private String modelId;

    @DecimalMin(value = "0.0", message = "temperature must be >= 0.0")
    @DecimalMax(value = "2.0", message = "temperature must be <= 2.0")
    private Double temperature;

    @Min(value = 1,      message = "maxTokens must be >= 1")
    @Max(value = 32_768, message = "maxTokens must be <= 32 768")
    private Integer maxTokens;

    // ── Tool selection ────────────────────────────────────────────────

    /**
     * Explicit list of MCP tool names the LLM may call for this request.
     * Names must match those returned by {@code GET /api/tools}.
     * {@code null} / empty  → all registered tools are available.
     */
    private List<String> selectedTools;

    /** When {@code true} no tools are offered to the LLM for this request. */
    @Builder.Default
    private boolean toolsDisabled = false;
}
