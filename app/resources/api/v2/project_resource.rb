# frozen_string_literal: true

module Api
  module V2
    class ProjectResource < BaseResource
      immutable

      default_includes :uuid_object

      attribute :name
      attribute :cost_code, delegate: :project_cost_code
      attribute :uuid, readonly: true
    end
  end
end
