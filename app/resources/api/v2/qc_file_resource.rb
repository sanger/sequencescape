# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {QcFile} which contains the QC data previously added to a piece of
    # {Labware}. The file contents are stored in the database using the {DbFile} model.
    #
    # @note Access this resource via the `/api/v2/qc_files/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Known issues:
    #  - Occasionally, encoding failures may occur resulting in 500 Internal Server errors
    #    mentioning `from ASCII-8BIT to UTF-8`. If this occurs, try re-requesting the resource
    #    without including the `contents` attribute, for example:
    #    `/api/v2/qc_files/1?fields[qc_files]=filename,uuid,created_at`
    #
    # @example POST request
    #   POST /api/v2/qc_files/
    #   {
    #     "data": {
    #       "type": "qc_files",
    #       "attributes": {
    #         "filename": "a_test_file.csv",
    #         "contents": "Hello"
    #       },
    #       "relationships": {
    #         // "asset": {
    #         //   "data": {
    #         //     "type": "labware",
    #         //     "id": 26
    #         //   }
    #         // }
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

      # @!attribute [r] created_at
      #   @return [DateTime] The date and time the QC file was created.
      attribute :created_at, readonly: true

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

      # @!attribute [rw] contents
      #   @return [String] The String contents of the QC file.
      #      This is usually the CSV data for the QC file.
      #      This can only be written once on creation.
      attribute :contents, write_once: true
      attr_writer :contents # Do not store the value on the model. It is stored by the CarrierWave gem via a Tempfile.

      def contents
        # The contents comes from the uploaded_data managed by CarrierWave.
        @model.current_data
      end

      # @!attribute [rw] filename
      #   @return [String] The filename of the QC file.
      #      This can only be written once on creation.
      attribute :filename, write_once: true
      attr_writer :filename # Do not store the value on the model. This value is consumed by the QcFileProcessor.

      def self.create(context)
        opts = { uploaded_data: context.slice(:filename, :tempfile) }
        new(QcFile.new(opts), context)
      end
    end
  end
end
