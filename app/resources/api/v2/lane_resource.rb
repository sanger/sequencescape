# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/lanes/` endpoint.
    #
    # Provides a JSON:API representation of {Lane}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class LaneResource < BaseResource
      # Constants...

      immutable

      # Associations:
      has_many :samples
      has_many :studies
      has_many :projects

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name
      # attribute :position
      # attribute :labware_barcode

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      # def labware_barcode
      #   {
      #     ean13_barcode: _model.labware.ean13_barcode,
      #     human_barcode: _model.labware.human_barcode
      #   }
      # end

      # Class method overrides
    end
  end
end
