# frozen_string_literal: true

module Api
  module V2
    # SampleMetadataResource
    class SampleMetadataResource < BaseResource
      # Set add_model_hint true to allow updates from Limber, otherwise get a
      # 500 error as it looks for resource Api::V2::MetadatumResource
      model_name 'Sample::Metadata', add_model_hint: true

      ###
      # Attributes
      ###

      # @!attribute [rw]
      # @return [String] The sample cohort.
      attribute :cohort

      # @!attribute [rw]
      # @return [String] The name of the body collecting the sample.
      attribute :collected_by

      # @!attribute [rw]
      # @return [String] The sample concentration.
      attribute :concentration

      # @!attribute [rw]
      # @return [String] The ID of the sample donor.
      attribute :donor_id

      # @!attribute [rw]
      # @return [String] The gender of the organism providing the sample.
      attribute :gender

      # @!attribute [rw]
      # @return [String] The common name for the sample.
      attribute :sample_common_name

      # @!attribute [rw]
      # @return [String] A description of the sample.
      attribute :sample_description

      # @!attribute [rw]
      # @return [String] The supplier name for the sample.
      attribute :supplier_name

      # @!attribute [rw]
      # @return [String] The volume of the sample.
      attribute :volume

      ###
      # Filters
      ###

      filter :sample_id
    end
  end
end
