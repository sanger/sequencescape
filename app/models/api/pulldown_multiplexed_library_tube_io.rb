class Api::PulldownMultiplexedLibraryTubeIO < Api::Base
  renders_model(::PulldownMultiplexedLibraryTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode)
  map_attribute_to_json_attribute(:concentration)
  map_attribute_to_json_attribute(:volume)
  map_attribute_to_json_attribute(:qc_state)
  map_attribute_to_json_attribute(:closed)
  map_attribute_to_json_attribute(:two_dimensional_barcode)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:public_name)

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end
  
  extra_json_attributes do |object, json_attributes|
    json_attributes["scanned_in_date"] = object.api_scanned_in_date if object.respond_to?(:api_scanned_in_date)
  end

end
