# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for submission
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class SubmissionsController < JSONAPI::ResourceController
      include Api::V2::ApiKeyAuthenticatable

      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.

      # JSONAPI-Resource doesn't currently allow for non-default fields
      # See https://github.com/cerebris/jsonapi-resources/issues/855
      # This is a temporary override, although probably won't help if submission
      # is included in a different resource
      def params
        default = super
        return default if default.dig('fields', 'submissions')

        default['fields'] ||= {}
        default['fields']['submissions'] = 'uuid,name,state,created_at,updated_at'
        default
      end
    end
  end
end
