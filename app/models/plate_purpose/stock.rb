#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.
module PlatePurpose::Stock
  def _pool_wells(wells)
    wells.pooled_as_source_by(Request::LibraryCreation)
  end
  private :_pool_wells

  def state_of(plate)
    submissions = plate.wells.map(&:requests).flatten.map(&:submission).uniq
    state_by_submissions = submissions.map {|s| state_by_submission(plate, s)}.uniq.sort

    # When there is just one submission
    return state_by_submissions.first if (state_by_submissions.length == 1)

    # When there is a list in which all are cancelled submissions except one submission that it
    # is in another state
    state_by_submissions_ignoring_cancelled = state_by_submissions.reject{|s| s=='cancelled'}
    if (state_by_submissions_ignoring_cancelled.length == 1)
      case state_by_submissions_ignoring_cancelled
      when ['pending'] then return 'passed'
      when ['started'] then return 'passed'
      else return state_by_submissions_ignoring_cancelled.first
      end
    end

    # When there is a list of submissions with different states.
    # Could be ['pending', 'pending'], or ['started', 'pending']
    return 'pending'
  end

  # The state of a pulldown stock plate is governed by the presence of pulldown requests combined
  # with the aliquots.  Basically every well that has stuff in it should have a pulldown request
  # for the plate to be 'passed', otherwise it is 'pending'.  An empty plate is also considered
  # to be pending.
  def state_by_submission(plate, submission)
    # If there are no wells with aliquots we're pending
    wells_with_aliquots = plate.wells.with_aliquots.all
    return 'pending' if wells_with_aliquots.empty?

    # All of the wells with aliquots must have requests for us to be considered passed
    requests = Request::LibraryCreation.all(:conditions => {
      :asset_id => wells_with_aliquots.map(&:id),
      :submission_id => submission.id })

    return 'pending' unless requests.count == wells_with_aliquots.count

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
