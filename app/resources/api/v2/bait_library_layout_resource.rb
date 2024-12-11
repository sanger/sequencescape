# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/bait_library_layouts/` endpoint.
    #
    # Provides a JSON:API representation of {BaitLibraryLayout}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class BaitLibraryLayoutResource < BaseResource
      # @!attribute [w] plate_uuid
      #   This is declared for convenience where the plate is not available to set as a relationship.
      #   Setting this attribute alongside the `plate` relationship will prefer the relationship value.
      #   @deprecated Use the `plate` relationship instead.
      #   @param value [String] The UUID of the plate for this bait library layout.
      #   @return [Void]
      #   @see #plate
      attribute :plate_uuid, writeonly: true

      def plate_uuid=(value)
        @model.plate = Plate.with_uuid(value).first
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who created this bait library layout.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] layout
      #   @return [Hash] The layout of the bait libraries on the plate.
      attribute :layout, readonly: true

      # # @!attribute [r] uuid
      # #   @return [String] The UUID of the state change.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who created this bait library layout.
      #   @note This relationship is required.
      has_one :user

      # @!attribute [rw] plate
      #   Setting this relationship alongside the `plate_uuid` attribute will override the attribute value.
      #   @return [PlateResource] The plate for this bait library layout.
      #   @note This relationship is required.
      has_one :plate
    end
  end
end
