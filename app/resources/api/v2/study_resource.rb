# frozen_string_literal: true

module Api
  module V2
    class StudyResource < BaseResource
      immutable # comment to make the resource mutable

      attribute :name
      attribute :uuid

      has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'

      filter :name

      filter :state, apply: lambda { |records, value, _options| records.by_state(value) }

      filter :user, apply: lambda { |records, value, _options| records.by_user(value) }
    end
  end
end
