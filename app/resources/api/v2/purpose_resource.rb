# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Purpose}.
    #
    # A Purpose defines the intended function of a labware or sample within the system.
    # While it was historically limited to PlatePurpose, it now applies to other labware like Tubes.
    #
    # @note Access this resource via the `/api/v2/purposes/` endpoint.
    #
    # @example Fetching all purposes
    #   GET /api/v2/purposes
    #
    # @example Fetching a purpose by ID
    #   GET /api/v2/purposes/{id}
    #
    # @note the below example is currently broken, as `target_type` is a required attribute in the
    #   model and `lifespan` is not.
    #
    # @example Creating a new purpose
    #   POST /api/v2/purposes
    #   {
    #     "data": {
    #         "type": "purposes",
    #         "attributes": {
    #            "name": "ExamplePurpose",
    #            "size": 96,
    #            "lifespan": 1
    #         }
    #     }
    # }
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class PurposeResource < BaseResource
      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The universally unique identifier (UUID) of purpose.
      attribute :uuid, readonly: true

      # @!attribute [rw] name
      #   The name of the purpose.
      #   @return [String]
      attribute :name, write_once: true

      # @!attribute [rw] size
      #   The expected size of the purpose.
      #   @return [Integer]
      attribute :size, write_once: true

      # @!attribute [rw] lifespan
      #   The expected lifespan of the purpose.
      #   @return [Integer]
      attribute :lifespan, write_once: true

      ###
      # Filters
      ###

      # @!method filter_by_name
      #   Allows filtering projects by name.
      #   @example Fetching a purpose by name
      #     GET /api/v2/purposes?filter[name]=ExamplePurpose
      filter :name
    end
  end
end
