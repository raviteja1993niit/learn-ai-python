package com.ai.assistant.service;

import com.ai.assistant.websocket.model.ConversationMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for {@link ConversationExportService}.
 */
class ConversationExportServiceTest {

    private ConversationStore conversationStore;
    private ConversationExportService exportService;

    @BeforeEach
    void setUp() {
        conversationStore = new ConversationStore(50);
        exportService = new ConversationExportService(conversationStore);
    }

    @Test
    void shouldExportConversationAsHtmlContainingMessageContent() {
        // Arrange
        String sessionId = "export-sess-001";
        conversationStore.addMessage(sessionId, ConversationMessage.Role.user,
                "Show me all open Jira bugs");
        conversationStore.addMessage(sessionId, ConversationMessage.Role.assistant,
                "I found **3 open bugs** in your project.");

        // Act
        String html = exportService.exportAsHtml(sessionId);

        // Assert
        assertThat(html).contains("<!DOCTYPE html>");
        assertThat(html).contains("Show me all open Jira bugs");
        assertThat(html).contains("I found");
        assertThat(html).contains("3 open bugs");          // markdown rendered
        assertThat(html).contains("message--user");
        assertThat(html).contains("message--ai");
        assertThat(html).contains("AI Assistant");
    }

    @Test
    void shouldExportConversationAsMarkdownWithProperHeaders() {
        // Arrange
        String sessionId = "export-sess-002";
        conversationStore.addMessage(sessionId, ConversationMessage.Role.user, "List Jira projects");
        conversationStore.addMessage(sessionId, ConversationMessage.Role.assistant, "Here are the projects.");

        // Act
        String md = exportService.exportAsMarkdown(sessionId);

        // Assert
        assertThat(md).startsWith("# AI Assistant — Conversation Export");
        assertThat(md).contains("👤 You");
        assertThat(md).contains("🤖 Assistant");
        assertThat(md).contains("List Jira projects");
        assertThat(md).contains("Here are the projects.");
    }

    @Test
    void shouldIncludeToolCallBadgesInHtmlExport() {
        // Arrange
        String sessionId = "export-sess-003";
        conversationStore.addMessage(sessionId, ConversationMessage.Role.user,
                "Search Confluence for onboarding docs");

        ConversationMessage assistantMsg = ConversationMessage.builder()
                .id(UUID.randomUUID().toString())
                .role(ConversationMessage.Role.assistant)
                .content("I found several onboarding pages.")
                .timestamp(Instant.now())
                .toolCalls(List.of(
                        ConversationMessage.ToolCallRecord.builder()
                                .toolName("searchContent")
                                .status("DONE")
                                .timestamp(Instant.now())
                                .build()))
                .build();
        conversationStore.addMessage(sessionId, assistantMsg);

        // Act
        String html = exportService.exportAsHtml(sessionId);

        // Assert
        assertThat(html).contains("tool-badge");
        assertThat(html).contains("searchContent");
        assertThat(html).contains("badge--done");
    }

    @Test
    void shouldThrowIllegalArgumentExceptionForNonExistentSession() {
        // Arrange
        String nonExistentSessionId = "does-not-exist";

        // Act + Assert
        assertThatThrownBy(() -> exportService.exportAsHtml(nonExistentSessionId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(nonExistentSessionId);

        assertThatThrownBy(() -> exportService.exportAsMarkdown(nonExistentSessionId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(nonExistentSessionId);
    }

    @Test
    void shouldRenderMarkdownTablesInHtmlExport() {
        // Arrange
        String sessionId = "export-sess-004";
        String tableMarkdown = """
                | Key      | Summary       | Status |
                |----------|---------------|--------|
                | ENG-1234 | Login timeout | Open   |
                """;
        conversationStore.addMessage(sessionId, ConversationMessage.Role.assistant, tableMarkdown);

        // Act
        String html = exportService.exportAsHtml(sessionId);

        // Assert — CommonMark GFM tables extension should render the table
        assertThat(html).contains("<table>");
        assertThat(html).contains("ENG-1234");
        assertThat(html).contains("Login timeout");
    }
}
