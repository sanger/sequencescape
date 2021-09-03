# frozen_string_literal: true
class PipelineRequestInformationType < ApplicationRecord
  belongs_to :pipeline
  belongs_to :request_information_type
end
