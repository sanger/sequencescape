# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/tube_from_tube_creation/` endpoint.
    #
    # Provides a JSON:API representation of {TubeFromTubeCreation}.
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
      attribute :child_purpose_uuid

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
      attribute :parent_uuid

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
      attribute :user_uuid

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
      has_one :child, class_name: 'Tube'

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
      has_one :user

      def self.creatable_fields(context)
        # The child relationship can only be read after the creation has happened.
        # UUID is set by the system.
        super - %i[child uuid]
      end

      def fetchable_fields
        # UUIDs for relationships are not fetchable. They should be accessed via the relationship itself.
        super - %i[child_purpose_uuid parent_uuid user_uuid]
      end
    end
  end
end
