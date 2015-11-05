#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015 Genome Research Ltd.
class IlluminaHtp::InitialDownstreamPlatePurpose < IlluminaHtp::DownstreamPlatePurpose
  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      super
      new_outer_state = ['started','passed','qc_complete','nx_in_progress'].include?(state) ? 'started' : state

      # CAUTION!
      # TODO: While the behaviour here wont cause us any issues, its actually subtly wrong.
      # 1) Multiple wells on the same plate may have the same stock wells
      # 2) Well location may change between parent and child plates.
      # 3) As we only fire on pending requests this isn't actually a massive problem as we'll be targeting the whole plate anyway
      active_submissions = plate.submission_ids

      stock_wells(plate,contents).each do |source_well|
        # Only transitions from last submission
        source_well.requests.select {|r| r.library_creation? && active_submissions.include?(r.submission_id) }.each do |request|
          request.transition_to(new_outer_state) if request.pending?
        end
      end
    end
  end

  def stock_wells(plate,contents)
    return plate.parent.wells unless contents.present?
    plate.parent.wells.located_at(contents)
  end

end
