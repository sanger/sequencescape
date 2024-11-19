# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {QcFile} which contains the QC data previously added to a piece of
    # {Labware}. The file contents are stored in the database using the {DbFile} model.
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
    #         "filename": "qc_file.csv",
    #         "contents": "A1,A2,A3\n1,2,3\n4,5,6\n"
    #       },
    #       "relationships": {
    #         "asset": {
    #           "data": {
    #             "type": "labware",
    #             "id": "123"
    #           }
    #         }
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

      # @!attribute [r] content_type
      #   @return [String] The content type, or MIME type, of the QC file.
      attribute :content_type, readonly: true

      # @!attribute [rw] contents
      #   @return [String] The String contents of the QC file.
      #      This is usually the CSV data for the QC file.
      #      This can only be written once on creation.
      attribute :contents, write_once: true

      def contents
        # The contents comes from the uploaded_data managed by CarrierWave.
        @model.current_data
      end

      def contents=(value)
        # Do not update the model.
        # File contents is set via the uploaded_data hash supplied during QcFile creation.
      end

      # @!attribute [r] created_at
      #   @return [DateTime] The date and time the QC file was created.
      attribute :created_at, readonly: true

      # @!attribute [rw] filename
      #   @return [String] The filename of the QC file.
      #      This can only be written once on creation.
      attribute :filename, write_once: true

      def filename=(value)
        # Do not update the model.
        # Filename is set via the uploaded_data hash supplied during QcFile creation.
      end

      # @!attribute [r] size
      #   @return [Integer] The size of the QC file in bytes.
      attribute :size, readonly: true

      # @!attribute [r] uuid
      #   @return [String] The UUID of the bulk transfers operation.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] labware
      #   @return [LabwareResource] The Labware which this QcFile belongs to.
      has_one :labware, relation_name: :asset, foreign_key: :asset_id, write_once: true

      ###
      # Filters
      ###

      # @!method filter_uuid
      #   Filter the QcFile resources by UUID.
      #   @example GET request with UUID filter
      #     GET /api/v2/qc_files?filter[uuid]=12345678-1234-1234-1234-123456789012
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      ###
      # Create method
      ###

      # @!method create_with_tempfile
      #   Create a new QcFile resource with the uploaded data from a temporary file. This is called by the controller
      #   when a create request for a QcFile is made. It ensures the contents of the file have been written to a
      #   new TempFile instance.
      # @param context [Hash] The context for the request.
      # @param tempfile [Tempfile] A temporary file containing the uploaded data.
      # @param filename [String] The filename for the uploaded data.
      # @return [QcFileResource] The new QcFile resource.
      def self.create_with_tempfile(context, tempfile, filename)
        opts = { uploaded_data: { tempfile:, filename: } }
        new(QcFile.new(opts), context)
      end
    end
  end
end
