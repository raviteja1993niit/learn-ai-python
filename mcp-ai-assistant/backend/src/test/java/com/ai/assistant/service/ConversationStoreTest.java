package com.ai.assistant.service;

import com.ai.assistant.websocket.model.ConversationMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link ConversationStore}.
 */
class ConversationStoreTest {

    private ConversationStore store;

    @BeforeEach
    void setUp() {
        store = new ConversationStore(10);
    }

    @Test
    void shouldAddAndRetrieveMessagesBySessionId() {
        // Arrange
        String sessionId = "sess-001";

        // Act
        store.addMessage(sessionId, ConversationMessage.Role.user, "Hello AI");
        store.addMessage(sessionId, ConversationMessage.Role.assistant, "Hello! How can I help?");

        // Assert
        List<ConversationMessage> messages = store.getMessages(sessionId);
        assertThat(messages).hasSize(2);
        assertThat(messages.get(0).getRole()).isEqualTo(ConversationMessage.Role.user);
        assertThat(messages.get(0).getContent()).isEqualTo("Hello AI");
        assertThat(messages.get(1).getRole()).isEqualTo(ConversationMessage.Role.assistant);
    }

    @Test
    void shouldReturnEmptyListForNonExistentSession() {
        // Act
        List<ConversationMessage> messages = store.getMessages("non-existent-session");

        // Assert
        assertThat(messages).isEmpty();
    }

    @Test
    void shouldDeleteSession() {
        // Arrange
        String sessionId = "sess-002";
        store.addMessage(sessionId, ConversationMessage.Role.user, "Test message");
        assertThat(store.sessionExists(sessionId)).isTrue();

        // Act
        store.deleteSession(sessionId);

        // Assert
        assertThat(store.sessionExists(sessionId)).isFalse();
        assertThat(store.getMessages(sessionId)).isEmpty();
    }

    @Test
    void shouldReturnSessionSummaryWithFirstMessageAsTitle() {
        // Arrange
        String sessionId = "sess-003";
        store.addMessage(sessionId, ConversationMessage.Role.user,
                "Find all open Jira bugs");

        // Act
        List<ConversationStore.SessionSummary> sessions = store.getSessions();

        // Assert
        assertThat(sessions).hasSize(1);
        assertThat(sessions.get(0).title()).isEqualTo("Find all open Jira bugs");
        assertThat(sessions.get(0).messageCount()).isEqualTo(1);
    }

    @Test
    void shouldTruncateLongTitleAt60Characters() {
        // Arrange
        String sessionId = "sess-004";
        String longMessage = "A".repeat(80);
        store.addMessage(sessionId, ConversationMessage.Role.user, longMessage);

        // Act
        ConversationStore.SessionSummary summary = store.getSessions().get(0);

        // Assert — title must be truncated at 60 chars plus ellipsis
        assertThat(summary.title()).hasSize(61); // 60 chars + "…"
        assertThat(summary.title()).endsWith("…");
    }

    @Test
    void shouldSupportMultipleConcurrentSessions() {
        // Arrange + Act
        store.addMessage("session-A", ConversationMessage.Role.user, "Message A");
        store.addMessage("session-B", ConversationMessage.Role.user, "Message B");
        store.addMessage("session-A", ConversationMessage.Role.assistant, "Reply A");

        // Assert
        assertThat(store.getMessages("session-A")).hasSize(2);
        assertThat(store.getMessages("session-B")).hasSize(1);
        assertThat(store.getSessions()).hasSize(2);
    }
}
