# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Receptacle}.
    #
    # A receptacle is a container for {Aliquot aliquots}, they are associated with
    # {Labware}, which represents the physical object which moves round the lab.
    # A {Labware} may have a single {Receptacle}, such as in the case of a {Tube}
    # or multiple, in the case of a {Plate}.
    # Work can be {Request requested} on a particular receptacle.
    #
    # This resource includes common behavior shared across various receptacles.
    # This behavior is imported from the `Api::V2::SharedBehaviour::Receptacle` module.
    #
    # @note Access this resource via the `/api/v2/receptacles/` endpoint.
    #
    # @example GET request to retrieve all receptacles
    #   GET /api/v2/receptacles/
    #
    # @example GET request to retrieve receptacles with a specific UUID
    #   GET /api/v2/receptacles?filter[uuid]=abc123
    #
    # @example GET request to retrieve samples associated with a specific receptacle
    #   GET /api/v2/receptacles/1/samples
    #
    # @todo The below POST is currently broken, as `display_name` is a required attribute in the
    #   model but it is not included in the resource.
    #
    # @example POST request to create a new receptacle
    #   POST /api/v2/receptacles/
    #   {
    #     "data": {
    #       "type": "receptacles",
    #       "attributes": {
    #         "name": "Tube Rack 1",
    #         "pcr_cycles": 25,
    #         "submit_for_sequencing": true
    #         // "display_name": "2"
    #       },
    #       "relationships": {
    #         "labware": {
    #           "data": {
    #             "type": "labware",
    #             "id": 1
    #           }
    #         }
    #       }
    #     }
    #   }
    #
    # @example PATCH request to update an existing receptacle
    #   PATCH /api/v2/receptacles/1
    #   {
    #     "data": {
    #       "id": 1,
    #       "type": "receptacles",
    #       "attributes": {
    #         "pcr_cycles": 26,
    #       },
    #     }
    #   }
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class ReceptacleResource < BaseResource
      # The Receptacle resource includes shared behaviors such as attributes, relationships, and filters
      # from the `Api::V2::SharedBehaviour::Receptacle` module.
      include Api::V2::SharedBehaviour::Receptacle

      default_includes :uuid_object
    end
  end
end
