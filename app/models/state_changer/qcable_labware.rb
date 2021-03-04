# frozen_string_literal: true

module StateChanger
  # State on Labware associated with Qcables (such as unused tag plates)
  # delegates their state back to the Qcable itself. Thus when the tag
  # plate is exhausted, we record this against the QCable
  class QcableLabware < StateChanger::Base
    # Updates the state of the qcable associated with the labware to the target state.
    # @return [Void]
    def update_labware_state
      qcable.transition_to(target_state)
    end

    private

    def qcable
      Qcable.find_by(asset_id: labware)
    end
  end
end
