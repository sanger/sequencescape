# frozen_string_literal: true

module Api
  module V2
    # SampleMetadataResource
    class SampleMetadataResource < BaseResource
      attribute :sample_common_name
      attribute :supplier_name
      attribute :collected_by
      attribute :cohort
      attribute :sample_description
      attribute :donor_id

      # set add_model_hint true to allow updates from Limber, otherwise get a
      # 500 error as it looks for resource Api::V2::MetadatumResource
      model_name 'Sample::Metadata', add_model_hint: true

      # Filters
      filter :sample_id
    end
  end
end
