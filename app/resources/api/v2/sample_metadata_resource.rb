# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Sample::Metadata} which contains additional
    # metadata related to a {Sample}.
    #
    # A {Sample} represents the life of a DNA/RNA sample as it moves through processes.
    # It may exist in multiple {Receptacle receptacles} as {Aliquot aliquots}.
    # {Sample} tracks aspects that are always true, like its origin.
    #
    # @note Access this resource via the `/api/v2/sample_metadata/` endpoint.
    #
    # @example GET request for all sample metadata
    #   GET /api/v2/sample_metadata/
    #
    # @example GET request for a specific sample metadata record by ID
    #   GET /api/v2/sample_metadata/123/
    #
    # @todo Figure out how to send a POST for a sample with sample metadata association. Currently,
    #   it is possible to create a sample and sample metadata seperately, but they are not associated
    #   with each other. How do you create the association, either in one request or after the
    #   individual requests?
    #
    # @example POST request to create a new sample metadata record
    #   POST /api/v2/sample_metadata/
    #   {
    #     "data": {
    #       "type": "sample_metadata",
    #       "attributes": {
    #         "cohort": "Cohort A",
    #         "collected_by": "Research Lab X",
    #         "concentration": "50",
    #         "donor_id": "D123456",
    #         "gender": "Female",
    #         "sample_common_name": "Homo sapiens",
    #         "sample_description": "Blood sample taken on 2024-01-15",
    #         "supplier_name": "Sample Supplier Y",
    #         "volume": "200"
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SampleMetadataResource < BaseResource
      # NB: `sample_metadata` has been added to `config/initializers/inflections.rb` to correctly
      # pluralize this class name. Without this, Rails would expect `SampleMetadatumResource`.
      #
      # `add_model_hint: true` is set to prevent 500 errors when updating from Limber, as it would
      # otherwise look for `Api::V2::MetadatumResource`.
      model_name 'Sample::Metadata', add_model_hint: true

      ###
      # Attributes
      ###

      # @!attribute [rw] cohort
      #   @return [String] The cohort to which the sample belongs.
      attribute :cohort

      # @!attribute [rw] collected_by
      #   @return [String] The name of the organization or person that collected the sample.
      attribute :collected_by

      # @!attribute [rw] concentration
      #   @return [String] The concentration of the sample, typically measured in ng/µL.
      attribute :concentration

      # @!attribute [rw] donor_id
      #   @return [String] The unique identifier assigned to the sample donor.
      attribute :donor_id

      # @!attribute [rw] gender
      #   @return [String] The gender of the organism providing the sample (e.g., Male, Female, Unknown).
      attribute :gender

      # @!attribute [rw] sample_common_name
      #   @return [String] The common name of the organism from which the sample was derived (e.g., Homo sapiens).
      attribute :sample_common_name

      # @!attribute [rw] sample_description
      #   @return [String] A textual description of the sample.
      attribute :sample_description

      # @!attribute [rw] supplier_name
      #   @return [String] The name of the supplier that provided the sample.
      attribute :supplier_name

      # @!attribute [rw] volume
      #   @return [String] The volume of the sample, typically measured in µL.
      attribute :volume

      ###
      # Filters
      ###

      # @!method filter_sample_id(value)
      #   Filters sample metadata by `sample_id`, allowing users to retrieve metadata for a specific sample.
      #
      #   @example Filtering by sample_id
      #     GET /api/v2/sample_metadata?filter[sample_id]=456
      #
      #   @param value [String] The sample ID to filter by.
      #   @return [SampleMetadataResource] The metadata records matching the given sample ID.
      filter :sample_id
    end
  end
end
