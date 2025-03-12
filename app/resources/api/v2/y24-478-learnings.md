# Y24-478 Learnings and Possible Future To-Dos

## Further Research Needed

- [ ] `app/resources/api/v2/request_resource.rb`/ `app/resources/api/v2/request_metadata.rb` - Figure out how to send a POST request.
- [ ] `app/resources/api/v2/sample_resource.rb`/ `app/resources/api/v2/sample_metadata.rb` - Figure out how to send a POST request.
- [ ] `app/resources/api/v2/work_order_resource.rb` - How to create POST request, order_type vs work_order_type resource and model mismatch on presence and requirement.

## Possible Bugs

- [ ] `app/resources/api/v2/plate_template_resource.rb` - GET requests are throwing an exception.
- [ ] `app/resources/api/v2/purpose_resource.rb` - POST is broken as `target_type` is a required attribute in the model but not included in the resource. `lifespan` is also not an allowed attribute.
- [ ] `app/resources/api/v2/tag_group_adapter_type_resource.rb` states the `name` attribute is read-only, but the model requires its presence.
- [ ] `app/resources/api/v2/receptacle_resource.rb` - POST is broken as `display_name` is a required attribute in the model but not included in the resource.
- [ ] `app/resources/api/v2/primer_panel_resource.rb` - POST is broken as `snp_count` is a required attribute in the model but not included in the resource.
- [ ] `app/resources/api/v2/lot_resource.rb` - POST is broken as `received_at` is a required attribute in the model but not included in the resource.
- [ ] `app/resources/api/v2/qcable_resource.rb` - POST is broken as it requires a `qcable_creator` which is not defined in the resource.

## Test Coverage Improvements

- [ ] Finish tests for all v2 API `spec/requests/api/v2/`.
- [ ] Add POST request tests to all `spec/resources/api/v2/..` files.
- [ ] Add tests to check `tag_index` and `tag2_index` are not updatable in `spec/resources/api/v2/aliquot_resource_spec.rb`.
- [ ] Create `spec/resources/api/v2/asset_audits_resource_spec.rb`.
- [ ] Add more tests to `spec/requests/api/v2/aliquots_spec.rb`.
- [ ] Add relationships for `user` to `app/resources/api/v2/custom_metadatum_collection_resource.rb` (see `app/resources/api/v2/tube_from_tube_creation_resource.rb`).
- [ ] Add more tests to `spec/requests/api/v2/asset_audits_spec.rb`, specifically testing the new relationships alongside the use of their respective attributes (see `spec/requests/api/v2/tube_from_tube_creations_spec.rb`), and that PATCH requests are denied.

## API Improvements

- [ ] `app/resources/api/v2/qc_assay_resource.rb` - Check if the `qc_results` relationship is necessary. Currently `qc_results` are created as an attribute
- [ ] Can `app/resources/api/v2/asset_resource.rb` be removed? It seems the `Asset` model (`app/models/asset.rb`) has been deprecated.
- [ ] `app/resources/api/v2/qc_assay_resource.rb` - POST request breaks if Asset `barcode` or `uuid` is not provided in the `qc_results`, but neither are specified as an attribute in the resource.
- [ ] `app/resources/api/v2/qc_assay_resource.rb` returns a `201 Created` even when no record is created (when no `qc_result` objects are passed).
- [ ] `app/resources/api/v2/tube_purpose_resource.rb` does not error if `purpose_type` is anything other than `Tube::Purpose`, but the object isn't created.
- [ ] `app/resources/api/v2/qc_result_resource.rb` - POST request breaks if Asset `barcode` or `uuid` is not provided in the `qc_results`, but neither are specified as an attribute in the resource.
- [ ] `app/resources/api/v2/lot_resource.rb` - Add `received_at` attribute to resource.
- [ ] `app/resources/api/v2/pick_list_resource.rb` - `links` should be read-only.
- [ ] `app/resources/api/v2/pooled_plate_creation_resource.rb` - Deprecate `child_purpose_uuid` attribute in favor of the `child_purpose` relationship.
- [ ] Make `app/resources/api/v2/tube_rack_status_resource.rb` immutable?
- [ ] Deprecate `target_uuid` and add target relationship in a few resources.
- [ ] `config/routes.rb` - Update v2 resources exceptions to reflect resources (e.g., `, except: %i[update]` for `lot`), and more. Include all actions in the except block for immutable resources.
- [ ] `app/resources/api/v2/request_type_resource.rb` - Remove `write_once` on attributes as it is immutable.
- [ ] `app/resources/api/v2/specific_tube_creation_resource.rb` - Create `child_purposes` relationship or fix `children` relationship.
- [ ] `app/resources/api/v2/specific_tube_creation_resource.rb` - Update attributes/relationships to write-once.
- [ ] `app/resources/api/v2/volume_update_resource.rb` - Update routes file to disallow updates.
- [ ] `app/resources/api/v2/volume_update_resource.rb` - `created_by` can be any string, update to user relationship.
- [ ] Use `except: %i[update]` in `routes.rb` or the access restrictions in `app/resources/api/v2/base_resource.rb` for `app/resources/api/v2/asset_audit_resource.rb`, instead of declaring `self.updatable_fields(_context)`.
- [ ] Same as above for `app/resources/api/v2/comment_resource.rb`
- [ ] Remove `write_once: true` from any attributes and relationships where the resource is immutable (e.g., `app/resources/api/v2/tag_resource.rb`, `app/resources/api/v2/lot_type_resource.rb` and more)
- [ ] Where resources are immutable, add `readonly` to attributes.
- [ ] Deprecate attributes that are defined via a `uuid` AND have a respective relationship.
- [ ] `app/resources/api/v2/qc_result_resource.rb` - Other attributes can be sent in the request body as it does not throw an error.
- [ ] Can `app/resources/api/v2/fragment_resource.rb` be removed? There is no access to this resource.
- [ ] `app/resources/api/v2/qc_result_resource.rb` - The `asset` relationship appears to be redundant. See comment.
