class Api::AssetLinkIO < Api::Base
  renders_model(::AssetLink)

  map_attribute_to_json_attribute(:uuid)

  with_association(:ancestor) do 
    map_attribute_to_json_attribute(:uuid, 'ancestor_uuid')
    map_attribute_to_json_attribute(:id,   'ancestor_internal_id')

    extra_json_attributes do |object, json_attributes|
      json_attributes['ancestor_type'] = object.sti_type.tableize unless object.nil?
    end
  end

  with_association(:descendant) do 
    map_attribute_to_json_attribute(:uuid, 'descendant_uuid')
    map_attribute_to_json_attribute(:id,   'descendant_internal_id')

    extra_json_attributes do |object, json_attributes|
      json_attributes['descendant_type'] = object.sti_type.tableize unless object.nil?
    end
  end
end
