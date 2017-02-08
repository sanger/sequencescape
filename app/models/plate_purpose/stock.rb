# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

module PlatePurpose::Stock
  def _pool_wells(wells)
    wells.pooled_as_source_by(Request::LibraryCreation)
  end
  private :_pool_wells

  UNREADY_STATE      = 'pending'
  READY_STATE        = 'passed'

  def state_of(plate)
    # If there are no wells with aliquots we're pending
    ids_of_wells_with_aliquots = plate.wells.with_aliquots.pluck(:id)
    return UNREADY_STATE if ids_of_wells_with_aliquots.empty?

    # All of the wells with aliquots must have requests for us to be considered passed
    well_requests = Request::LibraryCreation.where(asset_id: ids_of_wells_with_aliquots)

    wells_states = well_requests.group_by(&:asset_id).map do |_well_id, requests|
      calculate_state_of_well(requests.map(&:state))
    end

    return UNREADY_STATE unless wells_states.count == ids_of_wells_with_aliquots.count
    calculate_state_of_plate(wells_states)
  end

  def calculate_state_of_plate(wells_states)
    unique_states = wells_states.uniq
    return UNREADY_STATE if unique_states.include?(:unready)
    case unique_states.sort
     when ['failed'] then 'failed'
     when ['cancelled'] then 'cancelled'
     when ['cancelled', 'failed'] then 'failed'
     else READY_STATE
    end
  end

  def calculate_state_of_well(wells_states)
    cancelled = wells_states.delete('cancelled') if wells_states.count > 1
    return wells_states.first if wells_states.one?
    return :unready if wells_states.size > 1
    cancelled || :unready
  end

  def transition_state_requests(*args)
    # Does nothing, we'll do it in a moment!
  end
  private :transition_state_requests

  # The requests that we're going to be failing are based on the requests coming out of the
  # wells, and the wells themselves, for stock plates.
  def fail_request_details_for(wells)
    wells.each do |well|
      submission_ids = well.requests_as_source.map(&:submission_id)
      yield(submission_ids, [well.id]) unless submission_ids.empty?
    end
  end
  private :fail_request_details_for
end
