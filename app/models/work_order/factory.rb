# frozen_string_literal: true

class WorkOrder
  # Builds work orders for a given submission
  # Currently only supports single request type submissions.
  class Factory
    include ActiveModel::Validations

    attr_reader :submission

    validates :number_of_request_types, numericality: { equal_to: 1 }

    delegate :requests, to: :submission

    def initialize(submission)
      @submission = submission
    end

    def create_work_orders!
      requests
        .group_by(&:asset_id)
        .map do |_asset_id, requests|
          state = requests.first.state
          WorkOrder.create!(work_order_type:, requests:, state:)
        end
    end

    private

    def number_of_request_types
      requests.map(&:request_type_id).uniq.count
    end

    def work_order_type
      @work_order_type ||= WorkOrderType.find_or_create_by!(name: requests.first.request_type.key)
    end
  end
end
