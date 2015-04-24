#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.
module PlatePurpose::Stock
  def _pool_wells(wells)
    wells.pooled_as_source_by(Request::LibraryCreation)
  end
  private :_pool_wells


  def state_of(plate)
    # If there are no wells with aliquots we're pending
    wells_with_aliquots = plate.wells.with_aliquots.all
    return 'pending' if wells_with_aliquots.empty?

    # All of the wells with aliquots must have requests for us to be considered passed
    requests = Request::LibraryCreation.all(:conditions => { :asset_id => wells_with_aliquots.map(&:id) })

    wells_states = wells_with_aliquots.map do |w|
      calculate_state_of_well(requests.select{|r| r.asset_id == w.id}.map(&:state))
    end

    return 'pending' unless wells_states.count == wells_with_aliquots.count
    return calculate_state_of_plate(wells_states)
  end

  def calculate_state_of_plate(wells_states)
    ## We are aggregating all the wells status information
    case wells_states.uniq.sort
    when ['failed']             then 'failed'
    when ['cancelled']          then 'cancelled'
    when ['cancelled','failed'] then 'failed'
    when ['pending']            then 'pending'
    when []                     then 'pending'
    when ['started']            then 'started'
    when ['passed']             then 'passed'
    else 'pending'
    end
  end

  def calculate_state_of_well(well_requests_states)
    ## We take the assumption that all the requests belong to the same submission.
    case well_requests_states.uniq.sort
      when ['failed']               then return 'failed'
      when ['cancelled']            then return 'cancelled'
      when ['cancelled','failed']   then return 'failed'
      when ['cancelled', 'pending'] then return 'passed'
      when ['cancelled', 'started'] then return 'passed'
      when ['pending', 'pending']   then return 'pending'
      when ['started', 'pending']   then return 'pending'
      when ['passed', 'pending']    then return 'pending'
    end
    'passed' if well_requests_states.count == 1
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
