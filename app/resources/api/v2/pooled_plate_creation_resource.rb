# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PooledPlateCreation}.
    #
    # This resource represents the creation of a pooled plate from one or more parent plates.
    # The new plate is generated based on a specified `child_purpose_uuid` and associated with its parents and user.
    #
    # @note Access this resource via the `/api/v2/pooled_plate_creation/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example GET request to retrieve all pooled plate creations
    #   GET /api/v2/pooled_plate_creation/
    #
    # @example GET request to retrieve a specific pooled plate creation
    #   GET /api/v2/pooled_plate_creation/123
    #
    # @example POST request with attributes specified by UUID (deprecated)
    #   POST /api/v2/pooled_plate_creation/
    #   {
    #     "data": {
    #       "type": "pooled_plate_creation",
    #       "attributes": {
    #         "child_purpose_uuid": "uuid-of-child-purpose",
    #         "parent_uuids": ["uuid-of-parent-1", "uuid-of-parent-2"],
    #         "user_uuid": "uuid-of-user"
    #       }
    #     }
    #   }
    #
    # @example POST request to create a pooled plate using relationships
    #   POST /api/v2/pooled_plate_creation/
    #   {
    #     "data": {
    #       "type": "pooled_plate_creations",
    #       "attributes": {
    #         "child_purpose_uuid": ["f64dec80-f51c-11ef-8842-000000000000"]
    #       },
    #       "relationships": {
    #         "parents": {
    #           "data": [
    #             { "type": "labware", "id": 1 },
    #             { "type": "labware", "id": 4 }
    #           ]
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": 1 }
    #         }
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PooledPlateCreationResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] child_purpose_uuid
      #   The UUID of the child purpose, which determines the type of plate being created.
      #   @todo deprecate this attribute in favour of the `child_purpose` relationship.
      #   @param value [String] or String - The UUID of a child purpose.
      #   @return [Void]
      attribute :child_purpose_uuid, writeonly: true

      # @!attribute [w] parent_uuids
      #   This is declared for convenience where parents are not available to set as a relationship.
      #   This attribute is optional if the `parents` relationship is explicitly set.
      #   If both `parent_uuids` and `parents` are provided, `parents` takes precedence.
      #   @deprecated Use the `parents` relationship instead.
      #   @param value [Array<String>] UUIDs of the parent labware.
      #   @return [Void]
      #   @see #parents
      attribute :parent_uuids, writeonly: true

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   This attribute is optional if the `user` relationship is explicitly set.
      #   If both `user_uuid` and `user` are provided, `user` takes precedence.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] UUID of the user.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the collection. This uniquely identifies the pooled plate creation event.
      attribute :uuid, readonly: true

      ###
      # Getters and Setters
      ###

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      def parent_uuids=(value)
        @model.parents = value.map { |uuid| Labware.with_uuid(uuid).first }
      end

      def child_purpose_uuid=(value)
        @model.child_purpose = Purpose.with_uuid(value).first
      end

      ###
      # Relationships
      ###

      # @!attribute [r] child
      #   The plate that was created from the pooling process.
      #   @return [PlateResource] The newly created child plate.
      has_one :child, class_name: 'Plate', readonly: true

      # @!attribute [rw] parents
      #   The labware used as the source for the pooled plate.
      #   If both `parent_uuids` and `parents` are provided, `parents` takes precedence.
      #   @return [Array<LabwareResource>] An array of parent labware resources.
      has_many :parents, class_name: 'Labware'

      # @!attribute [rw] user
      #   The user who initiated the pooled plate creation.
      #   If both `user_uuid` and `user` are provided, `user` takes precedence.
      #   @return [UserResource] The user resource.
      has_one :user
    end
  end
end
