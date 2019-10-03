require_dependency 'tube/purpose'

# Purposes of this class represent multiplexed library tubes in the high-throughput
# pipeline. These tubes represent the cleaned-up normalized libraries at the end
# of the process that can pass directly into a {SequencingPipeline}.
# State changes on these tubes will automatically update the requests into the tubes
# @note Most current activity is on subclasses of this purpose, especially IlluminaHtp::MxTubeNoQcPurpose
#       As of 2019-10-01 only used directly by 'Lib Pool Norm' and 'Lib Pool SS-XP-Norm' which haven't been
#       used since 2017-04-28 14:16:03 +0100
class IlluminaHtp::MxTubePurpose < Tube::Purpose
  # Called via Tube#transition_to
  # Updates the state of tube to state
  # @param tube [Tube] The tube being updated
  # @param state [String] The desired target state
  # @param user [User] Provided for interface compatibility (The user performing the action)
  # @param _ [nil, Array] Provided for interface compatibility
  # @param customer_accepts_responsibility [Boolean] The customer has proceeded against
  #                                                  advice and will be charged for failures
  #
  # @return [Void]
  def transition_to(tube, state, user, _ = nil, customer_accepts_responsibility = false)
    transition_customer_requests(tube, mappings[state], user, customer_accepts_responsibility) if mappings[state]
    tube.transfer_requests_as_target.each { |request| request.transition_to(state) }
  end

  def transition_customer_requests(tube, state, user, customer_accepts_responsibility)
    orders = Set.new
    customer_requests(tube).each do |request|
      request.customer_accepts_responsibility! if customer_accepts_responsibility
      request.transition_to(state)
      orders << request.order.id
    end
    generate_events_for(tube, orders, user) if state == 'passed'
  end

  def customer_requests(tube)
    tube.requests_as_target.for_billing.where(state: Request::Statemachine::OPENED_STATE)
  end

  def stock_plate(tube)
    tube.requests_as_target.where.not(requests: { asset_id: nil }).first&.asset&.plate
  end

  def source_plate(tube)
    super || source_plate_scope(tube).first
  end

  def library_source_plates(tube)
    source_plate_scope(tube).map(&:source_plate)
  end

  def source_plate_scope(tube)
    Plate
      .joins(wells: :requests)
      .where(requests: {
               target_asset_id: tube.id,
               sti_type: [Request::Multiplexing, Request::AutoMultiplexing, Request::LibraryCreation, *Request::LibraryCreation.descendants].map(&:name)
             }).distinct
  end

  def mappings
    { 'cancelled' => 'cancelled', 'failed' => 'failed', 'qc_complete' => 'passed' }
  end
  private :mappings

  def generate_events_for(tube, orders, user)
    orders.each do |order_id|
      BroadcastEvent::LibraryComplete.create!(seed: tube, user: user, properties: { order_id: order_id })
    end
  end
  private :generate_events_for
end
require_dependency 'illumina_c/mx_tube_purpose'
require_dependency 'illumina_b/mx_tube_purpose'
require_dependency 'illumina_htp/mx_tube_no_qc_purpose'
