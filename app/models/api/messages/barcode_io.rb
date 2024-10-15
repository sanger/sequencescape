# frozen_string_literal: true
# Generates messages for the barcode warehouse summarising barcodes
class Api::Messages::BarcodeIo < Api::Base
  renders_model(::Barcode)

  with_association(:asset) do
    map_attribute_to_json_attribute(:uuid, 'barcodable_uuid')
    map_attribute_to_json_attribute(:sti_type, 'barcodable_type')
  end

  map_attribute_to_json_attribute(:machine_barcode, 'machine_readable_barcode')
  map_attribute_to_json_attribute(:human_barcode, 'human_readable_barcode')
  map_attribute_to_json_attribute(:handler_class_name, 'barcode_type')
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:created_at)
end
