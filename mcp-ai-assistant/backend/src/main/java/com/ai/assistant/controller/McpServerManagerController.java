package com.ai.assistant.controller;

import com.ai.assistant.mcp.model.McpServerStatus;
import com.ai.assistant.mcp.registry.McpServerRegistry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * REST + STOMP controller for MCP server process management.
 *
 * <p>REST endpoints (polled by frontend on load):
 * <pre>
 *   GET  /api/mcp/servers              → all statuses snapshot
 *   GET  /api/mcp/servers/{id}         → single server status
 *   POST /api/mcp/servers/{id}/start   → start a stopped server
 *   POST /api/mcp/servers/{id}/stop    → stop a running server
 *   POST /api/mcp/servers/{id}/restart → restart a server
 * </pre>
 *
 * <p>STOMP (pushed to frontend in real time):
 * <pre>
 *   SUBSCRIBE /topic/mcp/servers       → McpServerStatus frames on any state change
 *   SEND /app/mcp.server.start/{id}    → trigger start via WebSocket
 *   SEND /app/mcp.server.stop/{id}     → trigger stop via WebSocket
 *   SEND /app/mcp.server.restart/{id}  → trigger restart via WebSocket
 * </pre>
 */
@RestController
@RequestMapping("/api/mcp")
@RequiredArgsConstructor
@Slf4j
public class McpServerManagerController {

    private final McpServerRegistry registry;
    private final SimpMessagingTemplate messagingTemplate;

    // ── REST endpoints ───────────────────────────────────────────────

    @GetMapping("/servers")
    public ResponseEntity<List<McpServerStatus>> getAllServers() {
        return ResponseEntity.ok(registry.getAllStatuses());
    }

    @GetMapping("/servers/{serverId}")
    public ResponseEntity<McpServerStatus> getServer(@PathVariable String serverId) {
        McpServerStatus status = registry.getStatus(serverId);
        return status != null
                ? ResponseEntity.ok(status)
                : ResponseEntity.notFound().build();
    }

    @PostMapping("/servers/{serverId}/start")
    public ResponseEntity<Map<String, String>> startServer(@PathVariable String serverId) {
        try {
            registry.startServer(serverId);
            return ResponseEntity.ok(Map.of("result", "start requested", "serverId", serverId));
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage(), "serverId", serverId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/servers/{serverId}/stop")
    public ResponseEntity<Map<String, String>> stopServer(@PathVariable String serverId) {
        try {
            registry.stopServer(serverId);
            return ResponseEntity.ok(Map.of("result", "stop requested", "serverId", serverId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/servers/{serverId}/restart")
    public ResponseEntity<Map<String, String>> restartServer(@PathVariable String serverId) {
        try {
            registry.restartServer(serverId);
            return ResponseEntity.ok(Map.of("result", "restart requested", "serverId", serverId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // ── STOMP message handlers ───────────────────────────────────────

    /**
     * Start a server via WebSocket — client sends to {@code /app/mcp.server.start/{id}}.
     */
    @MessageMapping("/mcp.server.start/{serverId}")
    public void wsStartServer(@DestinationVariable String serverId) {
        log.debug("WS start request for server: {}", serverId);
        try {
            registry.startServer(serverId);
        } catch (Exception e) {
            log.warn("WS start failed for {}: {}", serverId, e.getMessage());
        }
    }

    /**
     * Stop a server via WebSocket — client sends to {@code /app/mcp.server.stop/{id}}.
     */
    @MessageMapping("/mcp.server.stop/{serverId}")
    public void wsStopServer(@DestinationVariable String serverId) {
        log.debug("WS stop request for server: {}", serverId);
        registry.stopServer(serverId);
    }

    /**
     * Restart a server via WebSocket — client sends to {@code /app/mcp.server.restart/{id}}.
     */
    @MessageMapping("/mcp.server.restart/{serverId}")
    public void wsRestartServer(@DestinationVariable String serverId) {
        log.debug("WS restart request for server: {}", serverId);
        try {
            registry.restartServer(serverId);
        } catch (Exception e) {
            log.warn("WS restart failed for {}: {}", serverId, e.getMessage());
        }
    }
}
