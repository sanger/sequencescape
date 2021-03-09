# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of initial stock tubes within the library prep process
  class InitialStockTube < StateChanger::TubeBase
    TERMINATED_STATES = %w[cancelled failed].freeze

    def update_associated_requests
      return if target_state == 'cancelled'

      associated_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(associated_request_target_state) if valid_transition?(request)
      end
    end

    private

    def transfer_requests
      @transfer_requests ||= labware.transfer_requests_as_target
                                    .where.not(state: TERMINATED_STATES)
    end

    def associated_requests
      transfer_requests.filter_map do |transfer_request|
        next if transfer_request.outer_request.blank?

        transfer_request.outer_request
      end
    end

    def associated_request_target_state
      %w[started passed qc_complete].include?(target_state) ? 'started' : target_state
    end

    def valid_transition?(outer_request)
      associated_request_target_state != 'started' || outer_request.pending?
    end
  end
end
