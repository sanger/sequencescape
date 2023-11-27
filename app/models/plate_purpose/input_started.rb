# frozen_string_literal: true

# Input Plate purposes are the initial stock plates passing into
# external piplines. They have special behaviour governing their state.
# This essentially makes sure that all non-empty wells on a plate have requests
# out of them. This is intended to ensure that submissions have been
# correctly built before a plate has processed.
#
# - Input plates are progressed when all sample containing wells have requests out of them
#
# This version of the input class sets the state as started rather than passed.
class PlatePurpose::InputStarted < PlatePurpose::Input
  self.state_changer = StateChanger::InputStartedPlate

  UNREADY_STATE = 'pending'
  PREP_STATE = 'started'
  READY_STATE = 'passed'

  private

  # TODO: for some reason this private method needs to be here despite being a copy of
  # the parent class method, otherwise the READY_STATE constant above isn't used over the
  # one in the parent class.
  def calculate_state_of_plate(wells_states)
    unique_states = wells_states.uniq
    return UNREADY_STATE if unique_states.include?(:unready)

    case unique_states.sort
    when ['failed'], %w[cancelled failed]
      'failed'
    when ['cancelled']
      'cancelled'
    else
      if unique_states.all?('pending')
        PREP_STATE
      else
        READY_STATE
      end
    end
  end
end
