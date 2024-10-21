# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PlateCreation} for creation of a child plate with a given purpose which
    # is linked to a parent plate as one of its children.
    # Creation of this resource via a `POST` request will initiate the child plate creation.
    # The child plate is returned by this endpoint under the {#child} relationship.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/plate_creations/` endpoint.
    #
    # @example POST request with arguments specified by UUID (deprecated)
    #   POST /api/v2/plate_creations/
    #   {
    #     "data": {
    #       "type": "plate_creations",
    #       "attributes": {
    #         "parent_uuid": "11111111-2222-3333-4444-555555666666",
    #         "child_purpose_uuid": "22222222-3333-4444-5555-666666777777",
    #         "user_uuid": "33333333-4444-5555-6666-777777888888"
    #       }
    #     }
    #   }
    #
    # @example POST request with arguments specified by relationship
    #   POST /api/v2/plate_creations/
    #   {
    #     "data": {
    #       "type": "plate_creations",
    #       "attributes": {},
    #       "relationships": {
    #         "parent": {
    #           "data": { "type": "plates", "id": "123" }
    #         },
    #         "child_purpose": {
    #           "data": { "type": "plate_purposes", "id": "234" }
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": "345" }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all PlateCreation resources
    #   GET /api/v2/plate_creations/
    #
    # @example GET request for a PlateCreation with ID 123
    #   GET /api/v2/plate_creations/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PlateCreationResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] child_purpose_uuid
      #   This is declared for convenience where the {PlatePurpose} is not available to set as a relationship.
      #   Setting this attribute alongside the `child_purpose` relationship will prefer the relationship value.
      #   @deprecated Use the `child_purpose` relationship instead.
      #   @param value [String] The UUID of the {PlatePurpose} to use when creating the child plate.
      #   @return [Void]
      #   @see #child_purpose
      attribute :child_purpose_uuid, writeonly: true

      def child_purpose_uuid=(value)
        @model.child_purpose = PlatePurpose.with_uuid(value).first
      end

      # @!attribute [w] parent_uuid
      #   This is declared for convenience where the parent {Plate} is not available to set as a relationship.
      #   Setting this attribute alongside the `parent` relationship will prefer the relationship value.
      #   @deprecated Use the `parent` relationship instead.
      #   @param value [String] The UUID of the {Plate} to become the parent of the created child plate.
      #   @return [Void]
      #   @see #parent
      attribute :parent_uuid, writeonly: true

      def parent_uuid=(value)
        @model.parent = Plate.with_uuid(value).first
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the {User} is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the {User} who initiated this plate creation.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the plate creation.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] child
      #   @return [Api::V2::PlateResource] The child plate created by this resource.
      has_one :child, class_name: 'Plate', readonly: true

      # @!attribute [rw] child_purpose
      #   Setting this relationship alongside the `child_purpose_uuid` attribute will override the attribute value.
      #   The purpose which the child plate should be created with.
      #   @return [Api::V2::PlatePurposeResource]
      #   @note This relationship is required.
      has_one :child_purpose, class_name: 'PlatePurpose'

      # @!attribute [rw] parent
      #   Setting this relationship alongside the `parent_uuid` attribute will override the attribute value.
      #   @return [Api::V2::PlateResource] The plate to become the parent of the created child plate.
      has_one :parent, class_name: 'Plate'

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [Api::V2::UserResource] The user who initiated this plate creation.
      #   @note This relationship is required.
      has_one :user
    end
  end
end
