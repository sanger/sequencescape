class Search::FindIlluminaBStockPlates < Search::FindIlluminaBPlates

  def self.illumina_b_plate_purposes
    @plate_purposes ||= PlatePurpose.find_all_by_name(
      IlluminaB::PlatePurposes::STOCK_PLATE_PURPOSE
    )
  end
  delegate :illumina_b_plate_purposes, :to => 'self.class'
end
