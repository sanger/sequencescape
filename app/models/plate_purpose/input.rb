# Input Plate purposes are the initial stock plates passing into
# external piplines. They have special behaviour governing their state.
# This essentially makes sure that all non-empty wells on a plate have requests
# out of them before the plate it 'passed'. This is intended to ensure that submissions
# have been correctly built before a plate has processed.
#
# - Input plates are passed when all sample containing wells have requests out of them
#
# @note Limber should probably make decisions about plate state itself. This would increase
#       flexibility, such as by allowing library-manifest plates to pass straight in to the
#       pipeline.
class PlatePurpose::Input < PlatePurpose
  include PlatePurpose::Stock

  WELL_STATE_PRIORITY = %w[pending started passed failed cancelled].freeze

  # Unlike other stock purposes
  def calculate_state_of_well(wells_states)
    wells_states.min_by { |state| WELL_STATE_PRIORITY.index(state) || WELL_STATE_PRIORITY.length }
  end
end
