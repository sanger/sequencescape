module IlluminaBPlatePurposes
  # We only have one flow at the moment
  def self.create_plate_purposes
    IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|

      stock_plate = create_stock_purpose(flow.shift)

      IlluminaB::PlatePurposes.request_type_for(stock_plate).acceptable_plate_purposes  << stock_plate

      flow.inject(stock_plate) do |previous,plate_purpose_name|
        new_purpose = create_purpose(plate_purpose_name)
        previous.child_plate_purposes << new_purpose
        new_purpose
      end
    end

    IlluminaB::PlatePurposes::BRANCHES.each do |parent,child|
      new_purpose = create_purpose(child)
      PlatePurpose.find_by_name(parent).child_plate_purposes << new_purpose
    end
  end

  def self.create_purpose(plate_purpose_name)
    IlluminaB::PlatePurposes::PLATE_PURPOSE_TYPE[plate_purpose_name].create!(
      :name => plate_purpose_name,
      :cherrypickable_target => false,
      :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction
      ).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')||plate_purpose.barcode_printer_type
      end
  end

  def self.create_stock_purpose(plate_purpose_name)
    IlluminaB::PlatePurposes.stock_plate_class.create!(
      :name => plate_purpose_name,
      :can_be_considered_a_stock_plate => true,
      :default_state => 'passed',
      :cherrypickable_target => true,
      :cherrypick_direction => IlluminaB::PlatePurposes.plate_direction
      ).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')||plate_purpose.barcode_printer_type
      end
  end
end