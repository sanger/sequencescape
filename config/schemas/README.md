# Schemas

Schemas that request payloads are checked against. Sequencescape gets them
from a schema registry (RedPanda), or from the files in this folder.
`Schemas::LocalSource` (`app/models/schemas/local_source.rb`) reads the files
when an environment's schema source is `local`, as in development and tests,
which need no registry. The settings that choose the schema
(`config.sapio_schema_source`, `_subject` and `_version`) are described in
`docs/sapio_operations.md`.

## Layout

```
config/schemas/<subject>/<version>.<extension>
```

- `<subject>`: the schema's name, as in a schema registry, for example
  `work-order-schema`. The folder gives the subject: the schema files
  don't name it.
- `<version>`: a whole number without leading zeros: `1.json`, `2.json` and
  so on. Files named otherwise, such as `draft.json`, `v1.json` or
  `01.json`, are ignored.
- `<extension>`: `.json` for JSON Schema, or `.avsc` for Avro. The
  extension gives the schema's type. Files with other extensions are
  ignored.

For example: `work-order-schema/1.json`.

## Versions

- The latest version is the highest number; the `latest` setting uses it.
- Use a fixed version, not `latest`, in deployed environments. With
  `latest`, a new version changes which payloads are accepted as soon as
  it is deployed, or registered in a schema registry, without any change
  to the settings. `latest` is meant for development and tests.
- As in a schema registry, all versions of a subject have the same type, so
  a subject folder with both `.json` and `.avsc` versions is an error.
- Tests use `latest`, so a new version that the test payloads don't match
  fails the specs, as a backward compatible change shouldn't.

## Modifying schemas managed by RedPanda

Each RedPanda instance has an admin web console, where schemas can be
changed in a visual editor. The console is at the instance's base URL
followed by `/console/`, and needs the credentials in the team password
vault. Use only its Schema Registry section: Sequencescape doesn't use the
other parts of RedPanda.

New versions of schemas are added by hand in the RedPanda console.
