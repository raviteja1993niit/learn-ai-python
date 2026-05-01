package com.ai.assistant.mcp.registry;

import com.ai.assistant.mcp.config.McpServersProperties;
import com.ai.assistant.mcp.config.McpServersProperties.ServerDefinition;
import com.ai.assistant.mcp.model.McpServerStatus;
import com.ai.assistant.mcp.model.McpServerStatus.ProcessState;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * Manages the lifecycle of all Node.js MCP STDIO server child processes.
 *
 * <p>Responsibilities:
 * <ul>
 *   <li>Tracks real-time {@link McpServerStatus} for every defined server.</li>
 *   <li>Provides start/stop/restart operations callable from the REST controller.</li>
 *   <li>Monitors process stdout/stderr asynchronously for tool-count extraction
 *       and error detection.</li>
 *   <li>Broadcasts status updates to the STOMP topic {@code /topic/mcp/servers}
 *       so the React frontend receives live updates.</li>
 * </ul>
 *
 * <p>Note: Spring AI's {@code spring-ai-starter-mcp-client} manages its own
 * process handles internally for LLM tool-calling. This registry manages a
 * <em>parallel</em> set of process handles purely for the frontend status panel
 * and manual start/stop control.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class McpServerRegistry {

    /** STOMP destination for broadcasting server status updates. */
    public static final String STATUS_TOPIC = "/topic/mcp/servers";

    private final McpServersProperties properties;
    private final SimpMessagingTemplate messagingTemplate;

    /** Live status map — one entry per defined server. */
    private final Map<String, McpServerStatus> statusMap = new ConcurrentHashMap<>();

    /** Running process handles — present only when process is alive. */
    private final Map<String, Process> processMap = new ConcurrentHashMap<>();

    /** Start timestamps for uptime calculation. */
    private final Map<String, Instant> startTimes = new ConcurrentHashMap<>();

    /** Thread pool for async log-reader threads. */
    private final ExecutorService logReaderPool =
            Executors.newCachedThreadPool(r -> {
                Thread t = new Thread(r, "mcp-log-reader");
                t.setDaemon(true);
                return t;
            });

    // ── Lifecycle ────────────────────────────────────────────────────

    /**
     * Initialise status entries for every defined server at startup.
     * All start in STOPPED state — Spring AI's own client handles tool
     * registration separately.
     */
    @PostConstruct
    public void initialise() {
        for (ServerDefinition def : properties.getDefinitions()) {
            McpServerStatus status = McpServerStatus.builder()
                    .id(def.getId())
                    .label(def.getLabel())
                    .script(def.getScript())
                    .category(def.getCategory())
                    .icon(def.getIcon())
                    .state(ProcessState.STOPPED)
                    .lastUpdated(Instant.now())
                    .build();
            statusMap.put(def.getId(), status);
        }
        log.info("McpServerRegistry initialised with {} server definitions",
                statusMap.size());
    }

    @PreDestroy
    public void shutdown() {
        log.info("Shutting down all MCP server processes…");
        processMap.forEach((id, process) -> killProcess(id, process));
        logReaderPool.shutdownNow();
    }

    // ── Query ─────────────────────────────────────────────────────────

    /**
     * Return a snapshot of all server statuses, ordered by category then label.
     */
    public List<McpServerStatus> getAllStatuses() {
        return statusMap.values().stream()
                .sorted(java.util.Comparator
                        .comparing((McpServerStatus s) -> s.getCategory().name())
                        .thenComparing(McpServerStatus::getLabel))
                .toList();
    }

    /**
     * Return status for a single server by ID.
     *
     * @param serverId server ID
     * @return status snapshot, or {@code null} if not found
     */
    public McpServerStatus getStatus(String serverId) {
        return statusMap.get(serverId);
    }

    // ── Control operations ────────────────────────────────────────────

    /**
     * Start a server process.
     *
     * @param serverId server ID
     * @throws IllegalArgumentException if ID is unknown
     * @throws IllegalStateException    if server is already running
     */
    public void startServer(String serverId) {
        ServerDefinition def = findDefinition(serverId);
        McpServerStatus current = statusMap.get(serverId);

        if (current.getState() == ProcessState.RUNNING
                || current.getState() == ProcessState.STARTING) {
            throw new IllegalStateException(
                    "Server " + serverId + " is already " + current.getState());
        }

        updateStatus(serverId, ProcessState.STARTING, null, null, null);

        try {
            Process process = buildProcess(def);
            processMap.put(serverId, process);
            startTimes.put(serverId, Instant.now());

            // Read stdout asynchronously — detect ready signal and tool count
            logReaderPool.submit(() -> monitorProcess(serverId, process, def));

            log.info("Started MCP server process: {} (PID={})",
                    serverId, process.pid());

        } catch (Exception e) {
            log.error("Failed to start MCP server {}: {}", serverId, e.getMessage());
            updateStatus(serverId, ProcessState.ERROR, null, null,
                    "Start failed: " + e.getMessage());
        }
    }

    /**
     * Stop a running server process.
     *
     * @param serverId server ID
     */
    public void stopServer(String serverId) {
        Process process = processMap.get(serverId);
        if (process == null || !process.isAlive()) {
            updateStatus(serverId, ProcessState.STOPPED, null, null, null);
            return;
        }

        updateStatus(serverId, ProcessState.STOPPING, null, null, null);
        killProcess(serverId, process);
        processMap.remove(serverId);
        startTimes.remove(serverId);
        updateStatus(serverId, ProcessState.STOPPED, null, null, null);
        log.info("Stopped MCP server: {}", serverId);
    }

    /**
     * Restart a server process.
     *
     * @param serverId server ID
     */
    public void restartServer(String serverId) {
        stopServer(serverId);
        startServer(serverId);
    }

    // ── Private helpers ───────────────────────────────────────────────

    private ServerDefinition findDefinition(String serverId) {
        return properties.getDefinitions().stream()
                .filter(d -> d.getId().equals(serverId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Unknown MCP server ID: " + serverId));
    }

    private Process buildProcess(ServerDefinition def) throws Exception {
        Path script = Path.of(properties.getBasePath(), def.getScript());

        ProcessBuilder pb = new ProcessBuilder(
                properties.getNodeExecutable(),
                script.toAbsolutePath().toString());

        pb.directory(Path.of(properties.getBasePath()).toFile());
        pb.redirectErrorStream(false);

        Map<String, String> env = pb.environment();
        env.put("ENV_FILE", properties.getEnvFile());
        if (def.isSslIgnore()) {
            env.put("NODE_TLS_REJECT_UNAUTHORIZED", "0");
        }

        return pb.start();
    }

    /**
     * Reads stdout of the process, detects "running on stdio" ready signal,
     * and transitions state from STARTING → RUNNING.
     * On process exit, transitions to STOPPED or ERROR.
     */
    private void monitorProcess(String serverId, Process process, ServerDefinition def) {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {

            String line;
            while ((line = reader.readLine()) != null) {
                log.debug("[{}] {}", serverId, line);

                // Node.js MCP servers print this to stderr when ready
                if (line.contains("running on stdio") || line.contains("MCP running on stdio")) {
                    long pid = process.pid();
                    long uptime = startTimes.containsKey(serverId)
                            ? java.time.Duration.between(startTimes.get(serverId), Instant.now()).getSeconds()
                            : 0;
                    updateStatus(serverId, ProcessState.RUNNING, pid, uptime, null);
                }
            }
        } catch (Exception e) {
            log.debug("[{}] Log reader ended: {}", serverId, e.getMessage());
        }

        // Also read stderr for the ready signal (Node.js servers use console.error)
        try (BufferedReader errReader = new BufferedReader(
                new InputStreamReader(process.getErrorStream()))) {
            String line;
            while ((line = errReader.readLine()) != null) {
                log.debug("[{}] ERR: {}", serverId, line);
                if (line.contains("running on stdio") || line.contains("MCP running on stdio")) {
                    updateStatus(serverId, ProcessState.RUNNING, process.pid(), 0L, null);
                }
                if (line.contains("Error") || line.contains("error")) {
                    log.warn("[{}] Process error output: {}", serverId, line);
                }
            }
        } catch (Exception e) {
            log.debug("[{}] Stderr reader ended: {}", serverId, e.getMessage());
        }

        // Process ended
        int exitCode = -1;
        try {
            exitCode = process.waitFor();
        } catch (InterruptedException ignored) {
            Thread.currentThread().interrupt();
        }

        processMap.remove(serverId);
        startTimes.remove(serverId);

        McpServerStatus current = statusMap.get(serverId);
        if (current != null && current.getState() != ProcessState.STOPPING) {
            String errMsg = exitCode != 0 ? "Process exited with code " + exitCode : null;
            ProcessState finalState = exitCode == 0 ? ProcessState.STOPPED : ProcessState.ERROR;
            updateStatus(serverId, finalState, null, null, errMsg);
            log.info("MCP server {} exited with code {}", serverId, exitCode);
        }
    }

    private void updateStatus(
            String serverId,
            ProcessState state,
            Long pid,
            Long uptimeSeconds,
            String errorMessage) {

        McpServerStatus existing = statusMap.get(serverId);
        if (existing == null) {
            return;
        }

        McpServerStatus updated = McpServerStatus.builder()
                .id(existing.getId())
                .label(existing.getLabel())
                .script(existing.getScript())
                .category(existing.getCategory())
                .icon(existing.getIcon())
                .state(state)
                .pid(pid)
                .uptimeSeconds(uptimeSeconds)
                .lastUpdated(Instant.now())
                .errorMessage(errorMessage)
                .tools(existing.getTools())
                .toolCount(existing.getToolCount())
                .build();

        statusMap.put(serverId, updated);
        broadcastStatus(updated);
    }

    private void broadcastStatus(McpServerStatus status) {
        try {
            messagingTemplate.convertAndSend(STATUS_TOPIC, status);
        } catch (Exception e) {
            log.debug("Could not broadcast server status — no active WebSocket connections");
        }
    }

    private void killProcess(String serverId, Process process) {
        try {
            process.descendants().forEach(ProcessHandle::destroy);
            process.destroy();
            if (!process.waitFor(5, TimeUnit.SECONDS)) {
                process.destroyForcibly();
            }
        } catch (Exception e) {
            log.warn("Error killing process for {}: {}", serverId, e.getMessage());
        }
    }
}
