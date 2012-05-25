class AddPlatePurposesForIlluminaBPipeline < ActiveRecord::Migration

  def plate_purposes
    [
      {
        :name => 'ILB_STD_INPUT',
        :type => IlluminaB::StockPlatePurpose,
        :can_be_considered_a_stock_plate => 1,
        :default_state => 'passed',
        :barcode_printer_type_id => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate').id,
        :cherrypickable_target => 1,
        :cherrypick_direction => 'row'
      },
      {
        :name => 'ILB_STD_COVARIS',
        :type => IlluminaB::CovarisPlatePurpose,
        :barcode_printer_type_id => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate').id,
        :cherrypick_direction => 'row'
      },
      {
        :name => 'ILB_STD_PCRXP',
        :type => IlluminaB::TaggedPlatePurpose,
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate').id,
        :cherrypick_direction => 'row'
      }
    ]
  end

  def child_plate_purposes
    {
      'ILB_STD_INPUT' => 'ILB_STD_COVARIS',
      'ILB_STD_COVARIS' => 'ILB_STD_PCRXP'
    }
  end

  def self.up
    ActiveRecord::Base.transaction do
      plate_purposes.each do |config|
        config[:type].create!(config)
      end
      child_plate_purposes.each do |parent,child|
        PlatePurpose.find_by_name(parent).child_plate_purposes << PlatePurpose.find_by_name(child)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      plate_purposes.each do |config|
        PlatePurpose.find_by_name(config[:name]).destroy
      end
    end
  end
end
