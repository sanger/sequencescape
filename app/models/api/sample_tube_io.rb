class Api::SampleTubeIO < Api::Base
  renders_model(::SampleTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode)
  map_attribute_to_json_attribute(:qc_state)
  map_attribute_to_json_attribute(:closed)
  map_attribute_to_json_attribute(:two_dimensional_barcode)
  map_attribute_to_json_attribute(:concentration)
  map_attribute_to_json_attribute(:volume)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  extra_json_attributes do |object, json_attributes|
    json_attributes["scanned_in_date"] = object.scanned_in_date if object.respond_to?(:scanned_in_date)
  end

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end

  with_association(:sample) do
    map_attribute_to_json_attribute(:uuid, 'sample_uuid')
    map_attribute_to_json_attribute(:id  , 'sample_internal_id')
    map_attribute_to_json_attribute(:name, 'sample_name')
  end

  self.related_resources = [ :library_tubes, :requests ]
end
