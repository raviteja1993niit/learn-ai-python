package com.ai.assistant.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.util.List;

/**
 * A group of MCP tools belonging to the same server, returned by
 * {@code GET /api/tools/grouped}.
 *
 * <p>The frontend renders one accordion section per group in the tool
 * selector panel, with individual checkboxes per tool.
 */
@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class McpToolGroup {

    /** Server identifier (e.g. {@code "confluence"}, {@code "jira"}). */
    private String serverId;

    /** Human-readable server label (e.g. {@code "Confluence"}). */
    private String serverLabel;

    /** Icon identifier for the server (maps to Lucide icon name). */
    private String icon;

    /** Logical category for display ordering. */
    private String category;

    /** Whether the underlying server process is currently running. */
    private boolean serverRunning;

    /** All tools registered from this server. */
    private List<ToolDescriptor> tools;

    /**
     * Metadata for a single MCP tool.
     */
    @Data
    @Builder
    public static class ToolDescriptor {

        /** Unique tool name — used in {@code ChatRequest.selectedTools}. */
        private String name;

        /** Human-readable description from the MCP server's tool definition. */
        private String description;
    }
}
