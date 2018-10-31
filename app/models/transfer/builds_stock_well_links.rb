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
    stock_well_picker = source.plate_purpose.stock_plate? ? ->(a) { [a] } : ->(a) { a.stock_wells }
    eligable = destination.wells.pluck(:id)

    Hash.new { |h, v| h[v] = Array.new }.tap do |t|
      source.transfer_requests_as_source
            .where(target_asset_id: eligable)
            .includes(:target_asset, asset: :stock_wells).each do |request|
        stock = stock_well_picker.call(request.asset)
        t[request.target_asset].concat(stock)
      end
    end.each do |well, stock_wells|
      well.stock_wells.attach!(stock_wells)
    end
  end
  private :build_stock_well_relationships
end
