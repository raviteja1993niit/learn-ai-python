package com.ai.assistant.mcp.model;

import com.ai.assistant.mcp.config.McpServersProperties.ServerCategory;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.List;

/**
 * Runtime snapshot of a single MCP server's state.
 * Pushed to the frontend as a STOMP frame on {@code /topic/mcp/servers}.
 */
@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class McpServerStatus {

    /**
     * Lifecycle states for an MCP STDIO server process.
     */
    public enum ProcessState {
        /** Process not yet started. */
        STOPPED,
        /** Process starting — waiting for first ListTools response. */
        STARTING,
        /** Process running and tools registered. */
        RUNNING,
        /** Process exited with an error. */
        ERROR,
        /** Stop was requested and in progress. */
        STOPPING
    }

    /** Matches {@code McpServersProperties.ServerDefinition.id}. */
    private String id;

    /** Human-readable label (e.g. "Confluence"). */
    private String label;

    /** Script filename (e.g. "confluence-server.js"). */
    private String script;

    /** Logical grouping for the frontend panel. */
    private ServerCategory category;

    /** Icon identifier for the frontend. */
    private String icon;

    /** Current process state. */
    private ProcessState state;

    /** OS process ID — present only when RUNNING. */
    private Long pid;

    /** Number of tools registered from this server — present when RUNNING. */
    private Integer toolCount;

    /** Names of registered tools — present when RUNNING. */
    private List<String> tools;

    /** ISO-8601 timestamp of the last state transition. */
    private Instant lastUpdated;

    /** Error message — present when state is ERROR. */
    private String errorMessage;

    /** Uptime in seconds — present when RUNNING. */
    private Long uptimeSeconds;
}
