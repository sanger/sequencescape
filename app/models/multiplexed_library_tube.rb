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

  # Transitioning an MX library tube to a state involves updating the state of the transfer requests.  If the
  # state is anything but "started" or "pending" then the pulldown library creation request should also be
  # set to the same state
  def transition_to(state)
    update_all_requests = ![ 'started', 'pending' ].include?(state)
    requests_as_target.each do |request|
      request.update_attributes!(:state => state) if update_all_requests or request.is_a?(TransferRequest)
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

  has_one_as_child(:stock_asset, :conditions => { :sti_type => 'StockMultiplexedLibraryTube' })

  def is_a_stock_asset?
    false
  end

  def create_stock_asset!(attributes = {}, &block)
    StockMultiplexedLibraryTube.create!(attributes.reverse_merge(:name => "(s) #{self.name}", :barcode => AssetBarcode.new_barcode), &block).tap do |stock_asset|
      stock_asset.aliquots = aliquots.map(&:clone)
    end
  end

  def new_stock_asset
    stock = StockMultiplexedLibraryTube.new(:name => "(s) #{self.name}", :barcode => AssetBarcode.new_barcode)
  end
  deprecate :new_stock_asset
end
