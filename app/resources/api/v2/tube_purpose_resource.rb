# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Tube::Purpose}.
    #
    # A {Tube::Purpose} is a base class for the all tube purposes, which describes the role the associated
    # {Tube} is playing within the lab, and modifies its behaviour.
    #
    # This resource allows for the management and retrieval of tube purposes.
    #
    # @note Access this resource via the `/api/v2/tube_purposes/` endpoint.
    #
    # @example GET request for all TubePurpose resources
    #   GET /api/v2/tube_purposes/
    #
    # @example GET request for a TubePurpose with ID 123
    #   GET /api/v2/tube_purposes/123/
    #
    # @todo The below POST request does not error if `purpose_type` is anything other than `Tube::Purpose`,
    #   but the object isn't created.
    #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
    #
    # @example POST request to create a new TubePurpose
    #   POST /api/v2/tube_purposes/
    #   {
    #     "data": {
    #       "type": "tube_purposes",
    #       "attributes": {
    #         "name": "9DNA Extraction",
    #         "purpose_type": "Tube::Purpose",
    #         "target_type": "StockLibraryTube"
    #       }
    #     }
    #   }
    #
    # @example PATCH request to update a TubePurpose with ID 123
    #   PATCH /api/v2/tube_purposes/123/
    #   {
    #     "data": {
    #       "id": 123,
    #       "type": "tube_purposes",
    #       "attributes": {
    #         "name": "DNA Extraction 123",
    #         "purpose_type": "Tube::Purpose",
    #         "target_type": "StockLibraryTube"
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubePurposeResource < BaseResource
      model_name 'Tube::Purpose'

      ###
      # Attributes
      ###

      # @!attribute [rw] name
      #   @return [String] The name of the tube purpose, describing the intended use of the tube.
      #   @note This attribute is required.
      attribute :name

      # @!attribute [rw] purpose_type
      #   @return [String] The purpose type (e.g., "Tube::Purpose").
      #   This is mapped to the `type` attribute on the model.
      attribute :purpose_type, delegate: :type

      # @!attribute [rw] target_type
      #   @return [String] The target type, indicating what type of tube the purpose is associated
      #     with (e.g., 'StockLibraryTube').
      #   @note This attribute is required.
      attribute :target_type

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the tube purpose.
      attribute :uuid, readonly: true

      ###
      # Filters
      ###

      # @!method filter_type
      #   Filter tube purposes by type.
      #   @example GET request with type filter
      #     GET /api/v2/tube_purposes?filter[type]=Extraction
      filter :type, default: 'Tube::Purpose'
    end
  end
end
