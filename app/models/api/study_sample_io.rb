class Api::StudySampleIO < Api::Base
  renders_model(::StudySample)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)

  with_association(:sample) do
    map_attribute_to_json_attribute(:id  , 'sample_internal_id')
    map_attribute_to_json_attribute(:uuid, 'sample_uuid')
  end

  with_association(:study) do
    map_attribute_to_json_attribute(:id  , 'study_internal_id')
    map_attribute_to_json_attribute(:uuid, 'study_uuid')
  end

  self.related_resources = [ :samples, :studies ]
end
