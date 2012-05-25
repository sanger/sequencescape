class PlatePurpose < ActiveRecord::Base
end
class IlluminaB::StockPlatePurpose < PlatePurpose
end
class IlluminaB::TaggedPlatePurpose < PlatePurpose
end

class AddPlatePurposesForIlluminaBPipeline < ActiveRecord::Migration

  @barcode_printer_type_id = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate').id
  @plate_purposes = [
      {
        :name => 'ILB_STD_INPUT',
        :type => IlluminaB::StockPlatePurpose,
        :qc_display => 0,
        :can_be_considered_a_stock_plate => 1,
        :default_state => 'passed',
        :barcode_printer_type_id => @barcode_printer_type_id,
        :cherrypickable_target => 1,
        :row_orientated => true
      },
      {
        :name => 'ILB_STD_PCRXP',
        :type => IlluminaB::TaggedPlatePurpose,
        :qc_display => 0,
        :can_be_considered_a_stock_plate => 0,
        :default_state => 'pending',
        :barcode_printer_type_id => @barcode_printer_type_id,
        :cherrypickable_target => 0,
        :row_orientated => true
      }
    ]
  def self.up
    ActiveRecord::Base.transaction do
      @plate_purposes.each do |config|
        config[:type].create!(config)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      @plate_purposes.each do |config|
        PlatePurpose.find_by_name(config[:name]).destroy
      end
    end
  end
end
