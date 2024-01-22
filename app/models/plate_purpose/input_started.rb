# frozen_string_literal: true

# Input Plate purposes are the initial stock plates passing into
# external piplines. They have special behaviour governing their state.
# This essentially makes sure that all non-empty wells on a plate have requests
# out of them. This is intended to ensure that submissions have been
# correctly built before a plate has processed.
#
# - Input plates are progressed when all sample containing wells have requests out of them
#
# This version of the input class sets the state as started rather than passed and allows
# the user to fail wells.
class PlatePurpose::InputStarted < PlatePurpose::Input
  self.state_changer = StateChanger::InputStartedPlate

  # Flag to indicate whether this purpose is an input plate on which the user can fail wells.
  self.has_failable_input_receptacles = true

  # States for labware
  LABWARE_UNREADY_STATE = 'pending'
  LABWARE_PREP_STATE = 'started'
  LABWARE_READY_STATE = 'passed'

  # States for receptacles
  RECEPTACLE_STATE_UNKNOWN = 'unknown'
  RECEPTACLE_STATE_READY = 'passed'

  # For an input plate that has no transfer requests as target, we need to check the state
  # of the customer request for the receptacle (well) to determine the state.
  def state_for_receptacle(receptacle)
    # Filtering for wells that do not contain aliquots
    return RECEPTACLE_STATE_UNKNOWN if receptacle.aliquots.blank?

    # Filtering to CustomerRequests only
    # Assumption: latest customer request is the one we want
    latest_request_state = receptacle.requests.where(sti_type: 'CustomerRequest').last&.state || 'unknown'

    return latest_request_state if latest_request_state.in?(%w[failed cancelled unknown])

    # other states i.e. 'started', 'qc_complete', 'pending', or 'passed'
    RECEPTACLE_STATE_READY
  end

  private

  # The state of the plate is determined by the state of the wells
  # In this version we add an extra state LABWARE_PREP_STATE
  def calculate_state_of_plate(wells_states)
    unique_states = wells_states.uniq
    return LABWARE_UNREADY_STATE if unique_states.include?(:unready)

    case unique_states.sort
    when ['failed'], %w[cancelled failed]
      'failed'
    when ['cancelled']
      'cancelled'
    else
      unique_states.all?('pending') ? LABWARE_PREP_STATE : LABWARE_READY_STATE
    end
  end
end
