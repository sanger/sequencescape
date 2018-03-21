require 'rexml/text'
xml.instruct!
xml.sample(api_data) {
  xml.id @sample.id
  xml.name @sample.name
  # We're experiencing some significant performance issues with this page
  # which currently accounts for 96% of ALL our traffic. This is ultra
  # optimized. Really though this is a bit misleading as samples can belong to
  # multiple studies.
  study_id = @sample.studies.limit(1).pluck(:id).first
  xml.study_id study_id if study_id
  xml.consent_withdrawn @sample.consent_withdrawn?
  # Descriptors

  xml.properties {
    @sample.sample_metadata.attribute_value_pairs.each do |attribute, value|
      # puts attribute.name.to_s
      xml.property {
        # NOTE: The display text is targeted at HTML, so contains escaped entities, which we must unescape for XML.
        xml.name(REXML::Text.unnormalize(attribute.to_field_info.display_name))
        xml.value(value)
      }
    end
    @sample.sample_metadata.association_value_pairs.each do |attribute, value|
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

  if study_id # Not sure why this appears twice.
    xml.study_id study_id
  end
}
