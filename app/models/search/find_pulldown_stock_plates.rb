class Search::FindPulldownStockPlates < Search::FindPulldownPlates # rubocop:todo Style/Documentation
  def pulldown_plate_purposes
    PlatePurpose.where(name: Pulldown::PlatePurposes::STOCK_PLATE_PURPOSES)
  end
  private :pulldown_plate_purposes
end
