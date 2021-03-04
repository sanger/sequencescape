# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of initial stock tubes within the library prep process
  class InitialStockTube < StateChanger::Base
    TERMINATED_STATES = %w[cancelled failed].freeze
    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.
    # @return [Void]
    def update_labware_state
      ActiveRecord::Base.transaction do
        labware.transfer_requests_as_target.where.not(state: TERMINATED_STATES).find_each do |request|
          request.transition_to(target_state)
          next if request.outer_request.blank?
          next if target_state == 'cancelled'

          new_outer_state = %w[started passed qc_complete].include?(target_state) ? 'started' : target_state
          request.outer_request.customer_accepts_responsibility! if customer_accepts_responsibility
          request.outer_request.transition_to(new_outer_state)   if valid_transition?(request.outer_request,
                                                                                      new_outer_state)
        end
      end
    end

    private

    def valid_transition?(outer_request, target_state)
      target_state != 'started' || outer_request.pending?
    end
  end
end
