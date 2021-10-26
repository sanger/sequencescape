# frozen_string_literal: true

module Api
  module V2
    # SampleResource
    class SampleResource < BaseResource
      immutable # comment to make the resource mutable

      default_includes :uuid_object

      has_one :sample_metadata, class_name: 'SampleMetadata', foreign_key_on: :related
      has_one :sample_manifest

      has_many :component_samples

      attribute :name
      attribute :sanger_sample_id
      attribute :uuid
      attribute :control
      attribute :control_type

      filter :uuid
      filter :sanger_sample_id
      filter :name
    end
  end
end
