# frozen_string_literal: true

module Api
  module V2
    class SampleResource < JSONAPI::Resource
      attribute :name
      attribute :sanger_sample_id
    end
  end
end
