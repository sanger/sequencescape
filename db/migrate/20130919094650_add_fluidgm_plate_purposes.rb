class AddFluidgmPlatePurposes < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.transaction do
      PlatePurpose.create!(
        :name=>'STA',
        :default_state=>'pending',
        :barcode_printer_type=>BarcodePrinterType.find_by_name('96 Well Plate'),
        :cherrypickable_target => true,
        :cherrypick_direction => 'column',
        :asset_shape => Map::AssetShape.find_by_name('Standard')
      )
      PlatePurpose.create!(
        :name=>'STA2',
        :default_state=>'pending',
        :barcode_printer_type=>BarcodePrinterType.find_by_name('96 Well Plate'),
        :cherrypickable_target => true,
        :cherrypick_direction => 'column',
        :asset_shape => Map::AssetShape.find_by_name('Standard')
      )
      PlatePurpose.create!(
        :name=>'Fluidgm 96-96',
        :default_state=>'pending',
        :cherrypickable_target => true,
        :cherrypick_direction => 'row',
        :size => 96,
        :asset_shape => Map::AssetShape.find_by_name('Fluidgm96')
      )
      PlatePurpose.create!(
        :name=>'Fluidgm 192-24',
        :default_state=>'pending',
        :cherrypickable_target => true,
        :cherrypick_direction => 'row',
        :size => 192,
        :asset_shape => Map::AssetShape.find_by_name('Fluidgm192')
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('STA').destroy
      PlatePurpose.find_by_name('STA2').destroy
      PlatePurpose.find_by_name('Fluidgm 96-96').destroy
      PlatePurpose.find_by_name('Fluidgm 192-24').destroy
    end
  end
end
