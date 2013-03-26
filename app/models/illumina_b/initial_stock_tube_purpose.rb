class IlluminaB::InitialStockTubePurpose < IlluminaB::StockTubePurpose

  module InitialTube

    def transition_to(tube, state, _ = nil)
      ActiveRecord::Base.transaction do
        tube.requests_as_target.all(not_terminated).each do |request|
          request.transition_to(state)
          new_outer_state = ['started','passed','qc_complete'].include?(state) ? 'started' : state
          request.outer_request.transition_to(new_outer_state) if request.outer_request.pending?
        end
      end
    end

  end

  include InitialTube

end
