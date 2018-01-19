# frozen_string_literal: true

module Api
  module V2
    class StudyResource < BaseResource
      immutable

      attribute :name
      attribute :uuid

      filter :state, apply: lambda { |records, value, _options|
        records.by_state(value)
      }

      filter :user, apply: lambda { |records, value, _options|
        records.by_user(value)
      }
    end
  end
end
