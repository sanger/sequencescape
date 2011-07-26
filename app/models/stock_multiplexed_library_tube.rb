class StockMultiplexedLibraryTube < Tube
  include Asset::Stock

  # A multiplexed library tube is created with the request options of it's parent library tubes.  In effect
  # all of the parent library tubes have the same details, we only need take the first one.
  delegate :created_with_request_options, :to => 'parents.first'
end
