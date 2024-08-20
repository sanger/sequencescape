# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/tubes/` endpoint.
    #
    # Provides a JSON:API representation of {Tube}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubeResource < BaseResource
      include Api::V2::SharedBehaviour::Labware

      # Constants...

      immutable

      default_includes :uuid_object, :barcodes, :transfer_requests_as_target

      # Associations:
      has_many :aliquots, readonly: true
      has_many :transfer_requests_as_target, readonly: true
      has_one :receptacle, readonly: true, foreign_key_on: :related

      # Attributes

      # Filters

      # Class method overrides
    end
  end
end
