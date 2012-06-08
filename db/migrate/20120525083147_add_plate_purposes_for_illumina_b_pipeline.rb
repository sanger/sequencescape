class AddPlatePurposesForIlluminaBPipeline < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|

        stock_plate = IlluminaB::PlatePurposes.stock_plate_class.create!(
          :name => flow.shift,
          :can_be_considered_a_stock_plate => true,
          :default_state => 'passed',
          :cherrypickable_target => true,
          :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction,
          :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')
          )

        IlluminaB::PlatePurposes.request_type_for(stock_plate).acceptable_plate_purposes << stock_plate

        flow.inject(stock_plate) do |previous,plate_purpose_name|
          new_purpose = IlluminaB::PlatePurposes::PLATE_PURPOSE_TYPE[plate_purpose_name].create!(
            :name => plate_purpose_name,
            :cherrypickable_target => false,
            :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction,
            :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')
            )
          previous.child_plate_purposes << new_purpose
          new_purpose
        end
      end

    end
  end

  def self.down

    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|
        flow.each do |name|
          PlatePurpose.find_by_name(name).destroy
        end
      end
    end

  end
end
