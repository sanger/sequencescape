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
    full_wells_with_requests = plate.wells.requests_as_source_is_a?(Request::LibraryCreation).count(:conditions => { :id => wells_with_aliquots.map(&:id) })
    full_wells_with_requests == wells_with_aliquots.size ? 'passed' : 'pending'
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
