# frozen_string_literal: true
xml.instruct!
if @exclude_nested_resource
  xml.samples({ type: 'array' }) { |samples| Sample.find_each { |p| samples.study { |sample| sample.id p.id } } }
else
  # Depricated interface
  xml.samples(api_data) do |samples|
    if @samples.empty?
      xml.comment!(
        'There were no results returned. You might want to check your parameters if you expected any results.'
      )
    else
      @samples.each do |ws|
        samples.workflow_sample do |workflow_sample|
          workflow_sample.id ws.id
          workflow_sample.descriptors do |descriptors|
            ws.sample_metadata.attribute_value_pairs.each do |attribute, value|
              descriptors.descriptor do |descriptor|
                xml.comment! attribute.to_field_info.display_name
                descriptor.key attribute.name.to_s
                descriptor.value value
              end
            end
          end
        end
      end
    end
  end
end
