class Search::FindPulldownStockPlates < Search::FindPulldownPlates
  def pulldown_plate_purposes
    PlatePurpose.where(name: Pulldown::PlatePurposes::STOCK_PLATE_PURPOSES)
  end
  private :pulldown_plate_purposes
end
