# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the high throughput multiplexed library tube
  class MxTubeNoQc < StateChanger::MxTube
    private

    def customer_request_target_state
      { 'cancelled' => 'cancelled', 'failed' => 'failed', 'passed' => 'passed' }[target_state]
    end
  end
end
