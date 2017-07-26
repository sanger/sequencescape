# frozen_string_literal: true

module Api
  module V2
    class SampleResource < JSONAPI::Resource
      immutable

      attribute :name
      attribute :sanger_sample_id
      attribute :uuid

      def self.apply_includes(records, options = {})
        super.includes(:uuid_object)
      end
    end
  end
end
