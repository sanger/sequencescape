# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TubeFromTubeCreation} for the creation of a single child tube from a single
    # parent tube.
    # Creation of this resource via a `POST` request will create the new child tube with the parent tube as an ancestor.
    # The created child will have the specified purpose and can be accessed via the {#child} relationship.
    #
    # @note Access this resource via the `/api/v2/tube_from_tube_creations/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example POST request with child purpose and parent tube specified by UUID (deprecated)
    #   POST /api/v2/tube_from_tube_creations/
    #   {
    #     "data": {
    #       "type": "tube_from_tube_creations",
    #       "attributes": {
    #         "child_purpose_uuid": "11111111-2222-3333-4444-555555666666",
    #         "parent_uuid": "33333333-4444-5555-6666-777777888888",
    #         "user_uuid": "99999999-0000-1111-2222-333333444444"
    #       }
    #     }
    #   }
    #
    # @example POST request with child purpose and parent tube specified by relationship
    #   POST /api/v2/tube_from_tube_creations/
    # {
    #   "data": {
    #     "type": "tube_from_tube_creations",
    #     "attributes": {},
    #     "relationships": {
    #       "child_purpose": {
    #         "data": { "type": "tube_purposes", "id": "256" }
    #       },
    #       "parent": {
    #         "data": { "type": "tubes", "id": "456" }
    #       },
    #       "user": {
    #         "data": { "type": "users", "id": "2" }
    #       }
    #     }
    #   }
    # }
    #
    # @example GET request for all TubeFromTubeCreation resources
    #   GET /api/v2/tube_from_tube_creations/
    #
    # @example GET request for a TubeFromTubeCreation with ID 123
    #   GET /api/v2/tube_from_tube_creations/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubeFromTubeCreationResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] child_purpose_uuid
      #   This is declared for convenience where child purpose is not available to set as a relationship.
      #   Setting this attribute alongside the `child_purpose` relationship will prefer the relationship value.
      #   @deprecated Use the `child_purpose` relationship instead.
      #   @param value [String] The UUID of a child purpose to use in the creation of the child tube.
      #   @return [Void]
      #   @see #child_purpose
      attribute :child_purpose_uuid, writeonly: true

      def child_purpose_uuid=(value)
        @model.child_purpose = Purpose.with_uuid(value).first
      end

      # @!attribute [w] parent_uuid
      #   This is declared for convenience where parent is not available to set as a relationship.
      #   Setting this attribute alongside the `parent` relationship will prefer the relationship value.
      #   @deprecated Use the `parent` relationship instead.
      #   @param value [String] The UUID of tube that will be the parent for the created tube.
      #   @return [Void]
      #   @see #parent
      attribute :parent_uuid, writeonly: true

      def parent_uuid=(value)
        @model.parent = Labware.with_uuid(value).first
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who initiated the creation of this tube from a parent tube.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the tube from tube creation.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] child
      #   @return [TubeResource] The child tube which was created.
      has_one :child, class_name: 'Tube', readonly: true

      # @!attribute [rw] child_purpose
      #   Setting this relationship alongside the `child_purpose_uuid` attribute will override the attribute value.
      #   @return [TubePurposeResource] The purpose assigned to the created child tube.
      #   @note This relationship is required.
      has_one :child_purpose, class_name: 'TubePurpose'

      # @!attribute [rw] parent
      #   Setting this relationship alongside the `parent_uuid` attribute will override the attribute value.
      #   @return [TubeResource] The parent tube of the tube being created.
      #   @note This relationship is required.
      has_one :parent, class_name: 'Tube'

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated the creation of the pooled plate.
      #   @note This relationship is required.
      has_one :user, write_once: true
    end
  end
end
