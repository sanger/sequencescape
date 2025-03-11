# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of a {Tube}.
    #
    # A Tube is a piece of {Labware}, which is a container that can hold samples,
    # aliquots, or other entities in a laboratory setting.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/tubes/` endpoint.
    #
    # @example GET request for all Tube resources
    #   GET /api/v2/tubes/
    #
    # @example GET request for a Tube with ID 123
    #   GET /api/v2/tubes/123/
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
      #   An array of hashes containing metadata for sibling tubes.
      #   Sibling tubes are tubes that share a common ancestor, often used in a grouping of tubes.
      #   @return [Array<Hash>] The metadata of sibling tubes.
      #   @note This attribute is read-only and may not be present for all tubes, as it depends on
      #     the context (e.g., tubes that are part of a group or series).
      #   @see #sibling_tubes
      attribute :sibling_tubes, readonly: true

      def sibling_tubes
        @model.try(:sibling_tubes) # Not all tubes/purposes implement sibling_tubes
      end

      ###
      # Relationships
      ###

      # @!attribute [r] aliquots
      #   The aliquots contained within this tube. An aliquot is a portion of the contents
      #   from a larger sample, typically for further analysis or experimentation.
      #   @return [Array<Api::V2::AliquotResource>] An array of aliquots associated with this tube.
      #   @note This relationship is read-only and represents the aliquots that are physically stored within the tube.
      has_many :aliquots, readonly: true

      # @!attribute [r] receptacle
      #   The receptacle associated with aliquots contained by this tube. A receptacle can refer to a container that
      #   holds multiple aliquots.
      #   @return [Api::V2::ReceptacleResource] The receptacle that holds aliquots for this tube.
      #   @note This relationship is read-only and is primarily used for retrieving information about the receptacle,
      #   not for modifying it.
      has_one :receptacle, readonly: true, foreign_key_on: :related

      # @!attribute [r] transfer_requests_as_target
      #   The transfer requests that target this tube. A transfer request represents an instruction to move aliquots or
      #    samples into the tube.
      #   @return [Array<Api::V2::TransferRequestResource>] An array of transfer requests associated with this tube.
      #   @note This relationship is read-only and provides insights into the transfer requests targeting this tube.
      has_many :transfer_requests_as_target, readonly: true
    end
  end
end
