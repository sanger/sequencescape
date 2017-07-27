# frozen_string_literal: true

module Api
  module V2
    class StudyResource < BaseResource
      immutable

      attribute :name
      attribute :uuid
    end
  end
end
