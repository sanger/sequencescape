# frozen_string_literal: true

module StateChanger
  # This adds an additional started state to input plates, which is used
  # by the input_started plate purpose.
  class InputStartedPlate < InputPlate
    # Target state of labware to state of associated requests.
    # All other transitions will be ignored.
    self.map_target_state_to_associated_request_state = { 'failed' => 'failed', 'passed' => 'started' }

    private

    def associated_requests
      receptacles.flat_map(&:requests_as_source)
    end

    def _receptacles
      labware.wells.includes(:requests_as_source)
    end

    def transfer_requests
      # We don't want to update any transfer requests
      []
    end
  end
end
