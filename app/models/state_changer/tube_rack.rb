# frozen_string_literal: true
module StateChanger
  # Handles the basic transitions of a tube rack
  class TubeRack < StateChanger::Base
    def update_labware_state
      ActiveRecord::Base.transaction do
        labware.racked_tubes.each do |racked_tube|
          process_in_progress_requests(racked_tube)
          process_transfer_requests(racked_tube)
        end
      end
    end

    private

    def process_in_progress_requests(racked_tube)
      racked_tube
        .tube
        .in_progress_requests
        .where.not(state: ['passed'])
        .find_each do |request|
          request.customer_accepts_responsibility! if customer_accepts_responsibility
          request.transition_to(target_state)
        end
    end

    def process_transfer_requests(racked_tube)
      racked_tube
        .tube
        .transfer_requests_as_target
        .where.not(state: ['failed'])
        .find_each { |request| request.transition_to(target_state) }
    end
  end
end
