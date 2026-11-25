# Proposed external work-order API flow

This document proposes an idempotent API endpoint for external work orders. An external work order is a request from another system and is not the same as Sequencescape's existing `WorkOrder` model, which groups requests after they have been created. The endpoint therefore persists the external request, translates its payload into one or more ordinary Sequencescape `Submission` records, and then uses the existing submission-building workflow.

```mermaid
flowchart TD
    A[External system sends work-order payload] --> B[POST /api/v2/external-work-orders]
    B --> C[Find or create ExternalWorkOrderRequest]
    C --> D{External ID already exists?}

    D -->|No| E[Store external ID and payload digest]
    D -->|Same digest| F[Return existing work order and submissions]
    D -->|Different digest| G[Return 409 Conflict]

    E --> H[Validate external payload]
    H --> I{Payload valid?}
    I -->|No| J[Mark external request failed and return 422]
    I -->|Yes| K[Translate payload into submission input]

    K --> L[Resolve templates, users, studies, projects, and receptacles]
    L --> M[Create submissions and orders in one transaction]
    M --> N{Transaction succeeds?}
    N -->|No| O[Rollback and mark external request failed]
    N -->|Yes| P[Mark external request queued]
    P --> Q[Enqueue ExternalWorkOrderBuilderJob]
    Q --> R[Return 202 Accepted]

    Q -. one submission per job run .-> S[Load next translated submission]
    S --> T{More submissions?}
    T -->|Yes| U[Build one submission through existing workflow]
    U --> V[Submission state: ready or failed]
    V --> W[Enqueue coordinator for next submission]
    W --> S

    T -->|No| X[Mark external request completed or failed]
    X --> Y[Create webhook delivery record]
    Y --> Z[Enqueue ExternalWorkOrderWebhookJob]
    Z --> AA[POST signed completion webhook to external system]
    AA --> AB{Webhook succeeds?}
    AB -->|Yes| AC[Mark delivery delivered]
    AB -->|No| AD[Record error and retry with backoff]

    style B fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style E fill:#f6d365,stroke:#9a6b00,color:#000000
    style F fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style G fill:#f8d7da,stroke:#a33,color:#000000
    style K fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style M fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style Q fill:#f6d365,stroke:#9a6b00,color:#000000
    style R fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style X fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style AA fill:#fff3cd,stroke:#9a6b00,color:#000000
    style AD fill:#fff3cd,stroke:#9a6b00,color:#000000
```

## Translation boundary

The external work-order adapter should convert the external payload into the canonical input needed to create Sequencescape submissions and orders. It should resolve external identifiers and map external concepts to Sequencescape concepts, including:

- external work-order type to a submission template;
- external user or account to a Sequencescape user;
- external study and project references to Sequencescape records;
- external source containers to receptacles;
- external options to order request options;
- one external work order to one or more submissions when the payload requires it.

The mapper should not build request graphs directly. Once the submissions are created and queued, the existing submission state machine and builder workflow remain responsible for creating requests and target receptacles.

## Existing `WorkOrder` distinction

Sequencescape's existing `WorkOrder` model groups already-created requests by work-order type. It is produced downstream from submission processing and should not be used as the inbound idempotency record for this endpoint. A separate parent record, such as `ExternalWorkOrderRequest`, can store the external ID, payload digest, callback details, mapping status, and references to the generated submissions.
