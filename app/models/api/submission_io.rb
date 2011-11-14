class Api::SubmissionIO < Api::Base
  renders_model(::Submission)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:message)
  
  with_association(:user) do 
    map_attribute_to_json_attribute(:login  , 'created_by')
  end

  self.related_resources = [:orders]

end
