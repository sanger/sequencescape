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
      #   @param value [Array<String>] Array of UUIDs for child purposes to use in the creation of tubes.
      #   @return [Void]
      attribute :child_purpose_uuids, writeonly: true

      def child_purpose_uuids=(value)
        @model.child_purposes = value.map { |uuid| Purpose.with_uuid(uuid).first }
      end

      # @!attribute [w] parent_uuids
      #   This is declared for convenience where the parent is not available to set as a relationship.
      #   Setting this attribute alongside the `parents` relationship will prefer the relationship value.
      #   @deprecated Use the `parents` relationship instead.
      #   @param value [Array<String>] The UUIDs of labware that will be the parents for all tubes created.
      #   @return [Void]
      #   @see #parents
      attribute :parent_uuids, writeonly: true

      def parent_uuids=(value)
        @model.parents = value.map { |uuid| Labware.with_uuid(uuid).first }
      end

      # @!attribute [w] tube_attributes
      #   @param value [Array<Hash>] Hashes defining the attributes to apply to each tube being created.
      #     This might be used to set custom attributes on the tubes, such as name.
      #   @example Setting the name of the tubes being created.
      #     [{ name: 'Tube one' }, { name: 'Tube two' }]
      #   @return [Void]
      attribute :tube_attributes, writeonly: true

      def tube_attributes=(value)
        return if value.nil?

        # Convert ActionController::Parameters into hashes.
        @model.tube_attributes = value.map(&:to_unsafe_h)
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who initiated the creation of tubes.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the state change.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] children
      #   @return [Array<TubeResource>] An array of tubes that were created.
      has_many :children, class_name: 'Tube', readonly: true

      # @!attribute [rw] parents
      #   Setting this relationship alongside the `parent_uuids` attribute will override the attribute value.
      #   @return [Array<LabwareResource>] An array of the parents of the tubes being created.
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
