#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015 Genome Research Ltd.
class IlluminaHtp::FinalPlatePurpose < PlatePurpose
  include PlatePurpose::Library

  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, user, contents = nil,customer_accepts_responsibility=false)
    nudge_pre_pcr_wells(plate, state, user, contents,customer_accepts_responsibility)
    default_transition_to(plate, state, user, contents,customer_accepts_responsibility)
  end

  def attatched?(plate)
    plate.state == ('qc_complete')
  end

  def fail_stock_well_requests(wells,_)
    # Handled by the nudge of the pre PCR wells!
  end
  private :fail_stock_well_requests

  def nudge_pre_pcr_wells(plate, state, user, contents,customer_accepts_responsibility)
    plate.parent.parent.transition_to(state, user, contents,customer_accepts_responsibility) if state == 'failed'
  end
  private :nudge_pre_pcr_wells
end
