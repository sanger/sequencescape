# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {QcFile} which contains the QC data previously added to a piece of
    # {Labware}. The file contents are stored in the database using the {DbFile} model. This resource only allows the
    # submission of the file contents at this time and not the retrieval of the file contents.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/qc_files/` endpoint.
    #
    # @example POST request
    #   POST /api/v2/qc_files/
    #   {
    #     "data": {
    #       "type": "qc_files",
    #       "attributes": {
    #       }
    #     }
    #   }
    #
    # @example GET request for all QcFile resources
    #   GET /api/v2/qc_files/
    #
    # @example GET request for a QcFile with ID 123
    #   GET /api/v2/qc_files/123/
    #
    # @example GET request for all QcFile resources associated with a Plate with ID 123
    #   GET /api/v2/plates/123/qc_files/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class QcFileResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @return [String] The UUID of the bulk transfers operation.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] asset
      #   @return [AssetResource] The Labware which this QcFile belongs to.
      has_one :asset, readonly: true
    end
  end
end
