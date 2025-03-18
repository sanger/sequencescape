# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {SpecificTubeCreation}
    #
    # {SpecificTubeCreation} allows for the creation of multiple tubes from multiple parents.
    #
    # @note Access this resource via the `/api/v2/specific_tube_creations/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # A `POST` request to this resource will create new tubes with the specified parent tubes as ancestors.
    # The created child tubes will be assigned the given purposes and attributes and can be accessed
    # via the {#children} relationship.
    #
    # @example POST request with child purposes and parents specified by UUIDs (deprecated)
    #   POST /api/v2/specific_tube_creations/
    #   {
    #     "data": {
    #       "type": "specific_tube_creations",
    #       "attributes": {
    #         "child_purpose_uuids": ["40c0d714-fb53-11ef-bc6c-000000000000"],
    #         "parent_uuids": ["ac517f04-f461-11ef-8842-000000000000"],
    #         "tube_attributes": [{ "name": "Tube 1" }],
    #         "user_uuid": "d8c22e20-f45d-11ef-8842-000000000000"
    #       }
    #     }
    #   }
    #

    # @note the below example does not include the children as relationships, but via the
    #  `child_purpose_uuids` attribute. This is to be deprecated and should be replaced with the
    #  a relevant relationship.
    #
    # @example POST request with child purposes and parents specified by relationships
    #   POST /api/v2/specific_tube_creations/
    #   {
    #     "data": {
    #       "type": "specific_tube_creations",
    #       "attributes": {
    #         "child_purpose_uuids": [
    #             "40c0d714-fb53-11ef-bc6c-000000000000", "40c0d714-fb53-11ef-bc6c-000000000000"
    #         ],
    #         "tube_attributes": [{ "name": "Tube 1" }, { "name": "Tube 2" }]
    #       },
    #       "relationships": {
    #         "parents": {
    #           "data": [{ "type": "labware", "id": 3 }]
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": 4 }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all SpecificTubeCreation resources
    #   GET /api/v2/specific_tube_creations/
    #
    # @example GET request for a SpecificTubeCreation with ID 123
    #   GET /api/v2/specific_tube_creations/123/
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape’s implementation
    # of the JSON:API standard.
    class SpecificTubeCreationResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the specific tube creation event.
      attribute :uuid, readonly: true

      # @!attribute [w] child_purpose_uuids
      #   This is currently declared for convenience as child purposes do not appear to be set as a relationship.
      #   @todo Deprecate - Create the `child_purposes` (or `children`) relationship instead.
      #   Setting this attribute alongside the relevant relationship shold prefer the relationship value.
      #   @param value [Array<String>] Array of UUIDs for child purposes to use in the creation of tubes.
      #   @return [Void]
      attribute :child_purpose_uuids, writeonly: true

      def child_purpose_uuids=(value)
        @model.child_purposes = value.map { |uuid| Purpose.with_uuid(uuid).first }
      end

      # @!attribute [w] parent_uuids
      #   @deprecated Use the `parents` relationship instead.
      #   This is declared for convenience where the parent tubes are not available to set as a relationship.
      #   Setting this attribute alongside the `parents` relationship will prefer the relationship value.
      #   @param value [Array<String>] The UUIDs of labware that will be the parents for all tubes created.
      #   @return [Void]
      #   @see #parents
      attribute :parent_uuids, writeonly: true

      def parent_uuids=(value)
        @model.parents = value.map { |uuid| Labware.with_uuid(uuid).first }
      end

      # @!attribute [w] tube_attributes
      #   @param value [Array<Hash>] Array of attribute hashes to apply to each tube being created.
      #     This can be used to set custom properties, such as tube names.
      #   @return [Void]
      attribute :tube_attributes, writeonly: true

      def tube_attributes=(value)
        return if value.nil?

        # Convert ActionController::Parameters into hashes.
        @model.tube_attributes = value.map(&:to_unsafe_h)
      end

      # @!attribute [w] user_uuid
      #   @deprecated Use the `user` relationship instead.
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @param value [String] The UUID of the user who initiated the creation of tubes.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      ###
      # Relationships
      ###

      # @!attribute [r] children
      #   @todo fix this relationship as it currently appears to be broken
      #   @return [Array<TubeResource>] An array of tubes that were created.
      has_many :children, class_name: 'Tube', readonly: true

      # @!attribute [rw] parents
      #   Setting this relationship alongside the `parent_uuids` attribute will override the attribute value.
      #   @return [Array<LabwareResource>] An array of parent tubes for the created tubes.
      #   @note This relationship is required.
      has_many :parents, class_name: 'Labware'

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated the creation of tubes.
      #   @note This relationship is required.
      has_one :user
    end
  end
end
