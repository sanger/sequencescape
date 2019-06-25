# frozen_string_literal: true

# Used to broadcast stock tubes to the UWH.
# Wells have a separate template, as the information
# is mapped slightly differently.
class Api::Messages::ReceptacleStockResourceIO < Api::Base
  renders_model(::Well)

  map_attribute_to_json_attribute(:uuid, 'stock_resource_uuid')
  map_attribute_to_json_attribute(:id, 'stock_resource_id')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:subject_type, 'labware_type')

  with_association(:labware) do
    map_attribute_to_json_attribute(:ean13_barcode, 'machine_barcode')
    map_attribute_to_json_attribute(:human_barcode, 'human_barcode')
  end

  map_attribute_to_json_attribute(:map_description, 'labware_coordinate')

  with_nested_has_many_association(:aliquots, as: 'samples') do
    with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
    with_association(:study)  { map_attribute_to_json_attribute(:uuid, 'study_uuid') }
  end
end
