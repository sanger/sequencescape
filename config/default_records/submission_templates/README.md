# Submission templates

This directory contains the submission templates which, when loaded by the record loader, populate the submission templates table. The submission templates are used to generate submissions with pre-determined values that the user can then edit. N.B. This directory does not contain all the submission templates, some are generated via database seeds.

Each submission template is a YAML document. By default all files here are loaded by the record loader, however there is some custom behaviour in record_loader:

- Files with .dev.yml will only be loaded in development environments (NOT UAT).
- Files with .wip.yml will only be loaded if explicitly enabled via a WIP environmental variable.
  These can be generated by running `WIP=my_submission rake record_loader:all`

For more information on the record loader see the [record_loader README](https://github.com/sanger/record_loader).

## Submission template format

The structure and contents of submission templates are explained below:

#### Submission name header

Each template has a header key which determines the name of the submission template. This value is the key used at the top level of the YAML document and all other data nests within it. This is the name that will be displayed to the user when they are selecting a submission template to use.

```yaml
My submission template: ...
```

Alternatively the submission name can be specified in the name field.

```yaml
My submission template:
    name: My submission template
    ...
```

#### submission_class_name

The class to determine the type of submission. Options include _LinearSubmission_, _FlexibleSubmission_. The main difference between them is how the request type graph is generated. See the respective classes for more information.

```yaml
<submission_name>:
  submission_class_name: LinearSubmission
```

#### related_records

An object to determine the related records to the submission.

```yaml
<submission_name>:
  related_records:
    <record_name>: <record_id>
```

- #### product_line

  A value to determine the product line of the submission. The value must match the name of a product line in the product_lines table.

  ```yaml
  related_records:
    product_line: Illumina-HTP
  ```

- #### product_catalogue

  A value to determine the product catalogue of the submission. The value must match the name of a product catalogue in the product_catalogues table.

  ```yaml
  related_records:
    product_catalogue: Bait Capture Library
  ```

- #### request_type_keys

  A list of request type keys to determine the type of requests generated during submission. The values must match the name of a request type in the request_types table. The order of the request types in the list determines the order that the request types are associated with the submitted labware. This is important because it determines which requests have their state changed during work_completion. request_type_keys are stored in the submission_parameters field.

  ```yaml
  related_records:
    request_type_keys:
      - WGS
      - WTS
  ```

- #### project_name

  A value to determine the project name of the submission. The value must match the name of a project in the projects table. Stored as project_id in the submission_parameters field. This field determines which projects can be associated with the submission. See Submission::ProjectValidation for more details.

  ```yaml
  related_records:
    project_name: My project
  ```

- #### study_name

  A value to determine the study name of the submission. The value must match the name of a study in the studies table. Stored as study_id in the submission_parameters field.

  ```yaml
  related_records:
    project_name: My project
  ```
