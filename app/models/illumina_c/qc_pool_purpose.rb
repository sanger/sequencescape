#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class IlluminaC::QcPoolPurpose < Tube::Purpose

  def transition_to(tube, state, _ = nil, customer_accepts_responsibility=false)
    ActiveRecord::Base.transaction do
      tube.requests_as_target.all(not_terminated).each do |request|
        request.transition_to(state)
      end
    end
  end

  def not_terminated
    {:conditions=>[ 'state NOT IN (?)',['cancelled','failed','aborted']]}
  end
  private :not_terminated

end
