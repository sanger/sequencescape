# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of custom_metadatum_collection
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class CustomMetadatumCollectionResource < BaseResource
      default_includes :uuid_object, :custom_metadata

      ###
      # Attributes
      ###

      # @!attribute [r]
      # @return [String] The UUID of the collection.
      attribute :uuid

      # @!attribute [rw]
      # @return [Int] The ID of the user who created this collection. Can only and must be set on creation.
      attribute :user_id

      # @!attribute [rw]
      # @return [Int] The ID of the labware the metadata corresponds to. Can only and must be set on creation.
      attribute :asset_id

      # @!attribute [rw]
      # @return [Hash] All metadata in this collection.
      attribute :metadata

      ###
      # Allowable fields (defining read/write permissions for POST and PATCH)
      ###

      # @return [Array<Symbol>] Fields that can be created in a POST request.
      def self.creatable_fields(context)
        super - %i[uuid]
      end

      # @return [Array<Symbol>] Fields that can be updated in a PATCH request.
      def self.updatable_fields(context)
        super - %i[uuid user_id asset_id] # PATCH should only update metadata
      end
    end
  end
end
