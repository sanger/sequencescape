# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Plate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PlatePurposeResource < BaseResource
      model_name 'PlatePurpose'

      # This resource is similar to PurposeResource but it was created to
      # migrate the registration of plate purposes done by the Limber rake
      # task config:generate from API version 1 to API version 2.

      # The following attributes are sent by Limber for a new plate purpose.

      # @!attribute name
      #  @return [String] the name of the plate purpose
      attribute :name

      # @!attribute stock_plate
      #  @return [Boolean] whether the plates of this purpose are stock plates
      attribute :stock_plate

      # @!attribute cherrypickable_target
      #  @return [Boolean] whether the plates of this purpose are cherrypickable
      attribute :cherrypickable_target

      # @!attribute input_plate
      #  @return [Boolean] whether the plates of this purpose are input plates
      attribute :input_plate

      # @!attribute size
      #  @return [Integer] the size of the plates of this purpose
      attribute :size

      # @!attribute asset_shape
      #  @return [String] the name of the shape of the plates of this purpose
      attribute :asset_shape

      # The following attribute is required by Limber to store purposes.

      # @!attribute [r] uuid
      #  @return [String] the UUID of the plate purpose
      attribute :uuid, readonly: true

      # Sets the asset shape of the plate purpose by name if given.
      # 'asset_shape' can be given via the Limber purpose configuration and
      # defaults to 'Standard' if not provided. If the name is given and not
      # found, an error is raised. Note that the name is case-sensitive.
      #
      # @param name [String] the name of the asset shape
      # @return [void]
      def asset_shape=(name)
        @model.asset_shape = (AssetShape.find_by!(name: name) if name.present?) || AssetShape.default
      end

      # Returns the name of the asset shape of the plate purpose.
      # The asset_shape association is not utilized in Limber. This method
      # returns the name of the asset shape associated with the plate purpose.
      #
      # @return [String] the name of the asset shape
      def asset_shape
        @model.asset_shape.name
      end

      # Returns the input_plate attribute from the type of the plate purpose.
      # This method is the counterpart to the model's attribute writer for
      # input_plate. It performs the inverse operation, determining the value
      # of input_plate attribute based on the model's type.
      #
      # @return [Boolean] whether the plate purpose is an input plate
      def input_plate
        @model.type == 'PlatePurpose::Input'
      end

      # Prevents updating existing plate purposes.
      #
      # @param _context [JSONAPI::Resource::Context] not used
      # @return [Array<Symbol>] empty array
      def updatable_fields(_context)
        []
      end
    end
  end
end
