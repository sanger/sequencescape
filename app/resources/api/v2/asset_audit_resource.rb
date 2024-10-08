# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/asset_audits/` endpoint.
    #
    # Provides a JSON:API representation of {AssetAudit}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class AssetAuditResource < BaseResource
      model_name 'AssetAudit'

      # @!attribute key
      #   @return [String] the key of the asset audit.
      attribute :key

      # @!attribute message
      #   @return [String] the message of the asset audit.
      attribute :message

      # @!attribute created_by
      #   @return [String] the user who created the asset audit.
      attribute :created_by

      # @!attribute asset_uuid
      #   @return [String] the uuid of the asset associated with the asset audit.
      attribute :asset_uuid

      # @!attribute witnessed_by
      #   @return [String] the user who witnessed the asset audit.
      attribute :witnessed_by

      # @!attribute metadata
      #   @return [Hash] the metadata of the asset audit.
      attribute :metadata # Currently known clients (AssetAudits app) are sending null; unsure of the expected format.

      # Sets the Asset on the model using the UUID provided in the API create/update request.
      #
      # @param uuid [String] the uuid of the associated asset.
      # @return [void]
      def asset_uuid=(uuid)
        @model.asset = Uuid.with_external_id(uuid).include_resource.map(&:resource).first
      end

      # Transforms the Asset into its UUID when generating an API query response.
      #
      # @return [String] the uuid of the associated asset.
      def asset_uuid
        @model.asset.uuid
      end

      # Gets the list of fields which are updatable on an existing AssetAudit.
      #
      # @param _context [JSONAPI::Resource::Context] not used.
      # @return [Array<Symbol>] the list of updatable fields.
      def self.updatable_fields(_context)
        [] # Do not allow updating any fields.
      end
    end
  end
end
