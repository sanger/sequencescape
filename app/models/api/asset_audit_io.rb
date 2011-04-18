class Api::AssetAuditIO < Api::Base
  renders_model(::AssetAudit)

  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:message)
  map_attribute_to_json_attribute(:key)
  map_attribute_to_json_attribute(:created_by)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:witnessed_by)

  with_association(:asset) do 
    map_attribute_to_json_attribute(:uuid, 'plate_uuid')
    map_attribute_to_json_attribute(:barcode, 'plate_barcode')
    
    with_association(:barcode_prefix) do
      map_attribute_to_json_attribute(:prefix, 'plate_barcode_prefix')
    end
  end
  
end
