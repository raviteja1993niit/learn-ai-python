package com.ai.assistant.service;

import com.ai.assistant.model.LlmModelDescriptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Static catalog of LLM models available via the GitHub Copilot
 * OpenAI-compatible endpoint.
 *
 * <p>The frontend calls {@code GET /api/models} and renders the list in the
 * model selector dropdown. The user's choice is forwarded as
 * {@code ChatRequest.modelId} and applied as an {@code OpenAiChatOptions}
 * override in {@link AiChatService}.
 *
 * <p>Add or remove models here when new ones become available through Copilot.
 */
@Service
public class ModelRegistryService {

    @Value("${spring.ai.openai.chat.options.model:gpt-4o}")
    private String defaultModelId;

    /**
     * Returns all available models ordered from most capable to most economical.
     *
     * @return immutable list of {@link LlmModelDescriptor}
     */
    public List<LlmModelDescriptor> getAvailableModels() {
        return List.of(
                // ── OpenAI flagship ───────────────────────────────────────
                LlmModelDescriptor.builder()
                        .id("gpt-4o")
                        .label("GPT-4o")
                        .provider("OpenAI via Copilot")
                        .contextWindow(128_000)
                        .toolsSupported(true)
                        .streamingSupported(true)
                        .description("Most capable multimodal model — best for complex reasoning and tool use")
                        .isDefault("gpt-4o".equals(defaultModelId))
                        .build(),

                LlmModelDescriptor.builder()
                        .id("gpt-4o-mini")
                        .label("GPT-4o Mini")
                        .provider("OpenAI via Copilot")
                        .contextWindow(128_000)
                        .toolsSupported(true)
                        .streamingSupported(true)
                        .description("Lightweight GPT-4o — fast and cost-efficient for most tasks")
                        .isDefault("gpt-4o-mini".equals(defaultModelId))
                        .build(),

                // ── OpenAI reasoning ──────────────────────────────────────
                LlmModelDescriptor.builder()
                        .id("o1")
                        .label("o1")
                        .provider("OpenAI via Copilot")
                        .contextWindow(200_000)
                        .toolsSupported(true)
                        .streamingSupported(false)
                        .description("Advanced reasoning model — best for math, code, and science")
                        .isDefault("o1".equals(defaultModelId))
                        .build(),

                LlmModelDescriptor.builder()
                        .id("o1-mini")
                        .label("o1 Mini")
                        .provider("OpenAI via Copilot")
                        .contextWindow(128_000)
                        .toolsSupported(true)
                        .streamingSupported(false)
                        .description("Compact reasoning model — faster o1 for STEM tasks")
                        .isDefault("o1-mini".equals(defaultModelId))
                        .build(),

                LlmModelDescriptor.builder()
                        .id("o3-mini")
                        .label("o3 Mini")
                        .provider("OpenAI via Copilot")
                        .contextWindow(200_000)
                        .toolsSupported(true)
                        .streamingSupported(false)
                        .description("Latest compact reasoning model with improved performance")
                        .isDefault("o3-mini".equals(defaultModelId))
                        .build(),

                // ── Anthropic via Copilot ─────────────────────────────────
                LlmModelDescriptor.builder()
                        .id("claude-3-5-sonnet")
                        .label("Claude 3.5 Sonnet")
                        .provider("Anthropic via Copilot")
                        .contextWindow(200_000)
                        .toolsSupported(true)
                        .streamingSupported(true)
                        .description("Excellent for long documents, coding and nuanced reasoning")
                        .isDefault("claude-3-5-sonnet".equals(defaultModelId))
                        .build(),

                LlmModelDescriptor.builder()
                        .id("claude-3-7-sonnet")
                        .label("Claude 3.7 Sonnet")
                        .provider("Anthropic via Copilot")
                        .contextWindow(200_000)
                        .toolsSupported(true)
                        .streamingSupported(true)
                        .description("Latest Claude with hybrid reasoning — strongest for agentic workflows")
                        .isDefault("claude-3-7-sonnet".equals(defaultModelId))
                        .build(),

                // ── Google via Copilot ────────────────────────────────────
                LlmModelDescriptor.builder()
                        .id("gemini-2.0-flash")
                        .label("Gemini 2.0 Flash")
                        .provider("Google via Copilot")
                        .contextWindow(1_000_000)
                        .toolsSupported(true)
                        .streamingSupported(true)
                        .description("Ultra-fast multimodal model with 1M token context window")
                        .isDefault("gemini-2.0-flash".equals(defaultModelId))
                        .build()
        );
    }

    /**
     * Returns a single model descriptor by id, or the default model if not found.
     *
     * @param modelId model identifier
     * @return matching descriptor, or the default model descriptor
     */
    public LlmModelDescriptor getModel(String modelId) {
        if (modelId == null || modelId.isBlank()) {
            return getDefaultModel();
        }
        return getAvailableModels().stream()
                .filter(m -> m.getId().equals(modelId))
                .findFirst()
                .orElseGet(this::getDefaultModel);
    }

    /**
     * Returns the default model (matching {@code spring.ai.openai.chat.options.model}).
     */
    public LlmModelDescriptor getDefaultModel() {
        return getAvailableModels().stream()
                .filter(LlmModelDescriptor::isDefault)
                .findFirst()
                .orElse(getAvailableModels().get(0));
    }
}
