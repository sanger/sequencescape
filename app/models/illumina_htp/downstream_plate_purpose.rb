class IlluminaHtp::DownstreamPlatePurpose < PlatePurpose
  def source_wells_for(stock_wells)
    Well.in_column_major_order.stock_wells_for(stock_wells)
  end

  def library_source_plates(plate)
    super.map(&:source_plates).flatten.uniq
  end

  def library_source_plate(plate)
    super.source_plate
  end
end
