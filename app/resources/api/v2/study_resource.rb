# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Study
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class StudyResource < BaseResource
      immutable # comment to make the resource mutable

      attribute :name
      attribute :uuid

      filter :name

      filter :state, apply: lambda { |records, value, _options| records.by_state(value) }

      filter :user, apply: lambda { |records, value, _options| records.by_user(value) }
    end
  end
end
