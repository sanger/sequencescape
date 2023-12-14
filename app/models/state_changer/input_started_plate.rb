# frozen_string_literal: true

module StateChanger
  # This adds an additional started state to input plates
  class InputStartedPlate < InputPlate
    # Maps target state of the labware to the state of associated requests.
    # When the labware is failed the associated requests will be failed.
    # When the labware is passed the associated requests will be started.
    # All other transitions will be ignored.
    self.map_target_state_to_associated_request_state = { 'failed' => 'failed', 'passed' => 'started' }
  end
end
