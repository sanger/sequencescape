xml.instruct!
xml.asset(api_data) {
  xml.id          @asset.id
  xml.type        @asset.sti_type
  xml.name        @asset.name
  xml.public_name @asset.public_name
  xml.qc_state    @asset.qc_state

  # A receptacle will have zero or more aliquots.  To support the legacy version of this XML we're displaying
  # the primary aliquot sample ID as sample_id in the XML, although it is not strictly true.  When the asset
  # is not a receptacle we simply output sample_id as nil, although it should not really be present at all.
  if @assets.is_a?(Aliquot::Receptacle)
    xml.sample_id @asset.primary_aliquot.try(:sample_id)
    xml.aliquots {
      @asset.aliquots.each do |aliquot|
        xml.sample_id aliquot.sample_id
        xml.tag_id    aliquot.tag_id
      end
    }
  else
    xml.sample_id nil
  end

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
