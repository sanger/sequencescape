# frozen_string_literal: true

module PlatePurpose::Stock
  UNREADY_STATE  = 'pending'
  READY_STATE    = 'passed'

  def state_of(plate)
    # If there are no wells with aliquots we're pending
    ids_of_wells_with_aliquots = plate.wells.with_aliquots.ids
    return UNREADY_STATE if ids_of_wells_with_aliquots.empty?

    # All of the wells with aliquots must have customer requests for us to consider the plate passed
    well_requests = CustomerRequest.where(asset_id: ids_of_wells_with_aliquots)

    wells_states = well_requests.group_by(&:asset_id).values.map do |requests|
      calculate_state_of_well(requests.map(&:state))
    end

    return UNREADY_STATE unless wells_states.count == ids_of_wells_with_aliquots.count

    calculate_state_of_plate(wells_states)
  end

  private

  def calculate_state_of_plate(wells_states)
    unique_states = wells_states.uniq
    return UNREADY_STATE if unique_states.include?(:unready)

    case unique_states.sort
    when ['failed'] then 'failed'
    when ['cancelled'] then 'cancelled'
    when %w[cancelled failed] then 'failed'
    else READY_STATE
    end
  end

  def calculate_state_of_well(_states)
    raise StandardError, "#{self.class.name} should implement #calculate_state_of_well"
  end

  def _pool_wells(wells)
    wells.pooled_as_source_by(Request::LibraryCreation)
  end

  def transition_state_requests(*args)
    # Does nothing, we'll do it in a moment!
  end

  # The requests that we're going to be failing are based on the requests coming out of the
  # wells, and the wells themselves, for stock plates.
  def fail_request_details_for(wells)
    wells.each do |well|
      submission_ids = well.requests_as_source.map(&:submission_id)
      yield(submission_ids, [well.id]) unless submission_ids.empty?
    end
  end
end
