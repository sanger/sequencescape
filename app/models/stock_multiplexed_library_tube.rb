class StockMultiplexedLibraryTube < Asset
  include LocationAssociation::Locatable
  def is_a_pool?
    true
  end
  
  def has_stock_asset?
    false
  end
  
  def is_a_stock_asset?
    true
  end

  # A multiplexed library tube is created with the request options of it's parent library tubes.  In effect
  # all of the parent library tubes have the same details, we only need take the first one.
  delegate :created_with_request_options, :to => 'parents.first'
end
