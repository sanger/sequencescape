# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class IlluminaC::QcPoolPurpose < Tube::Purpose
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      tube.requests_as_target.where.not(state: terminated_states).find_each do |request|
        request.transition_to(state)
      end
    end
  end

  def terminated_states
    ['cancelled', 'failed']
  end
  private :terminated_states
end
