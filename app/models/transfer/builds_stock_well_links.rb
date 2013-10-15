module Transfer::BuildsStockWellLinks
  def self.included(base)
    base.class_eval do
      after_create(:build_stock_well_relationships)
    end
  end

  # The stock wells of the target well are either the source well if that well is on a stock plate,
  # or they are the stock wells of our source well. We build from the source plate to avoid repeated
  # creation of links on future transfers
  def build_stock_well_relationships
    stock_well_picker = source.plate_purpose.can_be_considered_a_stock_plate? ? lambda { |a| [ a ] } : lambda { |a| a.stock_wells }
    eligable = destination.wells.map(&:id)
    Hash.new {|h,v| h[v] = Array.new }.tap do |t|
      source.wells.each do |well|
        stock = stock_well_picker.call(well)
        well.requests.where_is_a?(TransferRequest).each {|r| t[r.target_asset].concat(stock) if eligable.include?(r.target_asset_id)  }
      end
    end.each do |well,stock_wells|
      well.stock_wells.attach!(stock_wells)
    end
  end
  private :build_stock_well_relationships
end
