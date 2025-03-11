# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PlatePurpose}.

    # The standard {Purpose} class for plates. Plate purposes categorize plates based
    # on their intended function within the pipeline.
    #
    # This resource is primarily used by Limber, which registers plate purposes via the API.
    #
    # @note Access this resource via the `/api/v2/plate_purposes/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example GET request for all plate purposes
    #   GET /api/v2/plate_purposes/
    #
    # @example GET request for a specific plate purpose by ID
    #   GET /api/v2/plate_purposes/123/
    #
    # @example POST request to create a new plate purpose
    #   POST /api/v2/plate_purposes/
    #   {
    #     "data": {
    #         "type": "plate_purposes",
    #         "attributes": {
    #               "name": "API v2 Generated Plate Purpose6",
    #               "stock_plate": true,
    #               "cherrypickable_target": false,
    #               "size": 384,
    #               "asset_shape": "Standard",
    #               "input_plate": false
    #         }
    #     }
    # }
    #
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package, which powers Sequencescape's
    #   JSON:API implementation.
    class PlatePurposeResource < BaseResource
      model_name 'PlatePurpose'

      ###
      # Attributes
      ###

      # @!attribute [rw] name
      #   The name of the plate purpose.
      #   @note This attribute is required and must be unique.
      #   @return [String]
      attribute :name

      # @!attribute [rw] stock_plate
      #   Indicates whether plates of this purpose are stock plates.
      #   Stock plates serve as source plates for further processing.
      #   @return [Boolean]
      attribute :stock_plate

      # @!attribute [rw] cherrypickable_target
      #   Inurpose are dicates whether plates of this peligible for cherry-picking.
      #   Cherry-picking involves selecting specific wells or samples from a plate for further analysis.
      #   @return [Boolean]
      attribute :cherrypickable_target

      # @!attribute [rw] input_plate
      #   Indicates whether plates of this purpose serve as input plates.
      #   Input plates are used as starting points in pipelines.
      #   @return [Boolean]
      attribute :input_plate

      # @!attribute [rw] size
      #   The number of wells in plates of this purpose.
      #   Common sizes include 96 and 384 wells.
      #   @return [Integer]
      attribute :size

      # @!attribute [rw] asset_shape
      #   The shape of plates of this purpose.
      #   This value determines the physical layout and well arrangement of the plates.
      #   If not provided, it defaults to "Standard".
      #   @return [String]
      attribute :asset_shape

      # @!attribute [r] uuid
      #   A unique identifier for the plate purpose.
      #   This is automatically assigned upon creation and cannot be modified.
      #   @return [String]
      attribute :uuid, readonly: true

      ###
      # Getters and Setters
      ###

      # Sets the asset shape of the plate purpose by name.
      # If the provided name does not exist, an error is raised.
      # This method allows assigning a named asset shape while ensuring it exists in the system.
      #
      # @param name [String] The name of the asset shape.
      # @raise [ActiveRecord::RecordNotFound] if the asset shape is not found.
      # @return [void]
      def asset_shape=(name)
        @model.asset_shape = (AssetShape.find_by!(name:) if name.present?) || AssetShape.default
      end

      # Retrieves the name of the asset shape associated with the plate purpose.
      #
      # @return [String] The name of the asset shape.
      def asset_shape
        @model.asset_shape.name
      end

      # Sets the input plate type.
      # If set to `true`, the plate purpose will be categorized as `PlatePurpose::Input`.
      # This method ensures proper classification of input plates.
      #
      # @param is_input [Boolean] Whether to set the plate purpose as an input plate.
      # @return [void]
      def input_plate=(is_input)
        @model.input_plate = is_input
      end

      # Determines whether the plate purpose is categorized as an input plate.
      #
      # @return [Boolean] `true` if the plate purpose is an input plate, otherwise `false`.
      def input_plate
        @model.type == 'PlatePurpose::Input'
      end
    end
  end
end
