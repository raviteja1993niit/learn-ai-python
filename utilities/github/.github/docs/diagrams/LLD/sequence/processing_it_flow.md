# ProcessingIT Flow & Configuration (Flow Framework Integration)

This diagram captures the configuration and runtime interactions of `ProcessingIT` with the Flow framework, highlighting Spring test wiring, TLS settings, model injection, and external calls.

```mermaid
sequenceDiagram
    autonumber
    actor JUnit as JUnit 5 Runner
    participant ProcessingIT
    participant SpringContext as SpringBoot ApplicationContext
    participant IntegrationTestsConfig as IntegrationTestsConfig
    participant RestTemplate
    participant FlowModel as ElavonSystemTransactions.MODEL
    participant Integration as Flow Integration
    participant External as Elavon Test System

    JUnit->>ProcessingIT: Instantiate test class
    note over ProcessingIT: System.setProperty("jdk.tls.maxHandshakeMessageSize","65536")

    JUnit->>SpringContext: @SpringBootTest bootstraps context
    SpringContext->>IntegrationTestsConfig: @Import(IntegrationTestsConfig)
    IntegrationTestsConfig-->>SpringContext: Register RestTemplate bean
    SpringContext-->>ProcessingIT: @Autowired RestTemplate

    ProcessingIT->>Integration: new Integration(FlowModel, RestTemplate)
    Integration->>FlowModel: Load flow model (transactions graph)

    ProcessingIT->>Integration: componentTests()
    Integration-->>JUnit: Stream<DynamicNode> tests()

    loop For each dynamic test
        Integration->>RestTemplate: Invoke Flow step via HTTP
        RestTemplate->>External: Send request to test system (dev/stage/etc)
        External-->>RestTemplate: Response
        RestTemplate-->>Integration: Return response
        Integration-->>JUnit: Report result for DynamicNode
    end
```

- TLS: Sets `jdk.tls.maxHandshakeMessageSize=65536` to accommodate handshake size in tests.
- Spring Context: `@SpringBootTest` with `@Import(IntegrationTestsConfig)` supplies `RestTemplate`.
- Flow Model: `ElavonSystemTransactions.MODEL` defines transaction flows used by `Integration`.
- Execution: `Integration.tests()` produces `DynamicNode` stream executed by JUnit.
