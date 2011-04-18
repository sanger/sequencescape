require 'rexml/text'
xml.instruct!
xml.sample(api_data) {
  xml.id @sample.id
  xml.name @sample.name
  xml.study_id @sample.studies.first.id unless @sample.studies.empty?
  # Descriptors

  xml.properties {
    @sample.sample_metadata.attribute_value_pairs.each do |attribute,value|
    #puts attribute.name.to_s
      xml.property {
        # NOTE: The display text is targeted at HTML, so contains escaped entities, which we must unescape for XML.
        xml.name(REXML::Text.unnormalize(attribute.to_field_info.display_name))
        xml.value(value)
      }
    end
    @sample.sample_metadata.association_value_pairs.each do |attribute,value|
      xml.property {
        # NOTE: The display text is targeted at HTML, so contains escaped entities, which we must unescape for XML.
        xml.name(REXML::Text.unnormalize(attribute.to_field_info.display_name))
        if (attribute.to_field_info.display_name == "Reference Genome") && (value.blank?)
          xml.value(nil)
        else 
          xml.value(value)
        end
      }
    end
  }

  unless @sample.assets.empty?
    xml.assets {
      @sample.assets.each do |asset|
        xml.asset(:id => asset.id, :href => asset_path(asset))
      end
    }
  end
  if @sample.studies.size > 0
    xml.study_id @sample.studies.first.id
  end
}
