#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013 Genome Research Ltd.
module Tasks
  module PlatePurposeBehavior
    # Returns a list of valid plate purpose types based on the requests in the current batch.
    def plate_purpose_options(batch)
      requests       = batch.requests.map { |r| r.submission ? r.submission.next_requests(r) : [] }.flatten
      plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
      plate_purposes = PlatePurpose.cherrypickable_as_target.all if plate_purposes.empty?  # Fallback situation for the moment
      plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
    end
  end
end
