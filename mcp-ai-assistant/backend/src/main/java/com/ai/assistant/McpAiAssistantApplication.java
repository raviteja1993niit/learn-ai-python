package com.ai.assistant;

import com.ai.assistant.mcp.config.McpServersProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * MCP AI Assistant — Spring Boot entry point.
 *
 * Bootstraps:
 *  - Spring AI ChatClient (GitHub Copilot / OpenAI-compatible endpoint)
 *  - Spring AI MCP Server (SSE transport on /mcp/sse)
 *  - WebSocket/STOMP broker (/ws endpoint, /topic + /queue destinations)
 *  - Confluence, Jira, Bitbucket MCP tools (@Tool auto-registration)
 */
@SpringBootApplication
@EnableAsync
@EnableConfigurationProperties(McpServersProperties.class)
public class McpAiAssistantApplication {

    public static void main(String[] args) {
        SpringApplication.run(McpAiAssistantApplication.class, args);
    }
}
