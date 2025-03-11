# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {RackedTube}.
    #
    # A Racked Tube represents a tube placed within a specific coordinate of a tube rack.
    # A RackedTube links a tube to a tube rack.
    # It includes associations to the related tube and tube rack as well as the coordinate
    # where the tube is placed.
    #
    # @note Access this resource via the `/api/v2/racked_tubes/` endpoint.
    #
    # @example GET request to retrieve all racked tubes
    #   GET /api/v2/racked_tubes/
    #
    # @example POST request to create a new racked tube
    #   POST /api/v2/racked_tubes/
    # {
    #   "data": {
    #     "type": "racked_tubes",
    #     "attributes": {
    #       "coordinate": "A2"
    #     },
    #     "relationships": {
    #       "tube": {
    #         "data": {
    #           "type": "tubes",
    #           "id": 14
    #         }
    #       },
    #       "tube_rack": {
    #         "data": {
    #           "type": "tube_racks",
    #           "id": 19
    #         }
    #       }
    #     }
    #   }
    # }
    #
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class RackedTubeResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] coordinate
      #   The coordinate within the tube rack where the tube is located (e.g., "A1").
      #   @note This attribute is write-once, it cannot be updated after creation.
      #   @return [String]
      attribute :coordinate, write_once: true

      ###
      # Relationships
      ###

      # @!attribute [rw] tube
      #   The tube associated with the racked tube.
      #   @return [TubeResource]
      has_one :tube

      # @!attribute [rw] tube_rack
      #   The rack that holds the tube.
      #   @return [TubeRackResource]
      has_one :tube_rack
    end
  end
end
