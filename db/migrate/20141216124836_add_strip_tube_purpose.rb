class AddStripTubePurpose < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.create!(
        :name        =>'Strip Tube Purpose',
        :target_type => 'StripTube',
        :can_be_considered_a_stock_plate => false,
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :barcode_printer_type =>  BarcodePrinterType.find_by_name("96 Well Plate"),
        :cherrypick_direction => 'column',
        :size => 8,
        :asset_shape => Map::AssetShape.find_by_name('StripTubeColumn'),
        :barcode_for_tecan => 'ean13_barcode'
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name!('Strip Tube Purpose').destroy
    end
  end
end
