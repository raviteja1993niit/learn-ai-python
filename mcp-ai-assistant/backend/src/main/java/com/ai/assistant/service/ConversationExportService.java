package com.ai.assistant.service;

import com.ai.assistant.websocket.model.ConversationMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.commonmark.ext.gfm.tables.TablesExtension;
import org.commonmark.node.Node;
import org.commonmark.parser.Parser;
import org.commonmark.renderer.html.HtmlRenderer;
import org.springframework.stereotype.Service;

import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Renders a conversation session into a self-contained HTML page or a
 * clean Markdown document suitable for download.
 *
 * <p>HTML export features:
 * <ul>
 *   <li>Self-contained — inline CSS, no external runtime dependencies</li>
 *   <li>Prism.js syntax highlighting loaded from CDN (acceptable for export)</li>
 *   <li>Responsive layout, print-friendly {@code @media print} styles</li>
 *   <li>Dark/light auto-detection via {@code prefers-color-scheme}</li>
 *   <li>Tool-call badges rendered as styled spans</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ConversationExportService {

    private static final DateTimeFormatter DISPLAY_FMT =
            DateTimeFormatter.ofPattern("MMM dd, yyyy HH:mm")
                    .withZone(ZoneId.systemDefault());

    private final Parser markdownParser = Parser.builder()
            .extensions(List.of(TablesExtension.create()))
            .build();

    private final HtmlRenderer htmlRenderer = HtmlRenderer.builder()
            .extensions(List.of(TablesExtension.create()))
            .escapeHtml(false)
            .build();

    private final ConversationStore conversationStore;

    /**
     * Export a session as a self-contained HTML file.
     *
     * @param sessionId the session to export
     * @return complete HTML document as a string
     * @throws IllegalArgumentException if the session does not exist
     */
    public String exportAsHtml(String sessionId) {
        List<ConversationMessage> messages = getMessages(sessionId);
        String messagesHtml = messages.stream()
                .map(this::renderMessageHtml)
                .collect(Collectors.joining("\n"));
        String exportDate = DISPLAY_FMT.format(java.time.Instant.now());
        int messageCount = messages.size();

        return buildHtmlDocument(messagesHtml, exportDate, messageCount, sessionId);
    }

    /**
     * Export a session as a Markdown document.
     *
     * @param sessionId the session to export
     * @return Markdown document as a string
     * @throws IllegalArgumentException if the session does not exist
     */
    public String exportAsMarkdown(String sessionId) {
        List<ConversationMessage> messages = getMessages(sessionId);
        String exportDate = DISPLAY_FMT.format(java.time.Instant.now());

        StringBuilder sb = new StringBuilder();
        sb.append("# AI Assistant — Conversation Export\n\n");
        sb.append("**Date:** ").append(exportDate)
                .append(" | **Session:** `").append(sessionId)
                .append("` | **Messages:** ").append(messages.size()).append("\n\n");
        sb.append("---\n\n");

        for (ConversationMessage msg : messages) {
            String timestamp = DISPLAY_FMT.format(msg.getTimestamp());
            if (msg.getRole() == ConversationMessage.Role.user) {
                sb.append("### 👤 You *(").append(timestamp).append(")*\n\n");
                sb.append(msg.getContent()).append("\n\n");
            } else {
                sb.append("### 🤖 Assistant *(").append(timestamp).append(")*\n\n");
                // Render tool call badges
                if (msg.getToolCalls() != null && !msg.getToolCalls().isEmpty()) {
                    for (ConversationMessage.ToolCallRecord tc : msg.getToolCalls()) {
                        String icon = "DONE".equals(tc.getStatus()) ? "✅" : "❌";
                        sb.append("> 🔍 **Tool called:** `").append(tc.getToolName())
                                .append("` — ").append(icon).append(" ").append(tc.getStatus())
                                .append("\n\n");
                    }
                }
                sb.append(msg.getContent()).append("\n\n");
            }
            sb.append("---\n\n");
        }

        sb.append("*Exported by MCP AI Assistant on ").append(exportDate).append("*\n");
        return sb.toString();
    }

    // ── Private helpers ──────────────────────────────────────────────

    private List<ConversationMessage> getMessages(String sessionId) {
        List<ConversationMessage> messages = conversationStore.getMessages(sessionId);
        if (messages.isEmpty()) {
            throw new IllegalArgumentException("Session not found or has no messages: " + sessionId);
        }
        return messages;
    }

    private String renderMessageHtml(ConversationMessage msg) {
        String timestamp = DISPLAY_FMT.format(msg.getTimestamp());
        boolean isUser = msg.getRole() == ConversationMessage.Role.user;
        String roleClass = isUser ? "message--user" : "message--ai";
        String roleLabel = isUser ? "👤 You" : "🤖 Assistant";
        String contentHtml = isUser
                ? escapeHtml(msg.getContent())
                : markdownToHtml(msg.getContent());

        StringBuilder toolBadges = new StringBuilder();
        if (!isUser && msg.getToolCalls() != null && !msg.getToolCalls().isEmpty()) {
            toolBadges.append("<div class=\"tool-badges\">");
            for (ConversationMessage.ToolCallRecord tc : msg.getToolCalls()) {
                String badgeClass = "DONE".equals(tc.getStatus()) ? "badge--done" : "badge--error";
                String icon = "DONE".equals(tc.getStatus()) ? "✓" : "✗";
                toolBadges.append("<span class=\"tool-badge ").append(badgeClass).append("\">")
                        .append(icon).append(" ").append(escapeHtml(tc.getToolName()))
                        .append("</span>");
            }
            toolBadges.append("</div>");
        }

        return """
                <div class="message %s">
                  <div class="message__header">
                    <span class="message__role">%s</span>
                    <span class="message__time">%s</span>
                  </div>
                  %s
                  <div class="message__body">%s</div>
                </div>
                """.formatted(roleClass, roleLabel, timestamp,
                toolBadges.toString(), contentHtml);
    }

    private String markdownToHtml(String markdown) {
        if (markdown == null || markdown.isBlank()) {
            return "";
        }
        Node document = markdownParser.parse(markdown);
        return htmlRenderer.render(document);
    }

    private String escapeHtml(String text) {
        if (text == null) {
            return "";
        }
        return text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private String buildHtmlDocument(
            String messagesHtml, String exportDate, int messageCount, String sessionId) {
        return """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="UTF-8"/>
                  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                  <title>AI Assistant — Conversation Export</title>
                  <link rel="preconnect" href="https://fonts.googleapis.com"/>
                  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet"/>
                  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css"/>
                  <style>
                    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
                    :root {
                      --bg: #ffffff; --bg2: #f8fafc; --border: #e2e8f0;
                      --text: #0f172a; --text-muted: #64748b;
                      --primary: #6366f1; --bubble-user: #e0e7ff; --bubble-ai: #f8fafc;
                      --tool-bg: #fef3c7; --tool-text: #92400e; --tool-done: #d1fae5; --tool-done-text: #065f46;
                    }
                    @media (prefers-color-scheme: dark) {
                      :root {
                        --bg: #0f172a; --bg2: #1e293b; --border: #334155;
                        --text: #f1f5f9; --text-muted: #94a3b8;
                        --bubble-user: #312e81; --bubble-ai: #1e293b;
                        --tool-bg: #451a03; --tool-text: #fde68a; --tool-done: #064e3b; --tool-done-text: #6ee7b7;
                      }
                    }
                    body { font-family: 'Inter', system-ui, sans-serif; background: var(--bg); color: var(--text); line-height: 1.6; }
                    .container { max-width: 900px; margin: 0 auto; padding: 2rem 1.5rem; }
                    .export-header { border-bottom: 2px solid var(--primary); padding-bottom: 1.5rem; margin-bottom: 2rem; }
                    .export-header h1 { font-size: 1.75rem; font-weight: 700; color: var(--primary); }
                    .export-header .meta { margin-top: 0.5rem; font-size: 0.875rem; color: var(--text-muted); }
                    .message { margin-bottom: 1.5rem; border-radius: 0.75rem; overflow: hidden; border: 1px solid var(--border); }
                    .message__header { display: flex; justify-content: space-between; align-items: center; padding: 0.625rem 1rem; background: var(--bg2); border-bottom: 1px solid var(--border); }
                    .message__role { font-weight: 600; font-size: 0.875rem; }
                    .message__time { font-size: 0.75rem; color: var(--text-muted); }
                    .message__body { padding: 1rem 1.25rem; background: var(--bg); }
                    .message--user .message__header { background: var(--bubble-user); }
                    .message--user .message__body { background: var(--bubble-user); }
                    .message--ai .message__body { background: var(--bubble-ai); }
                    .tool-badges { display: flex; flex-wrap: wrap; gap: 0.5rem; padding: 0.5rem 1rem; background: var(--bg2); border-bottom: 1px solid var(--border); }
                    .tool-badge { font-size: 0.75rem; padding: 0.2rem 0.6rem; border-radius: 999px; font-family: 'JetBrains Mono', monospace; background: var(--tool-bg); color: var(--tool-text); }
                    .tool-badge.badge--done { background: var(--tool-done); color: var(--tool-done-text); }
                    .message__body p { margin-bottom: 0.75rem; }
                    .message__body h1,.message__body h2,.message__body h3 { margin: 1rem 0 0.5rem; font-weight: 600; }
                    .message__body ul,.message__body ol { padding-left: 1.5rem; margin-bottom: 0.75rem; }
                    .message__body table { width: 100%%; border-collapse: collapse; margin-bottom: 1rem; font-size: 0.875rem; }
                    .message__body th,.message__body td { border: 1px solid var(--border); padding: 0.5rem 0.75rem; text-align: left; }
                    .message__body th { background: var(--bg2); font-weight: 600; }
                    .message__body code:not([class]) { font-family: 'JetBrains Mono', monospace; background: var(--bg2); padding: 0.125rem 0.375rem; border-radius: 0.25rem; font-size: 0.85em; border: 1px solid var(--border); }
                    .message__body pre { border-radius: 0.5rem; margin-bottom: 1rem; overflow-x: auto; }
                    .export-footer { margin-top: 3rem; padding-top: 1.5rem; border-top: 1px solid var(--border); text-align: center; font-size: 0.8rem; color: var(--text-muted); }
                    @media print { body { background: white; color: black; } .message { break-inside: avoid; } }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <header class="export-header">
                      <h1>🤖 AI Assistant — Conversation Export</h1>
                      <p class="meta">
                        📅 %s &nbsp;·&nbsp; 💬 %d messages &nbsp;·&nbsp; Session: <code>%s</code>
                      </p>
                    </header>
                    <main>%s</main>
                    <footer class="export-footer">
                      <p>Exported by <strong>MCP AI Assistant</strong> on %s</p>
                    </footer>
                  </div>
                  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-core.min.js"></script>
                  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/plugins/autoloader/prism-autoloader.min.js"></script>
                </body>
                </html>
                """.formatted(exportDate, messageCount, sessionId, messagesHtml, exportDate);
    }
}
