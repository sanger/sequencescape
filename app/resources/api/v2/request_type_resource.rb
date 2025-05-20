# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {RequestType}.
    #
    # RequestTypes are used by {Order orders} to construct {Request requests}.
    # The request type identifies the type of Request and associates it with a particular {Pipeline}.
    # Request types have associated {RequestType::Validator validators} to ensure compatible {Request::Metadata}.
    # Request types also associate the request with a particular {ProductLine} team.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/request_types/` endpoint.
    #
    # @example GET request to retrieve all request types
    #   GET /api/v2/request_types/
    #
    # @example GET request to retrieve a specific request type by ID
    #   GET /api/v2/request_types/{id}/
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class RequestTypeResource < BaseResource
      immutable

      default_includes :uuid_object

      has_many :requests

      # @!attribute [r] uuid
      #   @return [String] The unique identifier of the request type.
      #   @note This field is readonly as this resource is immutable.
      # Associations:
      attribute :uuid, readonly: true

      # @!attribute [rw] name
      #   @return [String] The name of the request type.
      #   @note This field is readonly as this resource is immutable.
      #   @todo Update `write_once` to `readonly`, as resource is immutable
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      attribute :name, write_once: true

      # @!attribute [rw] key
      #   @return [String] A unique key for the request type.
      #   @note This field is readonly as this resource is immutable.
      #   @todo Update `write_once` to `readonly`, as resource is immutable
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      attribute :key, write_once: true

      # @!attribute [rw] for_multiplexing
      #   @return [Boolean] Whether the request type supports multiplexing.
      #   @note This field is readonly as this resource is immutable.
      #   @todo Update `write_once` to `readonly`, as resource is immutable
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      attribute :for_multiplexing, write_once: true
    end
  end
end
