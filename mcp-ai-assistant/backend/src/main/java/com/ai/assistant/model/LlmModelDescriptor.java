package com.ai.assistant.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

/**
 * Descriptor for an available LLM model returned by {@code GET /api/models}.
 *
 * <p>The frontend uses this list to populate the model selector dropdown.
 */
@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LlmModelDescriptor {

    /** Model identifier sent in {@code ChatRequest.modelId}. */
    private String id;

    /** Human-readable display name shown in the frontend dropdown. */
    private String label;

    /** Provider name for display grouping. */
    private String provider;

    /** Context window size in tokens. */
    private Integer contextWindow;

    /** Whether this model supports tool/function calling. */
    private boolean toolsSupported;

    /** Whether this model supports streaming responses. */
    private boolean streamingSupported;

    /** Short capability summary shown as a tooltip. */
    private String description;

    /** Whether this is the currently configured default model. */
    private boolean isDefault;
}
