# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/request_types/` endpoint.
    #
    # Provides a JSON:API representation of {RequestType}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class RequestTypeResource < BaseResource
      # Constants...

      immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_many :requests

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, readonly: true
      attribute :key, readonly: true
      attribute :for_multiplexing, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
