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

      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] sibling_tubes
      #   @return [Array<Hash>] An array of hashes containing the metadata for sibling tubes.
      attribute :sibling_tubes, readonly: true

      def sibling_tubes
        @model.try(:sibling_tubes) # Not all tubes/purposes implement sibling_tubes
      end

      ###
      # Relationships
      ###

      # @!attribute [r] aliquots
      #   @return [Array<Api::V2::AliquotResource>] An array of aliquots contained by this tube.
      has_many :aliquots, readonly: true

      # @!attribute [r] receptacle
      #   @return [Api::V2::ReceptacleResource] The receptacle of aliquots associated with this tube.
      has_one :receptacle, readonly: true, foreign_key_on: :related

      # @!attribute [r] transfer_requests_as_target
      #   @return [Array<Api::V2::TransferRequestResource>] An array of transfer requests into this tube.
      has_many :transfer_requests_as_target, readonly: true
    end
  end
end
