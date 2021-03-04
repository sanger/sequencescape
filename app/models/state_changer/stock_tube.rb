# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of stock tubes within the library prep process
  class StockTube < StateChanger::Base
    TERMINATED_STATES = %w[cancelled failed].freeze
    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.
    # @return [Void]
    def update_labware_state
      tube.transfer_requests_as_target.where.not(state: TERMINATED_STATES).find_each do |request|
        request.transition_to(target_state)
      end

      return unless TERMINATED_STATES.include?(target_state)

      outer_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(target_state)
      end
    end

    private

    # TODO: This is a migration of the current logic, but this is not correct!
    # * It assumes the tube is already fully pooled (which to be fair, will eb valid given)
    # * It fails the LibraryCompletion but these aren't used any more!
    def outer_requests_for
      labware.requests_as_target.map do |r|
        r.submission.requests.where_is_a(LibraryCompletion)
      end.uniq
    end
  end
end
