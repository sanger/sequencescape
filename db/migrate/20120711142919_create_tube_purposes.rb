class CreateTubePurposes < ActiveRecord::Migration
  NAMES_TO_TYPES = {
    'Standard MX'      => [ 'Tube::StandardMx', 'MultiplexedLibraryTube' ],
    'Standard library' => [ 'Tube::Purpose',    'LibraryTube' ],
    'Standard sample'  => [ 'Tube::Purpose',    'SampleTube' ],
    'Stock MX'         => [ 'Tube::StockMx',    'StockMultiplexedLibraryTube' ],
    'Stock library'    => [ 'Tube::Purpose',    'StockLibraryTube' ],
    'Stock sample'     => [ 'Tube::Purpose',    'StockSampleTube' ]
  }

  def self.up
    ActiveRecord::Base.transaction do
      barcode_printer_type = BarcodePrinterType.find_by_name('1D Tube') or raise 'Cannot find 1D printer'
      NAMES_TO_TYPES.each do |name, (type, asset_type)|
        type.constantize.create!(:name => name, :barcode_printer_type => barcode_printer_type, :target_type => asset_type)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Tube::Purpose.destroy_all
    end
  end
end
