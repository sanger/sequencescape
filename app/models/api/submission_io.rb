# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Submission}
# Historically used to be v0.5 API
class Api::SubmissionIO < Api::Base
  renders_model(::Submission)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:message)

  with_association(:user) { map_attribute_to_json_attribute(:login, 'created_by') }
end
