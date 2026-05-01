package com.ai.assistant.service;

import com.ai.assistant.websocket.model.ConversationMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * In-memory conversation store — persists messages per session for the lifetime
 * of the JVM process.
 *
 * <p>Implementation uses a size-bounded {@link LinkedHashMap} with LRU eviction
 * so that memory consumption stays predictable under load.
 *
 * <p>Upgrade path: replace with a Spring Data repository backed by PostgreSQL
 * or Redis without changing any callers.
 */
@Component
@Slf4j
public class ConversationStore {

    /** Holds session summaries for the sidebar API. */
    public record SessionSummary(
            String id,
            String title,
            Instant createdAt,
            int messageCount) {
    }

    private final int maxSessions;

    /** LRU-bounded map — oldest session evicted when maxSessions is exceeded. */
    private final Map<String, List<ConversationMessage>> sessions;

    /** Creation timestamps per session — used for sidebar ordering. */
    private final Map<String, Instant> createdAt;

    public ConversationStore(
            @Value("${conversation.store.max-sessions:100}") int maxSessions) {
        this.maxSessions = maxSessions;
        this.sessions = Collections.synchronizedMap(
                new LinkedHashMap<>(maxSessions, 0.75f, true) {
                    @Override
                    protected boolean removeEldestEntry(Map.Entry<String, List<ConversationMessage>> eldest) {
                        if (size() > maxSessions) {
                            log.info("Evicting oldest session: {}", eldest.getKey());
                            createdAt.remove(eldest.getKey());
                            return true;
                        }
                        return false;
                    }
                });
        this.createdAt = Collections.synchronizedMap(new LinkedHashMap<>());
    }

    /**
     * Append a message to a session, creating the session if it does not exist.
     *
     * @param sessionId session identifier
     * @param role      {@code user} or {@code assistant}
     * @param content   message content
     * @return the stored {@link ConversationMessage}
     */
    public ConversationMessage addMessage(
            String sessionId,
            ConversationMessage.Role role,
            String content) {

        ConversationMessage message = ConversationMessage.builder()
                .id(UUID.randomUUID().toString())
                .role(role)
                .content(content)
                .timestamp(Instant.now())
                .build();

        sessions.computeIfAbsent(sessionId, id -> {
            createdAt.put(id, Instant.now());
            log.debug("New conversation session created: {}", id);
            return new ArrayList<>();
        }).add(message);

        return message;
    }

    /**
     * Add a pre-built message (useful for assistant messages that carry tool-call metadata).
     *
     * @param sessionId session identifier
     * @param message   the pre-built message
     */
    public void addMessage(String sessionId, ConversationMessage message) {
        sessions.computeIfAbsent(sessionId, id -> {
            createdAt.put(id, Instant.now());
            return new ArrayList<>();
        }).add(message);
    }

    /**
     * Retrieve all messages for a session in chronological order.
     *
     * @param sessionId session identifier
     * @return unmodifiable list of messages, empty if session does not exist
     */
    public List<ConversationMessage> getMessages(String sessionId) {
        return Collections.unmodifiableList(
                sessions.getOrDefault(sessionId, Collections.emptyList()));
    }

    /**
     * Return a summary list of all sessions ordered by most-recently accessed.
     *
     * @return list of {@link SessionSummary} records
     */
    public List<SessionSummary> getSessions() {
        return sessions.entrySet().stream()
                .map(e -> {
                    List<ConversationMessage> messages = e.getValue();
                    String title = messages.isEmpty()
                            ? "New conversation"
                            : truncate(messages.get(0).getContent(), 60);
                    return new SessionSummary(
                            e.getKey(),
                            title,
                            Optional.ofNullable(createdAt.get(e.getKey())).orElse(Instant.now()),
                            messages.size());
                })
                .toList();
    }

    /**
     * Delete a session and all its messages.
     *
     * @param sessionId session identifier
     */
    public void deleteSession(String sessionId) {
        sessions.remove(sessionId);
        createdAt.remove(sessionId);
        log.debug("Session deleted: {}", sessionId);
    }

    /**
     * Check whether a session exists.
     *
     * @param sessionId session identifier
     * @return {@code true} if the session has at least one message
     */
    public boolean sessionExists(String sessionId) {
        return sessions.containsKey(sessionId);
    }

    // ── Private helpers ──────────────────────────────────────────────

    private String truncate(String text, int maxLength) {
        if (text == null) {
            return "New conversation";
        }
        return text.length() <= maxLength ? text : text.substring(0, maxLength) + "…";
    }
}
