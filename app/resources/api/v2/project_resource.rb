# frozen_string_literal: true

module Api
  module V2
    class ProjectResource < JSONAPI::Resource
      immutable

      attribute :name
      attribute :cost_code, delegate: :project_cost_code
      attribute :uuid
    end
  end
end
