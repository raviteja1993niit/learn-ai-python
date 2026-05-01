package com.ai.assistant.service;

import com.ai.assistant.mcp.config.McpServersProperties;
import com.ai.assistant.mcp.config.McpServersProperties.ServerDefinition;
import com.ai.assistant.model.McpToolGroup;
import com.ai.assistant.model.McpToolGroup.ToolDescriptor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.tool.ToolCallback;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Organises all MCP tools registered via {@link ToolCallbackProvider} into
 * groups by their originating server.
 *
 * <p>The grouping is done by matching tool names against well-known prefixes
 * or by consulting the {@link McpServersProperties} definitions.
 * The frontend uses {@code GET /api/tools/grouped} to render the tool selector
 * panel with one accordion section per MCP server.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class McpToolRegistryService {

    private final ToolCallbackProvider mcpToolCallbackProvider;
    private final McpServersProperties mcpServersProperties;

    /**
     * Server-id → set of tool names known to belong to that server.
     * Used as a lookup table for the grouping heuristic.
     */
    private static final Map<String, Set<String>> SERVER_TOOL_MAP = Map.ofEntries(
            Map.entry("confluence", Set.of(
                    "getPage", "searchContent", "createPage", "updatePage", "getSpaces",
                    "getSpace", "addComment", "getPageChildren", "getAttachments",
                    "getPageHistory", "deletePage", "movePage", "copyPage", "getLabels",
                    "addLabels", "removeLabel", "searchByLabel", "getBlogPosts",
                    "createBlogPost", "getContentProperties", "setContentProperty",
                    "getSpacePermissions", "getPageTree")),
            Map.entry("jira", Set.of(
                    "getIssue", "searchIssues", "getIssuesByProject", "createIssue",
                    "updateIssue", "transitionIssue", "getIssueTransitions", "addComment",
                    "getComments", "analyzeStoryRequirements", "getRelatedIssues",
                    "getProject", "listProjects", "getBoards", "getSprints",
                    "getSprintIssues", "extractAcceptanceCriteria", "getIssueHistory",
                    "deleteIssue", "assignIssue", "createSubtask", "linkIssues",
                    "getIssueLinkTypes", "cloneIssue", "getWatchers", "addWatcher",
                    "getCurrentUser", "searchUsers")),
            Map.entry("bitbucket", Set.of(
                    "listRepositories", "getRepository", "getPullRequests", "createPullRequest",
                    "getPullRequest", "updatePullRequest", "mergePullRequest", "declinePullRequest",
                    "approvePullRequest", "unapprovePullRequest", "requestChanges",
                    "getPullRequestActivity", "getPullRequestComments", "addPullRequestComment",
                    "getPullRequestComment", "updatePullRequestComment", "deletePullRequestComment",
                    "getPullRequestDiff", "getPullRequestTasks", "getPullRequestCommits",
                    "search", "browse_repository", "get_file_content", "listBranches",
                    "getBranch", "createBranch", "deleteBranch", "getDefaultBranch",
                    "getBranchPermissions", "listTags", "createTag", "deleteTag",
                    "getRepoPermissions", "listRepoAccessKeys", "getCurrentUser", "getUser")),
            Map.entry("github", Set.of(
                    "listRepositories", "getRepository", "createRepository", "deleteRepository",
                    "forkRepository", "getRepositoryTopics", "listBranches", "getBranch",
                    "createBranch", "deleteBranch", "getBranchProtection", "listPullRequests",
                    "getPullRequest", "createPullRequest", "updatePullRequest", "mergePullRequest",
                    "getPullRequestReviews", "createPullRequestReview", "getPullRequestFiles",
                    "addPullRequestReviewers", "listIssues", "getIssue", "createIssue",
                    "updateIssue", "addComment", "getComments", "listCommits", "getCommit",
                    "listWorkflows", "getWorkflowRuns", "triggerWorkflow", "listMilestones",
                    "createMilestone", "listRepoSecrets", "getCurrentUser")),
            Map.entry("sonar",      Set.of("getSonarIssues", "getSonarMetrics", "getSonarProjects",
                    "getSonarQualityGates", "getSonarCoverage", "getSonarHotspots")),
            Map.entry("jenkins",    Set.of("getJenkinsJobs", "getJenkinsBuild", "triggerJenkinsBuild",
                    "getJenkinsPipeline", "getJenkinsLogs", "getJenkinsNodes")),
            Map.entry("slack",      Set.of("sendSlackMessage", "getSlackChannels",
                    "getSlackMessages", "createSlackChannel")),
            Map.entry("teams",      Set.of("sendTeamsMessage", "getTeamsChannels",
                    "createTeamsMeeting")),
            Map.entry("artifactory",Set.of("searchArtifacts", "getArtifactInfo",
                    "downloadArtifact", "listRepositories")),
            Map.entry("docker",     Set.of("listContainers", "getContainer", "listImages",
                    "pullImage", "runContainer", "stopContainer", "removeContainer")),
            Map.entry("kubectl",    Set.of("getPods", "getServices", "getDeployments",
                    "getNamespaces", "describeResource", "getLogs", "applyManifest")),
            Map.entry("shell",      Set.of("runCommand", "runScript")),
            Map.entry("git-local",  Set.of("gitLog", "gitDiff", "gitStatus", "gitBranch",
                    "gitShow", "gitBlame")),
            Map.entry("search",     Set.of("webSearch", "braveSearch", "googleSearch",
                    "stackOverflowSearch")),
            Map.entry("security",   Set.of("scanDependencies", "checkCVE", "scanCode",
                    "getSecurityReport")),
            Map.entry("devtools",   Set.of("formatCode", "lintCode", "generateTypes",
                    "generateDocs")),
            Map.entry("packages",   Set.of("searchNpm", "searchPypi", "searchMaven",
                    "getPackageInfo", "getLatestVersion")),
            Map.entry("build",      Set.of("runMavenBuild", "runGradleBuild",
                    "runNpmBuild", "runTests")),
            Map.entry("utils",      Set.of("parseJson", "formatJson", "encodeBase64",
                    "decodeBase64", "generateUuid", "hashString"))
    );

    /**
     * Returns all registered MCP tools grouped by server, suitable for the
     * tool selector panel in the frontend.
     *
     * @return list of {@link McpToolGroup}, one per MCP server that has tools
     */
    public List<McpToolGroup> getGroupedTools() {
        ToolCallback[] allCallbacks = mcpToolCallbackProvider.getToolCallbacks();
        log.debug("Grouping {} registered MCP tools", allCallbacks.length);

        // Build a lookup: toolName → ToolDescriptor
        Map<String, ToolDescriptor> allTools = Arrays.stream(allCallbacks)
                .collect(Collectors.toMap(
                        cb -> cb.getToolDefinition().name(),
                        cb -> ToolDescriptor.builder()
                                .name(cb.getToolDefinition().name())
                                .description(cb.getToolDefinition().description())
                                .build(),
                        (a, b) -> a,
                        LinkedHashMap::new));

        List<McpToolGroup> groups = new ArrayList<>();
        Set<String> assignedTools = new java.util.HashSet<>();

        // Assign tools to their server group in definition order
        for (ServerDefinition def : mcpServersProperties.getDefinitions()) {
            Set<String> knownTools = SERVER_TOOL_MAP.getOrDefault(def.getId(), Set.of());
            List<ToolDescriptor> serverTools = allTools.entrySet().stream()
                    .filter(e -> knownTools.contains(e.getKey()))
                    .map(Map.Entry::getValue)
                    .sorted(java.util.Comparator.comparing(ToolDescriptor::getName))
                    .toList();

            if (!serverTools.isEmpty()) {
                assignedTools.addAll(serverTools.stream()
                        .map(ToolDescriptor::getName).collect(Collectors.toSet()));
                groups.add(McpToolGroup.builder()
                        .serverId(def.getId())
                        .serverLabel(def.getLabel())
                        .icon(def.getIcon())
                        .category(def.getCategory().name())
                        .serverRunning(true) // Spring AI manages the process; if tool is registered, server is running
                        .tools(serverTools)
                        .build());
            }
        }

        // Catch-all group for tools not matched to any known server
        List<ToolDescriptor> unmatched = allTools.entrySet().stream()
                .filter(e -> !assignedTools.contains(e.getKey()))
                .map(Map.Entry::getValue)
                .toList();
        if (!unmatched.isEmpty()) {
            groups.add(McpToolGroup.builder()
                    .serverId("other")
                    .serverLabel("Other")
                    .icon("tool")
                    .category("UTILITIES")
                    .serverRunning(true)
                    .tools(unmatched)
                    .build());
        }

        return groups;
    }

    /**
     * Returns a flat list of all registered tool names for quick lookup.
     *
     * @return sorted list of tool names
     */
    public List<String> getAllToolNames() {
        return Arrays.stream(mcpToolCallbackProvider.getToolCallbacks())
                .map(cb -> cb.getToolDefinition().name())
                .sorted()
                .toList();
    }

    /**
     * Returns all {@link ToolCallback} instances whose names appear in
     * {@code selectedToolNames}. Falls back to all callbacks when the list
     * is null or empty.
     *
     * @param selectedToolNames tool names chosen by the user
     * @return filtered array of callbacks
     */
    public ToolCallback[] filterCallbacks(List<String> selectedToolNames) {
        if (selectedToolNames == null || selectedToolNames.isEmpty()) {
            return mcpToolCallbackProvider.getToolCallbacks();
        }
        Set<String> allowed = Set.copyOf(selectedToolNames);
        return Arrays.stream(mcpToolCallbackProvider.getToolCallbacks())
                .filter(cb -> allowed.contains(cb.getToolDefinition().name()))
                .toArray(ToolCallback[]::new);
    }
}
