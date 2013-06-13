class Search::FindIlluminaAStockPlates < Search::FindIlluminaAPlates
  def illumina_a_plate_purposes
    PlatePurpose.find_all_by_name(IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE)
  end
  private :illumina_b_plate_purposes
end
