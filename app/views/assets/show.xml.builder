xml.instruct!
xml.asset(api_data) {
  xml.comment! <<~COMMENT
    WARNING: This endpoint is maintained to allow legacy systems to transition away from it.
    Asset has been deprecated. This page shows the receptacle #{@asset.id}.
  COMMENT
  xml.id          @asset.id
  xml.type        @asset.legacy_asset_type
  xml.name        @asset.name
  xml.public_name @asset.public_name
  xml.qc_state    @asset.qc_state

  # A receptacle will have zero or more aliquots.  To support the legacy version of this XML we're displaying
  # the primary aliquot sample ID as sample_id in the XML, although it is not strictly true.  When the asset
  # is not a receptacle we simply output sample_id as nil, although it should not really be present at all.
  if @asset.is_a?(Receptacle)
    xml.sample_id(@asset.primary_aliquot.try(:sample_id)) unless @asset.aliquots.size > 1
    @asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
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
  if @exclude_nested_resource # just send the ids
    xml.request_ids {
      @asset.request_ids.each do |request_id|
        xml.id request_id
      end
    }
  else
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
  end
}
