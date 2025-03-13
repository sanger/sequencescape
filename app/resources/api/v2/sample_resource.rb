# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Sample}, which represents a biological or synthetic
    #   sample used in laboratory processes.
    # This resource allows users to retrieve and filter samples based on various attributes such
    #   as UUID, name, or Sanger Sample ID.
    #
    # @note Access this resource via the `/api/v2/samples/` endpoint.
    #
    # @example GET request for all samples
    #   GET /api/v2/samples/
    #
    # @example GET request for a specific sample by ID
    #   GET /api/v2/samples/123/
    #
    # @example POST request to create a new sample
    #   POST /api/v2/samples/
    # {
    #   "data": {
    #     "type": "samples",
    #     "attributes": {
    #       "name": "Sample_A",
    #       "sanger_sample_id": "S12345",
    #       "control": false,
    #       "control_type": "positive"
    #     },
    #     "relationships": {
    #       "sample_metadata": {
    #         "data": {
    #           "type": "sample_metadata",
    #           "id": "1"
    #         }
    #       },
    #       "studies": {
    #         "data": [
    #           {
    #             "type": "studies",
    #             "id": "1"
    #           },
    #         ]
    #       },
    #       "component_samples": {
    #         "data": [
    #           {
    #             "type": "component_samples",
    #             "id": "1"
    #           },
    #         ]
    #       }
    #     }
    #   }
    # }
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SampleResource < BaseResource
      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [rw] name
      #   @return [String] The name of the sample.
      #   @note This field is optional.
      attribute :name

      # @!attribute [rw] sanger_sample_id
      #   @return [String] The unique identifier assigned to the sample within the Sanger Institute.
      #   @note This field is optional but commonly used for sample tracking.
      attribute :sanger_sample_id

      # @!attribute [r] uuid
      #   @return [String] The globally unique identifier (UUID) for this sample.
      #   @note This value is automatically assigned upon creation and cannot be modified.
      attribute :uuid, readonly: true

      # @!attribute [rw] control
      #   @return [Boolean] Indicates whether this sample is a control sample.
      #   @note Optional field.
      attribute :control

      # @!attribute [rw] control_type
      #   @return [String] The type of control sample (e.g., positive control, negative control).
      #   @note Optional field.
      attribute :control_type

      ###
      # Relationships
      ###

      # @!attribute [rw] sample_metadata
      #   @return [SampleMetadataResource] The metadata associated with this sample, containing additional
      #     details like collection method and donor information.
      #   @note Optional relationship.
      has_one :sample_metadata, class_name: 'SampleMetadata', foreign_key_on: :related

      # @!attribute [rw] sample_manifest
      #   @return [SampleManifestResource] The manifest to which this sample belongs, often linking it
      #     to a larger set of processed samples.
      #   @note Optional relationship.
      has_one :sample_manifest

      # @!attribute [rw] studies
      #   @return [Array<StudyResource>] The studies associated with this sample.
      #   @note A sample can be linked to multiple studies.
      has_many :studies

      # @!attribute [rw] component_samples
      #   @return [Array<ComponentSampleResource>] The component samples associated with this sample.
      #   @note A sample may consist of multiple component samples.
      has_many :component_samples

      ###
      # Filters
      ###

      # @!method filter_by_uuid
      #   Filters samples by their UUID.
      #   @example GET request filtering by UUID
      #     GET /api/v2/samples?filter[uuid]=550e8400-e29b-41d4-a716-446655440000
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      # @!method filter_by_sanger_sample_id
      #   Filters samples by their Sanger Sample ID.
      #   @example GET request filtering by Sanger Sample ID
      #     GET /api/v2/samples?filter[sanger_sample_id]=S12345
      filter :sanger_sample_id

      # @!method filter_by_name
      #   Filters samples by their name.
      #   @example GET request filtering by name
      #     GET /api/v2/samples?filter[name]=Sample_A
      filter :name
    end
  end
end
