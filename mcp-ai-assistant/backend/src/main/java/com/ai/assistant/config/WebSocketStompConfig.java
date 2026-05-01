package com.ai.assistant.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketTransportRegistration;

/**
 * STOMP over WebSocket configuration.
 *
 * <p>Architecture:
 * <pre>
 *   Browser ──SockJS/STOMP──► /ws  (endpoint)
 *                               │
 *             /app/chat.send ───► ChatWebSocketController (@MessageMapping)
 *             /topic/session/{id} ◄── server pushes StreamToken frames
 *             /user/queue/sessions ◄── per-user session list updates
 * </pre>
 *
 * <p>Horizontal scale path: replace {@code enableSimpleBroker} with
 * {@code enableStompBrokerRelay} pointing at a Redis/RabbitMQ instance — zero
 * application code changes required.
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketStompConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // In-memory simple broker for topic and user-queue destinations
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(1);
        scheduler.setThreadNamePrefix("ws-heartbeat-");
        scheduler.initialize();

        config.enableSimpleBroker("/topic", "/queue")
              .setHeartbeatValue(new long[]{10_000, 10_000})
              .setTaskScheduler(scheduler);

        // Prefix for @MessageMapping methods in controllers
        config.setApplicationDestinationPrefixes("/app");

        // Prefix for user-specific destinations (/user/queue/...)
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                // Allow React dev server + any deployed origin
                .setAllowedOriginPatterns("http://localhost:*", "https://*")
                // SockJS fallback for environments that block WebSocket
                .withSockJS()
                .setStreamBytesLimit(512 * 1024)
                .setHttpMessageCacheSize(1000)
                .setDisconnectDelay(30_000);
    }

    @Override
    public void configureWebSocketTransport(WebSocketTransportRegistration registration) {
        // 512 KB max message size — sufficient for large AI responses
        registration.setMessageSizeLimit(512 * 1024)
                    .setSendBufferSizeLimit(1024 * 1024)
                    .setSendTimeLimit(20_000);
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.taskExecutor()
                    .corePoolSize(4)
                    .maxPoolSize(8)
                    .queueCapacity(100);
    }

    @Override
    public void configureClientOutboundChannel(ChannelRegistration registration) {
        registration.taskExecutor()
                    .corePoolSize(4)
                    .maxPoolSize(8)
                    .queueCapacity(100);
    }
}
