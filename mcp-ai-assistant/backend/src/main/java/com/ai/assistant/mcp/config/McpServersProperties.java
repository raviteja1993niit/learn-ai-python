package com.ai.assistant.mcp.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Typed binding for the {@code mcp.servers} block in {@code application.yml}.
 *
 * <p>Each {@link ServerDefinition} entry maps 1-to-1 with a Node.js STDIO
 * MCP server script. The registry uses these definitions to:
 * <ul>
 *   <li>Spawn/stop individual server processes on demand.</li>
 *   <li>Track real-time process status (STARTING, RUNNING, STOPPED, ERROR).</li>
 *   <li>Push status updates to the frontend via STOMP WebSocket.</li>
 * </ul>
 */
@Component
@ConfigurationProperties(prefix = "mcp.servers")
@Data
public class McpServersProperties {

    /** Absolute path to the Node.js executable. */
    private String nodeExecutable = "C:/Program Files/nodejs/node.exe";

    /** Base directory where all *-server.js scripts live. */
    private String basePath = "C:/data/node-mcp-servers/build";

    /** Absolute path to the shared .env file loaded by every server. */
    private String envFile = "C:/data/node-mcp-servers/.env";

    /** Ordered list of server definitions. */
    private List<ServerDefinition> definitions = new ArrayList<>();

    // ── Nested types ──────────────────────────────────────────────────

    /**
     * Metadata for a single MCP server script.
     */
    @Data
    public static class ServerDefinition {

        /** Unique identifier — matches the key in {@code spring.ai.mcp.client.stdio}. */
        private String id;

        /** Human-readable display label shown in the frontend panel. */
        private String label;

        /** Script filename relative to {@code basePath}. */
        private String script;

        /** Logical grouping for the frontend panel. */
        private ServerCategory category = ServerCategory.UTILITIES;

        /** Icon identifier used by the frontend (maps to Lucide icon name). */
        private String icon;

        /** Whether to set {@code NODE_TLS_REJECT_UNAUTHORIZED=0} when spawning. */
        private boolean sslIgnore = false;
    }

    /**
     * Logical categories used to group servers in the frontend panel.
     */
    public enum ServerCategory {
        ENTERPRISE,
        DEVTOOLS,
        MESSAGING,
        SYSTEM,
        UTILITIES
    }
}
