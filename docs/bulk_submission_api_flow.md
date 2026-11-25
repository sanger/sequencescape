# Proposed bulk submission API flow

This document proposes an idempotent bulk-submission API endpoint. The bulk request is persisted as the idempotency and coordination record. A coordinator job builds its submissions sequentially, then creates a durable webhook delivery once the whole operation reaches a terminal state.

```mermaid
flowchart TD
    A[API client sends JSON payload] --> B[POST /api/v2/bulk-submission-requests]
    B --> C[Find or create BulkSubmissionRequest]
    C --> D{External ID already exists?}

    D -->|No| E[Store external ID and payload digest]
    D -->|Same digest| F[Return existing request and submissions]
    D -->|Different digest| G[Return 409 Conflict]

    E --> H[Validate payload and resolve UUIDs]
    H --> I{Payload valid?}
    I -->|No| J[Mark request failed and return 422]
    I -->|Yes| K[Create submissions and orders in one transaction]

    K --> L{Transaction succeeds?}
    L -->|No| M[Rollback and mark request failed]
    L -->|Yes| N[Mark request queued]
    N --> O[Enqueue BulkSubmissionBuilderJob]
    O --> P[Return 202 Accepted]

    O -. one submission per job run .-> Q[Load next unprocessed submission]
    Q --> R{More submissions?}
    R -->|Yes| S[Build one submission]
    S --> T[Submission state: ready or failed]
    T --> U[Enqueue coordinator for next submission]
    U --> Q

    R -->|No| V[Mark bulk request completed or failed]
    V --> W[Create webhook delivery record]
    W --> X[Enqueue BulkSubmissionWebhookJob]
    X --> Y[POST signed completion webhook]
    Y --> Z{Webhook succeeds?}
    Z -->|Yes| AA[Mark delivery delivered]
    Z -->|No| AB[Record error and retry with backoff]

    style B fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style E fill:#f6d365,stroke:#9a6b00,color:#000000
    style F fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style G fill:#f8d7da,stroke:#a33,color:#000000
    style K fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style O fill:#f6d365,stroke:#9a6b00,color:#000000
    style P fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style V fill:#d9f2d9,stroke:#4b8b4b,color:#000000
    style Y fill:#fff3cd,stroke:#9a6b00,color:#000000
    style AB fill:#fff3cd,stroke:#9a6b00,color:#000000
```
