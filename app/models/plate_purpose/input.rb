# Input Plate purposes are the initial stock plates passing into
# external piplines. They have special behaviour governing their state.
class PlatePurpose::Input < PlatePurpose
  include PlatePurpose::Stock

  WELL_STATE_PRIORITY = %w[pending started passed failed cancelled].freeze

  # Unlike other stock purposes
  def calculate_state_of_well(wells_states)
    wells_states.min_by { |state| WELL_STATE_PRIORITY.index(state) || WELL_STATE_PRIORITY.length }
  end
end
