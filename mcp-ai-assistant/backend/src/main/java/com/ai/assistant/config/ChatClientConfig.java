package com.ai.assistant.config;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.client.advisor.SimpleLoggerAdvisor;
import org.springframework.ai.chat.memory.InMemoryChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Spring AI {@link ChatClient} configuration.
 *
 * <p>Two beans are exposed:
 * <ol>
 *   <li>{@code chatClientBuilder} — pre-configured builder with system prompt +
 *       memory. {@code AiChatService} calls {@code .build()} on this for every
 *       request, injecting per-request model options and a filtered tool list.</li>
 *   <li>{@code chatClient} — fully-wired default client (all tools, default model)
 *       kept for health-check and testing convenience.</li>
 * </ol>
 */
@Configuration
public class ChatClientConfig {

    @Value("${conversation.store.memory-window-size:20}")
    private int memoryWindowSize;

    /**
     * Shared pre-configured builder reused by {@code AiChatService}.
     *
     * @param builder                 auto-configured by spring-ai-starter-model-openai
     * @param mcpToolCallbackProvider all tools harvested from every STDIO MCP server
     * @return builder with system prompt, memory advisor, logger, and all tools
     */
    @Bean
    public ChatClient.Builder chatClientBuilder(
            ChatClient.Builder builder,
            ToolCallbackProvider mcpToolCallbackProvider) {

        return builder
                .defaultSystem("""
                        You are an intelligent AI assistant with access to developer tooling via
                        MCP servers. Use the relevant tool when the user's request involves:

                        • Confluence  — search/read/create/update pages and spaces
                        • Jira        — search issues (JQL), create issues/subtasks, sprints,
                                        transitions, comments, story analysis
                        • Bitbucket   — repos, file content, pull requests, diffs, branches
                        • GitHub      — repos, issues, PRs, commits, workflows
                        • Git Local   — local git history, diffs, branches
                        • SonarQube   — code quality metrics, coverage, issues
                        • Jenkins     — build status, pipeline logs, trigger builds
                        • Slack/Teams — send messages to channels
                        • Artifactory — search and inspect artifacts
                        • Docker      — inspect containers, images, volumes
                        • Kubernetes  — inspect pods, services, deployments
                        • Shell       — run shell commands when explicitly asked
                        • Web Search  — search the internet for up-to-date information
                        • Security    — scan code/dependencies for vulnerabilities

                        Guidelines:
                        - Always call the relevant tool instead of guessing.
                        - Use valid JQL for Jira searches.
                        - Format responses with Markdown — tables for lists, code blocks for diffs.
                        - Never fabricate issue keys, page IDs, or repository slugs.
                        - Be concise and cite specific IDs/keys in your answers.
                        """)
                .defaultAdvisors(
                        MessageChatMemoryAdvisor.builder(
                                MessageWindowChatMemory.builder()
                                        .chatMemoryRepository(new InMemoryChatMemoryRepository())
                                        .maxMessages(memoryWindowSize)
                                        .build())
                                .build(),
                        new SimpleLoggerAdvisor()
                )
                .defaultTools(mcpToolCallbackProvider);
    }

    /**
     * Default fully-built client — all MCP tools, default model from application.yml.
     *
     * @param chatClientBuilder pre-configured builder
     * @return built default client
     */
    @Bean
    public ChatClient chatClient(ChatClient.Builder chatClientBuilder) {
        return chatClientBuilder.build();
    }
}
