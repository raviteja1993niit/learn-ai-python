package com.ai.assistant.websocket.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * A single message in a conversation session — persisted in
 * {@link com.ai.assistant.service.ConversationStore}.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ConversationMessage {

    public enum Role {
        user, assistant
    }

    private String id;
    private Role role;
    private String content;
    private Instant timestamp;

    /** Tool calls made during this assistant turn (empty for user messages). */
    @Builder.Default
    private List<ToolCallRecord> toolCalls = new ArrayList<>();

    /**
     * Lightweight record of a tool call made during an assistant turn.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ToolCallRecord {
        private String toolName;
        private String status;   // CALLING | DONE | ERROR
        private Instant timestamp;
    }
}
