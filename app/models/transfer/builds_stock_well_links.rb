module Transfer::BuildsStockWellLinks
  def self.included(base)
    base.class_eval do
      after_create(:build_stock_well_relationships)
    end
  end

  # The stock wells of the target well are either the source well if that well is on a stock plate,
  # or they are the stock wells of our source well.
  def build_stock_well_relationships
    stock_well_picker = source.plate_purpose.can_be_considered_a_stock_plate? ? lambda { |r| r.asset } : lambda { |r| r.asset.stock_wells }
    destination.wells.each do |well|
      well.stock_wells.attach!(well.requests_as_target.map(&stock_well_picker).flatten)
    end
  end
  private :build_stock_well_relationships
end
