# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for user
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class UsersController < JSONAPI::ResourceController
      include Api::V2::ApiKeyAuthenticatable
      prepend_before_action :authenticate_with_api_key

      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
    end
  end
end
