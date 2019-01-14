# frozen_string_literal: true

module Api
  module V2
    class Sample::MetadatumResource < BaseResource
      has_one :sample_common_name
      model_name 'Sample::Metadata'
    end
  end
end
