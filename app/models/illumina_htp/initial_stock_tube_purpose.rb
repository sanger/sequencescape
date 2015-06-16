#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class IlluminaHtp::InitialStockTubePurpose < IlluminaHtp::StockTubePurpose

  module InitialTube

    def valid_transition?(outer_request,target_state)
      target_state!='started'||outer_request.pending?
    end

    def transition_to(tube, state, _ = nil, customer_accepts_responsibility = false)
      ActiveRecord::Base.transaction do
        tube.requests_as_target.all(not_terminated).each do |request|
          request.transition_to(state)
          new_outer_state = ['started','passed','qc_complete'].include?(state) ? 'started' : state
          request.outer_request.customer_accepts_responsibility! if customer_accepts_responsibility
          request.outer_request.transition_to(new_outer_state)   if valid_transition?(request.outer_request,new_outer_state)
        end
      end
    end

    def pooling_information(tube)
      {
        :included_requests => outer_requests(tube),
        :expected_requests => submission_requests(tube)
      }
    end

    def outer_requests(tube)
      tube.requests_as_target.map {|rat| rat.outer_request.uuid }
    end

    def submission_requests(tube)
      tube.requests_as_target.first.outer_request.submission_siblings.map(&:uuid)
    end

  end

  include InitialTube

end
