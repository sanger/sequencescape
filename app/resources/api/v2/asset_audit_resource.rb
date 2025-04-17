# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {AssetAudit}, which records audit events related to assets.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/asset_audits/` endpoint.
    #
    # @example GET request for all AssetAudit resources
    #   GET /api/v2/asset_audits/
    #
    # @example GET request for a specific AssetAudit by ID
    #   GET /api/v2/asset_audits/123/
    #
    # @example POST request to create a new AssetAudit
    #   POST /api/v2/asset_audits/
    #   {
    #     "data": {
    #       "type": "asset_audits",
    #       "attributes": {
    #         "key": "asset_audit_key",
    #         "message": "Asset audit message",
    #         "created_by": "user_uuid",
    #         "witnessed_by": "witness_user_uuid",
    #         "metadata": null
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class AssetAuditResource < BaseResource
      model_name 'AssetAudit'

      ###
      # Attributes
      ###

      # @!attribute [w] key
      #   @note This field is required.
      #   @param value [String] The key of the asset audit event.
      #   @return [String] The key of the asset audit event.
      attribute :key

      # @!attribute [w] message
      #   @param value [String] The message describing the audit event.
      #   @return [String] The message describing the audit event.
      attribute :message

      # @!attribute [w] created_by
      #   @param value [String] The user who created the asset audit.
      #   @return [String] The user who created the asset audit.
      attribute :created_by

      # @!attribute [w] asset_uuid
      #   @note This field is required.
      #   @param value [String] The UUID of the associated asset.
      #   @return [String] The UUID of the associated asset.
      #   @todo deprecate; use the `asset` relationship instead
      attribute :asset_uuid

      # @!attribute [w] witnessed_by
      #   @param value [String]  The user who witnessed the asset audit.
      #   @return [String] The user who witnessed the asset audit.
      attribute :witnessed_by

      # @!attribute [w] metadata
      #   @param value [String] Additional metadata associated with the asset audit.
      #   @return [Hash] Additional metadata associated with the asset audit.
      #   @note Currently known clients (Asset Audits App) are sending null; unsure of the expected format.
      attribute :metadata

      ###
      # Getters and Setters
      ###

      # Sets the Asset on the model using the UUID provided in the API create/update request.
      #
      # @todo Deprecate. Replace with `asset` relationship
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      # @param uuid [String] the uuid of the associated asset.
      # @return [void]
      def asset_uuid=(uuid)
        @model.asset = Uuid.with_external_id(uuid).include_resource.map(&:resource).first
      end

      # Transforms the Asset into its UUID when generating an API query response.
      #
      # @return [String] the uuid of the associated asset
      def asset_uuid
        @model.asset.uuid
      end

      ###
      # Class Methods
      ###

      # Gets the list of fields that are updatable on an existing AssetAudit.
      # AssetAudits cannot be modified after creation.
      # @todo Use `except: %i[update]` in `routes.rb` or the access restrictions instead of this approach
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      # @param _context [JSONAPI::Resource::Context] Not used.
      # @return [Array<Symbol>] The list of updatable fields.
      def self.updatable_fields(_context)
        [] # Do not allow updating any fields.
      end
    end
  end
end
