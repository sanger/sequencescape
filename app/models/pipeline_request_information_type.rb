class PipelineRequestInformationType < ActiveRecord::Base
  belongs_to :pipeline
  belongs_to :request_information_type
end
