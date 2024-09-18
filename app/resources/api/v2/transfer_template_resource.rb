# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/transfer_templates/` endpoint.
    #
    # Provides a JSON:API representation of {TransferTemplate}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TransferTemplateResource < BaseResource
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   @return [String] the name of the transfer template.
      attribute :name

      # @!attribute [r] uuid
      #   @return [String] the UUID of the transfer template.
      attribute :uuid, readonly: true

      # @!method filter_uuid
      #   Filter the transfer templates by UUID.
      #   @example GET request with UUID filter
      #     GET /api/v2/transfer_templates?filter[uuid]=12345678-1234-1234-1234-123456789012
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
