class SetAppropriateTubePurpose < ActiveRecord::Migration
  TYPES_TO_PURPOSE_NAMES = {
    'MultiplexedLibraryTube'      => 'Standard MX',
    'LibraryTube'                 => 'Standard library',
    'SampleTube'                  => 'Standard sample',
    'StockMultiplexedLibraryTube' => 'Stock MX',
    'StockLibraryTube'            => 'Stock library',
    'StockSampleTube'             => 'Stock sample'
  }

  def self.up
    ActiveRecord::Base.transaction do
      TYPES_TO_PURPOSE_NAMES.each do |type, purpose_name|
        purpose = Tube::Purpose.find_by_name(purpose_name) or raise "Cannot find tube purpose #{purpose_name.inspect}"
        type.constantize.update_all("plate_purpose_id=#{purpose.id}")
      end
    end
  end

  def self.down
    # Nothing to do here really
  end
end
