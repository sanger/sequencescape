# frozen_string_literal: true

module StateChanger
  # Shared behaviour for tubes
  # @abstract This class should not be used directly. Subclasses should at least implement {update_associated_requests}
  class TubeBase < StateChanger::Base
    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.
    # @return [Void]
    def update_labware_state
      update_associated_requests if associated_request_target_state
      update_transfer_requests
    end

    private

    def update_associated_requests
      raise NotImplementedError
    end

    def update_transfer_requests
      transfer_requests.each { |request| request.transition_to(target_state) }
    end
  end
end
