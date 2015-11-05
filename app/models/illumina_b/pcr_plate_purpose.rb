#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2015 Genome Research Ltd.
class IlluminaB::PcrPlatePurpose < PlatePurpose
  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility=false)
    nudge_parent_plate(plate, state, user, contents)
    default_transition_to(plate, state, user, contents, customer_accepts_responsibility)
  end

  def nudge_parent_plate(plate, state, user, contents)
    case state
    when 'started_fx' then plate.parent.transition_to('started', user, contents)
    when 'started_mj' then plate.parent.transition_to('passed',  user, contents)
    end
  end
  private :nudge_parent_plate
end
