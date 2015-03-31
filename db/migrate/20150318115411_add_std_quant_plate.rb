class AddStdQuantPlate < ActiveRecord::Migration
  def self.purpose_name
    'Quant STD'
  end

  def self.up
    ActiveRecord::Base.transaction do
      purpose = PlatePurpose.create!(
        :name=> self.purpose_name,
        :default_state=>'pending',
        :barcode_printer_type => BarcodePrinterType.find_by_name('96 Well Plate'),
        :asset_shape => Map::AssetShape.find_by_name('Standard')
      )
      Plate::Creator.create!(:name => self.purpose_name, :plate_purpose => purpose, :plate_purposes => [ purpose ])
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name(self.purpose_name).destroy
      Plate::Creator.find_by_name(self.purpose_name).destroy
    end
  end
end
