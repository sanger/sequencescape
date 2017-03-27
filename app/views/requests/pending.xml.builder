def output_items(request, r)
  request.items do |items|
    [r.item].each do |i|
      items.item do |item|
        output_item(item, i, r)
      end
    end
  end
end

def output_sample_pool(request, r)
  if r.item.workflow_sample && r.item.workflow_sample.samples.size > 1
    request.sample_pool do |sample_pool|
      sample_pool.id r.item.workflow_sample.id
      sample_pool.descriptors do |descriptors|
        descriptors.descriptor do |descriptor|
          descriptor.name 'Tag'
          p = r.property('tag')
          if p
            descriptor.value p.value
          else
            descriptor.value ''
          end
        end
      end
    end
  end
end

def output_item(item, i, r)
  item.id i.id
  item.name i.name
  item.count i.count
  item.study_id r.study.id
  item.study_name r.study.name
  item.descriptors do |descriptors|
    # No properties on item!
  end
  output_sample_or_pool(item, i)
end

def output_sample_or_pool(item, i)
  if i.workflow_sample
    if i.workflow_sample.samples.size == 1
      output_sample(item, i)
    else
      output_pool(item, i)
    end
  end
end

def output_sample(item, i)
  item.sample do |sample|
    sample.id i.workflow_sample.id
    sample.name i.workflow_sample.name
    sample.descriptors do |descriptors|
      i.workflow_sample.sample_metadata.attribute_value_pairs.each do |attribute, name|
        descriptors.descriptor do |descriptor|
          descriptor.name  attribute.to_field_info.display_name
          descriptor.key   attribute.name.to_s
          descriptor.value value
        end
      end
    end
    unless i.workflow_sample.samples.empty?
      sample.descriptors do |descriptors|
        i.workflow_sample.samples.first.sample_metadata.attribute_value_pairs.each do |attribute, name|
          descriptors.descriptor do |descriptor|
            descriptor.name  attribute.to_field_info.display_name
            descriptor.key   attribute.name.to_s
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
    pool.descriptors do |descriptors|
      i.workflow_sample.sample_metadata.attribute_value_pairs.each do |attribute, name|
        descriptors.descriptor do |descriptor|
          descriptor.name  attribute.to_field_info.display_name
          descriptor.value value
        end
      end
    end
  end
end

# This is based on the submission ID
def group_id(request)
  request.item.workflow_sample.submission.id
rescue
  nil
end

xml.instruct!
xml.requests({api_version: '0.1'}) do |requests|
  @requests.each do |r|
    requests.request do |request|
      request.id r.id
      request.attempt r.attempts.size
      request.created_at r.created_at
      request.updated_at r.updated_at
      request.study_id r.study.id
      request.study_name r.study.name
      request.group_id group_id(r)
      request.read_length r.request_metadata.read_length
      output_items(request, r)
    end
  end
end
