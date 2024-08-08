# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/users/` endpoint.
    #
    # Provides a JSON:API representation of {User}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class UserResource < BaseResource
      # Constants...

      immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Attributes
      attribute :uuid, readonly: true
      attribute :login, readonly: true
      attribute :first_name, readonly: true
      attribute :last_name, readonly: true

      # Filters
      filter :user_code, apply: lambda { |records, value, _options| records.with_user_code(*value) }
    end
  end
end
