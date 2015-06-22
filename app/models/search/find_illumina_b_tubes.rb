#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2015 Genome Research Ltd.

require "#{Rails.root.to_s}/app/models/illumina_b/plate_purposes"

class Search::FindIlluminaBTubes < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Tube.include_purpose.
      with_purpose(illumina_b_tube_purposes).
      with_no_outgoing_transfers.
      in_state(criteria['state']).
      without_finished_tubes(illumina_b_final_tube_purpose).
      recent_first
  end

  def self.illumina_b_tube_purposes
    Tube::Purpose.find_all_by_name(IlluminaB::PlatePurposes::TUBE_PURPOSE_FLOWS.flatten)
  end
  delegate :illumina_b_tube_purposes, :to => 'self.class'

  def self.illumina_b_final_tube_purpose
    Tube::Purpose.find_all_by_name(IlluminaB::PlatePurposes::TUBE_PURPOSE_FLOWS.map(&:last))
  end
  delegate :illumina_b_final_tube_purpose, :to => 'self.class'

end
