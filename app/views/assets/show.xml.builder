xml.instruct!
xml.asset(api_data) {
  xml.id @asset.id
  xml.type @asset.sti_type
  xml.name @asset.name
  xml.public_name @asset.public_name
  xml.sample_id @asset.material_id
  xml.qc_state @asset.qc_state
  xml.children {
    @asset.children.each do |child_asset|
      xml.id child_asset.id
    end
  }
  xml.parents {
    @asset.parents.each do |parent_asset|
      xml.id parent_asset.id
    end
  }
  unless @exclude_nested_resource
    xml.requests {
      @asset.requests.each do |asset_request|
        xml.request {
          xml.id asset_request.id
          xml.properties {
            asset_request.request_metadata.attribute_value_pairs.each do |attribute, value|
              xml.property {
                xml.key   attribute.name.to_s
                xml.name  attribute.to_field_info.display_name
                xml.value value
              }
            end
          }
        }
      end
    }
  else # just send the ids
    xml.request_ids {
      @asset.request_ids.each do |request_id|
        xml.id  request_id
      end
    }
  end
}
