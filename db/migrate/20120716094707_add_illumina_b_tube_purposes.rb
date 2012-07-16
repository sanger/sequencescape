class AddIlluminaBTubePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType1DTube') or raise "Cannot find 1D tube printer type"
      IlluminaB::StockTubePurpose.create!(:name => 'ILB_STD_STOCK', :target_type => 'StockMultiplexedLibraryTube', :barcode_printer_type => printer_type)
      IlluminaB::MxTubePurpose.create!(:name => 'ILB_STD_MX', :target_type => 'MultiplexedLibraryTube', :barcode_printer_type => printer_type)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaB::StockTubePurpose.find_by_name('ILB_STD_STOCK').destroy
      IlluminaB::MxTubePurpose.find_by_name('ILB_STD_MX').destroy
    end
  end
end
