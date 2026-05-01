package com.ai.assistant.controller;

import com.ai.assistant.service.ConversationExportService;
import com.ai.assistant.service.ConversationStore;
import com.ai.assistant.websocket.model.ConversationMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

/**
 * REST controller for conversation session management and export.
 *
 * <p>Endpoints:
 * <pre>
 *   GET  /api/sessions                        → list all sessions (for sidebar)
 *   GET  /api/sessions/{id}/messages          → full message list for a session
 *   DELETE /api/sessions/{id}                 → delete a session
 *   GET  /api/export/{id}?format=html|md      → download conversation as HTML or MD
 * </pre>
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class ExportController {

    private final ConversationStore conversationStore;
    private final ConversationExportService exportService;

    /**
     * Return a summary list of all sessions — used by the React sidebar.
     *
     * @return list of {@link ConversationStore.SessionSummary} records
     */
    @GetMapping("/sessions")
    public ResponseEntity<List<ConversationStore.SessionSummary>> listSessions() {
        return ResponseEntity.ok(conversationStore.getSessions());
    }

    /**
     * Return all messages for a session.
     *
     * @param sessionId session identifier
     * @return list of {@link ConversationMessage} records
     */
    @GetMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<List<ConversationMessage>> getMessages(
            @PathVariable String sessionId) {

        if (!conversationStore.sessionExists(sessionId)) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(conversationStore.getMessages(sessionId));
    }

    /**
     * Delete a session and all its messages.
     *
     * @param sessionId session identifier
     * @return 204 No Content on success, 404 if not found
     */
    @DeleteMapping("/sessions/{sessionId}")
    public ResponseEntity<Void> deleteSession(@PathVariable String sessionId) {
        if (!conversationStore.sessionExists(sessionId)) {
            return ResponseEntity.notFound().build();
        }
        conversationStore.deleteSession(sessionId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Export a conversation as a downloadable file.
     *
     * @param sessionId session identifier
     * @param format    {@code html} (default) or {@code md}
     * @return file download response
     */
    @GetMapping("/export/{sessionId}")
    public ResponseEntity<byte[]> exportConversation(
            @PathVariable String sessionId,
            @RequestParam(defaultValue = "html") String format) {

        log.debug("Export request — session={} format={}", sessionId, format);

        if (!conversationStore.sessionExists(sessionId)) {
            return ResponseEntity.notFound().build();
        }

        try {
            String today = LocalDate.now().toString();
            if ("md".equalsIgnoreCase(format)) {
                String content = exportService.exportAsMarkdown(sessionId);
                String filename = "conversation-" + today + ".md";
                return buildDownloadResponse(
                        content.getBytes(StandardCharsets.UTF_8),
                        "text/markdown; charset=UTF-8",
                        filename);
            } else {
                String content = exportService.exportAsHtml(sessionId);
                String filename = "conversation-" + today + ".html";
                return buildDownloadResponse(
                        content.getBytes(StandardCharsets.UTF_8),
                        "text/html; charset=UTF-8",
                        filename);
            }
        } catch (IllegalArgumentException e) {
            log.warn("Export failed for session {}: {}", sessionId, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    // ── Private helpers ──────────────────────────────────────────────

    private ResponseEntity<byte[]> buildDownloadResponse(
            byte[] content, String contentType, String filename) {

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType(contentType));
        headers.setContentDisposition(
                ContentDisposition.attachment().filename(filename, StandardCharsets.UTF_8).build());
        headers.setContentLength(content.length);

        return ResponseEntity.ok().headers(headers).body(content);
    }
}
