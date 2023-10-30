# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of request
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class RequestsAsTargetResource < BaseResource
      model_name 'Request'
    end
  end
end
