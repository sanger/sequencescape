class StockMultiplexedLibraryTube < Tube
  include Asset::Stock

  def stock_wells
    purpose.stock_wells(self)
  end

  def created_with_request_options
    parent.created_with_request_options
  end

end
