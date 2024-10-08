# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Order}
# Historically used to be v0.5 API
class Api::OrderIo < Api::Base
  renders_model(::Order)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:template_name)
  map_attribute_to_json_attribute(:comments)

  with_association(:project) do
    map_attribute_to_json_attribute(:uuid, 'project_uuid')
    map_attribute_to_json_attribute(:id, 'project_internal_id')
    map_attribute_to_json_attribute(:name, 'project_name')
  end

  with_association(:study) do
    map_attribute_to_json_attribute(:uuid, 'study_uuid')
    map_attribute_to_json_attribute(:id, 'study_internal_id')
    map_attribute_to_json_attribute(:name, 'study_name')
  end

  with_association(:submission) do
    map_attribute_to_json_attribute(:uuid, 'submission_uuid')
    map_attribute_to_json_attribute(:id, 'submission_internal_id')
  end

  with_association(:user) { map_attribute_to_json_attribute(:login, 'created_by') }

  extra_json_attributes do |object, json_attributes|
    json_attributes['request_options'] = object.request_options_structured if object.request_options_structured.present?
  end
end
