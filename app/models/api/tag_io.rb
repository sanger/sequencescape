class Api::TagIO < Api::Base
  renders_model(::Tag)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:oligo, 'expected_sequence')
  map_attribute_to_json_attribute(:map_id)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:tag_group) do
    map_attribute_to_json_attribute(:name, 'tag_group_name')
    map_attribute_to_json_attribute(:uuid, 'tag_group_uuid')
    map_attribute_to_json_attribute(:id  , 'tag_group_internal_id')
  end
end
