# frozen_string_literal: true

module Api
  module V2
    class SampleResource < BaseResource
      immutable

      default_includes :uuid_object

      has_one :sample_metadata

      attribute :name
      attribute :sanger_sample_id
      attribute :uuid
    end
  end
end
