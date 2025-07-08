# frozen_string_literal: true

module Api
  module V2
    # This resource represents the api v2 resource for the specific tube rack creations endpoint.
    # This endpoint is used to create tube rack instances and the racked tubes within them.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/specific_tube_rack_creations/` endpoint.
    #
    # Provides a JSON:API representation of {SpecificTubeRackCreation}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SpecificTubeRackCreationResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] parent_uuids
      #   This is declared for convenience where the parent is not available to set as a relationship.
      #   Setting this attribute alongside the `parents` relationship will prefer the relationship value.
      #   @deprecated Use the `parents` relationship instead.
      #   @param value [Array<String>] The UUIDs of labware that will be the parents for all tube racks
      #   and tubes created.
      #   @return [Void]
      #   @see #parents
      attribute :parent_uuids

      def parent_uuids=(value)
        @model.parents = value.map { |uuid| Labware.with_uuid(uuid).first }
      end

      # @!attribute [w] tube_rack_attributes
      #   @param value [Array<Hash>] Hashes defining the attributes to apply to each tube rack and
      #     the tubes within that are being created.
      #     This is used to set custom attributes on the tube racks, such as name. As well as to create
      #     the tubes within the tube rack and link them together.
      #   @example [
      #   {
      #     :tube_rack_name=>"Tube Rack",
      #     :tube_rack_barcode=>"TR00000001",
      #     :tube_rack_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
      #     :racked_tubes=>[
      #       {
      #         :tube_barcode=>"SQ45303801",
      #         :tube_name=>"SEQ:NT749R:A1",
      #         :tube_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
      #         :tube_position=>"A1",
      #         :parent_uuids=>["bd49e7f8-80a1-11ef-bab6-82c61098d1a0"]
      #       },
      #       etc... more tubes
      #     ]
      #   },
      #   etc... more tube racks
      #
      #   @return [Void]
      attribute :tube_rack_attributes

      def tube_rack_attributes=(value)
        return if value.nil?

        # Convert ActionController::Parameters into hashes.
        @model.tube_rack_attributes = value.map(&:to_unsafe_h)
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who initiated the creation of tubes.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the AssetCreation instance.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] children
      #   @return [Array<TubeRackResource>] An array of tube racks that were created.
      has_many :children, class_name: 'TubeRack'

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

      def self.creatable_fields(context)
        # UUID is set by the system.
        super - %i[uuid]
      end

      def fetchable_fields
        # The tube_rack_attributes attribute is only available during resource creation.
        # UUIDs for relationships are not fetchable. They should be accessed via the relationship itself.
        super - %i[parent_uuids tube_rack_attributes user_uuid]
      end
    end
  end
end
