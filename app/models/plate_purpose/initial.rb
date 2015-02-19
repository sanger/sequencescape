#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.
module PlatePurpose::Initial
  def self.included(base)
    base.class_eval do
      include PlatePurpose::WorksOnLibraryRequests
    end
  end

  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.
  def transition_to(plate, state, contents = nil, customer_accepts_responsibility = false)
    super
    start_pulldown_library_requests(plate)
  end

  # Ensure that the pulldown library creation request is started
  def start_pulldown_library_requests(plate)
    each_well_and_its_library_request(plate) do |_, request|
      request.start! if request.pending?
    end
  end
  private :start_pulldown_library_requests
end
