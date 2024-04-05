# frozen_string_literal: true

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
  self.state_changer = StateChanger::InputPlate

  UNREADY_STATE = 'pending'
  READY_STATE = 'passed'
  WELL_STATE_PRIORITY = %w[pending started passed failed cancelled].freeze

  def state_of(plate)
    # If there are no wells with aliquots we're pending
    ids_of_wells_with_aliquots = plate.wells.with_aliquots.ids.uniq
    return UNREADY_STATE if ids_of_wells_with_aliquots.empty?

    # All of the wells with aliquots must have customer requests for us to consider the plate passed
    well_requests = CustomerRequest.where(asset_id: ids_of_wells_with_aliquots)

    wells_states =
      well_requests.group_by(&:asset_id).values.map { |requests| calculate_state_of_well(requests.map(&:state)) }

    return UNREADY_STATE unless wells_states.count == ids_of_wells_with_aliquots.count

    calculate_state_of_plate(wells_states)
  end

  private

  def calculate_state_of_plate(wells_states)
    unique_states = wells_states.uniq
    return UNREADY_STATE if unique_states.include?(:unready)

    case unique_states.sort
    when ['failed'], %w[cancelled failed]
      'failed'
    when ['cancelled']
      'cancelled'
    else
      READY_STATE
    end
  end

  def _pool_wells(wells)
    wells.pooled_as_source_by(Request::LibraryCreation)
  end

  # Unlike other stock purposes
  def calculate_state_of_well(wells_states)
    wells_states.min_by { |state| WELL_STATE_PRIORITY.index(state) || WELL_STATE_PRIORITY.length }
  end
end
