class Search::FindPulldownStockPlates < Search::FindPulldownPlates

  def self.pulldown_plate_purposes
    @plate_purposes ||= PlatePurpose.find_all_by_name(
      Pulldown::PlatePurposes::STOCK_PLATE_PURPOSES
    )
  end
  delegate :pulldown_plate_purposes, :to => 'self.class'
end
