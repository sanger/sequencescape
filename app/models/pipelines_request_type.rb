# frozen_string_literal: true

# Links a {Pipeline} to the {RequestType request types} it can process
class PipelinesRequestType < ApplicationRecord
  belongs_to :pipeline, inverse_of: :pipelines_request_types
  belongs_to :request_type, inverse_of: :pipelines_request_types

  validates :request_type_id, uniqueness: { scope: :pipeline_id }
end
