# ProcessingIT Request/Response Flow Sequence

## Overview
This diagram shows the detailed request/response processing flow during test execution.

```mermaid
sequenceDiagram
    autonumber
    participant MCTF as MCTF Integration
    participant RT as RestTemplate
    participant ETH as ElavonTransactionHandler
    participant CMA as ConnectivityMetricsAwareImpl
    participant MS as MetricsService
    participant RRP as RequestResponseProcessor
    participant EMT as ElavonMessageTranslator
    participant ERB as ElavonRequestResponseBuilder
    
    Note over MCTF,RT: Test Request Initiation
    MCTF->>RT: execute(httpRequest)
    activate RT
    
    RT->>ETH: handleTransaction(TSPIRequest)
    activate ETH
    
    Note over ETH,CMA: Prepare Metrics Context
    ETH->>ETH: Set isTestMode header
    ETH->>CMA: new ConnectivityMetricsAwareImpl(request, processor, headers)
    activate CMA
    
    ETH->>MS: responseDurationMetrics(metricsAware)
    activate MS
    MS->>CMA: executeTask()
    
    Note over CMA,RRP: Execute Request Processing
    CMA->>RRP: process(transactionRequest)
    activate RRP
    
    Note over RRP,EMT: Message Translation
    RRP->>EMT: buildRequest(transactionRequest, params)
    activate EMT
    
    EMT->>EMT: doValidation(transactionRequest)
    EMT->>ERB: Build ISO 8583 message
    activate ERB
    ERB->>ERB: Set message type (AUTHORIZATION)
    ERB->>ERB: Set PAN, amount, STAN
    ERB->>ERB: Set POS data code
    ERB->>ERB: Set merchant/terminal IDs
    ERB->>ERB: Set currency, dates
    ERB-->>EMT: MessageCommsRequest<byte[]>
    deactivate ERB
    
    EMT-->>RRP: Formatted request
    deactivate EMT
    
    Note over RRP: Send to Elavon Acquirer
    RRP->>RRP: Send TCP/HTTP request
    RRP->>RRP: Receive response bytes
    
    Note over RRP,EMT: Response Processing
    RRP->>EMT: buildResponse(responseBytes, params)
    activate EMT
    EMT->>EMT: Parse ISO 8583 response
    EMT->>EMT: Extract action code, approval code
    EMT->>EMT: Map to TransactionResponse
    EMT-->>RRP: TSPIResponse
    deactivate EMT
    
    RRP-->>CMA: TSPIResponse
    deactivate RRP
    
    CMA->>CMA: setResponse(tspiResponse)
    CMA-->>MS: Execution complete
    deactivate CMA
    
    MS->>MS: Record response duration
    MS-->>ETH: Metrics recorded
    deactivate MS
    
    ETH-->>RT: TSPIResponse
    deactivate ETH
    
    RT-->>MCTF: HTTP Response
    deactivate RT
    
    Note over MCTF: Validation Phase
    MCTF->>MCTF: Compare response with expected model
    MCTF->>MCTF: Assert field values match
    MCTF->>MCTF: Report test result
```

## Request Message Structure

```mermaid
graph TB
    subgraph "ISO 8583 Authorization Request"
        MT[Message Type: 0100]
        
        subgraph "Mandatory Fields"
            F2[Field 2: PAN]
            F3[Field 3: Processing Code]
            F4[Field 4: Amount]
            F11[Field 11: STAN]
            F12[Field 12: Local Time]
            F14[Field 14: Expiry Date]
        end
        
        subgraph "Terminal Fields"
            F22[Field 22: POS Data Code]
            F41[Field 41: Terminal ID]
            F42[Field 42: Merchant ID]
            F43[Field 43: Card Acceptor Location]
        end
        
        subgraph "Private Data"
            F48[Field 48: Additional Private Data]
            F63[Field 63: Reserved Private Data]
        end
    end
    
    MT --> F2
    MT --> F3
    MT --> F4
```

## Response Message Structure

```mermaid
graph TB
    subgraph "ISO 8583 Authorization Response"
        MT[Message Type: 0110]
        
        subgraph "Key Response Fields"
            F38[Field 38: Approval Code]
            F39[Field 39: Action Code - 000=Approved]
        end
        
        subgraph "Echo Fields"
            F2[Field 2: PAN]
            F4[Field 4: Amount]
            F11[Field 11: STAN]
        end
        
        subgraph "Elavon-Specific"
            F48[Field 48.02: Elavon STAN]
            F48_3[Field 48.03: Elavon DateTime]
            F48_4[Field 48.04: Elavon RRN]
            F63[Field 63.31: Card Scheme Data]
        end
    end
```

## Field Mapping Table

| Request Field | Description | Test Value |
|--------------|-------------|------------|
| Field 2 (PAN) | Card number | 5212345678901234 |
| Field 4 (Amount) | Transaction amount | 000000002112 ($21.12) |
| Field 11 (STAN) | System trace audit number | 012345 |
| Field 41 (Terminal ID) | POS terminal identifier | 00123455 |
| Field 42 (Merchant ID) | Merchant identifier | M12345 |
| Field 49 (Currency) | Transaction currency | 840 (USD) |

| Response Field | Description | Expected Value |
|---------------|-------------|----------------|
| Field 38 | Authorization code | 123456 |
| Field 39 | Action/Response code | 000 (Approved) |
| Field 48.02 | Elavon STAN | 654321 |
| Field 63.31 | UTRN | utrn1236325 |
