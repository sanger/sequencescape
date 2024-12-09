# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/plate_purposes/` endpoint.
    #
    # Provides a JSON:API representation of {PlatePurpose}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PlatePurposeResource < BaseResource
      model_name 'PlatePurpose'

      # This resource is similar to PurposeResource but it was created to
      # migrate the registration of plate purposes done by the Limber rake
      # task config:generate from API version 1 to API version 2.

      # The following attributes are sent by Limber for a new plate purpose.

      # @!attribute [rw] name
      #   @return [String] the name of the plate purpose.
      attribute :name

      # @!attribute [rw] stock_plate
      #   @return [Boolean] whether the plates of this purpose are stock plates.
      attribute :stock_plate

      # @!attribute [rw] cherrypickable_target
      #   @return [Boolean] whether the plates of this purpose are cherrypickable.
      attribute :cherrypickable_target

      # @!attribute [rw] input_plate
      #   @return [Boolean] whether the plates of this purpose are input plates.
      attribute :input_plate

      # @!attribute [rw] size
      #   @return [Integer] the size of the plates of this purpose.
      attribute :size

      # @!attribute [rw] asset_shape
      #   @return [String] the name of the shape of the plates of this purpose.
      attribute :asset_shape

      # The following attribute is required by Limber to store purposes.

      # @!attribute [r] uuid
      #   @return [String] the UUID of the plate purpose.
      attribute :uuid, readonly: true

      # Sets the asset shape of the plate purpose by name if given.
      # 'asset_shape' can be given via the Limber purpose configuration and
      # defaults to 'Standard' if not provided. If the name is given and not
      # found, an error is raised. Note that the name is case-sensitive.
      #
      # @param name [String] the name of the asset shape
      # @return [void]
      def asset_shape=(name)
        @model.asset_shape = (AssetShape.find_by!(name:) if name.present?) || AssetShape.default
      end

      # Returns the name of the asset shape of the plate purpose.
      # The asset_shape association is not utilized in Limber. This method
      # returns the name of the asset shape associated with the plate purpose.
      #
      # @return [String] the name of the asset shape
      def asset_shape
        @model.asset_shape.name
      end

      # Set the class to PlatePurpose::Input if set to true.
      # Pass through to the setter in the model.
      # While not strictly necessary as the model would respond implicitly, this method is provided for clarity.
      #
      # @param is_input [Bool] whether to set the sti type to PlatePurpose::Input.
      # @return [void]
      def input_plate=(is_input)
        @model.input_plate = is_input
      end

      # Returns the input_plate attribute from the type of the plate purpose.
      #
      # @return [Boolean] whether the plate purpose is an input plate.
      def input_plate
        @model.type == 'PlatePurpose::Input'
      end
    end
  end
end
