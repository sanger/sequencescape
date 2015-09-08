#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014,2015 Genome Research Ltd.
class IlluminaHtp::MxTubePurpose < Tube::Purpose
  def created_with_request_options(tube)
    tube.requests_as_target.where_is_a?(Request::LibraryCreation).first.try(:request_options_for_creation) || {}
  end

  def transition_to(tube, state, user, _ = nil, customer_accepts_responsibility = false)
    target_requests(tube).each do |request|
      request.customer_accepts_responsibility! if customer_accepts_responsibility
      to_state = request_state(request,state)
      request.transition_to(to_state) unless to_state.nil?
    end
  end

  def target_requests(tube)
    tube.requests_as_target.for_billing.all(
      :conditions=>[
        "state IN (?) OR (state='passed' AND sti_type IN (?))",
        Request::Statemachine::OPENED_STATE,
        Class.subclasses_of(TransferRequest).map(&:to_s)
      ])
  end
  private :target_requests

  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(Request::LibraryCreation).detect{|r| r.asset.present?} .asset.plate
  end

  def request_state(request,state)
    request.is_a?(TransferRequest) ? state : mappings[state]
  end
  private :request_state

  def mappings
    {'cancelled' =>'cancelled','failed' => 'failed','qc_complete' => 'passed'}
  end
  private :mappings

end
