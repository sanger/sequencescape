# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/specific_tube_creations/` endpoint.
    #
    # Provides a JSON:API representation of {SpecificTubeCreation}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SpecificTubeCreationResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] child_purpose_uuids
      #   @param value [Array] Array of UUIDs for child purposes to use in the creation of tubes.
      #   @return [Void]
      attribute :child_purpose_uuids

      def child_purpose_uuids=(value)
        @model.set_child_purposes(value)
      end

      # @!attribute [w] parent_uuid
      #   This is declared for convenience where the parent is not available to set as a relationship.
      #   Setting this attribute alongside the `parent` relationship will prefer the relationship value.
      #   @param value [String] The UUID of a single parent plate that will be the parent for all tubes created.
      #   @return [Void]
      #   @see #parent
      attribute :parent_uuid

      def parent_uuid=(value)
        @model.parent = Plate.with_uuid(value).first
      end

      # @!attribute [w] tube_attributes
      #   @param value [Array<Hash>] Hashes defining the attributes to apply to each tube being created.
      #   @return [Void]
      attribute :tube_attributes

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @param value [String] The UUID of the user who initiated the creation of tubes.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the state change.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated the creation of tubes.
      #   @note This relationship is required.
      has_one :user

      # @!attribute [rw] parents
      #   Setting this relationship alongside the `parent_uuid` attribute will override the attribute value.
      #   @return [Array<AssetResource>] An array of the parents of the tubes being created.
      #   @note This relationship is required.
      has_many :parents, class_name: 'Asset'

      # @!attribute [r] children
      #   @return [Array<TubeResource>] An array of tubes that were created.
      has_many :children, class_name: 'Tube'

      def self.creatable_fields(context)
        # UUID is set by the system.
        super - %i[uuid]
      end

      def fetchable_fields
        # The tube_attributes attribute is only available during resource creation.
        # UUIDs for relationships are not fetchable. They should be accessed via the relationship itself.
        super - %i[child_purpose_uuids parent_uuid tube_attributes user_uuid]
      end
    end
  end
end
