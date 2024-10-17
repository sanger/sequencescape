# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/pooled_plate_creation/` endpoint.
    #
    # Provides a JSON:API representation of {PooledPlateCreation}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PooledPlateCreationResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] child_purpose_uuid
      #   @param value [String] The UUID of a child purpose to use in the creation of the child plate.
      #   @return [Void]
      attribute :child_purpose_uuid, writeonly: true

      def child_purpose_uuid=(value)
        @model.child_purpose = Purpose.with_uuid(value).first
      end

      # @!attribute [w] parent_uuids
      #   This is declared for convenience where parents are not available to set as a relationship.
      #   Setting this attribute alongside the `parents` relationship will prefer the relationship value.
      #   @deprecated Use the `parents` relationship instead.
      #   @param value [Array<String>] The UUIDs of labware that will be the parents for the created plate.
      #   @return [Void]
      #   @see #parents
      attribute :parent_uuids, writeonly: true

      def parent_uuids=(value)
        @model.parents = value.map { |uuid| Labware.with_uuid(uuid).first }
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who initiated the creation of this pooled plate.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the pooled plate creation.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] child
      #   @return [PlateResource] The child plate which was created.
      has_one :child, class_name: 'Plate', readonly: true

      # @!attribute [rw] parents
      #   Setting this relationship alongside the `parent_uuids` attribute will override the attribute value.
      #   @return [Array<LabwareResource>] An array of the parents of the plate being created.
      #   @note This relationship is required.
      has_many :parents, class_name: 'Labware'

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated the creation of the pooled plate.
      #   @note This relationship is required.
      has_one :user
    end
  end
end
