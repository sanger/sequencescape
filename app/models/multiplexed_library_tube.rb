class MultiplexedLibraryTube < Tube
  include ModelExtensions::MultiplexedLibraryTube
  include Api::MultiplexedLibraryTubeIO::Extensions
  include Transfer::Associations

  # Default states for MX library tubes is pending, always.
  def default_state
    'pending'
  end

  # Transfer requests into a tube are direct requests where the tube is the target.
  def transfer_requests
    requests_as_target.where_is_a?(TransferRequest).all
  end

  STATE_TO_STATEMACHINE_EVENT = { 'started' => 'start!', 'passed' => 'pass!', 'failed' => 'fail!', 'cancelled' => 'cancel!' }

  # Transitioning an MX library tube to a state involves updating the state of the transfer requests.  If the
  # state is anything but "started" or "pending" then the pulldown library creation request should also be
  # set to the same state
  def transition_to(state, _ = nil)
    update_all_requests = ![ 'started', 'pending' ].include?(state)
    event               = STATE_TO_STATEMACHINE_EVENT[state] or raise StandardError, "Illegal state #{state.inspect}"
    requests_as_target.open.each do |request|
      request.send(event) if update_all_requests or request.is_a?(TransferRequest)
    end
  end

  # A multiplexed library tube is created with the request options of it's parent library tubes.  In effect
  # all of the parent library tubes have the same details, we only need take the first one.
  delegate :created_with_request_options, :to => 'parents.first'

  # You can do sequencing with this asset type, even though the request types suggest otherwise!
  def is_sequenceable?
    true
  end

  # Returns the type of asset that can be considered appropriate for request types.
  def asset_type_for_request_types
    LibraryTube
  end

  def self.stock_asset_type
    StockMultiplexedLibraryTube
  end

  extend Asset::Stock::CanCreateStockAsset
end
