# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

# Pre_PCR plates will remain 'started; until the run is complete.

class Search::FindOutstandingIlluminaBPrePcrPlates < Search
  def scope(_criteria)
    Plate.include_plate_metadata.include_plate_purpose.with_plate_purpose(pre_pcr_plate_purpose).in_state(['pending', 'started'])
  end

  def self.pre_pcr_plate_purpose
    PlatePurpose.find_by(name: 'ILB_STD_PREPCR')
  end
  delegate :pre_pcr_plate_purpose, to: 'self.class'
end
