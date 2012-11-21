module PlatePurpose::Stock
  def _pool_wells(wells)
    wells.pooled_as_source_by(Request::LibraryCreation)
  end
  private :_pool_wells

  # The state of a pulldown stock plate is governed by the presence of pulldown requests combined
  # with the aliquots.  Basically every well that has stuff in it should have a pulldown request
  # for the plate to be 'passed', otherwise it is 'pending'.  An empty plate is also considered
  # to be pending.
  def state_of(plate)
    # If there are no wells with aliquots we're pending
    wells_with_aliquots = plate.wells.with_aliquots.all
    return 'pending' if wells_with_aliquots.empty?

    # All of the wells with aliquots must have requests for us to be considered passed
    requests = Request::LibraryCreation.all(:conditions => { :asset_id => wells_with_aliquots.map(&:id) })
    return 'pending' unless requests.size == wells_with_aliquots.size

    case requests.map(&:state).uniq.sort
    when ['failed']             then 'failed'
    when ['cancelled']          then 'cancelled'
    when ['cancelled','failed'] then 'failed'
    else                             'passed'
    end
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
