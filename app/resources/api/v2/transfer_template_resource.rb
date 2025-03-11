# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TransferTemplate}.
    #
    # A template is effectively a partially constructed Transfer instance, containing only the
    # transfers that should be made and the final Transfer class that should be constructed.
    #
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/transfer_templates/` endpoint.
    #
    # @example GET request for all TransferTemplate resources
    #   GET /api/v2/transfer_templates/
    #
    # @example GET request for a TransferTemplate with ID 123
    #   GET /api/v2/transfer_templates/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TransferTemplateResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   The name of the transfer template.
      #   @return [String] the name of the transfer template.
      #   @note This attribute is read-only and cannot be modified.
      attribute :name

      # @!attribute [r] uuid
      #   The UUID of the transfer template.
      #   @return [String] the UUID of the transfer template.
      #   @note This attribute is read-only and cannot be modified.
      attribute :uuid, readonly: true

      ###
      # Filters
      ###

      # @!method filter_uuid
      #   Filter the transfer templates by UUID.
      #   @example GET request with UUID filter
      #     GET /api/v2/transfer_templates?filter[uuid]=12345678-1234-1234-1234-123456789012
      #   @return [ActiveRecord::Relation] The filtered transfer templates.
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
