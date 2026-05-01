package com.ai.assistant.websocket;

import com.ai.assistant.service.AiChatService;
import com.ai.assistant.service.ConversationStore;
import com.ai.assistant.websocket.model.ChatRequest;
import com.ai.assistant.websocket.model.ConversationMessage;
import com.ai.assistant.websocket.model.StreamToken;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * STOMP WebSocket controller — handles inbound chat messages and fans out
 * AI response tokens to the session-scoped topic.
 *
 * <p>Message routing:
 * <pre>
 *   Inbound:   /app/chat.send         → handleChatMessage()
 *   Outbound:  /topic/session/{id}    → StreamToken frames
 * </pre>
 *
 * <p>For each inbound message the flow is:
 * <ol>
 *   <li>Persist the user message to {@link ConversationStore}.</li>
 *   <li>Start a reactive {@link AiChatService#streamChat} pipeline.</li>
 *   <li>Push each {@link StreamToken} to the session topic.</li>
 *   <li>On DONE: assemble the full assistant message and persist it.</li>
 * </ol>
 */
@Controller
@RequiredArgsConstructor
@Slf4j
public class ChatWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final AiChatService aiChatService;
    private final ConversationStore conversationStore;

    /**
     * Handles an inbound chat message from the React frontend.
     *
     * @param request validated chat request containing sessionId and userMessage
     */
    @MessageMapping("/chat.send")
    public void handleChatMessage(@Valid @Payload ChatRequest request) {
        final String sessionId = request.getSessionId();
        final String destination = "/topic/session/" + sessionId;

        log.debug("Chat message received — session={} length={}",
                sessionId, request.getUserMessage().length());

        // 1. Persist user message immediately
        conversationStore.addMessage(
                sessionId,
                ConversationMessage.Role.user,
                request.getUserMessage());

        // 2. Accumulate the AI response tokens + tool call records for persistence
        StringBuilder fullResponse = new StringBuilder();
        List<ConversationMessage.ToolCallRecord> toolCallRecords = new ArrayList<>();

        // 3. Stream AI response tokens to the STOMP topic
        //    Pass the full request so AiChatService can apply per-request
        //    model selection and MCP tool filtering.
        aiChatService.streamChat(request)
                .subscribe(
                        token -> handleToken(token, destination, fullResponse, toolCallRecords),
                        error -> {
                            log.error("Unhandled stream error for session {}", sessionId, error);
                            sendSafely(destination, StreamToken.error("Unexpected stream error."));
                        },
                        () -> persistAssistantMessage(sessionId, fullResponse, toolCallRecords)
                );
    }

    // ── Private helpers ──────────────────────────────────────────────

    /**
     * Route each {@link StreamToken} frame — push to STOMP topic and accumulate
     * text content for persistence on completion.
     */
    private void handleToken(
            StreamToken token,
            String destination,
            StringBuilder fullResponse,
            List<ConversationMessage.ToolCallRecord> toolCallRecords) {

        sendSafely(destination, token);

        switch (token.getType()) {
            case TOKEN -> fullResponse.append(token.getToken());
            case TOOL_CALL -> toolCallRecords.add(
                    ConversationMessage.ToolCallRecord.builder()
                            .toolName(token.getToolName())
                            .status("CALLING")
                            .timestamp(Instant.now())
                            .build());
            case TOOL_RESULT -> {
                // Update the last matching tool call record status
                String toolName = token.getToolName();
                String status = StreamToken.ToolStatus.DONE == token.getStatus() ? "DONE" : "ERROR";
                for (int i = toolCallRecords.size() - 1; i >= 0; i--) {
                    if (toolName.equals(toolCallRecords.get(i).getToolName())
                            && "CALLING".equals(toolCallRecords.get(i).getStatus())) {
                        toolCallRecords.set(i,
                                ConversationMessage.ToolCallRecord.builder()
                                        .toolName(toolName)
                                        .status(status)
                                        .timestamp(Instant.now())
                                        .build());
                        break;
                    }
                }
            }
            default -> { /* DONE and ERROR handled by completion/error callbacks */ }
        }
    }

    /**
     * Persist the fully assembled assistant message once the stream completes.
     */
    private void persistAssistantMessage(
            String sessionId,
            StringBuilder fullResponse,
            List<ConversationMessage.ToolCallRecord> toolCallRecords) {

        if (fullResponse.isEmpty()) {
            log.warn("Empty assistant response for session {}", sessionId);
            return;
        }

        ConversationMessage assistantMessage = ConversationMessage.builder()
                .id(UUID.randomUUID().toString())
                .role(ConversationMessage.Role.assistant)
                .content(fullResponse.toString())
                .timestamp(Instant.now())
                .toolCalls(toolCallRecords)
                .build();

        conversationStore.addMessage(sessionId, assistantMessage);
        log.debug("Assistant message persisted for session={} length={}",
                sessionId, fullResponse.length());
    }

    /**
     * Send a {@link StreamToken} to the STOMP topic, logging and swallowing
     * any delivery errors so a single failed send does not abort the stream.
     */
    private void sendSafely(String destination, StreamToken token) {
        try {
            messagingTemplate.convertAndSend(destination, token);
        } catch (Exception e) {
            log.error("Failed to send token to {}: {}", destination, e.getMessage());
        }
    }
}
