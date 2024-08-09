# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/sample_metadata/` endpoint.
    #
    # Provides a JSON:API representation of {Sample::Metadata}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SampleMetadataResource < BaseResource
      # Set add_model_hint true to allow updates from Limber, otherwise get a
      # 500 error as it looks for resource Api::V2::MetadatumResource
      model_name 'Sample::Metadata', add_model_hint: true

      ###
      # Attributes
      ###

      # @!attribute [rw] cohort
      #   @return [String] the sample cohort.
      attribute :cohort

      # @!attribute [rw] collected_by
      #   @return [String] the name of the body collecting the sample.
      attribute :collected_by

      # @!attribute [rw] concentration
      #   @return [String] the sample concentration.
      attribute :concentration

      # @!attribute [rw] donor_id
      #   @return [String] the ID of the sample donor.
      attribute :donor_id

      # @!attribute [rw] gender
      #   @return [String] the gender of the organism providing the sample.
      attribute :gender

      # @!attribute [rw] sample_common_name
      #   @return [String] the common name for the sample.
      attribute :sample_common_name

      # @!attribute [rw] sample_description
      #   @return [String] a description of the sample.
      attribute :sample_description

      # @!attribute [rw] supplier_name
      #   @return [String] the supplier name for the sample.
      attribute :supplier_name

      # @!attribute [rw] volume
      #   @return [String] the volume of the sample.
      attribute :volume

      ###
      # Filters
      ###

      filter :sample_id
    end
  end
end
