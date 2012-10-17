class Search::FindPulldownStockPlates < Search::FindPulldownPlates
  def pulldown_plate_purposes
    PlatePurpose.find_all_by_name(Pulldown::PlatePurposes::STOCK_PLATE_PURPOSES)
  end
  private :pulldown_plate_purposes
end
