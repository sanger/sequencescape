class IlluminaHtp::DownstreamPlatePurpose < PlatePurpose

  def source_wells_for(stock_wells)
    Well.in_column_major_order.stock_wells_for(stock_wells)
  end

end
