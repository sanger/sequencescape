# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/custom_metadatum_collections/` endpoint.
    #
    # Provides a JSON:API representation of {CustomMetadatumCollection}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class CustomMetadatumCollectionResource < BaseResource
      default_includes :uuid_object, :custom_metadata

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @return [String] The UUID of the collection.
      attribute :uuid, readonly: true

      # @!attribute [rw] user_id
      #   @return [Int] The ID of the user who created this collection. Can only and must be set on creation.
      attribute :user_id

      # @!attribute [rw] asset_id
      #   @return [Int] The ID of the labware the metadata corresponds to. Can only and must be set on creation.
      attribute :asset_id

      # @!attribute [rw] metadata
      #   @return [Hash] All metadata in this collection.
      attribute :metadata

      ###
      # Allowable fields (defining read/write permissions for POST and PATCH)
      ###

      # @return [Array<Symbol>] Fields that can be updated in a PATCH request.
      def self.updatable_fields(context)
        super - %i[uuid user_id asset_id] # PATCH should only update metadata
      end
    end
  end
end
