# frozen_string_literal: true

module Api
  module V2
    # SampleMetadataResource
    class SampleMetadataResource < BaseResource
      attribute :sample_common_name
      model_name 'Sample::Metadata', add_model_hint: false
    end
  end
end
