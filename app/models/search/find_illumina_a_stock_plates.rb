
class Search::FindIlluminaAStockPlates < Search::FindIlluminaAPlates
  def illumina_a_plate_purposes
    PlatePurpose.where(name: IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE)
  end
  private :illumina_a_plate_purposes
end
