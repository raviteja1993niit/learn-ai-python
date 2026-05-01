package com.ai.assistant.websocket.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Outbound STOMP frame pushed to {@code /topic/session/{sessionId}}.
 *
 * <p>Token types:
 * <ul>
 *   <li>{@code TOKEN}       — regular text token from the LLM stream</li>
 *   <li>{@code TOOL_CALL}   — LLM decided to call a tool (status=CALLING)</li>
 *   <li>{@code TOOL_RESULT} — tool execution completed (status=DONE|ERROR)</li>
 *   <li>{@code DONE}        — streaming complete for this turn</li>
 *   <li>{@code ERROR}       — unrecoverable error occurred</li>
 * </ul>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class StreamToken {

    public enum Type {
        TOKEN, TOOL_CALL, TOOL_RESULT, DONE, ERROR
    }

    public enum ToolStatus {
        CALLING, DONE, ERROR
    }

    /** Frame type — always present. */
    private Type type;

    /** Text content — present only for {@code TOKEN} frames. */
    private String token;

    /** Tool name — present for {@code TOOL_CALL} and {@code TOOL_RESULT} frames. */
    private String toolName;

    /** Tool execution status — present for {@code TOOL_CALL} and {@code TOOL_RESULT}. */
    private ToolStatus status;

    /** Error message — present for {@code ERROR} frames. */
    private String message;

    // ── Factory helpers ───────────────────────────────────────────

    public static StreamToken token(String text) {
        return StreamToken.builder().type(Type.TOKEN).token(text).build();
    }

    public static StreamToken toolCalling(String toolName) {
        return StreamToken.builder()
                .type(Type.TOOL_CALL)
                .toolName(toolName)
                .status(ToolStatus.CALLING)
                .build();
    }

    public static StreamToken toolDone(String toolName) {
        return StreamToken.builder()
                .type(Type.TOOL_RESULT)
                .toolName(toolName)
                .status(ToolStatus.DONE)
                .build();
    }

    public static StreamToken toolError(String toolName) {
        return StreamToken.builder()
                .type(Type.TOOL_RESULT)
                .toolName(toolName)
                .status(ToolStatus.ERROR)
                .build();
    }

    public static StreamToken done() {
        return StreamToken.builder().type(Type.DONE).build();
    }

    public static StreamToken error(String message) {
        return StreamToken.builder().type(Type.ERROR).message(message).build();
    }
}
