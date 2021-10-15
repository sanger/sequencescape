# frozen_string_literal: true
module Api
  module V2
    # SampleMetadataResource
    class SampleCompoundComponentResource < BaseResource
      attribute :asset_id
      attribute :target_asset_id
      attribute :compound_sample_id
      attribute :component_sample_id
      
      filter :target_asset_id
    end
  end
end