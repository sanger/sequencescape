class Api::TagInstanceIO < Api::Base
  renders_model(::TagInstance)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode)
  map_attribute_to_json_attribute(:two_dimensional_barcode)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  
  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end

  with_association(:tag) do
    map_attribute_to_json_attribute(:uuid  , 'tag_uuid')
    map_attribute_to_json_attribute(:id    , 'tag_internal_id')
    map_attribute_to_json_attribute(:oligo , 'tag_expected_sequence')
    map_attribute_to_json_attribute(:map_id, 'tag_map_id')

    with_association(:tag_group) do
      map_attribute_to_json_attribute(:name, 'tag_group_name')
      map_attribute_to_json_attribute(:uuid, 'tag_group_uuid')
      map_attribute_to_json_attribute(:id  , 'tag_group_internal_id')
    end
  end

  self.related_resources = [ :requests ]
end
