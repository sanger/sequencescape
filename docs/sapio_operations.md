# @title Sapio Operations API

# Sapio Operations API

Integration Hub sends a combined labware reception and work order request
from Sapio to one endpoint. Sequencescape checks the request, records it as
an operation and answers straight away. The reception and the work order
are processed afterwards, in the background.

## Endpoint

`POST /api/v2/sapio/operations`

| Header                      | Value                       |
| --------------------------- | --------------------------- |
| `Content-Type`              | `application/json`          |
| `X-Sequencescape-Client-Id` | The Integration Hub API key |

The body is plain JSON, not JSON:API. The endpoint is behind the
`y26_282_sapio_operations_endpoint` feature flag; while the flag is off, it
returns 404 `FEATURE_DISABLED`.

## Request body

The body must match the work order schema, the contract between Integration
Hub and Sequencescape. Its versions are kept in this repository, in
`config/schemas/json_schema/work-order-schema/`.

Sequencescape also needs `request.external_id`, a non-empty string: the
request ID, which must be unique for the calling system.

The smallest valid body for version 3 of the schema: one tube with one
sample, and a work order for the tube.

```json
{
  "request": {
    "external_id": "request-1",
    "request_type": "reception_and_work_order",
    "schema_version": "0.3"
  },
  "labware": [
    {
      "uuid": "6f1c1d2e-0000-4000-8000-000000000001",
      "barcode": "TUBE-1",
      "type": "tube",
      "receptacles": [
        {
          "position": null,
          "uuid": "6f1c1d2e-0000-4000-8000-000000000002",
          "samples": [
            {
              "uuid": "6f1c1d2e-0000-4000-8000-000000000003",
              "study_uuid": "6f1c1d2e-0000-4000-8000-000000000004",
              "sanger_sample_id": "SAMPLE-1",
              "supplier_sample_name": "sample 1"
            }
          ]
        }
      ]
    }
  ],
  "work_order": {
    "external_id": "work-order-1",
    "service_name": "service",
    "requested_by": "user",
    "cost_code": "S0001",
    "requested_labware_identifiers": ["TUBE-1"],
    "options": {}
  }
}
```

## Responses

| Status | Code                       | When                                                                      |
| ------ | -------------------------- | ------------------------------------------------------------------------- |
| 202    |                            | A new request is accepted                                                 |
| 200    |                            | The same request ID is sent again with the same payload                   |
| 400    | `INVALID_JSON`             | The body is not valid JSON                                                |
| 401    | `401`                      | No API key, or an unknown one                                             |
| 403    | `FORBIDDEN`                | An API key other than Integration Hub's                                   |
| 404    | `FEATURE_DISABLED`         | The endpoint is switched off                                              |
| 409    | `PAYLOAD_CONFLICT`         | The request ID was already used with a different payload                  |
| 422    | `INVALID_STRUCTURE`        | The body is not a JSON object, or `request.external_id` is missing        |
| 422    | `SCHEMA_VALIDATION_FAILED` | A new request doesn't match the schema                                    |
| 500    | `SCHEMA_UNAVAILABLE`       | The schema can't be loaded; this is a Sequencescape configuration problem |
| 503    | `SCHEMA_UNAVAILABLE`       | The schema registry can't be reached; try again after `Retry-After`       |

### Accepted and repeated requests

A new request gets 202; sending it again gets 200 with the same body. The
status starts as `queued`.

```json
{
  "operation_id": "c09a37c4-ce64-11f1-b688-1ae941b82136",
  "status": "queued"
}
```

### Errors

Errors follow the JSON:API error format. Each has a `status`, `code`,
`title` and `detail`, and a `source.pointer` (a JSON Pointer into the
request body) when the error is about one part of it.

```json
{
  "errors": [
    {
      "title": "Conflict",
      "detail": "The request ID request-1 was already used with a different payload.",
      "code": "PAYLOAD_CONFLICT",
      "source": { "pointer": "/request/external_id" },
      "status": "409"
    }
  ]
}
```

### Schema errors

A new request that doesn't match the schema gets one error for each
problem, with the schema and version it was checked against. At most the
first 100 errors are returned; the top-level `meta` gives the total and how
many are shown. For a missing property, the pointer is the object that
lacks it, and the detail names the property.

```json
{
  "errors": [
    {
      "title": "Payload Does Not Match Schema",
      "detail": "value at `/labware/0/type` is not one of: [\"plate96\", \"plate384\", \"tube\"]",
      "code": "SCHEMA_VALIDATION_FAILED",
      "source": { "pointer": "/labware/0/type" },
      "status": "422",
      "meta": { "schema": "work-order-schema", "version": 3 }
    },
    {
      "title": "Payload Does Not Match Schema",
      "detail": "object at `/labware/0` is missing required properties: barcode",
      "code": "SCHEMA_VALIDATION_FAILED",
      "source": { "pointer": "/labware/0" },
      "status": "422",
      "meta": { "schema": "work-order-schema", "version": 3 }
    }
  ],
  "meta": { "errors_total": 2, "errors_shown": 2 }
}
```

### Schema unavailable

A new request gets 500 `SCHEMA_UNAVAILABLE` when Sequencescape can't load the
schema because of its own configuration, and 503 `SCHEMA_UNAVAILABLE` when
the schema registry can't be reached. A 503 has a `Retry-After` header with
the seconds to wait (60) before sending the request again with the same
request ID. In both cases nothing is stored, and PSD is told the cause.

## Repeated requests

- A request ID is unique for each calling system. Sending the same request
  ID with the same payload returns the existing operation (200), and doesn't
  create or restart anything.
- The same request ID with a different payload is a conflict (409).
- Two requests with the same request ID that arrive together create one
  operation; the other is answered as a repeat.
- Only new requests are checked against the schema, so a repeat always gets
  its operation back, whatever the schema version in use.
- A rejected request (400, 422, 500 or 503) isn't stored, so its request ID stays
  unused and a corrected payload can be sent with it.

## What counts as the same payload

Two payloads are the same when they hold the same JSON data:

- Key order, whitespace and how a number is written (`1.10` or `1.1`) don't
  matter.
- Array order and values do.

## For Sequencescape developers

- **Feature flag:** `y26_282_sapio_operations_endpoint`.
- **Settings**, in `config/environments/<env>.rb`:

  | Setting                            | Development default (environment variable)                   |
  | ---------------------------------- | ------------------------------------------------------------ |
  | `config.sapio_schema_source`       | `local` (`SAPIO_SCHEMA_SOURCE`)                              |
  | `config.sapio_schema_subject`      | `work-order-schema` (`SAPIO_SCHEMA_SUBJECT`)                 |
  | `config.sapio_schema_version`      | `latest` (`SAPIO_SCHEMA_VERSION`)                            |
  | `config.sapio_schema_registry_url` | only for the `redpanda` source (`SAPIO_SCHEMA_REGISTRY_URL`) |

  The source is `local` (files in this repository) or `redpanda` (a schema
  registry); `development.rb` has the registry settings commented out. The
  test environment has fixed values. Deployed environments get theirs from
  the deployment project (`environment_template.rb.j2`), and need them
  before the flag is switched on. Production uses a fixed version, never
  `latest`, so a new schema version only takes effect when it is deployed on
  purpose.

- **Schema files:** `config/schemas/<type>/<subject>/<version>.<extension>`,
  for example `config/schemas/json_schema/work-order-schema/3.json`. The
  folder gives the type (`json_schema`, or `avro` with `.avsc`). Versions are
  whole numbers, and `latest` is the highest. As in a schema registry, all
  versions of a subject have the same type.
- **Adding a version:** tests use `latest`, so a new version that the test
  payloads don't match fails the specs, as a backward compatible change
  shouldn't.
- **Schema registry:** the `redpanda` source reads
  `<registry URL>/subjects/<subject>/versions/<version>` through
  `HTTPClients::SchemaRegistryClient`. The registry's `schemaType` gives the
  type: `JSON` is JSON Schema, and none is Avro, which has no validator.
  Fetched versions are kept in `Rails.cache`; `latest` is always fetched. The
  client's time limits are its `OPEN_TIMEOUT` and `TIMEOUT` constants; a
  registry that can't be reached gives a 503 and an exception email.
- **A local schema registry**, for development:

  ```sh
  docker run -ti -p 9092:9092 -p 8081:8081 redpandadata/redpanda

  # Register a schema file as the subject's next version
  jq -Rs '{schema: ., schemaType: "JSON"}' < <schema file> \
    | curl -X POST "http://localhost:8081/subjects/work-order-schema/versions" \
        -H 'Content-Type: application/vnd.schemaregistry.v1+json' \
        --data-binary @-

  # Read it back
  curl http://localhost:8081/subjects/work-order-schema/versions/latest
  ```

  Then run Sequencescape with `SAPIO_SCHEMA_SOURCE=redpanda`, and with the
  registry URL setting uncommented in `development.rb`.

- **Code:** `Api::V2::Sapio::OperationsController`, `ApiOperation` (the
  `api_operations` table), `ApiOperation::SchemaCheck`, the `Schemas`
  classes and `ApiOperation::CoordinatorJob`, which processes each new
  operation in the background.
