# frozen_string_literal: true

module Api
  module V2
    # Class required by json-api-resources gem to be able to read the information of
    # a sample
    class ComponentSampleResource < BaseResource
      model_name 'Sample'
    end
  end
end
