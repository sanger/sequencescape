class RequestInformationType < ActiveRecord::Base
  has_many :pipeline_request_information_types
  has_many :pipelines, :through => :pipeline_request_information_types
end
