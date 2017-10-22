# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

require "#{Rails.root}/app/models/illumina_c/plate_purposes"

class Search::FindIlluminaCTubes < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Tube.include_purpose.with_purpose(illumina_c_tube_purposes).with_no_outgoing_transfers.in_state(criteria['state']).without_finished_tubes(illumina_c_final_tube_purpose)
  end

  def self.illumina_c_tube_purposes
    Tube::Purpose.where(name:
      IlluminaC::PlatePurposes::TUBE_PURPOSE_FLOWS.flatten)
  end
  delegate :illumina_c_tube_purposes, to: 'self.class'

  def self.illumina_c_final_tube_purpose
    Tube::Purpose.where(name:
      IlluminaC::PlatePurposes::TUBE_PURPOSE_FLOWS.map(&:last))
  end
  delegate :illumina_c_final_tube_purpose, to: 'self.class'
end
