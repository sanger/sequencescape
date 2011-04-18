def output_sample(item, i)
  item.sample do |sample|
    sample.id i.workflow_sample.id
    sample.name i.workflow_sample.name
    sample.descriptors do |descriptors|
      i.workflow_sample.sample_metadata.attribute_value_pairs.each do |attribute, value|
        descriptors.descriptor do |descriptor|
          descriptor.name  attribute.name.to_s
          descriptor.key   attribute.to_field_info.display_name
          descriptor.value value
        end
      end
    end
    unless i.workflow_sample.samples.empty?
      sample.descriptors do |descriptors|
        i.workflow_sample.samples.first.sample_metadata.attribute_value_pairs.each do |attribute, value|
          descriptors.descriptor do |descriptor|
            descriptor.name  attribute.name.to_s
            descriptor.key   attribute.to_field_info.display_name
            descriptor.value value
          end
        end
      end
    end
  end
end

def output_pool(item, i)
  item.pool do |pool|
    pool.id i.id
    pool.name i.name
    unless i.workflow_sample.sample_workflow_samples.empty?
      pool.sample_pools do |sample_pools|
        sample_pools.sample_pool do |sample_pool|
          sample_pool.id @request.item.id
          sample_pool.descriptors do |descriptors|
            @request.request_metadata.attribute_value_pairs.each do |attribute,value|
              descriptors.descriptor do |descriptor|
                descriptor.name  attribute.to_field_info.display_name
                descriptor.value value
              end
            end
          end
        end
      end
    end
  end
end

xml.instruct!
xml.comment!("/requests/expanded has been deprecated and will be removed in Sequencescape 3.1")
xml.request(api_data) do |request|
	request.id @request.id
	request.created_at @request.created_at
	request.updated_at @request.updated_at
	request.study_id @request.study.id
	request.study_name @request.study.name
	request.state      @request.state
	request.sample_name @request.sample_name
	request.descriptors do |descriptors|
  end
  request.read_length @request.request_metadata.read_length
	request.internal_pipeline_id @request.previous_pipeline_id
	request.items do |items|
	  [@request.item].each do |i|
	    items.item do |item|
	      item.id i.id
	      item.name i.name
	      item.count i.count
	      item.study_id @request.study.id
	      item.study_name @request.study.name
	      output_sample(item, i)
	    end
	  end
	end
end
