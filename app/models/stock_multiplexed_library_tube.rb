class StockMultiplexedLibraryTube < Tube
  include Asset::Stock

  def stock_wells
    purpose.stock_wells(self)
  end

end
