# Default Records README

This directory contains the config definitions for the Pipelines defined in Limber.

Please note the the information contained within this readme is not exhaustive, and is intended to be used as a guide only. It is based on the recently created 'scRNA Core Cell Extraction' pipeline (a naive duplicate of Cardinal, and currently under active development).

## Structure

Each subdirectory contains the config for a different aspect of pipeline operations.

The subdirectories are:

- `barcode_printer_types`:
- `flowcell_types`:
- `flowcell_types_request_types`:
- `library_types`:
- `pipeline_request_information_types`:
- `pipelines`:
- `plate_purposes`:
- `plate_types`:
- `primer_panels`:
- `product_catalogues`:
- `request_information_types`:
- `request_type_validators`:
- `request_types`:
- `robot_properties`:
- `robots`:
- `submission_templates`:
- `tag_group_adapter_types`:
- `tag_groups`:
- `tag_layout_templates`:
- `transfer_templates`:
- `tube_purposes`: The initial tubes that enter via the manifest from Limber.
- `tube_rack_purposes`:

### Product Catalogues

This seems to be required and to match the nominal pipeline name. It is not clear what the purpose of this is.

### Request Types

The name of an item created here should correspond with a `request_type_keys` entry defined in the `submission_templates` directory.  
Any listed `acceptable_purposes` should also be defined in the `plate_purposes` or `tube_purposes` directories.

### Submission Templates

The `request_type_keys` must match the name of the `request_type` defined in the `request_types` directory.

### Tube Purposes

The first Tube defined in the pipeline in Limber must be defined for use here too. The later Purposes will be automatically created by SequenceScape itself.
