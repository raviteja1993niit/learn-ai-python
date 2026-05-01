package com.ai.assistant.controller;

import com.ai.assistant.model.LlmModelDescriptor;
import com.ai.assistant.model.McpToolGroup;
import com.ai.assistant.service.McpToolRegistryService;
import com.ai.assistant.service.ModelRegistryService;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.boot.info.BuildProperties;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Health and catalogue endpoints.
 *
 * <pre>
 *   GET /api/health            — liveness probe + registered tool count
 *   GET /api/models            — available LLM models for the model selector
 *   GET /api/tools             — flat list of all registered MCP tool names
 *   GET /api/tools/grouped     — tools grouped by MCP server (for tool selector panel)
 * </pre>
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class HealthController {

    private final ToolCallbackProvider mcpToolCallbackProvider;
    private final ModelRegistryService modelRegistryService;
    private final McpToolRegistryService mcpToolRegistryService;
    private final Optional<BuildProperties> buildProperties;

    /** Liveness probe. */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "version", buildProperties.map(BuildProperties::getVersion).orElse("1.0.0"),
                "timestamp", Instant.now().toString(),
                "registeredToolCount", mcpToolCallbackProvider.getToolCallbacks().length
        ));
    }

    /**
     * All available LLM models for the model selector dropdown.
     *
     * @return list of {@link LlmModelDescriptor}
     */
    @GetMapping("/models")
    public ResponseEntity<List<LlmModelDescriptor>> listModels() {
        return ResponseEntity.ok(modelRegistryService.getAvailableModels());
    }

    /**
     * Flat alphabetical list of every registered MCP tool name.
     *
     * @return list of tool name + description maps
     */
    @GetMapping("/tools")
    public ResponseEntity<List<Map<String, String>>> listTools() {
        List<Map<String, String>> tools = Arrays.stream(
                        mcpToolCallbackProvider.getToolCallbacks())
                .map(cb -> Map.of(
                        "name",        cb.getToolDefinition().name(),
                        "description", cb.getToolDefinition().description()))
                .sorted(java.util.Comparator.comparing(m -> m.get("name")))
                .toList();
        return ResponseEntity.ok(tools);
    }

    /**
     * MCP tools grouped by originating server — used by the frontend tool
     * selector panel to render one accordion section per server.
     *
     * @return list of {@link McpToolGroup}
     */
    @GetMapping("/tools/grouped")
    public ResponseEntity<List<McpToolGroup>> listGroupedTools() {
        return ResponseEntity.ok(mcpToolRegistryService.getGroupedTools());
    }
}
