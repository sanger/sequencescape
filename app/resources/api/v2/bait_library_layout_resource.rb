# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {BaitLibraryLayout}.
    #
    # This resource represents the layout of bait libraries on a specific plate.
    # It is primarily used to retrieve information about the arrangement of bait libraries.
    #
    # @note This resource cannot be modified after creation; its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/bait_library_layouts/` endpoint.
    #
    # @example GET request for all BaitLibraryLayout resources
    #   GET /api/v2/bait_library_layouts/
    #
    # @example GET request for a BaitLibraryLayout with ID 123
    #   GET /api/v2/bait_library_layouts/123/
    #
    # @example POST request to create a BaitLibraryLayout
    #   POST /api/v2/bait_library_layouts/
    #   {
    #     "data": {
    #         "type": "bait_library_layouts",
    #         "attributes": {
    #         },
    #         "relationships": {
    #             "plate": { "data": { "type": "plates", "id": 1 } },
    #             "user": { "data": { "type": "users", "id": 4 } }
    #         }
    #     }
    # }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class BaitLibraryLayoutResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] plate_uuid
      #   This attribute is declared for convenience when the plate is not available to set as a relationship.
      #   Setting this attribute alongside the `plate` relationship will prefer the relationship value.
      #   @deprecated Use the `plate` relationship instead.
      #   @param value [String] The UUID of the plate for this bait library layout.
      #   @return [void]
      #   @see #plate
      attribute :plate_uuid, writeonly: true

      def plate_uuid=(value)
        @model.plate = Plate.with_uuid(value).first
      end

      # @!attribute [w] user_uuid
      #   This attribute is declared for convenience when the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who created this bait library layout.
      #   @return [void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] layout
      #   @return [Hash] The layout of the bait libraries on the plate.
      attribute :layout, readonly: true

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the bait library layout.
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
