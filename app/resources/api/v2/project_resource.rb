# frozen_string_literal: true

module Api
  module V2
    class ProjectResource < BaseResource
      immutable # comment to make the resource mutable

      default_includes :uuid_object

      attribute :name
      attribute :cost_code, delegate: :project_cost_code
      attribute :uuid, readonly: true

      # Filters
      filter :name
    end
  end
end
