# Schemas

Schemas that request payloads are checked against. `Schemas::LocalSource`
(`app/models/schemas/local_source.rb`) reads them when an environment's
schema source is `local`. The settings that choose the schema
(`config.sapio_schema_source`, `_subject` and `_version`) are described in
`docs/sapio_operations.md`.

## Layout

```
config/schemas/<type>/<subject>/<version>.<extension>
```

- `<type>`: `json_schema` for JSON Schema (`.json` files), or `avro` for
  Avro (`.avsc` files). The folder gives the schema's type.
- `<subject>`: the schema's name, as in a schema registry, for example
  `work-order-schema`.
- `<version>`: a whole number without leading zeros: `1.json`, `2.json` and
  so on. Files named otherwise, such as `draft.json`, `v1.json` or
  `01.json`, are ignored.

For example: `json_schema/work-order-schema/1.json`.

## Versions

- The latest version is the highest number; the `latest` setting uses it.
- Use a fixed version, not `latest`, in deployed environments. With
  `latest`, a new version changes which payloads are accepted as soon as
  it is deployed, or registered in a schema registry, without any change
  to the settings. `latest` is meant for development and tests.
- As in a schema registry, all versions of a subject have the same type, so
  a subject in more than one type folder is an error.
- Tests use `latest`, so a new version that the test payloads don't match
  fails the specs, as a backward compatible change shouldn't.
