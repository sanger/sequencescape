# frozen_string_literal: true

module Api
  module V2
    class StateChangeResource < BaseResource
      immutable # comment to make the resource mutable

      attribute :previous_state
      attribute :target_state
      attribute :created_at
      attribute :updated_at

      has_one :labware
    end
  end
end
