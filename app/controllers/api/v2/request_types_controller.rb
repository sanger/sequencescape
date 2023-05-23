# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for request_type
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class RequestTypesController < JSONAPI::ResourceController
      include Api::V2::ApiKeyAuthenticatable

      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
    end
  end
end
