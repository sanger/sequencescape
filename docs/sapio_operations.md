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
`config/schemas/work-order-schema/`.

Sequencescape also needs `request.external_id`, a non-empty string: the
request ID, which must be unique for the calling system.

Each environment checks bodies against one schema version, set in its
configuration. The body's `request.schema_version` isn't used to choose
it; a schema error's `meta` shows the version used.

| Version | Adds                                                                                                                          |
| ------- | ----------------------------------------------------------------------------------------------------------------------------- |
| 1       | labware, receptacles and samples, and the work order                                                                          |
| 2       | three optional sample fields: `volume`, `concentration` and `genome_size` (see "Volume, concentration and genome size" below) |

An environment on version 1 rejects a body with the version 2 fields: a
422 with "is a disallowed additional property" at the field's pointer.

The smallest valid body, for versions 1 and 2 of the schema: one tube with
one sample, and a work order for the tube.

```json
{
  "request": {
    "external_id": "request-1",
    "request_type": "reception_and_work_order",
    "schema_version": "1"
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
first 20 errors are returned; the top-level `meta` gives the total and how
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
      "meta": { "schema": "work-order-schema", "version": 1 }
    },
    {
      "title": "Payload Does Not Match Schema",
      "detail": "object at `/labware/0` is missing required properties: barcode",
      "code": "SCHEMA_VALIDATION_FAILED",
      "source": { "pointer": "/labware/0" },
      "status": "422",
      "meta": { "schema": "work-order-schema", "version": 1 }
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

- Key order, whitespace and how a decimal is written (`1.10` or `1.1`) don't
  matter.
- Array order, values, and whether a number is an integer or a decimal (`1`
  or `1.0`) do.

## After the 202

Sequencescape processes the operation in the background, one task after
another: the labware reception, then the work order (Y26-289). Operations
stay `queued` while reception is switched off (the
`y26_283_sapio_reception` feature flag).

### Statuses

| Status                | Meaning                                                                           |
| --------------------- | --------------------------------------------------------------------------------- |
| `queued`              | Accepted; no task has completed, including while reception runs or waits to retry |
| `reception_completed` | The labware and its samples are in Sequencescape                                  |
| `reception_failed`    | Reception failed and kept nothing; the operation's errors say why                 |

The status names the last task completed or failed: there is no status
for a task in progress. Sending the request again with the same request
ID returns the operation with its current status (200).

A failed operation isn't processed again, and a corrected payload under the
same request ID is a conflict (409). A corrected request needs a new
request ID. When an earlier attempt's reception completed, the new
request's reception finds the labware it created and leaves it as it is.

### Errors

A failed task's errors are stored with the operation: the task, and one
error for each problem, with a JSON Pointer into the request body and a
detail. An empty pointer means the whole request. Y26-285 sends the
outcome and these errors back to Integration Hub.

```json
{
  "task": "reception",
  "errors": [
    {
      "pointer": "/labware/0/receptacles/0/samples/0/study_uuid",
      "detail": "No study with UUID 6f1c1d2e-0000-4000-8000-000000000004 (used by 1 sample)"
    }
  ]
}
```

A task fails for one of three reasons:

- **Problems in the request**, such as an unknown study, or labware that
  doesn't match what Sequencescape already has. Reception checks the whole
  request first and reports every problem it finds, each with its pointer.
  It creates nothing.
- **A temporary problem in Sequencescape** that doesn't clear (see Retries,
  below): pointer `""`, detail "Reception could not be
  completed because of a temporary problem in Sequencescape; send the
  request again with a new request ID".
- **An error in Sequencescape**: pointer `""`, detail "Reception could not
  be completed because of an error in Sequencescape; PSD has been
  notified". When a record breaks a rule reception's checks don't cover,
  the detail gives the rule's message instead: "Reception could not be
  completed: Validation failed: …; PSD has been notified".

### Retries

Each task runs in a database transaction of its own: what it creates, the
operation's status and its errors are saved together, or not at all. A
temporary problem in Sequencescape rolls the task back, and the job runs
it again later. These problems are a deadlock, a lock wait timeout, a
lost or refused database connection, and a record that another request
saved at the same moment.

The job that processes an operation runs its tasks at most 10 times in
all: the limit is per operation, so reception and the work order share
it. A run that completes reception and goes on to the work order counts
once for each. The waits between runs start at 30 seconds and double, up
to 1 hour:

| Run | Wait before it | Starts at, from the first run |
| --- | -------------- | ----------------------------- |
| 1   |                | 0:00:00                       |
| 2   | 30 s           | 0:00:30                       |
| 3   | 1 min          | 0:01:30                       |
| 4   | 2 min          | 0:03:30                       |
| 5   | 4 min          | 0:07:30                       |
| 6   | 8 min          | 0:15:30                       |
| 7   | 16 min         | 0:31:30                       |
| 8   | 32 min         | 1:03:30                       |
| 9   | 1 h            | 2:03:30                       |
| 10  | 1 h            | 3:03:30                       |

The times leave out how long each run takes. If the 10th run fails, the
task it was running fails with the temporary problem error, and PSD gets
one message.

When a run is stopped part way, for example when a deployment restarts
the workers, the task it was running saves nothing. Another worker runs
the job again once its lock has expired, about 4 hours after the run
started (Delayed Job's `max_run_time`). That run counts as one of the 10.

Other errors in Sequencescape aren't retried, as the same run would fail
the same way. ([One endpoint or two?][one_endpoint_or_two] expected
Delayed Job to retry them.)

[one_endpoint_or_two]: https://ssg-confluence.internal.sanger.ac.uk/spaces/PSDPUB/pages/365756493

## Reception

Reception sorts the request's labware into labware Sequencescape already
has and new labware ([ADR 074][adr_074]). It checks the whole request, and
creates the new labware and its samples only when it finds no problems.

[adr_074]: https://ssg-confluence.internal.sanger.ac.uk/spaces/SLIM/pages/354943562

### Labware Sequencescape already has

A labware is known when its barcode is any of a Sequencescape labware's
barcodes, whatever else the request says about it. A barcode Sequencescape
doesn't have is new labware, even when its samples' supplier names match
samples in Sequencescape.

Known labware must be the same as in Sequencescape:

- the same type, a plate or a tube, and for a plate the same number of
  wells;
- in each well, or in the tube, the same number of samples, with the same
  supplier sample names, in any order. A well the request doesn't list
  counts as empty.

Known labware that is the same is left as it is. Reception doesn't check,
change or add to it, or its samples, and doesn't store the request's UUIDs
for them. Known labware that isn't the same is a conflict, and the
operation fails. For example:

| Pointer                    | Detail                                                                  |
| -------------------------- | ----------------------------------------------------------------------- |
| `/labware/0/type`          | TUBE-1 is a 96-well plate in Sequencescape, not a tube                  |
| `/labware/1/receptacles/2` | well C1 of PLATE-1 has 2 samples in Sequencescape, not 1 sample         |
| `/labware/1/receptacles/3` | well D1 of PLATE-1 has different supplier sample names in Sequencescape |
| `/labware/1`               | well E1 of PLATE-1 has 1 sample in Sequencescape, not 0 samples         |

The last is a well that has a sample in Sequencescape but isn't in the
request, so its error points at the labware.

### Checks on new labware

Reception checks the new labware and its samples before it creates
anything, and reports every problem it finds. A name Sequencescape doesn't
have, such as an unknown study or tag group, is reported once, at the
first sample that uses it, with how many samples do: one wrong value in a
large request gives one error.

**Labware:**

- Each barcode appears once in the request, known labware included.
- New 384-well plates aren't supported by reception.
- A new tube has one receptacle, with a `null` position.
- A new plate's positions are wells of its size, each listed once.

**Samples:**

- The study (`study_uuid`) exists. Its state isn't checked.
- The sample's `uuid` isn't used by any record in Sequencescape. Its
  `sanger_sample_id` isn't already a sample's Sanger sample ID or name,
  ignoring case, and no two samples in the request share one.
- A sample in more than one receptacle (the same `uuid`) has the same
  `sanger_sample_id`, `supplier_sample_name`, `study_uuid` and
  `genome_size` in each: a genome size is the organism's, not the
  receptacle's, so a sample has one. A missing genome size differs from a
  given one. The sample's `volume` and `concentration` may differ, as they
  describe its receptacles. It becomes one sample.
- A sample in one receptacle more than once has tags in all but one.
- A `volume` or `concentration` can be stored: a sample's entry in a
  receptacle with other samples gives neither when the sample has another
  entry, as neither the receptacle nor the sample could keep it (see
  "Volume, concentration and genome size" under "What reception creates").
- The values the sample's records would reject: `sanger_sample_id`, which
  becomes the sample's name, has only letters, digits, `_` and `-`; the
  supplier sample name has only ASCII characters and isn't blank;
  `donor_id` has no characters of more than 3 bytes, such as emoji.

**Fields a sample manifest also has**, checked as the manifest's
specialised field checks them (`SequencescapeExcel::SpecialisedField`,
`SampleManifestExcel::Tags::Validator`). Rules marked \* are reception's
own: a manifest has one column for each, so they can't contradict.

| Fields                                               | Rule                                                                                                                                                                           | Manifest rule                                    |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ |
| `reference_genome`                                   | An existing reference genome, ignoring case                                                                                                                                    | `ReferenceGenome`                                |
| `library_type`, `library_type_long_read`             | An existing library type, ignoring case; the same when both are given\*                                                                                                        | `LibraryType`                                    |
| `primer_panel`                                       | An existing primer panel, ignoring case                                                                                                                                        | `PrimerPanel`                                    |
| `insert_size_from`, `insert_size_to`                 | Whole numbers of at least 1 (the schema checks this); from is at most to when both are given\*                                                                                 | `InsertSizeFrom`, `InsertSizeTo`                 |
| `control_type`, `bioscan_control_type`               | The same when both are given\*                                                                                                                                                 | `ControlType`, `BioscanControlType`              |
| `bioscan_control_type`                               | The supplier name begins with `CONTROL_`; a pcr positive or pcr negative control isn't in H12; a lysate negative control is in H12, so not in a tube                           | `BioscanControlType`                             |
| `i7`, `i5`                                           | Only A, C, G, T or N, in either case, and at most 30 characters                                                                                                                | `Formatting`                                     |
| `tag_group`, `tag_index`, `tag2_group`, `tag2_index` | A group needs its index, and an index its group; the group exists, ignoring case, and has a tag at the index                                                                   | `TagGroup`, `TagIndex`, `Tag2Group`, `Tag2Index` |
| `dual_index_tag_set`, `dual_index_tag_well`          | A visible dual index tag set; a well of its plate, A1 to H12 (A01 is read as A1), whose position by column gives both tags, which exist; the receptacle holds only that sample | `DualIndexTagSet`, `DualIndexTagWell`            |
| `chromium_tag_group`, `chromium_tag_well`            | A visible single-index Chromium tag set; a well of its kit plate, A1 to H12, whose 4 tags exist; the receptacle holds only that sample                                         | `ChromiumTagGroup`, `ChromiumTagWell`            |

For dual index and Chromium wells, reception is stricter than the
manifest: a well that isn't on the plate, such as I1 or A13, is an error,
where the manifest reads some such wells as another well.

**Tags:**

- A sample gives its tags one way only: as `i7` and `i5`, as tag groups
  and indexes, as a dual index tag set and well, as a Chromium tag set and
  well, or not at all.
- In a new receptacle, samples with tags have different tags: their i7 and
  i5 oligos are compared, ignoring case, as the multiplexed library tube
  manifest compares them (`Uniqueness`). Different tag records can have
  the same oligos.
- Samples without tags in one receptacle are a pool, not a clash.

### What reception creates

**Labware.** Each new labware gets a stock purpose, chosen by whether its
samples have tags, given in any of the ways above. Library type and insert
sizes don't decide it.

| Request                               | Purpose               | Example                                               |
| ------------------------------------- | --------------------- | ----------------------------------------------------- |
| `plate96`, no sample has tags         | `Stock Plate`         | a plate of DNA samples                                |
| `plate96`, a sample has tags          | `Library Stock Plate` | a plate of libraries, one in each well                |
| `tube`, no sample has tags            | `Standard sample`     | one sample, or an untagged pool, such as scRNA Core's |
| `tube`, one sample has tags           | `Standard library`    | one library                                           |
| `tube`, more than one sample has tags | `Standard MX`         | a multiplexed library                                 |

The labware's only barcode is the one it arrived with (`barcode`, stored
in the external format): reception gives it no Sanger barcode. A plate is
named `Plate <barcode>` and gets all the wells of its size. The request's
labware and receptacle UUIDs aren't stored.

**Samples.** Reception creates one sample for each `uuid`, so a sample in
more than one receptacle is one sample. Each sample is externally managed:
Sapio writes the warehouse records for it, so Sequencescape doesn't send
the messages about it, its aliquots or its study link. The fields are
stored as a sample manifest stores the matching fields:

| Request field                                      | The sample's                                              |
| -------------------------------------------------- | --------------------------------------------------------- |
| `uuid`                                             | UUID, in lower case                                       |
| `study_uuid`                                       | study                                                     |
| `sanger_sample_id`                                 | name and Sanger sample ID                                 |
| `supplier_sample_name`, or `bioscan_supplier_name` | supplier name; `bioscan_supplier_name` replaces the other |
| `donor_id`                                         | donor ID                                                  |
| `reference_genome`                                 | reference genome, found by name                           |
| `control_type`, or `bioscan_control_type`          | control and control type                                  |
| `priority`                                         | priority                                                  |
| `genome_size`                                      | genome size                                               |

Supplier names such as Water, Blank, EMPTY or None are kept as samples, as
sample manifests keep them. Volume and concentration are below.

**Aliquots.** Each sample gets an aliquot in each receptacle that lists it,
with its study, and the library type (under Sequencescape's own name),
insert sizes and primer panel it gives. Its tags, as sample manifests set
them:

- a tag group and index, and tag 2's if given: one aliquot with the tag,
  and tag 2;
- a dual index tag set and well: one aliquot with the well's two tags;
- a Chromium tag set and well: four aliquots, one for each of the well's
  tags;
- `i7` and `i5`: one aliquot, with tags found or created in the Magic Tag
  Group by their oligos.

On labware whose samples have tags, each aliquot's library is its
receptacle, as library manifests set it, so the samples in a received
`Standard MX` tube share the tube as their library. Samples without tags
that share a receptacle get tag depths 1, 2, 3 and so on, in the order the
request lists them, so their aliquots can be told apart.

**Not created:** compound samples (samples made of other samples): a
pool's samples are received as separate samples. Nor a sample manifest, a
supplier, retention instructions, stock resource records or requests.
Reception doesn't accession the samples.

**Volume, concentration and genome size.** Schema version 2 adds three
optional sample fields: `volume` in µl and `concentration` in ng/µl, each
a number of at least 0, and `genome_size`, a whole number of at least 0.
They are the sample manifest's VOLUME (ul), CONC. (ng/ul) and GENOME SIZE
columns.

`genome_size` goes into the sample's metadata. `volume` and
`concentration` describe what is in a receptacle, so they are stored in
two places:

- **QC results on the well or tube**, when it holds only that sample: a
  customer-supplied QC result for each (key `volume`, units `ul`; key
  `concentration`, units `ng/ul`; assay version `v0.0`), in a QC assay
  whose lot number is `api_operation_id:<operation's id>`. A QC result
  sets its receptacle's own value, which pipelines read: a well's measured
  volume and concentration, a tube's volume. A tube's own concentration is
  molar, so a tube keeps ours in the QC result only.
- **The sample's metadata**, when the sample has only one entry in the
  request. The metadata's volume and concentration are text, so a number
  is kept as written: `12.5`, `10`.

| The sample is                                    | Its metadata          | QC results                  |
| ------------------------------------------------ | --------------------- | --------------------------- |
| the only sample in one well or tube              | volume, concentration | on that well or tube        |
| one of the samples in a pool or an MX tube, once | volume, concentration | none                        |
| the only sample in several wells or tubes        | none                  | on each, from its own entry |

A sample in a pool that also has another entry can't keep a volume or
concentration from its pooled entry, so the request is rejected if that
entry gives one (see the checks).

A sample manifest's VOLUME also makes a customer-supplied QC result on the
row's well or tube; its CONC. goes into the metadata only. Each manifest
row is one sample in its own receptacle, so a manifest never has the other
cases. In an MX library manifest a row's receptacle is the library's own
tube, which reception doesn't make: a received MX tube's samples keep
their values in their metadata.

### Sample data, the warehouse and the callback

- **Sample fields:** reception stores every sample field the schema has.
  Of the optional ones, `donor_id` is needed (scRNA Core's pooling uses
  it); `reference_genome`, `control_type`, `priority`,
  `bioscan_supplier_name` and `bioscan_control_type` could be removed from
  the schema. Sample manifest fields the request doesn't have, such as the
  sample metadata, taxon ID and EBI accession number, are left to Sapio.
- **Warehouse:** Sapio writes the warehouse (MLWH) records for its
  samples and studies, so Sequencescape doesn't send these messages:

  | Not sent                                       | Why                                                                                                                                                                                                                    |
  | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | the samples                                    | the MLWH sample table is Sapio's for them: Sequencescape's would be duplicates (Y26-267)                                                                                                                               |
  | their studies                                  | the same, for the study table (Y26-172)                                                                                                                                                                                |
  | the samples' aliquots and study links          | they are about Sapio's samples (Y26-283)                                                                                                                                                                               |
  | reception's QC results (volume, concentration) | the MLWH stores a QC result only once it has the sample, and these would be sent seconds after reception. The MLWH sample table, which Sapio writes, has columns for the customer's volume and concentration (Y26-327) |

  Sequencescape still sends, as for any labware:

  - messages about the new labware and wells, which the MLWH doesn't
    store;
  - the QC results the lab adds later, such as volume checks and
    concentrations. The MLWH stores each in its `qc_result` table, a row
    for each aliquot, linked to the sample it finds by UUID; it doesn't
    change the sample;
  - flowcell messages, when the samples are sequenced, which name the
    samples by UUID.

  The MLWH finds a sample only by its UUID, so Sapio must have written the
  sample before the lab's first QC result or flowcell message about it.
  Reception keeps the request's sample UUIDs, so they match.

- **For the callback:** an operation keeps its status, its events (each
  task's runs, and when it completed or failed) and its errors. Which
  labware reception created and which it matched isn't stored.

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

- **Schema files:** `config/schemas/<subject>/<version>.<extension>`, for
  example `config/schemas/work-order-schema/1.json`. The extension gives
  the type (`.json` for JSON Schema, `.avsc` for Avro). Versions are
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

- **Adding a task**, such as the work order:
  1. A subclass of `ApiOperation::Task`. Its `#call` does the work and
     returns the errors, `[{ pointer:, detail: }]`, empty on success. The
     job runs it in a transaction with the operation's row locked, so its
     records commit with the status or not at all. It raises for a problem
     that isn't in the payload: a transient error is retried, and any other
     fails the task and notifies PSD.
  2. Its line in `ApiOperation::Task.for`, which finds a task's class by
     its name.
  3. Its name in `ApiOperation::TASKS`, after the task it follows. This
     also allows the statuses `<task>_completed` and `<task>_failed`.

  The job does the rest for every task: a `started` event before each run,
  the retries, and the limit of `MAX_RUNS` runs per job. It runs
  every task in `TASKS` while `y26_283_sapio_reception` is on, so a task
  with a flag of its own needs the job to check that flag too. The specs
  that list a type's statuses (`spec/models/api_operation_spec.rb`) or stub
  its tasks (`spec/jobs/api_operation/coordinator_job_spec.rb`) change with
  `TASKS`.

- **Adding an operation type:** an operation's type is its request's
  `request.request_type`. The schema must allow the new value (versions 1
  and 2 allow only `reception_and_work_order`), and `ApiOperation::TASKS`
  gets the type with its tasks in order. Another calling system needs an
  endpoint and schema settings of its own: this endpoint and the
  `sapio_schema_*` settings are Sapio's.
- **Code:** `Api::V2::Sapio::OperationsController`, `ApiOperation` (the
  `api_operations` table), `ApiOperation::SchemaCheck`, the `Schemas`
  classes, `ApiOperation::CoordinatorJob`, which processes each new
  operation in the background, and its tasks (`ApiOperation::Task`).
